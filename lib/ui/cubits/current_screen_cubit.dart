import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../mcp/mcp_integration_interface.dart';
import 'generic_screen_view_model.dart';

/// If you have a base class for your screen VMs, prefer using it instead of Cubit.
typedef ScreenVM = Cubit<dynamic>;

class CurrentScreenState {
  final String? currentPath; // e.g. "/inbox/42"
  final Map<String, ScreenVM> vmByPath; // persistent mapping
  final String? previousPath; // track previous path to detect screen changes

  const CurrentScreenState({
    this.currentPath,
    this.vmByPath = const {},
    this.previousPath,
  });

  /// Convenience: the VM for the currentPath (if any)
  ScreenVM? get currentViewModel =>
      (currentPath == null) ? null : vmByPath[currentPath!];

  /// Get the previous ViewModel based on the previous path
  ScreenVM? get previousViewModel =>
      (previousPath == null) ? null : vmByPath[previousPath!];

  bool get hasScreenChanged =>
      previousPath != currentPath;

  CurrentScreenState copyWith({
    String? currentPath,
    Map<String, ScreenVM>? vmByPath,
    String? previousPath,
  }) =>
      CurrentScreenState(
        currentPath: currentPath ?? this.currentPath,
        vmByPath: vmByPath ?? this.vmByPath,
        previousPath: previousPath ?? this.previousPath,
      );
}

class CurrentScreenCubit extends Cubit<CurrentScreenState> {
  BuildContext? _lastContext;

  CurrentScreenCubit() : super(const CurrentScreenState());

  /// Called by your Navigator/GoRouter observer on push/pop/replace.
  void setCurrentPath(String? path, {BuildContext? context}) {
    print("setting current path to ${path ?? '(null)'}");
    final previousPath = state.currentPath;

    // Store the context for later use
    if (context != null) {
      _lastContext = context;
    }

    emit(state.copyWith(
      currentPath: path,
      previousPath: previousPath,
    ));

    // If we're switching to a path that already has a viewmodel registered,
    // update MCP tools for that viewmodel
    if (path != null && state.vmByPath.containsKey(path)) {
      final viewModel = state.vmByPath[path];
      if (viewModel is GenericScreenViewModel) {
        _updateMCPToolsForViewModel(viewModel, context ?? _lastContext);
      }
    }
  }

  /// Update MCP tools for a specific viewmodel
  void _updateMCPToolsForViewModel(GenericScreenViewModel viewModel, BuildContext? context) {
    if (context == null) return;

    try {
      // Try to get MCP integration if it's registered
      final getIt = GetIt.instance;

      if (getIt.isRegistered<MCPIntegrationInterface>()) {
        final mcpIntegration = getIt.get<MCPIntegrationInterface>();
        print('🎯 Updating MCP tools for existing VM: ${viewModel.runtimeType}');
        mcpIntegration.updateTools(viewModel, context);
      }
    } catch (e) {
      // MCP not available, which is fine
      print('⚠️ Could not update MCP tools: $e');
    }
  }

  /// Attach/register a VM for a path. Safe to call multiple times.
  void registerVmForPath(String path, ScreenVM viewModel, {BuildContext? context}) {
    print("registering VM for path to $path");

    // Store the context for later use if provided
    if (context != null) {
      _lastContext = context;
    }

    final next = Map<String, ScreenVM>.from(state.vmByPath)..[path] = viewModel;
    emit(state.copyWith(vmByPath: next));
  }


  /// Remove a VM when its screen is disposed/popped.
  void unregisterVm(ScreenVM viewModel) {
    final next = Map<String, ScreenVM>.from(state.vmByPath)
      ..removeWhere((k, v) => identical(v, viewModel));
    emit(state.copyWith(vmByPath: next));
  }

  // ---- Backward-compatible API (matches your error messages) ----
  void pushCurrentCubit(ScreenVM vm, {BuildContext? context}) {
    registerVmForPath(state.currentPath ?? '/', vm, context: context);
  }

  void removeCurrentCubit(ScreenVM vm) {
    unregisterVm(vm);
  }

  /// Optional helper if callers want the VM directly.
  ScreenVM? get currentCubit => state.currentViewModel;

  /// Get a ViewModel by its path
  ScreenVM? getViewModel(String path) {
    return state.vmByPath[path];
  }

  /// Get all registered paths
  List<String> getAllRegisteredPaths() {
    return state.vmByPath.keys.toList();
  }
}
