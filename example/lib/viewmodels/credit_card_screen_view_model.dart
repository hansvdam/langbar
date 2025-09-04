import 'package:flutter/material.dart';
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';

enum ActionOnCard {
  cancel,
  replace,
  none;

  static ActionOnCard? fromString(String? title) {
    return ActionOnCard.values.firstWhere((element) => element.name == title,
        orElse: () => ActionOnCard.none);
  }
}

class CreditCardScreenState {
  final ActionOnCard action;
  final int? limit;
  final bool initial;

  CreditCardScreenState({
    required this.action,
    this.limit,
    this.initial = true,
  });

  CreditCardScreenState copyWith({
    ActionOnCard? action,
    int? limit,
    bool? initial,
  }) {
    return CreditCardScreenState(
      action: action ?? this.action,
      limit: limit ?? this.limit,
      initial: initial ?? this.initial,
    );
  }
}

class CreditCardScreenViewModel
    extends GenericScreenViewModel<CreditCardScreenState> {
  CreditCardScreenViewModel({
    required BuildContext context,
    ActionOnCard? initialAction,
    int? initialLimit,
  }) : super(
          CreditCardScreenState(
            action: initialAction ?? ActionOnCard.none,
            limit: initialLimit,
            initial: true,
          ),
          context: context,
        );

  void updateAction(ActionOnCard action) {
    emit(state.copyWith(action: action, initial: false));
  }

  void updateLimit(int? limit) {
    emit(state.copyWith(limit: limit, initial: false));
  }

  void markAsNotInitial() {
    emit(state.copyWith(initial: false));
  }
}
