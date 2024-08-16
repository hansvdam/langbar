import 'package:flutter/material.dart';

import 'models/Space.dart';

class AveryScreen extends StatelessWidget {
  final Avery avery = Avery();

  static var name = "averij";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avery Parameters'),
      ),
      body: ListView.builder(
        itemCount: avery.parameters.length,
        itemBuilder: (context, index) {
          final parameter = avery.parameters[index];
          return ListTile(
            title: Text(parameter.name),
            subtitle: Text(parameter.value.toString()),
          );
        },
      ),
    );
  }
}
