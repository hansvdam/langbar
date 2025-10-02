import 'package:flutter/material.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/utils/utils.dart';
import 'app_generic_screen_view_model.dart';
import 'screen_tts_config.dart';

class ContactsScreenState {
  final String? selectedContact;
  final String? searchString;

  ContactsScreenState({
    this.selectedContact,
    this.searchString,
  });

  ContactsScreenState copyWith({
    String? selectedContact,
    String? searchString,
  }) {
    return ContactsScreenState(
      selectedContact: selectedContact ?? this.selectedContact,
      searchString: searchString ?? this.searchString,
    );
  }
}

class ContactsScreenViewModel extends AppGenericScreenViewModel<ContactsScreenState>
    with SpeechEnabled {
  late final ContactsScreenTtsConfig _ttsConfig;

  ContactsScreenViewModel({
    required BuildContext context,
    String? initialSearchString,
  }) : super(
          ContactsScreenState(searchString: initialSearchString),
          context: context,
        ) {
    _ttsConfig = ContactsScreenTtsConfig();
    langbarLogger.i('ContactsScreenViewModel created with search: $initialSearchString');

    // Speak initial search if provided
    if (initialSearchString != null && initialSearchString.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        speakSearchConfirmation(initialSearchString);
      });
    }
  }

  void updateSearchString(String searchString) {
    emit(state.copyWith(searchString: searchString));
  }

  void selectContact(String contactName) {
    final previousContact = state.selectedContact;

    emit(state.copyWith(selectedContact: contactName));

    // Speak the selection
    speakConfirmations(contactName, previousContact);
  }

  void speakConfirmations(String? selectedContact, String? previousContact) {
    Map<String, dynamic> currentValues = {};
    Map<String, dynamic> previousValues = {};

    if (selectedContact != null) {
      currentValues['selectedContact'] = selectedContact;
      if (previousContact != null) {
        previousValues['selectedContact'] = previousContact;
      }
    }

    _ttsConfig.speakConfirmations(
      currentValues: currentValues,
      previousValues: previousValues.isNotEmpty ? previousValues : null,
      currentScreenCubit: currentScreenCubit,
    );
  }

  void speakSearchConfirmation(String searchString) {
    tts.speak('searching for $searchString');
  }

  /// Update from constructor parameters (used when navigating with params)
  void updateFromConstructorParams({String? searchString}) {
    if (searchString != null && searchString != state.searchString) {
      emit(state.copyWith(searchString: searchString));

      if (searchString.isNotEmpty) {
        speakSearchConfirmation(searchString);
      }
    }
  }
}