import 'package:langchain/langchain.dart';

class RepairingToolsOutputParser extends ToolsOutputParser {
  ChatResult? lastChatResult;

  @override
  Future<List<ParsedToolCall>> invoke(
    final ChatResult input, {
    final OutputParserOptions? options,
  }) async {
    List<ParsedToolCall> result = await super.invoke(input, options: options);
    lastChatResult = input;
    if (result.isEmpty) {
      result = createParsedToolCallsFromToolsInContent(input.outputAsString);
    }
    // creat a new list to store the repaired result, by creating copies of the ParsedToolCalls in the list and removing any empty arguments
    List<ParsedToolCall> repairedResult = [];
    for (var parsedToolCall in result) {
      try {
        Map<String, dynamic> repairedArguments = {};
        parsedToolCall.arguments.forEach((key, value) {
          try {
            if (value is String && value.isNotEmpty) {
              repairedArguments[key] = value;
              final parsedValue = int.tryParse(value) ??
                  double.tryParse(value) ??
                  _tryParseBoolean(value) ??
                  value;
              repairedArguments[key] = parsedValue;
            } else if (value != null) {
              repairedArguments[key] = value;
            }
          } catch (e) {
            print("problem here: $e");
          }
        });

        repairedResult.add(ParsedToolCall(
          id: parsedToolCall.id,
          name: parsedToolCall.name,
          arguments: repairedArguments,
        ));
      } catch (e) {
        print(e);
      }
    }
    return repairedResult;
  }

  bool? _tryParseBoolean(String value) {
    final lowercaseValue = value.toLowerCase();
    if (lowercaseValue == 'true') return true;
    if (lowercaseValue == 'false') return false;
    return null;
  }

  List<ParsedToolCall> createParsedToolCallsFromToolsInContent(
      String outputAsString) {
    // Regular expression to match function calls with their arguments, separated by commas
    final regex = RegExp(r'(\w+)\((.*?)\)(?:\s*,\s*)?');
    final matches = regex.allMatches(outputAsString);

    return matches.map((match) {
      final functionName = match.group(1) ?? '';
      final argsString = match.group(2) ?? '';

      // Parse arguments string into a Map
      final arguments = _parseArguments(argsString);

      return ParsedToolCall(
        name: functionName,
        arguments: arguments,
        id: '', // Optional: generate a unique ID if needed
      );
    }).toList();
  }

  Map<String, dynamic> _parseArguments(String argsString) {
    final arguments = <String, dynamic>{};

    // Updated regex to handle values with or without quotes, including words with underscores
    final regex = RegExp(r'(\w+)=(?:"([^"]*)"|([\w_]+|\d+))');
    final matches = regex.allMatches(argsString);

    for (final match in matches) {
      final key = match.group(1)!;
      final quotedValue = match.group(2);
      final unquotedValue = match.group(3);

      // Handle different value types
      dynamic value;
      if (quotedValue != null) {
        value = quotedValue;
      } else if (unquotedValue != null) {
        if (unquotedValue.toLowerCase() == 'true') {
          value = true;
        } else if (unquotedValue.toLowerCase() == 'false') {
          value = false;
        } else {
          // Try to parse as int first, if fails keep the string value
          value = int.tryParse(unquotedValue) ?? unquotedValue;
        }
      }

      arguments[key] = value;
    }

    return arguments;
  }
}
