import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/domain/services/progression_service.dart';
import 'package:rate_my_life/domain/services/reward_service.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.mockProfiles);

  final List<UserProfile> mockProfiles;
  UserProfile? existing;

  @override
  Future<void> deleteCurrentProfile() async {}

  @override
  Future<UserProfile?> loadCurrentProfile() async => existing;

  @override
  Future<UserProfile?> loadProfileById(String id) async =>
      mockProfiles.where((p) => p.id == id).firstOrNull ?? (existing?.id == id ? existing : null);

  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async =>
      (profiles: mockProfiles, hasMore: false);

  @override
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after}) async =>
      (profiles: mockProfiles, hasMore: false);

  @override
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since}) async =>
      (profiles: mockProfiles.where((p) => !p.createdAt.isBefore(since)).toList(), hasMore: false);

  @override
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after}) async =>
      (profiles: mockProfiles, hasMore: false);

  @override
  Future<void> saveCurrentProfile(UserProfile profile) async => existing = profile;

  @override
  String newProfileId() => 'user_test';

  @override
  Future<void> recordProfileView(String profileId) async {}
}

class _FakeRatingRepository implements RatingRepository {
  List<Rating> stored = [];
  @override
  Future<List<Rating>> loadRatings() async => stored;
  @override
  Future<void> saveRatings(List<Rating> ratings) async => stored = ratings;
}

class _FakeSettingsRepository implements SettingsRepository {
  List<BlockedUser> blocked = [];
  @override
  Future<bool> hasSeenOnboarding() async => true;
  @override
  Future<void> setOnboardingSeen(bool value) async {}
  @override
  Future<UserSettings> loadSettings() async => const UserSettings();
  @override
  Future<void> saveSettings(UserSettings settings) async {}
  @override
  Future<List<BlockedUser>> loadBlockedUsers() async => blocked;
  @override
  Future<void> saveBlockedUsers(List<BlockedUser> blockedUsers) async => blocked = blockedUsers;
  @override
  Future<List<Report>> loadReports() async => const [];
  @override
  Future<void> saveReports(List<Report> reports) async {}
  List<HiddenConversation> hiddenConversations = [];
  @override
  Future<List<HiddenConversation>> loadHiddenConversations() async => hiddenConversations;
  @override
  Future<void> saveHiddenConversations(List<HiddenConversation> hidden) async => hiddenConversations = hidden;
  @override
  Future<void> resetApp() async {}
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

class _FakeChallengeRepository implements ChallengeRepository {
  List<ChallengeCompletion> stored = [];
  @override
  Future<List<ChallengeCompletion>> loadChallengeCompletions() async => stored;
  @override
  Future<void> saveChallengeCompletions(List<ChallengeCompletion> completions) async => stored = completions;
}

class _FakeCosmeticRepository implements CosmeticRepository {
  List<CosmeticPurchase> stored = [];
  @override
  Future<List<CosmeticPurchase>> loadPurchases() async => stored;
  @override
  Future<void> savePurchases(List<CosmeticPurchase> purchases) async => stored = purchases;
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

class _FakePurchaseRepository implements PurchaseRepository {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async => [];
  @override
  Future<void> buyConsumable(ProductDetails product) async {}
  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => const Stream.empty();
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

class _FakeNotificationRepository implements NotificationRepository {
  bool permissionGranted = true;
  bool scheduled = false;
  @override
  Future<bool> requestPermission() async => permissionGranted;
  @override
  Future<void> scheduleDailyChallengeReminder() async => scheduled = true;
  @override
  Future<void> cancelDailyChallengeReminder() async => scheduled = false;
  @override
  Future<void> showNotification({required String title, required String body, String? payload}) async {}
  @override
  Stream<String> get notificationTaps => const Stream.empty();
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

class _FakeMessageRepository implements MessageRepository {
  List<Message> stored = [];
  @override
  Future<List<Message>> loadMessages() async => stored;
  @override
  Stream<List<Message>> watchMessages() => Stream.value(stored);
  @override
  Future<void> saveMessages(List<Message> messages) async => stored = messages;
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

class _FakeCommentReactionRepository implements CommentReactionRepository {
  List<CommentReaction> stored = [];
  @override
  Future<List<CommentReaction>> loadReactionsForProfile(String profileOwnerId) async =>
      stored.where((r) => r.profileOwnerId == profileOwnerId).toList();
  @override
  Future<void> saveReactions(List<CommentReaction> reactions) async => stored = reactions;
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

UserProfile _profile({
  required String id,
  int overall = 50,
  ProfilePrivacy privacy = const ProfilePrivacy(),
}) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: id,
    age: 24,
    country: 'Morocco',
    city: 'Rabat',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: 10000,
    currency: 'MAD',
    savings: 50000,
    investments: 0,
    debt: 0,
    monthlyExpenses: 4000,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: false,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const ['Travel'],
    freeTimeHours: 12,
    closeFriends: 4,
    happiness: 7,
    stress: 4,
    currentGoal: 'Grow',
    bio: 'Building.',
    photos: const [],
    score: LifeScore(
      overall: overall,
      career: overall,
      financial: overall,
      education: overall,
      independence: overall,
      social: overall,
      lifestyle: overall,
      wellbeing: overall,
      explanations: const {},
      calculatedAt: now,
    ),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: privacy,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late ProviderContainer container;
  late AppController controller;
  late _FakeBattleRepository battleRepository;
  late _FakeBattleVoteRepository battleVoteRepository;
  late _FakeSettingsRepository settingsRepository;

