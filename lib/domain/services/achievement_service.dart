import '../../data/models/models.dart';

/// A snapshot of the local user's real, derivable activity — deliberately
/// excludes anything this MVP can't actually produce yet (incoming
/// ratings on your own profile, battle wins) rather than faking those
/// signals. See `docs/FEATURE_STATUS.md` for what's deferred and why.
class AchievementStats {
  const AchievementStats({
    required this.hasProfile,
    required this.ratingsGiven,
    required this.photoCount,
    required this.scoreImprovement,
    required this.level,
    required this.hasSharedProfile,
    required this.streakDays,
    required this.battlesVoted,
  });

  final bool hasProfile;
  final int ratingsGiven;
  final int photoCount;
  final int scoreImprovement;
  final int level;
  final bool hasSharedProfile;

  /// Current activity streak in days, from `StreakService`.
  final int streakDays;

  /// Life Battles judged (voted on). The spec's "won 10 Life Battles" isn't
  /// meaningful here — there's no live opponent to beat, only battles the
  /// local user judges — so this achievement tracks judging instead.
  final int battlesVoted;
}

class AchievementService {
  const AchievementService();

  /// Thresholds are scaled to what's actually reachable in this local MVP
  /// (e.g. only ~50 mock profiles exist to rate, each ratable once), not
  /// the spec's illustrative numbers written for a live multi-user app.
  static final List<AchievementDefinition> catalog = [
    const AchievementDefinition(
      id: 'first_steps',
      name: 'First Steps',
      description: 'Complete your profile and get your first Life Score.',
      iconKey: 'flag',
      xpReward: 50,
    ),
    const AchievementDefinition(
      id: 'rating_enthusiast',
      name: 'Rating Enthusiast',
      description: 'Rate 10 lives.',
      iconKey: 'star',
      xpReward: 75,
    ),
    const AchievementDefinition(
      id: 'rating_machine',
      name: 'Rating Machine',
      description: 'Rate 25 lives.',
      iconKey: 'bolt',
      xpReward: 150,
    ),
    const AchievementDefinition(
      id: 'photogenic_life',
      name: 'Photogenic Life',
      description: 'Fill your gallery with 8 photos.',
      iconKey: 'camera',
      xpReward: 100,
    ),
    const AchievementDefinition(
      id: 'rising_star',
      name: 'Rising Star',
      description: 'Improve your Life Score by 10+ points.',
      iconKey: 'trending_up',
      xpReward: 150,
    ),
    const AchievementDefinition(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: 'Share your profile for the first time.',
      iconKey: 'share',
      xpReward: 50,
    ),
    const AchievementDefinition(
      id: 'established',
      name: 'Established',
      description: 'Reach Level 25.',
      iconKey: 'shield',
      xpReward: 200,
    ),
    const AchievementDefinition(
      id: 'legendary',
      name: 'Legendary',
      description: 'Reach Level 75.',
      iconKey: 'crown',
      xpReward: 500,
    ),
    const AchievementDefinition(
      id: 'streak_3',
      name: 'On a Roll',
      description: 'Maintain a 3-day activity streak.',
      iconKey: 'flame',
      xpReward: 100,
    ),
    const AchievementDefinition(
      id: 'streak_7',
      name: '7 Day Streak',
      description: 'Maintain a 7-day activity streak.',
      iconKey: 'flame',
      xpReward: 300,
    ),
    const AchievementDefinition(
      id: 'streak_30',
      name: 'Unstoppable',
      description: 'Maintain a 30-day activity streak.',
      iconKey: 'flame',
      xpReward: 1000,
    ),
    const AchievementDefinition(
      id: 'battle_judge',
      name: 'Battle Judge',
      description: 'Judge 10 Life Battles.',
      iconKey: 'swords',
      xpReward: 150,
    ),
  ];

  bool isUnlocked(String achievementId, AchievementStats stats) {
    switch (achievementId) {
      case 'first_steps':
        return stats.hasProfile;
      case 'rating_enthusiast':
        return stats.ratingsGiven >= 10;
      case 'rating_machine':
        return stats.ratingsGiven >= 25;
      case 'photogenic_life':
        return stats.photoCount >= 8;
      case 'rising_star':
        return stats.scoreImprovement >= 10;
      case 'social_butterfly':
        return stats.hasSharedProfile;
      case 'established':
        return stats.level >= 25;
      case 'legendary':
        return stats.level >= 75;
      case 'streak_3':
        return stats.streakDays >= 3;
      case 'streak_7':
        return stats.streakDays >= 7;
      case 'streak_30':
        return stats.streakDays >= 30;
      case 'battle_judge':
        return stats.battlesVoted >= 10;
      default:
        return false;
    }
  }

  /// The catalog entries newly satisfied by [stats] and not already in
  /// [alreadyUnlockedIds].
  List<AchievementDefinition> evaluate(AchievementStats stats, Set<String> alreadyUnlockedIds) {
    return [
      for (final achievement in catalog)
        if (!alreadyUnlockedIds.contains(achievement.id) && isUnlocked(achievement.id, stats)) achievement,
    ];
  }
}
