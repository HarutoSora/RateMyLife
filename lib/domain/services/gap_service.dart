import '../../data/models/models.dart';

/// Where the algorithm's Life Score and the community's rating disagree
/// the most — reframes the disagreement the Score screen already names
/// as part of the game ("Algorithm vs People... that difference is part
/// of the game") into a discovery hook. Pure math over data the app
/// already computes; no new model, no new scoring.
class GapService {
  const GapService({this.minRatings = 3});

  /// Profiles with fewer ratings than this are excluded — a gap against
  /// one or two ratings is noise, not a real disagreement.
  final int minRatings;

  /// The community's 0-5 star average, rescaled to the same 0-100 scale
  /// as the algorithm's Life Score, so the two are directly comparable.
  int communityScoreOf(RatingSummary summary) => (summary.averageOverall * 20).round().clamp(0, 100);

  /// Null when the profile doesn't yet have enough ratings to measure a
  /// meaningful gap.
  int? gapFor(UserProfile profile) {
    if (profile.ratingSummary.count < minRatings) return null;
    return (profile.score.overall - communityScoreOf(profile.ratingSummary)).abs();
  }

  /// Eligible profiles (enough ratings), biggest disagreement first.
  List<UserProfile> rankByGap(List<UserProfile> profiles) {
    final eligible = profiles.where((profile) => gapFor(profile) != null).toList()
      ..sort((a, b) => gapFor(b)!.compareTo(gapFor(a)!));
    return eligible;
  }
}
