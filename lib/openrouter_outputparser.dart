import 'dart:convert';

import 'package:langchain/langchain.dart';

class OpenRouterLlamaOutputParser extends BaseOutputParser<ChatResult,
    OutputParserOptions, List<ParsedToolCall>> {
  /// {@macro tools_output_parser}
  OpenRouterLlamaOutputParser({
    this.reduceOutputStream = false,
  }) : super(
          defaultOptions: const OutputParserOptions(),
        );

  final bool reduceOutputStream;

  // ChatResult? _lastResult;
  // List<ParsedToolCall> _lastOutput = [];

  @override
  Future<List<ParsedToolCall>> invoke(
    final ChatResult input, {
    final OutputParserOptions? options,
  }) async {
    return _parseInvoke(input, options: options);
  }

  // @override
  // Stream<List<ParsedToolCall>> stream(
  //     final ChatResult input, {
  //       final OutputParserOptions? options,
  //     }) async* {
  //   yield await _parseStream(input, options: options);
  // }

  // @override
  // Stream<List<ParsedToolCall>> streamFromInputStream(
  //     final Stream<ChatResult> inputStream, {
  //       final OutputParserOptions? options,
  //     }) async* {
  //   if (reduceOutputStream) {
  //     await inputStream.forEach(
  //           (final input) => _parseStream(input, options: options),
  //     );
  //     yield _lastOutput;
  //     _clear();
  //   } else {
  //     yield* super
  //         .streamFromInputStream(inputStream, options: options)
  //         .distinct(const DeepCollectionEquality().equals)
  //         .doOnCancel(_clear);
  //   }
  // }

  Future<List<ParsedToolCall>> _parseInvoke(
    final ChatResult input, {
    final OutputParserOptions? options,
  }) async {
    return [parseOpenRouterToolContent(input.output.content)];
  }

  // Future<List<ParsedToolCall>> _parseStream(
  //     final ChatResult input, {
  //       final OutputParserOptions? options,
  //     }) async {
  //   final mergedResult = _lastResult?.concat(input) ?? input;
  //   _lastResult = mergedResult;
  //   return _lastOutput = _parse(
  //     mergedResult.output.toolCalls,
  //     fallback: _lastOutput,
  //   );
  // }
  //
  // List<ParsedToolCall> _parse(
  //     final List<AIChatMessageToolCall>? toolCalls, {
  //       List<ParsedToolCall> fallback = const [],
  //     }) {
  //   final List<ParsedToolCall> output = [];
  //   for (int i = 0; i < (toolCalls?.length ?? 0); i++) {
  //     final toolCall = toolCalls![i];
  //     final arguments = toolCall.arguments.isNotEmpty
  //         ? toolCall.arguments
  //         : parsePartialJson(toolCall.argumentsRaw) ??
  //         (i < fallback.length
  //             ? fallback[i].arguments
  //             : const <String, dynamic>{});
  //     output.add(
  //       ParsedToolCall(
  //         id: toolCall.id,
  //         name: toolCall.name,
  //         arguments: arguments,
  //       ),
  //     );
  //   }
  //   return output;
  // }

  ParsedToolCall parseOpenRouterToolContent(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final String functionName = jsonMap['function'];
    final Map<String, dynamic> parameters = jsonMap['parameters'];

    final parsedToolCall = ParsedToolCall(
      id: 'unique_id', // Replace with a unique identifier if needed
      name: functionName,
      arguments: parameters,
    );
    return parsedToolCall;
  }

  void _clear() {
    // _lastResult = null;
    // _lastOutput = [];
  }
}
