import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/photo_vote_service.dart';

void main() {
  group('PhotoVoteService', () {
    final service = PhotoVoteService();

    test('creates a new vote when none exists yet', () {
      final vote = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p1');
      expect(vote.voterId, 'me');
      expect(vote.profileId, 'them');
      expect(vote.photoId, 'p1');
    });

    test('moving a vote reuses the same id and just changes the photo', () {
      final first = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p1');
      final second = service.upsertVote(existing: [first], voterId: 'me', profileId: 'them', photoId: 'p2');

      expect(second.id, first.id);
      expect(second.photoId, 'p2');
    });

    test('a vote on one profile does not affect a vote on another', () {
      final first = service.upsertVote(existing: const [], voterId: 'me', profileId: 'alice', photoId: 'p1');
      final second = service.upsertVote(existing: [first], voterId: 'me', profileId: 'bob', photoId: 'p9');

      expect(second.id, isNot(first.id));
      expect(second.profileId, 'bob');
    });

    test('refuses to let a voter vote on their own photos', () {
      expect(
        () => service.upsertVote(existing: const [], voterId: 'me', profileId: 'me', photoId: 'p1'),
        throwsA(isA<PhotoVoteException>()),
      );
    });

    test('voteFor finds the right vote and returns null when there is none', () {
      final vote = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p1');
      expect(service.voteFor(votes: [vote], voterId: 'me', profileId: 'them')?.photoId, 'p1');
      expect(service.voteFor(votes: [vote], voterId: 'me', profileId: 'someone_else'), isNull);
    });
  });
}
