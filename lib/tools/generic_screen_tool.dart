import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:langchain/langchain.dart';

import '../data/for_langchain.dart';
import '../utils/utils.dart';

/// {@template forecasting_tool}
/// A for forecasting the weather from an api.
/// {@endtemplate}
final class GenericScreenTool
    extends GenericTool<Map<String, dynamic>, ToolOptions, String> {
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
  Future<String> invokeInternal(Map<String, dynamic> toolInput,
      {final ToolOptions? options}) async {
    Map<String, String>? extraPathParameters =
        await hook?.call(toolInput, namedLocation: namedLocation);
    String? fullPath = goRouter.namedLocation(
      namedLocation,
      pathParameters: extraPathParameters ?? {},
      queryParameters:
          toolInput.map((key, value) => MapEntry(key, value.toString())),
    );
    activateUri(fullPath, push);
    return fullPath;
  }

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) {
    return json;
  }
}
