#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:args/args.dart';

/// Standalone MCP Server Bridge
///
/// This server acts as a bridge between Claude Desktop (which expects stdio communication)
/// and the Flutter app's WebSocket-based MCP server.
///
/// Architecture:
/// Claude Desktop <--stdio--> This Bridge <--WebSocket--> Flutter App MCP Server
///
/// Usage:
/// dart run mcp_server.dart [--port 3000] [--host localhost]
///
/// add the following to ~/Library/Application Support/Claude/claude_desktop_config.json:
///
///     "flutter-langbar": {
//       "command": "/Users/<username>/Library/flutter/bin/dart",
//       "args": [
//         "run",
//         "/Users/<username>/Projects/Flutter/langbar_core/example/bin/mcp_server.dart",
//         "--port",
//         "3001",
//         "--host",
//         "localhost"
//       ]
//     }

class MCPBridgeServer {
  final String host;
  final int port;
  final bool verbose;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _stdinSubscription;

  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const maxReconnectAttempts = 10;

  MCPBridgeServer({
    this.host = 'localhost',
    this.port = 3000,
    this.verbose = false,
  });

  Future<void> start() async {
    try {
      _error('MCP Bridge Server starting up...');
      _error('Will connect to Flutter app at ws://$host:$port/mcp');

      // Setup stdin listener for Claude Desktop
      _setupStdinListener();

      // Connect to Flutter app's WebSocket server
      await _connectToWebSocket();

      // Keep the process alive
      await _keepAlive();
    } catch (e, stack) {
      _error('Fatal error in start(): $e');
      _error('Stack trace: $stack');
      exit(1);
    }
  }

