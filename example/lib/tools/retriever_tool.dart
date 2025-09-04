import 'dart:async';

import 'package:langbar_core/data/data_key.dart';
import 'retrieval.dart';
import 'package:langchain/langchain.dart';

import 'package:langbar_core/data/for_langchain.dart';

const retriever_name = "beantwoord_algemene_vraag";

const String user_question_key = 'user_question';

/// {@template forecasting_tool}
/// A for forecasting the weather from an api.
/// {@endtemplate}
final class RetrieverTool
    extends GenericTool<Map<String, dynamic>, ToolOptions, String> {
  RetrieverTool(
      {super.name = retriever_name,
      super.description =
          "Beantwoord een algemene vraag. Probeer ALTIJD eerst een andere functie in de lijst aan te roepen.",
      super.parameters = const [
        SUIParameter(
          name: 'gebruikersvraag',
          description: 'De vraag die de gebruiker stelt.',
          required: true,
          key: DataKey(user_question_key),
        )
      ]})
      : super(returnDirect: true);

  @override
  @override
  Future<String> invokeInternal(Map<String, dynamic> toolInput,
      {ToolOptions? options}) {
    var userQuestion = toolInput['gebruikersvraag'];
    var returnValue = conversationalRetrievalChain(userQuestion);
    return returnValue;
  }

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) {
    return json;
  }

// @override
// Future<String> invokeInternal(Map<String, dynamic> input, {ToolOptions? options}) {
//   // TODO: implement invokeInternal
//   throw UnimplementedError();
// }
}
