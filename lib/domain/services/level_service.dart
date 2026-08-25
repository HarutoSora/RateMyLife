/// Derived level/rank state for a given amount of XP. Never persisted —
/// always recomputed from `UserProfile.xp` via `LevelService`, so the
/// level curve can be tuned later without a data migration.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.rank,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  final int level;
  final String rank;
  final int totalXp;

  /// XP earned since hitting [level].
  final int xpIntoLevel;

  /// Total XP required to go from [level] to the next one. Zero at max
  /// level.
  final int xpForNextLevel;

  bool get isMaxLevel => xpForNextLevel == 0;

  /// 0.0-1.0 progress through the current level.
  double get progress => isMaxLevel ? 1.0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  int get xpRemaining => isMaxLevel ? 0 : (xpForNextLevel - xpIntoLevel).clamp(0, xpForNextLevel);
}

/// Deterministic, XP-only level curve (no dependency on Life Score or
/// money, per product rule: progression must stay earnable through any
/// activity — rating, sharing, keeping a profile fresh — not just the
/// score itself).
///
/// Level `L -> L+1` costs `100 * L` XP, so the curve gets meaningfully
/// harder at higher levels without becoming absurd by level 100 (~495,000
/// cumulative XP for a full playthrough).
class LevelService {
  const LevelService();

  static const int maxLevel = 100;

  /// Cumulative XP required to *be at* [level] (level 1 = 0).
  int xpFloorForLevel(int level) => 50 * (level - 1) * level;

  LevelInfo levelFor(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    while (level < maxLevel && xp >= xpFloorForLevel(level + 1)) {
      level++;
    }
    final floor = xpFloorForLevel(level);
    final nextFloor = level >= maxLevel ? floor : xpFloorForLevel(level + 1);
    return LevelInfo(
      level: level,
      rank: rankFor(level),
      totalXp: xp,
      xpIntoLevel: xp - floor,
      xpForNextLevel: nextFloor - floor,
    );
  }

  String rankFor(int level) {
    if (level >= 100) return 'Mythic';
    if (level >= 75) return 'Legendary';
    if (level >= 50) return 'Elite';
    if (level >= 25) return 'Established';
    if (level >= 10) return 'Rising';
    return 'Beginner';
  }
}
