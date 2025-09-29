import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import '../ui/cubits/generic_screen_view_model.dart';
import '../tools/generic_screen_tool.dart';
import '../documented_route.dart';
import '../data/for_langchain.dart' as langbar;
import '../logger_utils.dart';
import 'converters/route_tool_converter.dart';
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
  final Map<String, MCPTool> _routeTools = {};
  final Map<String, MCPTool> _viewModelTools = {};
  final Map<String, MCPTool> _keywordTools = {};

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

  void registerRouteTool(DocumentedGoRoute route) {
    try {
      final tool = RouteToolConverter.convert(route);
      _routeTools[tool.name] = tool;
      _tools[tool.name] = tool;
      logger.d('Registered route tool: ${tool.name}');
    } catch (e) {
      logger.e('Error registering route tool: $e');
    }
  }

  void registerRouteTools(List<DocumentedGoRoute> routes) {
    for (final route in routes) {
      registerRouteTool(route);
    }
    _notifyChanges();
  }

  void updateViewModelTools(GenericScreenViewModel viewModel, BuildContext context) {
    // Clear existing ViewModel tools
    _viewModelTools.clear();

    // Get tools from ViewModel
    try {
      final tools = viewModel.getTools(context);
      for (final tool in tools) {
        final mcpTool = ViewModelToolConverter.convert(tool);
        _viewModelTools[mcpTool.name] = mcpTool;
      }

      // Merge with route tools
      _rebuildToolsMap();
      _notifyChanges();

      logger.d('Updated ViewModel tools: ${_viewModelTools.length} tools');
    } catch (e) {
      logger.e('Error updating ViewModel tools: $e');
    }
  }

  void registerKeywordTool(String pattern, Function handler) {
    final tool = MCPToolImpl(
      name: 'keyword_${pattern.hashCode}',
      description: 'Direct keyword match for pattern: $pattern',
      parameters: {
        'input': {
          'type': 'string',
          'description': 'The user input to match against the pattern',
        },
      },
      executionHandler: (params, context) async {
        final input = params['input'] as String?;
        if (input != null && RegExp(pattern).hasMatch(input)) {
          return handler(input);
        }
        return null;
      },
    );

    _keywordTools[tool.name] = tool;
    _tools[tool.name] = tool;
    _notifyChanges();
  }

  void _rebuildToolsMap() {
    _tools.clear();
    _tools.addAll(_routeTools);
    _tools.addAll(_viewModelTools);
    _tools.addAll(_keywordTools);
  }

  MCPTool? getTool(String name) {
    return _tools[name];
  }

  List<MCPTool> getAllTools() {
    return _tools.values.toList();
  }

  List<MCPTool> getRouteTools() {
    return _routeTools.values.toList();
  }

  List<MCPTool> getViewModelTools() {
    return _viewModelTools.values.toList();
  }

  List<MCPTool> getKeywordTools() {
    return _keywordTools.values.toList();
  }

  void clearViewModelTools() {
    for (final toolName in _viewModelTools.keys) {
      _tools.remove(toolName);
    }
    _viewModelTools.clear();
    _notifyChanges();
  }

  void clearAll() {
    _tools.clear();
    _routeTools.clear();
    _viewModelTools.clear();
    _keywordTools.clear();
    _notifyChanges();
  }

  Map<String, dynamic> getStatistics() {
    return {
      'total': _tools.length,
      'routes': _routeTools.length,
      'viewModel': _viewModelTools.length,
      'keywords': _keywordTools.length,
    };
  }
}