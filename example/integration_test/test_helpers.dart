import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langbar_core/ui/langfield/langfield.dart';
import 'package:langbar_core/utils/utils.dart' show currentScreenCubit;

/// Helper functions for integration tests involving LangField interactions
class LangFieldTestHelpers {
  
  /// Finds the LangField widget and its descendant TextField
  /// Throws if LangField is not found
  static Finder findLangFieldTextField() {
    final langFieldFinder = find.byType(LangField);
    expect(langFieldFinder, findsOneWidget, 
      reason: 'Should find exactly one LangField widget');
    
    return find.descendant(
      of: langFieldFinder,
      matching: find.byType(TextField),
    );
  }
  
  /// Enters text into the LangField and submits it
  /// Returns the TextField widget for additional operations if needed
  static Future<TextField> enterAndSubmitInLangField(
    WidgetTester tester, 
    String text
  ) async {
    // Find the TextField inside the LangField
    final textFieldInLangField = findLangFieldTextField();
    
    // Tap on the TextField to focus it
    await tester.tap(textFieldInLangField);
    await tester.pumpAndSettle();
    
    // Enter the text
    await tester.enterText(textFieldInLangField, text);
    await tester.pumpAndSettle();
    
    // Verify the text was entered correctly
    expect(find.text(text), findsOneWidget,
      reason: 'Text "$text" should be visible after entering');
    
    // Get the TextField widget for submission
    final textField = tester.widget<TextField>(textFieldInLangField);
    
    // Submit the text by pressing enter
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    
    // Alternative submission method if onSubmitted callback exists
    if (textField.onSubmitted != null) {
      textField.onSubmitted!(text);
      await tester.pumpAndSettle();
    }
    
    return textField;
  }
  
  /// Waits for LLM processing and navigation to complete
  /// Polls for completion instead of waiting for full timeout
  /// Default timeout is 10 seconds but can be customized
  static Future<void> waitForLLMProcessing(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 500)
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pumpAndSettle(pollInterval);
      
      // Check if we can settle quickly (indicates processing is complete)
      try {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        // If we can settle quickly, processing is likely complete
        break;
      } catch (e) {
        // Continue polling if we can't settle yet
      }
    }
    
    stopwatch.stop();
  }
  
  /// Complete workflow: enter text in LangField, submit, and wait for processing
  /// Includes optimized polling for faster navigation detection
  static Future<TextField> submitLangFieldQuery(
    WidgetTester tester,
    String query, {
    Duration processingTimeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 500)
  }) async {
    final textField = await enterAndSubmitInLangField(tester, query);
    await waitForLLMProcessing(
      tester, 
      timeout: processingTimeout,
      pollInterval: pollInterval
    );
    return textField;
  }
  
  /// Waits for a specific screen type to appear, with early exit on detection
  /// This is more efficient than waiting for full timeout when checking for navigation
  static Future<bool> waitForScreenType(
    WidgetTester tester,
    Type screenType, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 200)
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pumpAndSettle(pollInterval);
      
      // Check if the target screen appeared
      final screenFinder = find.byType(screenType);
      if (screenFinder.evaluate().isNotEmpty) {
        stopwatch.stop();
        return true;
      }
    }
    
    stopwatch.stop();
    return false;
  }
  
  /// Waits for a specific ViewModel type to be set in currentScreenCubit
  /// Returns early when the expected ViewModel is detected
  static Future<bool> waitForViewModelType(
    WidgetTester tester,
    Type viewModelType, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 200)
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pumpAndSettle(pollInterval);
      
      // Check if the expected ViewModel is set
      final currentViewModel = currentScreenCubit.state.currentViewModel;
      if (currentViewModel != null && currentViewModel.runtimeType == viewModelType) {
        stopwatch.stop();
        return true;
      }
    }
    
    stopwatch.stop();
    return false;
  }
  
  /// Combined helper: waits for both screen type AND ViewModel type with early exit
  /// Returns as soon as both conditions are met
  static Future<bool> waitForScreenAndViewModel(
    WidgetTester tester,
    Type screenType,
    Type viewModelType, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 200)
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pumpAndSettle(pollInterval);
      
      // Check both conditions
      final screenFinder = find.byType(screenType);
      final currentViewModel = currentScreenCubit.state.currentViewModel;
      
      if (screenFinder.evaluate().isNotEmpty && 
          currentViewModel != null && 
          currentViewModel.runtimeType == viewModelType) {
        stopwatch.stop();
        return true;
      }
    }
    
    stopwatch.stop();
    return false;
  }
}