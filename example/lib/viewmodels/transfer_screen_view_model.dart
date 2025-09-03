import 'package:flutter/material.dart';
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/send_to_llm.dart';

class TransferScreenState {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;

  TransferScreenState({
    this.amount,
    this.destinationName,
    this.description,
    required this.fromAccountId,
  });

  TransferScreenState copyWith({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
  }) {
    return TransferScreenState(
      amount: amount ?? this.amount,
      destinationName: destinationName ?? this.destinationName,
      description: description ?? this.description,
      fromAccountId: fromAccountId ?? this.fromAccountId,
    );
  }
}

class TransferScreenViewModel extends GenericScreenViewModel<TransferScreenState> {
  TransferScreenViewModel({
    required BuildContext context,
    double? amount,
    String? destinationName,
    String? description,
    String fromAccountId = "1",
  }) : super(
          TransferScreenState(
            amount: amount,
            destinationName: destinationName,
            description: description,
            fromAccountId: fromAccountId,
          ),
          context: context,
        ) {
    langbarLogger.i('TransferScreenViewModel created with amount: $amount, destinationName: $destinationName, description: $description, fromAccountId: $fromAccountId');
  }

  void updateAmount(double? amount) {
    langbarLogger.i('TransferScreenViewModel updating amount from ${state.amount} to $amount');
    emit(state.copyWith(amount: amount));
  }

  void updateDestinationName(String? destinationName) {
    langbarLogger.i('TransferScreenViewModel updating destinationName from ${state.destinationName} to $destinationName');
    emit(state.copyWith(destinationName: destinationName));
  }

  void updateDescription(String? description) {
    langbarLogger.i('TransferScreenViewModel updating description from ${state.description} to $description');
    emit(state.copyWith(description: description));
  }

  void updateFromAccountId(String fromAccountId) {
    langbarLogger.i('TransferScreenViewModel updating fromAccountId from ${state.fromAccountId} to $fromAccountId');
    emit(state.copyWith(fromAccountId: fromAccountId));
  }

  /// Update the ViewModel with new route parameters
  void updateFromRouteParams({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
  }) {
    langbarLogger.i('TransferScreenViewModel updating from route params: amount=$amount, destinationName=$destinationName, description=$description, fromAccountId=$fromAccountId');
    
    emit(state.copyWith(
      amount: amount,
      destinationName: destinationName,
      description: description,
      fromAccountId: fromAccountId,
    ));
  }

  @override
  void maybeAddInitialMessageToChatHistory() {
    // Add any initial context message for the transfer screen if needed
    // For now, we'll keep it empty to let the conversation flow naturally
  }

  @override
  List<KeyWordtrigger> getKeyWordHandlers(BuildContext context) {
    // Return empty list for now - can add transfer-specific keywords later
    return [];
  }
}