// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'Space.dart';

class BSMap extends ChangeNotifier {
  /// The private field backing [currentSpace].
  late Space? _currentSpace;
  late Ticket? _currentTicket = Avery();

  /// Internal, private state of the cart. Stores the ids of each item.
  List<Space> _spaces = [];

  BSMap(this._spaces);

  /// The current catalog. Used to construct items from numeric ids.
  Space? get currentSpace => _currentSpace;

  Ticket? get currentTicket => _currentTicket;

  set currentSpace(Space? newCatalog) {
    _currentSpace = newCatalog;
    // Notify listeners, in case the new catalog provides information
    // different from the previous one. For example, availability of an item
    // might have changed.
    notifyListeners();
  }

  // /// The current total price of all items.
  // int get totalPrice =>
  //     tickets.fold(0, (total, current) => total + current.price);

  /// Adds [item] to cart. This is the only way to modify the cart from outside.
  void add(Ticket item) {
    _currentSpace?.add(item);
    // This line tells [Model] that it should rebuild the widgets that
    // depend on it.
    notifyListeners();
  }
}
