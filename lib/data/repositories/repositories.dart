import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../domain/services/achievement_service.dart';
import '../../domain/services/battle_service.dart';
import '../../domain/services/choice_service.dart';
import '../../domain/services/call_service.dart';
import '../../domain/services/comment_service.dart';
import '../../domain/services/cosmetic_service.dart';
import '../../domain/services/daily_challenge_service.dart';
import '../../domain/services/gap_service.dart';
import '../../domain/services/level_service.dart';
import '../../domain/services/message_service.dart';
import '../../domain/services/percentile_service.dart';
import '../../domain/services/photo_quality_service.dart';
import '../../domain/services/photo_service.dart';
import '../../domain/services/photo_vote_service.dart';
import '../../domain/services/profile_service.dart';
import '../../domain/services/progression_service.dart';
import '../../domain/services/rating_service.dart';
import '../../domain/services/reward_service.dart';
import '../../domain/services/streak_service.dart';
import '../../domain/services/trending_service.dart';
import '../mock/mock_profiles.dart';
import '../models/models.dart';

/// A bounded page from a paginated profile feed — never the whole
/// collection. `hasMore` is best-effort (the repository fetches one
/// extra row past `limit` and drops it just to detect this), so a
/// screen knows whether to offer a "load more" affordance.
///
/// A page is filtered by nothing but its sort key server-side —
/// privacy visibility and blocking still have to be applied by the
/// caller (`ProfileService.isVisibleInDiscover`/etc.) the same way
/// they always were, since "not blocked by this specific viewer" and
/// similar per-viewer checks aren't expressible as a Firestore query
/// filter. That can occasionally make one fetched page look sparse
/// after filtering — the fix is to fetch another page, not to treat
/// it as an error.
typedef ProfilesPage = ({List<UserProfile> profiles, bool hasMore});

/// A real vote tally for one "What Would You Choose" prompt.
typedef ChoiceTally = ({int countA, int countB});

abstract class ProfileRepository {
  Future<UserProfile?> loadCurrentProfile();
  Future<void> saveCurrentProfile(UserProfile profile);
  Future<void> deleteCurrentProfile();

  /// A single profile by id — the fallback lookup for a specific,
  /// already-known other user (a message thread, a call, a comment's
  /// author) who may not be in any page currently held in memory.
  /// Never used to build a browsable list.
  Future<UserProfile?> loadProfileById(String id);

  /// Newest-first. Pass the last profile from the previous page as
  /// [after] to continue; omit it for the first page.
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after});

  /// Highest community rating first.
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after});

  /// Newest-first, restricted to profiles created on or after [since]
  /// — `TrendingService` ranks by engagement within whatever page
  /// comes back; this method only bounds and orders the fetch itself.
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since});

  /// Most-rated first — the natural pool for a meaningful algorithm/
  /// community gap (`GapService` already requires a minimum rating
  /// count, so starting from the most-rated profiles surfaces
  /// eligible ones first instead of wasting a page on unrated ones).
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after});

  /// The id a brand-new profile should use. Local-only installs get a
  /// random id; a signed-in install uses its stable account id so the
  /// same person's data lines up across devices.
  String newProfileId();

  /// Records that [profileId] was opened by the current viewer — a
  /// no-op locally (viewing your own mock profiles isn't a meaningful
  /// signal on a single-device install); see `RemoteProfileRepository`
  /// for the real implementation.
  Future<void> recordProfileView(String profileId);
}

abstract class PhotoRepository {
  Future<ProfilePhoto> pickAndStorePhoto({
    required String ownerId,
    required ImageSource source,
    required int order,
    String category = 'Lifestyle',
  });

  /// Raw bytes of a real, previously-stored photo — for on-device photo
  /// QUALITY analysis (see `PhotoQualityService`), never anything else.
  /// Null for a photo this repository can't read back (a mock/seed demo
  /// photo, a missing local file, a failed remote fetch).
  Future<Uint8List?> readPhotoBytes(ProfilePhoto photo);
}

abstract class RatingRepository {
  Future<List<Rating>> loadRatings();
  Future<void> saveRatings(List<Rating> ratings);
}

abstract class PhotoVoteRepository {
  Future<List<PhotoVote>> loadVotes();
  Future<void> saveVotes(List<PhotoVote> votes);
}

abstract class ProgressionRepository {
  Future<List<XpTransaction>> loadXpTransactions();
  Future<void> saveXpTransactions(List<XpTransaction> transactions);
}

/// Just the set of calendar days this device's user has ever opened the
/// app on — separate from [ProgressionRepository], since an app open
/// doesn't earn XP but still counts toward the day streak (matching the
/// habit-app convention of Duolingo/Snapchat-style streaks: showing up
/// keeps it alive, not only earning points).
abstract class AppOpenRepository {
  Future<Set<DateTime>> loadOpenDays();
  Future<void> recordOpenDay(DateTime day);
}

abstract class AchievementRepository {
  Future<List<UserAchievement>> loadAchievements();
  Future<void> saveAchievements(List<UserAchievement> achievements);
}

abstract class CoinRepository {
  Future<List<CoinTransaction>> loadCoinTransactions();
  Future<void> saveCoinTransactions(List<CoinTransaction> transactions);
}

abstract class CosmeticRepository {
  Future<List<CosmeticPurchase>> loadPurchases();
  Future<void> savePurchases(List<CosmeticPurchase> purchases);
}

abstract class ChallengeRepository {
  Future<List<ChallengeCompletion>> loadChallengeCompletions();
  Future<void> saveChallengeCompletions(List<ChallengeCompletion> completions);
}

abstract class CommentRepository {
  /// Comments on one profile — never the whole collection. Callers
  /// accumulate results across the profiles actually viewed this
  /// session rather than holding the universe of every comment ever
  /// posted (see `AppController.ensureCommentsLoaded`).
  Future<List<Comment>> loadCommentsForProfile(String profileOwnerId);

  /// This device's own authored comments, across all profiles — the
  /// one thing that genuinely needs a cross-profile view, and it's
  /// naturally bounded the same way ratings/XP are (scoped to one
  /// owner), used only for `MessageService`-style rate limiting.
  Future<List<Comment>> loadCommentsByAuthor(String authorId);

  Future<void> saveComments(List<Comment> comments);
}

abstract class MessageRepository {
  /// Every message this device's user is a participant in, across all
  /// conversations — never the whole collection (messages are private).
  Future<List<Message>> loadMessages();

  /// Same scope as [loadMessages], but live — an incoming message has
  /// to appear without the recipient manually reopening the app, the
  /// same reasoning `CallRepository.currentCall` already uses.
  Stream<List<Message>> watchMessages();

  Future<void> saveMessages(List<Message> messages);
}

/// Signaling + local WebRTC session lifecycle for 1:1 audio calls,
/// combined rather than layered — the media session and the channel
/// that negotiates it are too tightly coupled to usefully separate for
/// an MVP. Audio only: no camera, no video track, ever.
///
/// Foreground-only — there's no CallKit-style background service here,
/// so a call drops if the app leaves the foreground. Reasonable for an
/// MVP; a real always-reachable calling experience needs platform-level
/// work well beyond this.
abstract class CallRepository {
  /// The call session this user is currently part of — incoming,
  /// outgoing, or active — or null when there's none. Screens drive
  /// their state entirely off this stream.
  Stream<CallSession?> get currentCall;

  bool get isMuted;

  Future<void> startCall(String calleeId);
  Future<void> acceptCall();
  Future<void> declineCall();
  Future<void> endCall();
  Future<void> toggleMute();
}

abstract class CommentReactionRepository {
  /// Reactions on one profile's comments — same scoping reasoning as
  /// `CommentRepository.loadCommentsForProfile`.
  Future<List<CommentReaction>> loadReactionsForProfile(String profileOwnerId);
  Future<void> saveReactions(List<CommentReaction> reactions);
}

abstract class BattleRepository {
  Future<List<Battle>> loadBattles();
  Future<void> saveBattles(List<Battle> battles);
}

abstract class BattleVoteRepository {
  Future<List<BattleVote>> loadVotes();
  Future<void> saveVotes(List<BattleVote> votes);
}

