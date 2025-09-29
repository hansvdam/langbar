import 'package:langchain/langchain.dart';

import 'data_key.dart';
export 'data_key.dart';

enum DataType { string, integer, number, boolean, object, array }

enum OutputType { text, navigation, localFunction }

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

class GenericOutput {
  const GenericOutput({
    required this.type,
    this.hyperlink,
    required this.result,
  });

  final OutputType type;
  final String? hyperlink;
  final String result;

  @override
  String toString() {
    return 'GenericOutput(type: $type, hyperlink: $hyperlink, contents: $result)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenericOutput &&
        other.type == type &&
        other.hyperlink == hyperlink &&
        other.result == result;
  }

  @override
  int get hashCode => Object.hash(type, hyperlink, result);
}


abstract base class GenericTool<
    Input extends Object,
    Options extends ToolOptions> extends Tool<Input, Options, GenericOutput> {
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
