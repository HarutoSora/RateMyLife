import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';

import '../../core/purchases/purchase_config.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/call_service.dart';
import '../../domain/services/comment_service.dart';
import '../../domain/services/daily_challenge_service.dart';
import '../../domain/services/level_service.dart';
import '../../domain/services/message_service.dart';
import '../../domain/services/moderation_service.dart';
import '../../domain/services/nuke_service.dart';
import '../../domain/services/photo_quality_service.dart';

final repositoryBundleProvider = Provider<RepositoryBundle>((ref) {
  // Every repository is remote now once signed in — see each Remote*
  // class's own doc comment for what stays private to the device vs.
  // what's genuinely shared (only profiles' public fields and the
  // rating-summary aggregate are visible to other users).
  final signedIn = FirebaseAuth.instance.currentUser != null;
  return RepositoryBundle(
    profileRepository: signedIn ? RemoteProfileRepository() : null,
    ratingRepository: signedIn ? RemoteRatingRepository() : null,
    photoVoteRepository: signedIn ? RemotePhotoVoteRepository() : null,
    nukeRepository: signedIn ? RemoteNukeRepository() : null,
    photoRepository: signedIn ? RemotePhotoRepository() : null,
    commentRepository: signedIn ? RemoteCommentRepository() : null,
    commentReactionRepository: signedIn ? RemoteCommentReactionRepository() : null,
    messageRepository: signedIn ? RemoteMessageRepository() : null,
    callRepository: signedIn ? RemoteCallRepository() : null,
    battleRepository: signedIn ? RemoteBattleRepository() : null,
    battleVoteRepository: signedIn ? RemoteBattleVoteRepository() : null,
    choiceRepository: signedIn ? RemoteChoiceRepository() : null,
    pushNotificationRepository: signedIn ? RemotePushNotificationRepository() : null,
    progressionRepository: signedIn ? RemoteProgressionRepository() : null,
    appOpenRepository: signedIn ? RemoteAppOpenRepository() : null,
    achievementRepository: signedIn ? RemoteAchievementRepository() : null,
    coinRepository: signedIn ? RemoteCoinRepository() : null,
    cosmeticRepository: signedIn ? RemoteCosmeticRepository() : null,
    challengeRepository: signedIn ? RemoteChallengeRepository() : null,
  );
});

final appControllerProvider =
    ChangeNotifierProvider<AppController>((ref) => AppController(ref.read));

typedef Reader = T Function<T>(ProviderListenable<T> provider);

class AppController extends ChangeNotifier {
  AppController(this._read) {
    _load();
  }

  final Reader _read;
  final Uuid _uuid = const Uuid();

  /// Counts XP-granting actions (ratings, votes, choices, shares, etc.
  /// — see `_awardXp`, the shared choke point every one of them already
  /// goes through) toward the periodic interstitial ad. Session-only by
  /// design — not persisted, so it resets on a fresh app launch rather
  /// than needing its own repository for an MVP-scoped ad cadence.
  int _actionCount = 0;

  bool isLoading = true;
  bool hasSeenOnboarding = false;
  UserProfile? currentProfile;

  /// A bounded lookup cache, not a browsable list — see `_load()`.
  /// Populated from the same first page `discoverProfiles` starts
  /// from, plus opportunistically from every other page fetched
  /// (`_mergeIntoProfileCache`), so a comment author or message/call
  /// partner already seen this session resolves without a fetch.
  List<UserProfile> profiles = [];
  List<Rating> ratings = [];
  List<PhotoVote> photoVotes = [];
  List<BlockedUser> blockedUsers = [];
  List<Report> reports = [];
  List<XpTransaction> xpTransactions = [];
  Set<DateTime> appOpenDays = {};
  List<HiddenConversation> hiddenConversations = [];
  List<UserAchievement> unlockedAchievements = [];
  List<CoinTransaction> coinTransactions = [];
  List<CosmeticPurchase> cosmeticPurchases = [];
  List<ChallengeCompletion> challengeCompletions = [];
  List<Comment> comments = [];
  List<Message> messages = [];
  List<CommentReaction> commentReactions = [];
  List<Battle> battles = [];
  List<BattleVote> battleVotes = [];
  /// This device's own sent nuke-attack history — see `NukeEvent`'s doc
  /// comment for why there's no symmetric "received" list.
  List<NukeEvent> nukeHistory = [];
  List<ChoiceVote> choiceVotes = [];
  ChoiceTally? todaysChoiceTally;
  CallSession? currentCall;
  StreamSubscription<CallSession?>? _callSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessagesSubscription;
  StreamSubscription<String>? _notificationTapSubscription;
  StreamSubscription<RemoteMessage>? _openedMessagesSubscription;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Whether the store (Play/App Store) is reachable at all — false
  /// almost always means "not signed into an account with purchase
  /// capability," not a transient error. `GetCoinsScreen` uses this to
  /// decide whether buy buttons should even try.
  bool purchasesAvailable = false;

  /// Real store metadata (localized price, title) for whichever coin
  /// packages actually exist as configured products — see
  /// `PurchaseConfig`'s doc comment on why this can be empty even when
  /// [purchasesAvailable] is true (no Play Console listing yet).
  List<ProductDetails> purchaseProducts = [];

  /// Set when the user taps a message notification (foreground, tapped
  /// from the tray while backgrounded, or the app cold-starting from a
  /// tap) — `RateMyLifeApp` watches this and pushes `ConversationScreen`
  /// once it's ready, then calls `clearPendingConversationOpen`. A call
  /// notification needs no equivalent: `currentCall` already drives
  /// `CallScreen` reactively the instant the app is open, tap or not.
  String? pendingConversationOpen;

