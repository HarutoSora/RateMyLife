import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/presentation/screens/screens.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

UserProfile _profile(String id) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: id,
    age: 24,
    country: 'Morocco',
    city: 'City',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: 5000,
    currency: 'MAD',
    savings: 10000,
    investments: 0,
    debt: 0,
    monthlyExpenses: 1000,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: false,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const [],
    freeTimeHours: 10,
    closeFriends: 3,
    happiness: 7,
    stress: 3,
    currentGoal: 'Grow',
    bio: '',
    photos: const [],
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.them);
  final UserProfile them;

  @override
  Future<void> deleteCurrentProfile() async {}
  @override
  Future<UserProfile?> loadCurrentProfile() async => null;
  @override
  Future<UserProfile?> loadProfileById(String id) async => id == them.id ? them : null;
  @override
  Future<void> saveCurrentProfile(UserProfile profile) async {}
  @override
  String newProfileId() => 'user_test';
  @override
  Future<void> recordProfileView(String profileId) async {}
  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[them], hasMore: false);
  @override
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);
  @override
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since}) async =>
      (profiles: <UserProfile>[], hasMore: false);
  @override
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);
}

class _FakeMessageRepository implements MessageRepository {
  List<Message> stored = [];
  final _updates = StreamController<List<Message>>.broadcast();

  @override
  Future<List<Message>> loadMessages() async => stored;

  // Mirrors RemoteMessageRepository's real shape: the current value
  // immediately, then whatever gets pushed afterward — lets the test
  // drive a "new message arrived live" update through the same
  // subscription path AppController actually uses, instead of poking
  // protected ChangeNotifier internals directly.
  @override
  Stream<List<Message>> watchMessages() async* {
    yield stored;
    yield* _updates.stream;
  }

  void push(List<Message> messages) {
    stored = messages;
    _updates.add(messages);
  }

  @override
  Future<void> saveMessages(List<Message> messages) async => stored = messages;
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleDailyChallengeReminder() async {}
  @override
  Future<void> cancelDailyChallengeReminder() async {}
  @override
  Future<void> showNotification({required String title, required String body, String? payload}) async {}
  final _tapController = StreamController<String>.broadcast();
  @override
  Stream<String> get notificationTaps => _tapController.stream;
}

class _FakePushNotificationRepository implements PushNotificationRepository {
  final _controller = StreamController<RemoteMessage>.broadcast();
  final _openedController = StreamController<RemoteMessage>.broadcast();
  @override
  Future<void> registerDevice() async {}
  @override
  Future<void> unregisterDevice() async {}
  @override
  Stream<RemoteMessage> get foregroundMessages => _controller.stream;
  @override
  Stream<RemoteMessage> get openedMessages => _openedController.stream;
  @override
  Future<RemoteMessage?> getInitialMessage() async => null;
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<bool> hasSeenOnboarding() async => true;
  @override
  Future<void> setOnboardingSeen(bool value) async {}
  @override
  Future<UserSettings> loadSettings() async => const UserSettings();
  @override
  Future<void> saveSettings(UserSettings settings) async {}
  @override
  Future<List<BlockedUser>> loadBlockedUsers() async => const [];
  @override
  Future<void> saveBlockedUsers(List<BlockedUser> blocked) async {}
  @override
  Future<List<Report>> loadReports() async => const [];
  @override
  Future<void> saveReports(List<Report> reports) async {}
  @override
  Future<List<HiddenConversation>> loadHiddenConversations() async => const [];
  @override
  Future<void> saveHiddenConversations(List<HiddenConversation> hidden) async {}
  @override
  Future<void> resetApp() async {}
}

class _FakeRatingRepository implements RatingRepository {
  List<Rating> stored = [];
  @override
  Future<List<Rating>> loadRatings() async => stored;
  @override
  Future<void> saveRatings(List<Rating> ratings) async => stored = ratings;
}

class _FakeProgressionRepository implements ProgressionRepository {
  List<XpTransaction> stored = [];
  @override
  Future<List<XpTransaction>> loadXpTransactions() async => stored;
  @override
  Future<void> saveXpTransactions(List<XpTransaction> transactions) async => stored = transactions;
}

class _FakeAppOpenRepository implements AppOpenRepository {
  Set<DateTime> stored = {};
  @override
  Future<Set<DateTime>> loadOpenDays() async => stored;
  @override
  Future<void> recordOpenDay(DateTime day) async => stored = {...stored, day};
}

class _FakeAchievementRepository implements AchievementRepository {
  List<UserAchievement> stored = [];
  @override
  Future<List<UserAchievement>> loadAchievements() async => stored;
  @override
  Future<void> saveAchievements(List<UserAchievement> achievements) async => stored = achievements;
}

class _FakeCoinRepository implements CoinRepository {
  List<CoinTransaction> stored = [];
  @override
  Future<List<CoinTransaction>> loadCoinTransactions() async => stored;
  @override
  Future<void> saveCoinTransactions(List<CoinTransaction> transactions) async => stored = transactions;
}

