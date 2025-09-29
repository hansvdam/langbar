import 'package:flutter_bloc/flutter_bloc.dart';

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
  CurrentScreenCubit() : super(const CurrentScreenState());

  /// Called by your Navigator/GoRouter observer on push/pop/replace.
  void setCurrentPath(String? path) {
    print("setting current path to ${path ?? '(null)'}");
    final previousPath = state.currentPath;
    emit(state.copyWith(
      currentPath: path,
      previousPath: previousPath,
    ));
  }

  /// Attach/register a VM for a path. Safe to call multiple times.
  void registerVmForPath(String path, ScreenVM viewModel) {
    print("registering VM for path to $path");
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
  void pushCurrentCubit(ScreenVM vm) {
    registerVmForPath(state.currentPath ?? '/', vm);
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
