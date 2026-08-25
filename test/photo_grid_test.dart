import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/presentation/widgets/widgets.dart';

ProfilePhoto _photo(String id, {required int order, bool isProfilePhoto = false}) => ProfilePhoto(
      id: id,
      ownerId: 'them',
      path: 'mock://$id',
      isProfilePhoto: isProfilePhoto,
      order: order,
      createdAt: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, Widget grid) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: grid)));
  await tester.pumpAndSettle();
}

void main() {
  group('PhotoGrid best-photo voting', () {
    testWidgets('hides the vote affordance when onVote is null, but still shows Fan Favorite', (tester) async {
      final photos = [_photo('cover', order: 0, isProfilePhoto: true), _photo('p1', order: 1)];
      await _pump(tester, PhotoGrid(photos: photos, onTap: (_) {}, voteCounts: const {'p1': 3}));

      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.text('Fan Favorite'), findsOneWidget);
    });

    testWidgets('shows an outline heart per votable photo, and a filled one for my own pick', (tester) async {
      final photos = [_photo('p1', order: 0), _photo('p2', order: 1)];
      await _pump(
        tester,
        PhotoGrid(photos: photos, onTap: (_) {}, myVotedPhotoId: 'p1', onVote: (_) {}),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('tapping the heart calls onVote with that photo\'s id', (tester) async {
      final photos = [_photo('p1', order: 0), _photo('p2', order: 1)];
      String? voted;
      await _pump(
        tester,
        PhotoGrid(photos: photos, onTap: (_) {}, onVote: (id) => voted = id),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pump();

      expect(voted, isNotNull);
    });

    testWidgets('shows Fan Favorite only on the photo with the highest vote count', (tester) async {
      final photos = [_photo('p1', order: 0), _photo('p2', order: 1)];
      await _pump(
        tester,
        PhotoGrid(photos: photos, onTap: (_) {}, voteCounts: const {'p1': 5, 'p2': 1}),
      );

      expect(find.text('Fan Favorite'), findsOneWidget);
    });

    testWidgets('no Fan Favorite badge when nobody has voted yet', (tester) async {
      final photos = [_photo('p1', order: 0), _photo('p2', order: 1)];
      await _pump(tester, PhotoGrid(photos: photos, onTap: (_) {}));

      expect(find.text('Fan Favorite'), findsNothing);
    });
  });
}
