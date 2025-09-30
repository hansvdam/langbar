import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:langchain_core/tools.dart';

import '../../send_to_llm.dart';
import '../../speech_enabled.dart';
import '../../tts_service.dart';
import '../../mcp/mcp_integration_interface.dart';
import 'current_screen_cubit.dart';

class GenericScreenViewModel<TState> extends Cubit<TState> with SpeechEnabled {
  CurrentScreenCubit currentScreenCubit;
  final TTSService tts = TTSService.instance;
  bool ttsEnabled = true;

  GenericScreenViewModel(super.initialState, {required BuildContext context})
      : currentScreenCubit = BlocProvider.of<CurrentScreenCubit>(context) {
    // Register as current view model
    context.read<CurrentScreenCubit>().pushCurrentCubit(this);
    // Initialize TTS service
    _initializeTTS();
    // Defer MCP tools update until after the widget is built to avoid Provider lifecycle issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMCPTools(context);
    });
  }
  
  Future<void> _initializeTTS() async {
    await tts.initialize();
  }

  void _updateMCPTools(BuildContext context) {
    // Check if MCP is initialized and update tools
    try {
      // Try to update MCP tools if the integration exists
      _attemptMCPUpdate(context);
    } catch (e) {
      // MCP not initialized, which is fine
    }
  }

  void _attemptMCPUpdate(BuildContext context) {
    // This will be called by MCP integration if it's available
    try {
      // Using GetIt to check if MCP is registered
      final mcpIntegration = _getMCPIntegration();
      if (mcpIntegration != null) {
        print('🎯 MCP integration found, updating tools for $runtimeType');
        mcpIntegration.updateTools(this, context);
      } else {
        print('❌ MCP integration not found for $runtimeType');
      }
    } catch (e) {
      // MCP not available
      print('⚠️ Error attempting MCP update: $e');
    }
  }

  MCPIntegrationInterface? _getMCPIntegration() {
    try {
      // Try to get MCP integration if it's registered
      final getIt = GetIt.instance;

      // Check if MCPIntegrationInterface is registered
      if (getIt.isRegistered<MCPIntegrationInterface>()) {
        return getIt.get<MCPIntegrationInterface>();
      }

      // Not registered - this is expected when MCP is not enabled
      return null;
    } catch (e) {
      // GetIt error - MCP not available
      return null;
    }
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