abstract class ChoiceRepository {
  /// This device's own votes, across every question ever answered.
  Future<List<ChoiceVote>> loadMyVotes();

  /// Saves [vote] and bumps its question's real, shared tally. Callers
  /// must not call this twice for the same (voterId, questionId) — a
  /// vote is immutable once cast — `AppController.submitChoice` already
  /// guards this in-memory before ever reaching here.
  Future<void> saveVote(ChoiceVote vote);

  /// The real, shared tally for [questionId] — everyone's picks, not
  /// just this device's own.
  Future<ChoiceTally> loadTally(String questionId);
}

abstract class SettingsRepository {
  Future<bool> hasSeenOnboarding();
  Future<void> setOnboardingSeen(bool value);
  Future<UserSettings> loadSettings();
  Future<void> saveSettings(UserSettings settings);
  Future<List<BlockedUser>> loadBlockedUsers();
  Future<void> saveBlockedUsers(List<BlockedUser> blocked);
  Future<List<Report>> loadReports();
  Future<void> saveReports(List<Report> reports);
  Future<List<HiddenConversation>> loadHiddenConversations();
  Future<void> saveHiddenConversations(List<HiddenConversation> hidden);
  Future<void> resetApp();
}

/// Real, OS-level notifications (Android notification tray), not an
/// in-app-only notification center. Entirely local/on-device — no
/// server, no Firebase Cloud Messaging — since daily-challenge state is
/// already local-first data with nothing server-side to push from.
abstract class NotificationRepository {
  /// Android 13+ requires this at runtime before any notification can
  /// show; a no-op returning true on platforms/versions that don't
  /// need it.
  Future<bool> requestPermission();

  Future<void> scheduleDailyChallengeReminder();

  Future<void> cancelDailyChallengeReminder();
}

class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _dailyChallengeNotificationId = 1001;
  static const _channelId = 'daily_challenges';
  static const _channelName = 'Daily Challenges';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    return await androidPlugin.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleDailyChallengeReminder() async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      _dailyChallengeNotificationId,
      "Today's challenges are waiting",
      'Rate a few lives and keep your streak going.',
      _nextInstanceOf(hour: 19, minute: 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'A daily reminder to complete your challenges.',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDailyChallengeReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(_dailyChallengeNotificationId);
  }

  /// Built from plain `DateTime.now()` (already device-local — Dart
  /// gets that from the OS natively) rather than `tz.TZDateTime.now
  /// (tz.local)`. `tz.local` defaults to UTC until something calls
  /// `tz.setLocalLocation`, which nothing in this app does — no
  /// dependency here resolves the device's actual IANA timezone name,
  /// and adding one just for this one call site isn't worth it. Wrapping
  /// the already-correct local instant as a `TZDateTime` in `tz.UTC`
  /// (always available, no `setLocalLocation` needed) sidesteps the
  /// bug entirely: the *absolute moment* is right regardless of which
  /// location object carries it. The tradeoff — a `matchDateTimeComponents:
  /// DateTimeComponents.time` daily repeat could drift by the DST delta
  /// across a transition — self-corrects anyway, since `AppController
  /// ._load()` recomputes and reschedules this fresh on every app launch.
  tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.UTC);
  }
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const _currentProfileKey = 'currentProfile';
  final Uuid _uuid;

  @override
  Future<UserProfile?> loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentProfileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_currentProfileKey);
      return null;
    }
  }

  @override
  Future<void> saveCurrentProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> deleteCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentProfileKey);
  }

  @override
  Future<UserProfile?> loadProfileById(String id) async =>
      buildMockProfiles().where((p) => p.id == id).firstOrNull;

  /// The mock seed is small and static — no real pagination needed,
  /// just the same sort-then-slice every `Remote*` page uses so the
  /// two behave identically from the caller's point of view.
  ProfilesPage _page(List<UserProfile> sorted, int limit, UserProfile? after) {
    var start = 0;
    if (after != null) {
      final index = sorted.indexWhere((p) => p.id == after.id);
      start = index == -1 ? sorted.length : index + 1;
    }
    final slice = sorted.skip(start).take(limit).toList();
    return (profiles: slice, hasMore: start + slice.length < sorted.length);
  }

  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async {
    final sorted = buildMockProfiles().toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _page(sorted, limit, after);
  }

  @override
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after}) async {
    final sorted = buildMockProfiles().toList()
      ..sort((a, b) => b.ratingSummary.averageOverall.compareTo(a.ratingSummary.averageOverall));
    return _page(sorted, limit, after);
  }

  @override
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since}) async {
    final sorted = buildMockProfiles().where((p) => !p.createdAt.isBefore(since)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _page(sorted, limit, after);
  }

  @override
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after}) async {
    final sorted = buildMockProfiles().toList()
      ..sort((a, b) => b.ratingSummary.count.compareTo(a.ratingSummary.count));
    return _page(sorted, limit, after);
  }

  @override
  String newProfileId() => 'user_${_uuid.v4()}';

  @override
  Future<void> recordProfileView(String profileId) async {}
}

/// Firestore-backed profile storage for a signed-in (anonymous) device,
/// so the same person's profile is reachable from other devices/other
/// users' Discover feeds. Income/savings/investments/debt/expenses are
/// split into separate subdocuments so Firestore security rules (which
/// can only grant or deny a whole document, not individual fields) can
/// enforce "never leaks unless the owner opted in" server-side — not
/// just hidden by the client, which a bypassing client couldn't be
/// trusted to respect.
class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _financeExtraKeys = {'investments', 'debt', 'monthlyExpenses'};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteProfileRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) => _firestore.collection('profiles').doc(uid);

  @override
  String newProfileId() => _uid;

  @override
  Future<UserProfile?> loadCurrentProfile() => _loadProfile(_uid);

  Future<UserProfile?> _loadProfile(String uid) async {
    final doc = await _profileDoc(uid).get();
    final publicData = doc.data();
    if (publicData == null) return null;

    final merged = Map<String, dynamic>.from(publicData);
    for (final subdocId in const ['income', 'savings', 'financeExtra']) {
      try {
        final snapshot = await _profileDoc(uid).collection('private').doc(subdocId).get();
        final data = snapshot.data();
        if (data != null) merged.addAll(data);
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') rethrow;
      }
    }
    return UserProfile.fromJson(merged);
  }

  @override
  Future<void> saveCurrentProfile(UserProfile profile) async {
    final json = profile.toJson();
    final financeExtra = {for (final key in _financeExtraKeys) key: json.remove(key)};
    final income = {'monthlyIncome': json.remove('monthlyIncome')};
    final savings = {'savings': json.remove('savings')};
    // Server-maintained fields — updated only by other devices' own
    // actions (a rater's transaction, a viewer's increment), never by
    // this device's own profile edits. Must not be written here at
    // all: a plain (non-merging) `set()` with these keys present would
    // blast a live value back down to this device's possibly-stale
    // local cache; omitting them + merge:true leaves them untouched.
    json.remove('ratingSummary');
    json.remove('viewCount');

    final batch = _firestore.batch();
    final doc = _profileDoc(_uid);
    batch.set(doc, json, SetOptions(merge: true));
    batch.set(doc.collection('private').doc('income'), income);
    batch.set(doc.collection('private').doc('savings'), savings);
    batch.set(doc.collection('private').doc('financeExtra'), financeExtra);
    await batch.commit();
  }

  /// Increments the target profile's view count by one. Server-side
  /// only — there is no per-viewer record anywhere (see `viewCount`'s
  /// doc comment on `UserProfile`), so unlike ratings there is no
  /// identity to protect, just a running total. No-ops for a self-view
  /// or a mock profile (no real Firestore doc to update).
  @override
  Future<void> recordProfileView(String profileId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid == profileId) return;
    final doc = _profileDoc(profileId);
    final snapshot = await doc.get();
    if (!snapshot.exists) return;
    await doc.update({'viewCount': FieldValue.increment(1)});
  }

  @override
  Future<void> deleteCurrentProfile() async {
    final doc = _profileDoc(_uid);
    final batch = _firestore.batch();
    batch.delete(doc.collection('private').doc('income'));
    batch.delete(doc.collection('private').doc('savings'));
    batch.delete(doc.collection('private').doc('financeExtra'));
    batch.delete(doc);
    await batch.commit();
  }

  @override
  Future<UserProfile?> loadProfileById(String id) => _loadProfile(id);

  CollectionReference<Map<String, dynamic>> get _profiles => _firestore.collection('profiles');

  /// Card/list rendering never shows income/savings/etc (see
  /// `ProfilesPage`'s doc comment on why pages skip the private-subdoc
  /// merge `_loadProfile` does) — `UserProfile.fromJson` already
  /// defaults those fields to 0 when absent, so this is safe as long
  /// as nothing renders a page profile the way `PublicProfileScreen`
  /// renders a `loadProfileById` one.
  ProfilesPage _pageFrom(QuerySnapshot<Map<String, dynamic>> snapshot, int limit) {
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final page = (hasMore ? docs.sublist(0, limit) : docs).map((doc) => UserProfile.fromJson(doc.data())).toList();
    return (profiles: page, hasMore: hasMore);
  }

  /// The static seed cast, mixed into the first page only — real users
  /// and mock flavor content coexist rather than one replacing the
  /// other (see `docs/FEATURE_STATUS.md`), but the seed is small and
  /// fixed so there's no reason to re-append it on every later page.
  List<UserProfile> _withSeedOnFirstPage(List<UserProfile> page, UserProfile? after) =>
      after == null ? [...page, ...buildMockProfiles()] : page;

  /// Cursors by document, not raw field values — more robust than
  /// `startAfter([value])` against ties/precision, and the only form
  /// that behaves correctly with a descending `orderBy` under
  /// `fake_cloud_firestore` (the test double this is verified against).
  Future<Query<Map<String, dynamic>>> _afterCursor(Query<Map<String, dynamic>> query, UserProfile? after) async {
    if (after == null) return query;
    final doc = await _profileDoc(after.id).get();
    return doc.exists ? query.startAfterDocument(doc) : query;
  }

  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async {
    var query = _profiles.orderBy('createdAt', descending: true).limit(limit + 1);
    query = await _afterCursor(query, after);
    final result = _pageFrom(await query.get(), limit);
    return (profiles: _withSeedOnFirstPage(result.profiles, after), hasMore: result.hasMore);
  }

  @override
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after}) async {
    var query = _profiles.orderBy('ratingSummary.averageOverall', descending: true).limit(limit + 1);
    query = await _afterCursor(query, after);
    final result = _pageFrom(await query.get(), limit);
    return (profiles: _withSeedOnFirstPage(result.profiles, after), hasMore: result.hasMore);
  }

  @override
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since}) async {
    var query = _profiles
        .where('createdAt', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('createdAt', descending: true)
        .limit(limit + 1);
    query = await _afterCursor(query, after);
    return _pageFrom(await query.get(), limit);
  }

  @override
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after}) async {
    var query = _profiles.orderBy('ratingSummary.count', descending: true).limit(limit + 1);
    query = await _afterCursor(query, after);
    final result = _pageFrom(await query.get(), limit);
    return (profiles: _withSeedOnFirstPage(result.profiles, after), hasMore: result.hasMore);
  }
}

