import 'dart:async';
import 'dart:convert';

import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

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
      'required': ['location', 'punchline'],
    },
  );

  const template =
      'You are a helpful assistant that translates {input_language} to {output_language}.';
  const humanTemplate = '{text}';

  final promptTemplate = ChatPromptTemplate.fromPromptMessages([
    SystemChatMessagePromptTemplate.fromTemplate(
      'You are a helpful chatbot',
    ),
    const MessagesPlaceholder(variableName: 'history'),
    HumanChatMessagePromptTemplate.fromTemplate('{input}'),
  ]);

  final chatPrompt = ChatPromptTemplate.fromTemplates([
    (ChatMessageType.system, template),
    (ChatMessageType.human, humanTemplate),
  ]);
  final res = chatPrompt.formatMessages({
    'input_language': 'English',
    'output_language': 'French',
    'text': 'I love programming.',
  });
  print(res);

  final promptTemplate = ChatPromptTemplate.fromTemplate(
    'tell me a long joke about {foo}',
  );

  final chat = ChatOpenAI(
    apiKey:
        "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",
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultOptions:
        ChatOpenAIOptions(model: 'gpt-4o', toolChoice: ChatToolChoice.required),
  );
  final outputParser = ToolsOutputParser();

  final chain = promptTemplate
      .pipe(chat.bind(ChatOpenAIOptions(tools: const [tool])))
      .pipe(outputParser);

  final stream = await chain.invoke({'foo': 'bears'});

  print(stream);
}

Future<void> main() async {
  test();
}
