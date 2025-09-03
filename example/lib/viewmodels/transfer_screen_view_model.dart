import 'package:flutter/material.dart';
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/send_to_llm.dart';
import '../utils/name_matcher.dart';
import '../ui/models/account.dart';

class TransferScreenState {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;
  final Future<Contact?>? mostLikelyDestinationContactFuture;

  TransferScreenState({
    this.amount,
    this.destinationName,
    this.description,
    required this.fromAccountId,
    this.mostLikelyDestinationContactFuture,
  });

  TransferScreenState copyWith({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
    Future<Contact?>? mostLikelyDestinationContactFuture,
  }) {
    return TransferScreenState(
      amount: amount ?? this.amount,
      destinationName: destinationName ?? this.destinationName,
      description: description ?? this.description,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      mostLikelyDestinationContactFuture: mostLikelyDestinationContactFuture ?? this.mostLikelyDestinationContactFuture,
    );
  }
}

class TransferScreenViewModel extends GenericScreenViewModel<TransferScreenState> {
  final BuildContext _context;

  TransferScreenViewModel({
    required BuildContext context,
    double? amount,
    String? destinationName,
    String? description,
    String fromAccountId = "1",
  }) : _context = context, super(
          TransferScreenState(
            amount: amount,
            destinationName: destinationName,
            description: description,
            fromAccountId: fromAccountId,
            mostLikelyDestinationContactFuture: destinationName != null ? null : Future(() => null), // Will be set properly in _updateContactFuture
          ),
          context: context,
        ) {
    langbarLogger.i('TransferScreenViewModel created with amount: $amount, destinationName: $destinationName, description: $description, fromAccountId: $fromAccountId');
    _updateContactFuture();
  }

  void updateAmount(double? amount) {
    langbarLogger.i('TransferScreenViewModel updating amount from ${state.amount} to $amount');
    emit(state.copyWith(amount: amount));
  }

  void updateDestinationName(String? destinationName) {
    langbarLogger.i('TransferScreenViewModel updating destinationName from ${state.destinationName} to $destinationName');
    emit(state.copyWith(destinationName: destinationName));
    _updateContactFuture();
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
    _updateContactFuture();
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

  /// Update the contact lookup Future based on current destinationName
  void _updateContactFuture() {
    if (state.destinationName != null) {
      final future = _findMostLikelyDestinationContact(_context, state.destinationName!);
      emit(state.copyWith(mostLikelyDestinationContactFuture: future));
    } else {
      emit(state.copyWith(mostLikelyDestinationContactFuture: Future(() => null)));
    }
  }

  /// Find the most likely destination contact for a given name
  Future<Contact?> _findMostLikelyDestinationContact(BuildContext context, String s) async {
    var contacts = await readContactsFromCsv(context);
    // insert a dummy iban if contact not in list; just for demo purposes (better than empty field)
    return findMatchingContact(contacts, s) ?? Contact(s, "GB33BUKB202015555");
  }
}