class LocalPhotoRepository implements PhotoRepository {
  LocalPhotoRepository({
    ImagePicker? picker,
    Uuid? uuid,
  })  : _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  final ImagePicker _picker;
  final Uuid _uuid;

  @override
  Future<ProfilePhoto> pickAndStorePhoto({
    required String ownerId,
    required ImageSource source,
    required int order,
    String category = 'Lifestyle',
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1800,
    );
    if (picked == null) {
      throw Exception('No photo selected.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/profile_photos/$ownerId');
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }
    final id = _uuid.v4();
    final extension = picked.path.split('.').last.toLowerCase();
    final path = '${photosDir.path}/$id.$extension';
    await File(picked.path).copy(path);
    return ProfilePhoto(
      id: id,
      ownerId: ownerId,
      path: path,
      thumbnailPath: path,
      isProfilePhoto: order == 0,
      order: order,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Uint8List?> readPhotoBytes(ProfilePhoto photo) async {
    final path = photo.path;
    if (path.startsWith('assets/') || path.startsWith('mock://')) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }
}

/// Uploads the picked photo to Firebase Storage under the owner's own
/// folder and stores its public download URL as `ProfilePhoto.path` —
/// so `ProfileImage` (see `presentation/widgets/widgets.dart`) can load
/// it with `Image.network` from any device, not just the one that
/// took it.
class RemotePhotoRepository implements PhotoRepository {
  RemotePhotoRepository({ImagePicker? picker, Uuid? uuid, FirebaseStorage? storage})
      : _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid(),
        _storage = storage ?? FirebaseStorage.instance;

  final ImagePicker _picker;
  final Uuid _uuid;
  final FirebaseStorage _storage;

  @override
  Future<ProfilePhoto> pickAndStorePhoto({
    required String ownerId,
    required ImageSource source,
    required int order,
    String category = 'Lifestyle',
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1800,
    );
    if (picked == null) {
      throw Exception('No photo selected.');
    }

    final id = _uuid.v4();
    final extension = picked.path.split('.').last.toLowerCase();
    final ref = _storage.ref('profile_photos/$ownerId/$id.$extension');
    await ref.putFile(
      File(picked.path),
      SettableMetadata(contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}'),
    );
    final url = await ref.getDownloadURL();

    return ProfilePhoto(
      id: id,
      ownerId: ownerId,
      path: url,
      thumbnailPath: url,
      isProfilePhoto: order == 0,
      order: order,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Uint8List?> readPhotoBytes(ProfilePhoto photo) async {
    final path = photo.path;
    if (!path.startsWith('http://') && !path.startsWith('https://')) return null;
    try {
      return await _storage.refFromURL(path).getData(10 * 1024 * 1024);
    } on FirebaseException {
      return null;
    }
  }
}

class LocalRatingRepository implements RatingRepository {
  static const _ratingsKey = 'ratings';

  @override
  Future<List<Rating>> loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ratingsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => Rating.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove(_ratingsKey);
      return [];
    }
  }

  @override
  Future<void> saveRatings(List<Rating> ratings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ratingsKey,
      jsonEncode(ratings.map((rating) => rating.toJson()).toList()),
    );
  }
}

class LocalPhotoVoteRepository implements PhotoVoteRepository {
  static const _votesKey = 'photo_votes';

  @override
  Future<List<PhotoVote>> loadVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_votesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => PhotoVote.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      await prefs.remove(_votesKey);
      return [];
    }
  }

  @override
  Future<void> saveVotes(List<PhotoVote> votes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_votesKey, jsonEncode(votes.map((vote) => vote.toJson()).toList()));
  }
}

/// Firestore-backed ratings for a signed-in device. Individual rating
/// documents are readable only by the rater who wrote them (enforced
/// by security rules) — nobody, including the profile owner, can read
/// who rated a profile or an individual score. Public visibility is
/// only ever the aggregate on `profiles/{id}.ratingSummary`, kept
/// current via a transaction run by the rater's own device whenever it
/// submits, edits, or removes its own rating.
///
/// `RatingRepository.saveRatings` takes the whole current-device rating
/// list (mirroring `LocalRatingRepository`'s single-blob-overwrite
/// shape), so this repository diffs each call against what it last
/// saw to find the one rating that actually changed, rather than
/// rewriting every rating this device has ever given.
class RemoteRatingRepository implements RatingRepository {
  RemoteRatingRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// This device's own ratings as of the last load/save, keyed by
  /// profileId — used only to detect which single rating changed in
  /// the next `saveRatings` call.
  Map<String, Rating> _lastKnownOwn = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteRatingRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _ratingsCollection => _firestore.collection('ratings');

  DocumentReference<Map<String, dynamic>> _profileDoc(String id) => _firestore.collection('profiles').doc(id);

  @override
  Future<List<Rating>> loadRatings() async {
    final snapshot = await _ratingsCollection.where('raterId', isEqualTo: _uid).get();
    final own = snapshot.docs.map((doc) => Rating.fromJson(doc.data())).toList();
    _lastKnownOwn = {for (final rating in own) rating.profileId: rating};
    return own;
  }

