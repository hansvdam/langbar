import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'resource_provider.dart';
import '../../ui/langfield/langbar_states.dart';
import '../../logger_utils.dart';

class ConversationResource extends MCPResourceProvider {
  @override
  Future<Map<String, dynamic>> read(BuildContext? context) async {
    if (context == null) {
      return {
        'error': 'Context not available',
        'messages': [],
      };
    }

    try {
      // Try to get ChatHistory from provider
      final chatHistory = context.read<ChatHistory?>();

      if (chatHistory == null) {
        return {
          'messages': [],
          'count': 0,
        };
      }

      // Convert messages to JSON-serializable format
      final messages = chatHistory.items.map((msg) => {
        'role': msg.isHuman ? 'user' : 'assistant',
        'content': msg.text,
        'navUri': msg.navUri,
      }).toList();

      return {
        'messages': messages,
        'count': messages.length,
      };
    } catch (e) {
      logger.e('Error reading conversation history: $e');
      return {
        'error': e.toString(),
        'messages': [],
      };
    }
  }
}