import 'package:flutter/widgets.dart';
import 'package:langchain_core/tools.dart';

import 'send_to_llm.dart';

mixin SpeechEnabled {
  List<Tool> getTools(BuildContext context);

  List<KeyWordtrigger> getKeyWordHandlers(BuildContext context) {
    return [];
  }

  /// Called just before a query is sent to the LLM while the chat memory is
  /// empty (app start, manual tab switch, or an error wiped it). Override to
  /// inject an initial context message via [addSystemChatMessage] so the LLM
  /// knows which screen the user is on and what state it currently holds.
  void maybeAddInitialMessageToChatHistory() {
    // Do nothing by default
  }
}
