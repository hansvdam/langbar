import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'default_appbar_scaffold.dart';
import '../../viewmodels/map_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';

class MapScreen extends StatelessWidget {
  final String label;
  final String? atmOrOffice;

  MapScreen({required this.label, super.key, this.atmOrOffice}) {
    langbarLogger.d('MapScreen constructor called with label: $label, atmOrOffice: $atmOrOffice');
  }

  static const name = 'map';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapScreenViewModel(
        context: context,
        initialLocation: atmOrOffice,
      ),
      child: BlocBuilder<MapScreenViewModel, MapScreenState>(
        builder: (context, state) {
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
                        child: RadioListTile<String>(
                          title: const Text('ATMs'),
                          value: 'atms',
                          groupValue: state.selectedLocation,
                          onChanged: (String? value) {
                            if (value != null) {
                              context.read<MapScreenViewModel>().updateSelectedLocation(value);
                            }
                          },
                        ),
                      ),
                      Flexible(
                        child: RadioListTile<String>(
                          title: const Text('Offices'),
                          value: 'offices',
                          groupValue: state.selectedLocation,
                          onChanged: (String? value) {
                            if (value != null) {
                              context.read<MapScreenViewModel>().updateSelectedLocation(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Image(
                      image: AssetImage(
                        "assets/images/${state.selectedLocation == "atms" ? "atms.jpg" : "offices.jpg"}"
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}