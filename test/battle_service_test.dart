import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/battle_service.dart';

UserProfile _profile(String id, {int overall = 50, String country = 'US', int ratingCount = 0}) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: id,
    age: 25,
    country: country,
    city: 'City',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    jobTitle: 'Engineer',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: 1000,
    currency: 'USD',
    savings: 0,
    investments: 0,
    debt: 0,
    monthlyExpenses: 0,
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
    score: LifeScore(
      overall: overall,
      career: overall,
      financial: overall,
      education: overall,
      independence: overall,
      social: overall,
      lifestyle: overall,
      wellbeing: overall,
      explanations: const {},
      calculatedAt: now,
    ),
    ratingSummary: RatingSummary(count: ratingCount),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BattleService', () {
    final service = BattleService();

    test('generate returns null when fewer than 2 candidates exist', () {
      final result = service.generate(
        pool: [_profile('a')],
        type: BattleType.random,
        random: Random(1),
      );
      expect(result, isNull);
    });

    test('generate never pairs a profile with itself', () {
      final pool = [_profile('a'), _profile('b'), _profile('c')];
      for (var seed = 0; seed < 20; seed++) {
        final battle = service.generate(pool: pool, type: BattleType.random, random: Random(seed));
        expect(battle, isNotNull);
        expect(battle!.profileAId, isNot(equals(battle.profileBId)));
      }
    });

    test('trending pairs come from the most-rated slice of the pool', () {
      final pool = [
        _profile('low1', ratingCount: 1),
        _profile('low2', ratingCount: 1),
        _profile('low3', ratingCount: 1),
        _profile('high1', ratingCount: 50),
        _profile('high2', ratingCount: 40),
      ];
      final battle = service.generate(pool: pool, type: BattleType.trending, random: Random(1));
      expect(battle, isNotNull);
      expect({battle!.profileAId, battle.profileBId}, {'high1', 'high2'});
    });

    test('country pairs share the preferred country when possible', () {
      final pool = [
        _profile('us1', country: 'US'),
        _profile('us2', country: 'US'),
        _profile('fr1', country: 'FR'),
      ];
      final battle = service.generate(
        pool: pool,
        type: BattleType.country,
        random: Random(1),
        preferredCountry: 'US',
      );
      expect(battle, isNotNull);
      expect({battle!.profileAId, battle.profileBId}, {'us1', 'us2'});
    });

    test('country falls back to the full pool when no country match exists', () {
      final pool = [_profile('a', country: 'US'), _profile('b', country: 'FR')];
      final battle = service.generate(
        pool: pool,
        type: BattleType.country,
        random: Random(1),
        preferredCountry: 'DE',
      );
      expect(battle, isNotNull);
    });

    test('categoryComparison reuses real LifeScore.breakdown values', () {
      final a = _profile('a', overall: 70);
      final b = _profile('b', overall: 40);
      final rows = service.categoryComparison(a, b);
      expect(rows, hasLength(BattleService.categories.length));
      for (final row in rows) {
        expect(row.$2, 70);
        expect(row.$3, 40);
      }
    });

    test('communityPercentageForA favors the higher-scored profile but never claims certainty', () {
      final higher = _profile('a', overall: 90);
      final lower = _profile('b', overall: 10);
      final pctHigherFirst = service.communityPercentageForA(higher, lower);
      final pctLowerFirst = service.communityPercentageForA(lower, higher);
      expect(pctHigherFirst, greaterThan(50));
      expect(pctLowerFirst, lessThan(50));
      expect(pctHigherFirst, lessThanOrEqualTo(92));
      expect(pctLowerFirst, greaterThanOrEqualTo(8));
    });

    test('communityPercentageForA is 50/50 for equal scores', () {
      final pct = service.communityPercentageForA(_profile('a', overall: 50), _profile('b', overall: 50));
      expect(pct, 50);
    });

    test('canBattle rejects a profile battling itself', () {
      expect(service.canBattle('a', 'b'), isTrue);
      expect(service.canBattle('a', 'a'), isFalse);
    });
  });
}
