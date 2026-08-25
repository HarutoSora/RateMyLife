import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

/// Awards XP for real, user-triggered actions. Reward amounts live here
/// so every call site (AppController) stays a one-liner and the economy
/// can be tuned in one place.
class ProgressionService {
  const ProgressionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static const Map<XpReason, int> xpRewards = {
    XpReason.profileCompleted: 150,
    XpReason.profileUpdated: 20,
    XpReason.photoAdded: 30,
    XpReason.ratingGiven: 15,
    XpReason.profileShared: 25,
    XpReason.battleVoted: 10,
    XpReason.choiceMade: 15,
  };

  XpTransaction award({required String profileId, required XpReason reason}) {
    return XpTransaction(
      id: _uuid.v4(),
      profileId: profileId,
      amount: xpRewards[reason] ?? 0,
      reason: reason,
      createdAt: DateTime.now(),
    );
  }
}
