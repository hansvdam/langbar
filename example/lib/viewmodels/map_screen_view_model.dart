import 'package:flutter/material.dart';
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';

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
      : super(
          MapScreenState(selectedLocation: initialLocation ?? 'atms'), 
          context: context
        );

  void updateSelectedLocation(String location) {
    emit(state.copyWith(selectedLocation: location));
  }
}