import '../../data/models/models.dart';

class CountryBenchmark {
  const CountryBenchmark({
    required this.country,
    required this.monthlyIncomeBenchmark,
    required this.savingsBenchmark,
    required this.costMultiplier,
  });

  final String country;
  final double monthlyIncomeBenchmark;
  final double savingsBenchmark;
  final double costMultiplier;
}

class LifeScoreService {
  const LifeScoreService();

  static const Map<String, CountryBenchmark> benchmarks = {
    'Morocco': CountryBenchmark(
      country: 'Morocco',
      monthlyIncomeBenchmark: 8000,
      savingsBenchmark: 60000,
      costMultiplier: 0.42,
    ),
    'USA': CountryBenchmark(
      country: 'USA',
      monthlyIncomeBenchmark: 5200,
      savingsBenchmark: 30000,
      costMultiplier: 1,
    ),
    'France': CountryBenchmark(
      country: 'France',
      monthlyIncomeBenchmark: 3200,
      savingsBenchmark: 24000,
      costMultiplier: 0.82,
    ),
    'India': CountryBenchmark(
      country: 'India',
      monthlyIncomeBenchmark: 90000,
      savingsBenchmark: 700000,
      costMultiplier: 0.28,
    ),
    'Switzerland': CountryBenchmark(
      country: 'Switzerland',
      monthlyIncomeBenchmark: 7800,
      savingsBenchmark: 60000,
      costMultiplier: 1.45,
    ),
    'Brazil': CountryBenchmark(
      country: 'Brazil',
      monthlyIncomeBenchmark: 6500,
      savingsBenchmark: 40000,
      costMultiplier: 0.36,
    ),
    'Canada': CountryBenchmark(
      country: 'Canada',
      monthlyIncomeBenchmark: 5200,
      savingsBenchmark: 32000,
      costMultiplier: 0.9,
    ),
    'UAE': CountryBenchmark(
      country: 'UAE',
      monthlyIncomeBenchmark: 18000,
      savingsBenchmark: 120000,
      costMultiplier: 0.95,
    ),
  };

  LifeScore calculate(UserProfile profile) {
    final benchmark = benchmarks[profile.country] ??
        const CountryBenchmark(
          country: 'Global',
          monthlyIncomeBenchmark: 3000,
          savingsBenchmark: 20000,
          costMultiplier: 0.7,
        );

    final financial = _financial(profile, benchmark);
    final career = _career(profile);
    final education = _education(profile.educationLevel);
    final independence = _independence(profile);
    final social = _social(profile);
    final lifestyle = _lifestyle(profile);
    final wellbeing = _wellbeing(profile);

    final weighted = financial * 0.25 +
        career * 0.20 +
        education * 0.10 +
        independence * 0.15 +
        social * 0.10 +
        lifestyle * 0.10 +
        wellbeing * 0.10;

    return LifeScore(
      overall: _clamp(weighted),
      career: _clamp(career),
      financial: _clamp(financial),
      education: _clamp(education),
      independence: _clamp(independence),
      social: _clamp(social),
      lifestyle: _clamp(lifestyle),
      wellbeing: _clamp(wellbeing),
      explanations: {
        'Career': _careerExplanation(_clamp(career), profile.age),
        'Money': _moneyExplanation(_clamp(financial), profile.country),
        'Education': 'Education is benchmarked gently so it helps but never defines the whole score.',
        'Independence': _clamp(independence) >= 70
            ? 'Your independence signals are strong for your current setup.'
            : 'Your independence score can move with housing, transport, or debt changes.',
        'Social': _clamp(social) >= 70
            ? 'You report a solid close circle and social base.'
            : 'More close connections or social activity would lift this area.',
        'Lifestyle': _clamp(lifestyle) >= 70
            ? 'Your lifestyle looks active and experience-rich.'
            : 'Travel, hobbies, movement, and free time shape this category.',
        'Wellbeing': _clamp(wellbeing) >= 70
            ? 'Happiness and stress inputs are currently balanced well.'
            : 'Lower stress and higher happiness are the biggest wellbeing levers.',
      },
      calculatedAt: DateTime.now(),
    );
  }

  double _financial(UserProfile profile, CountryBenchmark benchmark) {
    final incomeRatio = profile.monthlyIncome / benchmark.monthlyIncomeBenchmark;
    final savingsRatio = (profile.savings + profile.investments) /
        benchmark.savingsBenchmark.clamp(1, double.infinity).toDouble();
    final expenseLoad = profile.monthlyExpenses <= 0
        ? 0.75
        : (profile.monthlyIncome / profile.monthlyExpenses)
            .clamp(0, 3)
            .toDouble();
    final debtPenalty = profile.debt <= 0
        ? 0
        : (profile.debt / (benchmark.savingsBenchmark * 2))
            .clamp(0, 0.35)
            .toDouble();

    final incomeScore = _ratioScore(incomeRatio, midpoint: 1.0);
    final savingsScore = _ratioScore(savingsRatio, midpoint: _ageSavingsTarget(profile.age));
    final expenseScore = (expenseLoad / 3) * 100;
    return incomeScore * 0.45 +
        savingsScore * 0.35 +
        expenseScore * 0.20 -
        debtPenalty * 100;
  }

  double _career(UserProfile profile) {
    final status = profile.employmentStatus.toLowerCase();
    final statusBase = status.contains('student')
        ? 45
        : status.contains('unemployed')
            ? 22
            : status.contains('freelance')
                ? 62
                : status.contains('business') || status.contains('founder')
                    ? 76
                    : 66;
    final experience =
        (profile.yearsExperience / 10).clamp(0, 1).toDouble() * 24;
    final ageBoost = profile.age < 24 && profile.monthlyIncome > 0 ? 8 : 0;
    return statusBase + experience + ageBoost;
  }

