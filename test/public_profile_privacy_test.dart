import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/presentation/screens/screens.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.mockProfiles);

  final List<UserProfile> mockProfiles;

  @override
  Future<void> deleteCurrentProfile() async {}

  @override
  Future<UserProfile?> loadCurrentProfile() async => null;

  @override
  Future<UserProfile?> loadProfileById(String id) async => mockProfiles.where((p) => p.id == id).firstOrNull;

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
  Future<void> saveCurrentProfile(UserProfile profile) async {}

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

class _FakeCoinRepository implements CoinRepository {
  List<CoinTransaction> stored = [];

  @override
  Future<List<CoinTransaction>> loadCoinTransactions() async => stored;

  @override
  Future<void> saveCoinTransactions(List<CoinTransaction> transactions) async => stored = transactions;
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

class _FakeAchievementRepository implements AchievementRepository {
  List<UserAchievement> stored = [];

  @override
  Future<List<UserAchievement>> loadAchievements() async => stored;

  @override
  Future<void> saveAchievements(List<UserAchievement> achievements) async => stored = achievements;
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

  @override
  Future<List<HiddenConversation>> loadHiddenConversations() async => const [];

  @override
  Future<void> saveHiddenConversations(List<HiddenConversation> hidden) async {}

  @override
  Future<void> resetApp() async {}
}

UserProfile _profile({required String id, required ProfilePrivacy privacy}) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: 'Tester',
    age: 24,
    country: 'Morocco',
    city: 'Rabat',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    jobTitle: 'Secret Engineer',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: 123456,
    currency: 'MAD',
    savings: 987654,
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
  );
}

Future<_FakeRatingRepository> _pumpProfile(WidgetTester tester, UserProfile profile) async {
  // Make the test surface tall enough that every section of the scrolling
  // profile screen is realized in the widget tree (a plain ListView only
  // builds children near the viewport, so off-screen text is otherwise
  // invisible to finders).
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ratingRepository = _FakeRatingRepository();
  final repos = RepositoryBundle(
    profileRepository: _FakeProfileRepository([profile]),
    ratingRepository: ratingRepository,
    settingsRepository: _FakeSettingsRepository(),
    progressionRepository: _FakeProgressionRepository(),
    appOpenRepository: _FakeAppOpenRepository(),
    achievementRepository: _FakeAchievementRepository(),
    coinRepository: _FakeCoinRepository(),
    challengeRepository: _FakeChallengeRepository(),
    cosmeticRepository: _FakeCosmeticRepository(),
    photoVoteRepository: _FakePhotoVoteRepository(),
    notificationRepository: _FakeNotificationRepository(),
    commentRepository: _FakeCommentRepository(),
    messageRepository: _FakeMessageRepository(),
    callRepository: _FakeCallRepository(),
    commentReactionRepository: _FakeCommentReactionRepository(),
    battleRepository: _FakeBattleRepository(),
    battleVoteRepository: _FakeBattleVoteRepository(),
    choiceRepository: _FakeChoiceRepository(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryBundleProvider.overrideWithValue(repos)],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(appControllerProvider);
            if (state.isLoading) return const Scaffold(body: SizedBox());
            return PublicProfileScreen(profileId: profile.id);
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ratingRepository;
}

void main() {
  group('PublicProfileScreen privacy-sensitive rendering', () {
    testWidgets('hides income, savings, and career when disabled', (tester) async {
      final profile = _profile(
        id: 'p_private',
        privacy: const ProfilePrivacy(showIncome: false, showSavings: false, showCareer: false),
      );
      await _pumpProfile(tester, profile);

      expect(find.textContaining('123456'), findsNothing);
      expect(find.textContaining('987654'), findsNothing);
      expect(find.text('Secret Engineer'), findsNothing);
    });

    testWidgets('shows income, savings, and career when enabled', (tester) async {
      final profile = _profile(
        id: 'p_public',
        privacy: const ProfilePrivacy(showIncome: true, showSavings: true, showCareer: true),
      );
      await _pumpProfile(tester, profile);

      expect(find.textContaining('123456'), findsOneWidget);
      expect(find.textContaining('987654'), findsOneWidget);
      expect(find.text('Secret Engineer'), findsOneWidget);
    });

    testWidgets('hides age and country from the location line when disabled', (tester) async {
      final profile = _profile(
        id: 'p_location',
        privacy: const ProfilePrivacy(showAge: false, showCountry: false),
      );
      await _pumpProfile(tester, profile);

      expect(find.text('24 • Morocco'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('Morocco'), findsNothing);
    });

    testWidgets('with showPhotos disabled, only the cover photo shows — no swipeable gallery', (tester) async {
      final now = DateTime(2026);
      final photos = [
        ProfilePhoto(id: 'cover', ownerId: 'p_gallery', path: 'mock://Cover', isProfilePhoto: true, order: 0, createdAt: now),
        ProfilePhoto(id: 'extra', ownerId: 'p_gallery', path: 'mock://Extra', order: 1, createdAt: now),
      ];
      final profile = _profile(id: 'p_gallery', privacy: const ProfilePrivacy(showPhotos: false)).copyWith(photos: photos);
      await _pumpProfile(tester, profile);

      expect(find.byType(PageView), findsNothing);
      expect(find.text('COVER'), findsOneWidget);
      expect(find.text('EXTRA'), findsNothing);
    });

    testWidgets('with showPhotos enabled, the full gallery is swipeable', (tester) async {
      final now = DateTime(2026);
      final photos = [
        ProfilePhoto(id: 'cover', ownerId: 'p_gallery2', path: 'mock://Cover', isProfilePhoto: true, order: 0, createdAt: now),
        ProfilePhoto(id: 'extra', ownerId: 'p_gallery2', path: 'mock://Extra', order: 1, createdAt: now),
      ];
      final profile = _profile(id: 'p_gallery2', privacy: const ProfilePrivacy(showPhotos: true)).copyWith(photos: photos);
      await _pumpProfile(tester, profile);

      expect(find.byType(PageView), findsOneWidget);
      // Appears both in the header carousel and the gallery grid below.
      expect(find.text('COVER'), findsWidgets);
    });
  });

  group('PublicProfileScreen rating flow', () {
    testWidgets('tapping stars then submit persists a rating', (tester) async {
      final profile = _profile(id: 'p_rate', privacy: const ProfilePrivacy());
      final ratingRepository = await _pumpProfile(tester, profile);

      expect(ratingRepository.stored, isEmpty);

      final lookStars = find.bySemanticsLabel('Rate 5 out of 5');
      expect(lookStars, findsWidgets);
      await tester.tap(lookStars.first);
      await tester.pump();

      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      expect(ratingRepository.stored, hasLength(1));
      expect(ratingRepository.stored.first.profileId, 'p_rate');
    });
  });
}
