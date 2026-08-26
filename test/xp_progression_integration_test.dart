import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rate_my_life/core/purchases/purchase_config.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/domain/services/choice_service.dart';
import 'package:rate_my_life/domain/services/nuke_service.dart';
import 'package:rate_my_life/domain/services/progression_service.dart';
import 'package:rate_my_life/domain/services/reward_service.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  UserProfile? saved;

  /// What `_load()` should find as the already-existing current profile —
  /// null (the default) simulates a fresh install.
  UserProfile? existing;

  /// Other profiles for `_load()` to populate `AppController.profiles`
  /// with — empty by default (most tests don't need a comparison pool).
  List<UserProfile> mockProfiles = [];

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
  Future<void> saveCurrentProfile(UserProfile profile) async => saved = profile;

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

class _FakeNotificationRepository implements NotificationRepository {
  bool permissionGranted = true;
  bool scheduled = false;
  int scheduleCalls = 0;
  int cancelCalls = 0;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleDailyChallengeReminder() async {
    scheduled = true;
    scheduleCalls++;
  }

  @override
  Future<void> cancelDailyChallengeReminder() async {
    scheduled = false;
    cancelCalls++;
  }

  @override
  Future<void> showNotification({required String title, required String body, String? payload}) async {
    shownNotifications.add((title: title, body: body, payload: payload));
  }

  final shownNotifications = <({String title, String body, String? payload})>[];

  final _tapController = StreamController<String>.broadcast();
  void tapNotification(String payload) => _tapController.add(payload);

  @override
  Stream<String> get notificationTaps => _tapController.stream;
}

class _FakePushNotificationRepository implements PushNotificationRepository {
  int registerCalls = 0;
  int unregisterCalls = 0;
  final _controller = StreamController<RemoteMessage>.broadcast();
  final _openedController = StreamController<RemoteMessage>.broadcast();
  RemoteMessage? initialMessage;

  void push(RemoteMessage message) => _controller.add(message);
  void openFromBackground(RemoteMessage message) => _openedController.add(message);

  @override
  Future<void> registerDevice() async => registerCalls++;

  @override
  Future<void> unregisterDevice() async => unregisterCalls++;

  @override
  Stream<RemoteMessage> get foregroundMessages => _controller.stream;

  @override
  Stream<RemoteMessage> get openedMessages => _openedController.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;
}

class _FakeAdRepository implements AdRepository {
  int showCalls = 0;
  int interstitialCalls = 0;

  /// Whether the next `showRewardedAd` call simulates the user watching
  /// to completion (`onReward` fires) or the ad failing/being closed
  /// early (`onReward` never fires) — mirrors the two real outcomes.
  bool rewardOnShow = true;

  @override
  Future<void> showRewardedAd({required VoidCallback onReward}) async {
    showCalls++;
    if (rewardOnShow) onReward();
  }

  @override
  Future<void> showInterstitialAd() async {
    interstitialCalls++;
  }
}

class _FakePurchaseRepository implements PurchaseRepository {
  bool available = false;
  List<ProductDetails> products = [];
  final List<ProductDetails> bought = [];
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async =>
      products.where((p) => productIds.contains(p.id)).toList();

