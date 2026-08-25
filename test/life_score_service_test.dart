import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/scoring/life_score_service.dart';

void main() {
  group('LifeScoreService', () {
    const service = LifeScoreService();

    test('keeps scores within 0-100', () {
      final score = service.calculate(_profile(monthlyIncome: 0, savings: 0));
      expect(score.overall, inInclusiveRange(0, 100));
      for (final value in score.breakdown.values) {
        expect(value, inInclusiveRange(0, 100));
      }
    });

    test('high local income beats low local income without dominating all categories', () {
      final low = service.calculate(_profile(monthlyIncome: 2000, savings: 5000));
      final high = service.calculate(_profile(monthlyIncome: 30000, savings: 200000));
      expect(high.financial, greaterThan(low.financial));
      expect(high.overall - low.overall, lessThan(45));
    });

    test('uses country benchmarks for income', () {
      final morocco = service.calculate(_profile(country: 'Morocco', monthlyIncome: 12000, savings: 60000));
      final usa = service.calculate(_profile(country: 'USA', currency: 'USD', monthlyIncome: 12000, savings: 60000));
      expect(morocco.financial, isNot(equals(usa.financial)));
    });

    test('age changes savings expectations', () {
      final young = service.calculate(_profile(age: 22, savings: 30000));
      final older = service.calculate(_profile(age: 45, savings: 30000));
      expect(young.financial, greaterThan(older.financial));
    });

    test('education affects education category', () {
      final bachelor = service.calculate(_profile(education: 'Bachelor'));
      final master = service.calculate(_profile(education: 'Master'));
      expect(master.education, greaterThan(bachelor.education));
    });
  });
}

UserProfile _profile({
  int age = 28,
  String country = 'Morocco',
  String currency = 'MAD',
  String education = 'Bachelor',
  double monthlyIncome = 9000,
  double savings = 30000,
}) {
  final now = DateTime(2026, 8, 1);
  return UserProfile(
    id: 'p',
    displayName: 'Tester',
    age: age,
    country: country,
    city: 'Casablanca',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    jobTitle: 'Developer',
    yearsExperience: 4,
    educationLevel: education,
    monthlyIncome: monthlyIncome,
    currency: currency,
    savings: savings,
    investments: 5000,
    debt: 0,
    monthlyExpenses: 4500,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: true,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const ['Travel', 'Fitness'],
    freeTimeHours: 12,
    closeFriends: 5,
    happiness: 7,
    stress: 5,
    currentGoal: 'Build',
    bio: 'Trying.',
    photos: const [],
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}
