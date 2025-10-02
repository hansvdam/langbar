import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

void main() async {
  print('Connecting to MCP server at ws://localhost:3001/mcp...');

  final socket = await WebSocket.connect('ws://localhost:3001/mcp');
  final channel = IOWebSocketChannel(socket);
  final peer = json_rpc.Peer(channel.cast<String>());

  // Set up notification handler
  peer.registerMethod('notifications/tools/list_changed', (params) {
    print('📢 Received tools/list_changed notification!');
    print('   Fetching updated tool list...');

    // Request the updated tool list
    peer.sendRequest('tools/list', {}).then((result) {
      print('📋 Updated tools:');
      final tools = result['tools'] as List;
      for (var tool in tools) {
        print('   - ${tool['name']}: ${tool['description']}');
      }
      print('   Total tools: ${tools.length}');
    });
  });

  // Start listening
  peer.listen();

  print('Initializing MCP session...');

  // Initialize
  final initResult = await peer.sendRequest('initialize', {
    'protocolVersion': '2024-11-05',
    'clientInfo': {
      'name': 'Test MCP Client',
      'version': '1.0.0',
    },
  });

  print('✅ Initialized with server: ${initResult['serverInfo']['name']} v${initResult['serverInfo']['version']}');
  print('   Protocol version: ${initResult['protocolVersion']}');
  print('   Capabilities: ${initResult['capabilities']}');

  // Get initial tools
  final toolsResult = await peer.sendRequest('tools/list', {});
  final tools = toolsResult['tools'] as List;

  print('\n📋 Initial tools:');
  if (tools.isEmpty) {
    print('   No tools available yet (waiting for ViewModel to be active)');
  } else {
    for (var tool in tools) {
      print('   - ${tool['name']}: ${tool['description']}');
    }
  }

  print('\n👂 Listening for tool updates...');
  print('   Navigate between screens in the Flutter app to trigger tool updates');
  print('   Press Ctrl+C to exit\n');

  // Keep the client running
  await Future.delayed(Duration(hours: 1));
}