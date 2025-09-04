import 'package:flutter/material.dart';
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';

class MapScreenState {
  final String selectedLocation;

  MapScreenState({required this.selectedLocation});

  MapScreenState copyWith({String? selectedLocation}) {
    return MapScreenState(
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }
}

class MapScreenViewModel extends GenericScreenViewModel<MapScreenState> {
  MapScreenViewModel({required BuildContext context, String? initialLocation})
      : super(MapScreenState(selectedLocation: initialLocation ?? 'atms'),
            context: context) {
    langbarLogger.i(
        'MapScreenViewModel created with initialLocation: $initialLocation, final selectedLocation: ${state.selectedLocation}');
  }

  void updateSelectedLocation(String location) {
    langbarLogger.i(
        'MapScreenViewModel updating selectedLocation from ${state.selectedLocation} to $location');
    emit(state.copyWith(selectedLocation: location));
    langbarLogger.i(
        'MapScreenViewModel new state selectedLocation: ${state.selectedLocation}');
  }
}
