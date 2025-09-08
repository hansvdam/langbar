import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langbar_core/ui/langfield/langfield.dart';

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
  /// Default timeout is 10 seconds but can be customized
  static Future<void> waitForLLMProcessing(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10)
  }) async {
    await tester.pumpAndSettle(timeout);
  }
  
  /// Complete workflow: enter text in LangField, submit, and wait for processing
  static Future<TextField> submitLangFieldQuery(
    WidgetTester tester,
    String query, {
    Duration processingTimeout = const Duration(seconds: 10)
  }) async {
    final textField = await enterAndSubmitInLangField(tester, query);
    await waitForLLMProcessing(tester, timeout: processingTimeout);
    return textField;
  }
}