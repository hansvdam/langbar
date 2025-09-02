// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A proxy of the catalog of items the user can buy.
///
/// In a real app, this might be backed by a backend and cached on device.
/// In this sample app, the catalog is procedurally generated and infinite.
///
/// For simplicity, the catalog is expected to be immutable (no products are
/// expected to be added, removed or changed during the execution of the app).
class Space extends ChangeNotifier {
  final List<Ticket> _tickets = [];

  void add(Ticket item) {
    _tickets.add(item);
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }
}

class Ticket extends ChangeNotifier {}

enum BSSB { bakboord, stuurboord }

enum FRBK { voor, achter }

class FormProperty<T> extends ValueNotifier<T> {
  String name;

  FormProperty(this.name, super.value);
}

class Avery extends Ticket {
  List<FormProperty> parameters = [
    FormProperty('bakboord_of_stuurboord', BSSB.bakboord),
    FormProperty('voor_of_achter', FRBK.voor),
  ];

  Avery() : super();
}
