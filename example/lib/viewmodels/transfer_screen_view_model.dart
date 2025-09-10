import 'package:flutter/material.dart';
import 'app_generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'package:langbar_core/tts_highlight_service.dart';
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
    
    // Speak initial values with highlighting
    _speakInitialValuesWithHighlight(amount, destinationName, description);
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
    speakConfirmations(destinationName, previousName, amount, previousAmount, description, previousDescription);
  }

  void speakConfirmations(String? destinationName, String? previousName, double? amount, double? previousAmount, String? description, String? previousDescription) {
    List<TtsParameter> parameters = [];

    // Check which fields have been updated and prepare TTS parameters
    if (amount != null && (amount != previousAmount || currentScreenCubit.state.hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'amount',
        label: currentScreenCubit.state.hasScreenChanged || previousAmount == null
            ? 'amount'
            : 'amount corrected to',
        value: '${amount.toStringAsFixed(2)} euros',
      ));
    }
    
    if (destinationName != null && (destinationName != previousName || currentScreenCubit.state.hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'recipient',
        label: currentScreenCubit.state.hasScreenChanged || previousName == null ? 'recipient' : 'recipient corrected to',
        value: destinationName,
      ));
    }
    
    if (description != null && (description != previousDescription || currentScreenCubit.state.hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'description',
        label: currentScreenCubit.state.hasScreenChanged || previousDescription == null ? 'description' : 'description corrected to',
        value: description,
      ));
    }

    // Speak with highlighting
    if (parameters.isNotEmpty) {
      langbarLogger.d("Speaking parameters with highlighting: ${parameters.map((p) => p.spokenText).join(', ')}");
      TtsHighlightService.instance.speakParametersWithHighlight(parameters);
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

  void _checkFieldUpdate<T>(T? newValue, T? previousValue, String fieldName, String? displayValue, List<String> corrections, List<String> newValues) {
    if (newValue == null) return;
    
    final hasValue = newValue is String ? newValue.isNotEmpty : true;
    final previousHasValue = previousValue is String ? previousValue.isNotEmpty : previousValue != null;
    
    if (hasValue) {
      if (previousHasValue && previousValue != newValue && !currentScreenCubit.state.hasScreenChanged) {
        corrections.add('$fieldName corrected to $displayValue');
      } else if (!previousHasValue) {
        newValues.add('$fieldName $displayValue');
      }
    }
  }

  /// Speak initial values with synchronized highlighting
  void _speakInitialValuesWithHighlight(double? amount, String? destinationName, String? description) {
    List<TtsParameter> parameters = [];
    
    if (amount != null) {
      parameters.add(TtsParameter(
        fieldId: 'amount',
        label: 'amount',
        value: '${amount.toStringAsFixed(2)} euros',
      ));
    }
    
    if (destinationName != null && destinationName.isNotEmpty) {
      parameters.add(TtsParameter(
        fieldId: 'recipient',
        label: 'recipient',
        value: destinationName,
      ));
    }
    
    if (description != null && description.isNotEmpty) {
      parameters.add(TtsParameter(
        fieldId: 'description',
        label: 'description',
        value: description,
      ));
    }
    
    if (parameters.isNotEmpty) {
      // Small delay to ensure TTS and UI are initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        TtsHighlightService.instance.speakParametersWithHighlight(parameters);
      });
    }
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
