import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/domain/services/photo_vote_service.dart';

void main() {
  group('RemotePhotoVoteRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late RemotePhotoVoteRepository repo;
    final service = PhotoVoteService();

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
      repo = RemotePhotoVoteRepository(firestore: firestore, auth: auth);
      await firestore.collection('profiles').doc('them').set({'photoVoteCounts': <String, int>{}});
    });

    test('loadVotes starts empty', () async {
      expect(await repo.loadVotes(), isEmpty);
    });

    test('saveVotes persists this device\'s vote and increments the target photo\'s count', () async {
      await repo.loadVotes();
      final vote = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p1');
      await repo.saveVotes([vote]);

      final loaded = await repo.loadVotes();
      expect(loaded.single.photoId, 'p1');

      final profile = await firestore.collection('profiles').doc('them').get();
      expect(profile.data()!['photoVoteCounts'], {'p1': 1});
    });

    test('moving a vote to a different photo decrements the old count and increments the new one', () async {
      await repo.loadVotes();
      final first = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p1');
      await repo.saveVotes([first]);

      final moved = service.upsertVote(existing: [first], voterId: 'me', profileId: 'them', photoId: 'p2');
      await repo.saveVotes([moved]);

      final profile = await firestore.collection('profiles').doc('them').get();
      expect(profile.data()!['photoVoteCounts'], {'p1': 0, 'p2': 1});
    });

    test('two different voters both increment the same photo\'s count', () async {
      await repo.loadVotes();
      final mine = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p1');
      await repo.saveVotes([mine]);

      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemotePhotoVoteRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadVotes();
      final theirs = service.upsertVote(existing: const [], voterId: 'other', profileId: 'them', photoId: 'p1');
      await otherRepo.saveVotes([theirs]);

      final profile = await firestore.collection('profiles').doc('them').get();
      expect(profile.data()!['photoVoteCounts'], {'p1': 2});
    });

    test('only loads this device\'s own votes', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemotePhotoVoteRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadVotes();
      final theirs = service.upsertVote(existing: const [], voterId: 'other', profileId: 'them', photoId: 'p1');
      await otherRepo.saveVotes([theirs]);

      await repo.loadVotes();
      final mine = service.upsertVote(existing: const [], voterId: 'me', profileId: 'them', photoId: 'p2');
      await repo.saveVotes([mine]);

      final loaded = await repo.loadVotes();
      expect(loaded.map((v) => v.voterId), ['me']);
    });

    test('voting on a mock/seed profile with no real doc is a no-op for the aggregate, not a crash', () async {
      await repo.loadVotes();
      final vote = service.upsertVote(existing: const [], voterId: 'me', profileId: 'mock_someone', photoId: 'p1');
      await repo.saveVotes([vote]);

      final loaded = await repo.loadVotes();
      expect(loaded.single.photoId, 'p1');
    });
  });
}
