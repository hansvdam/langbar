import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:langchain_core/tools.dart';

import 'send_to_llm.dart';

mixin SpeechEnabled {
  List<Tool> getTools(BuildContext context);

  List<KeyWordtrigger> getKeyWordHandlers(BuildContext context) {
    return [];
  }

  void maybeAddInitialMessageToChatHistory() {
    // Do nothing by default
  }
}
