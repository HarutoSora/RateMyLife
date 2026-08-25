import '../../data/models/models.dart';

/// "New & Rising" rather than a true real-time velocity feed — there's
/// no historical view/rating time-series stored anywhere to compute an
/// honest growth rate from, and fabricating one would violate this
/// project's own no-fake-data stance. Instead: real profiles created
/// recently, ranked by the real engagement they've already earned.
class TrendingService {
  const TrendingService({this.windowDays = 14});

  /// How far back "recently created" reaches.
  final int windowDays;

  /// Ratings count for more than plain views — a rating is a much
  /// stronger engagement signal than a passive view.
  int engagementScoreOf(UserProfile profile) => profile.viewCount + profile.ratingSummary.count * 3;

  bool isRecent(UserProfile profile, DateTime now) => now.difference(profile.createdAt).inDays <= windowDays;

  /// Recently-created profiles ranked by real engagement, highest first;
  /// ties broken by newest first.
  List<UserProfile> rank(List<UserProfile> profiles, {DateTime? now}) {
    final resolvedNow = now ?? DateTime.now();
    final eligible = profiles.where((profile) => isRecent(profile, resolvedNow)).toList()
      ..sort((a, b) {
        final byEngagement = engagementScoreOf(b).compareTo(engagementScoreOf(a));
        if (byEngagement != 0) return byEngagement;
        return b.createdAt.compareTo(a.createdAt);
      });
    return eligible;
  }
}
