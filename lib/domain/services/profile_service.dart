import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../scoring/life_score_service.dart';

class ProfileService {
  ProfileService({LifeScoreService? scoreService})
      : _scoreService = scoreService ?? const LifeScoreService();

  final LifeScoreService _scoreService;

  UserProfile recalculate(UserProfile profile) {
    final rawScore = _scoreService.calculate(profile);
    // Nuke damage (see `NukeService`) is persisted on the profile, not
    // baked into `calculate`'s inputs — reapply it here so it survives
    // every ordinary profile edit instead of being wiped by the next
    // recalculation.
    final score = profile.nukeDamage.isEmpty
        ? rawScore
        : _scoreService.applyDamage(rawScore, profile.nukeDamage);
    final history = [...profile.history];
    final now = DateTime.now();
    final month = DateFormat.MMM().format(now);
    if (history.isEmpty || history.last.algorithmScore != score.overall) {
      history.add(ScoreHistoryPoint(
        month: month,
        algorithmScore: score.overall,
        communityRating: profile.ratingSummary.averageOverall,
        createdAt: now,
      ));
    }
    return profile.copyWith(
      score: score,
      history: history,
      updatedAt: now,
    );
  }

  /// Thin passthrough to `LifeScoreService.applyDamage` — used by
  /// `AppController.displayScoreFor` to overlay a mock/seed profile's
  /// local nuke damage without exposing `LifeScoreService` itself
  /// outside `domain/scoring`.
  LifeScore applyNukeDamage(LifeScore score, Map<String, int> damage) =>
      _scoreService.applyDamage(score, damage);

  bool isVisibleInDiscover(UserProfile profile, Set<String> blockedIds) {
    return profile.privacy.isPublic &&
        profile.privacy.showInDiscover &&
        !blockedIds.contains(profile.id);
  }

  bool isVisibleInLeaderboard(UserProfile profile, Set<String> blockedIds) {
    return profile.privacy.isPublic &&
        profile.privacy.showInLeaderboard &&
        !blockedIds.contains(profile.id) &&
        profile.ratingSummary.count > 0;
  }
}
