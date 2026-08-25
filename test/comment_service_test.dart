import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/comment_service.dart';

Comment _comment({
  String id = 'c1',
  String profileOwnerId = 'owner',
  String authorId = 'author',
  String content = 'Nice life!',
  bool isDeleted = false,
  bool isHidden = false,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return Comment(
    id: id,
    profileOwnerId: profileOwnerId,
    authorId: authorId,
    content: content,
    createdAt: now,
    updatedAt: now,
    isDeleted: isDeleted,
    isHidden: isHidden,
  );
}

void main() {
  group('CommentService.assertCanComment', () {
    final service = CommentService();

    test('blocks commenting on your own profile', () {
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'u1',
          ownerAllowsComments: true,
          ownerProfileIsPrivate: false,
          isBlockedEitherWay: false,
          authorsRecentComments: const [],
        ),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('blocks commenting on a private profile', () {
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'owner',
          ownerAllowsComments: true,
          ownerProfileIsPrivate: true,
          isBlockedEitherWay: false,
          authorsRecentComments: const [],
        ),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('blocks commenting when the owner disabled comments', () {
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'owner',
          ownerAllowsComments: false,
          ownerProfileIsPrivate: false,
          isBlockedEitherWay: false,
          authorsRecentComments: const [],
        ),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('blocks commenting when blocked', () {
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'owner',
          ownerAllowsComments: true,
          ownerProfileIsPrivate: false,
          isBlockedEitherWay: true,
          authorsRecentComments: const [],
        ),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('rate limits after too many comments in the window', () {
      final now = DateTime.now();
      final recent = List.generate(
        CommentService.rateLimitMax,
        (i) => _comment(id: 'r$i', createdAt: now.subtract(const Duration(seconds: 5))),
      );
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'owner',
          ownerAllowsComments: true,
          ownerProfileIsPrivate: false,
          isBlockedEitherWay: false,
          authorsRecentComments: recent,
        ),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('old comments outside the rate-limit window do not count', () {
      final old = List.generate(
        CommentService.rateLimitMax + 5,
        (i) => _comment(id: 'o$i', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
      );
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'owner',
          ownerAllowsComments: true,
          ownerProfileIsPrivate: false,
          isBlockedEitherWay: false,
          authorsRecentComments: old,
        ),
        returnsNormally,
      );
    });

    test('allows a normal comment', () {
      expect(
        () => service.assertCanComment(
          authorId: 'u1',
          profileOwnerId: 'owner',
          ownerAllowsComments: true,
          ownerProfileIsPrivate: false,
          isBlockedEitherWay: false,
          authorsRecentComments: const [],
        ),
        returnsNormally,
      );
    });
  });

  group('CommentService.createComment', () {
    final service = CommentService();

    test('rejects empty content', () {
      expect(
        () => service.createComment(profileOwnerId: 'owner', authorId: 'u1', content: '   '),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('rejects content over the max length', () {
      final tooLong = 'a' * (Comment.maxLength + 1);
      expect(
        () => service.createComment(profileOwnerId: 'owner', authorId: 'u1', content: tooLong),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('accepts content exactly at the max length', () {
      final exact = 'a' * Comment.maxLength;
      final comment = service.createComment(profileOwnerId: 'owner', authorId: 'u1', content: exact);
      expect(comment.content, exact);
    });

    test('trims whitespace', () {
      final comment = service.createComment(profileOwnerId: 'owner', authorId: 'u1', content: '  hello  ');
      expect(comment.content, 'hello');
    });
  });

  group('CommentService.editComment', () {
    final service = CommentService();

    test('only the author can edit', () {
      final comment = _comment(authorId: 'author');
      expect(
        () => service.editComment(comment, 'someone_else', 'edited'),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('a deleted comment cannot be edited', () {
      final comment = _comment(authorId: 'author', isDeleted: true);
      expect(
        () => service.editComment(comment, 'author', 'edited'),
        throwsA(isA<CommentValidationException>()),
      );
    });

    test('the author can edit their own comment', () {
      final comment = _comment(authorId: 'author', content: 'original');
      final edited = service.editComment(comment, 'author', 'updated text');
      expect(edited.content, 'updated text');
      expect(edited.updatedAt.isAfter(comment.updatedAt) || edited.updatedAt.isAtSameMomentAs(comment.updatedAt), isTrue);
    });
  });

  group('CommentService.deleteComment', () {
    final service = CommentService();

    test('the author can delete their own comment', () {
      final comment = _comment(authorId: 'author', profileOwnerId: 'owner', content: 'secret rant');
      final deleted = service.deleteComment(comment, 'author', 'owner');
      expect(deleted.isDeleted, isTrue);
      expect(deleted.content, isEmpty); // original content must not survive deletion
    });

    test('the profile owner can delete a comment on their own profile', () {
      final comment = _comment(authorId: 'author', profileOwnerId: 'owner', content: 'rude comment');
      final deleted = service.deleteComment(comment, 'owner', 'owner');
      expect(deleted.isDeleted, isTrue);
      expect(deleted.content, isEmpty);
    });

    test('a random third party cannot delete the comment', () {
      final comment = _comment(authorId: 'author', profileOwnerId: 'owner');
      expect(
        () => service.deleteComment(comment, 'random_user', 'owner'),
        throwsA(isA<CommentValidationException>()),
      );
    });
  });

  group('CommentService permission checks', () {
    final service = CommentService();

    test('canEdit is true only for the author on a non-deleted comment', () {
      final comment = _comment(authorId: 'author');
      expect(service.canEdit(comment, 'author'), isTrue);
      expect(service.canEdit(comment, 'someone_else'), isFalse);
      expect(service.canEdit(comment.copyWith(isDeleted: true), 'author'), isFalse);
    });

    test('canDelete is true for the author or the profile owner', () {
      final comment = _comment(authorId: 'author', profileOwnerId: 'owner');
      expect(service.canDelete(comment, 'author', 'owner'), isTrue);
      expect(service.canDelete(comment, 'owner', 'owner'), isTrue);
      expect(service.canDelete(comment, 'random_user', 'owner'), isFalse);
    });
  });

  group('CommentService.visibleComments', () {
    final service = CommentService();

    test('excludes deleted, hidden, blocked authors, and self-reported comments', () {
      final all = [
        _comment(id: 'visible', profileOwnerId: 'owner', authorId: 'a1'),
        _comment(id: 'deleted', profileOwnerId: 'owner', authorId: 'a2', isDeleted: true),
        _comment(id: 'hidden', profileOwnerId: 'owner', authorId: 'a3', isHidden: true),
        _comment(id: 'blocked_author', profileOwnerId: 'owner', authorId: 'blocked_user'),
        _comment(id: 'self_reported', profileOwnerId: 'owner', authorId: 'a4'),
        _comment(id: 'other_profile', profileOwnerId: 'someone_else', authorId: 'a5'),
      ];

      final visible = service.visibleComments(
        all,
        'owner',
        blockedByViewer: {'blocked_user'},
        reportedByViewer: {'self_reported'},
      );

      expect(visible.map((c) => c.id), ['visible']);
    });

    test('sorts newest first', () {
      final all = [
        _comment(id: 'old', profileOwnerId: 'owner', createdAt: DateTime(2026, 1, 1)),
        _comment(id: 'new', profileOwnerId: 'owner', createdAt: DateTime(2026, 6, 1)),
        _comment(id: 'mid', profileOwnerId: 'owner', createdAt: DateTime(2026, 3, 1)),
      ];
      final visible = service.visibleComments(all, 'owner', blockedByViewer: const {}, reportedByViewer: const {});
      expect(visible.map((c) => c.id), ['new', 'mid', 'old']);
    });
  });

  group('CommentService reactions', () {
    final service = CommentService();

    test('existingReaction finds a matching (comment, user, type) combination', () {
      final reactions = [
        CommentReaction(id: 'r1', commentId: 'c1', profileOwnerId: 'p1', userId: 'u1', type: CommentReactionType.heart, createdAt: DateTime(2026)),
      ];
      expect(service.existingReaction(reactions, 'c1', 'u1', CommentReactionType.heart), isNotNull);
      expect(service.existingReaction(reactions, 'c1', 'u1', CommentReactionType.fire), isNull);
      expect(service.existingReaction(reactions, 'c1', 'u2', CommentReactionType.heart), isNull);
    });

    test('reactionCounts aggregates by type for one comment', () {
      final reactions = [
        CommentReaction(id: 'r1', commentId: 'c1', profileOwnerId: 'p1', userId: 'u1', type: CommentReactionType.heart, createdAt: DateTime(2026)),
        CommentReaction(id: 'r2', commentId: 'c1', profileOwnerId: 'p1', userId: 'u2', type: CommentReactionType.heart, createdAt: DateTime(2026)),
        CommentReaction(id: 'r3', commentId: 'c1', profileOwnerId: 'p1', userId: 'u1', type: CommentReactionType.fire, createdAt: DateTime(2026)),
        CommentReaction(id: 'r4', commentId: 'c2', profileOwnerId: 'p1', userId: 'u3', type: CommentReactionType.heart, createdAt: DateTime(2026)),
      ];
      final counts = service.reactionCounts(reactions, 'c1');
      expect(counts[CommentReactionType.heart], 2);
      expect(counts[CommentReactionType.fire], 1);
      expect(counts[CommentReactionType.laugh], isNull);
    });
  });
}
