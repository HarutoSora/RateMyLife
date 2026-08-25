import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../scoring/life_score_service.dart';

class ProfileService {
  ProfileService({LifeScoreService? scoreService})
      : _scoreService = scoreService ?? const LifeScoreService();

  final LifeScoreService _scoreService;

  UserProfile recalculate(UserProfile profile) {
    final score = _scoreService.calculate(profile);
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
