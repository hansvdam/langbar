import 'package:flutter/widgets.dart';
import 'package:langchain_core/src/tools/base.dart';

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
