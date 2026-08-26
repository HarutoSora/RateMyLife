import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

/// Awards coins for real, user-triggered actions — the soft-currency
/// counterpart to `ProgressionService`. Reuses `XpReason` rather than a
/// parallel enum (see `CoinTransaction`'s doc comment). This is the
/// earning side only — spending happens elsewhere (cosmetic frames,
/// profile boosts), as a negative-amount transaction reusing the same
/// ledger rather than a separate mechanism.
class RewardService {
  const RewardService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Deliberately smaller than the matching XP reward so coins read as
  /// a secondary, collectible currency rather than a duplicate XP bar.
  static const Map<XpReason, int> coinRewards = {
    XpReason.profileCompleted: 20,
    XpReason.profileUpdated: 3,
    XpReason.photoAdded: 5,
    XpReason.ratingGiven: 2,
    XpReason.profileShared: 5,
    XpReason.battleVoted: 1,
    XpReason.choiceMade: 3,

    /// The one deliberate exception to "smaller than the matching XP
    /// reward" above — there's no XP counterpart, and watching a full
    /// rewarded ad is a bigger ask than a quick rating or vote.
    /// User-requested value, matching the "Buy Coins" packaging.
    XpReason.adWatched: 300,
  };

  CoinTransaction award({required String profileId, required XpReason reason}) {
    return CoinTransaction(
      id: _uuid.v4(),
      profileId: profileId,
      amount: coinRewards[reason] ?? 0,
      reason: reason,
      createdAt: DateTime.now(),
    );
  }
}
