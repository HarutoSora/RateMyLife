import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

class PhotoVoteException implements Exception {
  const PhotoVoteException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PhotoVoteService {
  PhotoVoteService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// One vote per (voterId, profileId), like `RatingService.upsertRating`
  /// — voting again just moves the existing pick to a different photo.
  PhotoVote upsertVote({
    required List<PhotoVote> existing,
    required String voterId,
    required String profileId,
    required String photoId,
  }) {
    if (voterId == profileId) {
      throw const PhotoVoteException('You cannot vote on your own photos.');
    }

    final now = DateTime.now();
    for (final vote in existing) {
      if (vote.voterId == voterId && vote.profileId == profileId) {
        return vote.copyWith(photoId: photoId, createdAt: now);
      }
    }

    return PhotoVote(id: _uuid.v4(), voterId: voterId, profileId: profileId, photoId: photoId, createdAt: now);
  }

  PhotoVote? voteFor({required List<PhotoVote> votes, required String voterId, required String profileId}) {
    for (final vote in votes) {
      if (vote.voterId == voterId && vote.profileId == profileId) return vote;
    }
    return null;
  }
}
