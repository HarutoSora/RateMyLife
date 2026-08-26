import 'dart:convert';

enum ProfileVisibility { public, private }

enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  fakeProfile,
  impersonation,
  threat,
  other,
}

String enumName(Object value) => value.toString().split('.').last;

T enumValue<T>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (enumName(value as Object) == name) return value;
  }
  return fallback;
}

class ProfilePrivacy {
  const ProfilePrivacy({
    this.visibility = ProfileVisibility.public,
    this.showInDiscover = true,
    this.showInLeaderboard = true,
    this.allowRatings = true,
    this.allowComments = true,
    this.allowMessages = true,
    this.allowCalls = true,
    this.showAge = true,
    this.showCountry = true,
    this.showIncome = false,
    this.showSavings = false,
    this.showCareer = true,
    this.showPhotos = true,
  });

  final ProfileVisibility visibility;
  final bool showInDiscover;
  final bool showInLeaderboard;
  final bool allowRatings;
  final bool allowComments;
  final bool allowMessages;
  final bool allowCalls;
  final bool showAge;
  final bool showCountry;
  final bool showIncome;
  final bool showSavings;
  final bool showCareer;
  final bool showPhotos;

  bool get isPublic => visibility == ProfileVisibility.public;

  ProfilePrivacy copyWith({
    ProfileVisibility? visibility,
    bool? showInDiscover,
    bool? showInLeaderboard,
    bool? allowRatings,
    bool? allowComments,
    bool? allowMessages,
    bool? allowCalls,
    bool? showAge,
    bool? showCountry,
    bool? showIncome,
    bool? showSavings,
    bool? showCareer,
    bool? showPhotos,
  }) {
    return ProfilePrivacy(
      visibility: visibility ?? this.visibility,
      showInDiscover: showInDiscover ?? this.showInDiscover,
      showInLeaderboard: showInLeaderboard ?? this.showInLeaderboard,
      allowRatings: allowRatings ?? this.allowRatings,
      allowComments: allowComments ?? this.allowComments,
      allowMessages: allowMessages ?? this.allowMessages,
      allowCalls: allowCalls ?? this.allowCalls,
      showAge: showAge ?? this.showAge,
      showCountry: showCountry ?? this.showCountry,
      showIncome: showIncome ?? this.showIncome,
      showSavings: showSavings ?? this.showSavings,
      showCareer: showCareer ?? this.showCareer,
      showPhotos: showPhotos ?? this.showPhotos,
    );
  }

  Map<String, dynamic> toJson() => {
        'visibility': enumName(visibility),
        'showInDiscover': showInDiscover,
        'showInLeaderboard': showInLeaderboard,
        'allowRatings': allowRatings,
        'allowComments': allowComments,
        'allowMessages': allowMessages,
        'allowCalls': allowCalls,
        'showAge': showAge,
        'showCountry': showCountry,
        'showIncome': showIncome,
        'showSavings': showSavings,
        'showCareer': showCareer,
        'showPhotos': showPhotos,
      };

  factory ProfilePrivacy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProfilePrivacy();
    return ProfilePrivacy(
      visibility: enumValue(
        ProfileVisibility.values,
        json['visibility'] as String?,
        ProfileVisibility.public,
      ),
      showInDiscover: json['showInDiscover'] as bool? ?? true,
      showInLeaderboard: json['showInLeaderboard'] as bool? ?? true,
      allowRatings: json['allowRatings'] as bool? ?? true,
      allowComments: json['allowComments'] as bool? ?? true,
      allowMessages: json['allowMessages'] as bool? ?? true,
      allowCalls: json['allowCalls'] as bool? ?? true,
      showAge: json['showAge'] as bool? ?? true,
      showCountry: json['showCountry'] as bool? ?? true,
      showIncome: json['showIncome'] as bool? ?? false,
      showSavings: json['showSavings'] as bool? ?? false,
      showCareer: json['showCareer'] as bool? ?? true,
      showPhotos: json['showPhotos'] as bool? ?? true,
    );
  }
}

