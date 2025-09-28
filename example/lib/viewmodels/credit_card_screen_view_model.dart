import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langbar_core/my_conversation_buffer_memory.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/tts_highlight_service.dart';
import 'package:langbar_core/ui/langfield/langbar_states.dart';
import 'package:langbar_core/ui/switchable_screen.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/send_to_llm.dart';
import 'package:langchain/langchain.dart';
import 'app_generic_screen_view_model.dart';
import 'screen_tts_config.dart';
import '../ui/screens/card_screen.dart';

enum ActionOnCard {
  cancel,
  replace,
  none;

  static ActionOnCard? fromString(String? title) {
    return ActionOnCard.values.firstWhere((element) => element.name == title,
        orElse: () => ActionOnCard.none);
  }
}

class CreditCardScreenState {
  final ActionOnCard action;
  final int? limit;
  final bool initial;

  CreditCardScreenState({
    required this.action,
    this.limit,
    this.initial = true,
  });

  CreditCardScreenState copyWith({
    ActionOnCard? action,
    int? limit,
    bool? initial,
  }) {
    return CreditCardScreenState(
      action: action ?? this.action,
      limit: limit ?? this.limit,
      initial: initial ?? this.initial,
    );
  }
}

class CreditCardScreenTtsConfig extends ScreenTtsConfig {
  final CardType cardType;

  CreditCardScreenTtsConfig({required this.cardType});

  @override
  String get screenName => cardType == CardType.credit ? 'Credit Card' : 'Debit Card';

  @override
  String? get tabBarIconFieldId => 'creditcard_icon';

  @override
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  }) {
    List<TtsParameter> parameters = [];

    final action = currentValues['action'] as ActionOnCard?;
    final previousAction = previousValues?['action'] as ActionOnCard?;
    final limit = currentValues['limit'] as int?;
    final previousLimit = previousValues?['limit'] as int?;

    if (action != null && action != ActionOnCard.none &&
        (action != previousAction || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'action',
        label: hasScreenChanged || previousAction == null
            ? 'action'
            : 'action changed to',
        value: action.name,
      ));
    }

    if (limit != null && (limit != previousLimit || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'limit',
        label: hasScreenChanged || previousLimit == null
            ? 'limit'
            : 'limit changed to',
        value: '$limit euros',
      ));
    }

    return parameters;
  }
}

// TTS config will be created in the ViewModel with the appropriate card type

class CreditCardScreenViewModel
    extends AppGenericScreenViewModel<CreditCardScreenState>
    with SpeechEnabled
    implements Switchable {
  final CardType cardType;
  late final CreditCardScreenTtsConfig _ttsConfig;

  CreditCardScreenViewModel({
    required BuildContext context,
    required this.cardType,
    ActionOnCard? initialAction,
    int? initialLimit,
  })  :
        super(
          CreditCardScreenState(
            action: initialAction ?? ActionOnCard.none,
            limit: initialLimit,
            initial: true,
          ),
          context: context,
        ) {
    _ttsConfig = CreditCardScreenTtsConfig(cardType: cardType);
    langbarLogger.i(
        'CreditCardScreenViewModel created with cardType: $cardType, action: $initialAction, limit: $initialLimit');

    // Speak initial values if provided
    if (initialAction != null || initialLimit != null) {
      // Small delay to ensure the screen is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        speakConfirmations(initialAction, null, initialLimit, null);
      });
    }
  }

  /// Update the ViewModel with new constructor parameters
  void updateFromConstructorParams({
    ActionOnCard? action,
    int? limit,
  }) {
    langbarLogger.i(
        'CreditCardScreenViewModel updating from constructor params: action=$action, limit=$limit');

    // Store previous values before updating
    final previousAction = state.action != ActionOnCard.none ? state.action : null;
    final previousLimit = state.limit;

    // Use existing state values if new values are not provided
    final newAction = action ?? state.action;
    final newLimit = limit ?? state.limit;

    emit(state.copyWith(
      action: newAction,
      limit: newLimit,
      initial: false,
    ));

    // Build smart confirmations based on what changed
    speakConfirmations(action, previousAction, limit, previousLimit);
  }

  void speakConfirmations(
      ActionOnCard? action,
      ActionOnCard? previousAction,
      int? limit,
      int? previousLimit) {
    // Build current and previous values maps for the TTS config
    Map<String, dynamic> currentValues = {};
    Map<String, dynamic> previousValues = {};

    // Only add values that were actually passed (not null in the method call)
    if (action != null) {
      currentValues['action'] = action;
      if (previousAction != null) {
        previousValues['action'] = previousAction;
      }
    }

    if (limit != null) {
      currentValues['limit'] = limit;
      if (previousLimit != null) {
        previousValues['limit'] = previousLimit;
      }
    }

    // Use the TTS config to speak the confirmations
    _ttsConfig.speakConfirmations(
      currentValues: currentValues,
      previousValues: previousValues.isNotEmpty ? previousValues : null,
      currentScreenCubit: currentScreenCubit,
    );
  }

  void updateAction(ActionOnCard action) {
    emit(state.copyWith(action: action, initial: false));
  }

  void updateLimit(int? limit) {
    emit(state.copyWith(limit: limit, initial: false));
  }

  void markAsNotInitial() {
    emit(state.copyWith(initial: false));
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
    var memoryLength = chatMessages.length;
    if ((toolcalls.length > 1 || (firstToolCall.name != currentScreenName)) &&
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
