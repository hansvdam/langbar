import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:langbar/main.dart' as app;
import 'package:langbar/ui/screens/transfer_screen.dart';
import 'package:langbar/viewmodels/transfer_screen_view_model.dart';
import 'package:langbar/ui/screens/map_screen.dart';
import 'package:langbar/viewmodels/map_screen_view_model.dart';
import 'package:langbar_core/utils/utils.dart' show currentScreenCubit;
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LangField Navigation Integration Test', () {
    testWidgets('Navigate to Transfer screen with "40 to robert"', (WidgetTester tester) async {
      // Start the app using the main function
      app.main();
      await tester.pumpAndSettle();

      // Wait for the app to fully initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Submit query using helper function
      await LangFieldTestHelpers.submitLangFieldQuery(tester, '40 to robert');
      
      // Wait for both Transfer screen and TransferScreenViewModel with early exit
      final navigationSuccessful = await LangFieldTestHelpers.waitForScreenAndViewModel(
        tester, 
        TransferScreen, 
        TransferScreenViewModel,
        timeout: const Duration(seconds: 10),
        pollInterval: const Duration(milliseconds: 300)
      );
      
      if (navigationSuccessful) {
        // Get the finder now that we know navigation succeeded
        final transferScreenFinder = find.byType(TransferScreen);
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
      
      // Submit query using helper function
      await LangFieldTestHelpers.submitLangFieldQuery(tester, 'find bank offices near me');
      
      // Wait for both Map screen and MapScreenViewModel with early exit
      final navigationSuccessful2 = await LangFieldTestHelpers.waitForScreenAndViewModel(
        tester, 
        MapScreen, 
        MapScreenViewModel,
        timeout: const Duration(seconds: 10),
        pollInterval: const Duration(milliseconds: 300)
      );
      
      if (navigationSuccessful2) {
        // Get the finder now that we know navigation succeeded
        final mapScreenFinder = find.byType(MapScreen);
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
      
      // Third test step: Navigate back to Transfer screen with "70 to Mary for dinner"
      print('Starting third test step: Transfer screen navigation with description...');
      
      // Submit query using helper function
      await LangFieldTestHelpers.submitLangFieldQuery(tester, '70 to Mary for dinner');
      
      // Wait for both Transfer screen and TransferScreenViewModel with early exit
      final navigationSuccessful3 = await LangFieldTestHelpers.waitForScreenAndViewModel(
        tester, 
        TransferScreen, 
        TransferScreenViewModel,
        timeout: const Duration(seconds: 10),
        pollInterval: const Duration(milliseconds: 300)
      );
      
      if (navigationSuccessful3) {
        // Get the finder now that we know navigation succeeded
        final transferScreenFinder3 = find.byType(TransferScreen);
        
        // Verify the Transfer screen is displayed
        expect(transferScreenFinder3, findsOneWidget, 
          reason: 'Should navigate to Transfer screen for third test');
          
        // Verify that currentScreenCubit is set to TransferScreenViewModel
        final currentViewModel3 = currentScreenCubit.state.currentViewModel;
        expect(currentViewModel3, isNotNull,
          reason: 'Current screen cubit should have a current ViewModel for third test');
        expect(currentViewModel3, isA<TransferScreenViewModel>(), 
          reason: 'Current screen cubit should be set to TransferScreenViewModel for third test');
        
        // Additional verification: check the ViewModel has the correct values
        final transferViewModel3 = currentViewModel3 as TransferScreenViewModel;
        expect(transferViewModel3.state.amount, equals(70.0),
          reason: 'TransferScreenViewModel should have amount = 70.0');
        expect(transferViewModel3.state.destinationName, equals('Mary'),
          reason: 'TransferScreenViewModel should have destinationName = Mary');
        expect(transferViewModel3.state.description, equals('dinner'),
          reason: 'TransferScreenViewModel should have description = dinner');
        
        // Check for amount field with "70"
        final amountTextFields3 = find.descendant(
          of: transferScreenFinder3,
          matching: find.byType(TextFormField)
        );
        
        bool foundAmountField3 = false;
        bool foundDestinationField3 = false;
        bool foundDescriptionField3 = false;
        
        // Check each TextFormField for the expected values
        for (final element in amountTextFields3.evaluate()) {
          final textField = element.widget as TextFormField;
          final initialValue = textField.initialValue;
          
          if (initialValue != null) {
            if (initialValue.contains('70')) {
              foundAmountField3 = true;
            }
            if (initialValue.toLowerCase().contains('mary')) {
              foundDestinationField3 = true;
            }
            if (initialValue.toLowerCase().contains('dinner')) {
              foundDescriptionField3 = true;
            }
          }
        }
        
        expect(foundAmountField3, isTrue, 
          reason: 'Transfer screen should have amount field filled with "70"');
        expect(foundDestinationField3, isTrue, 
          reason: 'Transfer screen should have destination field filled with "Mary"');
        expect(foundDescriptionField3, isTrue, 
          reason: 'Transfer screen should have description field filled with "dinner"');
        
        print('✓ Test passed: Successfully navigated to Transfer screen with amount=70, destination=Mary, description=dinner and currentScreenCubit set to TransferScreenViewModel');
      } else {
        // If we didn't find the Transfer screen, let's see what screens are available
        final allWidgets3 = find.byType(Widget);
        print('Available widgets on screen after "70 to Mary for dinner":');
        for (final element in allWidgets3.evaluate().take(10)) {
          print('- ${element.widget.runtimeType}');
        }
        
        fail('Expected to navigate to Transfer screen for third test, but Transfer screen was not found');
      }
      
      // Fourth test step: Test amount correction with "no 80"
      // This should be interpreted as "no, make it 80" - correcting the previous amount from 70 to 80
      print('Starting fourth test step: Testing amount correction from 70 to 80...');
      
      // Submit query using helper function
      await LangFieldTestHelpers.submitLangFieldQuery(tester, 'no 80');
      
      // Wait for Transfer screen and TransferScreenViewModel (should stay on or return to transfer screen)
      final navigationSuccessful4 = await LangFieldTestHelpers.waitForScreenAndViewModel(
        tester, 
        TransferScreen, 
        TransferScreenViewModel,
        timeout: const Duration(seconds: 10),
        pollInterval: const Duration(milliseconds: 300)
      );
      
      if (navigationSuccessful4) {
        // Get the finder now that we know we're on transfer screen
        final transferScreenFinder4 = find.byType(TransferScreen);
        
        // Verify the Transfer screen is displayed
        expect(transferScreenFinder4, findsOneWidget, 
          reason: 'Should be on Transfer screen after amount correction');
          
        // Verify that currentScreenCubit is set to TransferScreenViewModel
        final currentViewModel4 = currentScreenCubit.state.currentViewModel;
        expect(currentViewModel4, isNotNull,
          reason: 'Current screen cubit should have a current ViewModel for amount correction');
        expect(currentViewModel4, isA<TransferScreenViewModel>(), 
          reason: 'Current screen cubit should be set to TransferScreenViewModel for amount correction');
        
        // Additional verification: check the ViewModel has the corrected amount
        final transferViewModel4 = currentViewModel4 as TransferScreenViewModel;
        expect(transferViewModel4.state.amount, equals(80.0),
          reason: 'TransferScreenViewModel should have corrected amount = 80.0 (was 70.0)');
        
        // Destination and description should remain the same from previous state
        expect(transferViewModel4.state.destinationName, equals('Mary'),
          reason: 'TransferScreenViewModel should keep destinationName = Mary');
        expect(transferViewModel4.state.description, equals('dinner'),
          reason: 'TransferScreenViewModel should keep description = dinner');
        
        // Check for amount field with "80"
        final amountTextFields4 = find.descendant(
          of: transferScreenFinder4,
          matching: find.byType(TextFormField)
        );
        
        bool foundCorrectedAmountField = false;
        bool foundSameDestinationField = false;
        bool foundSameDescriptionField = false;
        
        // Check each TextFormField for the expected values
        for (final element in amountTextFields4.evaluate()) {
          final textField = element.widget as TextFormField;
          final initialValue = textField.initialValue;
          
          if (initialValue != null) {
            if (initialValue.contains('80')) {
              foundCorrectedAmountField = true;
            }
            if (initialValue.toLowerCase().contains('mary')) {
              foundSameDestinationField = true;
            }
            if (initialValue.toLowerCase().contains('dinner')) {
              foundSameDescriptionField = true;
            }
          }
        }
        
        expect(foundCorrectedAmountField, isTrue, 
          reason: 'Transfer screen should have amount field corrected to "80"');
        expect(foundSameDestinationField, isTrue, 
          reason: 'Transfer screen should still have destination field with "Mary"');
        expect(foundSameDescriptionField, isTrue, 
          reason: 'Transfer screen should still have description field with "dinner"');
        
        print('✓ Test passed: Amount correction "no 80" successfully changed amount from 70 to 80 while preserving Mary and dinner');
      } else {
        // If we didn't find the Transfer screen, this is unexpected for amount correction
        final allWidgets4 = find.byType(Widget);
        print('Available widgets on screen after "no 80":');
        for (final element in allWidgets4.evaluate().take(10)) {
          print('- ${element.widget.runtimeType}');
        }
        
        fail('Expected to be on Transfer screen for amount correction "no 80", but Transfer screen was not found');
      }
    });
  });
}