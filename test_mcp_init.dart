#!/usr/bin/env dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

void main() async {
  print('Connecting to MCP server at ws://localhost:3001/mcp...');

  try {
    // Connect to the MCP server
    final uri = Uri.parse('ws://localhost:3001/mcp');
    final channel = WebSocketChannel.connect(uri);

    // Create JSON-RPC peer
    final peer = json_rpc.Peer(channel.cast<String>());

    // Start listening
    final listenFuture = peer.listen();

    print('Connected! Sending initialize request...');

    // Send initialize request
    final initResult = await peer.sendRequest('initialize', {
      'protocolVersion': '2024-11-05',
      'clientInfo': {
        'name': 'Test Client',
        'version': '1.0.0',
      },
    });

    print('Initialize response: ${jsonEncode(initResult)}');

    // List tools
    print('\nListing tools...');
    final toolsResult = await peer.sendRequest('tools/list', {});
    final tools = toolsResult['tools'] as List;
    print('Available tools (${tools.length}):');
    for (final tool in tools) {
      print('  - ${tool['name']}: ${tool['description']}');
    }

    // Wait a bit to see if we get notifications
    print('\nWaiting for notifications...');
    await Future.delayed(const Duration(seconds: 5));

    // Close connection
    print('Closing connection...');
    await peer.close();
    await listenFuture;

  } catch (e, stack) {
    print('Error: $e');
    print('Stack: $stack');
  }
}