  Future<void> setUpController({
    required List<UserProfile> mockProfiles,
    UserProfile? seededCurrentProfile,
  }) async {
    battleRepository = _FakeBattleRepository();
    battleVoteRepository = _FakeBattleVoteRepository();
    settingsRepository = _FakeSettingsRepository();
    final repos = RepositoryBundle(
      profileRepository: _FakeProfileRepository(mockProfiles)..existing = seededCurrentProfile,
      ratingRepository: _FakeRatingRepository(),
      settingsRepository: settingsRepository,
      progressionRepository: _FakeProgressionRepository(),
      appOpenRepository: _FakeAppOpenRepository(),
      achievementRepository: _FakeAchievementRepository(),
      coinRepository: _FakeCoinRepository(),
      challengeRepository: _FakeChallengeRepository(),
      cosmeticRepository: _FakeCosmeticRepository(),
      photoVoteRepository: _FakePhotoVoteRepository(),
      nukeRepository: _FakeNukeRepository(),
      purchaseRepository: _FakePurchaseRepository(),
      notificationRepository: _FakeNotificationRepository(),
      commentRepository: _FakeCommentRepository(),
      messageRepository: _FakeMessageRepository(),
      callRepository: _FakeCallRepository(),
      commentReactionRepository: _FakeCommentReactionRepository(),
      battleRepository: battleRepository,
      battleVoteRepository: battleVoteRepository,
      choiceRepository: _FakeChoiceRepository(),
    );
    container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(repos)]);
    controller = container.read(appControllerProvider);
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() => container.dispose());

  group('Life Battles via AppController', () {
    test('ensureBattle returns null with fewer than 2 eligible profiles', () async {
      await setUpController(mockProfiles: [_profile(id: 'a')]);
      final battle = await controller.ensureBattle();
      expect(battle, isNull);
    });

    test('ensureBattle generates and persists a battle between two distinct profiles', () async {
      await setUpController(mockProfiles: [_profile(id: 'a'), _profile(id: 'b'), _profile(id: 'c')]);
      final battle = await controller.ensureBattle();

      expect(battle, isNotNull);
      expect(battle!.profileAId, isNot(equals(battle.profileBId)));
      expect(battleRepository.stored, hasLength(1));
    });

    test('ensureBattle reuses a pending unvoted battle instead of generating a new one', () async {
      await setUpController(mockProfiles: [_profile(id: 'a'), _profile(id: 'b'), _profile(id: 'c')]);
      final first = await controller.ensureBattle();
      final second = await controller.ensureBattle();

      expect(second!.id, first!.id);
      expect(battleRepository.stored, hasLength(1));
    });

    test('blocked profiles never appear as battle participants', () async {
      await setUpController(mockProfiles: [_profile(id: 'a'), _profile(id: 'b')]);
      await controller.blockUserId('b');

      final battle = await controller.ensureBattle();
      expect(battle, isNull);
    });

    test('voting records the vote, grants XP/coins once, and blocks a second vote', () async {
      await setUpController(
        mockProfiles: [_profile(id: 'a'), _profile(id: 'b')],
        seededCurrentProfile: _profile(id: 'me'),
      );
      final battle = await controller.ensureBattle();
      expect(battle, isNotNull);

      // Voting might also happen to be one of today's date-based 3
      // rotated daily challenges (see DailyChallengeService) — if so, its
      // bonus lands in the same call too, on top of the base reward.
      final todaysBattleChallenge = controller.todaysChallenges.where((c) => c.trackedReason == XpReason.battleVoted);
      final challengeXpBonus = todaysBattleChallenge.isEmpty ? 0 : todaysBattleChallenge.first.xpReward;
      final challengeCoinBonus = todaysBattleChallenge.isEmpty ? 0 : todaysBattleChallenge.first.coinReward;

      await controller.voteBattle(battle!, 'a');

      // Voting is also this profile's first-ever activity, so the
      // "First Steps" achievement bonus (50 XP) lands in the same call.
      expect(controller.myVoteFor(battle.id)?.chosenProfileId, 'a');
      expect(controller.currentProfile!.xp, ProgressionService.xpRewards[XpReason.battleVoted]! + 50 + challengeXpBonus);
      expect(controller.currentProfile!.coins, RewardService.coinRewards[XpReason.battleVoted]! + challengeCoinBonus);
      expect(battleVoteRepository.stored, hasLength(1));

      // Voting again on the same battle must not double-count.
      await controller.voteBattle(battle, 'b');
      expect(battleVoteRepository.stored, hasLength(1));
      expect(controller.myVoteFor(battle.id)?.chosenProfileId, 'a');
    });

    test('battleResultFor exposes real category data and a plausible estimate, not a live tally', () async {
      await setUpController(mockProfiles: [
        _profile(id: 'a', overall: 80),
        _profile(id: 'b', overall: 20),
      ]);
      final battle = await controller.ensureBattle();
      final result = controller.battleResultFor(battle!);

      expect(result.percentageForA + result.percentageForB, 100);
      expect(result.hasVoted, isFalse);

      final rows = controller.battleCategoryComparison(battle);
      expect(rows, isNotEmpty);
    });

    test('judging 10 battles unlocks the Battle Judge achievement', () async {
      final pool = [for (var i = 0; i < 20; i++) _profile(id: 'p$i')];
      await setUpController(mockProfiles: pool, seededCurrentProfile: _profile(id: 'me'));

      for (var i = 0; i < 10; i++) {
        final battle = await controller.generateBattle();
        await controller.voteBattle(battle!, battle.profileAId);
      }

      expect(controller.unlockedAchievementIds, contains('battle_judge'));
    });
  });
}
