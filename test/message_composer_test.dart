import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/presentation/widgets/widgets.dart';

void main() {
  Future<void> pump(WidgetTester tester, ValueChanged<String> onSubmit) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MessageComposer(onSubmit: onSubmit))),
    );
  }

  testWidgets('pressing Enter submits and clears the field', (tester) async {
    String? submitted;
    await pump(tester, (text) => submitted = text);

    await tester.enterText(find.byType(TextField), 'hello there');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(submitted, 'hello there');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('pressing the keyboard Enter key submits (not just the send button)', (tester) async {
    String? submitted;
    await pump(tester, (text) => submitted = text);

    await tester.enterText(find.byType(TextField), 'via keyboard');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitted, 'via keyboard');
  });

  testWidgets('Shift+Enter inserts a newline instead of submitting', (tester) async {
    String? submitted;
    await pump(tester, (text) => submitted = text);

    await tester.enterText(find.byType(TextField), 'line one');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(submitted, isNull);
  });

  testWidgets('tapping the send button submits', (tester) async {
    String? submitted;
    await pump(tester, (text) => submitted = text);

    await tester.enterText(find.byType(TextField), 'via button');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(submitted, 'via button');
  });

  testWidgets('does not submit empty/whitespace-only text', (tester) async {
    var callCount = 0;
    await pump(tester, (_) => callCount++);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(callCount, 0);
  });
}
