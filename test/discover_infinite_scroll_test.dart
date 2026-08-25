import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';
import 'package:rate_my_life/presentation/screens/screens.dart';
import 'package:rate_my_life/presentation/state/app_state.dart';

UserProfile _profile(String id, DateTime createdAt) {
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
    createdAt: createdAt,
    updatedAt: now,
  );
}

/// Paginates a fixed pool exactly like `RemoteProfileRepository` does —
/// used to verify `DiscoverScreen` actually asks for more pages as the
/// user scrolls, not just that the first page renders.
class _PagedProfileRepository implements ProfileRepository {
  _PagedProfileRepository(this.all, {this.pageSize = 5});

  final List<UserProfile> all;
  final int pageSize;
  int discoverPageCalls = 0;

  @override
  Future<void> deleteCurrentProfile() async {}
  @override
  Future<UserProfile?> loadCurrentProfile() async => null;
  @override
  Future<UserProfile?> loadProfileById(String id) async => all.where((p) => p.id == id).firstOrNull;
  @override
  Future<void> saveCurrentProfile(UserProfile profile) async {}
  @override
  String newProfileId() => 'user_test';
  @override
  Future<void> recordProfileView(String profileId) async {}

  @override
  Future<ProfilesPage> loadDiscoverPage({int limit = 30, UserProfile? after}) async {
    discoverPageCalls++;
    var start = 0;
    if (after != null) {
      final index = all.indexWhere((p) => p.id == after.id);
      start = index == -1 ? all.length : index + 1;
    }
    final slice = all.skip(start).take(pageSize).toList();
    return (profiles: slice, hasMore: start + slice.length < all.length);
  }

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

void main() {
  testWidgets('scrolling Discover near the bottom fetches the next page', (tester) async {
    final now = DateTime(2026);
    final profiles = [for (var i = 0; i < 30; i++) _profile('p$i', now.subtract(Duration(days: i)))];
    final profileRepo = _PagedProfileRepository(profiles, pageSize: 5);

    final bundle = RepositoryBundle(profileRepository: profileRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryBundleProvider.overrideWithValue(bundle)],
        child: const MaterialApp(home: DiscoverScreen()),
      ),
    );
    // First page load completes.
    await tester.pump();
    await tester.pump();

    expect(profileRepo.discoverPageCalls, 1);

    // Drag the list up repeatedly to reach the scroll threshold that
    // triggers a fetch — explicit pumps, no pumpAndSettle (the
    // Discover card stack's own animations don't reliably settle in
    // the test harness).
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(DiscoverScreen), const Offset(0, -800));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
    await tester.pump();

    expect(profileRepo.discoverPageCalls, greaterThan(1));
  });
}
