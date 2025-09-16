import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:langbar_core/ui/langfield/langfield.dart';
import 'package:langbar_core/ui/langfield/langbar_states.dart';

void main() {
  testWidgets('LangField maintains focus after submit', (WidgetTester tester) async {
    // Create a LangBarState for testing
    final langBarState = LangBarState();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: langBarState,
            child: const LangField(),
          ),
        ),
      ),
    );
    
    // Find the TextField
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    
    // Request focus on the text field
    await tester.tap(textFieldFinder);
    await tester.pump();
    
    // Verify the text field has focus
    final FocusNode focusNode = (tester.widget(textFieldFinder) as TextField).focusNode!;
    expect(focusNode.hasFocus, isTrue);
    
    // Type some text
    await tester.enterText(textFieldFinder, 'Test message');
    await tester.pump();
    
    // Simulate submit by pressing Enter
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    
    // The focus should be maintained after submit
    expect(focusNode.hasFocus, isTrue);
    
    // Simulate the sendingToOpenAI state change
    langBarState.sendingToOpenAI = true;
    await tester.pump();
    
    // Focus should still be maintained
    expect(focusNode.hasFocus, isTrue);
    
    // Simulate completion of the request
    langBarState.sendingToOpenAI = false;
    await tester.pumpAndSettle();
    
    // Focus should be restored after completion
    expect(focusNode.hasFocus, isTrue);
  });
}