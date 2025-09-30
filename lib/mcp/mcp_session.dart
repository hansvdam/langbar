import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'tool_registry.dart';
import 'resources/resource_provider.dart';
import 'resources/current_screen_resource.dart';
import 'resources/gui_events_resource.dart';
import 'resources/conversation_resource.dart';
import '../ui/cubits/current_screen_cubit.dart';
import '../ui/cubits/generic_screen_view_model.dart';
import '../logger_utils.dart';

class MCPSession {
  final String id;
  final MCPToolRegistry toolRegistry;
  final Map<String, MCPResourceProvider> _resourceProviders = {};

  bool _isInitialized = false;
  String? _protocolVersion;
  Map<String, dynamic>? _clientInfo;
  BuildContext? _context;

  MCPSession({
    required this.id,
    required this.toolRegistry,
    BuildContext? context,
  }) : _context = context {
    _initializeResourceProviders();
  }

  bool get isInitialized => _isInitialized;

  void _initializeResourceProviders() {
    // Initialize resource providers
    _resourceProviders['/current-screen'] = CurrentScreenResource();
    _resourceProviders['/last-gui-events'] = GuiEventsResource();
    _resourceProviders['/conversation-history'] = ConversationResource();
  }

  void initialize({
    required String protocolVersion,
    required Map<String, dynamic> clientInfo,
  }) {
    _isInitialized = true;
    _protocolVersion = protocolVersion;
    _clientInfo = clientInfo;

    logger.i('MCP Session $id initialized with protocol version: $protocolVersion');
    logger.d('Client info: $clientInfo');
  }

  void updateContext(BuildContext context) {
    _context = context;
    // Update tools based on new context
    _updateContextualTools();
  }

  void _updateContextualTools() {
    if (_context == null) return;

    // Get current screen cubit if available
    try {
      final currentScreenCubit = GetIt.instance<CurrentScreenCubit>();
      final currentPath = currentScreenCubit.state.currentPath;

      if (currentPath != null) {
        // Update tools based on current screen
        final currentVM = currentScreenCubit.getViewModel(currentPath);
        if (currentVM != null && currentVM is GenericScreenViewModel) {
          // Register ViewModel-specific tools
          toolRegistry.updateTools(currentVM, _context!);
        }
      }
    } catch (e) {
      logger.d('CurrentScreenCubit not available: $e');
    }
  }

  List<MCPTool> getTools() {
    return toolRegistry.getAllTools();
  }

  Future<dynamic> callTool(String toolName, Map<String, dynamic> params) async {
    final tool = toolRegistry.getTool(toolName);
    if (tool == null) {
      throw Exception('Tool not found: $toolName');
    }

    try {
      logger.d('Executing MCP tool: $toolName with params: $params');
      final result = await tool.execute(params, _context);
      logger.d('MCP tool $toolName executed successfully');
      return result;
    } catch (e) {
      logger.e('Error executing MCP tool $toolName: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> readResource(String uri) async {
    final provider = _resourceProviders[uri];
    if (provider == null) {
      throw Exception('Resource not found: $uri');
    }

    try {
      return await provider.read(_context);
    } catch (e) {
      logger.e('Error reading resource $uri: $e');
      rethrow;
    }
  }

  void dispose() {
    // Cleanup resources
    for (final provider in _resourceProviders.values) {
      provider.dispose();
    }
    _resourceProviders.clear();
    logger.i('MCP Session $id disposed');
  }
}