  void clearPendingConversationOpen() {
    pendingConversationOpen = null;
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || !payload.startsWith('message:')) return;
    pendingConversationOpen = payload.substring('message:'.length);
    notifyListeners();
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (message.data['type'] != 'message') return;
    final otherUserId = message.data['otherUserId'];
    if (otherUserId is String) {
      pendingConversationOpen = otherUserId;
      notifyListeners();
    }
  }

  /// This device's own authored comments, across every profile —
  /// loaded once, kept in sync on `addComment` — used only for the
  /// posting-rate-limit check, never rendered. See `CommentRepository`'s
  /// doc comment for why this is the one comment view that's allowed
  /// to span profiles.
  List<Comment> _myComments = [];

  /// Which profiles' comments/reactions have been fetched already this
  /// session, so re-opening a profile doesn't refetch every time.
  final Set<String> _loadedCommentProfileIds = {};

  // Four independent paginated feeds. Each accumulates the raw pages
  // fetched so far; the public `xProfiles` getters apply the same
  // privacy/blocking filter the single old `profiles` list used to be
  // filtered with, just over a bounded, growing-on-demand pool instead
  // of the whole user base.
  List<UserProfile> _discoverRaw = [];
  UserProfile? _discoverCursor;
  bool discoverHasMore = true;
  bool discoverLoadingMore = false;

  List<UserProfile> _leaderboardRaw = [];
  UserProfile? _leaderboardCursor;
  bool leaderboardHasMore = true;
  bool leaderboardLoadingMore = false;

  List<UserProfile> _trendingRaw = [];
  UserProfile? _trendingCursor;
  bool trendingHasMore = true;
  bool trendingLoadingMore = false;

  List<UserProfile> _gapRaw = [];
  UserProfile? _gapCursor;
  bool gapHasMore = true;
  bool gapLoadingMore = false;

  /// Achievements newly unlocked but not yet shown to the user, in
  /// unlock order. The UI pops the front one into a celebratory dialog
  /// and calls `dequeueAchievement()` — kept separate from `toast` since
  /// an achievement unlock deserves more visual weight than a snackbar,
  /// and mixing the two channels would reintroduce the toast race
  /// `_grantXp`'s docs describe.
  List<AchievementDefinition> achievementQueue = [];
  UserSettings settings = const UserSettings();
  String? toast;

  RepositoryBundle get _repos => _read(repositoryBundleProvider);

  /// Derived level/rank for the local user. Never stored — always
  /// recomputed from `currentProfile.xp`.
  LevelInfo get levelInfo => _repos.levelService.levelFor(currentProfile?.xp ?? 0);

  Set<String> get unlockedAchievementIds =>
      unlockedAchievements.map((a) => a.achievementId).toSet();

  UserAchievement? achievementRecordFor(String achievementId) {
    for (final record in unlockedAchievements) {
      if (record.achievementId == achievementId) return record;
    }
    return null;
  }

  /// Every calendar day the local user earned any XP on, or simply
  /// opened the app — the ground truth for streaks, so there's no
  /// separate counter that could drift from what actually happened.
  /// Opening the app counts on its own (Duolingo/Snapchat-style),
  /// distinct from earning XP, so a day of just browsing still keeps
  /// the streak alive.
  Set<DateTime> get _activeDays => {
        ...xpTransactions.map((tx) => DailyChallengeService.dateOnly(tx.createdAt)),
        ...appOpenDays,
      };

  int get currentStreakDays => _repos.streakService.currentStreak(_activeDays, DateTime.now());

  /// Oldest-first, for a Mon..Sun-style streak row.
  List<MapEntry<DateTime, bool>> get lastSevenDays =>
      _repos.streakService.lastSevenDays(_activeDays, DateTime.now());

  /// Coin balance + history, derived the same way `levelInfo` is derived
  /// from `xp` rather than stored as its own thing.
  Wallet get wallet => Wallet(balance: currentProfile?.coins ?? 0, transactions: coinTransactions);

  Set<String> get ownedFrameIds =>
      cosmeticPurchases.where((p) => p.profileId == currentUserId).map((p) => p.cosmeticId).toSet();

  List<DailyChallenge> get todaysChallenges => _repos.dailyChallengeService.challengesFor(DateTime.now());

  int challengeProgress(DailyChallenge challenge) =>
      _repos.dailyChallengeService.progressFor(challenge, xpTransactions, DateTime.now());

  bool isChallengeCompletedToday(DailyChallenge challenge) =>
      _repos.dailyChallengeService.isCompleted(challenge, xpTransactions, DateTime.now());

  bool isChallengeClaimedToday(String challengeId) {
    final today = DailyChallengeService.dateOnly(DateTime.now());
    return challengeCompletions.any((c) => c.challengeId == challengeId && DailyChallengeService.dateOnly(c.date) == today);
  }

  String get currentUserId => currentProfile?.id ?? 'local_user';
  Set<String> get blockedIds =>
      blockedUsers.map((block) => block.blockedUserId).toSet();

  /// Comments the local user has reported themselves — used to self-hide
  /// them from view (see `CommentService.visibleComments`), distinct
  /// from `isHidden` which is reserved for real moderation.
  Set<String> get _reportedCommentIds => reports
      .where((r) => r.targetCommentId != null && r.reporterId == currentUserId)
      .map((r) => r.targetCommentId!)
      .toSet();

  List<Comment> commentsFor(String profileOwnerId) => _repos.commentService.visibleComments(
        comments,
        profileOwnerId,
        blockedByViewer: blockedIds,
        reportedByViewer: _reportedCommentIds,
      );

  /// Fetches [profileOwnerId]'s comments + reactions the first time
  /// its screen is opened, merging into the accumulated `comments`/
  /// `commentReactions` caches — a no-op on later visits this session.
  /// Call from `initState`/before first build; `commentsFor` renders
  /// whatever's cached, empty until this resolves.
  Future<void> ensureCommentsLoaded(String profileOwnerId) async {
    if (_loadedCommentProfileIds.contains(profileOwnerId)) return;
    _loadedCommentProfileIds.add(profileOwnerId);
    final fetchedComments = await _repos.commentRepository.loadCommentsForProfile(profileOwnerId);
    final fetchedReactions = await _repos.commentReactionRepository.loadReactionsForProfile(profileOwnerId);
    final knownCommentIds = comments.map((c) => c.id).toSet();
    final knownReactionIds = commentReactions.map((r) => r.id).toSet();
    comments = [...comments, ...fetchedComments.where((c) => !knownCommentIds.contains(c.id))];
    commentReactions = [...commentReactions, ...fetchedReactions.where((r) => !knownReactionIds.contains(r.id))];
    notifyListeners();
  }

  /// Whether the composer should even be shown — the profile owner's own
  /// settings, not viewer-specific blocking (that's enforced at submit
  /// time in `addComment`).
  bool commentsAllowedFor(UserProfile profile) =>
      profile.privacy.visibility == ProfileVisibility.public && profile.privacy.allowComments;

  Map<CommentReactionType, int> reactionCountsFor(String commentId) =>
      _repos.commentService.reactionCounts(commentReactions, commentId);

  bool hasReacted(String commentId, CommentReactionType type) =>
      _repos.commentService.existingReaction(commentReactions, commentId, currentUserId, type) != null;

  bool canEditComment(Comment comment) => _repos.commentService.canEdit(comment, currentUserId);

  bool canDeleteComment(Comment comment) =>
      _repos.commentService.canDelete(comment, currentUserId, comment.profileOwnerId);

  BattleVote? myVoteFor(String battleId) {
    for (final vote in battleVotes) {
      if (vote.battleId == battleId && vote.voterId == currentUserId) return vote;
    }
    return null;
  }

  /// Today's "What Would You Choose" prompt — a deterministic pick, the
  /// same for everyone on a given day (see `ChoiceService.choiceFor`).
  Choice get todaysChoice => _repos.choiceService.choiceFor(DateTime.now());

  ChoiceVote? get myChoiceVoteToday {
    final questionId = todaysChoice.id;
    for (final vote in choiceVotes) {
      if (vote.questionId == questionId && vote.voterId == currentUserId) return vote;
    }
    return null;
  }

  UserProfile? profileById(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  /// Eligible battle participants: same visibility rule as Discover
  /// (public, opted into discovery, not blocked) and never the local
  /// user themself — keeps battles as "judge two other lives", matching
  /// the spec's own examples, without the added complexity of the local
  /// user's own profile being one of the two sides.
  List<UserProfile> get _battlePool => discoverProfiles;

  /// The most recent battle the local user hasn't voted on yet (and
  /// whose profiles are still eligible), or null if none exists.
  Battle? get pendingBattle {
    final eligibleIds = _battlePool.map((p) => p.id).toSet();
    for (final battle in battles.reversed) {
      if (myVoteFor(battle.id) != null) continue;
      if (!eligibleIds.contains(battle.profileAId) || !eligibleIds.contains(battle.profileBId)) continue;
      return battle;
    }
    return null;
  }

  /// A judged battle's outcome — real category data from each profile's
  /// `LifeScore`, plus a deterministic estimated audience split (not a
  /// live vote tally, see `BattleService.communityPercentageForA`).
  BattleResult battleResultFor(Battle battle) {
    final a = profileById(battle.profileAId);
    final b = profileById(battle.profileBId);
    final percentageForA = (a != null && b != null) ? _repos.battleService.communityPercentageForA(a, b) : 50;
    return BattleResult(battle: battle, myVote: myVoteFor(battle.id), percentageForA: percentageForA);
  }

  List<(String category, int a, int b)> battleCategoryComparison(Battle battle) {
    final a = profileById(battle.profileAId);
    final b = profileById(battle.profileBId);
    if (a == null || b == null) return const [];
    return _repos.battleService.categoryComparison(a, b);
  }

  int get battlesVotedCount => battleVotes.where((v) => v.voterId == currentUserId).length;

  /// Real percentile — the share of currently-known other profiles
  /// (mock seed + real synced users this device has loaded) whose
  /// overall Life Score is below the local user's own. Not a global
  /// statistic (this device only knows the profiles it has loaded),
  /// but genuinely computed from real data, not a fabricated formula.
  int get overallPercentile {
    final profile = currentProfile;
    if (profile == null) return 50;
    final others = profiles.where((p) => p.id != profile.id).map((p) => p.score.overall);
    return _repos.percentileService.percentileOf(profile.score.overall, others);
  }

  int categoryPercentile(String category) {
    final profile = currentProfile;
    if (profile == null) return 50;
    final myValue = profile.score.breakdown[category] ?? 0;
    final others = profiles.where((p) => p.id != profile.id).map((p) => p.score.breakdown[category] ?? 0);
    return _repos.percentileService.percentileOf(myValue, others);
  }

  /// Percentile among other known profiles within 5 years of the local
  /// user's age.
  int get agePercentile {
    final profile = currentProfile;
    if (profile == null) return 50;
    final others = profiles
        .where((p) => p.id != profile.id && (p.age - profile.age).abs() <= 5)
        .map((p) => p.score.overall);
    return _repos.percentileService.percentileOf(profile.score.overall, others);
  }

  /// Percentile among other known profiles in the same country.
  int get countryPercentile {
    final profile = currentProfile;
    if (profile == null) return 50;
    final others = profiles
        .where((p) => p.id != profile.id && p.country == profile.country)
        .map((p) => p.score.overall);
    return _repos.percentileService.percentileOf(profile.score.overall, others);
  }

  /// Every `xProfiles` getter below filters an accumulated, paginated
  /// pool (`_xRaw`) rather than the whole user base — see
  /// `loadMoreDiscover`/etc. Privacy/blocking can't be pushed into the
  /// Firestore query itself (see `ProfilesPage`'s doc comment), so it's
  /// still applied here, same as always, just over a bounded pool.
  List<UserProfile> get discoverProfiles {
    final service = _repos.profileService;
    return _discoverRaw
        .where((profile) =>
            profile.id != currentProfile?.id &&
            service.isVisibleInDiscover(profile, blockedIds))
        .toList();
  }

  Future<void> loadMoreDiscover({int limit = 30}) async {
    if (discoverLoadingMore || !discoverHasMore) return;
    discoverLoadingMore = true;
    notifyListeners();
    final page = await _repos.profileRepository.loadDiscoverPage(limit: limit, after: _discoverCursor);
    _discoverRaw = [..._discoverRaw, ..._refreshed(page.profiles)];
    _mergeIntoProfileCache(page.profiles);
    if (page.profiles.isNotEmpty) _discoverCursor = page.profiles.last;
    discoverHasMore = page.hasMore;
    discoverLoadingMore = false;
    notifyListeners();
  }

  List<UserProfile> get leaderboardProfiles {
    final service = _repos.profileService;
    return _leaderboardRaw.where((profile) => service.isVisibleInLeaderboard(profile, blockedIds)).toList();
  }

  Future<void> loadMoreLeaderboard({int limit = 30}) async {
    if (leaderboardLoadingMore || !leaderboardHasMore) return;
    leaderboardLoadingMore = true;
    notifyListeners();
    final page = await _repos.profileRepository.loadLeaderboardPage(limit: limit, after: _leaderboardCursor);
    _leaderboardRaw = [..._leaderboardRaw, ..._refreshed(page.profiles)];
    _mergeIntoProfileCache(page.profiles);
    if (page.profiles.isNotEmpty) _leaderboardCursor = page.profiles.last;
    leaderboardHasMore = page.hasMore;
    leaderboardLoadingMore = false;
    notifyListeners();
  }

  /// Public, rated profiles where the algorithm and the community
  /// disagree the most — biggest disagreement first, within whatever
  /// page(s) have been fetched so far (see `loadMoreGap`).
  List<UserProfile> get biggestGapProfiles {
    final service = _repos.profileService;
    final eligible = _gapRaw.where((profile) => service.isVisibleInLeaderboard(profile, blockedIds)).toList();
    return _repos.gapService.rankByGap(eligible);
  }

  Future<void> loadMoreGap({int limit = 30}) async {
    if (gapLoadingMore || !gapHasMore) return;
    gapLoadingMore = true;
    notifyListeners();
    final page = await _repos.profileRepository.loadGapPage(limit: limit, after: _gapCursor);
    _gapRaw = [..._gapRaw, ..._refreshed(page.profiles)];
    _mergeIntoProfileCache(page.profiles);
    if (page.profiles.isNotEmpty) _gapCursor = page.profiles.last;
    gapHasMore = page.hasMore;
    gapLoadingMore = false;
    notifyListeners();
  }

  /// Null when [profile] doesn't yet have enough ratings for a meaningful
  /// gap (see `GapService.minRatings`).
  int? gapFor(UserProfile profile) => _repos.gapService.gapFor(profile);

  /// The community's 0-5 average rescaled to the algorithm's 0-100 scale,
  /// so the two numbers can be shown side by side.
  int communityScoreOf(RatingSummary summary) => _repos.gapService.communityScoreOf(summary);

  /// Recently-created, publicly-discoverable profiles already gaining
  /// real engagement — see `TrendingService`'s own doc comment for why
  /// this isn't framed as a live growth-rate feed. Ranked within
  /// whatever page(s) have been fetched so far (see `loadMoreTrending`).
  List<UserProfile> get trendingProfiles {
    final service = _repos.profileService;
    final eligible = _trendingRaw
        .where((profile) => profile.id != currentProfile?.id && service.isVisibleInDiscover(profile, blockedIds))
        .toList();
    return _repos.trendingService.rank(eligible);
  }

  Future<void> loadMoreTrending({int limit = 30}) async {
    if (trendingLoadingMore || !trendingHasMore) return;
    trendingLoadingMore = true;
    notifyListeners();
    final since = DateTime.now().subtract(Duration(days: _repos.trendingService.windowDays));
    final page = await _repos.profileRepository.loadTrendingPage(limit: limit, after: _trendingCursor, since: since);
    _trendingRaw = [..._trendingRaw, ..._refreshed(page.profiles)];
    _mergeIntoProfileCache(page.profiles);
    if (page.profiles.isNotEmpty) _trendingCursor = page.profiles.last;
    trendingHasMore = page.hasMore;
    trendingLoadingMore = false;
    notifyListeners();
  }

  /// Always fetches the full profile (private-subdoc merge included)
  /// and upserts it into `profiles`, replacing any cheap copy already
  /// there. Unlike `ensureProfileLoaded` (fine returning a page-sourced
  /// copy for a name/photo lookup), `PublicProfileScreen` needs the
  /// real income/savings fields when the owner opted to show them —
  /// no paginated list page carries those.
  Future<UserProfile?> loadFullProfile(String id) async {
    if (id == currentUserId) return currentProfile;
    final fetched = await _repos.profileRepository.loadProfileById(id);
    if (fetched != null) {
      profiles = [fetched, ...profiles.where((p) => p.id != id)];
      notifyListeners();
    }
    return fetched;
  }

  /// Opportunistically widens the lookup cache (`profiles`) with
  /// whatever a browsing page just fetched, so a comment author or
  /// message/call partner seen while scrolling resolves without a
  /// separate fetch later.
  void _mergeIntoProfileCache(List<UserProfile> fetched) {
    if (fetched.isEmpty) return;
    final known = profiles.map((p) => p.id).toSet();
    final newOnes = fetched.where((p) => !known.contains(p.id));
    if (newOnes.isEmpty) return;
    profiles = [...profiles, ...newOnes];
  }

  /// Fallback for a specific, already-known other user (message
  /// thread, call, comment author) who isn't in `profiles` yet (see
  /// `profileById` above, `_mergeIntoProfileCache`) — a direct fetch,
  /// cached afterward so it only ever happens once per id.
  Future<UserProfile?> ensureProfileLoaded(String id) async {
    final cached = profileById(id);
    if (cached != null) return cached;
    final fetched = await _repos.profileRepository.loadProfileById(id);
    if (fetched != null) {
      profiles = [...profiles, fetched];
      notifyListeners();
    }
    return fetched;
  }

  List<UserProfile> rateQueue() {
    final unrated = discoverProfiles
        .where((profile) =>
            _repos.ratingService.ratingFor(
              ratings: ratings,
              raterId: currentUserId,
              profileId: profile.id,
            ) ==
            null)
        .toList();
    if (unrated.isNotEmpty) return unrated;
    return discoverProfiles;
  }

  Future<void> _load() async {
    final repo = _repos;
    hasSeenOnboarding = await repo.settingsRepository.hasSeenOnboarding();
    settings = await repo.settingsRepository.loadSettings();
    currentProfile = await repo.profileRepository.loadCurrentProfile();
    // A bounded lookup cache, not the whole user base — see `profiles`'
    // doc comment. This also seeds `discoverProfiles`' first page so
    // opening Discover right after launch doesn't re-fetch it.
    final bootstrap = await repo.profileRepository.loadDiscoverPage(limit: 60);
    profiles = bootstrap.profiles;
    _discoverRaw = bootstrap.profiles;
    _discoverCursor = bootstrap.profiles.isNotEmpty ? bootstrap.profiles.last : null;
    discoverHasMore = bootstrap.hasMore;
    ratings = await repo.ratingRepository.loadRatings();
    photoVotes = await repo.photoVoteRepository.loadVotes();
    blockedUsers = await repo.settingsRepository.loadBlockedUsers();
    hiddenConversations = await repo.settingsRepository.loadHiddenConversations();
    reports = await repo.settingsRepository.loadReports();
    xpTransactions = await repo.progressionRepository.loadXpTransactions();
    // Today counts toward the streak just for opening the app, even
    // before any XP-earning action happens — recorded once per launch,
    // idempotently (both stores dedupe on the date itself).
    final today = DailyChallengeService.dateOnly(DateTime.now());
    appOpenDays = await repo.appOpenRepository.loadOpenDays();
    if (!appOpenDays.contains(today)) {
      appOpenDays = {...appOpenDays, today};
      unawaited(repo.appOpenRepository.recordOpenDay(today));
    }
    unlockedAchievements = await repo.achievementRepository.loadAchievements();
    coinTransactions = await repo.coinRepository.loadCoinTransactions();
    cosmeticPurchases = await repo.cosmeticRepository.loadPurchases();
    challengeCompletions = await repo.challengeRepository.loadChallengeCompletions();
    // Comments/reactions are loaded lazily per profile from here on
    // (see `ensureCommentsLoaded`) — only this device's own authored
    // comments (a naturally small, owner-scoped set) are preloaded,
    // needed for the posting rate limit.
    battles = await repo.battleRepository.loadBattles();
    battleVotes = await repo.battleVoteRepository.loadVotes();
    nukeHistory = await repo.nukeRepository.loadSentHistory();
    choiceVotes = await repo.choiceRepository.loadMyVotes();
    if (_repos.choiceService.hasVoted(choiceVotes, todaysChoice.id)) {
      todaysChoiceTally = await repo.choiceRepository.loadTally(todaysChoice.id);
    }
    // Messages and calling both need a live subscription, unlike
    // everything else here — an incoming message/call has to appear
    // without the user manually restarting the app to refresh.
    unawaited(_messagesSubscription?.cancel());
    _messagesSubscription = repo.messageRepository.watchMessages().listen((updated) {
      messages = updated;
      notifyListeners();
    });
    unawaited(_callSubscription?.cancel());
    _callSubscription = repo.callRepository.currentCall.listen((call) {
      currentCall = call;
      notifyListeners();
    });
    unawaited(_foregroundMessagesSubscription?.cancel());
    _foregroundMessagesSubscription = repo.pushNotificationRepository.foregroundMessages.listen((message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      if (title == null) return;
      final otherUserId = message.data['otherUserId'];
      final payload = message.data['type'] == 'message' && otherUserId is String ? 'message:$otherUserId' : null;
      repo.notificationRepository.showNotification(title: title, body: body ?? '', payload: payload);
    });
    // Tapping the notification `showNotification` just displayed (app
    // was in the foreground when the message arrived).
    unawaited(_notificationTapSubscription?.cancel());
    _notificationTapSubscription = repo.notificationRepository.notificationTaps.listen(_handleNotificationPayload);
    // Tapping a background-delivered notification (app open but not
    // foreground when it arrived).
    unawaited(_openedMessagesSubscription?.cancel());
    _openedMessagesSubscription = repo.pushNotificationRepository.openedMessages.listen(_handleOpenedMessage);
    // The app was fully killed and this exact launch is the result of
    // tapping a notification — only meaningful once, right at startup.
    final initialMessage = await repo.pushNotificationRepository.getInitialMessage();
    if (initialMessage != null) _handleOpenedMessage(initialMessage);
    if (currentProfile != null) {
      currentProfile = _refreshProfileSummary(currentProfile!);
      profiles = [currentProfile!, ...profiles];
    }
    _myComments = await repo.commentRepository.loadCommentsByAuthor(currentUserId);
    _refreshMockSummaries();
    // Scheduled Android notifications don't reliably survive a device
    // reboot without a boot-time receiver — rescheduling here (cheap,
    // idempotent, same notification id every time) covers that without
    // needing one, and never re-prompts for permission on every launch.
    if (settings.notifications) {
      await repo.notificationRepository.scheduleDailyChallengeReminder();
      await repo.pushNotificationRepository.registerDevice();
    }
    purchasesAvailable = await repo.purchaseRepository.isAvailable();
    if (purchasesAvailable) {
      purchaseProducts = await repo.purchaseRepository.queryProducts(PurchaseConfig.allProductIds.toSet());
    }
    // Subscribed regardless of `purchasesAvailable` — a purchase from a
    // previous session that never got acknowledged (app killed
    // mid-flow, etc.) still needs to be caught and completed here, the
    // same reasoning as the messages/calls subscriptions above.
    unawaited(_purchaseSubscription?.cancel());
    _purchaseSubscription = repo.purchaseRepository.purchaseUpdates.listen(_handlePurchaseUpdates);
    isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _repos.settingsRepository.setOnboardingSeen(true);
    notifyListeners();
  }

  /// The id a brand-new profile should use — see `ProfileRepository.newProfileId`.
  String newProfileId() => _repos.profileRepository.newProfileId();

  /// Records that the local user opened [profileId]'s profile — a
  /// no-op locally, or for a self-view, or for a target this device
  /// doesn't currently have loaded (see `recordProfileView`'s doc
  /// comments in `repositories.dart` for the full picture). Does not
  /// update local state directly; the incremented count shows up the
  /// next time this profile is (re)loaded from its source of truth.
  Future<void> recordProfileView(String profileId) => _repos.profileRepository.recordProfileView(profileId);

  Future<void> createProfile(UserProfile profile) async {
    final recalculated = _repos.profileService
        .recalculate(profile.copyWith(isCurrentUser: true));
    currentProfile = recalculated;
    profiles = [
      recalculated,
      ...profiles.where((item) => item.id != recalculated.id),
    ];
    await _repos.profileRepository.saveCurrentProfile(recalculated);
    await _grantXp(XpReason.profileCompleted);
    await _grantCoins(XpReason.profileCompleted);
    await _checkDailyChallenges();
    notifyListeners();
    await _checkAchievements();
  }

  /// Appends an XP transaction, updates the local user's cumulative XP,
  /// and persists both — but does NOT touch `toast`/`notifyListeners`.
  /// Callers combine the returned amount into their own single toast
  /// instead of each stage calling `notifyListeners()` separately: the
  /// app shell shows+clears `toast` in a `postFrameCallback`, so two
  /// sequential notifies race and can drop or split the message across
  /// two separate snackbars. No-ops without a current profile (XP only
  /// tracks the local user in this device-local MVP).
  Future<int> _grantXp(XpReason reason) async {
    final profile = currentProfile;
    if (profile == null) return 0;
    return _applyXpTransaction(_repos.progressionService.award(profileId: profile.id, reason: reason));
  }

  /// Same as `_grantXp` but for a caller-chosen amount — used for
  /// achievement bonuses, which vary per achievement rather than coming
  /// from `ProgressionService.xpRewards`'s fixed-per-reason table.
  Future<int> _grantCustomXp(int amount, XpReason reason) async {
    final profile = currentProfile;
    if (profile == null || amount <= 0) return 0;
    return _applyXpTransaction(XpTransaction(
      id: _uuid.v4(),
      profileId: profile.id,
      amount: amount,
      reason: reason,
      createdAt: DateTime.now(),
    ));
  }

  Future<int> _applyXpTransaction(XpTransaction tx) async {
    final profile = currentProfile;
    if (profile == null) return 0;
    xpTransactions = [...xpTransactions, tx];
    await _repos.progressionRepository.saveXpTransactions(xpTransactions);
    final updated = profile.copyWith(xp: profile.xp + tx.amount);
    currentProfile = updated;
    profiles = [updated, ...profiles.where((item) => item.id != updated.id)];
    await _repos.profileRepository.saveCurrentProfile(updated);
    return tx.amount;
  }

  /// Coin counterpart to `_grantXp` — same no-toast, no-notify contract
  /// and the same reasoning applies to why callers combine the result
  /// into one toast themselves.
  Future<int> _grantCoins(XpReason reason) async {
    final profile = currentProfile;
    if (profile == null) return 0;
    return _applyCoinTransaction(_repos.rewardService.award(profileId: profile.id, reason: reason));
  }

  /// Shows a rewarded video ad; grants coins (see `RewardService`'s
  /// `XpReason.adWatched` entry) only if the user watches it to
  /// completion — returns whether that actually happened, so callers can
  /// show a real success/failure state instead of assuming success.
  /// Never throws for an unavailable/failed/closed-early ad, since ad
  /// availability is inherently unreliable — that's a normal `false`
  /// result, not an error.
  /// Guards `watchRewardedAd` against a double-tap (or any other
  /// double-call) firing two overlapping ad shows — without this, two
  /// rapid taps on "Watch Ad" could both resolve with a reward and grant
  /// coins twice for one ad watch.
  bool _watchingAd = false;

  Future<bool> watchRewardedAd() async {
    if (_watchingAd) return false;
    _watchingAd = true;
    try {
      var rewarded = false;
      await _repos.adRepository.showRewardedAd(onReward: () => rewarded = true);
      if (rewarded) await _grantAdReward();
      return rewarded;
    } finally {
      _watchingAd = false;
    }
  }

  Future<void> _grantAdReward() async {
    final earned = await _grantCoins(XpReason.adWatched);
    if (earned == 0) return;
    notifyListeners();
  }

  /// Starts a real Play/App Store purchase flow for [productId] (see
  /// `PurchaseConfig`). No-ops with an explanatory toast if the store
  /// isn't reachable or the product doesn't exist yet (e.g. no Play
  /// Console listing) — the actual coin grant happens later, in
  /// `_handlePurchaseUpdates`, once the store confirms the purchase.
  Future<void> purchaseCoins(String productId) async {
    final product = purchaseProducts.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      toast = purchasesAvailable
          ? 'This coin package isn\'t available yet.'
          : 'In-app purchases aren\'t available on this device right now.';
      notifyListeners();
      return;
    }
    await _repos.purchaseRepository.buyConsumable(product);
  }

  /// Every purchase event the store reports, successful or not — see
  /// `PurchaseRepository.purchaseUpdates`'s doc comment for why this
  /// has to handle every event, not just ones from this exact session's
  /// own `purchaseCoins` calls.
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.error:
          toast = purchase.error?.message ?? 'Purchase failed.';
          notifyListeners();
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final coins = PurchaseConfig.coinsForProduct[purchase.productID];
          if (coins != null) {
            await _grantCustomCoins(coins, XpReason.coinsPurchased);
            notifyListeners();
          }
        case PurchaseStatus.canceled:
          break;
      }
      await _repos.purchaseRepository.completePurchase(purchase);
    }
  }

  /// [amount] may be negative — spending on a cosmetic is just a
  /// negative-amount transaction, same ledger as earning.
  Future<int> _grantCustomCoins(int amount, XpReason reason) async {
    final profile = currentProfile;
    if (profile == null || amount == 0) return 0;
    return _applyCoinTransaction(CoinTransaction(
      id: _uuid.v4(),
      profileId: profile.id,
      amount: amount,
      reason: reason,
      createdAt: DateTime.now(),
    ));
  }

  /// Unlocks [frameId] permanently for coins — a no-op (with a toast
  /// explaining why) if it's already owned or unaffordable. Does not
  /// equip it; call `equipFrame` separately.
  Future<void> purchaseFrame(String frameId) async {
    final profile = currentProfile;
    if (profile == null) return;
    final frame = _repos.cosmeticService.frameById(frameId);
    if (frame == null) return;
    if (_repos.cosmeticService.isOwned(frameId, ownedFrameIds)) {
      toast = 'You already own this frame.';
      notifyListeners();
      return;
    }
    if (!_repos.cosmeticService.canAfford(frame, wallet.balance)) {
      toast = "You don't have enough coins for this frame.";
      notifyListeners();
      return;
    }

    cosmeticPurchases = [
      ...cosmeticPurchases,
      CosmeticPurchase(id: _uuid.v4(), profileId: profile.id, cosmeticId: frameId, purchasedAt: DateTime.now()),
    ];
    await _repos.cosmeticRepository.savePurchases(cosmeticPurchases);
    await _grantCustomCoins(-frame.cost, XpReason.cosmeticPurchased);
    notifyListeners();
  }

  /// Equips an owned frame (or `'none'`) — the only ones displayed
  /// anywhere this profile's photo appears.
  Future<void> equipFrame(String frameId) async {
    final profile = currentProfile;
    if (profile == null) return;
    if (!_repos.cosmeticService.isOwned(frameId, ownedFrameIds)) return;
    await updateProfile(profile.copyWith(equippedFrameId: frameId));
  }

  Future<int> _applyCoinTransaction(CoinTransaction tx) async {
    final profile = currentProfile;
    if (profile == null) return 0;
    coinTransactions = [...coinTransactions, tx];
    await _repos.coinRepository.saveCoinTransactions(coinTransactions);
    final updated = profile.copyWith(coins: profile.coins + tx.amount);
    currentProfile = updated;
    profiles = [updated, ...profiles.where((item) => item.id != updated.id)];
    await _repos.profileRepository.saveCurrentProfile(updated);
    return tx.amount;
  }

  /// Evaluates the achievement catalog against real, current activity and
  /// queues any newly-unlocked ones (with their XP bonus already
  /// granted) for the UI to show one at a time via `achievementQueue`.
  /// Deliberately excludes signals this local MVP can't produce yet
  /// (see `AchievementStats`'s doc comment).
  Future<void> _checkAchievements() async {
    final profile = currentProfile;
    if (profile == null) return;
    // Every action that reaches this shared post-action checkpoint
    // (ratings, battle/choice votes, messages, comments, etc.) counts
    // toward the periodic interstitial — see `_maybeShowInterstitialAd`.
    _maybeShowInterstitialAd();
    final stats = AchievementStats(
      hasProfile: true,
      ratingsGiven: ratings.where((r) => r.raterId == currentUserId).length,
      photoCount: profile.photos.length,
      scoreImprovement: profile.history.isEmpty
          ? 0
          : profile.history.last.algorithmScore - profile.history.first.algorithmScore,
      level: levelInfo.level,
      hasSharedProfile: xpTransactions.any((tx) => tx.reason == XpReason.profileShared),
      streakDays: currentStreakDays,
      battlesVoted: battlesVotedCount,
    );
    final newlyUnlocked = _repos.achievementService.evaluate(stats, unlockedAchievementIds);
    if (newlyUnlocked.isEmpty) return;
    for (final achievement in newlyUnlocked) {
      unlockedAchievements = [
        ...unlockedAchievements,
        UserAchievement(
          id: _uuid.v4(),
          profileId: profile.id,
          achievementId: achievement.id,
          unlockedAt: DateTime.now(),
        ),
      ];
    }
    await _repos.achievementRepository.saveAchievements(unlockedAchievements);
    for (final achievement in newlyUnlocked) {
      await _grantCustomXp(achievement.xpReward, XpReason.achievementUnlocked);
    }
    achievementQueue = [...achievementQueue, ...newlyUnlocked];
    notifyListeners();
  }

  /// Every 30th action shows a full-screen interstitial — user-requested
  /// ad cadence. Fire-and-forget: an ad (or a failed load) must never
  /// block or delay the action that triggered it.
  void _maybeShowInterstitialAd() {
    _actionCount++;
    if (_actionCount % 30 == 0) {
      unawaited(_repos.adRepository.showInterstitialAd());
    }
  }

  /// Called by the UI after showing (or dismissing) the front of
  /// `achievementQueue`.
  void dequeueAchievement() {
    if (achievementQueue.isEmpty) return;
    achievementQueue = achievementQueue.skip(1).toList();
    notifyListeners();
  }

  /// Checks today's 3 challenges against real activity and claims (with
  /// XP + coins already granted and persisted) any that are newly
  /// completed and not already claimed today. Unlike achievements, this
  /// does NOT touch `notifyListeners` — callers call this alongside their
  /// own XP/coin grants and notify once, for the same race-avoidance
  /// reason as `_grantXp`.
  Future<({int xp, int coins, List<String> titles})> _checkDailyChallenges() async {
    final profile = currentProfile;
    if (profile == null) return (xp: 0, coins: 0, titles: const <String>[]);
    final today = DateTime.now();
    var xpGained = 0;
    var coinsGained = 0;
    final titles = <String>[];
    for (final challenge in todaysChallenges) {
      if (isChallengeClaimedToday(challenge.id)) continue;
      if (!isChallengeCompletedToday(challenge)) continue;
      challengeCompletions = [
        ...challengeCompletions,
        ChallengeCompletion(
          id: _uuid.v4(),
          profileId: profile.id,
          challengeId: challenge.id,
          date: DailyChallengeService.dateOnly(today),
          completedAt: today,
        ),
      ];
      xpGained += await _grantCustomXp(challenge.xpReward, XpReason.dailyChallengeCompleted);
      coinsGained += await _grantCustomCoins(challenge.coinReward, XpReason.dailyChallengeCompleted);
      titles.add(challenge.title);
    }
    if (titles.isNotEmpty) {
      await _repos.challengeRepository.saveChallengeCompletions(challengeCompletions);
    }
    return (xp: xpGained, coins: coinsGained, titles: titles);
  }

  /// Single-notify convenience for call sites that don't already have
  /// their own toast to combine with (see `_grantXp` for why this
  /// matters).
  Future<void> _awardXp(XpReason reason) async {
    await _grantXp(reason);
    await _grantCoins(reason);
    await _checkDailyChallenges();
    notifyListeners();
    await _checkAchievements();
  }

  /// Called after the local user shares their own profile.
  Future<void> awardProfileSharedXp() => _awardXp(XpReason.profileShared);

  /// [xpReason], if given, grants XP as part of this same update — see
  /// `_grantXp` for why its return value isn't used directly here.
  Future<void> updateProfile(UserProfile profile, {XpReason? xpReason}) async {
    final recalculated = _repos.profileService
        .recalculate(profile.copyWith(isCurrentUser: true));
    currentProfile = recalculated;
    profiles = [
      recalculated,
      ...profiles.where((item) => item.id != recalculated.id),
    ];
    await _repos.profileRepository.saveCurrentProfile(recalculated);
    if (xpReason != null) {
      await _grantXp(xpReason);
      await _grantCoins(xpReason);
      await _checkDailyChallenges();
    }
    notifyListeners();
    await _checkAchievements();
  }

  Future<void> addPhoto(ImageSource source, {String category = 'Lifestyle'}) async {
    final profile = currentProfile;
    if (profile == null) return;
    try {
      final photo = await _repos.photoRepository.pickAndStorePhoto(
        ownerId: profile.id,
        source: source,
        order: profile.photos.length,
        category: category,
      );
      final photos = _repos.photoService.addPhoto(profile.photos, photo);
      await updateProfile(profile.copyWith(photos: photos), xpReason: XpReason.photoAdded);
    } catch (error) {
      toast = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deletePhoto(String id) async {
    final profile = currentProfile;
    if (profile == null) return;
    final photos = _repos.photoService.deletePhoto(profile.photos, id);
    await updateProfile(profile.copyWith(photos: photos));
  }

  Future<void> setProfilePhoto(String id) async {
    final profile = currentProfile;
    if (profile == null) return;
    final photos = _repos.photoService.setProfilePhoto(profile.photos, id);
    await updateProfile(profile.copyWith(photos: photos));
  }

  Future<void> setPhotoCategory(String id, String category) async {
    final profile = currentProfile;
    if (profile == null) return;
    final photos = _repos.photoService.setCategory(profile.photos, id, category);
    await updateProfile(profile.copyWith(photos: photos));
  }

  Future<void> reorderPhoto(int oldIndex, int newIndex) async {
    final profile = currentProfile;
    if (profile == null) return;
    final photos = _repos.photoService.reorder(profile.photos, oldIndex, newIndex);
    await updateProfile(profile.copyWith(photos: photos));
  }

  /// Judges the PHOTOGRAPH — lighting/sharpness/resolution — never the
  /// person in it (see `PhotoQualityService`'s own doc comment). Null
  /// when the photo's bytes can't be read back (a mock/seed demo photo,
  /// a missing local file, a failed remote fetch).
  Future<PhotoQualityResult?> analyzePhotoQuality(ProfilePhoto photo) async {
    final bytes = await _repos.photoRepository.readPhotoBytes(photo);
    if (bytes == null) return null;
    return _repos.photoQualityService.analyze(bytes);
  }

  /// Profile ids with a `submitRating` call currently in flight — guards
  /// against a double-tap (or any other double-call) firing two
  /// overlapping submissions for the same profile before the first
  /// one's local `ratings` update lands, which would otherwise race two
  /// writes against the same Firestore rating document.
  final _submittingRatings = <String>{};

  Future<void> submitRating(UserProfile target, int life, int look) async {
    if (!_submittingRatings.add(target.id)) return;
    try {
      final rating = _repos.ratingService.upsertRating(
        existing: ratings,
        raterId: currentUserId,
        profileId: target.id,
        overall: life,
        look: look,
        career: life,
        lifestyle: life,
        social: life,
        independence: life,
        experiences: life,
      );
      ratings = [
        ...ratings.where((item) => item.id != rating.id),
        rating,
      ];
      await _repos.ratingRepository.saveRatings(ratings);
      _applyRatingSummary(target.id);
      await _grantXp(XpReason.ratingGiven);
      await _grantCoins(XpReason.ratingGiven);
      await _checkDailyChallenges();
      notifyListeners();
      await _checkAchievements();
    } catch (error) {
      toast = error.toString();
      notifyListeners();
    } finally {
      _submittingRatings.remove(target.id);
    }
  }

  Future<void> removeRating(String profileId) async {
    ratings = _repos.ratingService.removeRating(
      existing: ratings,
      raterId: currentUserId,
      profileId: profileId,
    );
    await _repos.ratingRepository.saveRatings(ratings);
    _applyRatingSummary(profileId);
    notifyListeners();
  }

  Rating? myRatingFor(String profileId) {
    return _repos.ratingService.ratingFor(
      ratings: ratings,
      raterId: currentUserId,
      profileId: profileId,
    );
  }

  /// Votes (or moves an existing vote) for [photoId] as [profileId]'s
  /// best photo. The public tally (`UserProfile.photoVoteCounts`) is
  /// maintained server-side the same way `ratingSummary` is — this
  /// device's own `profiles` copy of the target catches up on next
  /// reload, same as ratings already do.
  Future<void> voteForBestPhoto(String profileId, String photoId) async {
    try {
      final vote = _repos.photoVoteService.upsertVote(
        existing: photoVotes,
        voterId: currentUserId,
        profileId: profileId,
        photoId: photoId,
      );
      photoVotes = [
        ...photoVotes.where((item) => item.id != vote.id),
        vote,
      ];
      await _repos.photoVoteRepository.saveVotes(photoVotes);
      notifyListeners();
    } catch (error) {
      toast = error.toString();
      notifyListeners();
    }
  }

  String? myBestPhotoVoteFor(String profileId) {
    return _repos.photoVoteService.voteFor(
      votes: photoVotes,
      voterId: currentUserId,
      profileId: profileId,
    )?.photoId;
  }

  /// Damage this device has personally dealt to [profileId] via
  /// `nukeProfile` — only meaningful for a mock/seed target, which has
  /// no real backend of its own to carry `nukeDamage` for it (see
  /// `NukeRepository`'s doc comment). Recomputed fresh from
  /// `nukeHistory` every call rather than ever baked into the stored
  /// `profiles`/`_discoverRaw` lists, so repeatedly nuking the same
  /// mock target can never double-count.
  Map<String, int> _localNukeDamageFor(String profileId) {
    final damage = <String, int>{};
    for (final event in nukeHistory) {
      if (event.targetId != profileId) continue;
      damage[event.attribute] = (damage[event.attribute] ?? 0) + event.damage;
    }
    return damage;
  }

  /// The Life Score a card/screen should actually render for [profile]
  /// — folds in this device's own local nuke damage for a mock target;
  /// a real, Firestore-synced profile's `score` already has every
  /// attacker's damage baked in server-side (see `RemoteNukeRepository`),
  /// so this is a no-op for one.
  LifeScore displayScoreFor(UserProfile profile) {
    if (!profile.id.startsWith('mock_')) return profile.score;
    final damage = _localNukeDamageFor(profile.id);
    if (damage.isEmpty) return profile.score;
    return _repos.profileService.applyNukeDamage(profile.score, damage);
  }

  /// The "X nukes survived" count a card/screen should render — same
  /// mock-only local mixing as `displayScoreFor`.
  int nukesSurvivedFor(UserProfile profile) {
    if (!profile.id.startsWith('mock_')) return profile.nukesSurvived;
    return profile.nukesSurvived + nukeHistory.where((e) => e.targetId == profile.id).length;
  }

  /// Active nuke damage by attribute for [profile] — same mock-only
  /// local mixing as `displayScoreFor`/`nukesSurvivedFor`, so a score
  /// breakdown can flag exactly which category `displayScoreFor` just
  /// lowered, for a mock target or a real one alike.
  Map<String, int> nukeDamageFor(UserProfile profile) {
    if (!profile.id.startsWith('mock_')) return profile.nukeDamage;
    final local = _localNukeDamageFor(profile.id);
    if (local.isEmpty) return profile.nukeDamage;
    final merged = {...profile.nukeDamage};
    for (final entry in local.entries) {
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    return merged;
  }

  /// Guards `nukeProfile`/`cureDamage` against a double-tap (or any other
  /// double-call) firing two overlapping spends before the first one's
  /// `wallet.balance` update lands — both methods check the balance
  /// synchronously up front, so two concurrent calls could otherwise
  /// both pass that check against the same stale balance and spend more
  /// coins than the wallet actually has. Shared across both since they
  /// draw from the same coin balance.
  bool _spendingCoins = false;

  /// Spends `NukeService.attackCost` coins to deal `NukeService.
  /// damagePerNuke` damage to a random Life Score attribute of
  /// [target]'s profile. Anonymous to the target by default — see
  /// `NukeEvent`'s doc comment.
  Future<void> nukeProfile(UserProfile target) async {
    if (_spendingCoins) return;
    _spendingCoins = true;
    try {
      final attribute = _repos.nukeService.randomAttribute(Random());
      try {
        _repos.nukeService.assertCanNuke(
          attackerId: currentUserId,
          targetId: target.id,
          isBlockedEitherWay: blockedIds.contains(target.id),
          balance: wallet.balance,
        );
      } on NukeValidationException catch (error) {
        toast = error.message;
        notifyListeners();
        return;
      }
      await _grantCustomCoins(-NukeService.attackCost, XpReason.nukeUsed);
      final event = await _repos.nukeRepository.attack(
        attackerId: currentUserId,
        target: target,
        attribute: attribute,
      );
      nukeHistory = [...nukeHistory, event];
      notifyListeners();
    } finally {
      _spendingCoins = false;
    }
  }

  /// Spends `NukeService.curePotionCost` coins to heal
  /// `NukeService.healPerPotion` points of damage off [attribute] on
  /// the local user's own profile — self-only, so unlike `nukeProfile`
  /// this is just a normal profile edit, no other party involved.
  Future<void> cureDamage(String attribute) async {
    if (currentProfile == null || _spendingCoins) return;
    _spendingCoins = true;
    try {
      _repos.nukeService.assertCanCure(balance: wallet.balance);
    } on NukeValidationException catch (error) {
      toast = error.message;
      notifyListeners();
      _spendingCoins = false;
      return;
    }
    try {
      final healedDamage = _repos.nukeService.mergeDamage(
        currentProfile!.nukeDamage,
        attribute,
        NukeService.healPerPotion,
      );
      await _grantCustomCoins(-NukeService.curePotionCost, XpReason.curePotionUsed);
      await updateProfile(currentProfile!.copyWith(nukeDamage: healedDamage));
    } finally {
      _spendingCoins = false;
    }
  }

  Future<void> updatePrivacy(ProfilePrivacy privacy) async {
    final profile = currentProfile;
    if (profile == null) return;
    await updateProfile(profile.copyWith(privacy: privacy));
  }

  Future<void> updateSettings(UserSettings next) async {
    final notificationsJustEnabled = next.notifications && !settings.notifications;
    final notificationsJustDisabled = !next.notifications && settings.notifications;
    settings = next;
    await _repos.settingsRepository.saveSettings(settings);

    if (notificationsJustEnabled) {
      final granted = await _repos.notificationRepository.requestPermission();
      if (granted) {
        await _repos.notificationRepository.scheduleDailyChallengeReminder();
        await _repos.pushNotificationRepository.registerDevice();
      } else {
        settings = settings.copyWith(notifications: false);
        await _repos.settingsRepository.saveSettings(settings);
        toast = 'Notification permission was denied.';
      }
    } else if (notificationsJustDisabled) {
      await _repos.notificationRepository.cancelDailyChallengeReminder();
      await _repos.pushNotificationRepository.unregisterDevice();
    }
    notifyListeners();
  }

  Future<void> blockProfile(UserProfile target) => blockUserId(target.id, displayName: target.displayName);

  Future<void> blockUserId(String userId, {String displayName = 'This user'}) async {
    final moderation = ModerationService();
    if (blockedIds.contains(userId)) return;
    blockedUsers = [
      ...blockedUsers,
      moderation.block(blockerId: currentUserId, blockedUserId: userId),
    ];
    await _repos.settingsRepository.saveBlockedUsers(blockedUsers);
    notifyListeners();
  }

  Future<void> reportProfile(UserProfile target, ReportReason reason) async {
    final moderation = ModerationService();
    reports = [
      ...reports,
      moderation.createReport(
        reporterId: currentUserId,
        targetUserId: target.id,
        reason: reason,
      ),
    ];
    await _repos.settingsRepository.saveReports(reports);
    await blockProfile(target);
  }

  Future<void> addComment(UserProfile profileOwner, String content) async {
    try {
      // Only the current device's own block list is representable in
      // this local single-user model — there's no way for a mock
      // profile to have "blocked" the viewer back.
      _repos.commentService.assertCanComment(
        authorId: currentUserId,
        profileOwnerId: profileOwner.id,
        ownerAllowsComments: profileOwner.privacy.allowComments,
        ownerProfileIsPrivate: profileOwner.privacy.visibility == ProfileVisibility.private,
        isBlockedEitherWay: blockedIds.contains(profileOwner.id),
        authorsRecentComments: _myComments,
      );
      final comment = _repos.commentService.createComment(
        profileOwnerId: profileOwner.id,
        authorId: currentUserId,
        content: content,
      );
      comments = [...comments, comment];
      _myComments = [..._myComments, comment];
      await _repos.commentRepository.saveComments(comments);
      notifyListeners();
    } on CommentValidationException catch (error) {
      toast = error.message;
      notifyListeners();
    }
  }

  Future<void> editComment(String commentId, String newContent) async {
    final existing = comments.firstWhere((c) => c.id == commentId);
    try {
      final updated = _repos.commentService.editComment(existing, currentUserId, newContent);
      comments = [
        for (final comment in comments) comment.id == commentId ? updated : comment,
      ];
      await _repos.commentRepository.saveComments(comments);
      notifyListeners();
    } on CommentValidationException catch (error) {
      toast = error.message;
      notifyListeners();
    }
  }

  Future<void> deleteComment(String commentId) async {
    final existing = comments.firstWhere((c) => c.id == commentId);
    try {
      final deleted = _repos.commentService.deleteComment(existing, currentUserId, existing.profileOwnerId);
      comments = [
        for (final comment in comments) comment.id == commentId ? deleted : comment,
      ];
      await _repos.commentRepository.saveComments(comments);
      notifyListeners();
    } on CommentValidationException catch (error) {
      toast = error.message;
      notifyListeners();
    }
  }

  /// Whether the composer should even be shown — the recipient's own
  /// settings, not viewer-specific blocking (that's enforced at send
  /// time in `sendMessage`).
  bool messagesAllowedFor(UserProfile profile) =>
      profile.privacy.visibility == ProfileVisibility.public && profile.privacy.allowMessages;

  /// This device's own deleted-conversation cutoffs, keyed by the other
  /// participant — see `HiddenConversation`'s doc comment.
  Map<String, DateTime> get _hiddenConversationCutoffs => {
        for (final hidden in hiddenConversations)
          if (hidden.ownerId == currentUserId) hidden.otherUserId: hidden.hiddenAt,
      };

  /// The thread with [otherUserId], oldest first — empty if either side
  /// has blocked the other.
  List<Message> conversationWith(String otherUserId) => _repos.messageService.conversationBetween(
        messages,
        currentUserId,
        otherUserId,
        isBlockedEitherWay: blockedIds.contains(otherUserId),
        hiddenAt: _hiddenConversationCutoffs[otherUserId],
      );

  /// One entry per conversation the local user is part of, most recent
  /// message first.
  List<Message> get conversations => _repos.messageService.latestMessagePerConversation(
        messages,
        currentUserId,
        blockedIds: blockedIds,
        hiddenAtByOtherId: _hiddenConversationCutoffs,
      );

  /// Removes the conversation with [otherUserId] from this device's own
  /// inbox. The other participant's copy is untouched — messages stay
  /// readable to them; only the sender can delete an individual message
  /// (see `deleteMessage`) — so this mirrors WhatsApp/Messenger-style
  /// "delete chat" rather than actually erasing shared data. A message
  /// sent after this point naturally revives the thread.
  Future<void> deleteConversation(String otherUserId) async {
    hiddenConversations = [
      ...hiddenConversations.where((h) => !(h.ownerId == currentUserId && h.otherUserId == otherUserId)),
      HiddenConversation(ownerId: currentUserId, otherUserId: otherUserId, hiddenAt: DateTime.now()),
    ];
    notifyListeners();
    await _repos.settingsRepository.saveHiddenConversations(hiddenConversations);
  }

  int get unreadMessageCount =>
      messages.where((m) => m.recipientId == currentUserId && !m.isRead && !blockedIds.contains(m.senderId)).length;

  Future<void> sendMessage(UserProfile recipient, String content) async {
    try {
      // Only the current device's own block list is representable in
      // this local single-user model — same known gap as addComment.
      _repos.messageService.assertCanMessage(
        senderId: currentUserId,
        recipientId: recipient.id,
        recipientAllowsMessages: recipient.privacy.allowMessages,
        recipientProfileIsPrivate: recipient.privacy.visibility == ProfileVisibility.private,
        isBlockedEitherWay: blockedIds.contains(recipient.id),
        sendersRecentMessages: messages.where((m) => m.senderId == currentUserId).toList(),
      );
      final message = _repos.messageService.createMessage(
        senderId: currentUserId,
        recipientId: recipient.id,
        content: content,
      );
      messages = [...messages, message];
      await _repos.messageRepository.saveMessages(messages);
      notifyListeners();
    } on MessageValidationException catch (error) {
      toast = error.message;
      notifyListeners();
    }
  }

  Future<void> markConversationRead(String otherUserId) async {
    final unreadIds = messages
        .where((m) => m.recipientId == currentUserId && m.senderId == otherUserId && !m.isRead)
        .map((m) => m.id)
        .toSet();
    if (unreadIds.isEmpty) return;
    messages = [
      for (final message in messages) unreadIds.contains(message.id) ? message.copyWith(isRead: true) : message,
    ];
    // Notify immediately, before the network round-trip — the unread
    // dot/badge must clear as soon as this device knows it read the
    // thread, not whenever Firestore's write happens to come back
    // (previously: navigating back out fast enough could still show
    // the old unread state, since nothing had told the UI yet).
    notifyListeners();
    await _repos.messageRepository.saveMessages(messages);
  }

  /// Only the sender can delete their own message — mirrors
  /// `PhotoService.deletePhoto`/`AppController.deleteProfile`'s "you can
  /// always delete your own content" guarantee, extended to messages.
  Future<void> deleteMessage(String messageId) async {
    final message = messages.firstWhere((m) => m.id == messageId);
    if (message.senderId != currentUserId) return;
    messages = messages.where((m) => m.id != messageId).toList();
    await _repos.messageRepository.saveMessages(messages);
    notifyListeners();
  }

  /// Reports [messageId] and blocks its sender — unlike `reportComment`,
  /// blocking here is immediate rather than a separate action: an
  /// abusive DM is a stronger, more direct signal than a public
  /// comment, and blocking also clears the thread from both sides.
  Future<void> reportMessage(String messageId, ReportReason reason) async {
    final message = messages.firstWhere((m) => m.id == messageId);
    final moderation = ModerationService();
    reports = [
      ...reports,
      moderation.createReport(
        reporterId: currentUserId,
        targetUserId: message.senderId,
        targetMessageId: messageId,
        reason: reason,
      ),
    ];
    await _repos.settingsRepository.saveReports(reports);
    await blockUserId(message.senderId);
  }

  /// Whether the composer/Call button should even be shown — mirrors
  /// `messagesAllowedFor`.
  bool callsAllowedFor(UserProfile profile) =>
      profile.privacy.visibility == ProfileVisibility.public && profile.privacy.allowCalls;

  /// Calling requires an existing conversation first (see `CallService`'s
  /// doc comment) — this is the check behind that gate.
  bool hasConversationWith(String otherUserId) => messages.any(
        (m) => (m.senderId == currentUserId && m.recipientId == otherUserId) ||
            (m.senderId == otherUserId && m.recipientId == currentUserId),
      );

  bool get isCallMuted => _repos.callRepository.isMuted;

  Future<void> startCall(UserProfile callee) async {
    try {
      _repos.callService.assertCanCall(
        callerId: currentUserId,
        calleeId: callee.id,
        calleeAllowsCalls: callee.privacy.allowCalls,
        calleeProfileIsPrivate: callee.privacy.visibility == ProfileVisibility.private,
        isBlockedEitherWay: blockedIds.contains(callee.id),
        hasExistingConversation: hasConversationWith(callee.id),
      );
      await _repos.callRepository.startCall(callee.id);
    } on CallValidationException catch (error) {
      toast = error.message;
      notifyListeners();
    }
  }

  Future<void> acceptCall() => _repos.callRepository.acceptCall();

  Future<void> declineCall() => _repos.callRepository.declineCall();

  Future<void> endCall() => _repos.callRepository.endCall();

  Future<void> toggleCallMute() async {
    await _repos.callRepository.toggleMute();
    notifyListeners();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _messagesSubscription?.cancel();
    _foregroundMessagesSubscription?.cancel();
    _notificationTapSubscription?.cancel();
    _openedMessagesSubscription?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  /// Reports [commentId] (never exposes the reporter's identity to the
  /// comment's author) and self-hides it from the reporter's own view —
  /// does NOT block the author, unlike `reportProfile`: the spec lists
  /// Report and Block as separate actions for comments.
  Future<void> reportComment(String commentId, ReportReason reason) async {
    final comment = comments.firstWhere((c) => c.id == commentId);
    final moderation = ModerationService();
    reports = [
      ...reports,
      moderation.createReport(
        reporterId: currentUserId,
        targetUserId: comment.authorId,
        targetCommentId: commentId,
        reason: reason,
      ),
    ];
    await _repos.settingsRepository.saveReports(reports);
    notifyListeners();
  }

  Future<void> blockCommentAuthor(String commentId) async {
    final comment = comments.firstWhere((c) => c.id == commentId);
    UserProfile? author;
    for (final profile in profiles) {
      if (profile.id == comment.authorId) {
        author = profile;
        break;
      }
    }
    await blockUserId(comment.authorId, displayName: author?.displayName ?? 'This user');
  }

  Future<void> toggleReaction(String commentId, CommentReactionType type) async {
    final existing = _repos.commentService.existingReaction(commentReactions, commentId, currentUserId, type);
    if (existing != null) {
      commentReactions = commentReactions.where((r) => r.id != existing.id).toList();
    } else {
      final comment = comments.firstWhere((c) => c.id == commentId);
      commentReactions = [
        ...commentReactions,
        CommentReaction(
          id: _uuid.v4(),
          commentId: commentId,
          profileOwnerId: comment.profileOwnerId,
          userId: currentUserId,
          type: type,
          createdAt: DateTime.now(),
        ),
      ];
    }
    await _repos.commentReactionRepository.saveReactions(commentReactions);
    notifyListeners();
  }

  /// Returns the current unvoted battle if one exists, otherwise
  /// generates, persists, and returns a fresh one. Null if fewer than 2
  /// eligible profiles exist to battle.
  Future<Battle?> ensureBattle() async {
    final existing = pendingBattle;
    if (existing != null) return existing;
    return generateBattle();
  }

  /// Generates a brand-new battle regardless of any existing unvoted
  /// one — used for "Skip" and for explicitly picking a battle type.
  Future<Battle?> generateBattle({BattleType type = BattleType.random}) async {
    final battle = _repos.battleService.generate(
      pool: _battlePool,
      type: type,
      random: Random(),
      preferredCountry: currentProfile?.country,
    );
    if (battle == null) return null;
    battles = [...battles, battle];
    await _repos.battleRepository.saveBattles(battles);
    notifyListeners();
    return battle;
  }

  Future<void> voteBattle(Battle battle, String chosenProfileId) async {
    if (myVoteFor(battle.id) != null) return;
    if (!_repos.battleService.canBattle(battle.profileAId, battle.profileBId)) return;
    final vote = BattleVote(
      id: _uuid.v4(),
      battleId: battle.id,
      voterId: currentUserId,
      chosenProfileId: chosenProfileId,
      createdAt: DateTime.now(),
    );
    battleVotes = [...battleVotes, vote];
    await _repos.battleVoteRepository.saveVotes(battleVotes);
    await _grantXp(XpReason.battleVoted);
    await _grantCoins(XpReason.battleVoted);
    await _checkDailyChallenges();
    notifyListeners();
    await _checkAchievements();
  }

  /// Casts this device's vote for today's "What Would You Choose"
  /// prompt — a no-op if already voted, since a vote is immutable once
  /// cast (see `ChoiceVote`'s doc comment).
  Future<void> submitChoice(ChoiceOption option) async {
    if (myChoiceVoteToday != null) return;
    final question = todaysChoice;
    final vote = ChoiceVote(
      id: '${currentUserId}_${question.id}',
      questionId: question.id,
      voterId: currentUserId,
      chosenOption: option,
      createdAt: DateTime.now(),
    );
    choiceVotes = [...choiceVotes, vote];
    await _repos.choiceRepository.saveVote(vote);
    todaysChoiceTally = await _repos.choiceRepository.loadTally(question.id);
    await _grantXp(XpReason.choiceMade);
    await _grantCoins(XpReason.choiceMade);
    await _checkDailyChallenges();
    notifyListeners();
    await _checkAchievements();
  }

  Future<void> deleteProfile() async {
    if (currentProfile == null) return;
    profiles = profiles.where((item) => item.id != currentProfile!.id).toList();
    currentProfile = null;
    await _repos.profileRepository.deleteCurrentProfile();
    notifyListeners();
  }

  Future<void> resetApp() async {
    await _repos.settingsRepository.resetApp();
    isLoading = true;
    currentProfile = null;
    profiles = [];
    ratings = [];
    photoVotes = [];
    blockedUsers = [];
    hiddenConversations = [];
    reports = [];
    xpTransactions = [];
    unlockedAchievements = [];
    coinTransactions = [];
    cosmeticPurchases = [];
    challengeCompletions = [];
    comments = [];
    messages = [];
    commentReactions = [];
    battles = [];
    battleVotes = [];
    choiceVotes = [];
    todaysChoiceTally = null;
    achievementQueue = [];
    hasSeenOnboarding = false;
    _myComments = [];
    _loadedCommentProfileIds.clear();
    _leaderboardRaw = [];
    _leaderboardCursor = null;
    leaderboardHasMore = true;
    _trendingRaw = [];
    _trendingCursor = null;
    trendingHasMore = true;
    _gapRaw = [];
    _gapCursor = null;
    gapHasMore = true;
    notifyListeners();
    await _load();
  }

  void clearToast() {
    toast = null;
  }

  List<UserProfile> _refreshed(List<UserProfile> list) => [
        for (final profile in list)
          profile.id == currentProfile?.id ? profile : _refreshProfileSummary(profile),
      ];

  void _refreshMockSummaries() {
    profiles = _refreshed(profiles);
    _discoverRaw = _refreshed(_discoverRaw);
  }

  /// Real (Firestore-synced) profiles carry an authoritative,
  /// server-updated `ratingSummary` — the transaction that wrote this
  /// device's own rating already folded it in, so mixing it in again
  /// client-side would double count it. Only mock/seed profiles, which
  /// have no live backend of their own, need that local mixing.
  bool get _ratingsAreRemote => _repos.ratingRepository is RemoteRatingRepository;

  UserProfile _refreshProfileSummary(UserProfile profile) {
    if (_ratingsAreRemote && !profile.id.startsWith('mock_')) return profile;

    final localSummary = _summaryFor(profile.id);
    if (!localSummary.hasRatings) return profile;
    final mixedCount = profile.ratingSummary.count + localSummary.count;
    final mixedAverage = ((profile.ratingSummary.averageOverall *
                profile.ratingSummary.count) +
            (localSummary.averageOverall * localSummary.count)) /
        mixedCount;
    final mixedLook = ((profile.ratingSummary.averageLook *
                profile.ratingSummary.count) +
            (localSummary.averageLook * localSummary.count)) /
        mixedCount;
    return profile.copyWith(
      ratingSummary: RatingSummary(
        averageOverall: mixedAverage,
        averageLook: mixedLook,
        count: mixedCount,
        averageCareer: localSummary.averageCareer == 0
            ? profile.ratingSummary.averageCareer
            : localSummary.averageCareer,
        averageLifestyle: localSummary.averageLifestyle == 0
            ? profile.ratingSummary.averageLifestyle
            : localSummary.averageLifestyle,
        averageSocial: localSummary.averageSocial == 0
            ? profile.ratingSummary.averageSocial
            : localSummary.averageSocial,
        averageIndependence: localSummary.averageIndependence == 0
            ? profile.ratingSummary.averageIndependence
            : localSummary.averageIndependence,
        averageExperiences: localSummary.averageExperiences == 0
            ? profile.ratingSummary.averageExperiences
            : localSummary.averageExperiences,
      ),
    );
  }

  RatingSummary _summaryFor(String profileId) =>
      _repos.ratingService.summaryFor(profileId, ratings);

  void _applyRatingSummary(String profileId) {
    profiles = [
      for (final profile in profiles)
        profile.id == profileId ? _refreshProfileSummary(profile) : profile,
    ];
    if (currentProfile?.id == profileId) {
      currentProfile = profiles.firstWhere((profile) => profile.id == profileId);
    }
  }
}
