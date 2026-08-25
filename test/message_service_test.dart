import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/message_service.dart';

void main() {
  group('MessageService', () {
    final service = MessageService();

    test('conversationIdFor is stable regardless of argument order', () {
      expect(service.conversationIdFor('a', 'b'), service.conversationIdFor('b', 'a'));
    });

    test('conversationIdFor differs for a different pair', () {
      expect(service.conversationIdFor('a', 'b'), isNot(service.conversationIdFor('a', 'c')));
    });

    test('createMessage stamps the conversation id and trims content', () {
      final message = service.createMessage(senderId: 'a', recipientId: 'b', content: '  hi  ');
      expect(message.conversationId, service.conversationIdFor('a', 'b'));
      expect(message.content, 'hi');
      expect(message.senderId, 'a');
      expect(message.recipientId, 'b');
    });

    test('createMessage rejects empty content', () {
      expect(
        () => service.createMessage(senderId: 'a', recipientId: 'b', content: '   '),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test('createMessage rejects content over the max length', () {
      expect(
        () => service.createMessage(senderId: 'a', recipientId: 'b', content: 'x' * (Message.maxLength + 1)),
        throwsA(isA<MessageValidationException>()),
      );
    });

    group('assertCanMessage', () {
      void assertOk({
        String senderId = 'a',
        String recipientId = 'b',
        bool recipientAllowsMessages = true,
        bool recipientProfileIsPrivate = false,
        bool isBlockedEitherWay = false,
        List<Message> sendersRecentMessages = const [],
      }) {
        service.assertCanMessage(
          senderId: senderId,
          recipientId: recipientId,
          recipientAllowsMessages: recipientAllowsMessages,
          recipientProfileIsPrivate: recipientProfileIsPrivate,
          isBlockedEitherWay: isBlockedEitherWay,
          sendersRecentMessages: sendersRecentMessages,
        );
      }

      test('allows a normal message', () {
        expect(() => assertOk(), returnsNormally);
      });

      test('refuses messaging yourself', () {
        expect(() => assertOk(senderId: 'a', recipientId: 'a'), throwsA(isA<MessageValidationException>()));
      });

      test('refuses when the recipient disabled messages', () {
        expect(() => assertOk(recipientAllowsMessages: false), throwsA(isA<MessageValidationException>()));
      });

      test('refuses when the recipient profile is private', () {
        expect(() => assertOk(recipientProfileIsPrivate: true), throwsA(isA<MessageValidationException>()));
      });

      test('refuses when blocked either way', () {
        expect(() => assertOk(isBlockedEitherWay: true), throwsA(isA<MessageValidationException>()));
      });

      test('refuses once the rate limit is hit', () {
        final now = DateTime.now();
        final recent = List.generate(
          MessageService.rateLimitMax,
          (i) => Message(id: '$i', conversationId: 'c', senderId: 'a', recipientId: 'other_$i', content: 'hi', createdAt: now),
        );
        expect(() => assertOk(sendersRecentMessages: recent), throwsA(isA<MessageValidationException>()));
      });

      test('an old message outside the rate-limit window does not count', () {
        final old = Message(
          id: '1',
          conversationId: 'c',
          senderId: 'a',
          recipientId: 'b',
          content: 'hi',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(() => assertOk(sendersRecentMessages: [old]), returnsNormally);
      });
    });

    group('conversationBetween', () {
      test('returns only messages in that thread, oldest first', () {
        final now = DateTime.now();
        final m1 = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'first', createdAt: now);
        final m2 = Message(id: '2', conversationId: 'a_b', senderId: 'b', recipientId: 'a', content: 'second', createdAt: now.add(const Duration(minutes: 1)));
        final other = Message(id: '3', conversationId: 'a_c', senderId: 'a', recipientId: 'c', content: 'unrelated', createdAt: now);

        final thread = service.conversationBetween([m2, m1, other], 'a', 'b', isBlockedEitherWay: false);

        expect(thread.map((m) => m.id), ['1', '2']);
      });

      test('returns nothing when blocked either way', () {
        final now = DateTime.now();
        final m1 = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'hi', createdAt: now);
        expect(service.conversationBetween([m1], 'a', 'b', isBlockedEitherWay: true), isEmpty);
      });

      test('excludes messages at or before hiddenAt, but keeps ones after it', () {
        final now = DateTime.now();
        final before = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'old', createdAt: now);
        final atCutoff = Message(id: '2', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'exactly at cutoff', createdAt: now.add(const Duration(minutes: 1)));
        final after = Message(id: '3', conversationId: 'a_b', senderId: 'b', recipientId: 'a', content: 'new', createdAt: now.add(const Duration(minutes: 2)));

        final thread = service.conversationBetween(
          [before, atCutoff, after],
          'a',
          'b',
          isBlockedEitherWay: false,
          hiddenAt: now.add(const Duration(minutes: 1)),
        );

        expect(thread.map((m) => m.id), ['3']);
      });
    });

    group('latestMessagePerConversation', () {
      test('one entry per conversation, the most recent message, newest conversation first', () {
        final now = DateTime.now();
        final aOld = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'old', createdAt: now);
        final aNew = Message(id: '2', conversationId: 'a_b', senderId: 'b', recipientId: 'a', content: 'new', createdAt: now.add(const Duration(minutes: 5)));
        final cMsg = Message(id: '3', conversationId: 'a_c', senderId: 'a', recipientId: 'c', content: 'hi c', createdAt: now.subtract(const Duration(minutes: 5)));

        final result = service.latestMessagePerConversation([aOld, aNew, cMsg], 'a', blockedIds: {});

        expect(result.map((m) => m.id), ['2', '3']);
      });

      test('excludes conversations with a blocked user', () {
        final now = DateTime.now();
        final blocked = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'hi', createdAt: now);
        expect(service.latestMessagePerConversation([blocked], 'a', blockedIds: {'b'}), isEmpty);
      });

      test('ignores messages not involving this user', () {
        final now = DateTime.now();
        final unrelated = Message(id: '1', conversationId: 'x_y', senderId: 'x', recipientId: 'y', content: 'hi', createdAt: now);
        expect(service.latestMessagePerConversation([unrelated], 'a', blockedIds: {}), isEmpty);
      });

      test('excludes a conversation whose only messages are at or before its hiddenAt cutoff', () {
        final now = DateTime.now();
        final old = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'old', createdAt: now);
        expect(
          service.latestMessagePerConversation(
            [old],
            'a',
            blockedIds: {},
            hiddenAtByOtherId: {'b': now.add(const Duration(minutes: 1))},
          ),
          isEmpty,
        );
      });

      test('a message after the hiddenAt cutoff revives the conversation', () {
        final now = DateTime.now();
        final old = Message(id: '1', conversationId: 'a_b', senderId: 'a', recipientId: 'b', content: 'old', createdAt: now);
        final revived = Message(id: '2', conversationId: 'a_b', senderId: 'b', recipientId: 'a', content: 'new', createdAt: now.add(const Duration(minutes: 5)));

        final result = service.latestMessagePerConversation(
          [old, revived],
          'a',
          blockedIds: {},
          hiddenAtByOtherId: {'b': now.add(const Duration(minutes: 1))},
        );

        expect(result.map((m) => m.id), ['2']);
      });
    });
  });
}
