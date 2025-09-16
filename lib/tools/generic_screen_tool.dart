import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:langchain/langchain.dart';

import '../data/for_langchain.dart';
import '../utils/utils.dart';

/// {@template forecasting_tool}
/// A for forecasting the weather from an api.
/// {@endtemplate}
final class GenericScreenTool
    extends GenericTool<Map<String, dynamic>, ToolOptions> {
  final GoRouter goRouter;

  final String path;

  final bool push;

  final Future<Map<String, String>?> Function(Map<String, dynamic>,
      {String? namedLocation})? hook;

  final String namedLocation;

  GenericScreenTool({
    required this.goRouter,
    required super.name,
    required this.path,
    required super.description,
    required super.parameters,
    this.push = false,
    this.hook,
    required this.namedLocation,
  }) : super(returnDirect: true);

  @override
  Future<GenericOutput> invokeInternal(Map<String, dynamic> toolInput,
      {final ToolOptions? options}) async {
    langbarLogger.i(
        'GenericScreenTool.invokeInternal - name: $name, toolInput: $toolInput, push: $push');
    Map<String, String>? extraPathParameters =
        await hook?.call(toolInput, namedLocation: namedLocation);
    
    // Filter out empty parameters
    final filteredQueryParams = Map<String, String>.fromEntries(
      toolInput.entries
          .where((entry) => 
              entry.value != null && 
              entry.value.toString().isNotEmpty)
          .map((entry) => MapEntry(entry.key, entry.value.toString()))
    );
    
    String? fullPath = goRouter.namedLocation(
      namedLocation,
      pathParameters: extraPathParameters ?? {},
      queryParameters: filteredQueryParams,
    );
    langbarLogger.i('GenericScreenTool generated fullPath: $fullPath');
    activateUri(fullPath, push);
    
    // Create a descriptive message about the parameters filled
    final parameterDescriptions = filteredQueryParams.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    
    final resultMessage = parameterDescriptions.isNotEmpty
        ? "Navigating to $name screen filling out the following parameters: $parameterDescriptions"
        : "Navigating to $name screen";
    
    GenericOutput returnValue = GenericOutput(
      type: OutputType.navigation, 
      hyperlink: fullPath, 
      result: resultMessage
    );
    return returnValue;
  }

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) {
    return json;
  }
}
