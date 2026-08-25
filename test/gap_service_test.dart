import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/gap_service.dart';

UserProfile _profile({required String id, required int score, required double averageOverall, required int ratingCount}) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: id,
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
    hobbies: const [],
    freeTimeHours: 12,
    closeFriends: 4,
    happiness: 7,
    stress: 4,
    currentGoal: '',
    bio: '',
    photos: const [],
    score: LifeScore(
      overall: score,
      career: score,
      financial: score,
      education: score,
      independence: score,
      social: score,
      lifestyle: score,
      wellbeing: score,
      explanations: const {},
      calculatedAt: now,
    ),
    ratingSummary: RatingSummary(averageOverall: averageOverall, count: ratingCount),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GapService', () {
    const service = GapService();

    test('communityScoreOf rescales a 0-5 average to 0-100', () {
      expect(service.communityScoreOf(const RatingSummary(averageOverall: 5, count: 3)), 100);
      expect(service.communityScoreOf(const RatingSummary(averageOverall: 0, count: 3)), 0);
      expect(service.communityScoreOf(const RatingSummary(averageOverall: 2.5, count: 3)), 50);
    });

    test('gapFor is the absolute difference between algorithm score and rescaled community score', () {
      final profile = _profile(id: 'a', score: 80, averageOverall: 3, ratingCount: 5);
      // Community: 3 * 20 = 60. |80 - 60| = 20.
      expect(service.gapFor(profile), 20);
    });

    test('gapFor is null below the minimum rating count', () {
      final profile = _profile(id: 'a', score: 80, averageOverall: 3, ratingCount: 2);
      expect(service.gapFor(profile), isNull);
    });

    test('a custom minRatings threshold is respected', () {
      const lenient = GapService(minRatings: 1);
      final profile = _profile(id: 'a', score: 80, averageOverall: 3, ratingCount: 1);
      expect(lenient.gapFor(profile), 20);
    });

    test('rankByGap excludes ineligible profiles and sorts biggest gap first', () {
      final small = _profile(id: 'small_gap', score: 55, averageOverall: 2.75, ratingCount: 5); // gap 0
      final big = _profile(id: 'big_gap', score: 90, averageOverall: 2, ratingCount: 5); // community 40, gap 50
      final ineligible = _profile(id: 'too_few', score: 100, averageOverall: 0, ratingCount: 1); // gap would be huge, but excluded

      final ranked = service.rankByGap([small, big, ineligible]);

      expect(ranked.map((p) => p.id), ['big_gap', 'small_gap']);
    });
  });
}
