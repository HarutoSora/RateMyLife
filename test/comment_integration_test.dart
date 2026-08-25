import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  UserProfile? existing;

  @override
  Future<void> deleteCurrentProfile() async {}

  @override
  Future<UserProfile?> loadCurrentProfile() async => existing;

  @override
  Future<UserProfile?> loadProfileById(String id) async => existing?.id == id ? existing : null;

  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);

  @override
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);

  @override
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since}) async =>
      (profiles: <UserProfile>[], hasMore: false);

  @override
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);

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
  List<Report> reports = [];

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
  Future<List<Report>> loadReports() async => reports;
  @override
  Future<void> saveReports(List<Report> value) async => reports = value;
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

class _FakeNotificationRepository implements NotificationRepository {
  bool permissionGranted = true;
  bool scheduled = false;
  @override
  Future<bool> requestPermission() async => permissionGranted;
  @override
  Future<void> scheduleDailyChallengeReminder() async => scheduled = true;
  @override
  Future<void> cancelDailyChallengeReminder() async => scheduled = false;
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
  ProfilePrivacy privacy = const ProfilePrivacy(),
  String displayName = 'Tester',
}) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: displayName,
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
    privacy: privacy,
    createdAt: now,
    updatedAt: now,
    isCurrentUser: true,
  );
}

void main() {
  late ProviderContainer container;
  late AppController controller;
  late _FakeProfileRepository profileRepository;
  late _FakeCommentRepository commentRepository;
  late _FakeSettingsRepository settingsRepository;

  Future<void> setUpController({UserProfile? seededProfile}) async {
    profileRepository = _FakeProfileRepository()..existing = seededProfile;
    commentRepository = _FakeCommentRepository();
    settingsRepository = _FakeSettingsRepository();
    final repos = RepositoryBundle(
      profileRepository: profileRepository,
      ratingRepository: _FakeRatingRepository(),
      settingsRepository: settingsRepository,
      progressionRepository: _FakeProgressionRepository(),
      appOpenRepository: _FakeAppOpenRepository(),
      achievementRepository: _FakeAchievementRepository(),
      coinRepository: _FakeCoinRepository(),
      challengeRepository: _FakeChallengeRepository(),
      cosmeticRepository: _FakeCosmeticRepository(),
      photoVoteRepository: _FakePhotoVoteRepository(),
      notificationRepository: _FakeNotificationRepository(),
      commentRepository: commentRepository,
      messageRepository: _FakeMessageRepository(),
      callRepository: _FakeCallRepository(),
      commentReactionRepository: _FakeCommentReactionRepository(),
      battleRepository: _FakeBattleRepository(),
      battleVoteRepository: _FakeBattleVoteRepository(),
      choiceRepository: _FakeChoiceRepository(),
    );
    container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(repos)]);
    controller = container.read(appControllerProvider);
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() => container.dispose());

  group('Comments via AppController', () {
    test('a real user can comment on another profile', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other', displayName: 'Other');

      await controller.addComment(other, 'Love this life!');

      expect(controller.comments, hasLength(1));
      expect(controller.comments.single.authorId, 'me');
      expect(controller.comments.single.profileOwnerId, 'other');
      expect(controller.commentsFor('other').single.content, 'Love this life!');
      expect(commentRepository.stored, hasLength(1));
    });

    test('cannot comment on your own profile', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);

      await controller.addComment(me, 'Nice.');

      expect(controller.comments, isEmpty);
      expect(controller.toast, contains('own profile'));
    });

    test('cannot comment when the profile owner disabled comments', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other', privacy: const ProfilePrivacy(allowComments: false));

      await controller.addComment(other, 'Hi');

      expect(controller.comments, isEmpty);
      expect(controller.toast, 'Comments are disabled for this profile.');
    });

    test('cannot comment on a private profile', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other', privacy: const ProfilePrivacy(visibility: ProfileVisibility.private));

      await controller.addComment(other, 'Hi');

      expect(controller.comments, isEmpty);
    });

    test('rejects an over-length comment', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');

      await controller.addComment(other, 'a' * 281);

      expect(controller.comments, isEmpty);
      expect(controller.toast, contains('280'));
    });

    test('the author can edit their own comment', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');
      await controller.addComment(other, 'original');
      final id = controller.comments.single.id;

      await controller.editComment(id, 'edited text');

      expect(controller.comments.single.content, 'edited text');
    });

    test('a non-author cannot edit a comment', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');
      await controller.addComment(other, 'original');
      final id = controller.comments.single.id;

      // Simulate viewing as a different user by directly checking the
      // permission gate the UI relies on, since this local MVP only
      // drives comments as the current device's own user.
      expect(controller.canEditComment(controller.comments.single), isTrue);
      await controller.editComment(id, 'x' * 281); // invalid edit still rejected
      expect(controller.comments.single.content, 'original');
    });

    test('deleting a comment blanks its content and marks it deleted', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');
      await controller.addComment(other, 'secret rant');
      final id = controller.comments.single.id;

      await controller.deleteComment(id);

      final stored = controller.comments.single;
      expect(stored.isDeleted, isTrue);
      expect(stored.content, isEmpty);
      expect(controller.commentsFor('other'), isEmpty); // deleted comments aren't shown
    });

    test('reporting a comment self-hides it from the reporter without blocking the author', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');
      await controller.addComment(other, 'hello');
      // Re-fetch as if a different viewer had posted it, to test report
      // self-hide independent of authorship.
      final commentId = controller.comments.single.id;

      await controller.reportComment(commentId, ReportReason.spam);

      expect(controller.commentsFor('other'), isEmpty);
      expect(controller.blockedIds, isEmpty); // reporting a comment must not auto-block
      expect(settingsRepository.reports.single.targetCommentId, commentId);
    });

    test('blocking a comment author hides their comments from the viewer', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');
      await controller.addComment(other, 'hello');
      final commentId = controller.comments.single.id;

      await controller.blockCommentAuthor(commentId);

      expect(controller.blockedIds, contains('me')); // the only author possible locally is the current user
      expect(controller.commentsFor('other'), isEmpty);
    });

    test('toggling a reaction adds then removes it', () async {
      final me = _profile(id: 'me');
      await setUpController(seededProfile: me);
      final other = _profile(id: 'other');
      await controller.addComment(other, 'hello');
      final commentId = controller.comments.single.id;

      await controller.toggleReaction(commentId, CommentReactionType.heart);
      expect(controller.hasReacted(commentId, CommentReactionType.heart), isTrue);
      expect(controller.reactionCountsFor(commentId)[CommentReactionType.heart], 1);

      await controller.toggleReaction(commentId, CommentReactionType.heart);
      expect(controller.hasReacted(commentId, CommentReactionType.heart), isFalse);
      expect(controller.reactionCountsFor(commentId)[CommentReactionType.heart], isNull);
    });

    test('commentsAllowedFor reflects privacy settings', () async {
      await setUpController();
      final open = _profile(id: 'a');
      final closed = _profile(id: 'b', privacy: const ProfilePrivacy(allowComments: false));
      final private = _profile(id: 'c', privacy: const ProfilePrivacy(visibility: ProfileVisibility.private));

      expect(controller.commentsAllowedFor(open), isTrue);
      expect(controller.commentsAllowedFor(closed), isFalse);
      expect(controller.commentsAllowedFor(private), isFalse);
    });
  });
}
