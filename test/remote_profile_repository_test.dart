import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

UserProfile _profile({required String id, double income = 5000, double savings = 20000}) {
  final now = DateTime(2026, 1, 1);
  return UserProfile(
    id: id,
    displayName: 'Tester',
    age: 24,
    country: 'Morocco',
    city: 'Rabat',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: income,
    currency: 'MAD',
    savings: savings,
    investments: 0,
    debt: 0,
    monthlyExpenses: 1000,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: false,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const [],
    freeTimeHours: 10,
    closeFriends: 3,
    happiness: 7,
    stress: 3,
    currentGoal: 'Grow',
    bio: '',
    photos: const [],
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late RemoteProfileRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
    repo = RemoteProfileRepository(firestore: firestore, auth: auth);
  });

  group('RemoteProfileRepository.saveCurrentProfile', () {
    test('splits income/savings/financeExtra into owner-only subdocuments', () async {
      await repo.saveCurrentProfile(_profile(id: 'me', income: 7000, savings: 30000));

      final publicDoc = await firestore.collection('profiles').doc('me').get();
      expect(publicDoc.data()!.containsKey('monthlyIncome'), isFalse);
      expect(publicDoc.data()!.containsKey('savings'), isFalse);

      final income = await firestore.collection('profiles').doc('me').collection('private').doc('income').get();
      expect(income.data()!['monthlyIncome'], 7000);

      final savings = await firestore.collection('profiles').doc('me').collection('private').doc('savings').get();
      expect(savings.data()!['savings'], 30000);
    });

    test('round-trips a saved profile correctly via loadCurrentProfile', () async {
      await repo.saveCurrentProfile(_profile(id: 'me', income: 7000, savings: 30000));

      final loaded = await repo.loadCurrentProfile();
      expect(loaded, isNotNull);
      expect(loaded!.id, 'me');
      expect(loaded.monthlyIncome, 7000);
      expect(loaded.savings, 30000);
    });

    // Regression test: saveCurrentProfile used to do a non-merging
    // set(), so a profile edit could silently overwrite a live
    // ratingSummary/viewCount with this device's stale local copy.
    test('does not clobber a live ratingSummary set by another device', () async {
      await repo.saveCurrentProfile(_profile(id: 'me'));

      // Simulate another device's rater transaction updating the
      // aggregate directly, bypassing this repository entirely.
      await firestore.collection('profiles').doc('me').update({
        'ratingSummary': const RatingSummary(averageOverall: 4.5, count: 3).toJson(),
      });

      // This device now saves its own profile edit, built from a
      // UserProfile whose local `ratingSummary` is still the stale
      // default (count: 0) — that must not overwrite the live value.
      await repo.saveCurrentProfile(_profile(id: 'me'));

      final doc = await firestore.collection('profiles').doc('me').get();
      final summary = RatingSummary.fromJson(doc.data()!['ratingSummary'] as Map<String, dynamic>?);
      expect(summary.count, 3);
      expect(summary.averageOverall, 4.5);
    });

    test('does not clobber a live viewCount set by another device', () async {
      await repo.saveCurrentProfile(_profile(id: 'me'));
      await firestore.collection('profiles').doc('me').update({'viewCount': 12});

      await repo.saveCurrentProfile(_profile(id: 'me'));

      final doc = await firestore.collection('profiles').doc('me').get();
      expect(doc.data()!['viewCount'], 12);
    });
  });

  group('RemoteProfileRepository.recordProfileView', () {
    test('increments an existing target profile\'s view count', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'them'), signedIn: true);
      final otherRepo = RemoteProfileRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.saveCurrentProfile(_profile(id: 'them'));

      await repo.recordProfileView('them');
      await repo.recordProfileView('them');

      final doc = await firestore.collection('profiles').doc('them').get();
      expect(doc.data()!['viewCount'], 2);
    });

    test('does not record a self-view', () async {
      await repo.saveCurrentProfile(_profile(id: 'me'));
      await repo.recordProfileView('me');

      final doc = await firestore.collection('profiles').doc('me').get();
      expect(doc.data()!['viewCount'], anyOf(isNull, 0));
    });

    test('is a no-op for a profile with no real Firestore doc (mock target)', () async {
      // Should complete without throwing even though "mock_1" was
      // never saved by anyone.
      await repo.recordProfileView('mock_1');
    });
  });

  group('RemoteProfileRepository.newProfileId', () {
    test('returns the authenticated Firebase UID', () {
      expect(repo.newProfileId(), 'me');
    });
  });

  group('RemoteProfileRepository pagination', () {
    // Writes straight to Firestore (bypassing saveCurrentProfile, which
    // only ever writes the signed-in uid's own doc) so several "other
    // users'" profiles can be seeded in one test.
    Future<void> seed(String id, {required DateTime createdAt, double rating = 0, int ratingCount = 0}) async {
      final profile = _profile(id: id).copyWith(
        createdAt: createdAt,
        ratingSummary: RatingSummary(averageOverall: rating, count: ratingCount),
      );
      await firestore.collection('profiles').doc(id).set(profile.toJson());
    }

    // The mock seed cast is mixed into the first page (see
    // `_withSeedOnFirstPage`) — irrelevant to these ordering/cursor
    // assertions, so it's filtered out rather than asserted on.
    List<String> realIds(ProfilesPage page) =>
        page.profiles.where((p) => !p.id.startsWith('mock_')).map((p) => p.id).toList();

    test('loadDiscoverPage returns newest first, bounded by limit, with a working cursor', () async {
      await seed('a', createdAt: DateTime(2026, 1, 1));
      await seed('b', createdAt: DateTime(2026, 1, 2));
      await seed('c', createdAt: DateTime(2026, 1, 3));

      final first = await repo.loadDiscoverPage(limit: 2);
      expect(realIds(first), ['c', 'b']);
      expect(first.hasMore, isTrue);

      final second = await repo.loadDiscoverPage(limit: 2, after: first.profiles.firstWhere((p) => p.id == 'b'));
      expect(realIds(second), ['a']);
      expect(second.hasMore, isFalse);
    });

    test('loadLeaderboardPage orders by community rating, highest first', () async {
      await seed('low', createdAt: DateTime(2026, 1, 1), rating: 2, ratingCount: 5);
      await seed('high', createdAt: DateTime(2026, 1, 1), rating: 4.5, ratingCount: 5);

      final page = await repo.loadLeaderboardPage(limit: 10);
      expect(realIds(page), ['high', 'low']);
    });

    test('loadGapPage orders by rating count, highest first', () async {
      await seed('few', createdAt: DateTime(2026, 1, 1), ratingCount: 2);
      await seed('many', createdAt: DateTime(2026, 1, 1), ratingCount: 20);

      final page = await repo.loadGapPage(limit: 10);
      expect(realIds(page), ['many', 'few']);
    });

    test('loadTrendingPage excludes profiles created before the cutoff', () async {
      final now = DateTime(2026, 6, 1);
      await seed('fresh', createdAt: now.subtract(const Duration(days: 1)));
      await seed('old', createdAt: now.subtract(const Duration(days: 60)));

      final page = await repo.loadTrendingPage(limit: 10, since: now.subtract(const Duration(days: 14)));
      expect(page.profiles.map((p) => p.id), ['fresh']);
    });

    test('loadProfileById returns null for a profile with no real Firestore doc', () async {
      expect(await repo.loadProfileById('nobody'), isNull);
    });

    test('loadProfileById round-trips a real profile including private fields', () async {
      await repo.saveCurrentProfile(_profile(id: 'me', income: 9000, savings: 40000));

      final loaded = await repo.loadProfileById('me');

      expect(loaded, isNotNull);
      expect(loaded!.monthlyIncome, 9000);
      expect(loaded.savings, 40000);
    });
  });
}
