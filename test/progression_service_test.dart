import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/progression_service.dart';

void main() {
  group('ProgressionService', () {
    const service = ProgressionService();

    // These are variable, per-event bonuses granted directly by
    // AppController (via _grantCustomXp), not looked up from this fixed
    // table.
    const variableReasons = {
      XpReason.achievementUnlocked,
      XpReason.dailyChallengeCompleted,
      XpReason.cosmeticPurchased,
      XpReason.boostPurchased,
    };

    test('awards the configured XP amount for each fixed-reward reason', () {
      for (final reason in XpReason.values) {
        if (variableReasons.contains(reason)) continue;
        final tx = service.award(profileId: 'p1', reason: reason);
        expect(tx.amount, ProgressionService.xpRewards[reason]);
        expect(tx.profileId, 'p1');
        expect(tx.reason, reason);
      }
    });

    test('every reward is positive — no action should ever cost XP', () {
      for (final amount in ProgressionService.xpRewards.values) {
        expect(amount, greaterThan(0));
      }
    });

    test('generates a unique id per transaction', () {
      final a = service.award(profileId: 'p1', reason: XpReason.ratingGiven);
      final b = service.award(profileId: 'p1', reason: XpReason.ratingGiven);
      expect(a.id, isNot(b.id));
    });
  });
}
