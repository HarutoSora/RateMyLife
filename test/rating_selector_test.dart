import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/presentation/widgets/widgets.dart';

void main() {
  group('RatingSelector', () {
    testWidgets('renders 5 stars filled up to the current value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingSelector(value: 3, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
    });

    testWidgets('tapping a star reports its 1-based value', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingSelector(value: 1, onChanged: (value) => tapped = value),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Rate 4 out of 5'));
      await tester.pump();

      expect(tapped, 4);
    });
  });
}
