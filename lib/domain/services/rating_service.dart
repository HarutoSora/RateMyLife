import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

class RatingException implements Exception {
  const RatingException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RatingService {
  RatingService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Rating upsertRating({
    required List<Rating> existing,
    required String raterId,
    required String profileId,
    required int overall,
    int? look,
    int? career,
    int? lifestyle,
    int? social,
    int? independence,
    int? experiences,
  }) {
    if (raterId == profileId) {
      throw const RatingException('You cannot rate your own life.');
    }
    if (overall < 1 || overall > 5) {
      throw const RatingException('Choose a life rating from 1 to 5.');
    }
    if (look != null && (look < 1 || look > 5)) {
      throw const RatingException('Choose a look rating from 1 to 5.');
    }

    final now = DateTime.now();
    for (final rating in existing) {
      if (rating.raterId == raterId && rating.profileId == profileId) {
        return rating.copyWith(
          overall: overall,
          look: look,
          career: career,
          lifestyle: lifestyle,
          social: social,
          independence: independence,
          experiences: experiences,
          updatedAt: now,
        );
      }
    }

    return Rating(
      id: _uuid.v4(),
      raterId: raterId,
      profileId: profileId,
      overall: overall,
      look: look,
      career: career,
      lifestyle: lifestyle,
      social: social,
      independence: independence,
      experiences: experiences,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Rating> removeRating({
    required List<Rating> existing,
    required String raterId,
    required String profileId,
  }) {
    return existing
        .where((rating) =>
            rating.raterId != raterId || rating.profileId != profileId)
        .toList();
  }

  Rating? ratingFor({
    required List<Rating> ratings,
    required String raterId,
    required String profileId,
  }) {
    for (final rating in ratings) {
      if (rating.raterId == raterId && rating.profileId == profileId) {
        return rating;
      }
    }
    return null;
  }

  RatingSummary summaryFor(String profileId, List<Rating> ratings) {
    final scoped =
        ratings.where((rating) => rating.profileId == profileId).toList();
    if (scoped.isEmpty) return const RatingSummary();

    double average(Iterable<int?> values) {
      final valid = values.whereType<int>().toList();
      if (valid.isEmpty) return 0;
      return valid.reduce((a, b) => a + b) / valid.length;
    }

    return RatingSummary(
      averageOverall: average(scoped.map((rating) => rating.overall)),
      averageLook: average(scoped.map((rating) => rating.look)),
      count: scoped.length,
      averageCareer: average(scoped.map((rating) => rating.career)),
      averageLifestyle: average(scoped.map((rating) => rating.lifestyle)),
      averageSocial: average(scoped.map((rating) => rating.social)),
      averageIndependence:
          average(scoped.map((rating) => rating.independence)),
      averageExperiences: average(scoped.map((rating) => rating.experiences)),
    );
  }
}