  @override
  Future<void> saveRatings(List<Rating> ratings) async {
    final uid = _uid;
    final ownNow = {for (final rating in ratings.where((r) => r.raterId == uid)) rating.profileId: rating};

    for (final entry in ownNow.entries) {
      final before = _lastKnownOwn[entry.key];
      if (before == null || !_sameScores(before, entry.value)) {
        await _upsertRatingAndSummary(entry.value);
      }
    }
    for (final profileId in _lastKnownOwn.keys.toSet().difference(ownNow.keys.toSet())) {
      await _removeRatingAndSummary(raterId: uid, profileId: profileId);
    }

    _lastKnownOwn = ownNow;
  }

  bool _sameScores(Rating a, Rating b) =>
      a.overall == b.overall &&
      a.look == b.look &&
      a.career == b.career &&
      a.lifestyle == b.lifestyle &&
      a.social == b.social &&
      a.independence == b.independence &&
      a.experiences == b.experiences;

  Future<void> _upsertRatingAndSummary(Rating rating) async {
    final ratingRef = _ratingsCollection.doc('${rating.raterId}_${rating.profileId}');
    final profileRef = _profileDoc(rating.profileId);

    await _firestore.runTransaction((transaction) async {
      final existingRatingSnapshot = await transaction.get(ratingRef);
      final profileSnapshot = await transaction.get(profileRef);

      final previous = existingRatingSnapshot.data() == null ? null : Rating.fromJson(existingRatingSnapshot.data()!);

      // No profile doc means the target is static seed/mock content,
      // not a real synced profile — nothing to update there.
      if (profileSnapshot.exists) {
        final current = RatingSummary.fromJson(profileSnapshot.data()?['ratingSummary'] as Map<String, dynamic>?);
        final updated = _blendSummary(current, previous: previous, next: rating);
        transaction.update(profileRef, {'ratingSummary': updated.toJson()});
      }
      transaction.set(ratingRef, rating.toJson());
    });
  }

  Future<void> _removeRatingAndSummary({required String raterId, required String profileId}) async {
    final ratingRef = _ratingsCollection.doc('${raterId}_$profileId');
    final profileRef = _profileDoc(profileId);

    await _firestore.runTransaction((transaction) async {
      final existingRatingSnapshot = await transaction.get(ratingRef);
      if (existingRatingSnapshot.data() == null) return;
      final previous = Rating.fromJson(existingRatingSnapshot.data()!);

      final profileSnapshot = await transaction.get(profileRef);
      if (profileSnapshot.exists) {
        final current = RatingSummary.fromJson(profileSnapshot.data()?['ratingSummary'] as Map<String, dynamic>?);
        final updated = _blendSummary(current, previous: previous, next: null);
        transaction.update(profileRef, {'ratingSummary': updated.toJson()});
      }
      transaction.delete(ratingRef);
    });
  }

  /// Folds [next] into [current] having first un-folded [previous] (if
  /// this is an edit/removal, not a fresh rating) — an incremental
  /// running average, so this device never needs to read anyone else's
  /// individual rating to keep the public aggregate correct.
  ///
  /// Assumes every dimension of a rating is filled in together (true
  /// for every rating `AppController.submitRating` creates), so one
  /// shared `count` is a valid denominator for all of them — this
  /// deliberately doesn't replicate `RatingService.summaryFor`'s more
  /// general per-dimension counting, which only matters for partially
  /// filled ratings this app's own UI never produces.
  RatingSummary _blendSummary(RatingSummary current, {required Rating? previous, required Rating? next}) {
    var count = current.count;
    if (previous == null && next != null) count += 1;
    if (previous != null && next == null) count -= 1;
    if (count < 0) count = 0;
    final resolvedCount = count;

    double blend(double currentAverage, int? previousValue, int? nextValue) {
      if (resolvedCount == 0) return 0;
      final sum = currentAverage * current.count - (previousValue ?? 0) + (nextValue ?? 0);
      return sum / resolvedCount;
    }

    return RatingSummary(
      averageOverall: blend(current.averageOverall, previous?.overall, next?.overall),
      averageLook: blend(current.averageLook, previous?.look, next?.look),
      count: resolvedCount,
      averageCareer: blend(current.averageCareer ?? 0, previous?.career, next?.career),
      averageLifestyle: blend(current.averageLifestyle ?? 0, previous?.lifestyle, next?.lifestyle),
      averageSocial: blend(current.averageSocial ?? 0, previous?.social, next?.social),
      averageIndependence: blend(current.averageIndependence ?? 0, previous?.independence, next?.independence),
      averageExperiences: blend(current.averageExperiences ?? 0, previous?.experiences, next?.experiences),
    );
  }
}

/// Firestore-backed "best photo" votes for a signed-in device — same
/// anonymity shape as [RemoteRatingRepository]: individual votes stay
/// private to the voter, and the public signal is only ever the
/// `photoVoteCounts` aggregate on the target profile, kept current via
/// a transaction run by the voter's own device.
class RemotePhotoVoteRepository implements PhotoVoteRepository {
  RemotePhotoVoteRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// This device's own votes as of the last load/save, keyed by
  /// profileId — used only to detect which single vote changed in the
  /// next `saveVotes` call.
  Map<String, PhotoVote> _lastKnownOwn = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemotePhotoVoteRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _votesCollection => _firestore.collection('photoVotes');

  DocumentReference<Map<String, dynamic>> _profileDoc(String id) => _firestore.collection('profiles').doc(id);

  @override
  Future<List<PhotoVote>> loadVotes() async {
    final snapshot = await _votesCollection.where('voterId', isEqualTo: _uid).get();
    final own = snapshot.docs.map((doc) => PhotoVote.fromJson(doc.data())).toList();
    _lastKnownOwn = {for (final vote in own) vote.profileId: vote};
    return own;
  }

  @override
  Future<void> saveVotes(List<PhotoVote> votes) async {
    final uid = _uid;
    final ownNow = {for (final vote in votes.where((v) => v.voterId == uid)) vote.profileId: vote};

    for (final entry in ownNow.entries) {
      final before = _lastKnownOwn[entry.key];
      if (before == null || before.photoId != entry.value.photoId) {
        await _upsertVoteAndCounts(entry.value, previous: before);
      }
    }

    _lastKnownOwn = ownNow;
  }

  Future<void> _upsertVoteAndCounts(PhotoVote vote, {required PhotoVote? previous}) async {
    final voteRef = _votesCollection.doc('${vote.voterId}_${vote.profileId}');
    final profileRef = _profileDoc(vote.profileId);

    await _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(profileRef);

      // No profile doc means the target is static seed/mock content,
      // not a real synced profile — nothing to update there.
      if (profileSnapshot.exists) {
        final counts = Map<String, int>.from((profileSnapshot.data()?['photoVoteCounts'] as Map?) ?? const {});
        if (previous != null && previous.photoId != vote.photoId) {
          final currentCount = counts[previous.photoId] ?? 1;
          counts[previous.photoId] = currentCount > 0 ? currentCount - 1 : 0;
        }
        counts[vote.photoId] = (counts[vote.photoId] ?? 0) + 1;
        transaction.update(profileRef, {'photoVoteCounts': counts});
      }
      transaction.set(voteRef, vote.toJson());
    });
  }
}

class LocalProgressionRepository implements ProgressionRepository {
  static const _xpKey = 'xp_transactions';

  @override
  Future<List<XpTransaction>> loadXpTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_xpKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => XpTransaction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove(_xpKey);
      return [];
    }
  }

  @override
  Future<void> saveXpTransactions(List<XpTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _xpKey,
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }
}

class LocalAppOpenRepository implements AppOpenRepository {
  static const _openDaysKey = 'app_open_days';

  @override
  Future<Set<DateTime>> loadOpenDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_openDaysKey) ?? [];
    return raw.map(DateTime.parse).toSet();
  }

  @override
  Future<void> recordOpenDay(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final days = (prefs.getStringList(_openDaysKey) ?? []).toSet();
    if (days.add(day.toIso8601String())) {
      await prefs.setStringList(_openDaysKey, days.toList());
    }
  }
}

class LocalAchievementRepository implements AchievementRepository {
  static const _achievementsKey = 'user_achievements';

