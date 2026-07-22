import 'package:flutter/material.dart';
import 'package:langbar_core/tts_highlight_service.dart';
import 'app_generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/ui/switchable_screen.dart';
import 'package:langbar_core/my_conversation_buffer_memory.dart';
import 'package:langbar_core/ui/langfield/langbar_states.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_core/src/chat_models/types.dart';
import 'package:langchain_core/src/prompts/chat_prompt.dart';
import 'package:langchain_core/src/prompts/types.dart';
import 'package:langchain_core/src/runnables/binding.dart';
import 'package:langchain_core/src/runnables/sequence.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'screen_tts_config.dart';

class MapScreenState {
  final String selectedLocation;
  final String? previousLocation;
  final bool isManualChange;

  MapScreenState({
    required this.selectedLocation, 
    this.previousLocation,
    this.isManualChange = false,
  });

  MapScreenState copyWith({
    String? selectedLocation, 
    String? previousLocation,
    bool? isManualChange,
  }) {
    return MapScreenState(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      previousLocation: previousLocation ?? this.previousLocation,
      isManualChange: isManualChange ?? this.isManualChange,
    );
  }
}

class MapScreenTtsConfig extends ScreenTtsConfig {
  @override
  String get screenName => 'Map';

  @override
  String? get tabBarIconFieldId => 'map_icon';

  @override
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  }) {
    List<TtsParameter> parameters = [];

    final selectedLocation = currentValues['selectedLocation'] as String?;
    final previousLocation = previousValues?['selectedLocation'] as String?;

    if (selectedLocation != null &&
        (selectedLocation != previousLocation || hasScreenChanged)) {
      // Use the specific field ID for the selected location
      final fieldId = selectedLocation == 'atms' ? 'location_atms' : 'location_offices';
      var label = hasScreenChanged || previousLocation == null
            ? 'showing'
            : 'changed to';
      var spokenLocation = selectedLocation == 'atms' ? 'ATMs' : 'Offices';
      parameters.add(TtsParameter(
        fieldId: fieldId,
        label: label,
        value: spokenLocation,
        spokenText: "$label $spokenLocation near you"
      ));
    }

    return parameters;
  }
}

final MapScreenTtsConfig _ttsConfig = MapScreenTtsConfig();

class MapScreenViewModel extends AppGenericScreenViewModel<MapScreenState>
    with SpeechEnabled
    implements Switchable {

  MapScreenViewModel({required BuildContext context, String? initialLocation})
      : super(MapScreenState(selectedLocation: initialLocation ?? 'atms'),
            context: context) {
    langbarLogger.i(
        'MapScreenViewModel created with initialLocation: $initialLocation, final selectedLocation: ${state.selectedLocation}');
    
    // Speak when navigating to the screen (check if this is a screen change)
    // We'll let updateFromConstructorParams handle the speaking
  }

  @override
  void maybeAddInitialMessageToChatHistory() {
    var showing = state.selectedLocation == 'atms' ? 'ATMs' : 'bank offices';
    addSystemChatMessage(
        'The user is currently on the map screen, showing $showing near them.');
  }

  /// Update the ViewModel with new constructor parameters
  void updateFromConstructorParams({String? atmOrOffice}) {
    langbarLogger.i(
        'MapScreenViewModel updating from constructor params: atmOrOffice=$atmOrOffice');
    
    final previousLocation = state.selectedLocation;
    final newLocation = atmOrOffice ?? state.selectedLocation;
    
    // Check if this is a screen change (navigation to this screen)
    final isScreenChange = currentScreenCubit.state.hasScreenChanged;
    
    if (newLocation != previousLocation || isScreenChange) {
      emit(state.copyWith(
        selectedLocation: newLocation,
        previousLocation: previousLocation,
        isManualChange: false, // This is a programmatic change from navigation
      ));
      
      // Speak if there's a screen change or location parameter change
      if (isScreenChange || atmOrOffice != null) {
        _speakCurrentLocation();
      }
    }
  }

  void updateSelectedLocation(String location, {bool isManual = false}) {
    langbarLogger.i(
        'MapScreenViewModel updating selectedLocation from ${state.selectedLocation} to $location (manual: $isManual)');
    
    final previousLocation = state.selectedLocation;
    emit(state.copyWith(
      selectedLocation: location, 
      previousLocation: previousLocation,
      isManualChange: isManual,
    ));
    
    langbarLogger.i(
        'MapScreenViewModel new state selectedLocation: ${state.selectedLocation}');
    
    // Only speak the change if it's not a manual user interaction
    if (!isManual) {
      _speakLocationChange(previousLocation);
    }
  }

  void _speakCurrentLocation() {
    // Only speak if we have a screen change (navigation) or programmatic change
    if (!state.isManualChange) {
      _ttsConfig.speakConfirmations(
        currentValues: {'selectedLocation': state.selectedLocation},
        previousValues: state.previousLocation != null 
          ? {'selectedLocation': state.previousLocation}
          : null,
        currentScreenCubit: currentScreenCubit,
      );
    }
  }

  void _speakLocationChange(String previousLocation) {
    _ttsConfig.speakConfirmations(
      currentValues: {'selectedLocation': state.selectedLocation},
      previousValues: {'selectedLocation': previousLocation},
      currentScreenCubit: currentScreenCubit,
    );
  }

  @override
  Future<List<ParsedToolCall>> handleNewAndSwitch(
      Cubit<dynamic>? currentViewmodel,
      String? currentPath,
      List<ParsedToolCall> toolcalls,
      ParsedToolCall firstToolCall,
      MyConversationBufferWindowMemory chatMessageMemory,
      ChatHistory chatHistoryForUi,
      RunnableSequence<Object, Object> chain,
      ChatPromptTemplate promptTemplate,
      RunnableBinding<PromptValue, ChatModelOptions, ChatResult> llmWithTools,
      String query) async {
    String currentScreenName = currentPath!.split("/")[1];
    var chatMessages = await chatMessageMemory.chatHistory.getChatMessages();
    // system messages only carry screen context, they are not conversation
    var memoryLength =
        chatMessages.where((m) => m is! SystemChatMessage).length;
    if ((toolcalls.length > 1 ||
        (firstToolCall.name != currentScreenName)) &&
        memoryLength > 1) {
      // context change, try again without history
      chatHistoryForUi.add(HistoryMessage(
          text:
          "received multiple tool calls (irt multiple user-messages). trying again with only the last user-message",
          isHuman: false));
      clearChatMessageMemory();
      chain = createChain(promptTemplate, llmWithTools, chatMessageMemory);
      final output2 = await chain.invoke(query);
      chatMessageMemory.chatHistory.addHumanChatMessage(query);
      toolcalls = output2 as List<ParsedToolCall>;
    }
    return toolcalls;
  }
}
