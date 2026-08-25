import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/rating_service.dart';

void main() {
  group('RatingService', () {
    late RatingService service;

    setUp(() {
      service = RatingService();
    });

    test('creates rating', () {
      final rating = service.upsertRating(
        existing: const [],
        raterId: 'a',
        profileId: 'b',
        overall: 4,
      );
      expect(rating.overall, 4);
      expect(rating.raterId, 'a');
    });

    test('updates duplicate rating instead of creating another identity', () {
      final first = service.upsertRating(
        existing: const [],
        raterId: 'a',
        profileId: 'b',
        overall: 3,
      );
      final second = service.upsertRating(
        existing: [first],
        raterId: 'a',
        profileId: 'b',
        overall: 5,
      );
      expect(second.id, first.id);
      expect(second.overall, 5);
    });

    test('prevents self-rating', () {
      expect(
        () => service.upsertRating(
          existing: const [],
          raterId: 'a',
          profileId: 'a',
          overall: 4,
        ),
        throwsA(isA<RatingException>()),
      );
    });

    test('removes rating', () {
      final rating = service.upsertRating(
        existing: const [],
        raterId: 'a',
        profileId: 'b',
        overall: 4,
      );
      final ratings = service.removeRating(
        existing: [rating],
        raterId: 'a',
        profileId: 'b',
      );
      expect(ratings, isEmpty);
    });

    test('rejects a life rating above 5', () {
      expect(
        () => service.upsertRating(
          existing: const [],
          raterId: 'a',
          profileId: 'b',
          overall: 6,
        ),
        throwsA(isA<RatingException>()),
      );
    });

    test('community rating stays within 1-5 when ratings exist', () {
      final first = service.upsertRating(existing: const [], raterId: 'a', profileId: 'p', overall: 1);
      final second = service.upsertRating(existing: [first], raterId: 'b', profileId: 'p', overall: 5);
      final summary = service.summaryFor('p', [first, second]);
      expect(summary.averageOverall, inInclusiveRange(1, 5));
      expect(summary.count, 2);
    });

    test('stores look rating alongside life rating', () {
      final rating = service.upsertRating(
        existing: const [],
        raterId: 'a',
        profileId: 'b',
        overall: 4,
        look: 3,
      );
      expect(rating.overall, 4);
      expect(rating.look, 3);
    });

    test('rejects an out-of-range look rating', () {
      expect(
        () => service.upsertRating(
          existing: const [],
          raterId: 'a',
          profileId: 'b',
          overall: 4,
          look: 6,
        ),
        throwsA(isA<RatingException>()),
      );
    });

    test('averages look and life ratings independently', () {
      final first = service.upsertRating(existing: const [], raterId: 'a', profileId: 'p', overall: 1, look: 5);
      final second = service.upsertRating(existing: [first], raterId: 'b', profileId: 'p', overall: 3, look: 3);
      final summary = service.summaryFor('p', [first, second]);
      expect(summary.averageOverall, 2);
      expect(summary.averageLook, 4);
    });
  });
}
