import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/profile_service.dart';

void main() {
  group('ProfileService', () {
    final service = ProfileService();

    test('recalculates profile and appends history', () {
      final profile = _profile();
      final updated = service.recalculate(profile);
      expect(updated.score.overall, inInclusiveRange(0, 100));
      expect(updated.history, isNotEmpty);
    });

    test('respects private profile visibility', () {
      final profile = _profile().copyWith(
        privacy: const ProfilePrivacy(visibility: ProfileVisibility.private),
      );
      expect(service.isVisibleInDiscover(profile, const {}), isFalse);
    });

    test('respects discover and leaderboard privacy', () {
      final profile = _profile().copyWith(
        ratingSummary: const RatingSummary(averageOverall: 8, count: 10),
        privacy: const ProfilePrivacy(showInDiscover: false, showInLeaderboard: false),
      );
      expect(service.isVisibleInDiscover(profile, const {}), isFalse);
      expect(service.isVisibleInLeaderboard(profile, const {}), isFalse);
    });

    test('blocked profiles are hidden', () {
      final profile = _profile();
      expect(service.isVisibleInDiscover(profile, {'p'}), isFalse);
    });
  });
}

UserProfile _profile() {
  final now = DateTime(2026);
  return UserProfile(
    id: 'p',
    displayName: 'Tester',
    age: 24,
    country: 'Morocco',
    city: 'Rabat',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: 10000,
    currency: 'MAD',
    savings: 50000,
    investments: 0,
    debt: 0,
    monthlyExpenses: 4000,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: false,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const ['Travel'],
    freeTimeHours: 12,
    closeFriends: 4,
    happiness: 7,
    stress: 4,
    currentGoal: 'Grow',
    bio: 'Building.',
    photos: const [],
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}
