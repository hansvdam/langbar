import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:langchain_openai/langchain_openai.dart';

import 'open_ai_key.dart';

enum Service {
  openai,
  openrouter,
  ollama,
  groq,
}

class LoggingClient extends http.BaseClient {
  final http.Client _inner;

  LoggingClient(this._inner);

  // Future<String> getBodyFromStreamedRequest(http.BaseRequest request) async {
  //   // Read the stream of bytes
  //   final bytes = await request.finalize().toList();
  //   // Convert bytes to a single string
  //   return utf8.decode(bytes.expand((x) => x).toList());
  // }

  Future<String> getBodyFromStreamedResponse(
      http.StreamedResponse response) async {
    // Read the stream of bytes
    final bytes = await response.stream.toList();
    // Convert bytes to a single string
    return utf8.decode(bytes.expand((x) => x).toList());
  }

  Future<http.Request> logAndForwardRequest(
      http.StreamedRequest request) async {
    // Read the request body stream into bytes
    final bodyBytes = await request.finalize().toList();
    // Convert bytes to a string
    String body = utf8.decode(bodyBytes.expand((x) => x).toList());
    var jsonObject = jsonDecode(body);
    var prettyJson = JsonEncoder.withIndent('  ').convert(jsonObject);

    print('Request Body:\n$prettyJson');

    // Create a new request with the original stream
    var newRequest = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bodyBytes.expand((x) => x).toList(); // Set the body bytes

    return newRequest;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.StreamedRequest) {
      request = await logAndForwardRequest(request);
    }

    var streamedResponse = await _inner.send(request);

    // Get the body from the streamed response
    String body = await getBodyFromStreamedResponse(streamedResponse);
    print('Response Body: $body');

    // Create a new Stream from the bytes to allow further listening
    final newStream = Stream.fromIterable([utf8.encode(body)]);

    // Return a new StreamedResponse with the new stream
    return http.StreamedResponse(newStream, streamedResponse.statusCode,
        headers: streamedResponse.headers);
  }
}

void test() async {
  const tool = ToolSpec(
    name: 'joke',
    description: 'A joke',
    inputJsonSchema: {
      'type': 'object',
      'properties': {
        'setup': {
          'type': 'string',
          'description': 'The setup for the joke',
        },
        'punchline': {
          'type': 'string',
          'description': 'The punchline to the joke',
        },
      },
      'required': ['punchline'],
    },
  );

  const template =
      'You are a helpful assistant that translates {input_language} to {output_language}.';
  const humanTemplate = '{text}';

  final promptTemplate1 = ChatPromptTemplate.fromPromptMessages([
    SystemChatMessagePromptTemplate.fromTemplate(
      'You are a helpful chatbot',
    ),
    const MessagesPlaceholder(variableName: 'history'),
    HumanChatMessagePromptTemplate.fromTemplate('{input}'),
  ]);

  var llm;
  var apiKey2 = getOpenAIKey2();
  var service = Service.groq;
  var baseUrl;
  // var baseUrl = getLlmBaseUrl();
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
          baseUrl: "http://38.29.145.13:40115/api",
          defaultOptions: const ChatOllamaOptions(
              temperature: 0.0,
              model: 'llama3.1:70b',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
    case Service.groq:
      llm = ChatOpenAI(
          apiKey: "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",
          baseUrl: "https://api.groq.com/openai/v1",
          defaultOptions: const ChatOpenAIOptions(
              temperature: 0.0,
              model: 'llama-3.1-8b-instant',
              toolChoice:
                  ChatToolChoice.required)); // model: 'gpt-4-1106-preview');
      break;
  }

  // final chat = ChatOpenAI(
  //   apiKey:
  //       "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",
  //   baseUrl: 'https://openrouter.ai/api/v1',
  //   defaultOptions:
  //       ChatOpenAIOptions(model: 'gpt-4o', toolChoice: ChatToolChoice.required),
  // );
  final outputParser = ToolsOutputParser();

  final memory = ConversationBufferMemory(returnMessages: true);

  const tools = const [tool];
  // final chainTest = Runnable.fromMap({
  //   'input': Runnable.passthrough(),
  //   'history': Runnable.mapInput(
  //         (_) async {
  //       final m = await memory.loadMemoryVariables();
  //       return m['history'];
  //     },
  //   ),
  // }) |
  // promptTemplate1;
  //
  // var bla = await chainTest.invoke("bla");
  // print(bla);

  var llm_with_tools;
  switch (service) {
    case Service.openai:
      llm_with_tools = llm.bind(ChatOpenAIOptions(tools: tools));
      break;
    case Service.groq:
      llm_with_tools = llm.bind(ChatOpenAIOptions(tools: tools));
      break;
    case Service.openrouter:
      // llm_with_tools = llm.bind(ChatModelOptions(tools: tools));
      break;
    case Service.ollama:
      llm_with_tools = llm.bind(ChatOllamaOptions(tools: tools));
      break;
  }
  var bald_chain = Runnable.fromMap({
        'input': Runnable.passthrough(),
        'history': Runnable.mapInput(
          (_) async {
            final m = await memory.loadMemoryVariables();
            return m['history'];
          },
        ),
      }) |
      promptTemplate1 |
      llm_with_tools;
  var chain = bald_chain | outputParser;

  // chain = bald_chain;

  // final chain = promptTemplate1
  //     .pipe(llm.bind(ChatOpenAIOptions(tools: const [tool])))
  //     .pipe(outputParser);

  var input1 = 'foo bears';
  var result1 = await chain.invoke({input1});
  final List<ParsedToolCall> result = result1 as List<ParsedToolCall>;

  result.forEach((element) {
    var foundTool =
        tools.firstWhere((toolelement) => toolelement.name == element.name);
    print(foundTool.name);
  });

  await memory.saveContext(
    inputValues: {'input': input1},
    outputValues: {'output': result},
  );

  var messages = await memory.chatHistory.getChatMessages();
  print("memory:\n" + messages.toString());

  var input2 = 'the president';
  final List<ParsedToolCall> result2 =
      await chain.invoke({input2}) as List<ParsedToolCall>;
}

Future<void> main() async {
  test();
}
