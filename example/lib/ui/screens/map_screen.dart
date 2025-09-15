import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/tts_highlight_service.dart';

import 'default_appbar_scaffold.dart';
import '../../viewmodels/map_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';

class MapScreen extends StatelessWidget {
  final String label;
  final String? atmOrOffice;

  MapScreen({required this.label, super.key, this.atmOrOffice}) {
    langbarLogger.d(
        'MapScreen constructor called with label: $label, atmOrOffice: $atmOrOffice');
  }

  static const name = 'map';

  @override
  Widget build(BuildContext context) {
    langbarLogger.d(
        'MapScreen build() called, about to create MapScreenViewModel with atmOrOffice: $atmOrOffice');
    return BlocProvider(
      key: ValueKey(
          'map_screen_$atmOrOffice'), // Force new instance when parameter changes
      create: (context) {
        langbarLogger.d('BlocProvider create() called for MapScreenViewModel');
        return MapScreenViewModel(
          context: context,
          initialLocation: atmOrOffice,
        );
      },
      child: Builder(builder: (context) {
        // Update ViewModel when parameters change
        context.read<MapScreenViewModel>().updateFromConstructorParams(
          atmOrOffice: atmOrOffice,
        );
        
        return BlocBuilder<MapScreenViewModel, MapScreenState>(
          builder: (context, state) {
            langbarLogger.d(
                'BlocBuilder rebuilding with state.selectedLocation: ${state.selectedLocation}');
            return DefaultAppbarScaffold(
              label: label,
              body: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: TtsHighlightWrapper(
                            fieldId: 'location_atms',
                            child: RadioListTile<String>(
                              title: const Text('ATMs'),
                              value: 'atms',
                              groupValue: state.selectedLocation,
                              onChanged: (String? value) {
                                if (value != null) {
                                  context
                                      .read<MapScreenViewModel>()
                                      .updateSelectedLocation(value, isManual: true);
                                }
                              },
                            ),
                          ),
                        ),
                        Flexible(
                          child: TtsHighlightWrapper(
                            fieldId: 'location_offices',
                            child: RadioListTile<String>(
                              title: const Text('Offices'),
                              value: 'offices',
                              groupValue: state.selectedLocation,
                              onChanged: (String? value) {
                                if (value != null) {
                                  context
                                      .read<MapScreenViewModel>()
                                      .updateSelectedLocation(value, isManual: true);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Image(
                        image: AssetImage(
                            "assets/images/${state.selectedLocation == "atms" ? "atms.jpg" : "offices.jpg"}"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
