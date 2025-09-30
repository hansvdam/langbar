import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'mcp_server.dart';
import '../logger_utils.dart';

/// Global navigation handler for MCP server
///
/// This singleton maintains a reference to the current BuildContext
/// and GoRouter to enable navigation from MCP tool calls.
class MCPNavigationHandler {
  static final MCPNavigationHandler _instance = MCPNavigationHandler._internal();
  factory MCPNavigationHandler() => _instance;
  MCPNavigationHandler._internal();

  BuildContext? _context;
  GoRouter? _router;
  MCPWindowMode _windowMode = MCPWindowMode.showOnly;

  /// Initialize with the app's context and router
  void initialize(BuildContext context, GoRouter router, {MCPWindowMode? windowMode}) {
    _context = context;
    _router = router;
    if (windowMode != null) {
      _windowMode = windowMode;
    }
    logger.i('MCPNavigationHandler initialized with window mode: $_windowMode');
  }

  /// Set the window mode for navigation
  void setWindowMode(MCPWindowMode mode) {
    _windowMode = mode;
    logger.d('MCPNavigationHandler window mode set to: $_windowMode');
  }

  /// Update the context (call this when the main widget rebuilds)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Get the current context
  BuildContext? get context => _context;

  /// Check if navigation is available
  bool get canNavigate => _context != null && _router != null;

  /// Navigate to a named route with parameters
  Future<void> navigateTo(String routeName, Map<String, String> parameters) async {
    if (!canNavigate) {
      throw Exception('MCPNavigationHandler not initialized. Call initialize() first.');
    }

    try {
      logger.d('MCP Navigation: $routeName with params: $parameters');

      // Handle window visibility based on configuration
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        try {
          switch (_windowMode) {
            case MCPWindowMode.none:
              // No window management
              logger.d('Window mode: none - no window management');
              break;
            case MCPWindowMode.showOnly:
              // Show window without taking focus (visual-only update)
              await windowManager.show();
              // NOT calling windowManager.focus() - window visible but Claude keeps focus
              logger.d('Window shown without focus steal');
              break;
            case MCPWindowMode.showAndFocus:
              // Show window and take focus
              await windowManager.show();
              await windowManager.focus();
              logger.d('Window shown with focus');
              break;
          }
        } catch (e) {
          logger.w('Could not manage window: $e');
          // Continue with navigation even if window management fails
        }
      }

      // Use the stored router to navigate
      final location = _router!.namedLocation(
        routeName,
        pathParameters: {},
        queryParameters: parameters,
      );

      // Navigate on the main thread using the stored router
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_router != null) {
          _router!.go(location);
          logger.d('MCP Navigation executed: $location');
        }
      });

    } catch (e) {
      logger.e('MCP Navigation error: $e');
      rethrow;
    }
  }

  /// Clear the handler (call on dispose)
  void dispose() {
    _context = null;
    _router = null;
  }
}