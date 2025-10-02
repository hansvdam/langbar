import 'package:flutter/material.dart';
import '../ui/cubits/generic_screen_view_model.dart';
import '../logger_utils.dart';
import 'converters/viewmodel_tool_converter.dart';

abstract class MCPTool {
  String get name;
  String get description;
  Map<String, dynamic> get parameters;

  Map<String, dynamic> toMCPSchema() {
    return {
      'name': name,
      'description': description,
      'inputSchema': {
        'type': 'object',
        'properties': parameters,
        'required': parameters.entries
            .where((e) => e.value['required'] == true)
            .map((e) => e.key)
            .toList(),
      },
    };
  }

  Future<dynamic> execute(Map<String, dynamic> params, BuildContext? context);
}

class MCPToolImpl extends MCPTool {
  @override
  final String name;
  @override
  final String description;
  @override
  final Map<String, dynamic> parameters;
  final Function(Map<String, dynamic> params, BuildContext? context)? executionHandler;

  MCPToolImpl({
    required this.name,
    required this.description,
    required this.parameters,
    this.executionHandler,
  });

  @override
  Future<dynamic> execute(Map<String, dynamic> params, BuildContext? context) async {
    if (executionHandler != null) {
      return await executionHandler!(params, context);
    }
    throw UnimplementedError('Tool $name does not have an execution handler');
  }
}

class MCPToolRegistry {
  final Map<String, MCPTool> _tools = {};

  // Observers for tool changes
  final List<Function()> _changeListeners = [];

  void addChangeListener(Function() listener) {
    _changeListeners.add(listener);
  }

  void removeChangeListener(Function() listener) {
    _changeListeners.remove(listener);
  }

  void _notifyChanges() {
    for (final listener in _changeListeners) {
      listener();
    }
  }

  /// Update all tools from the current ViewModel
  void updateTools(GenericScreenViewModel viewModel, BuildContext context) {
    logger.d('Starting tool update for ViewModel: ${viewModel.runtimeType}');

    // Clear all existing tools
    _tools.clear();
    logger.d('Cleared existing tools');

    // Get ALL tools from ViewModel (includes routes, keywords, and ViewModel-specific)
    try {
      logger.d('Attempting to get tools from ViewModel...');
      final tools = viewModel.getTools(context);
      logger.d('Got ${tools.length} tools from ViewModel ${viewModel.runtimeType}');

      for (final tool in tools) {
        final mcpTool = ViewModelToolConverter.convert(tool);
        _tools[mcpTool.name] = mcpTool;
        logger.d('Converted tool: ${tool.name} to MCP tool');
      }

      logger.d('Updated tools: ${_tools.length} total tools from ViewModel');

      // Notify listeners about the change
      logger.d('Notifying listeners about tool changes...');
      _notifyChanges();
      logger.d('Notification complete');
    } catch (e, stackTrace) {
      // Check if this is the Provider lifecycle error we expect during construction
      if (e.toString().contains('Tried to listen to an InheritedWidget') ||
          e.toString().contains('life-cycle that will never be called again')) {
        logger.d('Provider lifecycle error during construction - tools will be updated after frame');
      } else {
        logger.e('Error updating tools from ViewModel: $e');
        logger.e('Stack trace: $stackTrace');
      }

      // Even if there's an error getting tools, notify listeners that tools have changed (cleared)
      logger.d('Notifying listeners despite error...');
      _notifyChanges();
    }
  }

  MCPTool? getTool(String name) {
    return _tools[name];
  }

  List<MCPTool> getAllTools() {
    return _tools.values.toList();
  }

  void clearAll() {
    _tools.clear();
    _notifyChanges();
  }

  Map<String, dynamic> getStatistics() {
    return {
      'total': _tools.length,
    };
  }
}