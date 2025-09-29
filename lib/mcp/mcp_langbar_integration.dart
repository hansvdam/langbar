import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'mcp_server.dart';
import 'tool_registry.dart';
import '../documented_route.dart';
import '../ui/cubits/current_screen_cubit.dart';
import '../ui/cubits/generic_screen_view_model.dart';
import '../logger_utils.dart';
import 'converters/route_tool_converter.dart';
import 'resources/gui_events_resource.dart';

class MCPLangbarIntegration {
  static MCPLangbarIntegration? _instance;
  static MCPLangbarIntegration get instance => _instance ??= MCPLangbarIntegration._();

  MCPServer? _server;
  MCPToolRegistry? _toolRegistry;
  bool _isInitialized = false;

  MCPLangbarIntegration._();

  bool get isInitialized => _isInitialized;
  MCPServer? get server => _server;
  MCPToolRegistry? get toolRegistry => _toolRegistry;

  /// Initialize the MCP integration with Langbar
  Future<void> initialize({
    MCPConfiguration? configuration,
    List<RouteBase>? routes,
  }) async {
    if (_isInitialized) {
      logger.w('MCP integration already initialized');
      return;
    }

    try {
      // Create tool registry
      _toolRegistry = MCPToolRegistry();

      // Register route tools if provided
      if (routes != null) {
        _registerRouteTools(routes);
      }

      // Create and configure MCP server
      final config = configuration ?? MCPConfiguration();
      _server = MCPServer(
        configuration: config,
        toolRegistry: _toolRegistry!,
      );

      // Register with dependency injection
      _registerWithGetIt();

      // Set up listeners
      _setupListeners();

      _isInitialized = true;
      logger.i('MCP Langbar integration initialized successfully');
    } catch (e) {
      logger.e('Error initializing MCP integration: $e');
      rethrow;
    }
  }

  void _registerRouteTools(List<RouteBase> routes) {
    final documentedRoutes = <DocumentedGoRoute>[];

    void extractDocumentedRoutes(List<RouteBase> routeList) {
      for (final route in routeList) {
        // Check if it's a DocumentedGoRoute
        if (route is DocumentedGoRoute) {
          documentedRoutes.add(route);
        }

        // Handle StatefulShellRoute by iterating through its branches
        if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            extractDocumentedRoutes(branch.routes);
          }
        }

        // Handle regular GoRoute and its nested routes
        if (route is GoRoute && route.routes.isNotEmpty) {
          extractDocumentedRoutes(route.routes);
        }
      }
    }

    extractDocumentedRoutes(routes);
    _toolRegistry!.registerRouteTools(documentedRoutes);
    logger.i('Registered ${documentedRoutes.length} route tools with MCP');
  }

  void _registerWithGetIt() {
    final getIt = GetIt.instance;

    // Register MCP server and tool registry
    if (!getIt.isRegistered<MCPServer>()) {
      getIt.registerSingleton<MCPServer>(_server!);
    }

    if (!getIt.isRegistered<MCPToolRegistry>()) {
      getIt.registerSingleton<MCPToolRegistry>(_toolRegistry!);
    }
  }

  void _setupListeners() {
    // Listen for tool registry changes
    _toolRegistry!.addChangeListener(() {
      _server?.notifyToolsChanged();
    });

    // Listen for CurrentScreenCubit changes if available
    try {
      final currentScreenCubit = GetIt.instance<CurrentScreenCubit>();
      currentScreenCubit.stream.listen((state) {
        _onScreenChanged(state);
      });
    } catch (e) {
      logger.d('CurrentScreenCubit not available for MCP integration');
    }
  }

  void _onScreenChanged(CurrentScreenState state) {
    if (state.currentPath != null) {
      // Record navigation event
      GuiEventsResource().recordNavigation(
        state.previousPath ?? 'unknown',
        state.currentPath!,
        null,
      );

      // Update ViewModel tools if available
      final vm = GetIt.instance<CurrentScreenCubit>().getViewModel(state.currentPath!);
      if (vm != null) {
        updateViewModelTools(vm);
      }
    }
  }

  /// Update tools based on current ViewModel
  void updateViewModelTools(dynamic viewModel, [BuildContext? context]) {
    if (_toolRegistry == null) return;

    try {
      if (context != null && viewModel is GenericScreenViewModel) {
        _toolRegistry!.updateViewModelTools(viewModel, context);
        logger.d('Updated MCP tools for ViewModel: ${viewModel.runtimeType}');
      }
    } catch (e) {
      logger.e('Error updating ViewModel tools for MCP: $e');
    }
  }

  /// Start the MCP server
  Future<void> startServer() async {
    if (_server == null) {
      throw StateError('MCP integration not initialized');
    }

    await _server!.start();
  }

  /// Stop the MCP server
  Future<void> stopServer() async {
    await _server?.stop();
  }

  /// Register a keyword handler
  void registerKeywordHandler(String pattern, Function handler) {
    _toolRegistry?.registerKeywordTool(pattern, handler);
  }

  /// Record a GUI event
  void recordEvent(String type, String description, [Map<String, dynamic>? data]) {
    GuiEventsResource().recordEvent(GuiEvent(
      type: type,
      description: description,
      data: data,
    ));
  }

  /// Clean up resources
  void dispose() {
    _server?.stop();
    _toolRegistry?.clearAll();
    _isInitialized = false;
    _instance = null;
  }
}

/// Extension to make it easy to use MCP from BuildContext
extension MCPContextExtension on BuildContext {
  MCPLangbarIntegration get mcp => MCPLangbarIntegration.instance;

  void updateMCPTools(dynamic viewModel) {
    MCPLangbarIntegration.instance.updateViewModelTools(viewModel, this);
  }
}