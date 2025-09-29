import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'resource_provider.dart';
import '../../ui/cubits/current_screen_cubit.dart';
import '../../logger_utils.dart';

class CurrentScreenResource extends MCPResourceProvider {
  @override
  Future<Map<String, dynamic>> read(BuildContext? context) async {
    try {
      final getIt = GetIt.instance;

      // Check if CurrentScreenCubit is registered
      if (!getIt.isRegistered<CurrentScreenCubit>()) {
        return {
          'error': 'CurrentScreenCubit not available',
          'currentPath': null,
          'previousPath': null,
          'hasViewModel': false,
        };
      }

      final currentScreenCubit = getIt<CurrentScreenCubit>();
      final state = currentScreenCubit.state;

      // Get current ViewModel information if available
      Map<String, dynamic>? viewModelInfo;
      if (state.currentPath != null) {
        final vm = currentScreenCubit.getViewModel(state.currentPath!);
        if (vm != null) {
          viewModelInfo = {
            'type': vm.runtimeType.toString(),
            'state': vm.state?.toString() ?? 'null',
          };
        }
      }

      return {
        'currentPath': state.currentPath,
        'previousPath': state.previousPath,
        'hasScreenChanged': state.hasScreenChanged,
        'viewModel': viewModelInfo,
        'registeredPaths': currentScreenCubit.getAllRegisteredPaths(),
      };
    } catch (e) {
      logger.e('Error reading current screen resource: $e');
      return {
        'error': e.toString(),
        'currentPath': null,
        'previousPath': null,
        'hasViewModel': false,
      };
    }
  }
}