  @override
  Future<void> buyConsumable(ProductDetails product) async {
    bought.add(product);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _controller.stream;

  void push(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
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

  /// Set to simulate a slow/never-resolving write, for tests that
  /// need to assert something happened *before* the network round
  /// trip, not after.
  Duration? saveDelay;

  @override
  Future<List<Message>> loadMessages() async => stored;

  @override
  Stream<List<Message>> watchMessages() => Stream.value(stored);

  @override
  Future<void> saveMessages(List<Message> messages) async {
    if (saveDelay != null) await Future.delayed(saveDelay!);
    stored = messages;
  }
}

class _FakeCallRepository implements CallRepository {
  List<String> startedCalleeIds = [];

  @override
  Stream<CallSession?> get currentCall => Stream.value(null);
  @override
  bool get isMuted => false;
  @override
  Future<void> startCall(String calleeId) async {
    startedCalleeIds.add(calleeId);
  }

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

  List<HiddenConversation> hiddenConversations = [];

  @override
  Future<List<HiddenConversation>> loadHiddenConversations() async => hiddenConversations;

  @override
  Future<void> saveHiddenConversations(List<HiddenConversation> hidden) async => hiddenConversations = hidden;

  @override
  Future<void> resetApp() async {}
}

class _FakePhotoRepository implements PhotoRepository {
  Uint8List? bytesToReturn;

  @override
  Future<ProfilePhoto> pickAndStorePhoto({
    required String ownerId,
    required ImageSource source,
    required int order,
    String category = 'Lifestyle',
  }) async {
    return ProfilePhoto(
      id: 'photo_$order',
      ownerId: ownerId,
      path: 'mock://Profile',
      isProfilePhoto: order == 0,
      order: order,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Uint8List?> readPhotoBytes(ProfilePhoto photo) async => bytesToReturn;
}

UserProfile _profile({int xp = 0}) {
  final now = DateTime(2026);
  return UserProfile(
    id: 'me',
    displayName: 'Tester',
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
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
    isCurrentUser: true,
    xp: xp,
  );
}

/// A comparison-pool profile for percentile tests — unlike `_profile()`
/// (always the local device's own profile, id `'me'`), these are other
/// known profiles with a caller-chosen id/age/country/score.
UserProfile _otherProfile({required String id, int age = 24, String country = 'Morocco', int score = 50}) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: id,
    age: age,
    country: country,
    city: 'City',
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
    hobbies: const [],
    freeTimeHours: 12,
    closeFriends: 4,
    happiness: 7,
    stress: 4,
    currentGoal: 'Grow',
    bio: '',
    photos: const [],
    score: LifeScore(
      overall: score,
      career: score,
      financial: score,
      education: score,
      independence: score,
      social: score,
      lifestyle: score,
      wellbeing: score,
      explanations: const {},
      calculatedAt: now,
    ),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late ProviderContainer container;
  late AppController controller;
  late _FakeProfileRepository profileRepository;
  late _FakeProgressionRepository progressionRepository;
  late _FakeAchievementRepository achievementRepository;
  late _FakeCoinRepository coinRepository;
  late _FakeChallengeRepository challengeRepository;
  late _FakeCosmeticRepository cosmeticRepository;
  late _FakeCommentRepository commentRepository;
  late _FakeCommentReactionRepository commentReactionRepository;
  late _FakeBattleRepository battleRepository;
  late _FakeBattleVoteRepository battleVoteRepository;
  late _FakeChoiceRepository choiceRepository;
  late _FakePhotoRepository photoRepository;
  late _FakePhotoVoteRepository photoVoteRepository;
  late _FakeNotificationRepository notificationRepository;
  late _FakePushNotificationRepository pushNotificationRepository;
  late _FakeMessageRepository messageRepository;
  late _FakeCallRepository callRepository;
  late _FakeAppOpenRepository appOpenRepository;
  late _FakeAdRepository adRepository;
  late _FakePurchaseRepository purchaseRepository;
  late _FakeRatingRepository ratingRepository;
  late _FakeNukeRepository nukeRepository;

  Future<void> setUpController({List<UserProfile> mockProfiles = const [], RemoteMessage? initialPushMessage}) async {
    profileRepository = _FakeProfileRepository()..mockProfiles = mockProfiles;
    ratingRepository = _FakeRatingRepository();
    progressionRepository = _FakeProgressionRepository();
    appOpenRepository = _FakeAppOpenRepository();
    achievementRepository = _FakeAchievementRepository();
    coinRepository = _FakeCoinRepository();
    challengeRepository = _FakeChallengeRepository();
    cosmeticRepository = _FakeCosmeticRepository();
    commentRepository = _FakeCommentRepository();
    commentReactionRepository = _FakeCommentReactionRepository();
    battleRepository = _FakeBattleRepository();
    battleVoteRepository = _FakeBattleVoteRepository();
    choiceRepository = _FakeChoiceRepository();
    photoRepository = _FakePhotoRepository();
    photoVoteRepository = _FakePhotoVoteRepository();
    notificationRepository = _FakeNotificationRepository();
    pushNotificationRepository = _FakePushNotificationRepository()..initialMessage = initialPushMessage;
    messageRepository = _FakeMessageRepository();
    callRepository = _FakeCallRepository();
    adRepository = _FakeAdRepository();
    nukeRepository = _FakeNukeRepository();
    purchaseRepository = _FakePurchaseRepository();
    final repos = RepositoryBundle(
      profileRepository: profileRepository,
      ratingRepository: ratingRepository,
      photoVoteRepository: photoVoteRepository,
      nukeRepository: nukeRepository,
      notificationRepository: notificationRepository,
      pushNotificationRepository: pushNotificationRepository,
      adRepository: adRepository,
      purchaseRepository: purchaseRepository,
      messageRepository: messageRepository,
      callRepository: callRepository,
      settingsRepository: _FakeSettingsRepository(),
      progressionRepository: progressionRepository,
      appOpenRepository: appOpenRepository,
      achievementRepository: achievementRepository,
      coinRepository: coinRepository,
      challengeRepository: challengeRepository,
      cosmeticRepository: cosmeticRepository,
      commentRepository: commentRepository,
      commentReactionRepository: commentReactionRepository,
      battleRepository: battleRepository,
      battleVoteRepository: battleVoteRepository,
      choiceRepository: choiceRepository,
      photoRepository: photoRepository,
    );
    container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(repos)]);
    controller = container.read(appControllerProvider);
    // Let the async _load() in the constructor finish.
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() => container.dispose());

  group('XP progression via AppController', () {
    test('creating a profile awards profileCompleted XP plus the First Steps achievement bonus', () async {
      await setUpController();
      await controller.createProfile(_profile());

      // Completing a profile immediately satisfies the "First Steps"
      // achievement too, so both bonuses land in the same action.
      const expectedXp = 150 /* profileCompleted */ + 50 /* first_steps bonus */;
      expect(controller.currentProfile!.xp, expectedXp);
      expect(controller.xpTransactions, hasLength(2));
      expect(controller.xpTransactions.map((tx) => tx.reason), [XpReason.profileCompleted, XpReason.achievementUnlocked]);
      expect(controller.unlockedAchievementIds, contains('first_steps'));
    });

    test('adding a photo awards photoAdded XP on top of existing XP', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final afterCreate = controller.currentProfile!.xp;

      await controller.addPhoto(ImageSource.gallery);

      // On days where "Add a photo" happens to be in today's 3-challenge
      // rotation, this single action also completes it — account for
      // that date-dependent bonus rather than asserting a fixed amount.
      final photoChallenge = controller.todaysChallenges.where((c) => c.trackedReason == XpReason.photoAdded);
      final challengeBonus = photoChallenge.isEmpty ? 0 : photoChallenge.first.xpReward;
      expect(
        controller.currentProfile!.xp,
        afterCreate + ProgressionService.xpRewards[XpReason.photoAdded]! + challengeBonus,
      );
    });

    test('rating another profile awards ratingGiven XP', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.currentProfile!.xp;
      final other = _profile().copyWith(id: 'other');

      await controller.submitRating(other, 4, 5);

      expect(controller.currentProfile!.xp, before + ProgressionService.xpRewards[XpReason.ratingGiven]!);
    });

    test('editing a profile does not reset previously earned XP', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final earned = controller.currentProfile!.xp;
      expect(earned, greaterThan(0));

      // Simulate an edit that preserves xp the way ProfileWizardScreen does.
      final edited = controller.currentProfile!.copyWith(bio: 'Updated bio');
      await controller.updateProfile(edited, xpReason: XpReason.profileUpdated);

      // On days where "Update your profile" happens to be in today's
      // challenge rotation, this single edit also completes it —
      // account for that date-dependent bonus rather than asserting a
      // fixed amount.
      final updateChallenge = controller.todaysChallenges.where((c) => c.trackedReason == XpReason.profileUpdated);
      final challengeBonus = updateChallenge.isEmpty ? 0 : updateChallenge.first.xpReward;
      expect(
        controller.currentProfile!.xp,
        earned + ProgressionService.xpRewards[XpReason.profileUpdated]! + challengeBonus,
      );
    });

    test('enough XP actions level the player up past level 1', () async {
      await setUpController();
      await controller.createProfile(_profile());
      for (var i = 0; i < 10; i++) {
        await controller.submitRating(_profile().copyWith(id: 'other_$i'), 4, 4);
      }

      expect(controller.levelInfo.level, greaterThan(1));
      expect(controller.levelInfo.totalXp, controller.currentProfile!.xp);
    });

