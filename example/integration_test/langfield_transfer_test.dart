import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:langbar/main.dart' as app;
import 'package:langbar_core/ui/langfield/langfield.dart';
import 'package:langbar/ui/screens/transfer_screen.dart';
import 'package:langbar/viewmodels/transfer_screen_view_model.dart';
import 'package:langbar/ui/screens/map_screen.dart';
import 'package:langbar/viewmodels/map_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart' show currentScreenCubit;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LangField Navigation Integration Test', () {
    testWidgets('Navigate to Transfer screen with "40 to robert"', (WidgetTester tester) async {
      // Start the app using the main function
      app.main();
      await tester.pumpAndSettle();

      // Wait for the app to fully initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Find the LangField widget specifically
      final langFieldFinder = find.byType(LangField);
      expect(langFieldFinder, findsOneWidget);
      
      // Find the TextField inside the LangField
      final textFieldInLangField = find.descendant(
        of: langFieldFinder,
        matching: find.byType(TextField),
      );
      
      // Tap on the TextField inside LangField to focus it
      await tester.tap(textFieldInLangField);
      await tester.pumpAndSettle();
      
      // Enter the text "40 to robert"
      await tester.enterText(textFieldInLangField, '40 to robert');
      await tester.pumpAndSettle();
      
      // Verify the text was entered correctly
      expect(find.text('40 to robert'), findsOneWidget);
      
      // Submit the text by pressing enter or finding submit mechanism
      // Try to find and tap any submit button or trigger submission
      final textField = tester.widget<TextField>(textFieldInLangField);
      
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
          
        // Verify that currentScreenCubit is set to TransferScreenViewModel
        final currentViewModel = currentScreenCubit.state.currentViewModel;
        expect(currentViewModel, isNotNull,
          reason: 'Current screen cubit should have a current ViewModel');
        expect(currentViewModel, isA<TransferScreenViewModel>(), 
          reason: 'Current screen cubit should be set to TransferScreenViewModel');
        
        // Additional verification: check the ViewModel has the correct values
        final transferViewModel = currentViewModel as TransferScreenViewModel;
        expect(transferViewModel.state.amount, equals(40.0),
          reason: 'TransferScreenViewModel should have amount = 40.0');
        expect(transferViewModel.state.destinationName, equals('robert'),
          reason: 'TransferScreenViewModel should have destinationName = robert');
        
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
        
        print('✓ Test passed: Successfully navigated to Transfer screen with correct values and currentScreenCubit set to TransferScreenViewModel');
      } else {
        // If we didn't find the Transfer screen, let's see what screens are available
        final allWidgets = find.byType(Widget);
        print('Available widgets on screen:');
        for (final element in allWidgets.evaluate().take(10)) {
          print('- ${element.widget.runtimeType}');
        }
        
        fail('Expected to navigate to Transfer screen, but Transfer screen was not found');
      }
      
      // Second test step: Navigate to Map screen with "show offices"
      print('Starting second test step: Map screen navigation...');
      
      // Find the LangField again for the second test
      final langFieldFinder2 = find.byType(LangField);
      expect(langFieldFinder2, findsOneWidget);
      
      // Find the TextField inside the LangField
      final textFieldInLangField2 = find.descendant(
        of: langFieldFinder2,
        matching: find.byType(TextField),
      );
      
      await tester.tap(textFieldInLangField2);
      await tester.pumpAndSettle();
      
      // Clear the existing text and enter "find bank offices near me"
      await tester.enterText(textFieldInLangField2, 'find bank offices near me');
      await tester.pumpAndSettle();
      
      // Verify the text was entered correctly
      expect(find.text('find bank offices near me'), findsOneWidget);
      
      // Submit the text
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      
      // Alternative submission method
      final textField2 = tester.widget<TextField>(textFieldInLangField2);
      if (textField2.onSubmitted != null) {
        textField2.onSubmitted!('find bank offices near me');
        await tester.pumpAndSettle();
      }
      
      // Wait for navigation and LLM processing
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Check if we navigated to the Map screen
      final mapScreenFinder = find.byType(MapScreen);
      
      if (mapScreenFinder.evaluate().isNotEmpty) {
        // Verify the Map screen is displayed
        expect(mapScreenFinder, findsOneWidget, 
          reason: 'Should navigate to Map screen');
          
        // Verify that currentScreenCubit is set to MapScreenViewModel
        final currentViewModel2 = currentScreenCubit.state.currentViewModel;
        expect(currentViewModel2, isNotNull,
          reason: 'Current screen cubit should have a current ViewModel');
        expect(currentViewModel2, isA<MapScreenViewModel>(), 
          reason: 'Current screen cubit should be set to MapScreenViewModel');
        
        // Verify the ViewModel has 'offices' selected
        final mapViewModel = currentViewModel2 as MapScreenViewModel;
        expect(mapViewModel.state.selectedLocation, equals('offices'),
          reason: 'MapScreenViewModel should have selectedLocation = offices');
        
        // Check that the 'Offices' radio button is selected
        final officesRadio = find.widgetWithText(RadioListTile<String>, 'Offices');
        expect(officesRadio, findsOneWidget, 
          reason: 'Should find Offices radio button');
          
        // Verify the radio button is selected by checking its groupValue matches 'offices'
        final officesRadioWidget = tester.widget<RadioListTile<String>>(officesRadio);
        expect(officesRadioWidget.groupValue, equals('offices'),
          reason: 'Offices radio button should be selected');
        
        print('✓ Test passed: Successfully navigated to Map screen with offices selected and currentScreenCubit set to MapScreenViewModel');
      } else {
        // If we didn't find the Map screen, let's see what screens are available
        final allWidgets2 = find.byType(Widget);
        print('Available widgets on screen after "find bank offices near me":');
        for (final element in allWidgets2.evaluate().take(10)) {
          print('- ${element.widget.runtimeType}');
        }
        
        fail('Expected to navigate to Map screen, but Map screen was not found');
      }
    });
  });
}