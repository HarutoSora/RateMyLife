import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

/// Thrown by `MessageService` for any rule violation — always carries a
/// user-facing message so `AppController` can surface it as a toast
/// without re-deriving what went wrong.
class MessageValidationException implements Exception {
  const MessageValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MessageService {
  MessageService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Same rate limit shape as `CommentService` — generous enough not to
  /// interfere with a real conversation, tight enough to stop a spam
  /// burst to one or many recipients.
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const int rateLimitMax = 5;

  /// The two participant ids, sorted and joined — stable regardless of
  /// who's the sender in a given message, so every message between the
  /// same pair shares one queryable conversation id.
  String conversationIdFor(String userIdA, String userIdB) {
    final sorted = [userIdA, userIdB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Throws [MessageValidationException] with a user-facing message if
  /// [senderId] should not be allowed to message [recipientId] right
  /// now. Callers gather each fact separately (rather than this method
  /// reaching into repositories) so it stays pure and testable.
  void assertCanMessage({
    required String senderId,
    required String recipientId,
    required bool recipientAllowsMessages,
    required bool recipientProfileIsPrivate,
    required bool isBlockedEitherWay,
    required List<Message> sendersRecentMessages,
  }) {
    if (senderId == recipientId) {
      throw const MessageValidationException('You cannot message yourself.');
    }
    if (recipientProfileIsPrivate || !recipientAllowsMessages) {
      throw const MessageValidationException('This person has messages turned off.');
    }
    if (isBlockedEitherWay) {
      throw const MessageValidationException('You cannot message this person.');
    }
    final windowStart = DateTime.now().subtract(rateLimitWindow);
    final recentCount = sendersRecentMessages.where((m) => m.createdAt.isAfter(windowStart)).length;
    if (recentCount >= rateLimitMax) {
      throw const MessageValidationException("You're sending messages too quickly. Try again in a moment.");
    }
  }

  Message createMessage({
    required String senderId,
    required String recipientId,
    required String content,
  }) {
    final trimmed = _validatedText(content);
    return Message(
      id: _uuid.v4(),
      conversationId: conversationIdFor(senderId, recipientId),
      senderId: senderId,
      recipientId: recipientId,
      content: trimmed,
      createdAt: DateTime.now(),
    );
  }

  /// Messages in the thread between [userId] and [otherUserId], oldest
  /// first (chat order) — excludes anything if either side has blocked
  /// the other, so a stale thread can't linger after a block. Also
  /// excludes anything at or before [hiddenAt], if the caller deleted
  /// this conversation from their own inbox — a message sent after that
  /// point still shows, naturally reviving the thread.
  List<Message> conversationBetween(
    List<Message> all,
    String userId,
    String otherUserId, {
    required bool isBlockedEitherWay,
    DateTime? hiddenAt,
  }) {
    if (isBlockedEitherWay) return const [];
    final conversationId = conversationIdFor(userId, otherUserId);
    return all
        .where((m) => m.conversationId == conversationId && (hiddenAt == null || m.createdAt.isAfter(hiddenAt)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// One entry per conversation [userId] is part of, most recent
  /// message first — excludes any conversation with someone [userId]
  /// has blocked or been blocked by, and any conversation whose only
  /// messages are at or before that thread's own entry in
  /// [hiddenAtByOtherId] (the caller deleted it from their own inbox
  /// and nothing new has arrived since).
  List<Message> latestMessagePerConversation(
    List<Message> all,
    String userId, {
    required Set<String> blockedIds,
    Map<String, DateTime> hiddenAtByOtherId = const {},
  }) {
    final mine = all.where((m) => m.senderId == userId || m.recipientId == userId);
    final latestByConversation = <String, Message>{};
    for (final message in mine) {
      final otherId = message.senderId == userId ? message.recipientId : message.senderId;
      if (blockedIds.contains(otherId)) continue;
      final hiddenAt = hiddenAtByOtherId[otherId];
      if (hiddenAt != null && !message.createdAt.isAfter(hiddenAt)) continue;
      final current = latestByConversation[message.conversationId];
      if (current == null || message.createdAt.isAfter(current.createdAt)) {
        latestByConversation[message.conversationId] = message;
      }
    }
    final result = latestByConversation.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  String _validatedText(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const MessageValidationException('Message cannot be empty.');
    }
    if (trimmed.length > Message.maxLength) {
      throw const MessageValidationException('Messages can be at most ${Message.maxLength} characters.');
    }
    return trimmed;
  }
}
