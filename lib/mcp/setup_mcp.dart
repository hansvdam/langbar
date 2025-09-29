import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'mcp_server.dart';
import 'mcp_langbar_integration.dart';
import '../send_to_llm.dart';
import '../logger_utils.dart';
import 'resources/gui_events_resource.dart';

/// Setup function to initialize MCP server with Langbar
///
/// Example usage:
/// ```dart
/// await setupMCP(
///   routes: router.routes,
///   configuration: MCPConfiguration(
///     transport: MCPTransport.websocket,
///     port: 3000,
///   ),
/// );
/// ```
Future<void> setupMCP({
  required List<RouteBase> routes,
  MCPConfiguration? configuration,
  bool autoStart = true,
}) async {
  try {
    logger.i('Setting up MCP integration...');

    // Initialize MCP integration
    await MCPLangbarIntegration.instance.initialize(
      configuration: configuration,
      routes: routes,
    );

    // Register MCP recording function for tool calls
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<Function>(instanceName: 'mcpRecordToolCall')) {
      getIt.registerSingleton<Function>(
        (String toolName, Map<String, dynamic> params, dynamic result) {
          GuiEventsResource().recordToolCall(toolName, params, result);
        },
        instanceName: 'mcpRecordToolCall',
      );
    }

    // Enable MCP mode
    enableMCPMode(true);

    // Auto-start server if requested
    if (autoStart) {
      await MCPLangbarIntegration.instance.startServer();
    }

    logger.i('MCP setup completed successfully');
  } catch (e) {
    logger.e('Error setting up MCP: $e');
    rethrow;
  }
}

/// Convenience function to setup MCP with standard configuration
Future<void> setupMCPWithDefaults(List<RouteBase> routes) async {
  await setupMCP(
    routes: routes,
    configuration: MCPConfiguration(
      transport: MCPTransport.websocket,
      port: 3000,
      exposeRoutes: true,
      exposeViewModels: true,
      enableKeywordMatching: true,
    ),
  );
}

/// Stop the MCP server and cleanup
Future<void> stopMCP() async {
  await MCPLangbarIntegration.instance.stopServer();
  MCPLangbarIntegration.instance.dispose();
  enableMCPMode(false);
}

/// Check if MCP is currently running
bool isMCPRunning() {
  return MCPLangbarIntegration.instance.isInitialized &&
      MCPLangbarIntegration.instance.server?.isRunning == true;
}

/// Get MCP server statistics
Map<String, dynamic> getMCPStatistics() {
  if (!MCPLangbarIntegration.instance.isInitialized) {
    return {'status': 'not_initialized'};
  }

  final registry = MCPLangbarIntegration.instance.toolRegistry;
  final server = MCPLangbarIntegration.instance.server;

  return {
    'status': server?.isRunning == true ? 'running' : 'stopped',
    'tools': registry?.getStatistics() ?? {},
  };
}