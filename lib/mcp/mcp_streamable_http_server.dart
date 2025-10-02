import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'mcp_session.dart';
import 'tool_registry.dart';
import '../logger_utils.dart';

/// Streamable HTTP-based MCP server implementation according to the
/// MCP specification (2025-06-18)
///
/// This implementation provides:
/// - Single endpoint for both RPC and SSE
/// - Proper session management with Mcp-Session-Id header
/// - Protocol version negotiation
/// - Support for both JSON responses and SSE streams
class MCPStreamableHttpServer {
  final int port;
  final MCPToolRegistry toolRegistry;
  final String endpoint;
  final bool bindToLocalhost;

  final Map<String, MCPSession> _sessions = {};
  final Map<String, StreamController<String>> _sseControllers = {};
  final Map<String, Timer> _keepAliveTimers = {};
  final Map<String, DateTime> _sessionLastActivity = {};

  HttpServer? _httpServer;
  bool _isRunning = false;
  final Random _random = Random.secure();
  Timer? _sessionCleanupTimer;

  // Configuration
  static const Duration sessionTimeout = Duration(hours: 1);
  static const Duration keepAliveInterval = Duration(seconds: 30);
  static const String defaultProtocolVersion = '2025-03-26';

  MCPStreamableHttpServer({
    required this.port,
    required this.toolRegistry,
    this.endpoint = '/mcp',
    this.bindToLocalhost = true,
  });

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) {
      logger.i('MCP Streamable HTTP Server already running');
      return;
    }

    // Bind to localhost or any interface based on configuration
    final address = bindToLocalhost
        ? InternetAddress.loopbackIPv4
        : InternetAddress.anyIPv4;

    _httpServer = await HttpServer.bind(address, port);
    logger.i('MCP Streamable HTTP server listening on ${address.host}:$port');
    logger.i('  Endpoint: http://${address.host}:$port$endpoint');

    // Start session cleanup timer
    _sessionCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupInactiveSessions(),
    );

    _httpServer!.listen((HttpRequest request) async {
      try {
        await _handleRequest(request);
      } catch (e, stack) {
        logger.e('Error handling request: $e\n$stack');
        _sendError(request.response, HttpStatus.internalServerError, 'Internal server error');
      }
    });

    _isRunning = true;
    logger.i('MCP Streamable HTTP Server started successfully');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Add CORS headers
    _addCorsHeaders(request.response);

    // Handle preflight requests
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    // Check endpoint
    if (request.uri.path != endpoint) {
      _sendError(request.response, HttpStatus.notFound, 'Not Found');
      return;
    }

    // Validate Origin header if configured
    if (!_validateOrigin(request)) {
      _sendError(request.response, HttpStatus.forbidden, 'Invalid origin');
      return;
    }

    // Extract protocol version
    final protocolVersion = request.headers.value('MCP-Protocol-Version')
        ?? defaultProtocolVersion;

    // Handle based on method
    switch (request.method) {
      case 'GET':
        await _handleGet(request, protocolVersion);
        break;
      case 'POST':
        await _handlePost(request, protocolVersion);
        break;
      default:
        _sendError(request.response, HttpStatus.methodNotAllowed, 'Method not allowed');
    }
  }

  /// Handle GET requests for SSE streaming
  Future<void> _handleGet(HttpRequest request, String protocolVersion) async {
    // Get or create session
    String sessionId = request.headers.value('Mcp-Session-Id') ?? '';

    // Check for reconnection with Last-Event-ID
    final lastEventId = request.headers.value('Last-Event-ID');
    if (lastEventId != null && _sessions.containsKey(lastEventId)) {
      sessionId = lastEventId;
      logger.i('SSE client reconnected with session: $sessionId');
    } else if (sessionId.isEmpty || !_sessions.containsKey(sessionId)) {
      // Generate new session ID
      sessionId = _generateSessionId();
      logger.i('Creating new session: $sessionId');

      final session = MCPSession(
        id: sessionId,
        toolRegistry: toolRegistry,
      );
      _sessions[sessionId] = session;
    }

    _updateSessionActivity(sessionId);

    // Set SSE headers
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..headers.add('Cache-Control', 'no-cache')
      ..headers.add('Connection', 'keep-alive')
      ..headers.add('X-Accel-Buffering', 'no') // Disable nginx buffering
      ..headers.add('Mcp-Session-Id', sessionId)
      ..headers.add('MCP-Protocol-Version', protocolVersion);

    // Create or get stream controller
    _sseControllers[sessionId]?.close();
    final controller = StreamController<String>();
    _sseControllers[sessionId] = controller;

    // Send initial connection event
    final connectEvent = _formatSSEEvent(
      id: sessionId,
      event: 'connected',
      data: jsonEncode({
        'sessionId': sessionId,
        'protocolVersion': protocolVersion,
      }),
    );
    request.response.write(connectEvent);
    await request.response.flush();

    // Setup keep-alive
    _keepAliveTimers[sessionId]?.cancel();
    _keepAliveTimers[sessionId] = Timer.periodic(
      keepAliveInterval,
      (timer) => _sendKeepAlive(request.response, sessionId),
    );

    // Stream events
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
      onDone: () => _cleanupSession(sessionId),
      onError: (error) {
        logger.e('SSE stream error: $error');
        _cleanupSession(sessionId);
      },
    );

    // Handle client disconnect
    request.response.done.then((_) {
      logger.i('SSE client disconnected: $sessionId');
      // Don't immediately cleanup - allow reconnection
      _keepAliveTimers[sessionId]?.cancel();
    }).catchError((e) {
      logger.e('SSE connection error: $e');
      _keepAliveTimers[sessionId]?.cancel();
    });
  }

  /// Handle POST requests for JSON-RPC
  Future<void> _handlePost(HttpRequest request, String protocolVersion) async {
    // Get or create session
    var sessionId = request.headers.value('Mcp-Session-Id') ?? '';

    if (sessionId.isEmpty) {
      sessionId = _generateSessionId();
      logger.i('Creating new session for POST request: $sessionId');

      final session = MCPSession(
        id: sessionId,
        toolRegistry: toolRegistry,
      );
      _sessions[sessionId] = session;
    }

    final session = _sessions[sessionId];
    if (session == null) {
      _sendRPCError(request.response, -32000, 'Invalid session', null, sessionId);
      return;
    }

    _updateSessionActivity(sessionId);

    // Parse request body
    final body = await utf8.decodeStream(request);
    Map<String, dynamic> rpcRequest;

    try {
      rpcRequest = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      _sendRPCError(request.response, -32700, 'Parse error', null, sessionId);
      return;
    }

    // Validate JSON-RPC
    if (!rpcRequest.containsKey('jsonrpc') || rpcRequest['jsonrpc'] != '2.0') {
      _sendRPCError(request.response, -32600, 'Invalid Request', null, sessionId);
      return;
    }

    final method = rpcRequest['method'] as String?;
    final params = rpcRequest['params'] as Map<String, dynamic>? ?? {};
    final id = rpcRequest['id'];

    // Check if this is a notification or response (no id means notification)
    if (id == null) {
      // Notification or response - return 202 Accepted
      request.response
        ..statusCode = HttpStatus.accepted
        ..headers.add('Mcp-Session-Id', sessionId)
        ..headers.add('MCP-Protocol-Version', protocolVersion)
        ..close();

      logger.i('Received notification: $method');
      return;
    }

    if (method == null) {
      _sendRPCError(request.response, -32600, 'Invalid Request', id, sessionId);
      return;
    }

    logger.i('RPC Request: $method from session $sessionId');

    // Check Accept header to determine response format
    final acceptHeader = request.headers.value('Accept') ?? '';
    final wantsSSE = acceptHeader.contains('text/event-stream');

    try {
      // Handle the RPC method
      final result = await _handleRPCMethod(session, method, params, protocolVersion);

      if (wantsSSE) {
        // Return SSE stream for this response
        await _sendSSEResponse(request, sessionId, id, result, protocolVersion);
      } else {
        // Return JSON response
        _sendJSONResponse(request.response, id, result, sessionId, protocolVersion);
      }
    } catch (e) {
      if (e is json_rpc.RpcException) {
        _sendRPCError(request.response, e.code, e.message, id, sessionId);
      } else {
        _sendRPCError(request.response, -32603, 'Internal error: $e', id, sessionId);
      }
    }
  }

  Future<dynamic> _handleRPCMethod(
    MCPSession session,
    String method,
    Map<String, dynamic> params,
    String protocolVersion,
  ) async {
    switch (method) {
      case 'initialize':
        return await _handleInitialize(session, params, protocolVersion);
      case 'tools/list':
        return _handleToolsList(session);
      case 'tools/call':
        return await _handleToolCall(session, params);
      case 'resources/list':
        return _handleResourcesList();
      case 'resources/read':
        return await _handleResourceRead(session, params);
      case 'ping':
        return {'pong': true, 'timestamp': DateTime.now().toIso8601String()};
      default:
        throw json_rpc.RpcException(-32601, 'Method not found');
    }
  }

  Future<Map<String, dynamic>> _handleInitialize(
    MCPSession session,
    Map<String, dynamic> params,
    String protocolVersion,
  ) async {
    logger.i('Initialize request for session ${session.id}');

    final clientProtocolVersion = params['protocolVersion'] as String;
    final clientInfo = params['clientInfo'] as Map<String, dynamic>;

    // Support multiple protocol versions
    final supportedVersions = ['2024-11-05', '2025-03-26', '2025-06-18'];
    final negotiatedVersion = supportedVersions.contains(clientProtocolVersion)
        ? clientProtocolVersion
        : protocolVersion;

    session.initialize(
      protocolVersion: negotiatedVersion,
      clientInfo: clientInfo,
    );

    return {
      'protocolVersion': negotiatedVersion,
      'serverInfo': {
        'name': 'Langbar MCP Streamable HTTP Server',
        'version': '2.0.0',
      },
      'capabilities': {
        'tools': {'listChanged': true},
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
  }

  /// Send JSON response
  void _sendJSONResponse(
    HttpResponse response,
    dynamic id,
    dynamic result,
    String sessionId,
    String protocolVersion,
  ) {
    final jsonResponse = {
      'jsonrpc': '2.0',
      'result': result,
      'id': id,
    };

    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.add('Mcp-Session-Id', sessionId)
      ..headers.add('MCP-Protocol-Version', protocolVersion)
      ..write(jsonEncode(jsonResponse))
      ..close();
  }

  /// Send SSE response stream
  Future<void> _sendSSEResponse(
    HttpRequest request,
    String sessionId,
    dynamic id,
    dynamic result,
    String protocolVersion,
  ) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..headers.add('Cache-Control', 'no-cache')
      ..headers.add('Mcp-Session-Id', sessionId)
      ..headers.add('MCP-Protocol-Version', protocolVersion);

    // Send the response as an SSE event
    final responseEvent = _formatSSEEvent(
      id: id.toString(),
      event: 'response',
      data: jsonEncode({
        'jsonrpc': '2.0',
        'result': result,
        'id': id,
      }),
    );

    request.response.write(responseEvent);
    await request.response.flush();
    await request.response.close();
  }

  /// Send RPC error response
  void _sendRPCError(
    HttpResponse response,
    int code,
    String message,
    dynamic id,
    String sessionId,
  ) {
    final error = {
      'jsonrpc': '2.0',
      'error': {
        'code': code,
        'message': message,
      },
      'id': id,
    };

    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.add('Mcp-Session-Id', sessionId)
      ..write(jsonEncode(error))
      ..close();
  }

  /// Send notification to all initialized sessions via SSE
  Future<void> notifyToolsChanged() async {
    logger.i('Notifying tools changed to ${_sessions.length} sessions');

    for (final entry in _sessions.entries) {
      final sessionId = entry.key;
      final session = entry.value;

      if (!session.isInitialized) continue;

      final controller = _sseControllers[sessionId];
      if (controller == null || controller.isClosed) continue;

      try {
        final event = _formatSSEEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          event: 'notification',
          data: jsonEncode({
            'method': 'notifications/tools/list_changed',
            'params': {},
          }),
        );

        controller.add(event);
        logger.i('Sent tools/list_changed to session $sessionId');
      } catch (e) {
        logger.e('Error sending notification to $sessionId: $e');
      }
    }
  }

  /// Format SSE event
  String _formatSSEEvent({
    String? id,
    String? event,
    required String data,
  }) {
    final buffer = StringBuffer();
    if (id != null) buffer.write('id: $id\n');
    if (event != null) buffer.write('event: $event\n');
    buffer.write('data: $data\n\n');
    return buffer.toString();
  }

  /// Generate cryptographically secure session ID
  String _generateSessionId() {
    final bytes = List<int>.generate(32, (i) => _random.nextInt(256));
    return base64Url.encode(sha256.convert(bytes).bytes);
  }

  /// Add CORS headers
  void _addCorsHeaders(HttpResponse response) {
    response.headers
      ..add('Access-Control-Allow-Origin', '*')
      ..add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..add('Access-Control-Allow-Headers',
            'Content-Type, Accept, Mcp-Session-Id, MCP-Protocol-Version, Last-Event-ID');
  }

  /// Validate Origin header
  bool _validateOrigin(HttpRequest request) {
    // For localhost binding, always allow
    if (bindToLocalhost) return true;

    // TODO: Implement origin validation based on configuration
    // For now, allow all origins
    return true;
  }

  /// Send keep-alive ping
  void _sendKeepAlive(HttpResponse response, String sessionId) {
    try {
      response.write(':ping\n\n');
      response.flush().catchError((e) {
        logger.d('Keep-alive failed for session $sessionId');
      });
    } catch (e) {
      logger.d('Keep-alive error for session $sessionId: $e');
    }
  }

  /// Update session last activity
  void _updateSessionActivity(String sessionId) {
    _sessionLastActivity[sessionId] = DateTime.now();
  }

  /// Cleanup inactive sessions
  void _cleanupInactiveSessions() {
    final now = DateTime.now();
    final sessionsToRemove = <String>[];

    for (final entry in _sessionLastActivity.entries) {
      if (now.difference(entry.value) > sessionTimeout) {
        sessionsToRemove.add(entry.key);
      }
    }

    for (final sessionId in sessionsToRemove) {
      logger.i('Removing inactive session: $sessionId');
      _cleanupSession(sessionId);
    }
  }

  /// Cleanup session resources
  void _cleanupSession(String sessionId) {
    _keepAliveTimers[sessionId]?.cancel();
    _keepAliveTimers.remove(sessionId);

    final controller = _sseControllers[sessionId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _sseControllers.remove(sessionId);

    // Keep session for potential reconnection
    // Only remove after timeout
  }

  /// Send error response
  void _sendError(HttpResponse response, int statusCode, String message) {
    response
      ..statusCode = statusCode
      ..write(message)
      ..close();
  }

  /// Stop the server
  Future<void> stop() async {
    if (!_isRunning) return;

    logger.i('Stopping MCP Streamable HTTP Server...');

    // Cancel cleanup timer
    _sessionCleanupTimer?.cancel();

    // Cleanup all sessions
    for (final sessionId in _sessions.keys.toList()) {
      _cleanupSession(sessionId);
    }

    _sessions.clear();
    _sessionLastActivity.clear();

    await _httpServer?.close();
    _isRunning = false;

    logger.i('MCP Streamable HTTP Server stopped');
  }
}