  void _setupStdinListener() {
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleStdinMessage,
          onError: (error) {
            _error('Stdin error: $error');
          },
          cancelOnError: false,
        );
    _log('Stdin listener ready');
  }

  Future<void> _connectToWebSocket() async {
    try {
      _error('Attempting WebSocket connection to ws://$host:$port/mcp');
      final uri = Uri.parse('ws://$host:$port/mcp');

      // Try to connect with a timeout
      try {
        _wsChannel = WebSocketChannel.connect(uri);

        // Don't use ready.timeout as it consumes the stream
        // Instead, set up the stream listener and see if we get any errors quickly
        _wsSubscription?.cancel();

        final completer = Completer<void>();
        bool connected = false;

        _wsSubscription = _wsChannel!.stream.listen(
          (message) {
            if (!connected) {
              connected = true;
              completer.complete();
            }
            _handleWebSocketMessage(message);
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
            _handleWebSocketError(error);
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(Exception('Connection closed'));
            }
            _handleWebSocketDone();
          },
          cancelOnError: false,
        );

        // Wait a bit to see if connection succeeds
        await Future.any([
          completer.future,
          Future.delayed(const Duration(seconds: 2)),
        ]);

        _isConnected = true;
        _reconnectAttempts = 0;
        _error('Successfully connected to Flutter MCP server');
      } catch (e) {
        _isConnected = false;
        _error('WebSocket connection failed: $e');
        // Don't schedule reconnect here - let the bridge continue to work
        // It will try to connect when it receives messages
      }
    } catch (e) {
      _error('Failed to connect to WebSocket: $e');
      _isConnected = false;
    }
  }

  void _handleStdinMessage(String message) {
    if (message.trim().isEmpty) return;

    try {
      _error('Received from Claude: $message');
      final json = jsonDecode(message) as Map<String, dynamic>;

      // Handle initialize specially - respond even if not connected to Flutter
      if (json['method'] == 'initialize') {
        _handleInitialize(json);
        return;
      }

      // For other messages, check connection
      if (!_isConnected || _wsChannel == null) {
        // Try to reconnect first
        _connectToWebSocket().then((_) {
          if (_isConnected && _wsChannel != null) {
            // Now forward the message
            final messageStr = jsonEncode(json);
            _wsChannel!.sink.add(messageStr);
            _error('Forwarded to Flutter after reconnect: $messageStr');
          } else {
            _sendErrorResponse(
              json['id'] as int? ?? -1,
              'MCP Bridge: Cannot connect to Flutter app on ws://$host:$port/mcp. Make sure the Flutter app is running.',
            );
          }
        });
      } else {
        // Forward to WebSocket
        final messageStr = jsonEncode(json);
        _wsChannel!.sink.add(messageStr);
        _error('Forwarded to Flutter: $messageStr');
      }

    } catch (e) {
      _error('Error processing stdin message: $e');
      _sendErrorResponse(-1, 'Internal error: $e');
    }
  }

  void _handleInitialize(Map<String, dynamic> json) {
    try {
      final id = json['id'] as int? ?? 0;
      final params = json['params'] as Map<String, dynamic>? ?? {};
      final clientProtocol = params['protocolVersion'] ?? '2025-06-18';

      _error('=== INITIALIZE REQUEST ===');
      _error('Client protocol: $clientProtocol');
      _error('Connected to Flutter: $_isConnected');

      // If connected to Flutter, forward and let it respond
      if (_isConnected && _wsChannel != null) {
        // Adapt protocol version if needed
        if (clientProtocol == '2025-06-18') {
          _error('Adapting protocol from 2025-06-18 to 2024-11-05 for Flutter');
          params['protocolVersion'] = '2024-11-05';
        }
        final messageStr = jsonEncode(json);
        _wsChannel!.sink.add(messageStr);
        _error('Forwarded initialize to Flutter: $messageStr');
      } else {
        // Not connected - respond directly from bridge
        _error('Not connected to Flutter, responding from bridge');
        final response = {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'protocolVersion': clientProtocol, // Echo back client's version
            'serverInfo': {
              'name': 'Langbar MCP Bridge (Flutter app not connected)',
              'version': '1.0.0',
            },
            'capabilities': {
              'tools': {},
              'resources': {
                'listResources': false,
                'readResource': false,
              },
            },
          },
        };
        stdout.writeln(jsonEncode(response));
        _error('Sent initialize response from bridge');

        // Try to connect in the background
        _connectToWebSocket();
      }
    } catch (e) {
      _error('Error handling initialize: $e');
      _sendErrorResponse(json['id'] as int? ?? 0, 'Failed to initialize: $e');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      _error('Received from Flutter: $message');
      final json = jsonDecode(message.toString()) as Map<String, dynamic>;

      // Adapt protocol version in response if needed
      if (json['result'] != null) {
        final result = json['result'] as Map<String, dynamic>;
        if (result['protocolVersion'] == '2024-11-05') {
          // Change to client's expected version
          result['protocolVersion'] = '2025-06-18';
          _error('Adapted response protocol version to 2025-06-18');
        }
      }

      // Send to stdout for Claude
      final output = jsonEncode(json);
      stdout.writeln(output);
      _error('Sent to Claude: $output');

    } catch (e) {
      _error('Error processing WebSocket message: $e');
    }
  }

  void _handleWebSocketError(dynamic error) {
    _error('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleWebSocketDone() {
    _log('WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _error('Max reconnection attempts reached. Exiting.');
      exit(1);
    }

    _reconnectTimer?.cancel();

    final delay = _getReconnectDelay(_reconnectAttempts);
    _log('Reconnecting in ${delay.inSeconds} seconds... (attempt ${_reconnectAttempts + 1}/$maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connectToWebSocket();
    });
  }

  Duration _getReconnectDelay(int attempt) {
    // Exponential backoff with max 30 seconds
    final seconds = (2 << attempt).clamp(1, 30);
    return Duration(seconds: seconds);
  }

  void _sendErrorResponse(int id, String message) {
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': -32603,
        'message': message,
      },
    };
    stdout.writeln(jsonEncode(response));
  }

  Future<void> _keepAlive() async {
    // Keep the process running
    final completer = Completer<void>();

    // Handle process signals
    ProcessSignal.sigint.watch().listen((_) {
      _log('Received SIGINT, shutting down...');
      _shutdown();
      completer.complete();
    });

    ProcessSignal.sigterm.watch().listen((_) {
      _log('Received SIGTERM, shutting down...');
      _shutdown();
      completer.complete();
    });

    await completer.future;
  }

  void _shutdown() {
    _log('Shutting down MCP Bridge Server...');
    _reconnectTimer?.cancel();
    _stdinSubscription?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
  }

  void _log(String message) {
    if (verbose) {
      stderr.writeln('[MCP Bridge] $message');
    }
  }

  void _error(String message) {
    stderr.writeln('[MCP Bridge ERROR] $message');
  }
}

void main(List<String> arguments) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('host',
        abbr: 'h',
        defaultsTo: 'localhost',
        help: 'Host of the Flutter MCP server')
    ..addOption('port',
        abbr: 'p',
        defaultsTo: '3000',
        help: 'Port of the Flutter MCP server')
    ..addFlag('verbose',
        abbr: 'v',
        defaultsTo: false,
        help: 'Enable verbose logging to stderr')
    ..addFlag('help',
        defaultsTo: false,
        help: 'Show this help message');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      stderr.writeln('MCP Bridge Server - Bridge between Claude Desktop and Flutter MCP');
      stderr.writeln('\nUsage: dart run mcp_server.dart [options]');
      stderr.writeln('\nOptions:');
      stderr.writeln(parser.usage);
      exit(0);
    }

    final host = results['host'] as String;
    final port = int.parse(results['port'] as String);
    final verbose = results['verbose'] as bool;

    // Start the bridge server
    final server = MCPBridgeServer(
      host: host,
      port: port,
      verbose: verbose,
    );

    await server.start();

  } catch (e) {
    stderr.writeln('Error: $e');
    stderr.writeln('\nUsage: dart run mcp_server.dart [options]');
    stderr.writeln(parser.usage);
    exit(1);
  }
}