  double _education(String education) {
    final value = education.toLowerCase();
    if (value.contains('doctor') || value.contains('phd')) return 95;
    if (value.contains('master')) return 88;
    if (value.contains('bachelor')) return 76;
    if (value.contains('diploma')) return 66;
    if (value.contains('student')) return 58;
    if (value.contains('high')) return 48;
    return 55;
  }

  double _independence(UserProfile profile) {
    var score = 42.0;
    final living = profile.livingSituation.toLowerCase();
    if (living.contains('own')) score += 24;
    if (living.contains('rent')) score += 18;
    if (living.contains('family')) score -= profile.age > 25 ? 12 : 4;
    if (profile.ownsCar) score += 10;
    if (profile.ownsHome) score += 16;
    if (profile.debt > profile.savings && profile.debt > 0) score -= 8;
    return score;
  }

  double _social(UserProfile profile) {
    final friends = (profile.closeFriends / 8).clamp(0, 1).toDouble() * 70;
    final relationship = profile.relationshipStatus.toLowerCase() == 'single' ? 8 : 16;
    final hobbies = profile.hobbies.length.clamp(0, 5).toDouble() * 3;
    return friends + relationship + hobbies;
  }

  double _lifestyle(UserProfile profile) {
    final travel = switch (profile.travelFrequency) {
      'Monthly' => 28,
      '3-4 times/year' => 22,
      'Once/year' => 14,
      'Rarely' => 6,
      _ => 10,
    };
    final exercise = switch (profile.exerciseFrequency) {
      'Daily' => 26,
      'Weekly' => 20,
      'Sometimes' => 12,
      'Rarely' => 4,
      _ => 10,
    };
    final freeTime =
        (profile.freeTimeHours / 24).clamp(0, 1).toDouble() * 20;
    final hobbies = profile.hobbies.length.clamp(0, 6).toDouble() * 4;
    return travel + exercise + freeTime + hobbies;
  }

  double _wellbeing(UserProfile profile) {
    final happiness = profile.happiness.clamp(1, 10).toDouble() * 7.0;
    final stress = (11 - profile.stress.clamp(1, 10)).toDouble() * 3.0;
    return happiness + stress;
  }

  /// Applies every entry in [damageByAttribute] (see `NukeService`) to
  /// [score] one at a time via `applyDelta` — used by
  /// `ProfileService.recalculate` to reapply a profile's full,
  /// persisted nuke damage on top of a freshly calculated score, since
  /// `calculate` itself only ever sees the raw profile fields.
  LifeScore applyDamage(LifeScore score, Map<String, int> damageByAttribute) {
    var result = score;
    for (final entry in damageByAttribute.entries) {
      result = applyDelta(result, entry.key, entry.value);
    }
    return result;
  }

  /// Adjusts a single `LifeScore.breakdown` category (keyed the same as
  /// `LifeScore.toJson`: `career`/`financial`/`education`/
  /// `independence`/`social`/`lifestyle`/`wellbeing`) by [delta] —
  /// negative for nuke damage, positive for a cure potion — reclamps it
  /// to 0-100, and recomputes `overall` from the same weights
  /// `calculate` uses. An unrecognized [attribute] is a no-op. Public
  /// (not just used via `applyDamage`) because a remote nuke/cure only
  /// ever needs to adjust the one already-stored `score` it can see by
  /// this single increment — it has no access to the target's raw,
  /// owner-private profile fields to recompute from scratch.
  LifeScore applyDelta(LifeScore score, String attribute, int delta) {
    int adjust(String key, int current) =>
        key == attribute ? _clamp(current + delta) : current;
    final career = adjust('career', score.career);
    final financial = adjust('financial', score.financial);
    final education = adjust('education', score.education);
    final independence = adjust('independence', score.independence);
    final social = adjust('social', score.social);
    final lifestyle = adjust('lifestyle', score.lifestyle);
    final wellbeing = adjust('wellbeing', score.wellbeing);
    final weighted = financial * 0.25 +
        career * 0.20 +
        education * 0.10 +
        independence * 0.15 +
        social * 0.10 +
        lifestyle * 0.10 +
        wellbeing * 0.10;
    return LifeScore(
      overall: _clamp(weighted),
      career: career,
      financial: financial,
      education: education,
      independence: independence,
      social: social,
      lifestyle: lifestyle,
      wellbeing: wellbeing,
      explanations: score.explanations,
      calculatedAt: DateTime.now(),
    );
  }

  double _ratioScore(double ratio, {required double midpoint}) {
    final adjusted = ratio / midpoint.clamp(0.4, 2.5).toDouble();
    return (adjusted / (adjusted + 0.75)) * 100;
  }

  double _ageSavingsTarget(int age) {
    if (age < 22) return 0.25;
    if (age < 28) return 0.65;
    if (age < 35) return 1.0;
    if (age < 45) return 1.6;
    return 2.2;
  }

  String _careerExplanation(int score, int age) {
    if (score >= 80) return 'Your career score is strong for your age group.';
    if (score >= 60) return 'Your career looks stable with room to compound.';
    return 'Career score improves with work stability, experience, or clearer direction.';
  }

  String _moneyExplanation(int score, String country) {
    if (score >= 80) return 'Your money score is high against $country benchmarks.';
    if (score >= 60) return 'Your finances are competitive for the local benchmark.';
    return 'Income, savings, expenses, and debt all matter here. No single number dominates.';
  }

  int _clamp(num value) => value.round().clamp(0, 100).toInt();
}
