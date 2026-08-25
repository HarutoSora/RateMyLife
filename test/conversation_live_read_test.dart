import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/presentation/screens/screens.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

UserProfile _profile(String id) {
  final now = DateTime(2026);
  return UserProfile(
    id: id,
    displayName: id,
    age: 24,
    country: 'Morocco',
    city: 'City',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    yearsExperience: 2,
    educationLevel: 'Bachelor',
    monthlyIncome: 5000,
    currency: 'MAD',
    savings: 10000,
    investments: 0,
    debt: 0,
    monthlyExpenses: 1000,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: false,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const [],
    freeTimeHours: 10,
    closeFriends: 3,
    happiness: 7,
    stress: 3,
    currentGoal: 'Grow',
    bio: '',
    photos: const [],
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.them);
  final UserProfile them;

  @override
  Future<void> deleteCurrentProfile() async {}
  @override
  Future<UserProfile?> loadCurrentProfile() async => null;
  @override
  Future<UserProfile?> loadProfileById(String id) async => id == them.id ? them : null;
  @override
  Future<void> saveCurrentProfile(UserProfile profile) async {}
  @override
  String newProfileId() => 'user_test';
  @override
  Future<void> recordProfileView(String profileId) async {}
  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[them], hasMore: false);
  @override
  Future<ProfilesPage> loadLeaderboardPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);
  @override
  Future<ProfilesPage> loadTrendingPage({int limit = 30, UserProfile? after, required DateTime since}) async =>
      (profiles: <UserProfile>[], hasMore: false);
  @override
  Future<ProfilesPage> loadGapPage({int limit = 30, UserProfile? after}) async =>
      (profiles: <UserProfile>[], hasMore: false);
}

class _FakeMessageRepository implements MessageRepository {
  List<Message> stored = [];
  final _updates = StreamController<List<Message>>.broadcast();

  @override
  Future<List<Message>> loadMessages() async => stored;

  // Mirrors RemoteMessageRepository's real shape: the current value
  // immediately, then whatever gets pushed afterward — lets the test
  // drive a "new message arrived live" update through the same
  // subscription path AppController actually uses, instead of poking
  // protected ChangeNotifier internals directly.
  @override
  Stream<List<Message>> watchMessages() async* {
    yield stored;
    yield* _updates.stream;
  }

  void push(List<Message> messages) {
    stored = messages;
    _updates.add(messages);
  }

  @override
  Future<void> saveMessages(List<Message> messages) async => stored = messages;
}

void main() {
  testWidgets('a message that arrives while the conversation is already open gets marked read too', (tester) async {
    final them = _profile('them');
    final messageRepo = _FakeMessageRepository()
      ..stored = [
        Message(id: 'm1', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'first', createdAt: DateTime(2026)),
      ];
    final bundle = RepositoryBundle(
      profileRepository: _FakeProfileRepository(them),
      messageRepository: messageRepo,
    );
    final container = ProviderContainer(overrides: [repositoryBundleProvider.overrideWithValue(bundle)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConversationScreen(otherUserId: 'them')),
      ),
    );
    await tester.pump();
    await tester.pump();

    final controller = container.read(appControllerProvider);
    // initState's one-shot markConversationRead already caught the
    // first message.
    expect(controller.unreadMessageCount, 0);

    // Simulate a second message arriving live (what the Firestore
    // listener does) while this same screen is still open — the
    // regression this test guards: without the build-time check, this
    // one would stay unread until the screen was reopened.
    messageRepo.push([
      ...controller.messages,
      Message(id: 'm2', conversationId: 'me_them', senderId: 'them', recipientId: 'me', content: 'second', createdAt: DateTime(2026, 1, 2)),
    ]);
    await tester.pump();
    await tester.pump();

    expect(controller.unreadMessageCount, 0);
  });
}