class _FakeCosmeticRepository implements CosmeticRepository {
  List<CosmeticPurchase> stored = [];
  @override
  Future<List<CosmeticPurchase>> loadPurchases() async => stored;
  @override
  Future<void> savePurchases(List<CosmeticPurchase> purchases) async => stored = purchases;
}

class _FakeChallengeRepository implements ChallengeRepository {
  List<ChallengeCompletion> stored = [];
  @override
  Future<List<ChallengeCompletion>> loadChallengeCompletions() async => stored;
  @override
  Future<void> saveChallengeCompletions(List<ChallengeCompletion> completions) async => stored = completions;
}

class _FakeCommentRepository implements CommentRepository {
  List<Comment> stored = [];
  @override
  Future<List<Comment>> loadCommentsForProfile(String profileOwnerId) async =>
      stored.where((c) => c.profileOwnerId == profileOwnerId).toList();
  @override
  Future<List<Comment>> loadCommentsByAuthor(String authorId) async =>
      stored.where((c) => c.authorId == authorId).toList();
  @override
  Future<void> saveComments(List<Comment> comments) async => stored = comments;
}

class _FakeCommentReactionRepository implements CommentReactionRepository {
  List<CommentReaction> stored = [];
  @override
  Future<List<CommentReaction>> loadReactionsForProfile(String profileOwnerId) async =>
      stored.where((r) => r.profileOwnerId == profileOwnerId).toList();
  @override
  Future<void> saveReactions(List<CommentReaction> reactions) async => stored = reactions;
}

class _FakePhotoVoteRepository implements PhotoVoteRepository {
  List<PhotoVote> stored = [];
  @override
  Future<List<PhotoVote>> loadVotes() async => stored;
  @override
  Future<void> saveVotes(List<PhotoVote> votes) async => stored = votes;
}

class _FakeNukeRepository implements NukeRepository {
  List<NukeEvent> stored = [];
  @override
  Future<List<NukeEvent>> loadSentHistory() async => stored;
  @override
  Future<NukeEvent> attack({
    required String attackerId,
    required UserProfile target,
    required String attribute,
  }) async {
    final event = NukeEvent(
      id: 'nuke_${stored.length}',
      attackerId: attackerId,
      targetId: target.id,
      targetName: target.displayName,
      attribute: attribute,
      damage: -5,
      createdAt: DateTime.now(),
    );
    stored = [...stored, event];
    return event;
  }
}

class _FakeBattleRepository implements BattleRepository {
  List<Battle> stored = [];
  @override
  Future<List<Battle>> loadBattles() async => stored;
  @override
  Future<void> saveBattles(List<Battle> battles) async => stored = battles;
}

class _FakeBattleVoteRepository implements BattleVoteRepository {
  List<BattleVote> stored = [];
  @override
  Future<List<BattleVote>> loadVotes() async => stored;
  @override
  Future<void> saveVotes(List<BattleVote> votes) async => stored = votes;
}

class _FakeChoiceRepository implements ChoiceRepository {
  List<ChoiceVote> stored = [];
  @override
  Future<List<ChoiceVote>> loadMyVotes() async => stored;
  @override
  Future<void> saveVote(ChoiceVote vote) async {
    if (stored.any((v) => v.id == vote.id)) return;
    stored = [...stored, vote];
  }

  @override
  Future<ChoiceTally> loadTally(String questionId) async {
    final matching = stored.where((v) => v.questionId == questionId);
    return (
      countA: matching.where((v) => v.chosenOption == ChoiceOption.a).length,
      countB: matching.where((v) => v.chosenOption == ChoiceOption.b).length,
    );
  }
}

class _FakeCallRepository implements CallRepository {
  @override
  Stream<CallSession?> get currentCall => Stream.value(null);
  @override
  bool get isMuted => false;
  @override
  Future<void> startCall(String calleeId) async {}
  @override
  Future<void> acceptCall() async {}
  @override
  Future<void> declineCall() async {}
  @override
  Future<void> endCall() async {}
  @override
  Future<void> toggleMute() async {}
}