    test('XP transactions persist through the progression repository', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.addPhoto(ImageSource.gallery);

      // profileCompleted + first_steps achievement bonus + photoAdded,
      // plus (only on days where "Add a photo" happens to be in today's
      // 3-challenge rotation) one dailyChallengeCompleted bonus — the
      // rotation is date-dependent, so assert on the reasons that must
      // always be present rather than a day-dependent exact count.
      final reasons = progressionRepository.stored.map((tx) => tx.reason).toList();
      expect(reasons, containsAll([XpReason.profileCompleted, XpReason.achievementUnlocked, XpReason.photoAdded]));
      expect(progressionRepository.stored.length, anyOf(3, 4));
      expect(profileRepository.saved!.xp, controller.currentProfile!.xp);
    });
  });

  group('Achievement unlocking via AppController', () {
    test('creating a profile unlocks and queues First Steps exactly once', () async {
      await setUpController();
      await controller.createProfile(_profile());

      expect(controller.unlockedAchievementIds, {'first_steps'});
      expect(controller.achievementQueue.map((a) => a.id), ['first_steps']);
      expect(achievementRepository.stored, hasLength(1));
    });

    test('unlock persists and is never granted twice', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final xpAfterFirst = controller.currentProfile!.xp;

      // Nothing about a second, unrelated edit should re-unlock or
      // re-pay First Steps.
      await controller.updateProfile(controller.currentProfile!.copyWith(bio: 'v2'));

      expect(controller.unlockedAchievementIds.where((id) => id == 'first_steps'), hasLength(1));
      expect(
        controller.xpTransactions.where((tx) => tx.reason == XpReason.achievementUnlocked),
        hasLength(1),
      );
      expect(controller.currentProfile!.xp, xpAfterFirst);
    });

    test('dequeueAchievement removes only the front of the queue', () async {
      await setUpController();
      await controller.createProfile(_profile());
      for (var i = 0; i < 10; i++) {
        await controller.submitRating(_profile().copyWith(id: 'other_$i'), 4, 4);
      }
      expect(controller.achievementQueue.length, greaterThanOrEqualTo(2)); // first_steps + rating_enthusiast

      final queueBefore = controller.achievementQueue.map((a) => a.id).toList();
      controller.dequeueAchievement();

      expect(controller.achievementQueue.map((a) => a.id).toList(), queueBefore.sublist(1));
    });

    test('dequeueAchievement on an empty queue is a safe no-op', () async {
      await setUpController();
      expect(() => controller.dequeueAchievement(), returnsNormally);
      expect(controller.achievementQueue, isEmpty);
    });

    test('rating_enthusiast unlocks after 10 ratings and grants its bonus', () async {
      await setUpController();
      await controller.createProfile(_profile());
      for (var i = 0; i < 10; i++) {
        await controller.submitRating(_profile().copyWith(id: 'other_$i'), 4, 4);
      }

      expect(controller.unlockedAchievementIds, contains('rating_enthusiast'));
    });

    test('photogenic_life unlocks once the gallery reaches 8 photos', () async {
      await setUpController();
      await controller.createProfile(_profile());
      for (var i = 0; i < 8; i++) {
        await controller.addPhoto(ImageSource.gallery);
      }

      expect(controller.unlockedAchievementIds, contains('photogenic_life'));
    });

    test('achievementRecordFor returns the unlock record with a timestamp', () async {
      await setUpController();
      await controller.createProfile(_profile());

      final record = controller.achievementRecordFor('first_steps');
      expect(record, isNotNull);
      expect(record!.profileId, controller.currentProfile!.id);
    });
  });

  group('Coins via AppController', () {
    test('creating a profile earns coins matching profileCompleted', () async {
      await setUpController();
      await controller.createProfile(_profile());

      expect(controller.wallet.balance, RewardService.coinRewards[XpReason.profileCompleted]);
      expect(controller.wallet.transactions, hasLength(1));
    });

    test('wallet balance accumulates across actions and matches the profile balance', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.submitRating(_profile().copyWith(id: 'other'), 4, 4);

      final expected = RewardService.coinRewards[XpReason.profileCompleted]! + RewardService.coinRewards[XpReason.ratingGiven]!;
      expect(controller.wallet.balance, expected);
      expect(controller.currentProfile!.coins, expected);
    });

    test('coin transactions persist through the coin repository', () async {
      await setUpController();
      await controller.createProfile(_profile());

      expect(coinRepository.stored, hasLength(1));
      expect(coinRepository.stored.single.reason, XpReason.profileCompleted);
    });
  });

  group('Ratings via AppController', () {
    // A double-tap on Discover's "love" button (or any other double-call)
    // used to fire two overlapping submitRating calls for the same
    // profile before the first one's local `ratings` update landed,
    // racing two writes against the same Firestore rating document.
    test('a double-tap only submits one rating for the same profile', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final target = _profile().copyWith(id: 'other');

      final first = controller.submitRating(target, 5, 5);
      final second = controller.submitRating(target, 5, 5);
      await Future.wait([first, second]);

      expect(ratingRepository.stored, hasLength(1));
      expect(controller.wallet.balance, RewardService.coinRewards[XpReason.profileCompleted]! + RewardService.coinRewards[XpReason.ratingGiven]!);
    });
  });

  group('Nuke via AppController', () {
    test('nuking a profile spends attackCost coins, damages a random attribute, and logs sent history', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(coins: 6000));
      final target = _profile().copyWith(id: 'other', displayName: 'Rival');

      await controller.nukeProfile(target);

      expect(controller.wallet.balance, 6000 - NukeService.attackCost);
      expect(controller.nukeHistory, hasLength(1));
      final event = controller.nukeHistory.single;
      expect(event.targetId, 'other');
      expect(event.damage, -NukeService.damagePerNuke);
      expect(NukeService.attributes, contains(event.attribute));
      expect(nukeRepository.stored, hasLength(1));
    });

    test('refuses to nuke your own profile', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(coins: 6000));

      await controller.nukeProfile(controller.currentProfile!);

      expect(controller.wallet.balance, 6000);
      expect(controller.nukeHistory, isEmpty);
      expect(controller.toast, isNotNull);
    });

    test('refuses to nuke a blocked profile', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(coins: 6000));
      final target = _profile().copyWith(id: 'blocked_user');
      await controller.blockUserId(target.id);

      await controller.nukeProfile(target);

      expect(controller.wallet.balance, 6000);
      expect(controller.nukeHistory, isEmpty);
    });

    test('refuses to nuke without enough coins', () async {
      await setUpController();
      await controller.createProfile(_profile());
      // createProfile only grants the small profileCompleted coin reward — nowhere near attackCost.
      final target = _profile().copyWith(id: 'other');

      await controller.nukeProfile(target);

      expect(controller.nukeHistory, isEmpty);
      expect(controller.toast, isNotNull);
    });

    // A double-tap (or any other double-call) used to let two overlapping
    // nukeProfile calls both pass the synchronous balance check against
    // the same stale balance before either one's coin deduction landed —
    // spending more coins than the wallet actually had.
    test('a double-tap only spends attackCost once, even with balance for two', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(
          controller.currentProfile!.copyWith(coins: NukeService.attackCost * 2));
      final target = _profile().copyWith(id: 'other');

      final first = controller.nukeProfile(target);
      final second = controller.nukeProfile(target);
      await Future.wait([first, second]);

      expect(controller.nukeHistory, hasLength(1));
      expect(controller.wallet.balance, NukeService.attackCost * 2 - NukeService.attackCost);
    });
  });

  group('Cure via AppController', () {
    test('curing a damaged attribute spends curePotionCost coins and heals healPerPotion points', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(
        coins: 6000,
        nukeDamage: const {'career': -5},
      ));

      await controller.cureDamage('career');

      expect(controller.wallet.balance, 6000 - NukeService.curePotionCost);
      expect(controller.currentProfile!.nukeDamage['career'], -5 + NukeService.healPerPotion);
    });

    test('a cure never heals an attribute above 0 damage', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(
        coins: 6000,
        nukeDamage: const {'career': -2},
      ));

      await controller.cureDamage('career');

      expect(controller.currentProfile!.nukeDamage['career'], 0);
    });

    test('refuses to cure without enough coins', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(nukeDamage: const {'career': -5}));

      await controller.cureDamage('career');

      expect(controller.currentProfile!.nukeDamage['career'], -5);
      expect(controller.toast, isNotNull);
    });

    // Same double-tap race class as nukeProfile above — both spend from
    // the same shared coin balance, so the guard is shared between them.
    test('a double-tap only spends curePotionCost once, even with balance for two', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.updateProfile(controller.currentProfile!.copyWith(
        coins: NukeService.curePotionCost * 2,
        nukeDamage: const {'career': -5},
      ));

      final first = controller.cureDamage('career');
      final second = controller.cureDamage('career');
      await Future.wait([first, second]);

      expect(controller.wallet.balance, NukeService.curePotionCost * 2 - NukeService.curePotionCost);
      expect(controller.currentProfile!.nukeDamage['career'], -5 + NukeService.healPerPotion);
    });
  });

  group('Rewarded ads via AppController', () {
    test('watching a rewarded ad to completion grants coins and reports success', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.wallet.balance;

      final earned = await controller.watchRewardedAd();

      expect(earned, isTrue);
      expect(adRepository.showCalls, 1);
      expect(controller.wallet.balance, before + RewardService.coinRewards[XpReason.adWatched]!);
      expect(controller.wallet.transactions.last.reason, XpReason.adWatched);
    });

    test('an ad that fails to load or is closed early grants no coins and reports failure', () async {
      await setUpController();
      await controller.createProfile(_profile());
      adRepository.rewardOnShow = false;
      final before = controller.wallet.balance;

      final earned = await controller.watchRewardedAd();

      expect(earned, isFalse);
      expect(adRepository.showCalls, 1);
      expect(controller.wallet.balance, before);
    });

    // A double-tap (or any other double-call) on "Watch Ad" used to be
    // able to fire two overlapping ad shows, each independently granting
    // coins for what was really only one ad watch.
    test('a double-tap only shows and rewards the ad once', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.wallet.balance;

      final first = controller.watchRewardedAd();
      final second = controller.watchRewardedAd();
      final results = await Future.wait([first, second]);

      expect(adRepository.showCalls, 1);
      expect(results, containsAll([true, false]));
      expect(controller.wallet.balance, before + RewardService.coinRewards[XpReason.adWatched]!);
    });
  });

  group('Coin purchases via AppController', () {
    ProductDetails product(String id) => ProductDetails(
          id: id,
          title: 'Coins',
          description: 'Coins',
          price: r'$0.99',
          rawPrice: 0.99,
          currencyCode: 'USD',
        );

    PurchaseDetails purchase(String id, PurchaseStatus status) {
      final details = PurchaseDetails(
        productID: id,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: null,
        status: status,
      );
      details.pendingCompletePurchase = true;
      if (status == PurchaseStatus.error) {
        details.error = IAPError(source: 'test', code: 'boom', message: 'Something went wrong.');
      }
      return details;
    }

    test('a purchased product grants the mapped coin amount and completes the purchase', () async {
      await setUpController();
      await controller.createProfile(_profile());
      purchaseRepository.available = true;
      purchaseRepository.products = [product(PurchaseConfig.coins500)];
      // Re-run the product query the way _load() would on a fresh launch.
      controller.purchaseProducts = await purchaseRepository.queryProducts(PurchaseConfig.allProductIds.toSet());
      final before = controller.wallet.balance;

      purchaseRepository.push([purchase(PurchaseConfig.coins500, PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.wallet.balance, before + PurchaseConfig.coinsForProduct[PurchaseConfig.coins500]!);
      expect(controller.wallet.transactions.last.reason, XpReason.coinsPurchased);
    });

    test('a restored purchase also grants coins', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.wallet.balance;

      purchaseRepository.push([purchase(PurchaseConfig.coins1200, PurchaseStatus.restored)]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.wallet.balance, before + PurchaseConfig.coinsForProduct[PurchaseConfig.coins1200]!);
    });

    test('a canceled purchase grants nothing and shows no error', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.wallet.balance;

      purchaseRepository.push([purchase(PurchaseConfig.coins500, PurchaseStatus.canceled)]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.wallet.balance, before);
    });

    test('an errored purchase grants nothing and surfaces the error', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.wallet.balance;

      purchaseRepository.push([purchase(PurchaseConfig.coins500, PurchaseStatus.error)]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.wallet.balance, before);
      expect(controller.toast, isNotNull);
    });

    test('purchaseCoins on a product not yet available shows an explanatory toast', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final before = controller.wallet.balance;

      await controller.purchaseCoins(PurchaseConfig.coins500);

      expect(purchaseRepository.bought, isEmpty);
      expect(controller.wallet.balance, before);
      expect(controller.toast, isNotNull);
    });

    test('purchaseCoins on an available product starts the real purchase flow', () async {
      await setUpController();
      await controller.createProfile(_profile());
      purchaseRepository.available = true;
      purchaseRepository.products = [product(PurchaseConfig.coins2500)];
      controller.purchaseProducts = await purchaseRepository.queryProducts(PurchaseConfig.allProductIds.toSet());

      await controller.purchaseCoins(PurchaseConfig.coins2500);

      expect(purchaseRepository.bought.single.id, PurchaseConfig.coins2500);
    });
  });

  group('Interstitial ads via AppController', () {
    test('the 30th action shows an interstitial, not before or after', () async {
      await setUpController();
      // Profile creation itself is action #1 (it goes through the same
      // _checkAchievements() checkpoint as everything else below).
      await controller.createProfile(_profile());

      for (var i = 0; i < 28; i++) {
        await controller.submitRating(_profile().copyWith(id: 'other$i'), 4, 4);
      }
      expect(adRepository.interstitialCalls, 0);

      await controller.submitRating(_profile().copyWith(id: 'other28'), 4, 4);
      expect(adRepository.interstitialCalls, 1);

      await controller.submitRating(_profile().copyWith(id: 'other29'), 4, 4);
      expect(adRepository.interstitialCalls, 1);
    });
  });

  group('Daily challenges via AppController', () {
    // Today's 3-challenge rotation is date-based (see DailyChallengeService),
    // so a hardcoded reason (e.g. always "rate a profile") would be flaky
    // depending on which day the suite runs. This performs whatever real
    // action matches a given challenge's tracked reason instead.
    Future<void> performAction(XpReason reason, int index) async {
      switch (reason) {
        case XpReason.ratingGiven:
          await controller.submitRating(_profile().copyWith(id: 'other_$index'), 4, 4);
        case XpReason.photoAdded:
          await controller.addPhoto(ImageSource.gallery);
        case XpReason.profileUpdated:
          await controller.updateProfile(controller.currentProfile!.copyWith(bio: 'v$index'), xpReason: XpReason.profileUpdated);
        case XpReason.profileShared:
          await controller.awardProfileSharedXp();
        case XpReason.battleVoted:
          // A fresh battle each call — unlike the other reasons above,
          // the same battle can't be voted on twice, but a *different*
          // battle always can, so this is still a genuinely repeatable
          // action.
          final battle = Battle(id: 'battle_$index', profileAId: 'a_$index', profileBId: 'b_$index', type: BattleType.random, createdAt: DateTime.now());
          await controller.voteBattle(battle, battle.profileAId);
        case XpReason.choiceMade:
          await controller.submitChoice(ChoiceOption.a);
        default:
          fail('unexpected trackedReason: $reason');
      }
    }

    test('completing a tracked challenge grants its bonus exactly once', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final challenge = controller.todaysChallenges.first;

      for (var i = 0; i < challenge.targetCount; i++) {
        await performAction(challenge.trackedReason, i);
      }
      expect(controller.isChallengeClaimedToday(challenge.id), isTrue);
      final xpAfterCompletion = controller.currentProfile!.xp;
      final claimsAfterCompletion = challengeRepository.stored.length;

      if (challenge.trackedReason == XpReason.choiceMade) {
        // Choice is answered once, ever — a "repeat" is a guaranteed
        // no-op (see submitChoice), so there's nothing further to grant
        // or claim, unlike every other repeatable tracked reason below.
        await performAction(challenge.trackedReason, 999);
        expect(challengeRepository.stored.length, claimsAfterCompletion);
        expect(controller.currentProfile!.xp, xpAfterCompletion);
        return;
      }

      // One more matching action must not re-grant the same challenge's reward.
      await performAction(challenge.trackedReason, 999);

      expect(challengeRepository.stored.length, claimsAfterCompletion);
      expect(
        controller.currentProfile!.xp,
        xpAfterCompletion + ProgressionService.xpRewards[challenge.trackedReason]!,
      );
    });

    test('challengeProgress reflects real activity for the day', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final challenge = controller.todaysChallenges.first;

      expect(controller.challengeProgress(challenge), 0);
      await performAction(challenge.trackedReason, 0);
      expect(controller.challengeProgress(challenge), 1);
    });

    test('todaysChallenges always returns exactly 3 challenges', () async {
      await setUpController();
      expect(controller.todaysChallenges, hasLength(3));
    });
  });

  group('Streaks via AppController', () {
    test('with no prior activity, only today\'s new action gives a 1-day streak', () async {
      await setUpController();
      await controller.createProfile(_profile());

      expect(controller.currentStreakDays, 1);
    });

    test('activity on prior days plus opening the app today builds a multi-day streak', () async {
      final today = DateTime.now();
      final dayOnly = DateTime(today.year, today.month, today.day);
      final seededProfile = _profile(xp: 30);

      progressionRepository = _FakeProgressionRepository()
        ..stored = [
          XpTransaction(id: 'd2', profileId: seededProfile.id, amount: 15, reason: XpReason.ratingGiven, createdAt: dayOnly.subtract(const Duration(days: 2))),
          XpTransaction(id: 'd1', profileId: seededProfile.id, amount: 15, reason: XpReason.ratingGiven, createdAt: dayOnly.subtract(const Duration(days: 1))),
        ];
      appOpenRepository = _FakeAppOpenRepository();
      profileRepository = _FakeProfileRepository()..existing = seededProfile;
      achievementRepository = _FakeAchievementRepository();
      coinRepository = _FakeCoinRepository();
      challengeRepository = _FakeChallengeRepository();
      commentRepository = _FakeCommentRepository();
      commentReactionRepository = _FakeCommentReactionRepository();
      battleRepository = _FakeBattleRepository();
      battleVoteRepository = _FakeBattleVoteRepository();
      final repos = RepositoryBundle(
        profileRepository: profileRepository,
        ratingRepository: _FakeRatingRepository(),
        settingsRepository: _FakeSettingsRepository(),
        progressionRepository: progressionRepository,
        appOpenRepository: appOpenRepository,
        achievementRepository: achievementRepository,
        coinRepository: coinRepository,
        challengeRepository: challengeRepository,
        cosmeticRepository: _FakeCosmeticRepository(),
        photoVoteRepository: _FakePhotoVoteRepository(),
        nukeRepository: _FakeNukeRepository(),
        purchaseRepository: _FakePurchaseRepository(),
        notificationRepository: _FakeNotificationRepository(),
        messageRepository: _FakeMessageRepository(),
        callRepository: _FakeCallRepository(),
        commentRepository: commentRepository,
        commentReactionRepository: commentReactionRepository,
        battleRepository: battleRepository,
        battleVoteRepository: battleVoteRepository,
        choiceRepository: _FakeChoiceRepository(),
        photoRepository: _FakePhotoRepository(),
      );
      container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(repos)]);
      controller = container.read(appControllerProvider);
      await Future<void>.delayed(Duration.zero);

      // _load() should have picked up the seeded profile as currentProfile.
      expect(controller.currentProfile, isNotNull);
      // Simply opening the app today (no rating/photo/etc. yet) already
      // extends what would otherwise be a 2-day streak (yesterday + the
      // day before) to 3 — showing up counts on its own, like a
      // Duolingo/Snapchat streak, not just earning XP.
      expect(controller.currentStreakDays, 3);
      expect(appOpenRepository.stored, contains(dayOnly));

      // A real action today doesn't double-count the day that opening
      // the app already claimed.
      await controller.submitRating(_profile().copyWith(id: 'someone_else'), 4, 4);
      expect(controller.currentStreakDays, 3);
    });

    test('opening the app with zero prior XP activity still starts a 1-day streak', () async {
      await setUpController();
      final today = DateTime.now();
      final dayOnly = DateTime(today.year, today.month, today.day);

      expect(controller.currentStreakDays, 1);
      expect(appOpenRepository.stored, {dayOnly});
    });
  });

  group('What Would You Choose via AppController', () {
    test('todaysChoice matches ChoiceService\'s own deterministic pick', () async {
      await setUpController();

      expect(controller.todaysChoice.id, const ChoiceService().choiceFor(DateTime.now()).id);
    });

    test('submitChoice records a vote, grants a reward, and populates the tally', () async {
      await setUpController();
      await controller.createProfile(_profile());
      expect(controller.myChoiceVoteToday, isNull);

      await controller.submitChoice(ChoiceOption.a);

      expect(controller.myChoiceVoteToday?.chosenOption, ChoiceOption.a);
      expect(controller.todaysChoiceTally, (countA: 1, countB: 0));
      expect(controller.currentProfile!.xp, greaterThan(0));
      expect(choiceRepository.stored, hasLength(1));
    });

    test('submitChoice is a no-op once already voted today', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.submitChoice(ChoiceOption.a);
      final xpAfterFirstVote = controller.currentProfile!.xp;

      await controller.submitChoice(ChoiceOption.b);

      expect(controller.myChoiceVoteToday?.chosenOption, ChoiceOption.a);
      expect(controller.currentProfile!.xp, xpAfterFirstVote);
      expect(choiceRepository.stored, hasLength(1));
    });

    test('the tally counts every voter, not just this device', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final questionId = controller.todaysChoice.id;
      choiceRepository.stored = [
        ChoiceVote(id: 'p1_$questionId', questionId: questionId, voterId: 'p1', chosenOption: ChoiceOption.a, createdAt: DateTime.now()),
        ChoiceVote(id: 'p2_$questionId', questionId: questionId, voterId: 'p2', chosenOption: ChoiceOption.b, createdAt: DateTime.now()),
      ];

      await controller.submitChoice(ChoiceOption.a);

      expect(controller.todaysChoiceTally, (countA: 2, countB: 1));
    });
  });

  group('Percentiles via AppController', () {
    // `createProfile` always recalculates `score` from raw life data
    // (see `ProfileService.recalculate`), so these tests never assume
    // a specific score for 'me' — sentinel-low/-high comparison-pool
    // values (which are NOT recalculated, since mock profiles load
    // as-is) guarantee the expected ordering regardless of whatever
    // real score 'me' actually computes to.
    test('overallPercentile reflects the real share of known profiles scoring lower', () async {
      await setUpController(mockProfiles: [
        _otherProfile(id: 'sentinel_low', score: -1000),
        _otherProfile(id: 'sentinel_high', score: 1000),
      ]);
      await controller.createProfile(_otherProfile(id: 'me').copyWith(isCurrentUser: true));

      expect(controller.overallPercentile, 50);
    });

    test('overallPercentile defaults to 50 with no comparison pool at all', () async {
      await setUpController();
      await controller.createProfile(_otherProfile(id: 'me').copyWith(isCurrentUser: true));

      expect(controller.overallPercentile, 50);
    });

    test('agePercentile only compares against profiles within 5 years', () async {
      await setUpController(mockProfiles: [_otherProfile(id: 'near', age: 26, score: -1000)]);
      await controller.createProfile(_otherProfile(id: 'me', age: 24).copyWith(isCurrentUser: true));

      expect(controller.agePercentile, 99);
    });

    test('agePercentile excludes profiles outside the age window entirely', () async {
      await setUpController(mockProfiles: [_otherProfile(id: 'far', age: 60, score: 1000)]);
      await controller.createProfile(_otherProfile(id: 'me', age: 24).copyWith(isCurrentUser: true));

      // The only known other profile is outside the +/-5-year window,
      // so the age-scoped pool is empty -> the honest default (50),
      // not dragged down by a sentinel-high profile that shouldn't count.
      expect(controller.agePercentile, 50);
    });

    test('countryPercentile only compares against profiles in the same country', () async {
      await setUpController(mockProfiles: [_otherProfile(id: 'other_country', country: 'France', score: 1000)]);
      await controller.createProfile(_otherProfile(id: 'me', country: 'Morocco').copyWith(isCurrentUser: true));

      expect(controller.countryPercentile, 50);
    });

    test('categoryPercentile compares one specific category, not the overall score', () async {
      final careerStar = _otherProfile(id: 'career_star').copyWith(
        score: LifeScore(
          overall: -1000,
          career: 1000,
          financial: -1000,
          education: -1000,
          independence: -1000,
          social: -1000,
          lifestyle: -1000,
          wellbeing: -1000,
          explanations: const {},
          calculatedAt: DateTime(2026),
        ),
      );
      await setUpController(mockProfiles: [careerStar]);
      await controller.createProfile(_otherProfile(id: 'me').copyWith(isCurrentUser: true));

      // Overall: 'me' beats the sentinel-low overall -> high percentile.
      expect(controller.overallPercentile, 99);
      // Career specifically: 'me' is below the sentinel-high career
      // value -> low percentile, proving this looks at that one
      // category's numbers, not the overall score.
      expect(controller.categoryPercentile('Career'), 1);
    });
  });

  group('Cosmetic frames via AppController', () {
    test('purchaseFrame deducts coins and unlocks the frame when affordable', () async {
      await setUpController();
      await controller.createProfile(_profile().copyWith(coins: 200));
      final balanceBeforePurchase = controller.wallet.balance;

      await controller.purchaseFrame('gold');

      expect(controller.ownedFrameIds, contains('gold'));
      expect(controller.wallet.balance, balanceBeforePurchase - 150);
      expect(cosmeticRepository.stored.single.cosmeticId, 'gold');
    });

    test('purchaseFrame refuses when the balance is too low, and spends nothing', () async {
      await setUpController();
      // Even with the profileCompleted creation bonus on top, this stays
      // well under the 150-coin cost of a real frame.
      await controller.createProfile(_profile().copyWith(coins: 10));
      final balanceBeforePurchase = controller.wallet.balance;

      await controller.purchaseFrame('gold');

      expect(controller.ownedFrameIds, isNot(contains('gold')));
      expect(controller.wallet.balance, balanceBeforePurchase);
      expect(cosmeticRepository.stored, isEmpty);
    });

    test('purchaseFrame refuses a frame already owned, without spending again', () async {
      await setUpController();
      await controller.createProfile(_profile().copyWith(coins: 500));
      await controller.purchaseFrame('gold');
      final balanceAfterFirstPurchase = controller.wallet.balance;

      await controller.purchaseFrame('gold');

      expect(controller.wallet.balance, balanceAfterFirstPurchase);
      expect(cosmeticRepository.stored, hasLength(1));
    });

    test('equipFrame is a no-op for a frame that is not owned', () async {
      await setUpController();
      await controller.createProfile(_profile().copyWith(coins: 200));

      await controller.equipFrame('gold');

      expect(controller.currentProfile?.equippedFrameId, isNot('gold'));
    });

    test('equipFrame sets equippedFrameId once the frame is owned', () async {
      await setUpController();
      await controller.createProfile(_profile().copyWith(coins: 200));
      await controller.purchaseFrame('gold');

      await controller.equipFrame('gold');

      expect(controller.currentProfile?.equippedFrameId, 'gold');
      expect(profileRepository.saved?.equippedFrameId, 'gold');
    });
  });

  group('Biggest Gaps via AppController', () {
    test('biggestGapProfiles excludes profiles below the minimum rating count', () async {
      final tooFew = _otherProfile(id: 'too_few', score: 90).copyWith(
        ratingSummary: const RatingSummary(averageOverall: 1, count: 1),
      );
      await setUpController(mockProfiles: [tooFew]);
      await controller.createProfile(_profile().copyWith(isCurrentUser: true));

      expect(controller.biggestGapProfiles, isEmpty);
    });

    test('biggestGapProfiles sorts the biggest algorithm/community disagreement first', () async {
      final bigGap = _otherProfile(id: 'big_gap', score: 90).copyWith(
        ratingSummary: const RatingSummary(averageOverall: 1, count: 5), // community 20, gap 70
      );
      final smallGap = _otherProfile(id: 'small_gap', score: 50).copyWith(
        ratingSummary: const RatingSummary(averageOverall: 2.5, count: 5), // community 50, gap 0
      );
      await setUpController(mockProfiles: [smallGap, bigGap]);
      await controller.createProfile(_profile().copyWith(isCurrentUser: true));
      await controller.loadMoreGap();

      expect(controller.biggestGapProfiles.map((p) => p.id), ['big_gap', 'small_gap']);
      expect(controller.gapFor(bigGap), 70);
    });

    test('communityScoreOf rescales the 0-5 average onto the algorithm\'s 0-100 scale', () async {
      await setUpController();
      await controller.createProfile(_profile());

      expect(controller.communityScoreOf(const RatingSummary(averageOverall: 4, count: 10)), 80);
    });
  });

  group('Photo quality via AppController', () {
    final photo = ProfilePhoto(id: 'p1', ownerId: 'me', path: 'mock://irrelevant', order: 0, createdAt: DateTime(2026));

    test('returns null when the repository can\'t read the photo\'s bytes back', () async {
      await setUpController();
      await controller.createProfile(_profile());
      photoRepository.bytesToReturn = null;

      expect(await controller.analyzePhotoQuality(photo), isNull);
    });

    test('analyzes real image bytes into a bounded score', () async {
      await setUpController();
      await controller.createProfile(_profile());
      final image = img.Image(width: 400, height: 400);
      img.fill(image, color: img.ColorRgb8(150, 150, 150));
      photoRepository.bytesToReturn = Uint8List.fromList(img.encodePng(image));

      final result = await controller.analyzePhotoQuality(photo);

      expect(result, isNotNull);
      expect(result!.score, inInclusiveRange(0, 100));
      expect(result.tip, isNotEmpty);
    });
  });

  group('Photo categories via AppController', () {
    test('addPhoto tags the new photo with the chosen category', () async {
      await setUpController();
      await controller.createProfile(_profile());

      await controller.addPhoto(ImageSource.gallery, category: 'Car');

      expect(controller.currentProfile!.photos.single.category, 'Car');
    });

    test('setPhotoCategory recategorizes an existing photo without touching others', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.addPhoto(ImageSource.gallery, category: 'Lifestyle');
      await controller.addPhoto(ImageSource.gallery, category: 'Lifestyle');
      final photos = controller.currentProfile!.photos;

      await controller.setPhotoCategory(photos.last.id, 'Travel');

      final updated = controller.currentProfile!.photos;
      expect(updated.firstWhere((p) => p.id == photos.first.id).category, 'Lifestyle');
      expect(updated.firstWhere((p) => p.id == photos.last.id).category, 'Travel');
    });
  });

  group('Best-photo voting via AppController', () {
    test('voteForBestPhoto records this device\'s pick', () async {
      await setUpController();
      await controller.createProfile(_profile());

      await controller.voteForBestPhoto('them', 'p1');

      expect(controller.myBestPhotoVoteFor('them'), 'p1');
      expect(photoVoteRepository.stored.single.photoId, 'p1');
    });

    test('voting again moves the same vote to a different photo instead of adding a second one', () async {
      await setUpController();
      await controller.createProfile(_profile());
      await controller.voteForBestPhoto('them', 'p1');

      await controller.voteForBestPhoto('them', 'p2');

      expect(controller.myBestPhotoVoteFor('them'), 'p2');
      expect(photoVoteRepository.stored, hasLength(1));
    });

    test('votes for different profiles do not interfere with each other', () async {
      await setUpController();
      await controller.createProfile(_profile());

      await controller.voteForBestPhoto('alice', 'a1');
      await controller.voteForBestPhoto('bob', 'b1');

      expect(controller.myBestPhotoVoteFor('alice'), 'a1');
      expect(controller.myBestPhotoVoteFor('bob'), 'b1');
    });

    test('voting on your own profile is refused, not silently recorded', () async {
      await setUpController();
      await controller.createProfile(_profile());

      await controller.voteForBestPhoto('me', 'p1');

      expect(controller.myBestPhotoVoteFor('me'), isNull);
      expect(photoVoteRepository.stored, isEmpty);
    });

    test('myBestPhotoVoteFor is null before any vote is cast', () async {
      await setUpController();
      await controller.createProfile(_profile());

      expect(controller.myBestPhotoVoteFor('them'), isNull);
    });
  });

  group('Trending profiles via AppController', () {
    test('excludes profiles created outside the recency window', () async {
      final now = DateTime.now();
      final fresh = _otherProfile(id: 'fresh').copyWith(createdAt: now.subtract(const Duration(days: 1)), viewCount: 10);
      final old = _otherProfile(id: 'old').copyWith(createdAt: now.subtract(const Duration(days: 60)), viewCount: 1000);
      await setUpController(mockProfiles: [fresh, old]);
      await controller.createProfile(_profile());
      await controller.loadMoreTrending();

      expect(controller.trendingProfiles.map((p) => p.id), ['fresh']);
    });

    test('ranks recent profiles by real engagement, highest first', () async {
      final now = DateTime.now();
      final quiet = _otherProfile(id: 'quiet').copyWith(createdAt: now, viewCount: 2);
      final active = _otherProfile(id: 'active').copyWith(createdAt: now, viewCount: 5, ratingSummary: const RatingSummary(averageOverall: 4, count: 10));
      await setUpController(mockProfiles: [quiet, active]);
      await controller.createProfile(_profile());
      await controller.loadMoreTrending();

      expect(controller.trendingProfiles.map((p) => p.id), ['active', 'quiet']);
    });
  });

  group('Notifications via AppController', () {
    test('_load schedules the daily reminder when notifications start enabled', () async {
      await setUpController();

      expect(notificationRepository.scheduled, isTrue);
      expect(notificationRepository.scheduleCalls, 1);
    });

    test('turning notifications off cancels the reminder', () async {
      await setUpController();

      await controller.updateSettings(controller.settings.copyWith(notifications: false));

      expect(notificationRepository.scheduled, isFalse);
      expect(notificationRepository.cancelCalls, 1);
      expect(controller.settings.notifications, isFalse);
    });

    test('turning notifications back on requests permission and reschedules', () async {
      await setUpController();
      await controller.updateSettings(controller.settings.copyWith(notifications: false));

      await controller.updateSettings(controller.settings.copyWith(notifications: true));

      expect(notificationRepository.scheduled, isTrue);
      expect(controller.settings.notifications, isTrue);
    });

    test('a denied permission reverts the toggle instead of pretending it\'s on', () async {
      await setUpController();
      await controller.updateSettings(controller.settings.copyWith(notifications: false));
      notificationRepository.permissionGranted = false;

      await controller.updateSettings(controller.settings.copyWith(notifications: true));

      expect(controller.settings.notifications, isFalse);
      expect(notificationRepository.scheduled, isFalse);
    });

    test('toggling an unrelated setting does not touch notifications', () async {
      await setUpController();
      final callsBefore = notificationRepository.scheduleCalls;

      await controller.updateSettings(controller.settings.copyWith(sound: false));

      expect(notificationRepository.scheduleCalls, callsBefore);
      expect(notificationRepository.cancelCalls, 0);
    });

    test('_load also registers this device for push notifications when notifications start enabled', () async {
      await setUpController();

      expect(pushNotificationRepository.registerCalls, 1);
    });

    test('turning notifications off unregisters this device from push, not just the local reminder', () async {
      await setUpController();

      await controller.updateSettings(controller.settings.copyWith(notifications: false));

      expect(pushNotificationRepository.unregisterCalls, 1);
    });

    test('turning notifications back on re-registers this device for push', () async {
      await setUpController();
      await controller.updateSettings(controller.settings.copyWith(notifications: false));

      await controller.updateSettings(controller.settings.copyWith(notifications: true));

      // Once from _load(), once from re-enabling.
      expect(pushNotificationRepository.registerCalls, 2);
    });

    test('a message arriving in the foreground shows a local notification with its title/body', () async {
      await setUpController();

      pushNotificationRepository.push(const RemoteMessage(notification: RemoteNotification(title: 'Nova', body: 'Sent you a message')));
      await Future<void>.delayed(Duration.zero);

      expect(notificationRepository.shownNotifications, [(title: 'Nova', body: 'Sent you a message', payload: null)]);
    });

    test('a foreground message with no notification payload is ignored, not shown blank', () async {
      await setUpController();

      pushNotificationRepository.push(const RemoteMessage(data: {'type': 'silent'}));
      await Future<void>.delayed(Duration.zero);

      expect(notificationRepository.shownNotifications, isEmpty);
    });

    test('a foreground message payload encodes the sender for tap-to-navigate', () async {
      await setUpController();

      pushNotificationRepository.push(const RemoteMessage(
        notification: RemoteNotification(title: 'Nova', body: 'Sent you a message'),
        data: {'type': 'message', 'otherUserId': 'nova_uid'},
      ));
      await Future<void>.delayed(Duration.zero);

      expect(notificationRepository.shownNotifications.single.payload, 'message:nova_uid');
    });

    test('tapping a foreground notification sets pendingConversationOpen', () async {
      await setUpController();

      notificationRepository.tapNotification('message:nova_uid');
      await Future<void>.delayed(Duration.zero);

      expect(controller.pendingConversationOpen, 'nova_uid');
    });

    test('tapping a daily-reminder notification (no message: prefix) does not navigate', () async {
      await setUpController();

      notificationRepository.tapNotification('some_other_payload');
      await Future<void>.delayed(Duration.zero);

      expect(controller.pendingConversationOpen, isNull);
    });

    test('tapping a background-delivered message notification sets pendingConversationOpen', () async {
      await setUpController();

      pushNotificationRepository.openFromBackground(const RemoteMessage(data: {'type': 'message', 'otherUserId': 'nova_uid'}));
      await Future<void>.delayed(Duration.zero);

      expect(controller.pendingConversationOpen, 'nova_uid');
    });

    test('a call notification tap never sets pendingConversationOpen', () async {
      await setUpController();

      pushNotificationRepository.openFromBackground(const RemoteMessage(data: {'type': 'call', 'callId': 'call1'}));
      await Future<void>.delayed(Duration.zero);

      expect(controller.pendingConversationOpen, isNull);
    });

    test('clearPendingConversationOpen resets it back to null', () async {
      await setUpController();
      notificationRepository.tapNotification('message:nova_uid');
      await Future<void>.delayed(Duration.zero);
      expect(controller.pendingConversationOpen, 'nova_uid');

      controller.clearPendingConversationOpen();

      expect(controller.pendingConversationOpen, isNull);
    });

    test('a notification that cold-started the app opens the right conversation', () async {
      await setUpController(
        initialPushMessage: const RemoteMessage(data: {'type': 'message', 'otherUserId': 'nova_uid'}),
      );

      expect(controller.pendingConversationOpen, 'nova_uid');
    });
  });

  group('Direct messages via AppController', () {
    test('sending a message adds it to the thread and persists it', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());

      await controller.sendMessage(them, 'hey there');

      expect(controller.conversationWith('them').single.content, 'hey there');
      expect(messageRepository.stored, hasLength(1));
    });

    test('refuses to send to yourself', () async {
      await setUpController();
      await controller.createProfile(_profile());

      await controller.sendMessage(controller.currentProfile!, 'hi me');

      expect(messageRepository.stored, isEmpty);
    });

    test('refuses to send when the recipient turned messages off', () async {
      final them = _otherProfile(id: 'them').copyWith(privacy: const ProfilePrivacy(allowMessages: false));
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());

      await controller.sendMessage(them, 'hey');

      expect(messageRepository.stored, isEmpty);
    });

    test('a blocked user cannot be messaged, and their thread disappears', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      await controller.sendMessage(them, 'hey');
      expect(controller.conversationWith('them'), isNotEmpty);

      await controller.blockUserId('them');

      expect(controller.conversationWith('them'), isEmpty);
      await controller.sendMessage(them, 'still here?');
      expect(messageRepository.stored, hasLength(1)); // only the pre-block message
    });

    test('rate limits a burst of outgoing messages', () async {
      await setUpController(mockProfiles: [for (var i = 0; i < 6; i++) _otherProfile(id: 'p$i')]);
      await controller.createProfile(_profile());

      for (var i = 0; i < 5; i++) {
        await controller.sendMessage(_otherProfile(id: 'p$i'), 'hi $i');
      }
      await controller.sendMessage(_otherProfile(id: 'p5'), 'one too many');

      expect(messageRepository.stored, hasLength(5));
    });

    test('conversations lists the latest message per thread, most recent first', () async {
      final alice = _otherProfile(id: 'alice');
      final bob = _otherProfile(id: 'bob');
      await setUpController(mockProfiles: [alice, bob]);
      await controller.createProfile(_profile());
      final now = DateTime.now();
      // Explicit, distinct timestamps — two real sendMessage() calls can
      // land in the same millisecond and make this ordering flaky.
      controller.messages = [
        Message(id: 'to_alice', conversationId: 'alice_me', senderId: 'me', recipientId: 'alice', content: 'hi alice', createdAt: now),
        Message(id: 'to_bob', conversationId: 'bob_me', senderId: 'me', recipientId: 'bob', content: 'hi bob', createdAt: now.add(const Duration(minutes: 1))),
      ];

      expect(controller.conversations.map((m) => m.recipientId), ['bob', 'alice']);
    });

    test('markConversationRead flips isRead only for messages received from that person', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      final incoming = Message(id: 'in1', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'hi', createdAt: DateTime.now());
      controller.messages = [incoming];
      expect(controller.unreadMessageCount, 1);

      await controller.markConversationRead('them');

      expect(controller.unreadMessageCount, 0);
    });

    test('marks the conversation read immediately, without waiting for the write to finish', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      final incoming = Message(id: 'in1', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'hi', createdAt: DateTime.now());
      controller.messages = [incoming];
      // Regression guard: navigating back out of a conversation used to
      // still show the old unread state if it happened before the
      // Firestore write for markConversationRead came back.
      messageRepository.saveDelay = const Duration(seconds: 30);

      unawaited(controller.markConversationRead('them'));

      expect(controller.unreadMessageCount, 0);
    });

    test('a message can be deleted by its sender, and only its sender', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      await controller.sendMessage(them, 'oops typo');
      final sent = controller.conversationWith('them').single;

      await controller.deleteMessage(sent.id);

      expect(controller.conversationWith('them'), isEmpty);
      expect(messageRepository.stored, isEmpty);
    });

    test('deleteMessage is a no-op for a message you did not send', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      final incoming = Message(id: 'in1', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'hi', createdAt: DateTime.now());
      controller.messages = [incoming];

      await controller.deleteMessage('in1');

      expect(controller.messages, hasLength(1));
    });

    test('reportMessage reports and blocks the sender in one step', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      final incoming = Message(id: 'in1', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'abuse', createdAt: DateTime.now());
      controller.messages = [incoming];

      await controller.reportMessage('in1', ReportReason.harassment);

      expect(controller.blockedIds, contains('them'));
      expect(controller.reports.where((r) => r.targetMessageId == 'in1'), hasLength(1));
    });

    test('deleteConversation removes the thread from this device\'s view but leaves the messages intact', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      await controller.sendMessage(them, 'hey');
      expect(controller.conversationWith('them'), isNotEmpty);
      expect(controller.conversations, isNotEmpty);

      await controller.deleteConversation('them');

      expect(controller.conversationWith('them'), isEmpty);
      expect(controller.conversations, isEmpty);
      // "Delete conversation" only hides it from this device's own
      // view — it doesn't touch the shared message data, unlike
      // deleteMessage.
      expect(messageRepository.stored, hasLength(1));
    });

    test('a message sent after deleting the conversation revives the thread', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      // A comfortably past cutoff — sendMessage's own DateTime.now() call
      // below is guaranteed to land after it, avoiding the millisecond
      // ties two back-to-back DateTime.now() calls can otherwise produce
      // (see the "explicit, distinct timestamps" note elsewhere in this
      // file for the same underlying flakiness).
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      controller.messages = [
        Message(id: 'old', conversationId: 'me_them', senderId: 'me', recipientId: 'them', content: 'first', createdAt: past),
      ];
      controller.hiddenConversations = [
        HiddenConversation(ownerId: controller.currentUserId, otherUserId: 'them', hiddenAt: past.add(const Duration(seconds: 1))),
      ];
      expect(controller.conversationWith('them'), isEmpty);

      await controller.sendMessage(them, 'second, after deleting');

      expect(controller.conversationWith('them').single.content, 'second, after deleting');
      expect(controller.conversations.single.content, 'second, after deleting');
    });
  });

  group('Audio calls via AppController', () {
    test('starting a call requires an existing conversation first', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());

      await controller.startCall(them);

      expect(callRepository.startedCalleeIds, isEmpty);
      expect(controller.toast, contains('Message this person'));
    });

    test('starting a call succeeds once a conversation exists', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      await controller.sendMessage(them, 'hey');

      await controller.startCall(them);

      expect(callRepository.startedCalleeIds, ['them']);
    });

    test('refuses to call yourself', () async {
      await setUpController();
      await controller.createProfile(_profile());

      await controller.startCall(controller.currentProfile!);

      expect(callRepository.startedCalleeIds, isEmpty);
    });

    test('refuses to call someone who turned calls off', () async {
      final them = _otherProfile(id: 'them').copyWith(privacy: const ProfilePrivacy(allowCalls: false));
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      await controller.sendMessage(them, 'hey');

      await controller.startCall(them);

      expect(callRepository.startedCalleeIds, isEmpty);
    });

    test('refuses to call a blocked user', () async {
      final them = _otherProfile(id: 'them');
      await setUpController(mockProfiles: [them]);
      await controller.createProfile(_profile());
      await controller.sendMessage(them, 'hey');
      await controller.blockUserId('them');

      await controller.startCall(them);

      expect(callRepository.startedCalleeIds, isEmpty);
    });
  });
}
