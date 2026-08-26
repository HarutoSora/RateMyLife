import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/advice_service.dart';

void main() {
  group('LifeAdviceService', () {
    const service = LifeAdviceService();

    test('returns up to 4 tips by default', () {
      final tips = service.generate(_profile(score: _score()), random: Random(1));
      expect(tips.length, 4);
    });

    test('respects a custom count', () {
      final tips = service.generate(_profile(score: _score()), count: 2, random: Random(1));
      expect(tips.length, 2);
    });

    test('leads with the weakest score category, whichever variant is picked', () {
      final tips = service.generate(
        _profile(
          employmentStatus: 'Unemployed',
          jobCategory: 'Design',
          score: _score(career: 10),
        ),
        random: Random(1),
      );
      expect(tips.first.category, 'Career');
      expect(tips.first.tip, contains('Design'));
    });

    test('career advice pool differs for a student vs. an experienced professional', () {
      final student = service.generate(
        _profile(
          employmentStatus: 'Student',
          jobCategory: 'Marketing',
          yearsExperience: 0,
          score: _score(career: 10),
        ),
        random: Random(1),
      );
      final veteran = service.generate(
        _profile(
          employmentStatus: 'Employed',
          jobCategory: 'Marketing',
          yearsExperience: 8,
          score: _score(career: 10),
        ),
        random: Random(1),
      );
      expect(student.first.tip, isNot(equals(veteran.first.tip)));
    });

    test('flags debt outweighing savings when money is the weakest category', () {
      final tips = service.generate(
        _profile(
          debt: 20000,
          savings: 2000,
          score: _score(financial: 10),
        ),
        random: Random(1),
      );
      expect(tips.first.category, 'Money');
      expect(tips.first.tip, contains('debt'));
    });

    test('flags high stress when wellbeing is the weakest category', () {
      final tips = service.generate(
        _profile(
          stress: 9,
          happiness: 8,
          score: _score(wellbeing: 10),
        ),
        random: Random(1),
      );
      expect(tips.first.category, 'Wellbeing');
      expect(tips.first.tip, contains('stress'));
    });

    test('carries the raw category score alongside the tip', () {
      final tips = service.generate(_profile(score: _score(career: 37)), random: Random(1));
      final careerTip = tips.firstWhere((t) => t.category == 'Career');
      expect(careerTip.score, 37);
    });

    test('is reproducible for the same profile and the same seed', () {
      final profile = _profile(score: _score(social: 10));
      final a = service.generate(profile, random: Random(42)).map((t) => t.tip).toList();
      final b = service.generate(profile, random: Random(42)).map((t) => t.tip).toList();
      expect(a, b);
    });

    test('draws from a large pool — many distinct variants are reachable for one profile', () {
      final profile = _profile(score: _score(career: 10));
      final seen = <String>{};
      for (var seed = 0; seed < 40; seed++) {
        seen.add(service.generate(profile, count: 1, random: Random(seed)).first.tip);
      }
      expect(seen.length, greaterThan(5));
    });

    test('every category has at least 10 variants to draw from', () {
      for (final category in ['Career', 'Money', 'Education', 'Independence', 'Social', 'Lifestyle', 'Wellbeing']) {
        final seen = <String>{};
        final profile = _profile(score: _scoreWeakest(category));
        for (var seed = 0; seed < 30; seed++) {
          seen.add(service.generate(profile, count: 1, random: Random(seed)).first.tip);
        }
        expect(seen.length, greaterThanOrEqualTo(10), reason: 'category $category');
      }
    });
  });
}

LifeScore _score({
  int career = 70,
  int financial = 70,
  int education = 70,
  int independence = 70,
  int social = 70,
  int lifestyle = 70,
  int wellbeing = 70,
}) {
  return LifeScore(
    overall: 70,
    career: career,
    financial: financial,
    education: education,
    independence: independence,
    social: social,
    lifestyle: lifestyle,
    wellbeing: wellbeing,
    explanations: const {},
    calculatedAt: DateTime(2026, 8, 1),
  );
}

LifeScore _scoreWeakest(String category) {
  return switch (category) {
    'Career' => _score(career: 5),
    'Money' => _score(financial: 5),
    'Education' => _score(education: 5),
    'Independence' => _score(independence: 5),
    'Social' => _score(social: 5),
    'Lifestyle' => _score(lifestyle: 5),
    'Wellbeing' => _score(wellbeing: 5),
    _ => _score(),
  };
}

UserProfile _profile({
  int age = 28,
  String country = 'Morocco',
  String employmentStatus = 'Employed',
  String jobCategory = 'Technology',
  int yearsExperience = 4,
  String educationLevel = 'Bachelor',
  double savings = 30000,
  double debt = 0,
  double monthlyIncome = 9000,
  double monthlyExpenses = 4500,
  String livingSituation = 'Rents apartment',
  bool ownsCar = true,
  bool ownsHome = false,
  String travelFrequency = 'Once/year',
  String exerciseFrequency = 'Weekly',
  List<String> hobbies = const ['Travel', 'Fitness'],
  int freeTimeHours = 12,
  int closeFriends = 5,
  int happiness = 7,
  int stress = 5,
  required LifeScore score,
}) {
  final now = DateTime(2026, 8, 1);
  return UserProfile(
    id: 'p',
    displayName: 'Tester',
    age: age,
    country: country,
    city: 'Casablanca',
    employmentStatus: employmentStatus,
    jobCategory: jobCategory,
    jobTitle: 'Developer',
    yearsExperience: yearsExperience,
    educationLevel: educationLevel,
    monthlyIncome: monthlyIncome,
    currency: 'MAD',
    savings: savings,
    investments: 5000,
    debt: debt,
    monthlyExpenses: monthlyExpenses,
    relationshipStatus: 'Single',
    livingSituation: livingSituation,
    ownsCar: ownsCar,
    ownsHome: ownsHome,
    travelFrequency: travelFrequency,
    exerciseFrequency: exerciseFrequency,
    hobbies: hobbies,
    freeTimeHours: freeTimeHours,
    closeFriends: closeFriends,
    happiness: happiness,
    stress: stress,
    currentGoal: 'Build',
    bio: 'Trying.',
    photos: const [],
    score: score,
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}
