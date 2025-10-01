import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:async/async.dart';
import 'mcp_session.dart';
import 'mcp_http_server.dart';
import 'mcp_streamable_http_server.dart';
import 'tool_registry.dart';
import '../logger_utils.dart';

enum MCPTransport { stdio, websocket, http, streamableHttp }

/// Window behavior when MCP navigation occurs
enum MCPWindowMode {
  none,        // No window management
  showOnly,    // Show window without focus (default)
  showAndFocus // Show window and take focus
}

class MCPConfiguration {
  final MCPTransport transport;
  final int? port;
  final bool exposeRoutes;
  final bool exposeViewModels;
  final bool enableKeywordMatching;
  final List<String> resources;
  final MCPWindowMode windowMode;

  MCPConfiguration({
    this.transport = MCPTransport.stdio,
    this.port,
    this.exposeRoutes = true,
    this.exposeViewModels = true,
    this.enableKeywordMatching = false,
    this.resources = const [
      '/current-screen',
      '/last-gui-events',
      '/conversation-history',
    ],
    this.windowMode = MCPWindowMode.showOnly, // Default to visual-only (no focus steal)
  });
}

class MCPServer {
  final MCPConfiguration configuration;
  final MCPToolRegistry toolRegistry;
  final List<MCPSession> _sessions = [];
  final Map<String, json_rpc.Peer> _sessionPeers = {}; // Store peers for notifications
  HttpServer? _httpServer;
  MCPHttpServer? _httpServerInstance; // For HTTP/SSE transport
  MCPStreamableHttpServer? _streamableHttpServer; // For Streamable HTTP transport
  json_rpc.Server? _currentRpcServer;
  json_rpc.Peer? _stdioPeer; // For stdio transport
  bool _isRunning = false;

