import 'package:flutter_bloc/flutter_bloc.dart';

/// If you have a base class for your screen VMs, prefer using it instead of Cubit.
typedef ScreenVM = Cubit<dynamic>;

class CurrentScreenState {
  final String? currentPath;                 // e.g. "/inbox/42"
  final Map<String, ScreenVM> vmByPath;      // persistent mapping

  const CurrentScreenState({
    this.currentPath,
    this.vmByPath = const {},
  });

  /// Convenience: the VM for the currentPath (if any)
  ScreenVM? get currentViewModel =>
      (currentPath == null) ? null : vmByPath[currentPath!];

  CurrentScreenState copyWith({
    String? currentPath,
    Map<String, ScreenVM>? vmByPath,
  }) =>
      CurrentScreenState(
        currentPath: currentPath ?? this.currentPath,
        vmByPath: vmByPath ?? this.vmByPath,
      );
}

class CurrentScreenCubit extends Cubit<CurrentScreenState> {
  CurrentScreenCubit() : super(const CurrentScreenState());

  /// Called by your Navigator/GoRouter observer on push/pop/replace.
  void setCurrentPath(String? path) {
    print("setting current path to ${path ?? '(null)'}");
    // Do NOT drop the map; just update the path. currentViewModel resolves via getter.
    emit(state.copyWith(currentPath: path));
  }

  /// Attach/register a VM for a path. Safe to call multiple times.
  void registerVmForPath(String path, ScreenVM viewModel) {
    print("setting current path to ${path ?? '(null)'}");
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
}