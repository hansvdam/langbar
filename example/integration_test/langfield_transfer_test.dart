import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:langbar/main.dart' as app;
import 'package:langbar_core/ui/langfield/langfield.dart';
import 'package:langbar/ui/screens/transfer_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LangField Transfer Integration Test', () {
    testWidgets('Fill langfield with "40 to robert" and navigate to Transfer screen', (WidgetTester tester) async {
      // Start the app using the main function
      app.main();
      await tester.pumpAndSettle();

      // Wait for the app to fully initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Find the LangField widget
      final langFieldFinder = find.byType(TextField).first;
      expect(langFieldFinder, findsOneWidget);
      
      // Tap on the LangField to focus it
      await tester.tap(langFieldFinder);
      await tester.pumpAndSettle();
      
      // Enter the text "40 to robert"
      await tester.enterText(langFieldFinder, '40 to robert');
      await tester.pumpAndSettle();
      
      // Verify the text was entered correctly
      expect(find.text('40 to robert'), findsOneWidget);
      
      // Submit the text by pressing enter or finding submit mechanism
      // Try to find and tap any submit button or trigger submission
      final textField = tester.widget<TextField>(langFieldFinder);
      
      // Simulate pressing enter to submit
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      
      // Alternative: try to find submit functionality through the LangField's onSubmitted callback
      if (textField.onSubmitted != null) {
        textField.onSubmitted!('40 to robert');
        await tester.pumpAndSettle();
      }
      
      // Wait for potential navigation and LLM processing
      // This might take some time as it involves LLM API calls
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Check if we navigated to the Transfer screen
      // Look for Transfer screen indicators
      final transferScreenFinder = find.byType(TransferScreen);
      
      if (transferScreenFinder.evaluate().isNotEmpty) {
        // We found the Transfer screen, now check if the values are filled correctly
        
        // Verify the Transfer screen has the correct values
        expect(transferScreenFinder, findsOneWidget, 
          reason: 'Should navigate to Transfer screen');
        
        // Check for amount field with "40"
        final amountTextFields = find.descendant(
          of: transferScreenFinder,
          matching: find.byType(TextFormField)
        );
        
        bool foundAmountField = false;
        bool foundDestinationField = false;
        
        // Check each TextFormField for the expected values
        for (final element in amountTextFields.evaluate()) {
          final textField = element.widget as TextFormField;
          final initialValue = textField.initialValue;
          
          if (initialValue != null) {
            if (initialValue.contains('40')) {
              foundAmountField = true;
            }
            if (initialValue.toLowerCase().contains('robert')) {
              foundDestinationField = true;
            }
          }
        }
        
        expect(foundAmountField, isTrue, 
          reason: 'Transfer screen should have amount field filled with "40"');
        expect(foundDestinationField, isTrue, 
          reason: 'Transfer screen should have destination field filled with "robert"');
        
        print('✓ Test passed: Successfully navigated to Transfer screen with correct values');
      } else {
        // If we didn't find the Transfer screen, let's see what screens are available
        final allWidgets = find.byType(Widget);
        print('Available widgets on screen:');
        for (final element in allWidgets.evaluate().take(10)) {
          print('- ${element.widget.runtimeType}');
        }
        
        fail('Expected to navigate to Transfer screen, but Transfer screen was not found');
      }
    });
  });
}