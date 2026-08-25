import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/daily_challenge_service.dart';

XpTransaction _tx(XpReason reason, DateTime createdAt, {String id = 't'}) => XpTransaction(
      id: id,
      profileId: 'p1',
      amount: 10,
      reason: reason,
      createdAt: createdAt,
    );

void main() {
  group('DailyChallengeService', () {
    const service = DailyChallengeService();

    test('pool ids are unique', () {
      final ids = DailyChallengeService.pool.map((c) => c.id).toSet();
      expect(ids, hasLength(DailyChallengeService.pool.length));
    });

    test('every challenge grants positive XP and coins', () {
      for (final challenge in DailyChallengeService.pool) {
        expect(challenge.xpReward, greaterThan(0));
        expect(challenge.coinReward, greaterThan(0));
        expect(challenge.targetCount, greaterThan(0));
      }
    });

    test('challengesFor always returns exactly 3 challenges', () {
      for (var i = 0; i < 30; i++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: i));
        expect(service.challengesFor(date), hasLength(3));
      }
    });

    test('challengesFor is deterministic for the same day', () {
      final date = DateTime(2026, 3, 15);
      final a = service.challengesFor(date).map((c) => c.id).toList();
      final b = service.challengesFor(date.add(const Duration(hours: 5))).map((c) => c.id).toList();
      expect(a, b);
    });

    test('challengesFor varies across different days', () {
      final sets = <String>{};
      for (var i = 0; i < 10; i++) {
        final ids = service.challengesFor(DateTime(2026, 1, 1 + i)).map((c) => c.id).join(',');
        sets.add(ids);
      }
      expect(sets.length, greaterThan(1));
    });

    test('progressFor only counts matching-reason transactions from the given day', () {
      final challenge = DailyChallengeService.pool.firstWhere((c) => c.id == 'rate_3');
      final today = DateTime(2026, 5, 10, 14);
      final transactions = [
        _tx(XpReason.ratingGiven, DateTime(2026, 5, 10, 9), id: 't1'),
        _tx(XpReason.ratingGiven, DateTime(2026, 5, 10, 20), id: 't2'),
        _tx(XpReason.ratingGiven, DateTime(2026, 5, 9, 23), id: 't3'), // yesterday
        _tx(XpReason.photoAdded, DateTime(2026, 5, 10, 10), id: 't4'), // wrong reason
      ];
      expect(service.progressFor(challenge, transactions, today), 2);
    });

    test('isCompleted respects targetCount', () {
      final challenge = DailyChallengeService.pool.firstWhere((c) => c.id == 'rate_3');
      final today = DateTime(2026, 5, 10);
      final under = [
        _tx(XpReason.ratingGiven, today, id: 'a'),
        _tx(XpReason.ratingGiven, today, id: 'b'),
      ];
      final met = [...under, _tx(XpReason.ratingGiven, today, id: 'c')];
      expect(service.isCompleted(challenge, under, today), isFalse);
      expect(service.isCompleted(challenge, met, today), isTrue);
    });
  });
}
