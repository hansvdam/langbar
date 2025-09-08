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
    
    // Speak initial values that were provided
    List<String> initialValues = [];
    if (amount != null) {
      initialValues.add('amount ${amount.toStringAsFixed(2)} euros');
    }
    if (destinationName != null && destinationName.isNotEmpty) {
      initialValues.add('recipient $destinationName');
    }
    if (description != null && description.isNotEmpty) {
      initialValues.add('description $description');
    }
    if (initialValues.isNotEmpty) {
      // Small delay to ensure TTS is initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        speakConfirmation(initialValues.join(', '));
      });
    }
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

    // Store previous values before updating
    final previousAmount = state.amount;
    final previousName = state.destinationName;
    final previousDescription = state.description;

    // Use existing state values if new values are not provided
    final newAmount = amount ?? state.amount;
    final newDestinationName = destinationName ?? state.destinationName;
    final newDescription = description ?? state.description;
    final newFromAccountId = fromAccountId ?? state.fromAccountId;

    emit(state.copyWith(
      amount: newAmount,
      destinationName: newDestinationName,
      description: newDescription,
      fromAccountId: newFromAccountId,
      fromAccount: accounts[newFromAccountId],
      amountText: newAmount?.toStringAsFixed(2) ?? '',
      destinationAccountNameText: newDestinationName ?? '',
      descriptionText: newDescription ?? '',
    ));
    _updateContactFuture();
    
    // Build smart confirmations based on what changed
    // Only speak about parameters that were explicitly passed (not null in the method call)
    List<String> newValues = [];
    List<String> corrections = [];
    
    // Check amount - only if explicitly passed
    // Check destination name - only if explicitly passed
    if (destinationName != null) {
      if (destinationName.isNotEmpty) {
        if (previousName != null && previousName.isNotEmpty && previousName != destinationName && !currentScreenCubit.state.hasViewModelChanged) {
          corrections.add('recipient corrected to $destinationName');
        } else if (previousName == null || previousName.isEmpty) {
          newValues.add('recipient $destinationName');
        }
      }
    }

    if (amount != null) {
      if (previousAmount != null && previousAmount != amount && !currentScreenCubit.state.hasViewModelChanged) {
        corrections.add('amount corrected to ${amount.toStringAsFixed(2)} euros');
      } else if (previousAmount == null) {
        newValues.add('amount ${amount.toStringAsFixed(2)} euros');
      }
    }


    // Check description - only if explicitly passed
    if (description != null) {
      if (description.isNotEmpty) {
        if (previousDescription != null && previousDescription.isNotEmpty && previousDescription != description && !currentScreenCubit.state.hasViewModelChanged) {
          corrections.add('description corrected to $description');
        } else if (previousDescription == null || previousDescription.isEmpty) {
          newValues.add('description $description');
        }
      }
    }
    
    // Speak corrections first, then new values
    List<String> allConfirmations = [...corrections, ...newValues];
    if (allConfirmations.isNotEmpty) {
      langbarLogger.d("Speaking confirmations: ${allConfirmations.join(', ')}");
      speakConfirmation(allConfirmations.join(', '));
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