  MCPServer({
    required this.configuration,
    MCPToolRegistry? toolRegistry,
  }) : toolRegistry = toolRegistry ?? MCPToolRegistry();

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) {
      logger.i('MCP Server already running');
      return;
    }

    switch (configuration.transport) {
      case MCPTransport.stdio:
        await _startStdioServer();
        break;
      case MCPTransport.websocket:
        await _startWebSocketServer();
        break;
      case MCPTransport.http:
        await _startHttpServer();
        break;
      case MCPTransport.streamableHttp:
        await _startStreamableHttpServer();
        break;
    }
    _isRunning = true;
    logger.i('MCP Server started with ${configuration.transport} transport');
  }

  Future<void> _startStdioServer() async {
    final inputStream = stdin.transform(utf8.decoder).transform(const LineSplitter());
    final outputSink = stdout;

    final channel = StreamChannel<String>(
      inputStream,
      StreamSinkTransformer.fromHandlers(
        handleData: (String data, EventSink<String> sink) {
          outputSink.writeln(data);
        },
      ).bind(StreamController<String>().sink),
    );

    final session = MCPSession(
      id: 'stdio',
      toolRegistry: toolRegistry,
    );
    _sessions.add(session);

    // Use Peer instead of Server for bidirectional communication
    _stdioPeer = json_rpc.Peer(channel);
    _sessionPeers[session.id] = _stdioPeer!;
    _registerHandlers(_stdioPeer!, session);
    _stdioPeer!.listen();
  }

  Future<void> _startWebSocketServer() async {
    if (configuration.port == null) {
      throw ArgumentError('Port must be specified for WebSocket transport');
    }

    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, configuration.port!);
    logger.i('MCP WebSocket server listening on port ${configuration.port}');

    _httpServer!.listen((HttpRequest request) async {
      if (request.uri.path == '/mcp' && WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocketConnection(socket);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    });
  }

  Future<void> _startHttpServer() async {
    if (configuration.port == null) {
      throw ArgumentError('Port must be specified for HTTP transport');
    }

    _httpServerInstance = MCPHttpServer(
      port: configuration.port!,
      toolRegistry: toolRegistry,
    );

    await _httpServerInstance!.start();
    logger.i('MCP HTTP Server started on port ${configuration.port}');
  }

  Future<void> _startStreamableHttpServer() async {
    if (configuration.port == null) {
      throw ArgumentError('Port must be specified for Streamable HTTP transport');
    }

    _streamableHttpServer = MCPStreamableHttpServer(
      port: configuration.port!,
      toolRegistry: toolRegistry,
    );

    await _streamableHttpServer!.start();
    logger.i('MCP Streamable HTTP Server started on port ${configuration.port}');
  }

  void _handleWebSocketConnection(WebSocket socket) {
    final wsChannel = IOWebSocketChannel(socket);
    final channel = wsChannel.cast<String>();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    logger.i('=== NEW WEBSOCKET CONNECTION ===');
    logger.i('Creating session: $sessionId');

    final session = MCPSession(
      id: sessionId,
      toolRegistry: toolRegistry,
    );
    _sessions.add(session);
    logger.i('Session added. Total sessions: ${_sessions.length}');
    logger.i('Session ${sessionId} initialized: ${session.isInitialized}');

    // Use Peer instead of Server for bidirectional communication
    final rpcPeer = json_rpc.Peer(channel);
    _sessionPeers[sessionId] = rpcPeer;
    logger.i('Registering handlers for session $sessionId');
    _registerHandlers(rpcPeer, session);

    logger.i('Starting to listen on peer for session $sessionId');
    rpcPeer.listen().then((_) {
      logger.i('=== WEBSOCKET DISCONNECTED ===');
      logger.i('Session $sessionId disconnected');
      _sessions.remove(session);
      _sessionPeers.remove(sessionId);
      logger.i('Remaining sessions: ${_sessions.length}');
    });
  }

  void _registerHandlers(json_rpc.Peer peer, MCPSession session) {
    // Initialize method
    peer.registerMethod('initialize', (json_rpc.Parameters params) {
      logger.i('=== INITIALIZE REQUEST RECEIVED ===');
      logger.i('Session ID: ${session.id}');
      logger.i('Raw params: ${params.value}');

      final protocolVersion = params['protocolVersion'].asString;
      final clientInfo = params['clientInfo'].asMap as Map<String, dynamic>;
      logger.d('Protocol version: $protocolVersion');
      logger.d('Client info: $clientInfo');

      // Accept both protocol versions
      final supportedVersions = ['2024-11-05', '2025-06-18'];
      final responseVersion = supportedVersions.contains(protocolVersion)
          ? protocolVersion
          : '2024-11-05'; // Default to older version

      // Initialize the session
      logger.d('About to initialize session...');
      session.initialize(
        protocolVersion: protocolVersion,
        clientInfo: clientInfo,
      );
      logger.d('Session.initialize() called, isInitialized: ${session.isInitialized}');

      logger.i('Session ${session.id} initialized successfully');
      logger.i('Total sessions: ${_sessions.length}, initialized count: ${_sessions.where((s) => s.isInitialized).length}');

      final response = {
        'protocolVersion': responseVersion, // Echo back the client's version if supported
        'serverInfo': {
          'name': 'Langbar MCP Server',
          'version': '1.0.0',
        },
        'capabilities': {
          'tools': {
            'listChanged': true, // Server will emit notifications when tools change
          },
          'resources': {
            'listResources': true,
            'readResource': true,
            'subscribeResource': false,
          },
        },
      };

      logger.i('=== SENDING INITIALIZE RESPONSE ===');
      logger.d('Response: $response');

      return response;
    });

    // List tools method
    peer.registerMethod('tools/list', (json_rpc.Parameters params) {
      return {
        'tools': session.getTools().map((tool) => tool.toMCPSchema()).toList(),
      };
    });

    // Call tool method
    peer.registerMethod('tools/call', (json_rpc.Parameters params) async {
      final toolName = params['name'].asString;
      final toolParams = params['arguments'].asMap as Map<String, dynamic>;

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
    });

    // List resources method
    peer.registerMethod('resources/list', (json_rpc.Parameters params) {
      final resources = configuration.resources.map((path) => {
        'uri': path,
        'name': path.replaceAll('/', '').replaceAll('-', ' '),
        'mimeType': 'application/json',
      }).toList();

      return {'resources': resources};
    });

    // Read resource method
    peer.registerMethod('resources/read', (json_rpc.Parameters params) async {
      final uri = params['uri'].asString;

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
          -32602,  // Invalid params error code
          'Resource not found: $uri',
        );
      }
    });

    // Ping method (keep-alive)
    peer.registerMethod('ping', (json_rpc.Parameters params) {
      return {'pong': true};
    });
  }

  Future<void> notifyToolsChanged() async {
    // If using HTTP transport, delegate to HTTP server
    if (configuration.transport == MCPTransport.http && _httpServerInstance != null) {
      await _httpServerInstance!.notifyToolsChanged();
      return;
    }

    // If using Streamable HTTP transport, delegate to streamable server
    if (configuration.transport == MCPTransport.streamableHttp && _streamableHttpServer != null) {
      await _streamableHttpServer!.notifyToolsChanged();
      return;
    }

    // Original WebSocket/stdio notification logic
    logger.i('=== NOTIFY TOOLS CHANGED ===');
    logger.i('Total sessions: ${_sessions.length}');
    logger.i('Session details:');

    for (final session in _sessions) {
      logger.i('  Session ${session.id}:');
      logger.i('    - initialized: ${session.isInitialized}');
      logger.i('    - has peer: ${_sessionPeers.containsKey(session.id)}');

      // if (!session.isInitialized) {
      //   logger.w('    → Skipping: session not initialized');
      //   continue;
      // }

      final peer = _sessionPeers[session.id];
      if (peer == null) {
        logger.w('    → Skipping: no peer found');
        continue;
      }

      try {
        // Send notification about tools change
        // Per MCP spec, send notification without tool data
        // Client should request tools/list to get the updated list
        logger.i('    → Sending tools/list_changed notification...');
        peer.sendNotification('notifications/tools/list_changed', {});
        logger.i('    ✓ Successfully sent notification');
      } catch (e) {
        logger.e('    ✗ Error sending notification: $e');
      }
    }

    logger.i('=== END NOTIFY TOOLS CHANGED ===');
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    // Stop HTTP server if running
    if (_httpServerInstance != null) {
      await _httpServerInstance!.stop();
      _httpServerInstance = null;
    }

    // Stop Streamable HTTP server if running
    if (_streamableHttpServer != null) {
      await _streamableHttpServer!.stop();
      _streamableHttpServer = null;
    }

    // Close all peers
    for (final peer in _sessionPeers.values) {
      peer.close();
    }
    _sessionPeers.clear();
    _stdioPeer = null;
    _currentRpcServer?.close();
    await _httpServer?.close();
    _sessions.clear();
    _isRunning = false;
    logger.i('MCP Server stopped');
  }
}