  @override
  Future<List<UserAchievement>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_achievementsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => UserAchievement.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove(_achievementsKey);
      return [];
    }
  }

  @override
  Future<void> saveAchievements(List<UserAchievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _achievementsKey,
      jsonEncode(achievements.map((item) => item.toJson()).toList()),
    );
  }
}

class LocalCoinRepository implements CoinRepository {
  static const _coinsKey = 'coin_transactions';

  @override
  Future<List<CoinTransaction>> loadCoinTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_coinsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => CoinTransaction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove(_coinsKey);
      return [];
    }
  }

  @override
  Future<void> saveCoinTransactions(List<CoinTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _coinsKey,
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }
}

class LocalCosmeticRepository implements CosmeticRepository {
  static const _cosmeticsKey = 'cosmetic_purchases';

  @override
  Future<List<CosmeticPurchase>> loadPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cosmeticsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => CosmeticPurchase.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove(_cosmeticsKey);
      return [];
    }
  }

  @override
  Future<void> savePurchases(List<CosmeticPurchase> purchases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cosmeticsKey,
      jsonEncode(purchases.map((item) => item.toJson()).toList()),
    );
  }
}

class LocalChallengeRepository implements ChallengeRepository {
  static const _challengesKey = 'challenge_completions';

  @override
  Future<List<ChallengeCompletion>> loadChallengeCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_challengesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => ChallengeCompletion.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove(_challengesKey);
      return [];
    }
  }

  @override
  Future<void> saveChallengeCompletions(List<ChallengeCompletion> completions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _challengesKey,
      jsonEncode(completions.map((item) => item.toJson()).toList()),
    );
  }
}

