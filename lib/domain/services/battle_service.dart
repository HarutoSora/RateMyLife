import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

/// Generates and judges Life Battles. Category comparisons reuse
/// `LifeScore.breakdown` directly — real, already-computed per-profile
/// data, nothing invented for this feature. The only genuinely
/// synthetic number here is the "estimated audience split" (see
/// `communityPercentageForA`), and it's clearly framed as an estimate,
/// not a live vote tally — see `BattleResult`'s doc comment for why.
class BattleService {
  BattleService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static const List<String> categories = ['Career', 'Money', 'Education', 'Lifestyle', 'Social'];

  /// A deterministic-per-call pairing (determinism comes from the caller
  /// supplying [random] with a fixed seed when reproducibility matters —
  /// e.g. re-showing the same not-yet-voted battle — not from this
  /// method itself). Returns null if fewer than 2 distinct candidates
  /// exist.
  Battle? generate({
    required List<UserProfile> pool,
    required BattleType type,
    required Random random,
    String? preferredCountry,
  }) {
    final candidates = switch (type) {
      BattleType.random => pool,
      BattleType.trending => _topByActivity(pool),
      BattleType.country => _sameCountry(pool, preferredCountry) ?? pool,
    };
    if (candidates.length < 2) {
      if (pool.length < 2) return null;
      return _pickPair(pool, type, random);
    }
    return _pickPair(candidates, type, random);
  }

  Battle _pickPair(List<UserProfile> candidates, BattleType type, Random random) {
    final shuffled = [...candidates]..shuffle(random);
    return Battle(
      id: _uuid.v4(),
      profileAId: shuffled[0].id,
      profileBId: shuffled[1].id,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  List<UserProfile> _topByActivity(List<UserProfile> pool) {
    final sorted = [...pool]..sort((a, b) => b.ratingSummary.count.compareTo(a.ratingSummary.count));
    final topCount = max(2, (sorted.length * 0.2).round());
    return sorted.take(topCount).toList();
  }

  List<UserProfile>? _sameCountry(List<UserProfile> pool, String? preferredCountry) {
    if (preferredCountry == null) return null;
    final matches = pool.where((p) => p.country == preferredCountry).toList();
    return matches.length >= 2 ? matches : null;
  }

  /// Real per-category numbers straight from each profile's computed
  /// `LifeScore` — no synthetic data.
  List<(String category, int a, int b)> categoryComparison(UserProfile a, UserProfile b) {
    final breakdownA = a.score.breakdown;
    final breakdownB = b.score.breakdown;
    return [
      for (final category in categories) (category, breakdownA[category] ?? 0, breakdownB[category] ?? 0),
    ];
  }

  /// A deterministic estimate (not a live tally — see `BattleResult`)
  /// of the share who'd pick profile A, derived from the Life Score gap
  /// via a logistic curve. Clamped to 8-92 so it never claims false
  /// certainty.
  int communityPercentageForA(UserProfile a, UserProfile b) {
    final diff = (a.score.overall - b.score.overall).toDouble();
    final logistic = 1 / (1 + exp(-diff / 12));
    return (logistic * 100).round().clamp(8, 92);
  }

  bool canBattle(String profileAId, String profileBId) => profileAId != profileBId;
}
