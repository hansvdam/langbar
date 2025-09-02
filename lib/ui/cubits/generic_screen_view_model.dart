import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:langchain_core/src/tools/base.dart';
import 'package:langchain_core/src/tools/types.dart';

import '../../send_to_llm.dart';
import '../../speech_enabled.dart';
import 'current_screen_cubit.dart';

class GenericScreenViewModel<State> extends Cubit<State> with SpeechEnabled {
  CurrentScreenCubit currentScreenCubit;

  GenericScreenViewModel(super.initialState, {required BuildContext context})
      : currentScreenCubit = BlocProvider.of<CurrentScreenCubit>(context) {
    // Register as current view model
    context.read<CurrentScreenCubit>().pushCurrentCubit(this);
  }

  @override
  Future<void> close() async {
    clearChatMessageMemory(caller: 'GenericScreenViewModel.close'); // new context for parameter interpretation
    currentScreenCubit.removeCurrentCubit(this);
    return super.close();
  }

  @override
  List<Tool<Object, ToolOptions, Object>> getTools(BuildContext context) {
    List<Tool> tools =
        parseRouters(GoRouter.of(context), globalRoutes, context: context);
    return tools;
  }
}
