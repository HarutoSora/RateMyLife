import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/domain/services/rating_service.dart';

void main() {
  group('RemoteRatingRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late RemoteRatingRepository repo;
    final service = RatingService();

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
      repo = RemoteRatingRepository(firestore: firestore, auth: auth);
      await firestore.collection('profiles').doc('them').set({'ratingSummary': <String, dynamic>{}});
    });

    test('loadRatings starts empty', () async {
      expect(await repo.loadRatings(), isEmpty);
    });

    test('saveRatings persists this device\'s rating and updates the target\'s summary', () async {
      await repo.loadRatings();
      final rating = service.upsertRating(existing: const [], raterId: 'me', profileId: 'them', overall: 4, look: 5);
      await repo.saveRatings([rating]);

      final loaded = await repo.loadRatings();
      expect(loaded.single.profileId, 'them');
      expect(loaded.single.overall, 4);

      final profile = await firestore.collection('profiles').doc('them').get();
      final summary = profile.data()!['ratingSummary'] as Map<String, dynamic>;
      expect(summary['count'], 1);
      expect(summary['averageOverall'], 4);
      expect(summary['averageLook'], 5);
    });

    test('editing an already-submitted rating updates the average without double-counting', () async {
      await repo.loadRatings();
      final first = service.upsertRating(existing: const [], raterId: 'me', profileId: 'them', overall: 2, look: 2);
      await repo.saveRatings([first]);

      final edited = service.upsertRating(existing: [first], raterId: 'me', profileId: 'them', overall: 4, look: 4);
      await repo.saveRatings([edited]);

      final profile = await firestore.collection('profiles').doc('them').get();
      final summary = profile.data()!['ratingSummary'] as Map<String, dynamic>;
      expect(summary['count'], 1);
      expect(summary['averageOverall'], 4);
    });

    test('removing a rating deletes the doc and rebalances the summary back down', () async {
      await repo.loadRatings();
      final rating = service.upsertRating(existing: const [], raterId: 'me', profileId: 'them', overall: 5, look: 5);
      await repo.saveRatings([rating]);
      await repo.saveRatings([]);

      expect(await repo.loadRatings(), isEmpty);
      final profile = await firestore.collection('profiles').doc('them').get();
      final summary = profile.data()!['ratingSummary'] as Map<String, dynamic>;
      expect(summary['count'], 0);
    });

    test('only loads this device\'s own ratings', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemoteRatingRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadRatings();
      final theirs = service.upsertRating(existing: const [], raterId: 'other', profileId: 'them', overall: 3, look: 3);
      await otherRepo.saveRatings([theirs]);

      await repo.loadRatings();
      final mine = service.upsertRating(existing: const [], raterId: 'me', profileId: 'them', overall: 5, look: 5);
      await repo.saveRatings([mine]);

      final loaded = await repo.loadRatings();
      expect(loaded.map((r) => r.raterId), ['me']);
    });

    // The exact scenario behind a live "permission-denied" investigation:
    // Discover mixes real synced profiles with mock/seed ones that have
    // no Firestore doc at all (see `_withSeedOnFirstPage`). Rating one
    // must still save the rating itself even though there's no summary
    // to update.
    test('rating a mock/seed profile with no real doc saves the rating without crashing', () async {
      await repo.loadRatings();
      final rating = service.upsertRating(existing: const [], raterId: 'me', profileId: 'mock_1', overall: 5, look: 5);
      await repo.saveRatings([rating]);

      final loaded = await repo.loadRatings();
      expect(loaded.single.profileId, 'mock_1');
    });
  });
}
