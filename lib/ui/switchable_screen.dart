import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langchain/langchain.dart';

import '../my_conversation_buffer_memory.dart';
import 'langfield/langbar_states.dart';

abstract class Switchable {
  Future<List<ParsedToolCall>> handleNewAndSwitch(
      Cubit<dynamic>? currentViewmodel,
      String? currentPath,
      List<ParsedToolCall> toolcalls,
      ParsedToolCall firstToolCall,
      MyConversationBufferWindowMemory chatMessageMemory,
      ChatHistory chatHistoryForUi,
      RunnableSequence<Object, Object> chain,
      ChatPromptTemplate promptTemplate,
      RunnableBinding<PromptValue, ChatModelOptions, ChatResult> llmWithTools,
      String query);
}
