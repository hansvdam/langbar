import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'mcp_session.dart';
import 'tool_registry.dart';
import '../logger_utils.dart';

/// HTTP-based MCP server implementation using SSE for notifications
/// and standard HTTP POST for RPC requests
class MCPHttpServer {
  final int port;
  final MCPToolRegistry toolRegistry;
  final Map<String, MCPSession> _sessions = {};
  final Map<String, StreamController<String>> _sseControllers = {};
  final Map<String, Timer> _keepAliveTimers = {};
  HttpServer? _httpServer;
  bool _isRunning = false;
  final Random _random = Random();

  MCPHttpServer({
    required this.port,
    required this.toolRegistry,
  });

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) {
      logger.i('MCP HTTP Server already running');
      return;
    }

    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    logger.i('MCP HTTP server listening on port $port');
    logger.i('  SSE endpoint: http://localhost:$port/mcp/events');
    logger.i('  RPC endpoint: http://localhost:$port/mcp/rpc');

    _httpServer!.listen((HttpRequest request) async {
      // Add CORS headers for browser-based clients
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-Session-ID');

      // Handle preflight requests
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      final path = request.uri.path;

      if (path == '/mcp/events' && request.method == 'GET') {
        await _handleSSE(request);
      } else if (path == '/mcp/rpc' && request.method == 'POST') {
        await _handleRPC(request);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    });

    _isRunning = true;
    logger.i('MCP HTTP Server started successfully');
  }

  /// Handle Server-Sent Events connection for notifications
  Future<void> _handleSSE(HttpRequest request) async {
    // Generate session ID
    final sessionId = _generateSessionId();

    // Check for reconnection with existing session
    final lastEventId = request.headers.value('Last-Event-ID');
    if (lastEventId != null && _sessions.containsKey(lastEventId)) {
      // Reuse existing session
      sessionId.replaceRange(0, sessionId.length, lastEventId);
      logger.i('SSE client reconnected with session: $lastEventId');
    } else {
      logger.i('=== NEW SSE CONNECTION ===');
      logger.i('Creating session: $sessionId');

      // Create new session
      final session = MCPSession(
        id: sessionId,
        toolRegistry: toolRegistry,
      );
      _sessions[sessionId] = session;
      logger.i('Session added. Total sessions: ${_sessions.length}');
    }

    // Set SSE headers
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..headers.add('Cache-Control', 'no-cache')
      ..headers.add('Connection', 'keep-alive')
      ..headers.add('X-Session-ID', sessionId);

    // Create stream controller for this connection
    final controller = StreamController<String>();
    _sseControllers[sessionId] = controller;

    // Send initial connection event
    request.response.write('id: $sessionId\n');
    request.response.write('event: connected\n');
    request.response.write('data: ${jsonEncode({'sessionId': sessionId})}\n\n');
    await request.response.flush();

    // Setup keep-alive ping every 30 seconds
    _keepAliveTimers[sessionId] = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (!controller.isClosed) {
          try {
            request.response.write(':ping\n\n');
            request.response.flush().catchError((e) {
              // Connection closed, cleanup
              _cleanupSession(sessionId);
            });
          } catch (e) {
            _cleanupSession(sessionId);
          }
        }
      },
    );

    // Listen for events to send
    controller.stream.listen(
      (event) {
        try {
          request.response.write(event);
          request.response.flush();
        } catch (e) {
          logger.e('Error sending SSE event: $e');
          _cleanupSession(sessionId);
        }
      },
      onDone: () {
        _cleanupSession(sessionId);
      },
      onError: (error) {
        logger.e('SSE stream error: $error');
        _cleanupSession(sessionId);
      },
    );

    // Handle client disconnect
    request.response.done.then((_) {
      logger.i('SSE client disconnected: $sessionId');
      _cleanupSession(sessionId);
    }).catchError((e) {
      logger.e('SSE connection error: $e');
      _cleanupSession(sessionId);
    });
  }

  /// Handle JSON-RPC requests over HTTP POST
  Future<void> _handleRPC(HttpRequest request) async {
    try {
      // Get session ID from header
      final sessionId = request.headers.value('X-Session-ID');
      if (sessionId == null) {
        _sendRPCError(request.response, -32000, 'Missing X-Session-ID header');
        return;
      }

      final session = _sessions[sessionId];
      if (session == null) {
        _sendRPCError(request.response, -32000, 'Invalid session ID');
        return;
      }

      // Parse JSON-RPC request
      final body = await utf8.decodeStream(request);
      final Map<String, dynamic> rpcRequest;

      try {
        rpcRequest = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        _sendRPCError(request.response, -32700, 'Parse error');
        return;
      }

      // Validate JSON-RPC structure
      if (!rpcRequest.containsKey('jsonrpc') || rpcRequest['jsonrpc'] != '2.0') {
        _sendRPCError(request.response, -32600, 'Invalid Request');
        return;
      }

      final method = rpcRequest['method'] as String?;
      final params = rpcRequest['params'] as Map<String, dynamic>? ?? {};
      final id = rpcRequest['id'];

      if (method == null) {
        _sendRPCError(request.response, -32600, 'Invalid Request', id);
        return;
      }

      logger.i('RPC Request: $method from session $sessionId');

      // Handle different methods
      dynamic result;
      switch (method) {
        case 'initialize':
          result = await _handleInitialize(session, params);
          break;
        case 'tools/list':
          result = _handleToolsList(session);
          break;
        case 'tools/call':
          result = await _handleToolCall(session, params);
          break;
        case 'resources/list':
          result = _handleResourcesList();
          break;
        case 'resources/read':
          result = await _handleResourceRead(session, params);
          break;
        case 'ping':
          result = {'pong': true};
          break;
        default:
          _sendRPCError(request.response, -32601, 'Method not found', id);
          return;
      }

      // Send successful response
      final response = {
        'jsonrpc': '2.0',
        'result': result,
        'id': id,
      };

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response))
        ..close();

    } catch (e) {
      logger.e('RPC handler error: $e');
      _sendRPCError(request.response, -32603, 'Internal error');
    }
  }

  Future<Map<String, dynamic>> _handleInitialize(
    MCPSession session,
    Map<String, dynamic> params,
  ) async {
    logger.i('=== INITIALIZE REQUEST RECEIVED ===');
    logger.i('Session ID: ${session.id}');

    final protocolVersion = params['protocolVersion'] as String;
    final clientInfo = params['clientInfo'] as Map<String, dynamic>;

    // Accept both protocol versions
    final supportedVersions = ['2024-11-05', '2025-06-18'];
    final responseVersion = supportedVersions.contains(protocolVersion)
        ? protocolVersion
        : '2024-11-05';

    session.initialize(
      protocolVersion: protocolVersion,
      clientInfo: clientInfo,
    );

    logger.i('Session ${session.id} initialized successfully');

    return {
      'protocolVersion': responseVersion,
      'serverInfo': {
        'name': 'Langbar MCP HTTP Server',
        'version': '1.0.0',
      },
      'capabilities': {
        'tools': {
          'listChanged': true,
        },
        'resources': {
          'listResources': true,
          'readResource': true,
          'subscribeResource': false,
        },
      },
    };
  }

  Map<String, dynamic> _handleToolsList(MCPSession session) {
    return {
      'tools': session.getTools().map((tool) => tool.toMCPSchema()).toList(),
    };
  }

  Future<Map<String, dynamic>> _handleToolCall(
    MCPSession session,
    Map<String, dynamic> params,
  ) async {
    final toolName = params['name'] as String;
    final toolParams = params['arguments'] as Map<String, dynamic>? ?? {};

    try {
      final result = await session.callTool(toolName, toolParams);
      return {
        'content': [
          {
            'type': 'text',
            'text': result.toString(),
          }
        ],
      };
    } catch (e) {
      return {
        'isError': true,
        'content': [
          {
            'type': 'text',
            'text': 'Error calling tool: $e',
          }
        ],
      };
    }
  }

  Map<String, dynamic> _handleResourcesList() {
    final resources = [
      '/current-screen',
      '/last-gui-events',
      '/conversation-history',
    ].map((path) => {
      'uri': path,
      'name': path.replaceAll('/', '').replaceAll('-', ' '),
      'mimeType': 'application/json',
    }).toList();

    return {'resources': resources};
  }

  Future<Map<String, dynamic>> _handleResourceRead(
    MCPSession session,
    Map<String, dynamic> params,
  ) async {
    final uri = params['uri'] as String;

    try {
      final content = await session.readResource(uri);
      return {
        'contents': [
          {
            'uri': uri,
            'mimeType': 'application/json',
            'text': jsonEncode(content),
          }
        ],
      };
    } catch (e) {
      throw json_rpc.RpcException(
        -32602,
        'Resource not found: $uri',
      );
    }
  }

  /// Send notification to all initialized sessions via SSE
  Future<void> notifyToolsChanged() async {
    logger.i('=== NOTIFY TOOLS CHANGED (HTTP/SSE) ===');
    logger.i('Total sessions: ${_sessions.length}');

    for (final sessionId in _sessions.keys) {
      final session = _sessions[sessionId]!;
      final controller = _sseControllers[sessionId];

      if (!session.isInitialized) {
        logger.w('Session $sessionId not initialized, skipping');
        continue;
      }

      if (controller == null || controller.isClosed) {
        logger.w('No active SSE connection for session $sessionId');
        continue;
      }

      try {
        // Send SSE notification
        final event = StringBuffer();
        event.write('id: ${DateTime.now().millisecondsSinceEpoch}\n');
        event.write('event: notification\n');
        event.write('data: ${jsonEncode({
          'method': 'notifications/tools/list_changed',
          'params': {},
        })}\n\n');

        controller.add(event.toString());
        logger.i('Sent tools/list_changed notification to session $sessionId');
      } catch (e) {
        logger.e('Error sending notification to session $sessionId: $e');
      }
    }

    logger.i('=== END NOTIFY TOOLS CHANGED ===');
  }

  void _sendRPCError(
    HttpResponse response,
    int code,
    String message, [
    dynamic id,
  ]) {
    final error = {
      'jsonrpc': '2.0',
      'error': {
        'code': code,
        'message': message,
      },
      'id': id,
    };

    response
      ..statusCode = HttpStatus.ok // JSON-RPC errors still use 200 OK
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(error))
      ..close();
  }

  void _cleanupSession(String sessionId) {
    logger.i('Cleaning up session: $sessionId');

    // Cancel keep-alive timer
    _keepAliveTimers[sessionId]?.cancel();
    _keepAliveTimers.remove(sessionId);

    // Close SSE controller
    final controller = _sseControllers[sessionId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _sseControllers.remove(sessionId);

    // Note: We keep the session in _sessions for potential reconnection
    // You might want to implement a timeout to remove old sessions
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
           '_' +
           _random.nextInt(10000).toString();
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    // Cleanup all sessions
    for (final sessionId in _sessions.keys.toList()) {
      _cleanupSession(sessionId);
    }

    _sessions.clear();
    await _httpServer?.close();
    _isRunning = false;

    logger.i('MCP HTTP Server stopped');
  }
}