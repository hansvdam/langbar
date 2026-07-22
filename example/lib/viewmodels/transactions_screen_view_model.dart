import 'package:flutter/material.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/utils/utils.dart';
import 'app_generic_screen_view_model.dart';
import 'screen_tts_config.dart';

class TransactionsScreenState {
  final String? selectedTransaction;
  final String? searchFilter;
  final int? accountId;

  TransactionsScreenState({
    this.selectedTransaction,
    this.searchFilter,
    this.accountId,
  });

  TransactionsScreenState copyWith({
    String? selectedTransaction,
    String? searchFilter,
    int? accountId,
  }) {
    return TransactionsScreenState(
      selectedTransaction: selectedTransaction ?? this.selectedTransaction,
      searchFilter: searchFilter ?? this.searchFilter,
      accountId: accountId ?? this.accountId,
    );
  }
}

class TransactionsScreenViewModel extends AppGenericScreenViewModel<TransactionsScreenState>
    with SpeechEnabled {
  late final TransactionsScreenTtsConfig _ttsConfig;

  TransactionsScreenViewModel({
    required BuildContext context,
    String? initialFilterString,
    int? accountId = 1,
  }) : super(
          TransactionsScreenState(
            searchFilter: initialFilterString,
            accountId: accountId,
          ),
          context: context,
        ) {
    _ttsConfig = TransactionsScreenTtsConfig();
    langbarLogger.i('TransactionsScreenViewModel created with filter: $initialFilterString, accountId: $accountId');

    // Speak initial filter if provided
    if (initialFilterString != null && initialFilterString.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        speakFilterConfirmation(initialFilterString);
      });
    }
  }

  @override
  void maybeAddInitialMessageToChatHistory() {
    var message = 'The user is currently on the transactions screen';
    if (state.accountId != null) {
      message += ', showing transactions of account ${state.accountId}';
    }
    message += '.';
    if (state.searchFilter != null && state.searchFilter!.isNotEmpty) {
      message += ' Transactions are filtered on "${state.searchFilter}".';
    }
    if (state.selectedTransaction != null) {
      message += ' Selected transaction: ${state.selectedTransaction}.';
    }
    addSystemChatMessage(message);
  }

  void updateSearchFilter(String filter) {
    emit(state.copyWith(searchFilter: filter));
  }

  void selectTransaction(String transactionDescription) {
    final previousTransaction = state.selectedTransaction;

    emit(state.copyWith(selectedTransaction: transactionDescription));

    // Speak the selection
    speakConfirmations(
      selectedTransaction: transactionDescription,
      previousTransaction: previousTransaction,
    );
  }

  void speakConfirmations({
    String? searchFilter,
    String? previousFilter,
    String? selectedTransaction,
    String? previousTransaction,
  }) {
    Map<String, dynamic> currentValues = {};
    Map<String, dynamic> previousValues = {};

    if (searchFilter != null) {
      currentValues['searchFilter'] = searchFilter;
      if (previousFilter != null) {
        previousValues['searchFilter'] = previousFilter;
      }
    }

    if (selectedTransaction != null) {
      currentValues['selectedTransaction'] = selectedTransaction;
      if (previousTransaction != null) {
        previousValues['selectedTransaction'] = previousTransaction;
      }
    }

    _ttsConfig.speakConfirmations(
      currentValues: currentValues,
      previousValues: previousValues.isNotEmpty ? previousValues : null,
      currentScreenCubit: currentScreenCubit,
    );
  }

  void speakFilterConfirmation(String filter) {
    speakConfirmations(searchFilter: filter, previousFilter: null);
  }

  /// Update from constructor parameters (used when navigating with params)
  void updateFromConstructorParams({String? filterString, int? accountId}) {
    if (filterString != null && filterString != state.searchFilter) {
      final previousFilter = state.searchFilter;
      emit(state.copyWith(searchFilter: filterString));

      if (filterString.isNotEmpty) {
        speakConfirmations(
          searchFilter: filterString,
          previousFilter: previousFilter,
        );
      }
    }

    if (accountId != null && accountId != state.accountId) {
      emit(state.copyWith(accountId: accountId));
    }
  }
}