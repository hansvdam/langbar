import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Test client for MCP HTTP/SSE server
///
/// Usage: dart test_mcp_http_client.dart
///
/// This client demonstrates:
/// 1. Connecting to SSE endpoint for notifications
/// 2. Sending RPC requests over HTTP POST
/// 3. Proper session management
class MCPHttpTestClient {
  final String baseUrl;
  String? sessionId;
  HttpClient? sseClient;

  MCPHttpTestClient({this.baseUrl = 'http://localhost:3001'});

  /// Connect to SSE endpoint and listen for notifications
  Future<void> connectSSE() async {
    print('🔄 Connecting to SSE endpoint...');

    sseClient = HttpClient();
    final request = await sseClient!.getUrl(Uri.parse('$baseUrl/mcp/events'));

    // Add Last-Event-ID header if we have a session (for reconnection)
    if (sessionId != null) {
      request.headers.add('Last-Event-ID', sessionId!);
    }

    final response = await request.close();

    if (response.statusCode != 200) {
      print('❌ SSE connection failed: ${response.statusCode}');
      return;
    }

    // Extract session ID from header
    final headers = response.headers;
    sessionId = headers.value('X-Session-ID');
    print('✅ SSE connected! Session ID: $sessionId');

    // Listen to SSE stream
    response.transform(utf8.decoder).listen((data) {
      // Parse SSE format
      for (final line in data.split('\n')) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr.isNotEmpty) {
            try {
              final json = jsonDecode(jsonStr);
              print('📨 SSE Event: $json');
            } catch (e) {
              // Not JSON, might be plain text
              print('📨 SSE Data: $jsonStr');
            }
          }
        } else if (line.startsWith('event: ')) {
          print('📨 SSE Event Type: ${line.substring(7)}');
        } else if (line.startsWith('id: ')) {
          print('📨 SSE Event ID: ${line.substring(4)}');
        } else if (line == ':ping') {
          print('🏓 Received keep-alive ping');
        }
      }
    }, onError: (error) {
      print('❌ SSE error: $error');
    }, onDone: () {
      print('🔌 SSE connection closed');
    });
  }

  /// Send JSON-RPC request
  Future<dynamic> sendRPCRequest(String method, [Map<String, dynamic>? params]) async {
    if (sessionId == null) {
      print('❌ No session ID. Connect to SSE first!');
      return null;
    }

    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params ?? {},
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    print('📤 Sending RPC: $method');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mcp/rpc'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId!,
        },
        body: jsonEncode(request),
      );

      final json = jsonDecode(response.body);

      if (json['error'] != null) {
        print('❌ RPC Error: ${json['error']}');
        return null;
      }

      print('✅ RPC Response received');
      return json['result'];
    } catch (e) {
      print('❌ RPC request failed: $e');
      return null;
    }
  }

  /// Initialize MCP session
  Future<void> initialize() async {
    final result = await sendRPCRequest('initialize', {
      'protocolVersion': '2024-11-05',
      'clientInfo': {
        'name': 'MCP HTTP Test Client',
        'version': '1.0.0',
      },
    });

    if (result != null) {
      print('✅ Initialized: $result');
    }
  }

  /// Get list of available tools
  Future<void> listTools() async {
    final result = await sendRPCRequest('tools/list');

    if (result != null) {
      final tools = result['tools'] as List;
      print('📋 Available tools: ${tools.length}');
      for (final tool in tools) {
        print('  - ${tool['name']}: ${tool['description']}');
      }
    }
  }

  /// Call a tool
  Future<void> callTool(String toolName, Map<String, dynamic> args) async {
    final result = await sendRPCRequest('tools/call', {
      'name': toolName,
      'arguments': args,
    });

    if (result != null) {
      print('🔧 Tool result: $result');
    }
  }

  /// Get list of resources
  Future<void> listResources() async {
    final result = await sendRPCRequest('resources/list');

    if (result != null) {
      final resources = result['resources'] as List;
      print('📚 Available resources: ${resources.length}');
      for (final resource in resources) {
        print('  - ${resource['uri']}: ${resource['name']}');
      }
    }
  }

  /// Read a resource
  Future<void> readResource(String uri) async {
    final result = await sendRPCRequest('resources/read', {'uri': uri});

    if (result != null) {
      print('📖 Resource content: $result');
    }
  }

  /// Ping to check connection
  Future<void> ping() async {
    final result = await sendRPCRequest('ping');
    print('🏓 Ping response: $result');
  }

  /// Close connections
  void close() {
    sseClient?.close();
    print('👋 Client closed');
  }
}

void main() async {
  print('🚀 MCP HTTP Test Client');
  print('=' * 50);

  final client = MCPHttpTestClient();

  try {
    // 1. Connect to SSE for notifications
    await client.connectSSE();

    // Give SSE time to establish
    await Future.delayed(Duration(seconds: 1));

    // 2. Initialize session
    await client.initialize();

    // 3. List available tools
    await client.listTools();

    // 4. List available resources
    await client.listResources();

    // 5. Read a resource
    await client.readResource('/current-screen');

    // 6. Call a tool (example: navigate to home)
    await client.callTool('navigate_to_screen', {'path': '/home'});

    // 7. Ping to check connection
    await client.ping();

    // Keep connection open to receive notifications
    print('\n📡 Listening for notifications (press Ctrl+C to exit)...\n');

    // Keep the program running
    await Future.delayed(Duration(hours: 1));

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}