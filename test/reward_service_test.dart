import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/reward_service.dart';

void main() {
  group('RewardService', () {
    const service = RewardService();

    // Variable, per-event bonuses granted directly by AppController, not
    // looked up from this fixed table.
    const variableReasons = {
      XpReason.achievementUnlocked,
      XpReason.dailyChallengeCompleted,
      XpReason.cosmeticPurchased,
      XpReason.boostPurchased,
    };

    test('awards the configured coin amount for each fixed-reward reason', () {
      for (final reason in XpReason.values) {
        if (variableReasons.contains(reason)) continue;
        final tx = service.award(profileId: 'p1', reason: reason);
        expect(tx.amount, RewardService.coinRewards[reason]);
        expect(tx.profileId, 'p1');
        expect(tx.reason, reason);
      }
    });

    test('every coin reward is positive', () {
      for (final amount in RewardService.coinRewards.values) {
        expect(amount, greaterThan(0));
      }
    });

    test('coin rewards are smaller than the matching XP reward, so coins read as secondary', () {
      // Cross-checked against ProgressionService's table by value here to
      // avoid a circular import; kept in sync manually.
      const xpRewards = {
        XpReason.profileCompleted: 150,
        XpReason.profileUpdated: 20,
        XpReason.photoAdded: 30,
        XpReason.ratingGiven: 15,
        XpReason.profileShared: 25,
      };
      for (final entry in RewardService.coinRewards.entries) {
        final xp = xpRewards[entry.key];
        if (xp == null) continue;
        expect(entry.value, lessThan(xp));
      }
    });

    test('generates a unique id per transaction', () {
      final a = service.award(profileId: 'p1', reason: XpReason.ratingGiven);
      final b = service.award(profileId: 'p1', reason: XpReason.ratingGiven);
      expect(a.id, isNot(b.id));
    });
  });
}
