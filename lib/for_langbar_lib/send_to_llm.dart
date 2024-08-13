import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:langbar/for_langbar_lib/retriever_tool.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:provider/provider.dart';

import '../openAIKey.dart';
import '../routes.dart';
import 'generic_screen_tool.dart';
import 'langbar_states.dart';
import 'llm_go_route.dart';
import 'my_conversation_buffer_memory.dart';

enum Service {
  openai,
  openrouter,
  ollama, groq }

// uses langchain and langchain_openai, and implicitly uses openai_dart
void submitToLLM(BuildContext context) {
  var langbarState = Provider.of<LangBarState>(context, listen: false);
  var apiKey2 = getOpenAIKey();
  // var baseUrl;
  var baseUrl = getLlmBaseUrl();
  var llm;

  var service = Service.openai;
  switch (service) {
    case Service.openai:
      llm = ChatOpenAI(
          // nu met de tools moet aan assistant.tool-calls gevolgd worden door iets anders (verplicht, anders is er een bad request)
          apiKey: apiKey2,
          baseUrl: baseUrl ?? 'https://api.openai.com/v1',
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              model: 'gpt-4o',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
    case Service.openrouter:
      const model = 'meta-llama/llama-3.1-405b-instruct';
      // const model = 'meta-llama/llama-3.1-70b-instruct';
      // const model = 'gpt-4o';
      llm = ChatOpenAI(
          apiKey:
              "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",
          baseUrl: "https://openrouter.ai/api/v1",
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              model: model,
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
    case Service.ollama:
      llm = ChatOllama(
          baseUrl: "http://129.146.20.55:16707/api",
          defaultOptions: const ChatOllamaOptions(
              temperature: 0.0,
              model: 'llama3.1:70b',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
    case Service.groq:
      llm = ChatOpenAI(
          apiKey: "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",
          baseUrl: "https://api.groq.com/openai/v1",
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              // versatile lijkt het alleen te doen bij beperkt aantal functies
              model: 'llama-3.1-70b-versatile',
              // model: 'llama-3.1-8b-instant',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
  }
  // model: 'gpt-3.5-turbo');
  langbarState.sendingToOpenAI = true;
  sendToOpenai(llm, context);
}

final memory = MyConversationBufferWindowMemory(
    chatHistory: ChatMessageHistory(),
    returnMessages: true); // default window length is 5
// final memory = MyConversationBufferWindowMemory(
//     chatHistory: ChatMessageHistory(),
//     returnMessages: true); // default window length is 5

Future<void> sendToOpenai(BaseChatModel llm, BuildContext context) async {
  // final forecastTool = ForecastScreen.getTool(GoRouter.of(context));
  // final creditCardTool = CreditCardScreen.getTool(GoRouter.of(context));
  var langbarState = Provider.of<LangBarState>(context, listen: false);
  var tools = parseRouters(GoRouter.of(context), routes);

  var tool = RetrieverTool();

  tools.insert(0, tool);
  var chatHistory = Provider.of<ChatHistory>(context, listen: false);

  final promptTemplate = ChatPromptTemplate.fromPromptMessages([
    SystemChatMessagePromptTemplate.fromTemplate(
      'Never directly answer a question yourself, but always use a function call.',
    ),
    const MessagesPlaceholder(variableName: 'history'),
    HumanChatMessagePromptTemplate.fromTemplate('{input}'),
  ]);

  var query = langbarState.controllerOutlined.text;

  var llm_with_tools;
  if (llm is ChatOpenAI) {
    llm_with_tools = llm.bind(ChatOpenAIOptions(
      tools: tools,
      toolChoice: ChatToolChoice.required,
    ));
  } else {
    llm_with_tools = llm.bind(ChatOllamaOptions(
      tools: tools,
      toolChoice: ChatToolChoice.required,
    ));
  }
  var fromMap = Runnable.fromMap({
    'input': Runnable.passthrough(),
    'history': Runnable.mapInput(
      (_) async {
        final m = await memory.loadMemoryVariables();
        return m['history'];
      },
    ),
  });
  var chain = fromMap | promptTemplate | llm_with_tools | ToolsOutputParser();

  // moet blijkbaar anders of met andere toolparser: https://langchaindart.dev/#/modules/model_io/models/chat_models/integrations/ollama?id=chatollama
  // var chain = fromMap | promptTemplate | llm_with_tools | ToolsOutputParser();
  // final chain = chain1 | OpenRouterLlamaOutputParser();
  var response;

  var lastResult;
  try {
    final output1 = await chain.invoke(query);
    memory.chatHistory.addHumanChatMessage(query);
    var toolcalls = output1 as List<ParsedToolCall>;
    var results = [];
    for (var parsedToolCall in toolcalls) {
      Tool tool = matchTool(parsedToolCall, tools);
      lastResult = await tool.invoke(parsedToolCall.arguments);
      results.add(lastResult);
    }
    print(output1);
  } catch (e) {
    response = e.toString();
    memory
        .clear(); // make sure an error does not prevent the next query from being processed (strange things in the history may cause bad-request errors)
  }
  langbarState.controllerOutlined.clear();
  langbarState.sendingToOpenAI = false;

  if (lastResult is String && !lastResult.startsWith("/")) {
    // lastResult is not a hyperlink, so it is a message to the user:
    memory.chatHistory.addAIChatMessage(lastResult);
    chatHistory.add(HistoryMessage(text: query, isHuman: true));
    chatHistory.add(HistoryMessage(text: lastResult, isHuman: false));
    langbarState.historyExpansion = ChatSheetExpansion.full;
    langbarState.historyShowing = true;
  } else {
    //lastResult is a hyperlink, so add hyperlink to the history:
    // add the original query, but the navigation-uri-repsonse as the hyperlink when you click on it
    langbarState.historyShowing = false;
    langbarState.historyExpansion = ChatSheetExpansion.part;
    chatHistory
        .add(HistoryMessage(text: query, isHuman: true, navUri: lastResult));
  }
}

Tool matchTool(ParsedToolCall parsedToolCall,
    List<Tool<Object, ToolOptions, Object>> tools) {
  var tool = tools
      .firstWhere((toolelement) => toolelement.name == parsedToolCall.name);
  return tool;
}

/**
 * If the last message in the chat history is a retriever function call, replace it with the response
 * from the assistant. This is the case when the user asks a general question that is relayed to the
 * RAG functionality. In the history we do not want to see this intermediate step, but rather see
 * the result of the RAG call.
 */
Future<void> replace_retriever_function_call_with_assistant_response_in_history(
    response) async {
  var chatHistoryLLM = memory.chatHistory;
  var chatHistoryLLMItems = await chatHistoryLLM.getChatMessages();
  ChatMessage? lastChatMessage = chatHistoryLLMItems.lastOrNull;
  if (lastChatMessage is AIChatMessage &&
      lastChatMessage.toolCalls.isNotEmpty &&
      lastChatMessage.toolCalls.first.name == retriever_name) {
    await chatHistoryLLM.removeLast();
    await chatHistoryLLM.addAIChatMessage(response);
  }
}

// converts the chat history (as shown to the user) to a memory object that can be used by the LLM
ConversationBufferMemory memoryFromChathistory(ChatHistory chatHistory) {
  var historyItems = chatHistory.items;
  final historyLength = 2;
  var lastHistoryItems = historyItems.length > historyLength
      ? historyItems.sublist(historyItems.length - historyLength)
      : historyItems;
  List<ChatMessage> historyMessages = lastHistoryItems.map((e) {
    if (e.isHuman) {
      return ChatMessage.human(ChatMessageContent.text(e.text));
    } else {
      return ChatMessage.ai(e.text);
    }
  }).toList();

  final memory2 = ConversationBufferMemory(
      chatHistory: ChatMessageHistory(messages: historyMessages),
      returnMessages: true);
  return memory2;
}

List<Tool> parseRouters(GoRouter, List<RouteBase> routes, {parentPath}) {
  var tools = <Tool>[];
  for (var route in routes) {
    String? newPath = null;
    if (route is GoRoute) {
      // route.path is only the local path. If the route e.g. points to a details screen, we have to prepend the path of the parent:
      newPath = (parentPath != null ? parentPath + "/" : "") + route.path;
    }
    if (route is DocumentedGoRoute) {
      var tool = GenericScreenTool(
          goRouter: goRouter,
          name: route.name,
          push: route.modal,
          path: newPath!,
          description: route.description,
          parameters: route.parameters);
      tools.add(tool);
    }
    if (route.routes.isNotEmpty) {
      tools.addAll(parseRouters(goRouter, route.routes, parentPath: newPath));
    }
  }
  return tools;
}
