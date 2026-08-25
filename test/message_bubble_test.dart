import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/presentation/widgets/widgets.dart';

void main() {
  Message message({required bool isRead}) => Message(
        id: 'm1',
        conversationId: 'a_b',
        senderId: 'a',
        recipientId: 'b',
        content: 'hi',
        createdAt: DateTime(2026),
        isRead: isRead,
      );

  Future<void> pump(WidgetTester tester, {required bool isMine, required bool isRead}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(message: message(isRead: isRead), isMine: isMine, onLongPress: () {}),
        ),
      ),
    );
  }

  testWidgets('shows a single check for your own unread-by-them message', (tester) async {
    await pump(tester, isMine: true, isRead: false);

    expect(find.byIcon(Icons.done_rounded), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsNothing);
  });

  testWidgets('shows a double check once your own message has been read', (tester) async {
    await pump(tester, isMine: true, isRead: true);

    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    expect(find.byIcon(Icons.done_rounded), findsNothing);
  });

  testWidgets('shows no read receipt on a message received from the other person', (tester) async {
    await pump(tester, isMine: false, isRead: true);

    expect(find.byIcon(Icons.done_rounded), findsNothing);
    expect(find.byIcon(Icons.done_all_rounded), findsNothing);
  });
}
