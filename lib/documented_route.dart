import 'package:go_router/go_router.dart';

import 'data/for_langchain.dart';

class DocumentedGoRoute extends GoRoute {
  final bool modal;
  final Type? screenType;

  DocumentedGoRoute({
    required super.name,
    required this.description,
    this.screenType, //
    required super.path,
    this.parameters = const [],
    this.modal = false,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.routes = const <RouteBase>[],
  }) : super();

  final String description;
  final List<SUIParameter> parameters;
}
