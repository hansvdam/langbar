import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:async/async.dart';
import 'mcp_session.dart';
import 'tool_registry.dart';
import '../logger_utils.dart';

enum MCPTransport { stdio, websocket }

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
  HttpServer? _httpServer;
  json_rpc.Server? _currentRpcServer;
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

    _currentRpcServer = json_rpc.Server(channel);
    _registerHandlers(_currentRpcServer!, session);
    _currentRpcServer!.listen();
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

  void _handleWebSocketConnection(WebSocket socket) {
    final wsChannel = IOWebSocketChannel(socket);
    final channel = wsChannel.cast<String>();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final session = MCPSession(
      id: sessionId,
      toolRegistry: toolRegistry,
    );
    _sessions.add(session);

    final rpcServer = json_rpc.Server(channel);
    _registerHandlers(rpcServer, session);

    rpcServer.listen().then((_) {
      logger.i('MCP WebSocket session $sessionId disconnected');
      _sessions.remove(session);
    });
  }

  void _registerHandlers(json_rpc.Server server, MCPSession session) {
    // Initialize method
    server.registerMethod('initialize', (json_rpc.Parameters params) {
      final protocolVersion = params['protocolVersion'].asString;
      final clientInfo = params['clientInfo'].asMap as Map<String, dynamic>;

      // Accept both protocol versions
      final supportedVersions = ['2024-11-05', '2025-06-18'];
      final responseVersion = supportedVersions.contains(protocolVersion)
          ? protocolVersion
          : '2024-11-05'; // Default to older version

      session.initialize(
        protocolVersion: protocolVersion,
        clientInfo: clientInfo,
      );

      return {
        'protocolVersion': responseVersion, // Echo back the client's version if supported
        'serverInfo': {
          'name': 'Langbar MCP Server',
          'version': '1.0.0',
        },
        'capabilities': {
          'tools': {},
          'resources': {
            'listResources': true,
            'readResource': true,
            'subscribeResource': false,
          },
        },
      };
    });

    // List tools method
    server.registerMethod('tools/list', (json_rpc.Parameters params) {
      return {
        'tools': session.getTools().map((tool) => tool.toMCPSchema()).toList(),
      };
    });

    // Call tool method
    server.registerMethod('tools/call', (json_rpc.Parameters params) async {
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
    server.registerMethod('resources/list', (json_rpc.Parameters params) {
      final resources = configuration.resources.map((path) => {
        'uri': path,
        'name': path.replaceAll('/', '').replaceAll('-', ' '),
        'mimeType': 'application/json',
      }).toList();

      return {'resources': resources};
    });

    // Read resource method
    server.registerMethod('resources/read', (json_rpc.Parameters params) async {
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
    server.registerMethod('ping', (json_rpc.Parameters params) {
      return {'pong': true};
    });
  }

  Future<void> notifyToolsChanged() async {
    for (final session in _sessions) {
      if (session.isInitialized) {
        // Send notification to client about tools change
        // This would need to be implemented based on the specific transport
        logger.d('Notifying session ${session.id} about tools change');
      }
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _currentRpcServer?.close();
    await _httpServer?.close();
    _sessions.clear();
    _isRunning = false;
    logger.i('MCP Server stopped');
  }
}