/// XP/coins/achievements/daily-challenge completions are all personal
/// progression logs — same own-device-only, additions-only shape as
/// `RemoteBattleRepository`: nobody but the earner ever reads them, and
/// nothing here is ever edited or removed by the app's own flows.
class RemoteProgressionRepository implements ProgressionRepository {
  RemoteProgressionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('RemoteProgressionRepository used without a signed-in Firebase user.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('xpTransactions');

  @override
  Future<List<XpTransaction>> loadXpTransactions() async {
    final snapshot = await _collection.where('profileId', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => XpTransaction.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((tx) => tx.id).toSet();
    return all;
  }

  @override
  Future<void> saveXpTransactions(List<XpTransaction> transactions) async {
    for (final tx in transactions) {
      if (_lastKnownIds.contains(tx.id)) continue;
      await _collection.doc(tx.id).set(tx.toJson());
    }
    _lastKnownIds = transactions.map((tx) => tx.id).toSet();
  }
}

/// One small document per user (`appOpens/{uid}`) rather than a growing
/// collection like [RemoteProgressionRepository]'s — there's nothing
/// per-open worth keeping beyond "did this day happen," so a single
/// `arrayUnion`ed field is both cheaper and simpler than one doc per day.
class RemoteAppOpenRepository implements AppOpenRepository {
  RemoteAppOpenRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('RemoteAppOpenRepository used without a signed-in Firebase user.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore.collection('appOpens').doc(_uid);

  @override
  Future<Set<DateTime>> loadOpenDays() async {
    final snapshot = await _doc.get();
    final raw = (snapshot.data()?['days'] as List<dynamic>?) ?? [];
    return raw.map((item) => DateTime.parse(item as String)).toSet();
  }

  @override
  Future<void> recordOpenDay(DateTime day) async {
    await _doc.set({
      'days': FieldValue.arrayUnion([day.toIso8601String()]),
    }, SetOptions(merge: true));
  }
}

class RemoteAchievementRepository implements AchievementRepository {
  RemoteAchievementRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('RemoteAchievementRepository used without a signed-in Firebase user.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('userAchievements');

  @override
  Future<List<UserAchievement>> loadAchievements() async {
    final snapshot = await _collection.where('profileId', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => UserAchievement.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((a) => a.id).toSet();
    return all;
  }

  @override
  Future<void> saveAchievements(List<UserAchievement> achievements) async {
    for (final achievement in achievements) {
      if (_lastKnownIds.contains(achievement.id)) continue;
      await _collection.doc(achievement.id).set(achievement.toJson());
    }
    _lastKnownIds = achievements.map((a) => a.id).toSet();
  }
}

class RemoteCosmeticRepository implements CosmeticRepository {
  RemoteCosmeticRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('RemoteCosmeticRepository used without a signed-in Firebase user.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('cosmeticPurchases');

  @override
  Future<List<CosmeticPurchase>> loadPurchases() async {
    final snapshot = await _collection.where('profileId', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => CosmeticPurchase.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((p) => p.id).toSet();
    return all;
  }

  @override
  Future<void> savePurchases(List<CosmeticPurchase> purchases) async {
    for (final purchase in purchases) {
      if (_lastKnownIds.contains(purchase.id)) continue;
      await _collection.doc(purchase.id).set(purchase.toJson());
    }
    _lastKnownIds = purchases.map((p) => p.id).toSet();
  }
}

class RemoteCoinRepository implements CoinRepository {
  RemoteCoinRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('RemoteCoinRepository used without a signed-in Firebase user.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('coinTransactions');

  @override
  Future<List<CoinTransaction>> loadCoinTransactions() async {
    final snapshot = await _collection.where('profileId', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => CoinTransaction.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((tx) => tx.id).toSet();
    return all;
  }

  @override
  Future<void> saveCoinTransactions(List<CoinTransaction> transactions) async {
    for (final tx in transactions) {
      if (_lastKnownIds.contains(tx.id)) continue;
      await _collection.doc(tx.id).set(tx.toJson());
    }
    _lastKnownIds = transactions.map((tx) => tx.id).toSet();
  }
}

class RemoteChallengeRepository implements ChallengeRepository {
  RemoteChallengeRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('RemoteChallengeRepository used without a signed-in Firebase user.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('challengeCompletions');

  @override
  Future<List<ChallengeCompletion>> loadChallengeCompletions() async {
    final snapshot = await _collection.where('profileId', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => ChallengeCompletion.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((c) => c.id).toSet();
    return all;
  }

  @override
  Future<void> saveChallengeCompletions(List<ChallengeCompletion> completions) async {
    for (final completion in completions) {
      if (_lastKnownIds.contains(completion.id)) continue;
      await _collection.doc(completion.id).set(completion.toJson());
    }
    _lastKnownIds = completions.map((c) => c.id).toSet();
  }
}

class LocalCommentRepository implements CommentRepository {
  static const _commentsKey = 'comments';

  Future<List<Comment>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_commentsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => Comment.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      await prefs.remove(_commentsKey);
      return [];
    }
  }

  /// Single-device local storage is already small and bounded — no
  /// scale concern loading everything and filtering in memory, unlike
  /// `RemoteCommentRepository` which has to scope the actual query.
  @override
  Future<List<Comment>> loadCommentsForProfile(String profileOwnerId) async =>
      (await _loadAll()).where((c) => c.profileOwnerId == profileOwnerId).toList();

  @override
  Future<List<Comment>> loadCommentsByAuthor(String authorId) async =>
      (await _loadAll()).where((c) => c.authorId == authorId).toList();

  @override
  Future<void> saveComments(List<Comment> comments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _commentsKey,
      jsonEncode(comments.map((item) => item.toJson()).toList()),
    );
  }
}

class LocalMessageRepository implements MessageRepository {
  static const _messagesKey = 'messages';

  @override
  Future<List<Message>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => Message.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      await prefs.remove(_messagesKey);
      return [];
    }
  }

  // Single-device local storage has no other party who could send a
  // message in the background — a one-shot read is all a live stream
  // could ever report anyway.
  @override
  Stream<List<Message>> watchMessages() => Stream.fromFuture(loadMessages());

  @override
  Future<void> saveMessages(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _messagesKey,
      jsonEncode(messages.map((item) => item.toJson()).toList()),
    );
  }
}

/// Signed-out mode has no other real device to call — calling is
/// unavailable, matching how every other cross-device feature behaves
/// locally.
class LocalCallRepository implements CallRepository {
  @override
  Stream<CallSession?> get currentCall => Stream.value(null);

  @override
  bool get isMuted => false;

  @override
  Future<void> startCall(String calleeId) async {
    throw StateError('Sign in to make calls.');
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

class LocalCommentReactionRepository implements CommentReactionRepository {
  static const _reactionsKey = 'comment_reactions';

  @override
  Future<List<CommentReaction>> loadReactionsForProfile(String profileOwnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reactionsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => CommentReaction.fromJson(Map<String, dynamic>.from(item)))
          .where((r) => r.profileOwnerId == profileOwnerId)
          .toList();
    } catch (_) {
      await prefs.remove(_reactionsKey);
      return [];
    }
  }

  @override
  Future<void> saveReactions(List<CommentReaction> reactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reactionsKey,
      jsonEncode(reactions.map((item) => item.toJson()).toList()),
    );
  }
}

/// Firestore-backed comments. Unlike ratings, comments have no
/// anonymity requirement — authorship is meant to be visible — but
/// unlike the old design this doc comment used to describe, that does
/// NOT mean loading the whole collection: a viewer only ever needs one
/// profile's comments at a time (whichever profile screen is open), so
/// each call is scoped to that profile and `_lastKnown` accumulates
/// across whichever profiles get viewed this session instead of
/// holding the universe of every comment ever posted. `saveComments`'s
/// diff-against-last-load logic (same pattern `RemoteRatingRepository`
/// uses) needs no change for this — it only ever sees the ids this
/// device has actually loaded, so nothing outside that ever looks
/// "deleted".
class RemoteCommentRepository implements CommentRepository {
  RemoteCommentRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Map<String, Comment> _lastKnown = {};

  CollectionReference<Map<String, dynamic>> get _commentsCollection => _firestore.collection('comments');

  @override
  Future<List<Comment>> loadCommentsForProfile(String profileOwnerId) async {
    final snapshot = await _commentsCollection.where('profileOwnerId', isEqualTo: profileOwnerId).get();
    final all = snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
    _lastKnown = {..._lastKnown, for (final comment in all) comment.id: comment};
    return all;
  }

  @override
  Future<List<Comment>> loadCommentsByAuthor(String authorId) async {
    final snapshot = await _commentsCollection.where('authorId', isEqualTo: authorId).get();
    final all = snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
    _lastKnown = {..._lastKnown, for (final comment in all) comment.id: comment};
    return all;
  }

  @override
  Future<void> saveComments(List<Comment> comments) async {
    final now = {for (final comment in comments) comment.id: comment};

    for (final entry in now.entries) {
      final before = _lastKnown[entry.key];
      if (before == null || !_sameContent(before, entry.value)) {
        await _commentsCollection.doc(entry.key).set(entry.value.toJson());
      }
    }
    for (final id in _lastKnown.keys.toSet().difference(now.keys.toSet())) {
      await _commentsCollection.doc(id).delete();
    }

    _lastKnown = now;
  }

  bool _sameContent(Comment a, Comment b) =>
      a.content == b.content && a.isDeleted == b.isDeleted && a.isHidden == b.isHidden;
}

/// Firestore-backed direct messages. Unlike comments, private — this
/// only ever loads messages this device's user is a participant in
/// (`participants array-contains uid`), never the whole collection, and
/// the security rules independently enforce the same restriction
/// server-side so a client can't be trusted to self-limit its own
/// query. Diffs against the last load the same way `RemoteCommentRepository`
/// does, so re-saving an unchanged message (e.g. after marking others
/// read) doesn't rewrite it — and a message missing from the next save
/// (the sender deleted it) is deleted here too, same as comments.
class RemoteMessageRepository implements MessageRepository {
  RemoteMessageRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Map<String, Message> _lastKnown = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteMessageRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _messagesCollection => _firestore.collection('messages');

  @override
  Future<List<Message>> loadMessages() async {
    final snapshot = await _messagesCollection.where('participants', arrayContains: _uid).get();
    final all = snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
    _lastKnown = {for (final message in all) message.id: message};
    return all;
  }

  // `_lastKnown` is kept current here too (not just in loadMessages/
  // saveMessages) so saveMessages' diff-against-last-load logic stays
  // correct regardless of whether the latest read came from a one-shot
  // load or this stream.
  @override
  Stream<List<Message>> watchMessages() {
    return _messagesCollection.where('participants', arrayContains: _uid).snapshots().map((snapshot) {
      final all = snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
      _lastKnown = {for (final message in all) message.id: message};
      return all;
    });
  }

  @override
  Future<void> saveMessages(List<Message> messages) async {
    final now = {for (final message in messages) message.id: message};

    for (final entry in now.entries) {
      final before = _lastKnown[entry.key];
      if (before == null || before.isRead != entry.value.isRead) {
        await _messagesCollection.doc(entry.key).set(entry.value.toJson());
      }
    }
    for (final id in _lastKnown.keys.toSet().difference(now.keys.toSet())) {
      await _messagesCollection.doc(id).delete();
    }

    _lastKnown = now;
  }
}

/// Firestore-signaled, WebRTC-backed 1:1 audio calling. STUN-only (no
/// TURN relay — that needs a paid service this project doesn't have),
/// so connection isn't guaranteed on every network: it works reliably
/// on Wi-Fi/favorable NATs, and can fail to connect on some restrictive
/// carrier networks. A real production deployment would add a TURN
/// fallback; documented here rather than silently overclaiming.
///
/// Firestore doc shape: `calls/{id}` holds the `CallSession` fields
/// plus raw `offer`/`answer` SDP maps (opaque WebRTC payloads, not
/// modeled as app data); `calls/{id}/callerCandidates` and
/// `.../calleeCandidates` each hold one ICE candidate per document,
/// added as they're gathered and consumed as they arrive.
class RemoteCallRepository implements CallRepository {
  RemoteCallRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _listenForCalls();
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  final StreamController<CallSession?> _callController = StreamController<CallSession?>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteCandidatesSubscription;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  CallSession? _current;
  bool _isMuted = false;
  bool _remoteDescriptionSet = false;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteCallRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _calls => _firestore.collection('calls');

  @override
  Stream<CallSession?> get currentCall => _callController.stream;

  @override
  bool get isMuted => _isMuted;

  void _listenForCalls() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _callsSubscription = _calls.where('participants', arrayContains: uid).snapshots().listen((snapshot) {
      final relevant = snapshot.docs
          .map((doc) => CallSession.fromJson(doc.data()))
          .where((call) => call.status == CallStatus.ringing || call.status == CallStatus.active)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final next = relevant.isEmpty ? null : relevant.first;

      if (next == null && _current != null) {
        // The call this device knew about just ended/was declined —
        // possibly from the other side, possibly a stale reference.
        unawaited(_cleanupSession());
      }
      _current = next;
      _callController.add(next);

      // Caller: the callee accepting flips the doc to 'active' — finish
      // the handshake by reading the answer back.
      if (next != null && next.status == CallStatus.active && next.callerId == uid && _pc != null && !_remoteDescriptionSet) {
        unawaited(_completeCallerHandshake(next.id));
      }
    });
  }

  Future<void> _completeCallerHandshake(String callId) async {
    final doc = await _calls.doc(callId).get();
    final answer = doc.data()?['answer'] as Map<String, dynamic>?;
    final pc = _pc;
    if (answer == null || pc == null) return;
    await pc.setRemoteDescription(RTCSessionDescription(answer['sdp'] as String, answer['type'] as String));
    _remoteDescriptionSet = true;
    _listenToRemoteCandidates(callId, 'calleeCandidates');
  }

  void _listenToRemoteCandidates(String callId, String subcollection) {
    _remoteCandidatesSubscription?.cancel();
    _remoteCandidatesSubscription = _calls.doc(callId).collection(subcollection).snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        final pc = _pc;
        if (data == null || pc == null) continue;
        pc.addCandidate(RTCIceCandidate(data['candidate'] as String, data['sdpMid'] as String?, data['sdpMLineIndex'] as int?));
      }
    });
  }

