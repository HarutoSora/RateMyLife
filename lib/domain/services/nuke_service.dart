import 'dart:math';

class NukeValidationException implements Exception {
  const NukeValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Business rules for the Nuke / Cure mini-game: paying coins to damage
/// (or heal) a random `LifeScore.breakdown` category. Pure and testable,
/// like `RatingService`/`CommentService` — `AppController` gathers the
/// facts (balances, blocking) and applies the returned amounts.
class NukeService {
  const NukeService();

  static const int attackCost = 5000;
  static const int curePotionCost = 1000;
  static const int damagePerNuke = 5;
  static const int healPerPotion = 3;

  /// `LifeScore.breakdown`'s categories, keyed the same as
  /// `LifeScore.toJson`/`LifeScoreService.applyDelta`.
  static const List<String> attributes = [
    'career',
    'financial',
    'education',
    'independence',
    'social',
    'lifestyle',
    'wellbeing',
  ];

  static const Map<String, String> attributeLabels = {
    'career': 'Career',
    'financial': 'Money',
    'education': 'Education',
    'independence': 'Independence',
    'social': 'Social',
    'lifestyle': 'Lifestyle',
    'wellbeing': 'Wellbeing',
  };

  String randomAttribute(Random random) => attributes[random.nextInt(attributes.length)];

  /// Throws [NukeValidationException] with a user-facing message if
  /// [attackerId] should not be allowed to nuke [targetId] right now.
  void assertCanNuke({
    required String attackerId,
    required String targetId,
    required bool isBlockedEitherWay,
    required int balance,
  }) {
    if (attackerId == targetId) {
      throw const NukeValidationException('You cannot nuke your own life.');
    }
    if (isBlockedEitherWay) {
      throw const NukeValidationException('You cannot nuke this profile.');
    }
    if (balance < attackCost) {
      throw const NukeValidationException('Not enough coins for a nuke.');
    }
  }

  void assertCanCure({required int balance}) {
    if (balance < curePotionCost) {
      throw const NukeValidationException('Not enough coins for a cure potion.');
    }
  }

  /// Merges a new [amount] (negative for damage, positive for a cure)
  /// into [current]'s running total for [attribute], never letting a
  /// cure push the entry above 0 — you can only heal damage that
  /// actually exists, never bank a surplus for later.
  Map<String, int> mergeDamage(Map<String, int> current, String attribute, int amount) {
    final next = Map<String, int>.from(current);
    final updated = (next[attribute] ?? 0) + amount;
    next[attribute] = updated > 0 ? 0 : updated;
    return next;
  }

  /// The most-damaged attribute in [damage], or null if nothing is
  /// currently damaged — used to default the cure picker to the entry
  /// that needs it most.
  String? mostDamagedAttribute(Map<String, int> damage) {
    String? worst;
    var worstValue = 0;
    for (final entry in damage.entries) {
      if (entry.value < worstValue) {
        worst = entry.key;
        worstValue = entry.value;
      }
    }
    return worst;
  }
}
