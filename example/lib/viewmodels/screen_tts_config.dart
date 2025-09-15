import 'package:langbar_core/tts_highlight_service.dart';
import 'package:langbar_core/utils/utils.dart';
import 'package:langbar_core/ui/cubits/current_screen_cubit.dart';

/// Base class for screen TTS and highlighting configuration
abstract class ScreenTtsConfig {
  /// The screen name to use as prefix when speaking
  String get screenName;
  
  /// The tab bar icon field ID for highlighting
  String? get tabBarIconFieldId => null;
  
  /// Builds TTS parameters based on current and previous values
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  });
  
  /// Speaks confirmations with highlighting
  void speakConfirmations({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required CurrentScreenCubit currentScreenCubit,
  }) {
    List<TtsParameter> parameters = buildTtsParameters(
      currentValues: currentValues,
      previousValues: previousValues,
      hasScreenChanged: currentScreenCubit.state.hasScreenChanged,
    );
    
    String? prefix;
    if (currentScreenCubit.state.hasScreenChanged) {
      prefix = screenName;
    }
    
    // Speak with highlighting
    if (parameters.isNotEmpty) {
      langbarLogger.d(
          "Speaking parameters with highlighting: ${parameters.map((p) => p.spokenText).join(', ')}");
      TtsHighlightService.instance.speakParametersWithHighlight(
        prefix,
        parameters,
        tabIconId: tabBarIconFieldId,
      );
    }
  }
}

/// Transfer screen TTS configuration
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
    
    if (amount != null &&
        (amount != previousAmount || hasScreenChanged)) {
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

/// Map screen TTS configuration
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
      parameters.add(TtsParameter(
        fieldId: fieldId,
        label: hasScreenChanged || previousLocation == null
            ? 'showing'
            : 'changed to',
        value: selectedLocation == 'atms' ? 'ATMs' : 'Offices',
      ));
    }
    
    return parameters;
  }
}

/// Contacts screen TTS configuration
class ContactsScreenTtsConfig extends ScreenTtsConfig {
  @override
  String get screenName => 'Contacts';
  
  @override
  String? get tabBarIconFieldId => 'contacts_icon';
  
  @override
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  }) {
    List<TtsParameter> parameters = [];
    
    final selectedContact = currentValues['selectedContact'] as String?;
    final previousContact = previousValues?['selectedContact'] as String?;
    
    if (selectedContact != null &&
        (selectedContact != previousContact || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'contact_selection',
        label: hasScreenChanged || previousContact == null
            ? 'selected contact'
            : 'changed to',
        value: selectedContact,
      ));
    }
    
    return parameters;
  }
}

/// Accounts screen TTS configuration
class AccountsScreenTtsConfig extends ScreenTtsConfig {
  @override
  String get screenName => 'Accounts';
  
  @override
  String? get tabBarIconFieldId => 'accounts_icon';
  
  @override
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  }) {
    List<TtsParameter> parameters = [];
    
    final selectedAccount = currentValues['selectedAccount'] as String?;
    final previousAccount = previousValues?['selectedAccount'] as String?;
    
    if (selectedAccount != null &&
        (selectedAccount != previousAccount || hasScreenChanged)) {
      parameters.add(TtsParameter(
        fieldId: 'account_selection',
        label: hasScreenChanged || previousAccount == null
            ? 'selected account'
            : 'changed to',
        value: selectedAccount,
      ));
    }
    
    return parameters;
  }
}

/// Home screen TTS configuration
class HomeScreenTtsConfig extends ScreenTtsConfig {
  @override
  String get screenName => 'Home';
  
  @override
  String? get tabBarIconFieldId => 'home_icon';
  
  @override
  List<TtsParameter> buildTtsParameters({
    required Map<String, dynamic> currentValues,
    Map<String, dynamic>? previousValues,
    required bool hasScreenChanged,
  }) {
    List<TtsParameter> parameters = [];
    
    // Home screen might not have specific parameters to speak
    // but we include it for consistency
    if (hasScreenChanged) {
      // Could add welcome message or status updates here
    }
    
    return parameters;
  }
}