  @override
  Future<void> startCall(String calleeId) async {
    final uid = _uid;
    await _cleanupSession();

    final callDoc = _calls.doc();
    final pc = await createPeerConnection(_iceServers);
    _pc = pc;
    _remoteDescriptionSet = false;

    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      callDoc.collection('callerCandidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    final session = CallSession(id: callDoc.id, callerId: uid, calleeId: calleeId, status: CallStatus.ringing, createdAt: DateTime.now());
    await callDoc.set({
      ...session.toJson(),
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });

    _listenToRemoteCandidates(callDoc.id, 'calleeCandidates');
  }

  @override
  Future<void> acceptCall() async {
    final current = _current;
    if (current == null || current.status != CallStatus.ringing) return;
    final callDoc = _calls.doc(current.id);
    final doc = await callDoc.get();
    final offerData = doc.data()?['offer'] as Map<String, dynamic>?;
    if (offerData == null) return;

    final pc = await createPeerConnection(_iceServers);
    _pc = pc;

    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      callDoc.collection('calleeCandidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    await pc.setRemoteDescription(RTCSessionDescription(offerData['sdp'] as String, offerData['type'] as String));
    _remoteDescriptionSet = true;
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await callDoc.update({
      'answer': {'sdp': answer.sdp, 'type': answer.type},
      'status': enumName(CallStatus.active),
    });

    _listenToRemoteCandidates(current.id, 'callerCandidates');
  }

  @override
  Future<void> declineCall() async {
    final current = _current;
    if (current == null) return;
    await _calls.doc(current.id).update({'status': enumName(CallStatus.declined)});
  }

  @override
  Future<void> endCall() async {
    final current = _current;
    if (current != null) {
      try {
        await _calls.doc(current.id).update({'status': enumName(CallStatus.ended)});
      } catch (_) {
        // Already deleted/transitioned by the other side — fine.
      }
    }
    await _cleanupSession();
  }

  @override
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = !_isMuted;
    }
  }

  Future<void> _cleanupSession() async {
    await _remoteCandidatesSubscription?.cancel();
    _remoteCandidatesSubscription = null;
    for (final track in _localStream?.getTracks() ?? const []) {
      track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    await _pc?.close();
    _pc = null;
    _remoteDescriptionSet = false;
    _isMuted = false;
  }

  Future<void> dispose() async {
    await _callsSubscription?.cancel();
    await _callController.close();
    await _cleanupSession();
  }
}

/// Firestore-backed reactions — scoped per profile like
/// `RemoteCommentRepository`, same reasoning: `_lastKnownIds`
/// accumulates across whichever profiles' comments this device has
/// actually loaded this session, not the whole collection.
class RemoteCommentReactionRepository implements CommentReactionRepository {
  RemoteCommentReactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Set<String> _lastKnownIds = {};

  CollectionReference<Map<String, dynamic>> get _reactionsCollection => _firestore.collection('commentReactions');

  @override
  Future<List<CommentReaction>> loadReactionsForProfile(String profileOwnerId) async {
    final snapshot = await _reactionsCollection.where('profileOwnerId', isEqualTo: profileOwnerId).get();
    final all = snapshot.docs.map((doc) => CommentReaction.fromJson(doc.data())).toList();
    _lastKnownIds = {..._lastKnownIds, ...all.map((reaction) => reaction.id)};
    return all;
  }

  @override
  Future<void> saveReactions(List<CommentReaction> reactions) async {
    final nowIds = reactions.map((reaction) => reaction.id).toSet();

    for (final reaction in reactions) {
      if (!_lastKnownIds.contains(reaction.id)) {
        await _reactionsCollection.doc(reaction.id).set(reaction.toJson());
      }
    }
    for (final id in _lastKnownIds.difference(nowIds)) {
      await _reactionsCollection.doc(id).delete();
    }

    _lastKnownIds = nowIds;
  }
}

class LocalBattleRepository implements BattleRepository {
  static const _battlesKey = 'battles';

  @override
  Future<List<Battle>> loadBattles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_battlesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => Battle.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      await prefs.remove(_battlesKey);
      return [];
    }
  }

  @override
  Future<void> saveBattles(List<Battle> battles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _battlesKey,
      jsonEncode(battles.map((item) => item.toJson()).toList()),
    );
  }
}

class LocalBattleVoteRepository implements BattleVoteRepository {
  static const _votesKey = 'battle_votes';

  @override
  Future<List<BattleVote>> loadVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_votesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => BattleVote.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      await prefs.remove(_votesKey);
      return [];
    }
  }

  @override
  Future<void> saveVotes(List<BattleVote> votes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _votesKey,
      jsonEncode(votes.map((item) => item.toJson()).toList()),
    );
  }
}

/// Firestore-backed battles for a signed-in device. A battle is a
/// matchup this device generated purely for itself to judge — nothing
/// here is ever shared with or visible to other users (see
/// `firestore.rules`), so this only ever needs this device's own
/// battles, and — unlike ratings/comments — a battle is never edited
/// once created, so `saveBattles` only ever needs to write additions.
class RemoteBattleRepository implements BattleRepository {
  RemoteBattleRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteBattleRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _battlesCollection => _firestore.collection('battles');

  @override
  Future<List<Battle>> loadBattles() async {
    final snapshot = await _battlesCollection.where('generatedBy', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => Battle.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((battle) => battle.id).toSet();
    return all;
  }

  @override
  Future<void> saveBattles(List<Battle> battles) async {
    final uid = _uid;
    for (final battle in battles) {
      if (_lastKnownIds.contains(battle.id)) continue;
      await _battlesCollection.doc(battle.id).set({...battle.toJson(), 'generatedBy': uid});
    }
    _lastKnownIds = battles.map((battle) => battle.id).toSet();
  }
}

/// Firestore-backed battle votes — same own-device-only, additions-only
/// shape as `RemoteBattleRepository`.
class RemoteBattleVoteRepository implements BattleVoteRepository {
  RemoteBattleVoteRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Set<String> _lastKnownIds = {};

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteBattleVoteRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _votesCollection => _firestore.collection('battleVotes');

  @override
  Future<List<BattleVote>> loadVotes() async {
    final snapshot = await _votesCollection.where('voterId', isEqualTo: _uid).get();
    final all = snapshot.docs.map((doc) => BattleVote.fromJson(doc.data())).toList();
    _lastKnownIds = all.map((vote) => vote.id).toSet();
    return all;
  }

  @override
  Future<void> saveVotes(List<BattleVote> votes) async {
    for (final vote in votes) {
      if (_lastKnownIds.contains(vote.id)) continue;
      await _votesCollection.doc(vote.id).set(vote.toJson());
    }
    _lastKnownIds = votes.map((vote) => vote.id).toSet();
  }
}

class LocalChoiceRepository implements ChoiceRepository {
  static const _votesKey = 'choice_votes';

  List<ChoiceVote> _cached = [];

  @override
  Future<List<ChoiceVote>> loadMyVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_votesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      _cached = list.map((item) => ChoiceVote.fromJson(Map<String, dynamic>.from(item))).toList();
      return _cached;
    } catch (_) {
      await prefs.remove(_votesKey);
      return [];
    }
  }

  @override
  Future<void> saveVote(ChoiceVote vote) async {
    if (_cached.any((v) => v.questionId == vote.questionId)) return;
    _cached = [..._cached, vote];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_votesKey, jsonEncode(_cached.map((item) => item.toJson()).toList()));
  }

  // No shared backend when signed out — the only real data is this
  // device's own single vote, if any.
  @override
  Future<ChoiceTally> loadTally(String questionId) async {
    final mine = _cached.where((v) => v.questionId == questionId);
    if (mine.isEmpty) return (countA: 0, countB: 0);
    final mine1 = mine.first;
    return (countA: mine1.chosenOption == ChoiceOption.a ? 1 : 0, countB: mine1.chosenOption == ChoiceOption.b ? 1 : 0);
  }
}

