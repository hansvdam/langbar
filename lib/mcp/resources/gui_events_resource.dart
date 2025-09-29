import 'package:flutter/material.dart';
import 'resource_provider.dart';
import '../../logger_utils.dart';

class GuiEvent {
  final String type;
  final String description;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  GuiEvent({
    required this.type,
    required this.description,
    this.data,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

class GuiEventsResource extends MCPResourceProvider {
  static final GuiEventsResource _instance = GuiEventsResource._internal();
  factory GuiEventsResource() => _instance;
  GuiEventsResource._internal();

  final List<GuiEvent> _events = [];
  static const int _maxEvents = 50;

  void recordEvent(GuiEvent event) {
    _events.add(event);
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
    logger.d('GUI Event recorded: ${event.type} - ${event.description}');
  }

  void recordNavigation(String from, String to, Map<String, dynamic>? params) {
    recordEvent(GuiEvent(
      type: 'navigation',
      description: 'Navigated from $from to $to',
      data: {
        'from': from,
        'to': to,
        'parameters': params,
      },
    ));
  }

  void recordAction(String action, Map<String, dynamic>? data) {
    recordEvent(GuiEvent(
      type: 'action',
      description: action,
      data: data,
    ));
  }

  void recordToolCall(String toolName, Map<String, dynamic>? params, dynamic result) {
    recordEvent(GuiEvent(
      type: 'tool_call',
      description: 'Tool $toolName called',
      data: {
        'tool': toolName,
        'parameters': params,
        'result': result?.toString(),
      },
    ));
  }

  @override
  Future<Map<String, dynamic>> read(BuildContext? context) async {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'count': _events.length,
      'maxEvents': _maxEvents,
    };
  }

  void clear() {
    _events.clear();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}