import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/trending_service.dart';

UserProfile _profile({required String id, required DateTime createdAt, int viewCount = 0, int ratingCount = 0}) {
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
    score: LifeScore.empty(),
    ratingSummary: RatingSummary(averageOverall: ratingCount > 0 ? 4 : 0, count: ratingCount),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: createdAt,
    updatedAt: createdAt,
    viewCount: viewCount,
  );
}

void main() {
  group('TrendingService', () {
    const service = TrendingService(windowDays: 14);
    final now = DateTime(2026, 8, 24);

    test('excludes profiles created outside the recency window', () {
      final fresh = _profile(id: 'fresh', createdAt: now.subtract(const Duration(days: 5)), viewCount: 10);
      final old = _profile(id: 'old', createdAt: now.subtract(const Duration(days: 30)), viewCount: 1000);

      final ranked = service.rank([fresh, old], now: now);

      expect(ranked.map((p) => p.id), ['fresh']);
    });

    test('engagementScoreOf weights ratings above plain views', () {
      final heavilyViewed = _profile(id: 'viewed', createdAt: now, viewCount: 100);
      final heavilyRated = _profile(id: 'rated', createdAt: now, viewCount: 10, ratingCount: 30);

      // rated: 10 + 30*3 = 100, viewed: 100 + 0 = 100 — equal engagement,
      // so this specifically checks the weighting formula, not just ordering.
      expect(service.engagementScoreOf(heavilyViewed), 100);
      expect(service.engagementScoreOf(heavilyRated), 100);
    });

    test('ranks by engagement score, highest first', () {
      final low = _profile(id: 'low', createdAt: now, viewCount: 5);
      final high = _profile(id: 'high', createdAt: now, viewCount: 5, ratingCount: 10);

      final ranked = service.rank([low, high], now: now);

      expect(ranked.map((p) => p.id), ['high', 'low']);
    });

    test('ties break by newest first', () {
      final older = _profile(id: 'older', createdAt: now.subtract(const Duration(days: 3)), viewCount: 10);
      final newer = _profile(id: 'newer', createdAt: now.subtract(const Duration(days: 1)), viewCount: 10);

      final ranked = service.rank([older, newer], now: now);

      expect(ranked.map((p) => p.id), ['newer', 'older']);
    });

    test('a custom windowDays is respected', () {
      const strict = TrendingService(windowDays: 2);
      final justOutside = _profile(id: 'p', createdAt: now.subtract(const Duration(days: 3)));

      expect(strict.rank([justOutside], now: now), isEmpty);
    });
  });
}
