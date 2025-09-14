import 'package:langchain/langchain.dart';

import 'data_key.dart';

enum DataType { string, integer, number, boolean, object, array }

class SUIParamBase {
  const SUIParamBase({
    required this.name,
    this.description,
    this.type = DataType.string,
    this.required = false,
    this.enumeration,
  });

  final String name;
  final String? description;
  final DataType type;
  final bool required;
  final List<String>? enumeration;

  Map<String, dynamic> asFunctionParam() {
    Map<String, dynamic> map = {'type': type.toString().split('.').last};

    if (description != null) {
      map['description'] = description;
    }
    if (enumeration != null) {
      map['enum'] = enumeration!;
    }
    return {name: map};
  }
}

class SUIParameter extends SUIParamBase {
  const SUIParameter({
    required super.name,
    super.description,
    super.type,
    super.required,
    super.enumeration,
    this.isDataModelParam = true,
    String? codeName,
    String? unit,
    required this.key,
  })  : unit = unit;

  final String? unit;

  final bool isDataModelParam;
  final DataKey key;

}

abstract base class GenericTool<
    Input extends Object,
    Options extends ToolOptions,
    Output extends Object> extends Tool<Input, Options, Output> {
  GenericTool(
      {required super.name,
      required super.description,
      required List<SUIParamBase> parameters,
      super.returnDirect})
      : super(
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              for (var param in parameters) ...param.asFunctionParam(),
            },
            'required': parameters
                .where((param) => param.required)
                .map((param) => param.name)
                .toList(),
          },
        );
}
