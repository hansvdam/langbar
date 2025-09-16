import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:langbar_core/data/for_langchain.dart';
import 'package:langbar_core/my_conversation_buffer_memory.dart';
import 'package:langbar_core/speech_enabled.dart';
import 'package:langbar_core/tts_highlight_service.dart';
import 'package:langbar_core/ui/langfield/langbar_states.dart';
import 'package:langbar_core/ui/switchable_screen.dart';
import 'package:langchain_core/src/chat_models/types.dart';
import 'package:langchain_core/src/output_parsers/types.dart';
import 'package:langchain_core/src/prompts/chat_prompt.dart';
import 'package:langchain_core/src/prompts/types.dart';
import 'package:langchain_core/src/runnables/binding.dart';
import 'package:langchain_core/src/runnables/sequence.dart';
import 'app_generic_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/send_to_llm.dart';
import '../utils/name_matcher.dart';
import '../ui/models/account.dart';
import 'package:langchain_core/tools.dart';
import '../widgets/transfer_completed_dialog.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/transfer_screen.dart';
import 'screen_tts_config.dart';
import '../models/transfer_intent.dart';

class TransferScreenState {
  final double? amount;
  final String? destinationName;
  final String? description;
  final String fromAccountId;
  final BankAccount? fromAccount;
  final Future<Contact?>? mostLikelyDestinationContactFuture;

  // UI field values
  final String amountText;
  final String destinationAccountNameText;
  final String destinationAccountNumberText;
  final String descriptionText;

  TransferScreenState({
    this.amount,
    this.destinationName,
    this.description,
    required this.fromAccountId,
    this.fromAccount,
    this.mostLikelyDestinationContactFuture,
    this.amountText = '',
    this.destinationAccountNameText = '',
    this.destinationAccountNumberText = '',
    this.descriptionText = '',
  });

  TransferScreenState copyWith({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
    BankAccount? fromAccount,
    Future<Contact?>? mostLikelyDestinationContactFuture,
    String? amountText,
    String? destinationAccountNameText,
    String? destinationAccountNumberText,
    String? descriptionText,
  }) {
    return TransferScreenState(
      amount: amount ?? this.amount,
      destinationName: destinationName ?? this.destinationName,
      description: description ?? this.description,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      fromAccount: fromAccount ?? this.fromAccount,
      mostLikelyDestinationContactFuture: mostLikelyDestinationContactFuture ??
          this.mostLikelyDestinationContactFuture,
      amountText: amountText ?? this.amountText,
      destinationAccountNameText:
          destinationAccountNameText ?? this.destinationAccountNameText,
      destinationAccountNumberText:
          destinationAccountNumberText ?? this.destinationAccountNumberText,
      descriptionText: descriptionText ?? this.descriptionText,
    );
  }
}

class TransferScreenTtsConfig extends ScreenTtsConfig {
  @override
  String get screenName => 'Transfer';

  @override
  String? get tabBarIconFieldId => 'transfer_icon';

  @override
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  }) {
    List<TtsParameter> parameters = [];

    final amount = currentValues['amount'] as double?;
    final previousAmount = previousValues?['amount'] as double?;
    final destinationName = currentValues['destinationName'] as String?;
    final previousName = previousValues?['destinationName'] as String?;
    final description = currentValues['description'] as String?;
    final previousDescription = previousValues?['description'] as String?;

    if (amount != null && (amount != previousAmount || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'amount',
        label: hasScreenChanged || previousAmount == null
            ? 'amount'
            : 'amount corrected to',
        value: '${amount.toStringAsFixed(2)} euros',
      ));
    }

    if (destinationName != null &&
        (destinationName != previousName || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'recipient',
        label: hasScreenChanged || previousName == null
            ? 'recipient'
            : 'recipient corrected to',
        value: destinationName,
      ));
    }

    if (description != null &&
        (description != previousDescription || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'description',
        label: hasScreenChanged || previousDescription == null
            ? 'description'
            : 'description corrected to',
        value: description,
      ));
    }

    return parameters;
  }
}

final TransferScreenTtsConfig _ttsConfig = TransferScreenTtsConfig();

