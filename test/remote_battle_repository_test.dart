import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

Battle _battle(String id, {String a = 'p1', String b = 'p2'}) => Battle(
      id: id,
      profileAId: a,
      profileBId: b,
      type: BattleType.random,
      createdAt: DateTime(2026, 1, 1),
    );

BattleVote _vote(String id, String battleId, {required String voterId}) => BattleVote(
      id: id,
      battleId: battleId,
      voterId: voterId,
      chosenProfileId: 'p1',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('RemoteBattleRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late RemoteBattleRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
      repo = RemoteBattleRepository(firestore: firestore, auth: auth);
    });

    test('loadBattles starts empty', () async {
      expect(await repo.loadBattles(), isEmpty);
    });

    test('saveBattles persists a new battle tagged with the owner', () async {
      await repo.loadBattles();
      await repo.saveBattles([_battle('b1')]);

      final doc = await firestore.collection('battles').doc('b1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['generatedBy'], 'me');
      expect(doc.data()!['profileAId'], 'p1');
    });

    test('loadBattles round-trips a saved battle correctly', () async {
      await repo.loadBattles();
      await repo.saveBattles([_battle('b1')]);

      final loaded = await repo.loadBattles();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'b1');
      expect(loaded.single.profileAId, 'p1');
      expect(loaded.single.profileBId, 'p2');
    });

    test('saveBattles does not rewrite a battle it already knows about', () async {
      await repo.loadBattles();
      await repo.saveBattles([_battle('b1')]);
      await repo.saveBattles([_battle('b1'), _battle('b2')]);

      final snapshot = await firestore.collection('battles').get();
      expect(snapshot.docs, hasLength(2));
    });

    test('loadBattles only returns battles this device generated', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'someone_else'), signedIn: true);
      final otherRepo = RemoteBattleRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadBattles();
      await otherRepo.saveBattles([_battle('their_battle')]);

      await repo.loadBattles();
      await repo.saveBattles([_battle('my_battle')]);

      final mine = await repo.loadBattles();
      expect(mine.map((b) => b.id), ['my_battle']);
    });
  });

  group('RemoteBattleVoteRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late RemoteBattleVoteRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
      repo = RemoteBattleVoteRepository(firestore: firestore, auth: auth);
    });

    test('loadVotes starts empty', () async {
      expect(await repo.loadVotes(), isEmpty);
    });

    test('saveVotes persists a new vote', () async {
      await repo.loadVotes();
      await repo.saveVotes([_vote('v1', 'b1', voterId: 'me')]);

      final doc = await firestore.collection('battleVotes').doc('v1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['voterId'], 'me');
      expect(doc.data()!['chosenProfileId'], 'p1');
    });

    test('loadVotes round-trips a saved vote correctly', () async {
      await repo.loadVotes();
      await repo.saveVotes([_vote('v1', 'b1', voterId: 'me')]);

      final loaded = await repo.loadVotes();
      expect(loaded, hasLength(1));
      expect(loaded.single.battleId, 'b1');
      expect(loaded.single.chosenProfileId, 'p1');
    });

    test('saveVotes does not rewrite a vote it already knows about', () async {
      await repo.loadVotes();
      await repo.saveVotes([_vote('v1', 'b1', voterId: 'me')]);
      await repo.saveVotes([_vote('v1', 'b1', voterId: 'me'), _vote('v2', 'b2', voterId: 'me')]);

      final snapshot = await firestore.collection('battleVotes').get();
      expect(snapshot.docs, hasLength(2));
    });

    test('loadVotes only returns this device\'s own votes', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'someone_else'), signedIn: true);
      final otherRepo = RemoteBattleVoteRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadVotes();
      await otherRepo.saveVotes([_vote('their_vote', 'b1', voterId: 'someone_else')]);

      await repo.loadVotes();
      await repo.saveVotes([_vote('my_vote', 'b2', voterId: 'me')]);

      final mine = await repo.loadVotes();
      expect(mine.map((v) => v.id), ['my_vote']);
    });
  });
}
