import 'package:flutter/material.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/utils/utils.dart';
import 'app_generic_screen_view_model.dart';
import 'screen_tts_config.dart';

class AccountsScreenState {
  final String? selectedAccount;
  final String? selectedAccountBalance;

  AccountsScreenState({
    this.selectedAccount,
    this.selectedAccountBalance,
  });

  AccountsScreenState copyWith({
    String? selectedAccount,
    String? selectedAccountBalance,
  }) {
    return AccountsScreenState(
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedAccountBalance: selectedAccountBalance ?? this.selectedAccountBalance,
    );
  }
}

class AccountsScreenViewModel extends AppGenericScreenViewModel<AccountsScreenState>
    with SpeechEnabled {
  late final AccountsScreenTtsConfig _ttsConfig;

  AccountsScreenViewModel({required BuildContext context})
      : super(
          AccountsScreenState(),
          context: context,
        ) {
    _ttsConfig = AccountsScreenTtsConfig();
    langbarLogger.i('AccountsScreenViewModel created');
  }

  void selectAccount(String accountName, String balance) {
    final previousAccount = state.selectedAccount;

    emit(state.copyWith(
      selectedAccount: accountName,
      selectedAccountBalance: balance,
    ));

    // Speak the selection
    speakConfirmations(accountName, previousAccount);
  }

  void speakConfirmations(String? selectedAccount, String? previousAccount) {
    Map<String, dynamic> currentValues = {};
    Map<String, dynamic> previousValues = {};

    if (selectedAccount != null) {
      currentValues['selectedAccount'] = selectedAccount;
      if (previousAccount != null) {
        previousValues['selectedAccount'] = previousAccount;
      }
    }

    _ttsConfig.speakConfirmations(
      currentValues: currentValues,
      previousValues: previousValues.isNotEmpty ? previousValues : null,
      currentScreenCubit: currentScreenCubit,
    );
  }
}
