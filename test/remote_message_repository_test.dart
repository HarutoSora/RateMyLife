import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

Message _message(String id, {required String senderId, required String recipientId, bool isRead = false}) => Message(
      id: id,
      conversationId: ([senderId, recipientId]..sort()).join('_'),
      senderId: senderId,
      recipientId: recipientId,
      content: 'hello',
      createdAt: DateTime(2026, 1, 1),
      isRead: isRead,
    );

void main() {
  group('RemoteMessageRepository', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late RemoteMessageRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
      repo = RemoteMessageRepository(firestore: firestore, auth: auth);
    });

    test('loadMessages starts empty', () async {
      expect(await repo.loadMessages(), isEmpty);
    });

    test('saveMessages persists a message this device sent', () async {
      await repo.loadMessages();
      await repo.saveMessages([_message('m1', senderId: 'me', recipientId: 'them')]);

      final loaded = await repo.loadMessages();
      expect(loaded.single.id, 'm1');
    });

    test('only loads messages this device is a participant in, as sender or recipient', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemoteMessageRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadMessages();
      // A conversation between two people that don't include "me" at all.
      await otherRepo.saveMessages([_message('unrelated', senderId: 'other', recipientId: 'someone_else')]);

      await repo.loadMessages();
      await repo.saveMessages([_message('to_me', senderId: 'other_sender', recipientId: 'me')]);

      final loaded = await repo.loadMessages();
      expect(loaded.map((m) => m.id), ['to_me']);
    });

    test('does not rewrite an already-known, unchanged message', () async {
      await repo.loadMessages();
      await repo.saveMessages([_message('m1', senderId: 'me', recipientId: 'them')]);
      await repo.saveMessages([_message('m1', senderId: 'me', recipientId: 'them'), _message('m2', senderId: 'me', recipientId: 'them')]);

      expect(await firestore.collection('messages').get().then((s) => s.docs), hasLength(2));
    });

    test('rewrites a message whose isRead flag changed', () async {
      await repo.loadMessages();
      await repo.saveMessages([_message('m1', senderId: 'them', recipientId: 'me', isRead: false)]);
      await repo.saveMessages([_message('m1', senderId: 'them', recipientId: 'me', isRead: true)]);

      final loaded = await repo.loadMessages();
      expect(loaded.single.isRead, isTrue);
    });

    test('a message missing from the next save is deleted (sender deleted it)', () async {
      await repo.loadMessages();
      await repo.saveMessages([_message('m1', senderId: 'me', recipientId: 'them'), _message('m2', senderId: 'me', recipientId: 'them')]);
      await repo.saveMessages([_message('m1', senderId: 'me', recipientId: 'them')]);

      final loaded = await repo.loadMessages();
      expect(loaded.map((m) => m.id), ['m1']);
      expect(await firestore.collection('messages').get().then((s) => s.docs), hasLength(1));
    });
  });
}