void main() {
  testWidgets('a message that arrives while the conversation is already open gets marked read too', (tester) async {
    final them = _profile('them');
    final messageRepo = _FakeMessageRepository()
      ..stored = [
        Message(id: 'm1', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'first', createdAt: DateTime(2026)),
      ];
    final bundle = RepositoryBundle(
      profileRepository: _FakeProfileRepository(them),
      messageRepository: messageRepo,
      notificationRepository: _FakeNotificationRepository(),
      pushNotificationRepository: _FakePushNotificationRepository(),
    );
    final container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(bundle)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConversationScreen(otherUserId: 'them')),
      ),
    );
    await tester.pump();
    await tester.pump();

    final controller = container.read(appControllerProvider);
    // initState's one-shot markConversationRead already caught the
    // first message.
    expect(controller.unreadMessageCount, 0);

    // Simulate a second message arriving live (what the Firestore
    // listener does) while this same screen is still open — the
    // regression this test guards: without the build-time check, this
    // one would stay unread until the screen was reopened.
    messageRepo.push([
      ...controller.messages,
      Message(id: 'm2', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'second', createdAt: DateTime(2026, 1, 2)),
    ]);
    await tester.pump();
    await tester.pump();

    expect(controller.unreadMessageCount, 0);
  });

  testWidgets('opening a long thread lands on the newest message, not wherever it laid out first', (tester) async {
    // A small viewport, so a modest number of messages reliably
    // overflows it — "scrolled to the bottom" and "not scrolled" must
    // be actually distinguishable for this test to mean anything.
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final them = _profile('them');
    final now = DateTime(2026);
    final messages = [
      for (var i = 0; i < 30; i++)
        Message(
          id: 'm$i',
          conversationId: 'local_user_them',
          senderId: i.isEven ? 'them' : 'local_user',
          recipientId: i.isEven ? 'local_user' : 'them',
          content: 'message number $i, long enough to take its own line in the list',
          createdAt: now.add(Duration(minutes: i)),
        ),
    ];
    final messageRepo = _FakeMessageRepository()..stored = messages;
    final bundle = RepositoryBundle(
      profileRepository: _FakeProfileRepository(them),
      messageRepository: messageRepo,
      notificationRepository: _FakeNotificationRepository(),
      pushNotificationRepository: _FakePushNotificationRepository(),
      settingsRepository: _FakeSettingsRepository(),
      ratingRepository: _FakeRatingRepository(),
      progressionRepository: _FakeProgressionRepository(),
      appOpenRepository: _FakeAppOpenRepository(),
      achievementRepository: _FakeAchievementRepository(),
      coinRepository: _FakeCoinRepository(),
      cosmeticRepository: _FakeCosmeticRepository(),
      challengeRepository: _FakeChallengeRepository(),
      commentRepository: _FakeCommentRepository(),
      commentReactionRepository: _FakeCommentReactionRepository(),
      photoVoteRepository: _FakePhotoVoteRepository(),
      nukeRepository: _FakeNukeRepository(),
      battleRepository: _FakeBattleRepository(),
      battleVoteRepository: _FakeBattleVoteRepository(),
      choiceRepository: _FakeChoiceRepository(),
      callRepository: _FakeCallRepository(),
    );
    final container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(bundle)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConversationScreen(otherUserId: 'them')),
      ),
    );
    await tester.pump();
    await tester.pump();

    final position = tester
        .widget<Scrollable>(find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)))
        .controller!
        .position;
    expect(position.pixels, position.maxScrollExtent);
    expect(position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('a live message that arrives while the thread is open scrolls down to it too', (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final them = _profile('them');
    final now = DateTime(2026);
    final initial = [
      for (var i = 0; i < 30; i++)
        Message(
          id: 'm$i',
          conversationId: 'local_user_them',
          senderId: i.isEven ? 'them' : 'local_user',
          recipientId: i.isEven ? 'local_user' : 'them',
          content: 'message number $i, long enough to take its own line in the list',
          createdAt: now.add(Duration(minutes: i)),
        ),
    ];
    final messageRepo = _FakeMessageRepository()..stored = initial;
    final bundle = RepositoryBundle(
      profileRepository: _FakeProfileRepository(them),
      messageRepository: messageRepo,
      notificationRepository: _FakeNotificationRepository(),
      pushNotificationRepository: _FakePushNotificationRepository(),
      settingsRepository: _FakeSettingsRepository(),
      ratingRepository: _FakeRatingRepository(),
      progressionRepository: _FakeProgressionRepository(),
      appOpenRepository: _FakeAppOpenRepository(),
      achievementRepository: _FakeAchievementRepository(),
      coinRepository: _FakeCoinRepository(),
      cosmeticRepository: _FakeCosmeticRepository(),
      challengeRepository: _FakeChallengeRepository(),
      commentRepository: _FakeCommentRepository(),
      commentReactionRepository: _FakeCommentReactionRepository(),
      photoVoteRepository: _FakePhotoVoteRepository(),
      nukeRepository: _FakeNukeRepository(),
      battleRepository: _FakeBattleRepository(),
      battleVoteRepository: _FakeBattleVoteRepository(),
      choiceRepository: _FakeChoiceRepository(),
      callRepository: _FakeCallRepository(),
    );
    final container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(bundle)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConversationScreen(otherUserId: 'them')),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Scroll back up, away from the bottom, before the new message
    // arrives — mimics re-reading earlier context mid-conversation.
    final position = tester
        .widget<Scrollable>(find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)))
        .controller!
        .position;
    position.jumpTo(0);
    await tester.pump();
    expect(position.pixels, 0);

    messageRepo.push([
      ...initial,
      Message(
        id: 'm30',
        conversationId: 'local_user_them',
        senderId: 'them',
        recipientId: 'local_user',
        content: 'just arrived',
        createdAt: now.add(const Duration(minutes: 30)),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(position.pixels, position.maxScrollExtent);
  });
}
