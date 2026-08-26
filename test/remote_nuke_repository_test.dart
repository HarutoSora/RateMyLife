import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

void main() {
  group('RemoteNukeRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late RemoteNukeRepository repo;

    UserProfile targetProfile({Map<String, dynamic>? score}) {
      final now = DateTime(2026, 1, 1);
      return UserProfile(
        id: 'them',
        displayName: 'Target',
        age: 25,
        country: 'Morocco',
        city: 'Rabat',
        employmentStatus: 'Employed',
        jobCategory: 'Tech',
        yearsExperience: 3,
        educationLevel: 'Bachelor',
        monthlyIncome: 8000,
        currency: 'MAD',
        savings: 20000,
        investments: 0,
        debt: 0,
        monthlyExpenses: 3000,
        relationshipStatus: 'Single',
        livingSituation: 'Rents apartment',
        ownsCar: false,
        ownsHome: false,
        travelFrequency: 'Rarely',
        exerciseFrequency: 'Weekly',
        hobbies: const [],
        freeTimeHours: 10,
        closeFriends: 3,
        happiness: 6,
        stress: 5,
        currentGoal: '',
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

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
      repo = RemoteNukeRepository(firestore: firestore, auth: auth);
      await firestore.collection('profiles').doc('them').set({
        'score': {
          'overall': 60,
          'career': 60,
          'financial': 60,
          'education': 60,
          'independence': 60,
          'social': 60,
          'lifestyle': 60,
          'wellbeing': 60,
          'explanations': <String, dynamic>{},
          'calculatedAt': DateTime(2026, 1, 1).toIso8601String(),
        },
      });
    });

    test('loadSentHistory starts empty', () async {
      expect(await repo.loadSentHistory(), isEmpty);
    });

    test('attack persists the event and updates the target\'s damage/score/survived count', () async {
      await repo.attack(attackerId: 'me', target: targetProfile(), attribute: 'career');

      final profile = await firestore.collection('profiles').doc('them').get();
      final data = profile.data()!;
      expect((data['nukeDamage'] as Map)['career'], -5);
      expect(data['nukesSurvived'], 1);
      expect((data['score'] as Map)['career'], 55);
      // Untouched categories stay exactly as they were.
      expect((data['score'] as Map)['financial'], 60);

      final history = await repo.loadSentHistory();
      expect(history.single.targetId, 'them');
      expect(history.single.attribute, 'career');
      expect(history.single.damage, -5);
    });

    test('repeated attacks on the same attribute accumulate damage', () async {
      await repo.attack(attackerId: 'me', target: targetProfile(), attribute: 'social');
      await repo.attack(attackerId: 'me', target: targetProfile(), attribute: 'social');

      final profile = await firestore.collection('profiles').doc('them').get();
      final data = profile.data()!;
      expect((data['nukeDamage'] as Map)['social'], -10);
      expect(data['nukesSurvived'], 2);
      expect((data['score'] as Map)['social'], 50);
    });

    test('nuking a mock/seed profile with no real doc records the event without crashing', () async {
      final mockTarget = targetProfile().copyWith(id: 'mock_1', displayName: 'Mock Person');
      final event = await repo.attack(attackerId: 'me', target: mockTarget, attribute: 'wellbeing');

      expect(event.targetId, 'mock_1');
      final history = await repo.loadSentHistory();
      expect(history.single.targetId, 'mock_1');
    });

    test('only loads this device\'s own sent history', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemoteNukeRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.attack(attackerId: 'other', target: targetProfile(), attribute: 'career');
      await repo.attack(attackerId: 'me', target: targetProfile(), attribute: 'lifestyle');

      final mine = await repo.loadSentHistory();
      expect(mine.map((e) => e.attackerId), ['me']);
    });
  });
}
