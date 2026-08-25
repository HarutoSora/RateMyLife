import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

XpTransaction _xp(String id, {String profileId = 'me'}) => XpTransaction(
      id: id,
      profileId: profileId,
      amount: 10,
      reason: XpReason.ratingGiven,
      createdAt: DateTime(2026, 1, 1),
    );

CoinTransaction _coin(String id, {String profileId = 'me'}) => CoinTransaction(
      id: id,
      profileId: profileId,
      amount: 5,
      reason: XpReason.ratingGiven,
      createdAt: DateTime(2026, 1, 1),
    );

UserAchievement _achievement(String id, {String profileId = 'me'}) => UserAchievement(
      id: id,
      profileId: profileId,
      achievementId: 'first_steps',
      unlockedAt: DateTime(2026, 1, 1),
    );

ChallengeCompletion _challenge(String id, {String profileId = 'me'}) => ChallengeCompletion(
      id: id,
      profileId: profileId,
      challengeId: 'rate_3',
      date: DateTime(2026, 1, 1),
      completedAt: DateTime(2026, 1, 1),
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
  });

  group('RemoteProgressionRepository', () {
    test('saves and round-trips XP transactions, scoped to the owner', () async {
      final repo = RemoteProgressionRepository(firestore: firestore, auth: auth);
      await repo.loadXpTransactions();
      await repo.saveXpTransactions([_xp('tx1')]);

      final loaded = await repo.loadXpTransactions();
      expect(loaded.single.id, 'tx1');
      expect(loaded.single.amount, 10);
    });

    test('does not rewrite an already-known transaction', () async {
      final repo = RemoteProgressionRepository(firestore: firestore, auth: auth);
      await repo.loadXpTransactions();
      await repo.saveXpTransactions([_xp('tx1')]);
      await repo.saveXpTransactions([_xp('tx1'), _xp('tx2')]);

      expect(await firestore.collection('xpTransactions').get().then((s) => s.docs), hasLength(2));
    });

    test('only loads this device\'s own transactions', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemoteProgressionRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadXpTransactions();
      await otherRepo.saveXpTransactions([_xp('theirs', profileId: 'other')]);

      final repo = RemoteProgressionRepository(firestore: firestore, auth: auth);
      await repo.loadXpTransactions();
      await repo.saveXpTransactions([_xp('mine')]);

      final mine = await repo.loadXpTransactions();
      expect(mine.map((tx) => tx.id), ['mine']);
    });
  });

  group('RemoteAppOpenRepository', () {
    test('saves and round-trips an open day', () async {
      final repo = RemoteAppOpenRepository(firestore: firestore, auth: auth);
      await repo.recordOpenDay(DateTime(2026, 1, 1));

      final loaded = await repo.loadOpenDays();
      expect(loaded, {DateTime(2026, 1, 1)});
    });

    test('recording the same day twice does not duplicate it', () async {
      final repo = RemoteAppOpenRepository(firestore: firestore, auth: auth);
      await repo.recordOpenDay(DateTime(2026, 1, 1));
      await repo.recordOpenDay(DateTime(2026, 1, 1));
      await repo.recordOpenDay(DateTime(2026, 1, 2));

      final loaded = await repo.loadOpenDays();
      expect(loaded, {DateTime(2026, 1, 1), DateTime(2026, 1, 2)});
    });

    test('only loads this device\'s own open days', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemoteAppOpenRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.recordOpenDay(DateTime(2026, 1, 5));

      final repo = RemoteAppOpenRepository(firestore: firestore, auth: auth);
      await repo.recordOpenDay(DateTime(2026, 1, 1));

      final mine = await repo.loadOpenDays();
      expect(mine, {DateTime(2026, 1, 1)});
    });
  });

  group('RemoteChoiceRepository', () {
    ChoiceVote vote(String voterId, String questionId, ChoiceOption option) => ChoiceVote(
          id: '${voterId}_$questionId',
          questionId: questionId,
          voterId: voterId,
          chosenOption: option,
          createdAt: DateTime(2026, 1, 1),
        );

    test('saves and round-trips this device\'s own vote', () async {
      final repo = RemoteChoiceRepository(firestore: firestore, auth: auth);
      await repo.saveVote(vote('me', 'q1', ChoiceOption.a));

      final mine = await repo.loadMyVotes();
      expect(mine.single.questionId, 'q1');
      expect(mine.single.chosenOption, ChoiceOption.a);
    });

    test('saveVote never reads before writing, so voting on a brand-new question succeeds', () async {
      // Regression guard: an earlier version pre-checked whether the
      // vote doc already existed via a `.get()`, which the real
      // firestore.rules deny for a document that doesn't exist yet
      // (the same "safe accessor" pitfall as allowMessages/allowCalls).
      // fake_cloud_firestore doesn't enforce rules, so this test can't
      // catch that class of bug directly, but it does pin the fixed
      // contract: no existence check, straight to `set`.
      final repo = RemoteChoiceRepository(firestore: firestore, auth: auth);
      await repo.saveVote(vote('me', 'q1', ChoiceOption.a));

      expect(await firestore.collection('choiceVotes').doc('me_q1').get().then((d) => d.exists), isTrue);
    });

    test('the tally reflects every voter, not just this device\'s own', () async {
      final other1 = MockFirebaseAuth(mockUser: MockUser(uid: 'p1'), signedIn: true);
      final other2 = MockFirebaseAuth(mockUser: MockUser(uid: 'p2'), signedIn: true);
      await RemoteChoiceRepository(firestore: firestore, auth: other1).saveVote(vote('p1', 'q1', ChoiceOption.a));
      await RemoteChoiceRepository(firestore: firestore, auth: other2).saveVote(vote('p2', 'q1', ChoiceOption.b));
      final repo = RemoteChoiceRepository(firestore: firestore, auth: auth);
      await repo.saveVote(vote('me', 'q1', ChoiceOption.a));

      final tally = await repo.loadTally('q1');
      expect(tally.countA, 2);
      expect(tally.countB, 1);
    });

    test('loadTally is zero for a question nobody has voted on yet', () async {
      final repo = RemoteChoiceRepository(firestore: firestore, auth: auth);
      final tally = await repo.loadTally('never_voted');
      expect(tally, (countA: 0, countB: 0));
    });

    test('only loads this device\'s own votes', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      await RemoteChoiceRepository(firestore: firestore, auth: otherAuth).saveVote(vote('other', 'q1', ChoiceOption.b));

      final repo = RemoteChoiceRepository(firestore: firestore, auth: auth);
      await repo.saveVote(vote('me', 'q1', ChoiceOption.a));

      final mine = await repo.loadMyVotes();
      expect(mine.map((v) => v.voterId), ['me']);
    });
  });

  group('RemoteCoinRepository', () {
    test('saves and round-trips coin transactions', () async {
      final repo = RemoteCoinRepository(firestore: firestore, auth: auth);
      await repo.loadCoinTransactions();
      await repo.saveCoinTransactions([_coin('c1')]);

      final loaded = await repo.loadCoinTransactions();
      expect(loaded.single.id, 'c1');
      expect(loaded.single.amount, 5);
    });

    test('does not rewrite an already-known transaction', () async {
      final repo = RemoteCoinRepository(firestore: firestore, auth: auth);
      await repo.loadCoinTransactions();
      await repo.saveCoinTransactions([_coin('c1')]);
      await repo.saveCoinTransactions([_coin('c1'), _coin('c2')]);

      expect(await firestore.collection('coinTransactions').get().then((s) => s.docs), hasLength(2));
    });
  });

  group('RemoteAchievementRepository', () {
    test('saves and round-trips unlocked achievements', () async {
      final repo = RemoteAchievementRepository(firestore: firestore, auth: auth);
      await repo.loadAchievements();
      await repo.saveAchievements([_achievement('a1')]);

      final loaded = await repo.loadAchievements();
      expect(loaded.single.achievementId, 'first_steps');
    });

    test('does not rewrite an already-known achievement', () async {
      final repo = RemoteAchievementRepository(firestore: firestore, auth: auth);
      await repo.loadAchievements();
      await repo.saveAchievements([_achievement('a1')]);
      await repo.saveAchievements([_achievement('a1'), _achievement('a2')]);

      expect(await firestore.collection('userAchievements').get().then((s) => s.docs), hasLength(2));
    });
  });

  group('RemoteChallengeRepository', () {
    test('saves and round-trips challenge completions', () async {
      final repo = RemoteChallengeRepository(firestore: firestore, auth: auth);
      await repo.loadChallengeCompletions();
      await repo.saveChallengeCompletions([_challenge('cc1')]);

      final loaded = await repo.loadChallengeCompletions();
      expect(loaded.single.challengeId, 'rate_3');
    });

    test('does not rewrite an already-known completion', () async {
      final repo = RemoteChallengeRepository(firestore: firestore, auth: auth);
      await repo.loadChallengeCompletions();
      await repo.saveChallengeCompletions([_challenge('cc1')]);
      await repo.saveChallengeCompletions([_challenge('cc1'), _challenge('cc2')]);

      expect(await firestore.collection('challengeCompletions').get().then((s) => s.docs), hasLength(2));
    });
  });
}
