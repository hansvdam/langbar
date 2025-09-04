import 'package:flutter/material.dart';
import 'package:langbar_core/ui/cubits/generic_screen_view_model.dart';
import 'package:langchain_core/tools.dart';
import '../tools/retriever_tool.dart';

class AppGenericScreenViewModel<State> extends GenericScreenViewModel<State> {
  AppGenericScreenViewModel(super.initialState, {required BuildContext context})
      : super(context: context);

  @override
  List<Tool<Object, ToolOptions, Object>> getTools(BuildContext context) {
    // Get base tools from parent implementation
    List<Tool> tools = super.getTools(context);
    
    // Add RetrieverTool to the list
    var retrieverTool = RetrieverTool();
    tools.add(retrieverTool);
    
    return tools;
  }
}