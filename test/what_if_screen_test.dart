import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/scoring/life_score_service.dart';
import 'package:rate_my_life/presentation/screens/screens.dart';

const _service = LifeScoreService();

UserProfile _profile() {
  final now = DateTime(2026);
  final base = UserProfile(
    id: 'me',
    displayName: 'Tester',
    age: 28,
    country: 'Morocco',
    city: 'Rabat',
    employmentStatus: 'Employed',
    jobCategory: 'Technology',
    yearsExperience: 5,
    educationLevel: 'Bachelor',
    monthlyIncome: 10000,
    currency: 'MAD',
    savings: 50000,
    investments: 0,
    debt: 0,
    monthlyExpenses: 4000,
    relationshipStatus: 'Single',
    livingSituation: 'Rents apartment',
    ownsCar: false,
    ownsHome: false,
    travelFrequency: 'Once/year',
    exerciseFrequency: 'Weekly',
    hobbies: const ['Travel'],
    freeTimeHours: 12,
    closeFriends: 4,
    happiness: 7,
    stress: 4,
    currentGoal: 'Grow',
    bio: 'Building.',
    photos: const [],
    score: LifeScore.empty(),
    ratingSummary: const RatingSummary(),
    history: const [],
    privacy: const ProfilePrivacy(),
    createdAt: now,
    updatedAt: now,
  );
  return base.copyWith(score: _service.calculate(base));
}

Future<void> _pump(WidgetTester tester, UserProfile profile) async {
  // Make the test surface tall enough that every lever in the scrolling
  // simulator is realized in the widget tree (a plain ListView only builds
  // children near the viewport, so off-screen chips are otherwise
  // invisible to finders/taps).
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: WhatIfScreen(original: profile)));
  await tester.pumpAndSettle();
}

void main() {
  group('WhatIfScreen', () {
    testWidgets('starts with the simulated score equal to the real score (±0 delta)', (tester) async {
      final profile = _profile();
      await _pump(tester, profile);

      expect(find.byKey(const Key('whatIfAfterOverall')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('whatIfAfterOverall'))).data, '${profile.score.overall}');
      expect(tester.widget<Text>(find.byKey(const Key('whatIfDeltaOverall'))).data, '±0');
    });

    testWidgets('switching to Unemployed moves the simulated score away from the real one', (tester) async {
      final profile = _profile();
      await _pump(tester, profile);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Unemployed'));
      await tester.pumpAndSettle();

      final afterText = tester.widget<Text>(find.byKey(const Key('whatIfAfterOverall'))).data;
      expect(afterText, isNot('${profile.score.overall}'));
      expect(tester.widget<Text>(find.byKey(const Key('whatIfDeltaOverall'))).data, isNot('±0'));
    });

    testWidgets('RESET restores the original values after a change', (tester) async {
      final profile = _profile();
      await _pump(tester, profile);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Unemployed'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(const Key('whatIfDeltaOverall'))).data, isNot('±0'));

      await tester.tap(find.text('RESET'));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('whatIfAfterOverall'))).data, '${profile.score.overall}');
      expect(tester.widget<Text>(find.byKey(const Key('whatIfDeltaOverall'))).data, '±0');
      final employedChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Employed'));
      expect(employedChip.selected, isTrue);
    });
  });
}
