import '../../data/models/models.dart';

class DailyChallengeService {
  const DailyChallengeService();

  /// Every challenge is measured against the local user's own real
  /// `XpTransaction` log for the day — there's no separate, driftable
  /// counter to keep in sync. Deliberately excludes anything this local
  /// MVP can't produce (receiving ratings, battle wins).
  static final List<DailyChallenge> pool = [
    const DailyChallenge(
      id: 'rate_3',
      title: 'Rate 3 lives',
      description: 'Rate 3 profiles today.',
      iconKey: 'star',
      xpReward: 50,
      coinReward: 10,
      targetCount: 3,
      trackedReason: XpReason.ratingGiven,
    ),
    const DailyChallenge(
      id: 'rate_5',
      title: 'Rate 5 lives',
      description: 'Rate 5 profiles today.',
      iconKey: 'bolt',
      xpReward: 100,
      coinReward: 20,
      targetCount: 5,
      trackedReason: XpReason.ratingGiven,
    ),
    const DailyChallenge(
      id: 'add_photo',
      title: 'Add a photo',
      description: 'Add a new photo to your gallery.',
      iconKey: 'camera',
      xpReward: 75,
      coinReward: 15,
      targetCount: 1,
      trackedReason: XpReason.photoAdded,
    ),
    const DailyChallenge(
      id: 'update_profile',
      title: 'Update your profile',
      description: 'Make an edit to keep your profile fresh.',
      iconKey: 'edit',
      xpReward: 50,
      coinReward: 10,
      targetCount: 1,
      trackedReason: XpReason.profileUpdated,
    ),
    const DailyChallenge(
      id: 'share_profile',
      title: 'Share your profile',
      description: 'Share your profile once today.',
      iconKey: 'share',
      xpReward: 60,
      coinReward: 12,
      targetCount: 1,
      trackedReason: XpReason.profileShared,
    ),
    const DailyChallenge(
      id: 'judge_battle',
      title: 'Judge a Life Battle',
      description: 'Vote in a Life Battle today.',
      iconKey: 'swords',
      xpReward: 50,
      coinReward: 10,
      targetCount: 1,
      trackedReason: XpReason.battleVoted,
    ),
    const DailyChallenge(
      id: 'answer_choice',
      title: 'Would You Choose?',
      description: "Answer today's What Would You Choose.",
      iconKey: 'help',
      xpReward: 40,
      coinReward: 8,
      targetCount: 1,
      trackedReason: XpReason.choiceMade,
    ),
  ];

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// A deterministic 3-challenge rotation for [date]: the same day
  /// always yields the same set (nothing to persist for "today's
  /// picks"), but the set changes day to day.
  List<DailyChallenge> challengesFor(DateTime date) {
    final day = dateOnly(date);
    final dayIndex = day.difference(DateTime(2026)).inDays;
    final start = dayIndex % pool.length;
    return [for (var i = 0; i < 3; i++) pool[(start + i) % pool.length]];
  }

  int progressFor(DailyChallenge challenge, List<XpTransaction> transactions, DateTime date) {
    final day = dateOnly(date);
    return transactions
        .where((tx) => tx.reason == challenge.trackedReason && dateOnly(tx.createdAt) == day)
        .length;
  }

  bool isCompleted(DailyChallenge challenge, List<XpTransaction> transactions, DateTime date) {
    return progressFor(challenge, transactions, date) >= challenge.targetCount;
  }
}
