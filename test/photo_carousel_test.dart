import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/presentation/widgets/widgets.dart';

ProfilePhoto _photo(String label, {required int order, bool isProfilePhoto = false}) {
  return ProfilePhoto(
    id: label,
    ownerId: 'me',
    path: 'mock://$label',
    isProfilePhoto: isProfilePhoto,
    order: order,
    createdAt: DateTime(2026),
  );
}

Future<void> _pump(WidgetTester tester, List<ProfilePhoto> photos) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: PhotoCarousel(photos: photos, label: 'Me'))));
  await tester.pumpAndSettle();
}

void main() {
  group('PhotoCarousel', () {
    testWidgets('falls back to a static photo with no swipe UI when there are 0-1 photos', (tester) async {
      await _pump(tester, []);
      expect(find.byType(PageView), findsNothing);

      await _pump(tester, [_photo('Solo', order: 0)]);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('SOLO'), findsOneWidget);
    });

    testWidgets('with multiple photos, opens on the designated profile photo regardless of order', (tester) async {
      final photos = [
        _photo('First', order: 0),
        _photo('Cover', order: 1, isProfilePhoto: true),
        _photo('Third', order: 2),
      ];
      await _pump(tester, photos);

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('COVER'), findsOneWidget);
      expect(find.text('FIRST'), findsNothing);
    });

    testWidgets('tapping the right half advances to the next photo, clamped at the end', (tester) async {
      final photos = [
        _photo('One', order: 0, isProfilePhoto: true),
        _photo('Two', order: 1),
      ];
      await _pump(tester, photos);
      expect(find.text('ONE'), findsOneWidget);

      final size = tester.getSize(find.byType(PhotoCarousel));
      final topLeft = tester.getTopLeft(find.byType(PhotoCarousel));
      await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));
      await tester.pumpAndSettle();
      expect(find.text('TWO'), findsOneWidget);

      // Already on the last photo — tapping right again stays put.
      await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));
      await tester.pumpAndSettle();
      expect(find.text('TWO'), findsOneWidget);
    });

    testWidgets('tapping the left half goes back, clamped at the start', (tester) async {
      final photos = [
        _photo('One', order: 0, isProfilePhoto: true),
        _photo('Two', order: 1),
      ];
      await _pump(tester, photos);

      final size = tester.getSize(find.byType(PhotoCarousel));
      final topLeft = tester.getTopLeft(find.byType(PhotoCarousel));
      // Move to the second photo first.
      await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));
      await tester.pumpAndSettle();
      expect(find.text('TWO'), findsOneWidget);

      await tester.tapAt(topLeft + Offset(size.width * 0.25, size.height / 2));
      await tester.pumpAndSettle();
      expect(find.text('ONE'), findsOneWidget);

      // Already on the first photo — tapping left again stays put.
      await tester.tapAt(topLeft + Offset(size.width * 0.25, size.height / 2));
      await tester.pumpAndSettle();
      expect(find.text('ONE'), findsOneWidget);
    });
  });
}