/// Firestore-backed "What Would You Choose" votes. Unlike
/// `RemoteBattleVoteRepository`, the tally genuinely needs to reflect
/// every voter, not just this device's own — so it's kept as a small,
/// denormalized `choiceAggregates/{questionId}` doc (one `FieldValue
/// .increment` write per vote, no read-then-write transaction needed
/// since a vote only ever adds, never moves between options) rather
/// than a per-voter collection scan, avoiding the O(N)-read mistake
/// fixed elsewhere in this app (see profile/comment pagination).
class RemoteChoiceRepository implements ChoiceRepository {
  RemoteChoiceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('RemoteChoiceRepository used without a signed-in Firebase user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _votesCollection => _firestore.collection('choiceVotes');

  DocumentReference<Map<String, dynamic>> _aggregateDoc(String questionId) =>
      _firestore.collection('choiceAggregates').doc(questionId);

  @override
  Future<List<ChoiceVote>> loadMyVotes() async {
    final snapshot = await _votesCollection.where('voterId', isEqualTo: _uid).get();
    return snapshot.docs.map((doc) => ChoiceVote.fromJson(doc.data())).toList();
  }

  // No existence pre-check: reading a document that doesn't exist yet
  // denies under the `choiceVotes` rule's `resource.data` access (the
  // same "safe accessor" lesson as `allowMessages`/`allowCalls` — see
  // firestore.rules) — and it's unnecessary anyway, since a duplicate
  // vote never reaches here: `AppController.submitChoice` guards
  // synchronously in-memory before ever calling this, and the rule
  // itself (`allow update: if false`) would reject a second write for
  // the same voter+question regardless.
  @override
  Future<void> saveVote(ChoiceVote vote) async {
    final voteRef = _votesCollection.doc('${vote.voterId}_${vote.questionId}');
    await voteRef.set(vote.toJson());
    await _aggregateDoc(vote.questionId).set({
      vote.chosenOption == ChoiceOption.a ? 'countA' : 'countB': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Future<ChoiceTally> loadTally(String questionId) async {
    final snapshot = await _aggregateDoc(questionId).get();
    final data = snapshot.data();
    return (countA: (data?['countA'] as num?)?.toInt() ?? 0, countB: (data?['countB'] as num?)?.toInt() ?? 0);
  }
}

class LocalSettingsRepository implements SettingsRepository {
  static const _onboardingKey = 'onboardingSeen';
  static const _settingsKey = 'settings';
  static const _blockedKey = 'blockedUsers';
  static const _reportsKey = 'reports';
  static const _hiddenConversationsKey = 'hiddenConversations';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<void> setOnboardingSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  @override
  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return const UserSettings();
    return UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<List<BlockedUser>> loadBlockedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_blockedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((item) => BlockedUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> saveBlockedUsers(List<BlockedUser> blocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _blockedKey,
      jsonEncode(blocked.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<List<Report>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((item) => Report.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> saveReports(List<Report> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reportsKey,
      jsonEncode(reports.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<List<HiddenConversation>> loadHiddenConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hiddenConversationsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((item) => HiddenConversation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> saveHiddenConversations(List<HiddenConversation> hidden) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _hiddenConversationsKey,
      jsonEncode(hidden.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class RepositoryBundle {
  RepositoryBundle({
    ProfileRepository? profileRepository,
    PhotoRepository? photoRepository,
    RatingRepository? ratingRepository,
    PhotoVoteRepository? photoVoteRepository,
    NotificationRepository? notificationRepository,
    SettingsRepository? settingsRepository,
    ProgressionRepository? progressionRepository,
    AppOpenRepository? appOpenRepository,
    AchievementRepository? achievementRepository,
    CoinRepository? coinRepository,
    CosmeticRepository? cosmeticRepository,
    ChallengeRepository? challengeRepository,
    CommentRepository? commentRepository,
    CommentReactionRepository? commentReactionRepository,
    MessageRepository? messageRepository,
    CallRepository? callRepository,
    BattleRepository? battleRepository,
    BattleVoteRepository? battleVoteRepository,
    ChoiceRepository? choiceRepository,
    ProfileService? profileService,
    RatingService? ratingService,
    PhotoVoteService? photoVoteService,
    MessageService? messageService,
    CallService? callService,
    PhotoService? photoService,
    ProgressionService? progressionService,
    LevelService? levelService,
    AchievementService? achievementService,
    RewardService? rewardService,
    DailyChallengeService? dailyChallengeService,
    StreakService? streakService,
    CommentService? commentService,
    BattleService? battleService,
    ChoiceService? choiceService,
    PercentileService? percentileService,
    CosmeticService? cosmeticService,
    GapService? gapService,
    PhotoQualityService? photoQualityService,
    TrendingService? trendingService,
  })  : profileRepository = profileRepository ?? LocalProfileRepository(),
        photoRepository = photoRepository ?? LocalPhotoRepository(),
        ratingRepository = ratingRepository ?? LocalRatingRepository(),
        photoVoteRepository = photoVoteRepository ?? LocalPhotoVoteRepository(),
        notificationRepository = notificationRepository ?? LocalNotificationRepository(),
        settingsRepository = settingsRepository ?? LocalSettingsRepository(),
        progressionRepository = progressionRepository ?? LocalProgressionRepository(),
        appOpenRepository = appOpenRepository ?? LocalAppOpenRepository(),
        achievementRepository = achievementRepository ?? LocalAchievementRepository(),
        coinRepository = coinRepository ?? LocalCoinRepository(),
        cosmeticRepository = cosmeticRepository ?? LocalCosmeticRepository(),
        challengeRepository = challengeRepository ?? LocalChallengeRepository(),
        commentRepository = commentRepository ?? LocalCommentRepository(),
        commentReactionRepository = commentReactionRepository ?? LocalCommentReactionRepository(),
        messageRepository = messageRepository ?? LocalMessageRepository(),
        callRepository = callRepository ?? LocalCallRepository(),
        battleRepository = battleRepository ?? LocalBattleRepository(),
        battleVoteRepository = battleVoteRepository ?? LocalBattleVoteRepository(),
        choiceRepository = choiceRepository ?? LocalChoiceRepository(),
        profileService = profileService ?? ProfileService(),
        ratingService = ratingService ?? RatingService(),
        photoVoteService = photoVoteService ?? PhotoVoteService(),
        photoService = photoService ?? PhotoService(),
        progressionService = progressionService ?? const ProgressionService(),
        levelService = levelService ?? const LevelService(),
        achievementService = achievementService ?? const AchievementService(),
        rewardService = rewardService ?? const RewardService(),
        dailyChallengeService = dailyChallengeService ?? const DailyChallengeService(),
        streakService = streakService ?? const StreakService(),
        commentService = commentService ?? CommentService(),
        messageService = messageService ?? MessageService(),
        callService = callService ?? const CallService(),
        battleService = battleService ?? BattleService(),
        choiceService = choiceService ?? const ChoiceService(),
        percentileService = percentileService ?? const PercentileService(),
        cosmeticService = cosmeticService ?? const CosmeticService(),
        gapService = gapService ?? const GapService(),
        photoQualityService = photoQualityService ?? const PhotoQualityService(),
        trendingService = trendingService ?? const TrendingService();

  final ProfileRepository profileRepository;
  final PhotoRepository photoRepository;
  final RatingRepository ratingRepository;
  final PhotoVoteRepository photoVoteRepository;
  final NotificationRepository notificationRepository;
  final SettingsRepository settingsRepository;
  final ProgressionRepository progressionRepository;
  final AppOpenRepository appOpenRepository;
  final AchievementRepository achievementRepository;
  final CoinRepository coinRepository;
  final CosmeticRepository cosmeticRepository;
  final ChallengeRepository challengeRepository;
  final CommentRepository commentRepository;
  final CommentReactionRepository commentReactionRepository;
  final MessageRepository messageRepository;
  final CallRepository callRepository;
  final BattleRepository battleRepository;
  final BattleVoteRepository battleVoteRepository;
  final ChoiceRepository choiceRepository;
  final ProfileService profileService;
  final RatingService ratingService;
  final PhotoVoteService photoVoteService;
  final PhotoService photoService;
  final ProgressionService progressionService;
  final LevelService levelService;
  final AchievementService achievementService;
  final RewardService rewardService;
  final DailyChallengeService dailyChallengeService;
  final StreakService streakService;
  final CommentService commentService;
  final MessageService messageService;
  final CallService callService;
  final BattleService battleService;
  final ChoiceService choiceService;
  final PercentileService percentileService;
  final CosmeticService cosmeticService;
  final GapService gapService;
  final PhotoQualityService photoQualityService;
  final TrendingService trendingService;
}
