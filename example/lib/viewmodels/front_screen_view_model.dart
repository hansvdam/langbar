import 'package:flutter/material.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'app_generic_screen_view_model.dart';

class FrontScreenViewModel extends AppGenericScreenViewModel<void> {
  FrontScreenViewModel({required BuildContext context})
      : super(null, context: context);

  @override
  void maybeAddInitialMessageToChatHistory() {
    addSystemChatMessage(
        'The user is currently on the home screen of the banking app.');
  }
}
