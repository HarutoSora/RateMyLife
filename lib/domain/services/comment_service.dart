import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

/// Thrown by `CommentService` for any rule violation — always carries a
/// user-facing message so `AppController` can surface it as a toast
/// without re-deriving what went wrong.
class CommentValidationException implements Exception {
  const CommentValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CommentService {
  CommentService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Architectural rate limit (spec: "Rate limiting should be supported
  /// architecturally") — generous enough not to interfere with normal
  /// use, tight enough to stop a runaway loop or accidental double-tap
  /// spam.
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const int rateLimitMax = 5;

  /// Throws [CommentValidationException] with a user-facing message if
  /// [authorId] should not be allowed to comment on [profileOwnerId]
  /// right now. Callers gather each fact separately (rather than this
  /// method reaching into repositories) so it stays pure and testable.
  void assertCanComment({
    required String authorId,
    required String profileOwnerId,
    required bool ownerAllowsComments,
    required bool ownerProfileIsPrivate,
    required bool isBlockedEitherWay,
    required List<Comment> authorsRecentComments,
  }) {
    if (authorId == profileOwnerId) {
      throw const CommentValidationException('You cannot comment on your own profile.');
    }
    if (ownerProfileIsPrivate || !ownerAllowsComments) {
      throw const CommentValidationException('Comments are disabled for this profile.');
    }
    if (isBlockedEitherWay) {
      throw const CommentValidationException('You cannot comment here.');
    }
    final windowStart = DateTime.now().subtract(rateLimitWindow);
    final recentCount = authorsRecentComments.where((c) => c.createdAt.isAfter(windowStart)).length;
    if (recentCount >= rateLimitMax) {
      throw const CommentValidationException("You're commenting too quickly. Try again in a moment.");
    }
  }

  Comment createComment({
    required String profileOwnerId,
    required String authorId,
    required String content,
  }) {
    final trimmed = _validatedText(content);
    final now = DateTime.now();
    return Comment(
      id: _uuid.v4(),
      profileOwnerId: profileOwnerId,
      authorId: authorId,
      content: trimmed,
      createdAt: now,
      updatedAt: now,
    );
  }

  Comment editComment(Comment existing, String requesterId, String newContent) {
    if (existing.isDeleted) {
      throw const CommentValidationException('This comment was deleted.');
    }
    if (existing.authorId != requesterId) {
      throw const CommentValidationException('You can only edit your own comments.');
    }
    return existing.copyWith(content: _validatedText(newContent), updatedAt: DateTime.now());
  }

  /// Blanks [existing]'s content (see `Comment`'s doc comment on why)
  /// and marks it deleted. Allowed for the comment's own author, or the
  /// profile owner removing a comment from their own profile.
  Comment deleteComment(Comment existing, String requesterId, String profileOwnerId) {
    final isAuthor = existing.authorId == requesterId;
    final isProfileOwner = profileOwnerId == requesterId;
    if (!isAuthor && !isProfileOwner) {
      throw const CommentValidationException('You cannot delete this comment.');
    }
    return existing.copyWith(content: '', isDeleted: true, updatedAt: DateTime.now());
  }

  bool canEdit(Comment comment, String userId) => !comment.isDeleted && comment.authorId == userId;

  bool canDelete(Comment comment, String userId, String profileOwnerId) =>
      !comment.isDeleted && (comment.authorId == userId || profileOwnerId == userId);

  /// Comments visible to a viewer on [profileOwnerId]'s profile —
  /// excludes deleted, moderator-hidden, anyone the viewer has blocked,
  /// and (a simple per-viewer self-hide, not a moderation action)
  /// anything the viewer has already reported themselves. Newest first.
  List<Comment> visibleComments(
    List<Comment> all,
    String profileOwnerId, {
    required Set<String> blockedByViewer,
    required Set<String> reportedByViewer,
  }) {
    return all
        .where((c) =>
            c.profileOwnerId == profileOwnerId &&
            !c.isDeleted &&
            !c.isHidden &&
            !blockedByViewer.contains(c.authorId) &&
            !reportedByViewer.contains(c.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CommentReaction? existingReaction(
    List<CommentReaction> reactions,
    String commentId,
    String userId,
    CommentReactionType type,
  ) {
    for (final reaction in reactions) {
      if (reaction.commentId == commentId && reaction.userId == userId && reaction.type == type) {
        return reaction;
      }
    }
    return null;
  }

  Map<CommentReactionType, int> reactionCounts(List<CommentReaction> reactions, String commentId) {
    final counts = <CommentReactionType, int>{};
    for (final reaction in reactions) {
      if (reaction.commentId != commentId) continue;
      counts[reaction.type] = (counts[reaction.type] ?? 0) + 1;
    }
    return counts;
  }

  String _validatedText(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const CommentValidationException('Comment cannot be empty.');
    }
    if (trimmed.length > Comment.maxLength) {
      throw const CommentValidationException('Comments can be at most ${Comment.maxLength} characters.');
    }
    return trimmed;
  }
}
