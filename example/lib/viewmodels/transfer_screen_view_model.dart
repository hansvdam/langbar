import 'package:flutter/material.dart';
import 'app_generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/send_to_llm.dart';
import '../utils/name_matcher.dart';
import '../ui/models/account.dart';

class TransferScreenState {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;
  final BankAccount? fromAccount;
  final Future<Contact?>? mostLikelyDestinationContactFuture;

  // UI field values
  final String amountText;
  final String destinationAccountNameText;
  final String destinationAccountNumberText;
  final String descriptionText;

  TransferScreenState({
    this.amount,
    this.destinationName,
    this.description,
    required this.fromAccountId,
    this.fromAccount,
    this.mostLikelyDestinationContactFuture,
    this.amountText = '',
    this.destinationAccountNameText = '',
    this.destinationAccountNumberText = '',
    this.descriptionText = '',
  });

  TransferScreenState copyWith({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
    BankAccount? fromAccount,
    Future<Contact?>? mostLikelyDestinationContactFuture,
    String? amountText,
    String? destinationAccountNameText,
    String? destinationAccountNumberText,
    String? descriptionText,
  }) {
    return TransferScreenState(
      amount: amount ?? this.amount,
      destinationName: destinationName ?? this.destinationName,
      description: description ?? this.description,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      fromAccount: fromAccount ?? this.fromAccount,
      mostLikelyDestinationContactFuture: mostLikelyDestinationContactFuture ??
          this.mostLikelyDestinationContactFuture,
      amountText: amountText ?? this.amountText,
      destinationAccountNameText:
          destinationAccountNameText ?? this.destinationAccountNameText,
      destinationAccountNumberText:
          destinationAccountNumberText ?? this.destinationAccountNumberText,
      descriptionText: descriptionText ?? this.descriptionText,
    );
  }
}

class TransferScreenViewModel
    extends AppGenericScreenViewModel<TransferScreenState> {
  final BuildContext _context;

  TransferScreenViewModel({
    required BuildContext context,
    double? amount,
    String? destinationName,
    String? description,
    String fromAccountId = "1",
  })  : _context = context,
        super(
          TransferScreenState(
            amount: amount,
            destinationName: destinationName,
            description: description,
            fromAccountId: fromAccountId,
            fromAccount: accounts[
                fromAccountId], // Initialize fromAccount from accounts map
            mostLikelyDestinationContactFuture: destinationName != null
                ? null
                : Future(
                    () => null), // Will be set properly in _updateContactFuture
            amountText: amount?.toStringAsFixed(2) ?? '',
            destinationAccountNameText: destinationName ?? '',
            descriptionText: description ?? '',
          ),
          context: context,
        ) {
    langbarLogger.i(
        'TransferScreenViewModel created with amount: $amount, destinationName: $destinationName, description: $description, fromAccountId: $fromAccountId');
    _updateContactFuture();
  }

  void updateAmount(double? amount) {
    langbarLogger.i(
        'TransferScreenViewModel updating amount from ${state.amount} to $amount');
    emit(state.copyWith(
      amount: amount,
      amountText: amount?.toStringAsFixed(2) ?? '',
    ));
    // Speak confirmation of amount update
    if (amount != null) {
      speakConfirmation('bedrag ${amount.toStringAsFixed(2)} euro');
    }
  }

  void updateDestinationName(String? destinationName) {
    langbarLogger.i(
        'TransferScreenViewModel updating destinationName from ${state.destinationName} to $destinationName');
    emit(state.copyWith(
      destinationName: destinationName,
      destinationAccountNameText: destinationName ?? '',
    ));
    _updateContactFuture();
    // Speak confirmation of destination name update
    if (destinationName != null && destinationName.isNotEmpty) {
      speakConfirmation('begunstigde $destinationName');
    }
  }

  void updateDescription(String? description) {
    langbarLogger.i(
        'TransferScreenViewModel updating description from ${state.description} to $description');
    emit(state.copyWith(
      description: description,
      descriptionText: description ?? '',
    ));
    // Speak confirmation of description update
    if (description != null && description.isNotEmpty) {
      speakConfirmation('omschrijving $description');
    }
  }

  void updateFromAccountId(String fromAccountId) {
    langbarLogger.i(
        'TransferScreenViewModel updating fromAccountId from ${state.fromAccountId} to $fromAccountId');
    emit(state.copyWith(
      fromAccountId: fromAccountId,
      fromAccount: accounts[fromAccountId],
    ));
  }

  /// Update the ViewModel with new constructor parameters
  void updateFromConstructorParams({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
  }) {
    langbarLogger.i(
        'TransferScreenViewModel updating from constructor params: amount=$amount, destinationName=$destinationName, description=$description, fromAccountId=$fromAccountId');

    emit(state.copyWith(
      amount: amount,
      destinationName: destinationName,
      description: description,
      fromAccountId: fromAccountId,
      fromAccount: fromAccountId != null ? accounts[fromAccountId] : null,
      amountText: amount?.toStringAsFixed(2) ?? '',
      destinationAccountNameText: destinationName ?? '',
      descriptionText: description ?? '',
    ));
    _updateContactFuture();
    
    // Speak confirmation of all parameters
    List<String> confirmations = [];
    if (amount != null) {
      confirmations.add('bedrag ${amount.toStringAsFixed(2)} euro');
    }
    if (destinationName != null && destinationName.isNotEmpty) {
      confirmations.add('begunstigde $destinationName');
    }
    if (description != null && description.isNotEmpty) {
      confirmations.add('omschrijving $description');
    }
    if (confirmations.isNotEmpty) {
      print("speaking confirmations");
      speakConfirmation(confirmations.join(', '));
    }
  }

  /// Update text field values directly (for user input)
  void updateAmountText(String text) {
    double? amount = double.tryParse(text);
    emit(state.copyWith(
      amountText: text,
      amount: amount,
    ));
  }

  void updateDestinationAccountNameText(String text) {
    emit(state.copyWith(
      destinationAccountNameText: text,
      destinationName: text.isEmpty ? null : text,
    ));
    _updateContactFuture();
  }

  void updateDestinationAccountNumberText(String text) {
    emit(state.copyWith(destinationAccountNumberText: text));
  }

  void updateDescriptionText(String text) {
    emit(state.copyWith(
      descriptionText: text,
      description: text.isEmpty ? null : text,
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

  /// Update the contact lookup Future based on current destinationName
  void _updateContactFuture() {
    if (state.destinationName != null) {
      final future =
          _findMostLikelyDestinationContact(_context, state.destinationName!);
      emit(state.copyWith(mostLikelyDestinationContactFuture: future));
      // Update the destination account number when we get the contact
      future.then((contact) {
        if (contact != null) {
          emit(state.copyWith(destinationAccountNumberText: contact.iban));
        }
      });
    } else {
      emit(state.copyWith(
        mostLikelyDestinationContactFuture: Future(() => null),
        destinationAccountNumberText: '',
      ));
    }
  }

  /// Find the most likely destination contact for a given name
  Future<Contact?> _findMostLikelyDestinationContact(
      BuildContext context, String s) async {
    var contacts = await readContactsFromCsv(context);
    // insert a dummy iban if contact not in list; just for demo purposes (better than empty field)
    return findMatchingContact(contacts, s) ?? Contact(s, "GB33BUKB202015555");
  }
}
