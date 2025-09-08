import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:langchain_core/src/tools/base.dart';
import 'package:langchain_core/src/tools/types.dart';

import '../../send_to_llm.dart';
import '../../speech_enabled.dart';
import '../../tts_service.dart';
import 'current_screen_cubit.dart';

class GenericScreenViewModel<State> extends Cubit<State> with SpeechEnabled {
  CurrentScreenCubit currentScreenCubit;
  final TTSService tts = TTSService.instance;
  bool ttsEnabled = true;

  GenericScreenViewModel(super.initialState, {required BuildContext context})
      : currentScreenCubit = BlocProvider.of<CurrentScreenCubit>(context) {
    // Register as current view model
    context.read<CurrentScreenCubit>().pushCurrentCubit(this);
    // Initialize TTS service
    _initializeTTS();
  }
  
  Future<void> _initializeTTS() async {
    await tts.initialize();
  }

  @override
  List<Tool<Object, ToolOptions, Object>> getTools(BuildContext context) {
    List<Tool> tools =
        parseRouters(GoRouter.of(context), globalRoutes, context: context);
    return tools;
  }
  
  /// Speak text using TTS if enabled and this is the current view model
  Future<void> speak(String text, {bool interruptCurrent = true}) async {
    // Only speak if this is the current view model and TTS is enabled
    if (!_isCurrentViewModel() || !ttsEnabled) {
      return;
    }
    
    await tts.speak(text, interruptCurrent: interruptCurrent);
  }
  
  bool _isCurrentViewModel() {
    final currentState = currentScreenCubit.state.currentViewModel;
    return currentState is GenericScreenViewModel && currentState == this;
  }
  
  /// Speak confirmation of understood parameters
  Future<void> speakConfirmation(String confirmation) async {
    await speak('Understood: $confirmation');
  }
  
  /// Enable or disable TTS for this view model
  void setTTSEnabled(bool enabled) {
    ttsEnabled = enabled;
  }
  
  /// Stop any ongoing TTS speech
  Future<void> stopSpeaking() async {
    await tts.stop();
  }
}
