import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'mcp_server.dart';
import 'tool_registry.dart';
import 'mcp_integration_interface.dart';
import '../ui/cubits/current_screen_cubit.dart';
import '../ui/cubits/generic_screen_view_model.dart';
import '../logger_utils.dart';
import 'resources/gui_events_resource.dart';

class MCPLangbarIntegration implements MCPIntegrationInterface {
  static MCPLangbarIntegration? _instance;
  static MCPLangbarIntegration get instance => _instance ??= MCPLangbarIntegration._();

  MCPServer? _server;
  MCPToolRegistry? _toolRegistry;
  bool _isInitialized = false;
  BuildContext? _context; // Store context for ViewModel tool updates

  MCPLangbarIntegration._();

  bool get isInitialized => _isInitialized;
  MCPServer? get server => _server;
  MCPToolRegistry? get toolRegistry => _toolRegistry;

  /// Initialize the MCP integration with Langbar
  Future<void> initialize({
    MCPConfiguration? configuration,
    BuildContext? context,
  }) async {
    if (_isInitialized) {
      logger.w('MCP integration already initialized');
      return;
    }

    try {
      // Store context if provided
      _context = context;

      // Create tool registry
      _toolRegistry = MCPToolRegistry();

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


  void _registerWithGetIt() {
    final getIt = GetIt.instance;

    // Register MCP integration as interface type for ViewModels to access
    if (!getIt.isRegistered<MCPIntegrationInterface>()) {
      getIt.registerSingleton<MCPIntegrationInterface>(this);
      logger.d('Registered MCP integration with GetIt as MCPIntegrationInterface');
    }

    // Also register as concrete type for direct access if needed
    if (!getIt.isRegistered<MCPLangbarIntegration>()) {
      getIt.registerSingleton<MCPLangbarIntegration>(this);
      logger.d('Registered MCP integration with GetIt as MCPLangbarIntegration type');
    }

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
      logger.d('Tool registry changed, notifying MCP clients');
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
      final vm = state.currentViewModel;
      if (vm != null) {
        logger.d('Screen changed to ${state.currentPath}, updating MCP tools for ViewModel: ${vm.runtimeType}');
        // Use stored context (will be set by the app when it initializes MCP)
        updateViewModelTools(vm, _context);
      } else {
        logger.d('Screen changed to ${state.currentPath}, but no ViewModel found');
      }
    }
  }

  /// Update the BuildContext (should be called when context becomes available)
  void updateContext(BuildContext context) {
    _context = context;
    // Re-update tools if we have a current ViewModel
    try {
      final currentScreenCubit = GetIt.instance<CurrentScreenCubit>();
      final currentPath = currentScreenCubit.state.currentPath;
      if (currentPath != null) {
        final vm = currentScreenCubit.getViewModel(currentPath);
        if (vm != null && vm is GenericScreenViewModel) {
          updateViewModelTools(vm, context);
        }
      }
    } catch (e) {
      logger.d('Could not update tools after context change: $e');
    }
  }

  /// Update tools based on current ViewModel (alias for compatibility)
  @override
  void updateTools(dynamic viewModel, dynamic context) {
    updateViewModelTools(viewModel, context as BuildContext?);
  }

  /// Update tools based on current ViewModel
  void updateViewModelTools(dynamic viewModel, [BuildContext? context]) {
    if (_toolRegistry == null) return;

    // Use stored context if not provided
    final ctx = context ?? _context;
    if (ctx == null) {
      logger.w('Cannot update ViewModel tools without BuildContext');
      return;
    }

    try {
      if (viewModel is GenericScreenViewModel) {
        _toolRegistry!.updateTools(viewModel, ctx);
        // Get the tool names for logging
        final toolNames = _toolRegistry!.getAllTools().map((t) => t.name).toList();
        logger.d('Updated MCP tools for ViewModel: ${viewModel.runtimeType} - Tools: [${toolNames.join(', ')}]');
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