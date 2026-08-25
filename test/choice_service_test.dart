import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/choice_service.dart';

void main() {
  group('ChoiceService', () {
    const service = ChoiceService();

    test('choiceFor is deterministic for the same day', () {
      final day = DateTime(2026, 6, 10);
      expect(service.choiceFor(day).id, service.choiceFor(day).id);
      expect(service.choiceFor(day).id, service.choiceFor(DateTime(2026, 6, 10, 23, 59)).id);
    });

    test('choiceFor rotates day to day', () {
      final choices = {for (var i = 0; i < ChoiceService.pool.length; i++) service.choiceFor(DateTime(2026, 1, 1 + i)).id};
      // With a pool this small relative to the sample, every entry
      // should appear at least once across one full rotation.
      expect(choices.length, ChoiceService.pool.length);
    });

    test('pool has no duplicate ids', () {
      final ids = ChoiceService.pool.map((c) => c.id).toSet();
      expect(ids.length, ChoiceService.pool.length);
    });

    test('hasVoted is true only once a matching questionId exists', () {
      final votes = [
        ChoiceVote(id: 'me_q1', questionId: 'q1', voterId: 'me', chosenOption: ChoiceOption.a, createdAt: DateTime(2026)),
      ];
      expect(service.hasVoted(votes, 'q1'), isTrue);
      expect(service.hasVoted(votes, 'q2'), isFalse);
    });
  });
}