class TransferScreenViewModel
    extends AppGenericScreenViewModel<TransferScreenState>
    with SpeechEnabled
    implements Switchable {
  final BuildContext _context;

  TransferScreenViewModel({
    required BuildContext context,
    double? amount,
    String? destinationName,
    String? description,
    String fromAccountId = "1",
    String? intent,
  })  : _context = context,
        super(
          TransferScreenState(
            amount: amount,
            destinationName: destinationName,
            description: description,
            fromAccountId: fromAccountId,
            fromAccount: accounts[fromAccountId],
            // Initialize fromAccount from accounts map
            mostLikelyDestinationContactFuture:
                destinationName != null ? null : Future(() => null),
            // Will be set properly in _updateContactFuture
            amountText: amount?.toStringAsFixed(2) ?? '',
            destinationAccountNameText: destinationName ?? '',
            descriptionText: description ?? '',
          ),
          context: context,
        ) {
    langbarLogger.i(
        'TransferScreenViewModel created with amount: $amount, destinationName: $destinationName, description: $description, fromAccountId: $fromAccountId');
    _updateContactFuture();

    // speakConfirmations(destinationName,null,amount,null,description,null);
    // Speak initial values with highlighting
    // _speakInitialValuesWithHighlight(amount, destinationName, description);
  }

  /// Update the ViewModel with new constructor parameters
  void updateFromConstructorParams({
    double? amount,
    String? destinationName,
    String? description,
    String? fromAccountId,
    String? intent,
  }) {
    langbarLogger.i(
        'TransferScreenViewModel updating from constructor params: amount=$amount, destinationName=$destinationName, description=$description, fromAccountId=$fromAccountId');

    // Determine if this is a correction/modification or a new transfer
    final transferIntent = intent != null
        ? TransferIntent.fromString(intent)
        : TransferIntent.initialization;
    var isCorrection = transferIntent == TransferIntent.correction;
    print("intent: $intent, transferIntent: $transferIntent");
    // Store previous values before updating

    // final previousAmount = state.amount;
    // final previousName = state.destinationName;
    // final previousDescription = state.description;
    final previousAmount = isCorrection && amount != null ? state.amount : null;
    final previousName = isCorrection && destinationName != null ? state.destinationName : null;
    final previousDescription = isCorrection && description != null ? state.description : null;

    // Use existing state values if new values are not provided
    final newAmount = amount ?? previousAmount;
    final newDestinationName = destinationName ?? previousName;
    final newDescription = description ?? previousDescription;
    final newFromAccountId = fromAccountId ?? state.fromAccountId;

    emit(state.copyWith(
      amount: newAmount,
      destinationName: newDestinationName,
      description: newDescription,
      fromAccountId: newFromAccountId,
      fromAccount: accounts[newFromAccountId],
      amountText: newAmount?.toStringAsFixed(2) ?? '',
      destinationAccountNameText: newDestinationName ?? '',
      descriptionText: newDescription ?? '',
    ));
    _updateContactFuture();

    // Build smart confirmations based on what changed
    // Only speak about parameters that were explicitly passed (not null in the method call)
    speakConfirmations(destinationName, previousName, amount, previousAmount,
        description, previousDescription, intent);
  }

  void speakConfirmations(
      String? destinationName,
      String? previousName,
      double? amount,
      double? previousAmount,
      String? description,
      String? previousDescription,
      String? intent) {
    // Build current and previous values maps for the TTS config
    Map<String, dynamic> currentValues = {};
    Map<String, dynamic> previousValues = {};

    // Only add values that were actually passed (not null in the method call)
    if (amount != null) {
      currentValues['amount'] = amount;
      if (previousAmount != null) {
        previousValues['amount'] = previousAmount;
      }
    }

    if (destinationName != null) {
      currentValues['destinationName'] = destinationName;
      if (previousName != null) {
        previousValues['destinationName'] = previousName;
      }
    }

    if (description != null) {
      currentValues['description'] = description;
      if (previousDescription != null) {
        previousValues['description'] = previousDescription;
      }
    }

    // Use the TTS config to speak the confirmations
    _ttsConfig.speakConfirmations(
      currentValues: currentValues,
      previousValues: previousValues.isNotEmpty ? previousValues : null,
      currentScreenCubit: currentScreenCubit,
    );
  }

  /// Update text field values directly (for user input)
  void updateAmountText(String text) {
    double? amount = double.tryParse(text);
    emit(state.copyWith(
      amountText: text,
      amount: amount,
    ));
  }

  void updateDestinationAccountNameText(String text) {
    emit(state.copyWith(
      destinationAccountNameText: text,
      destinationName: text.isEmpty ? null : text,
    ));
    _updateContactFuture();
  }

  void updateDestinationAccountNumberText(String text) {
    emit(state.copyWith(destinationAccountNumberText: text));
  }

  void updateDescriptionText(String text) {
    emit(state.copyWith(
      descriptionText: text,
      description: text.isEmpty ? null : text,
    ));
  }

  @override
  void maybeAddInitialMessageToChatHistory() {
    // Add any initial context message for the transfer screen if needed
    // For now, we'll keep it empty to let the conversation flow naturally
  }

  void navigateBack(BuildContext context) {
    var backPath = currentScreenCubit.state.previousPath;
    context.go(backPath!);
  }

  @override
  List<KeyWordtrigger> getKeyWordHandlers(BuildContext context) {
    KeyWordtrigger backKeyHandler = KeyWordtrigger(
        regexList: ["(\b\w+\s+)?[bB]ack"],
        handler: (input) {
          navigateBack(context);
        });

    return [backKeyHandler];
  }

  @override
  List<Tool<Object, ToolOptions, Object>> getTools(BuildContext context) {
    // Create the confirm transfer tool
    final confirmTransferTool = Tool.fromFunction<Object, GenericOutput>(
      name: 'confirm_transfer',
      description: 'Confirms and executes the current transfer',
      inputJsonSchema: const {
        'type': 'object',
        'properties': {},
        'required': [],
      },
      func: (_) async {
        // Call the shared confirmTransfer method
        await confirmTransfer();
        var returnValue = GenericOutput(
            type: OutputType.localFunction,
            result: 'Transfer completed successfully');
        return returnValue;
      },
    );

    // Get tools from superclass
    final superTools = super.getTools(context);

    // Prepend the confirm transfer tool
    return [confirmTransferTool, ...superTools];
  }

  /// Confirm and execute the transfer
  Future<void> confirmTransfer() async {
    // Show dialog with transfer completed message
    if (ttsEnabled) {
      tts.speak("Transfer completed");
    }
    await showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Auto-close after 3 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return const TransferCompletedDialog();
      },
    );

    // Navigate to home screen
    if (_context.mounted) {
      // First navigate to transfer to clear state, then to home
      GoRouter.of(_context).go("/${TransferScreen.name}");
      // Small delay to ensure state is cleared
      await Future.delayed(const Duration(milliseconds: 50));
      if (_context.mounted) {
        GoRouter.of(_context).go("/home");
      }
    }
  }

  /// Update the contact lookup Future based on current destinationName
  void _updateContactFuture() {
    if (state.destinationName != null) {
      final future =
          _findMostLikelyDestinationContact(_context, state.destinationName!);
      emit(state.copyWith(mostLikelyDestinationContactFuture: future));
      // Update the destination account number when we get the contact
      future.then((contact) {
        if (contact != null) {
          emit(state.copyWith(destinationAccountNumberText: contact.iban));
        }
      });
    } else {
      emit(state.copyWith(
        mostLikelyDestinationContactFuture: Future(() => null),
        destinationAccountNumberText: '',
      ));
    }
  }

  /// Find the most likely destination contact for a given name
  Future<Contact?> _findMostLikelyDestinationContact(
      BuildContext context, String s) async {
    var contacts = await readContactsFromCsv(context);
    // insert a dummy iban if contact not in list; just for demo purposes (better than empty field)
    return findMatchingContact(contacts, s) ?? Contact(s, "GB33BUKB202015555");
  }

  // @override
  // Future<List<ParsedToolCall>> handleNewAndSwitch(Cubit<dynamic>? currentViewmodel, String? currentScreenName, List<ParsedToolCall> toolcalls, ParsedToolCall firstToolCall, MyConversationBufferWindowMemory chatMessageMemory, ChatHistory chatHistoryForUi, RunnableSequence<Object, Object> chain, ChatPromptTemplate promptTemplate, RunnableBinding<PromptValue, ChatModelOptions, ChatResult> llmWithTools, String query
  //     ) {
  //   // TODO: implement handleNewAndSwitch
  //   throw UnimplementedError();
  // }

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