class ProfilePhoto {
  const ProfilePhoto({
    required this.id,
    required this.ownerId,
    required this.path,
    this.thumbnailPath,
    this.isProfilePhoto = false,
    required this.order,
    this.category = 'Lifestyle',
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String path;
  final String? thumbnailPath;
  final bool isProfilePhoto;
  final int order;
  final String category;
  final DateTime createdAt;

  ProfilePhoto copyWith({
    String? id,
    String? ownerId,
    String? path,
    String? thumbnailPath,
    bool? isProfilePhoto,
    int? order,
    String? category,
    DateTime? createdAt,
  }) {
    return ProfilePhoto(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isProfilePhoto: isProfilePhoto ?? this.isProfilePhoto,
      order: order ?? this.order,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'path': path,
        'thumbnailPath': thumbnailPath,
        'isProfilePhoto': isProfilePhoto,
        'order': order,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) => ProfilePhoto(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        path: json['path'] as String,
        thumbnailPath: json['thumbnailPath'] as String?,
        isProfilePhoto: json['isProfilePhoto'] as bool? ?? false,
        order: json['order'] as int? ?? 0,
        category: json['category'] as String? ?? 'Lifestyle',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class LifeScore {
  const LifeScore({
    required this.overall,
    required this.career,
    required this.financial,
    required this.education,
    required this.independence,
    required this.social,
    required this.lifestyle,
    required this.wellbeing,
    required this.explanations,
    required this.calculatedAt,
  });

  final int overall;
  final int career;
  final int financial;
  final int education;
  final int independence;
  final int social;
  final int lifestyle;
  final int wellbeing;
  final Map<String, String> explanations;
  final DateTime calculatedAt;

  Map<String, int> get breakdown => {
        'Career': career,
        'Money': financial,
        'Education': education,
        'Independence': independence,
        'Social': social,
        'Lifestyle': lifestyle,
        'Wellbeing': wellbeing,
      };

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'career': career,
        'financial': financial,
        'education': education,
        'independence': independence,
        'social': social,
        'lifestyle': lifestyle,
        'wellbeing': wellbeing,
        'explanations': explanations,
        'calculatedAt': calculatedAt.toIso8601String(),
      };

  factory LifeScore.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LifeScore.empty();
    }
    return LifeScore(
      overall: json['overall'] as int? ?? 0,
      career: json['career'] as int? ?? 0,
      financial: json['financial'] as int? ?? 0,
      education: json['education'] as int? ?? 0,
      independence: json['independence'] as int? ?? 0,
      social: json['social'] as int? ?? 0,
      lifestyle: json['lifestyle'] as int? ?? 0,
      wellbeing: json['wellbeing'] as int? ?? 0,
      explanations: Map<String, String>.from(
        json['explanations'] as Map? ?? const {},
      ),
      calculatedAt: DateTime.tryParse(json['calculatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory LifeScore.empty() => LifeScore(
        overall: 0,
        career: 0,
        financial: 0,
        education: 0,
        independence: 0,
        social: 0,
        lifestyle: 0,
        wellbeing: 0,
        explanations: const {},
        calculatedAt: DateTime.now(),
      );
}

class RatingSummary {
  const RatingSummary({
    this.averageOverall = 0,
    this.averageLook = 0,
    this.count = 0,
    this.averageCareer,
    this.averageLifestyle,
    this.averageSocial,
    this.averageIndependence,
    this.averageExperiences,
  });

  /// Average "life" rating (the original single rating dimension).
  final double averageOverall;

  /// Average "look" rating.
  final double averageLook;
  final int count;
  final double? averageCareer;
  final double? averageLifestyle;
  final double? averageSocial;
  final double? averageIndependence;
  final double? averageExperiences;

  bool get hasRatings => count > 0;

  Map<String, dynamic> toJson() => {
        'averageOverall': averageOverall,
        'averageLook': averageLook,
        'count': count,
        'averageCareer': averageCareer,
        'averageLifestyle': averageLifestyle,
        'averageSocial': averageSocial,
        'averageIndependence': averageIndependence,
        'averageExperiences': averageExperiences,
      };

  factory RatingSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RatingSummary();
    return RatingSummary(
      averageOverall: (json['averageOverall'] as num?)?.toDouble() ?? 0,
      averageLook: (json['averageLook'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
      averageCareer: (json['averageCareer'] as num?)?.toDouble(),
      averageLifestyle: (json['averageLifestyle'] as num?)?.toDouble(),
      averageSocial: (json['averageSocial'] as num?)?.toDouble(),
      averageIndependence:
          (json['averageIndependence'] as num?)?.toDouble(),
      averageExperiences: (json['averageExperiences'] as num?)?.toDouble(),
    );
  }
}

class ScoreHistoryPoint {
  const ScoreHistoryPoint({
    required this.month,
    required this.algorithmScore,
    required this.communityRating,
    required this.createdAt,
  });

  final String month;
  final int algorithmScore;
  final double communityRating;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'month': month,
        'algorithmScore': algorithmScore,
        'communityRating': communityRating,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScoreHistoryPoint.fromJson(Map<String, dynamic> json) =>
      ScoreHistoryPoint(
        month: json['month'] as String? ?? 'Now',
        algorithmScore: json['algorithmScore'] as int? ?? 0,
        communityRating: (json['communityRating'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// The action that earned a player XP. Kept separate from free-text so
/// reward amounts stay centralized in `ProgressionService`.
enum XpReason {
  profileCompleted,
  profileUpdated,
  photoAdded,
  ratingGiven,
  profileShared,

  /// Bonus XP from an achievement unlock. The actual amount is
  /// per-achievement (see `AchievementDefinition.xpReward`), not looked
  /// up from `ProgressionService.xpRewards` like the other reasons.
  achievementUnlocked,

  /// Bonus XP from completing a daily challenge. Like
  /// `achievementUnlocked`, the amount is per-challenge, not looked up
  /// from `ProgressionService.xpRewards`.
  dailyChallengeCompleted,

  /// Voting (judging) a Life Battle.
  battleVoted,

  /// Coins spent on a cosmetic (see `CosmeticFrame`) — always a
  /// negative-amount transaction, never used for XP.
  cosmeticPurchased,

  /// Answering today's "What Would You Choose" prompt.
  choiceMade,

  /// Coins spent on a profile boost (see `ProfileBoost`) — always a
  /// negative-amount transaction, never used for XP.
  boostPurchased,

  /// Watched a rewarded ad to completion (see `AdRepository`). Coins
  /// only, never used for XP — watching an ad isn't a "life" action.
  adWatched,

  /// Coins spent nuking another profile's Life Score (see
  /// `NukeService`) — always a negative-amount transaction, like
  /// `cosmeticPurchased`.
  nukeUsed,

  /// Coins spent on a cure potion to heal your own nuke damage (see
  /// `NukeService`) — always a negative-amount transaction.
  curePotionUsed,

  /// Real-money coin purchase via Google Play Billing (see
  /// `PurchaseRepository`). The amount is per-product (`PurchaseConfig.
  /// coinsForProduct`), not looked up from `RewardService.coinRewards`
  /// like the other earning reasons — coins only, never used for XP.
  coinsPurchased,
}

/// A single XP award, kept as an append-only log (mirrors the `Rating`
/// persistence pattern) so a future "recent activity" or audit view has
/// real data to show instead of another fake feed.
class XpTransaction {
  const XpTransaction({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final int amount;
  final XpReason reason;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'amount': amount,
        'reason': enumName(reason),
        'createdAt': createdAt.toIso8601String(),
      };

  factory XpTransaction.fromJson(Map<String, dynamic> json) => XpTransaction(
        id: json['id'] as String,
        profileId: json['profileId'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        reason: enumValue(XpReason.values, json['reason'] as String?, XpReason.profileUpdated),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A static catalog entry — not persisted itself, only referenced by id
/// from `UserAchievement`. `iconKey` is a plain string (not `IconData`)
/// so this model stays free of Flutter imports; the presentation layer
/// maps keys to icons.
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.xpReward,
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final int xpReward;
}

/// Records that the local user unlocked [achievementId] — mirrors the
/// `XpTransaction` append-only persistence pattern.
class UserAchievement {
  const UserAchievement({
    required this.id,
    required this.profileId,
    required this.achievementId,
    required this.unlockedAt,
  });

  final String id;
  final String profileId;
  final String achievementId;
  final DateTime unlockedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'achievementId': achievementId,
        'unlockedAt': unlockedAt.toIso8601String(),
      };

  factory UserAchievement.fromJson(Map<String, dynamic> json) => UserAchievement(
        id: json['id'] as String,
        profileId: json['profileId'] as String? ?? '',
        achievementId: json['achievementId'] as String? ?? '',
        unlockedAt: DateTime.tryParse(json['unlockedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A static, purchasable cosmetic catalog entry — not persisted
/// itself, only referenced by id from `CosmeticPurchase` and
/// `UserProfile.equippedFrameId`. Frames are the only cosmetic type
/// for now (nameplates/etc. can reuse this shape later without a
/// migration, same pattern as `AchievementDefinition`).
class CosmeticFrame {
  const CosmeticFrame({
    required this.id,
    required this.name,
    required this.gradientKey,
    required this.cost,
  });

  final String id;
  final String name;

  /// Maps to one of the app's existing brand gradients in the
  /// presentation layer (gold/purple/pink/blue) — kept as a plain
  /// string so this model stays Flutter-free, same reasoning as
  /// `iconKey` elsewhere. Never a hand-rolled color.
  final String gradientKey;
  final int cost;
}

/// Records that the local user bought [cosmeticId] — mirrors the
/// `UserAchievement` append-only persistence pattern exactly.
class CosmeticPurchase {
  const CosmeticPurchase({
    required this.id,
    required this.profileId,
    required this.cosmeticId,
    required this.purchasedAt,
  });

  final String id;
  final String profileId;
  final String cosmeticId;
  final DateTime purchasedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'cosmeticId': cosmeticId,
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  factory CosmeticPurchase.fromJson(Map<String, dynamic> json) => CosmeticPurchase(
        id: json['id'] as String,
        profileId: json['profileId'] as String? ?? '',
        cosmeticId: json['cosmeticId'] as String? ?? '',
        purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A single coin award — mirrors `XpTransaction` exactly, including
/// reusing `XpReason` rather than a parallel enum (spec's own "don't
/// duplicate models" instruction applies just as much to enums).
class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final int amount;
  final XpReason reason;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'amount': amount,
        'reason': enumName(reason),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) => CoinTransaction(
        id: json['id'] as String,
        profileId: json['profileId'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        reason: enumValue(XpReason.values, json['reason'] as String?, XpReason.profileUpdated),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A read-only view of the local user's coin balance and history — not
/// persisted itself; `AppController.wallet` derives it from
/// `UserProfile.coins` + the `CoinTransaction` log, the same way
/// `LevelInfo` is derived from `xp` rather than stored.
class Wallet {
  const Wallet({required this.balance, required this.transactions});

  final int balance;
  final List<CoinTransaction> transactions;
}

/// A static daily-challenge template — not persisted itself, only
/// referenced by id from `ChallengeCompletion`. Progress toward
/// [targetCount] is measured by counting the local user's *own*
/// `XpTransaction`s with [trackedReason] dated today, so challenges are
/// always backed by real activity rather than a separately-tracked
/// (and driftable) counter.
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.xpReward,
    required this.coinReward,
    required this.targetCount,
    required this.trackedReason,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final int xpReward;
  final int coinReward;
  final int targetCount;
  final XpReason trackedReason;
}

enum ChoiceOption { a, b }

/// A single "What Would You Choose" would-you-rather prompt — pure
/// content, like `DailyChallenge`, so it isn't persisted or serialized.
class Choice {
  const Choice({
    required this.id,
    required this.promptA,
    required this.promptB,
  });

  final String id;
  final String promptA;
  final String promptB;
}

/// Records that [voterId] picked [chosenOption] for [questionId]. One
/// per (voterId, questionId) and immutable once cast — enforced by
/// `ChoiceService`/`AppController`, not this model, matching the rest
/// of the app's pattern of pure data classes plus a service that
/// enforces the rules.
class ChoiceVote {
  const ChoiceVote({
    required this.id,
    required this.questionId,
    required this.voterId,
    required this.chosenOption,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String voterId;
  final ChoiceOption chosenOption;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionId': questionId,
        'voterId': voterId,
        'chosenOption': enumName(chosenOption),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChoiceVote.fromJson(Map<String, dynamic> json) => ChoiceVote(
        id: json['id'] as String,
        questionId: json['questionId'] as String? ?? '',
        voterId: json['voterId'] as String? ?? '',
        chosenOption: enumValue(ChoiceOption.values, json['chosenOption'] as String?, ChoiceOption.a),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Records that the local user claimed [challengeId]'s reward on
/// [date] (a day, truncated to midnight — see `DailyChallengeService`).
/// Mirrors `UserAchievement`'s persistence pattern; the (challengeId,
/// date) pair is what prevents claiming the same challenge's reward
/// twice in one day.
class ChallengeCompletion {
  const ChallengeCompletion({
    required this.id,
    required this.profileId,
    required this.challengeId,
    required this.date,
    required this.completedAt,
  });

  final String id;
  final String profileId;
  final String challengeId;
  final DateTime date;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'challengeId': challengeId,
        'date': date.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
      };

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) => ChallengeCompletion(
        id: json['id'] as String,
        profileId: json['profileId'] as String? ?? '',
        challengeId: json['challengeId'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.country,
    required this.city,
    this.gender,
    required this.employmentStatus,
    required this.jobCategory,
    this.jobTitle,
    required this.yearsExperience,
    required this.educationLevel,
    required this.monthlyIncome,
    required this.currency,
    required this.savings,
    required this.investments,
    required this.debt,
    required this.monthlyExpenses,
    required this.relationshipStatus,
    required this.livingSituation,
    required this.ownsCar,
    this.carModel,
    required this.ownsHome,
    required this.travelFrequency,
    required this.exerciseFrequency,
    required this.hobbies,
    required this.freeTimeHours,
    required this.closeFriends,
    required this.happiness,
    required this.stress,
    required this.currentGoal,
    required this.bio,
    required this.photos,
    required this.score,
    required this.ratingSummary,
    required this.history,
    required this.privacy,
    required this.createdAt,
    required this.updatedAt,
    this.isCurrentUser = false,
    this.xp = 0,
    this.coins = 0,
    this.viewCount = 0,
    this.equippedFrameId,
    this.socialLinks = const {},
    this.photoVoteCounts = const {},
    this.nukeDamage = const {},
    this.nukesSurvived = 0,
  });

  final String id;
  final String displayName;
  final int age;
  final String country;
  final String city;
  final String? gender;
  final String employmentStatus;
  final String jobCategory;
  final String? jobTitle;
  final int yearsExperience;
  final String educationLevel;
  final double monthlyIncome;
  final String currency;
  final double savings;
  final double investments;
  final double debt;
  final double monthlyExpenses;
  final String relationshipStatus;
  final String livingSituation;
  final bool ownsCar;
  final String? carModel;
  final bool ownsHome;
  final String travelFrequency;
  final String exerciseFrequency;
  final List<String> hobbies;
  final int freeTimeHours;
  final int closeFriends;
  final int happiness;
  final int stress;
  final String currentGoal;
  final String bio;
  final List<ProfilePhoto> photos;
  final LifeScore score;
  final RatingSummary ratingSummary;
  final List<ScoreHistoryPoint> history;
  final ProfilePrivacy privacy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCurrentUser;

  /// Cumulative lifetime XP. Level/rank are derived from this via
  /// `LevelService` rather than stored, so the level curve can change
  /// without a migration.
  final int xp;

  /// Current coin balance — the soft currency's spec, not real money.
  /// Spendable on cosmetics (see `equippedFrameId`, `CosmeticFrame`).
  final int coins;

  /// How many times other people have opened this profile. Server-
  /// maintained only (see `RemoteProfileRepository.recordProfileView`)
  /// — never set by the owner's own profile edits, and no per-viewer
  /// record exists anywhere, so there's no identity to leak.
  final int viewCount;

  /// The purchased `CosmeticFrame.id` currently displayed around this
  /// profile's photo, or null for no frame. Purchasing and equipping
  /// are separate steps (see `AppController.purchaseFrame`/`equipFrame`)
  /// — owning several frames but wearing only one is the point.
  final String? equippedFrameId;

  /// Optional external links the owner chose to share — platform name
  /// (e.g. "Instagram") to full URL. Purely opt-in self-promotion, not a
  /// verified identity claim; never populated automatically.
  final Map<String, String> socialLinks;

  /// "Best photo" vote tally, photoId → count. Server-maintained only
  /// (see `RemotePhotoVoteRepository`) via the same incremental,
  /// transactional pattern as `ratingSummary` — no device ever reads
  /// another voter's individual pick, only this running total.
  final Map<String, int> photoVoteCounts;

  /// Active nuke damage by attribute (see `NukeService`), always <= 0 —
  /// `ProfileService.recalculate` subtracts these from the freshly
  /// computed `LifeScoreService.calculate` result every time, so damage
  /// persists across ordinary profile edits instead of being silently
  /// wiped by the next recalculation. A cure potion moves an entry back
  /// toward 0; it never goes positive. Server-maintained for a nuke
  /// (same transactional-aggregate pattern as `photoVoteCounts`), owner-
  /// written for a cure (a normal profile edit, since it only ever
  /// touches your own damage).
  final Map<String, int> nukeDamage;

  /// Lifetime count of nuke attacks received — the public "X nukes
  /// survived" stat shown in Discover. Never reveals who attacked; see
  /// `NukeEvent`'s doc comment.
  final int nukesSurvived;

  ProfilePhoto? get profilePhoto {
    final sorted = [...photos]..sort((a, b) => a.order.compareTo(b.order));
    for (final photo in sorted) {
      if (photo.isProfilePhoto) return photo;
    }
    return sorted.isEmpty ? null : sorted.first;
  }

  String get locationLine {
    final parts = [
      if (privacy.showAge) '$age',
      if (privacy.showCountry) country,
    ];
    return parts.join(' • ');
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    int? age,
    String? country,
    String? city,
    String? gender,
    String? employmentStatus,
    String? jobCategory,
    String? jobTitle,
    int? yearsExperience,
    String? educationLevel,
    double? monthlyIncome,
    String? currency,
    double? savings,
    double? investments,
    double? debt,
    double? monthlyExpenses,
    String? relationshipStatus,
    String? livingSituation,
    bool? ownsCar,
    String? carModel,
    bool? ownsHome,
    String? travelFrequency,
    String? exerciseFrequency,
    List<String>? hobbies,
    int? freeTimeHours,
    int? closeFriends,
    int? happiness,
    int? stress,
    String? currentGoal,
    String? bio,
    List<ProfilePhoto>? photos,
    LifeScore? score,
    RatingSummary? ratingSummary,
    List<ScoreHistoryPoint>? history,
    ProfilePrivacy? privacy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCurrentUser,
    int? xp,
    int? coins,
    int? viewCount,
    String? equippedFrameId,
    Map<String, String>? socialLinks,
    Map<String, int>? photoVoteCounts,
    Map<String, int>? nukeDamage,
    int? nukesSurvived,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      country: country ?? this.country,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      jobCategory: jobCategory ?? this.jobCategory,
      jobTitle: jobTitle ?? this.jobTitle,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      educationLevel: educationLevel ?? this.educationLevel,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currency: currency ?? this.currency,
      savings: savings ?? this.savings,
      investments: investments ?? this.investments,
      debt: debt ?? this.debt,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      livingSituation: livingSituation ?? this.livingSituation,
      ownsCar: ownsCar ?? this.ownsCar,
      carModel: carModel ?? this.carModel,
      ownsHome: ownsHome ?? this.ownsHome,
      travelFrequency: travelFrequency ?? this.travelFrequency,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      hobbies: hobbies ?? this.hobbies,
      freeTimeHours: freeTimeHours ?? this.freeTimeHours,
      closeFriends: closeFriends ?? this.closeFriends,
      happiness: happiness ?? this.happiness,
      stress: stress ?? this.stress,
      currentGoal: currentGoal ?? this.currentGoal,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      score: score ?? this.score,
      ratingSummary: ratingSummary ?? this.ratingSummary,
      history: history ?? this.history,
      privacy: privacy ?? this.privacy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      viewCount: viewCount ?? this.viewCount,
      equippedFrameId: equippedFrameId ?? this.equippedFrameId,
      socialLinks: socialLinks ?? this.socialLinks,
      photoVoteCounts: photoVoteCounts ?? this.photoVoteCounts,
      nukeDamage: nukeDamage ?? this.nukeDamage,
      nukesSurvived: nukesSurvived ?? this.nukesSurvived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'age': age,
        'country': country,
        'city': city,
        'gender': gender,
        'employmentStatus': employmentStatus,
        'jobCategory': jobCategory,
        'jobTitle': jobTitle,
        'yearsExperience': yearsExperience,
        'educationLevel': educationLevel,
        'monthlyIncome': monthlyIncome,
        'currency': currency,
        'savings': savings,
        'investments': investments,
        'debt': debt,
        'monthlyExpenses': monthlyExpenses,
        'relationshipStatus': relationshipStatus,
        'livingSituation': livingSituation,
        'ownsCar': ownsCar,
        'carModel': carModel,
        'ownsHome': ownsHome,
        'travelFrequency': travelFrequency,
        'exerciseFrequency': exerciseFrequency,
        'hobbies': hobbies,
        'freeTimeHours': freeTimeHours,
        'closeFriends': closeFriends,
        'happiness': happiness,
        'stress': stress,
        'currentGoal': currentGoal,
        'bio': bio,
        'photos': photos.map((photo) => photo.toJson()).toList(),
        'score': score.toJson(),
        'ratingSummary': ratingSummary.toJson(),
        'history': history.map((point) => point.toJson()).toList(),
        'privacy': privacy.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isCurrentUser': isCurrentUser,
        'xp': xp,
        'coins': coins,
        'viewCount': viewCount,
        'equippedFrameId': equippedFrameId,
        'socialLinks': socialLinks,
        'photoVoteCounts': photoVoteCounts,
        'nukeDamage': nukeDamage,
        'nukesSurvived': nukesSurvived,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? 'Anonymous',
        age: json['age'] as int? ?? 18,
        country: json['country'] as String? ?? 'Morocco',
        city: json['city'] as String? ?? '',
        gender: json['gender'] as String?,
        employmentStatus: json['employmentStatus'] as String? ?? 'Employed',
        jobCategory: json['jobCategory'] as String? ?? 'Other',
        jobTitle: json['jobTitle'] as String?,
        yearsExperience: json['yearsExperience'] as int? ?? 0,
        educationLevel: json['educationLevel'] as String? ?? 'High School',
        monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'MAD',
        savings: (json['savings'] as num?)?.toDouble() ?? 0,
        investments: (json['investments'] as num?)?.toDouble() ?? 0,
        debt: (json['debt'] as num?)?.toDouble() ?? 0,
        monthlyExpenses: (json['monthlyExpenses'] as num?)?.toDouble() ?? 0,
        relationshipStatus:
            json['relationshipStatus'] as String? ?? 'Single',
        livingSituation: json['livingSituation'] as String? ?? 'With family',
        ownsCar: json['ownsCar'] as bool? ?? false,
        carModel: json['carModel'] as String?,
        ownsHome: json['ownsHome'] as bool? ?? false,
        travelFrequency: json['travelFrequency'] as String? ?? 'Rarely',
        exerciseFrequency:
            json['exerciseFrequency'] as String? ?? 'Sometimes',
        hobbies: List<String>.from(json['hobbies'] as List? ?? const []),
        freeTimeHours: json['freeTimeHours'] as int? ?? 10,
        closeFriends: json['closeFriends'] as int? ?? 3,
        happiness: json['happiness'] as int? ?? 6,
        stress: json['stress'] as int? ?? 5,
        currentGoal: json['currentGoal'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        photos: (json['photos'] as List? ?? const [])
            .map((item) => ProfilePhoto.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        score: LifeScore.fromJson(
          Map<String, dynamic>.from(json['score'] as Map? ?? const {}),
        ),
        ratingSummary: RatingSummary.fromJson(
          Map<String, dynamic>.from(json['ratingSummary'] as Map? ?? const {}),
        ),
        history: (json['history'] as List? ?? const [])
            .map((item) =>
                ScoreHistoryPoint.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        privacy: ProfilePrivacy.fromJson(
          Map<String, dynamic>.from(json['privacy'] as Map? ?? const {}),
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
        xp: json['xp'] as int? ?? 0,
        coins: json['coins'] as int? ?? 0,
        viewCount: json['viewCount'] as int? ?? 0,
        equippedFrameId: json['equippedFrameId'] as String?,
        socialLinks: Map<String, String>.from(json['socialLinks'] as Map? ?? const {}),
        photoVoteCounts: Map<String, int>.from(json['photoVoteCounts'] as Map? ?? const {}),
        nukeDamage: Map<String, int>.from(json['nukeDamage'] as Map? ?? const {}),
        nukesSurvived: json['nukesSurvived'] as int? ?? 0,
      );
}

class Rating {
  const Rating({
    required this.id,
    required this.raterId,
    required this.profileId,
    required this.overall,
    this.look,
    this.career,
    this.lifestyle,
    this.social,
    this.independence,
    this.experiences,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String raterId;
  final String profileId;

  /// Rating of the person's life (0-10). Historically the only rating
  /// dimension, so the field kept its original name.
  final int overall;

  /// Rating of the person's look/photos (0-10). Optional so older
  /// persisted ratings (life-only) still decode cleanly.
  final int? look;
  final int? career;
  final int? lifestyle;
  final int? social;
  final int? independence;
  final int? experiences;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating copyWith({
    String? id,
    String? raterId,
    String? profileId,
    int? overall,
    int? look,
    int? career,
    int? lifestyle,
    int? social,
    int? independence,
    int? experiences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      raterId: raterId ?? this.raterId,
      profileId: profileId ?? this.profileId,
      overall: overall ?? this.overall,
      look: look ?? this.look,
      career: career ?? this.career,
      lifestyle: lifestyle ?? this.lifestyle,
      social: social ?? this.social,
      independence: independence ?? this.independence,
      experiences: experiences ?? this.experiences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'raterId': raterId,
        'profileId': profileId,
        'overall': overall,
        'look': look,
        'career': career,
        'lifestyle': lifestyle,
        'social': social,
        'independence': independence,
        'experiences': experiences,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        id: json['id'] as String,
        raterId: json['raterId'] as String,
        profileId: json['profileId'] as String,
        overall: json['overall'] as int,
        look: json['look'] as int?,
        career: json['career'] as int?,
        lifestyle: json['lifestyle'] as int?,
        social: json['social'] as int?,
        independence: json['independence'] as int?,
        experiences: json['experiences'] as int?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// One voter's pick for a profile's best photo — at most one per
/// (voterId, profileId), like [Rating]. Anonymity mirrors ratings too:
/// individual votes are never read by anyone but the voter; the public
/// signal is the aggregate `UserProfile.photoVoteCounts`.
class PhotoVote {
  const PhotoVote({
    required this.id,
    required this.voterId,
    required this.profileId,
    required this.photoId,
    required this.createdAt,
  });

  final String id;
  final String voterId;
  final String profileId;
  final String photoId;
  final DateTime createdAt;

  PhotoVote copyWith({
    String? id,
    String? voterId,
    String? profileId,
    String? photoId,
    DateTime? createdAt,
  }) {
    return PhotoVote(
      id: id ?? this.id,
      voterId: voterId ?? this.voterId,
      profileId: profileId ?? this.profileId,
      photoId: photoId ?? this.photoId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'voterId': voterId,
        'profileId': profileId,
        'photoId': photoId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PhotoVote.fromJson(Map<String, dynamic> json) => PhotoVote(
        id: json['id'] as String,
        voterId: json['voterId'] as String,
        profileId: json['profileId'] as String,
        photoId: json['photoId'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// One paid attack against another profile's Life Score (see
/// `NukeService`) — [attribute] is one of `LifeScore.breakdown`'s
/// lowercase keys (`career`, `financial`, `education`, `independence`,
/// `social`, `lifestyle`, `wellbeing`), [damage] is always negative.
/// Only ever readable by the attacker's own device — see
/// `firestore.rules`' `nukeEvents` match — so the target never learns
/// who attacked them, mirroring [Rating]'s anonymity. The target's own
/// `UserProfile.nukesSurvived`/`nukeDamage` are the public signal.
class NukeEvent {
  const NukeEvent({
    required this.id,
    required this.attackerId,
    required this.targetId,
    required this.targetName,
    required this.attribute,
    required this.damage,
    required this.createdAt,
  });

  final String id;
  final String attackerId;
  final String targetId;

  /// Denormalized at attack time purely for this device's own "sent"
  /// history display — the target's live display name may since have
  /// changed, and that's fine, this is a receipt, not a live lookup.
  final String targetName;
  final String attribute;
  final int damage;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'attackerId': attackerId,
        'targetId': targetId,
        'targetName': targetName,
        'attribute': attribute,
        'damage': damage,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NukeEvent.fromJson(Map<String, dynamic> json) => NukeEvent(
        id: json['id'] as String,
        attackerId: json['attackerId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        targetName: json['targetName'] as String? ?? 'Anonymous',
        attribute: json['attribute'] as String? ?? '',
        damage: json['damage'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetUserId,
    this.targetPhotoId,
    this.targetCommentId,
    this.targetMessageId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetUserId;
  final String? targetPhotoId;

  /// Set when this report is against a comment rather than the profile
  /// or a photo directly — reuses `Report`/`ReportReason` rather than a
  /// parallel `CommentReport` model, per the spec's own "don't duplicate
  /// reporting logic" instruction.
  final String? targetCommentId;

  /// Same reuse, for a reported direct message.
  final String? targetMessageId;
  final ReportReason reason;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterId': reporterId,
        'targetUserId': targetUserId,
        'targetPhotoId': targetPhotoId,
        'targetCommentId': targetCommentId,
        'targetMessageId': targetMessageId,
        'reason': enumName(reason),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterId: json['reporterId'] as String,
        targetUserId: json['targetUserId'] as String,
        targetPhotoId: json['targetPhotoId'] as String?,
        targetCommentId: json['targetCommentId'] as String?,
        targetMessageId: json['targetMessageId'] as String?,
        reason: enumValue(
          ReportReason.values,
          json['reason'] as String?,
          ReportReason.other,
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A direct message between two users. Unlike comments, never public —
/// readable only by its sender and recipient (enforced server-side by
/// Firestore rules, same "private by construction" posture as ratings).
/// [conversationId] is the two participant ids sorted and joined
/// (`MessageService.conversationIdFor`), so every message in a thread
/// shares one queryable id regardless of who sent it.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  static const maxLength = 500;

  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  List<String> get participants => [senderId, recipientId];

  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'recipientId': recipientId,
        'participants': participants,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String,
        recipientId: json['recipientId'] as String,
        content: json['content'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
}

enum CallStatus { ringing, active, declined, ended, missed }

/// A 1:1 audio call's signaling record — ephemeral state, not persisted
/// content like a message. SDP offer/answer and ICE candidates are
/// handled directly by `CallRepository` (they're opaque WebRTC payloads,
/// not meaningful app data), so this only carries what the UI needs to
/// render a ringing/active call screen.
class CallSession {
  const CallSession({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String callerId;
  final String calleeId;
  final CallStatus status;
  final DateTime createdAt;

  String otherUserId(String myId) => myId == callerId ? calleeId : callerId;

  CallSession copyWith({CallStatus? status}) => CallSession(
        id: id,
        callerId: callerId,
        calleeId: calleeId,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'callerId': callerId,
        'calleeId': calleeId,
        'participants': [callerId, calleeId],
        'status': enumName(status),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
        id: json['id'] as String,
        callerId: json['callerId'] as String,
        calleeId: json['calleeId'] as String,
        status: enumValue(CallStatus.values, json['status'] as String?, CallStatus.ended),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A comment left on a profile. Soft-deleted rather than removed
/// outright (so a moderator/audit trail can exist later), but per spec
/// rule "deleted comments should not expose their original content",
/// [content] itself is blanked out at delete time — `isDeleted` isn't
/// just a display flag, the text is actually gone from the record.
class Comment {
  const Comment({
    required this.id,
    required this.profileOwnerId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isHidden = false,
  });

  static const maxLength = 280;

  final String id;
  final String profileOwnerId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  /// Reserved for future server-side/moderator hiding (distinct from a
  /// single viewer's own block/report, which are handled by filtering
  /// in `CommentService` instead of mutating the record).
  final bool isHidden;

  Comment copyWith({
    String? content,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isHidden,
  }) {
    return Comment(
      id: id,
      profileOwnerId: profileOwnerId,
      authorId: authorId,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileOwnerId': profileOwnerId,
        'authorId': authorId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
        'isHidden': isHidden,
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        profileOwnerId: json['profileOwnerId'] as String? ?? '',
        authorId: json['authorId'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        isDeleted: json['isDeleted'] as bool? ?? false,
        isHidden: json['isHidden'] as bool? ?? false,
      );
}

enum CommentReactionType { heart, laugh, fire, thumbsUp }

/// One user's reaction of [type] to a comment. Uniqueness is on
/// (commentId, userId, type) — a user can react with several *different*
/// emoji on the same comment, but not stack the same one twice.
class CommentReaction {
  const CommentReaction({
    required this.id,
    required this.commentId,
    required this.profileOwnerId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String commentId;

  /// Denormalized from the comment being reacted to — lets a reaction
  /// be fetched scoped to one profile (`loadReactionsForProfile`)
  /// without a separate lookup of which comments belong to it.
  final String profileOwnerId;
  final String userId;
  final CommentReactionType type;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'commentId': commentId,
        'profileOwnerId': profileOwnerId,
        'userId': userId,
        'type': enumName(type),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommentReaction.fromJson(Map<String, dynamic> json) => CommentReaction(
        id: json['id'] as String,
        commentId: json['commentId'] as String? ?? '',
        profileOwnerId: json['profileOwnerId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        type: enumValue(CommentReactionType.values, json['type'] as String?, CommentReactionType.heart),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// How a `Battle`'s two profiles were picked. MVP supports the 3 types
/// the spec calls out for launch; the enum leaves room for more (e.g. a
/// future `friendGroup`) without touching persisted data.
enum BattleType { random, trending, country }

/// A single generated pairing of two profiles for the local user to
/// judge. Persisted once generated so "you already voted on this one"
/// is meaningful — re-rolling gets a new [id], it doesn't mutate this
/// one.
class Battle {
  const Battle({
    required this.id,
    required this.profileAId,
    required this.profileBId,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String profileAId;
  final String profileBId;
  final BattleType type;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileAId': profileAId,
        'profileBId': profileBId,
        'type': enumName(type),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Battle.fromJson(Map<String, dynamic> json) => Battle(
        id: json['id'] as String,
        profileAId: json['profileAId'] as String? ?? '',
        profileBId: json['profileBId'] as String? ?? '',
        type: enumValue(BattleType.values, json['type'] as String?, BattleType.random),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Records that [voterId] chose [chosenProfileId] in [battleId]. One per
/// (battleId, voterId) — enforced by `BattleService`/`AppController`,
/// not by this model, matching the rest of the app's pattern of pure
/// data classes plus a service that enforces the rules.
class BattleVote {
  const BattleVote({
    required this.id,
    required this.battleId,
    required this.voterId,
    required this.chosenProfileId,
    required this.createdAt,
  });

  final String id;
  final String battleId;
  final String voterId;
  final String chosenProfileId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'battleId': battleId,
        'voterId': voterId,
        'chosenProfileId': chosenProfileId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BattleVote.fromJson(Map<String, dynamic> json) => BattleVote(
        id: json['id'] as String,
        battleId: json['battleId'] as String? ?? '',
        voterId: json['voterId'] as String? ?? '',
        chosenProfileId: json['chosenProfileId'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A read-only view combining a [battle] with the local user's own vote
/// (if any) and an estimated audience split — not persisted, derived on
/// demand the same way `Wallet`/`LevelInfo` are. The percentage is a
/// deterministic estimate from both profiles' Life Scores (see
/// `BattleService.communityPercentageForA`), **not** a live tally of
/// other real users' votes — this is a single-device local MVP with one
/// real voter, so it can't be anything else honestly. Framed the same
/// way the rest of the app's seeded mock community data already is.
class BattleResult {
  const BattleResult({
    required this.battle,
    required this.myVote,
    required this.percentageForA,
  });

  final Battle battle;
  final BattleVote? myVote;

  /// 0-100, estimated share who'd pick profile A.
  final int percentageForA;

  int get percentageForB => 100 - percentageForA;

  bool get hasVoted => myVote != null;
}

class BlockedUser {
  const BlockedUser({
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
  });

  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        blockerId: json['blockerId'] as String,
        blockedUserId: json['blockedUserId'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// This device's own record of having deleted a conversation from its
/// inbox — mirrors [BlockedUser]'s shape/scoping. Only the sender can
/// delete an individual message ([Message] stays readable by both
/// participants otherwise — see `AppController.deleteMessage`'s doc
/// comment), so "delete conversation" can only ever hide the thread
/// from this device's own view, not erase the other participant's copy.
/// Storing a cutoff timestamp rather than a plain flag lets a new
/// incoming message naturally revive the thread instead of leaving it
/// hidden forever.
class HiddenConversation {
  const HiddenConversation({
    required this.ownerId,
    required this.otherUserId,
    required this.hiddenAt,
  });

  final String ownerId;
  final String otherUserId;
  final DateTime hiddenAt;

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'otherUserId': otherUserId,
        'hiddenAt': hiddenAt.toIso8601String(),
      };

  factory HiddenConversation.fromJson(Map<String, dynamic> json) => HiddenConversation(
        ownerId: json['ownerId'] as String,
        otherUserId: json['otherUserId'] as String,
        hiddenAt: DateTime.tryParse(json['hiddenAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class UserSettings {
  const UserSettings({
    this.notifications = true,
    this.sound = true,
    this.darkMode = true,
  });

  final bool notifications;
  final bool sound;
  final bool darkMode;

  UserSettings copyWith({
    bool? notifications,
    bool? sound,
    bool? darkMode,
  }) {
    return UserSettings(
      notifications: notifications ?? this.notifications,
      sound: sound ?? this.sound,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'notifications': notifications,
        'sound': sound,
        'darkMode': darkMode,
      };

  factory UserSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserSettings();
    return UserSettings(
      notifications: json['notifications'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? true,
    );
  }
}

String encodeJson(Object object) => jsonEncode(object);
