import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  /// Initialize with the app's context and router
  void initialize(BuildContext context, GoRouter router) {
    _context = context;
    _router = router;
    logger.i('MCPNavigationHandler initialized');
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