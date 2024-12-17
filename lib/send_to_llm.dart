import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'speech_enabled.dart';
import 'tools/retriever_tool.dart';
import 'ui/swichable_screen.dart';
import 'utils/utils.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:provider/provider.dart';

import 'documented_route.dart';
import 'my_conversation_buffer_memory.dart';
import 'llm_keys.dart';
import 'tools/generic_screen_tool.dart';
import 'tools/repairing_tools_output_parser.dart';
// use the following command to ignore the file from git (like a changelist)
// git update-index --skip-worktree lib/llm_keys.dart
// git update-index --no-skip-worktree <file>
import 'ui/cubits/current_screen_cubit.dart';
import 'ui/langfield/langbar_states.dart';

enum Service { openai, openrouter, ollama, groq }

late List<RouteBase> globalRoutes;

setRoutes(List<RouteBase> routes) {
  globalRoutes = routes;
}

late String systemPrompt;

void setSystemPrompt(String prompt) {
  systemPrompt = prompt;
}

// uses langchain and langchain_openai, and implicitly uses openai_dart
void submitToLLM(BuildContext context) {
  var langbarState = Provider.of<LangBarState>(context, listen: false);
  // var apiKey2 = getOpenAIKey();
  var groqApiKey = getGroqApiKey();
  var openRouterAPIKey = getOpenRouterAPIKey();

  // var baseUrl;
  // var baseUrl = getLlmBaseUrl();
  BaseChatModel llm;

  // var service = Service.ollama;
  var service = Service.openai;
  switch (service) {
    case Service.openai:
      llm = ChatOpenAI(
          // nu met de tools moet aan assistant.tool-calls gevolgd worden door iets anders (verplicht, anders is er een bad request)
          apiKey: getOpenAIKey2(),
          // baseUrl: baseUrl ?? 'https://api.openai.com/v1',
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
          apiKey: openRouterAPIKey,
          baseUrl: "https://openrouter.ai/api/v1",
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              model: model,
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
    case Service.ollama:
      llm = ChatOllama(
          baseUrl: "http://45.135.56.11:25215/api",
          defaultOptions: const ChatOllamaOptions(
              temperature: 0.0,
              model: 'llama3.3:70b-instruct-q8_0',
              // model: 'llama3.1:70b',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
    case Service.groq:
      llm = ChatOpenAI(
          apiKey: groqApiKey,
          baseUrl: "https://api.groq.com/openai/v1",
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              // versatile lijkt het alleen te doen bij beperkt aantal functies
              model: 'llama-3.3-70b-versatile',
              // model: 'llama-3.1-8b-instant',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
  }
  // model: 'gpt-3.5-turbo');
  langbarState.sendingToOpenAI = true;
  final currentViewmodel = context.read<CurrentScreenCubit>().state;
  final chatHistory = Provider.of<ChatHistory>(context, listen: false);
  sendToOpenai(llm, context, chatHistory, currentViewmodel);
}

final _chatMessageMemory = MyConversationBufferWindowMemory(
    chatHistory: ChatMessageHistory(),
    returnMessages: true); // default window length is 5
// final memory = MyConversationBufferWindowMemory(
//     chatHistory: ChatMessageHistory(),
//     returnMessages: true); // default window length is 5

clearChatMessageMemory() async {
  await _chatMessageMemory.clear();
  print("chatMessageMemory cleared");
}

addHumanChatMessage(String message) {
  _chatMessageMemory.chatHistory.addHumanChatMessage(message);
}

printChatMessageMemory(String heading) async {
  var messages = await _chatMessageMemory.chatHistory.getChatMessages();
  print("$heading: $messages");
}

Future<void> sendToOpenai(BaseChatModel llm, BuildContext context,
    ChatHistory chatHistoryForUi, Cubit? currentViewmodel) async {
  // final forecastTool = ForecastScreen.getTool(GoRouter.of(context));
  // final creditCardTool = CreditCardScreen.getTool(GoRouter.of(context));
  var langbarState = Provider.of<LangBarState>(context, listen: false);
  List<Tool> tools = [];
  List<KeyWordtrigger> keyWordHandlers = [];
  if (currentViewmodel is SpeechEnabled) {
    tools = (currentViewmodel as SpeechEnabled).getTools(context);
    keyWordHandlers =
        (currentViewmodel as SpeechEnabled).getKeyWordHandlers(context);
  } else {
    tools = parseRouters(GoRouter.of(context), globalRoutes, context: context);
  }

  var tool = RetrieverTool();

  tools.add(tool);
  if (currentViewmodel is SpeechEnabled) {
    List<ChatMessage> messages =
        await _chatMessageMemory.chatHistory.getChatMessages();
    if (messages.isEmpty) {
      (currentViewmodel as SpeechEnabled).maybeAddInitialMessageToChatHistory();
    }
    await printChatMessageMemory(
        "messages after maybeAddInitialMessageToChatHistory");
  }

  final promptTemplate = ChatPromptTemplate.fromPromptMessages([
    SystemChatMessagePromptTemplate.fromTemplate(
      systemPrompt,
    ),
    const MessagesPlaceholder(variableName: 'history'),
    HumanChatMessagePromptTemplate.fromTemplate('{input}'),
  ]);

  var query = langbarState.controllerOutlined.text;

  for (var keyWordHandler in keyWordHandlers) {
    if (keyWordHandler.regexList
        .any((pattern) => RegExp(pattern).hasMatch(query))) {
      keyWordHandler.invoke(query);
      langbarState.controllerOutlined.clear();
      langbarState.sendingToOpenAI = false;
      return;
    }
  }

  RunnableBinding<PromptValue, ChatModelOptions, ChatResult> llmWithTools;
  if (llm is ChatOpenAI) {
    llmWithTools = llm.bind(ChatOpenAIOptions(
      tools: tools,
      toolChoice: ChatToolChoice.required,
    ));
  } else {
    llmWithTools = llm.bind(ChatOllamaOptions(
      tools: tools,
      toolChoice: ChatToolChoice.required,
    ));
  }
  RunnableSequence<Object, Object> chain =
      createChain(promptTemplate, llmWithTools, _chatMessageMemory);

  // moet blijkbaar anders of met andere toolparser: https://langchaindart.dev/#/modules/model_io/models/chat_models/integrations/ollama?id=chatollama
  // var chain = fromMap | promptTemplate | llm_with_tools | ToolsOutputParser();
  // final chain = chain1 | OpenRouterLlamaOutputParser();

  dynamic lastResult;
  try {
    final output1 = await chain.invoke(query);
    _chatMessageMemory.chatHistory.addHumanChatMessage(query);
    var toolcalls = output1 as List<ParsedToolCall>;
    if (toolcalls.isEmpty) {
      chatHistoryForUi.add(HistoryMessage(
          text:
              "no tool calls but: ${repairingToolsOutputParser.lastChatResult}",
          isHuman: false));
      langbarState.historyShowing = true;
      langbarState.sendingToOpenAI = false;
      return;
    }
    var firstToolCall = toolcalls.first;
    // in case of a switch of we start clean:

    String? currentScreenName;
    if (currentViewmodel is Switchable) {
      toolcalls = await (currentViewmodel as Switchable).handleNewAndSwitch(
          currentViewmodel,
          currentScreenName,
          toolcalls,
          firstToolCall,
          _chatMessageMemory,
          chatHistoryForUi,
          chain,
          promptTemplate,
          llmWithTools,
          query);
    }

    ParsedToolCall toolCallToCall = toolcalls.last;
    if (toolcalls.length > 1) {
      chatHistoryForUi.add(HistoryMessage(
          text:
              "received multiple tool calls for 1 user-message. Picking the last: ${toolCallToCall.name}",
          isHuman: false));
    }
    var results = [];
    // for (var parsedToolCall in toolcalls) {
    Tool tool = matchTool(toolCallToCall, tools);
    chatHistoryForUi.add(
        HistoryMessage(text: "invoking tool: $toolCallToCall", isHuman: false));
    lastResult = await tool.invoke(toolCallToCall.arguments);
    results.add(lastResult);
    // }
    print(output1);
    langbarState.controllerOutlined.clear();
    langbarState.sendingToOpenAI = false;

    if (lastResult == LOCAL_ACTION_HANDLED) {
      return;
    }

    if (lastResult is String && !lastResult.startsWith("/")) {
      // lastResult is not a hyperlink, so it is a message to the user:
      _chatMessageMemory.chatHistory.addAIChatMessage(lastResult);
      chatHistoryForUi.add(HistoryMessage(text: query, isHuman: true));
      chatHistoryForUi.add(HistoryMessage(text: lastResult, isHuman: false));
      langbarState.historyExpansion = ChatSheetExpansion.full;
      langbarState.historyShowing = true;
    } else if (lastResult is String) {
      //lastResult is a hyperlink, so add hyperlink to the history:
      // add the original query, but the navigation-uri-repsonse as the hyperlink when you click on it
      langbarState.historyShowing = false;
      langbarState.historyExpansion = ChatSheetExpansion.part;
      chatHistoryForUi
          .add(HistoryMessage(text: query, isHuman: true, navUri: lastResult));

      // make sure the chathistory is immune to clearing by closing cubits
      await liftChathistoryOverClearingsByGUI();
    }
  } catch (e) {
    print("error calling llm or parsing output: $e");
    clearChatMessageMemory(); // make sure an error does not prevent the next query from being processed (strange things in the history may cause bad-request errors)
    langbarState.historyShowing = true;
    langbarState.sendingToOpenAI = false;
    chatHistoryForUi.add(
        HistoryMessage(text: "error sending to LLM: {$e}", isHuman: false));
  }
}

class KeyWordtrigger {
  final List<String> regexList;
  final Function(String input) handler;

  KeyWordtrigger({required this.regexList, required this.handler});

  invoke(String input) {
    handler(input);
  }
}

var repairingToolsOutputParser = RepairingToolsOutputParser();

Future<void> liftChathistoryOverClearingsByGUI() async {
  // make sure the chathistory is immune to clearing by closing cubits
  List<ChatMessage> messages =
      await _chatMessageMemory.chatHistory.getChatMessages();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await clearChatMessageMemory();
    for (var message in messages) {
      await _chatMessageMemory.chatHistory.addChatMessage(message);
    }
    await printChatMessageMemory(
        "messages after re-adding them in PostFrameCallback");
  });
}

RunnableSequence<Object, Object> createChain(
    ChatPromptTemplate promptTemplate, llmWithTools, memory) {
  var fromMap = Runnable.fromMap({
    'input': Runnable.passthrough(),
    'history': Runnable.mapInput(
      (_) async {
        final m = await memory.loadMemoryVariables();
        return m['history'];
      },
    ),
  });
  var chain =
      fromMap | promptTemplate | llmWithTools | repairingToolsOutputParser;
  return chain;
}

Tool matchTool(ParsedToolCall parsedToolCall,
    List<Tool<Object, ToolOptions, Object>> tools) {
  var tool = tools
      .firstWhere((toolelement) => toolelement.name == parsedToolCall.name);
  return tool;
}

/// If the last message in the chat history is a retriever function call, replace it with the response
/// from the assistant. This is the case when the user asks a general question that is relayed to the
/// RAG functionality. In the history we do not want to see this intermediate step, but rather see
/// the result of the RAG call.
Future<void> replaceRetrieverFunctionCallWithAssistantResponseInHistory(
    response) async {
  var chatHistoryLLM = _chatMessageMemory.chatHistory;
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
  const historyLength = 2;
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

List<Tool> parseRouters(GoRouter goRouter, List<RouteBase> routes,
    {parentPath, required BuildContext context}) {
  // Get the current route
  final GoRouterState routerState = GoRouterState.of(context);

  // Get the value of CurrentScreenCubit
  var tools = <Tool>[];
  for (var route in routes) {
    String? newPath;
    String? namedLocation;
    if (route is GoRoute) {
      newPath = (parentPath != null ? "$parentPath/" : "") + route.path;
      namedLocation = route.name;
    }

    if (route is DocumentedGoRoute) {
      var hook = globalCreateHook(route, routerState);
      var tool = GenericScreenTool(
          goRouter: goRouter,
          name: route.name!,
          push: route.modal,
          path: newPath!,
          namedLocation: namedLocation!,
          description: route.description,
          parameters: route.parameters,
          hook: hook);
      tools.add(tool);
    }
    if (route.routes.isNotEmpty) {
      tools.addAll(parseRouters(goRouter, route.routes,
          parentPath: newPath, context: context));
    }
  }
  return tools;
}

typedef HookCreator = Future<Map<String, String>?>
    Function(Map<String, dynamic>, {String? namedLocation});
typedef CreateHookFunction = HookCreator? Function(
    DocumentedGoRoute route, GoRouterState routerState);

// Global variable to store the hook creation function
late CreateHookFunction globalCreateHook;

void setGlobalCreateHook(CreateHookFunction newHook) {
  globalCreateHook = newHook;
}
