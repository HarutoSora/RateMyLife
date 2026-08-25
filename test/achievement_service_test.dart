import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/achievement_service.dart';

AchievementStats _stats({
  bool hasProfile = false,
  int ratingsGiven = 0,
  int photoCount = 0,
  int scoreImprovement = 0,
  int level = 1,
  bool hasSharedProfile = false,
  int streakDays = 0,
  int battlesVoted = 0,
}) =>
    AchievementStats(
      hasProfile: hasProfile,
      ratingsGiven: ratingsGiven,
      photoCount: photoCount,
      scoreImprovement: scoreImprovement,
      level: level,
      hasSharedProfile: hasSharedProfile,
      streakDays: streakDays,
      battlesVoted: battlesVoted,
    );

void main() {
  group('AchievementService', () {
    const service = AchievementService();

    test('catalog ids are unique', () {
      final ids = AchievementService.catalog.map((a) => a.id).toSet();
      expect(ids, hasLength(AchievementService.catalog.length));
    });

    test('every achievement grants positive XP', () {
      for (final achievement in AchievementService.catalog) {
        expect(achievement.xpReward, greaterThan(0));
      }
    });

    test('first_steps unlocks once a profile exists', () {
      expect(service.isUnlocked('first_steps', _stats(hasProfile: false)), isFalse);
      expect(service.isUnlocked('first_steps', _stats(hasProfile: true)), isTrue);
    });

    test('rating_enthusiast and rating_machine use their real thresholds', () {
      expect(service.isUnlocked('rating_enthusiast', _stats(ratingsGiven: 9)), isFalse);
      expect(service.isUnlocked('rating_enthusiast', _stats(ratingsGiven: 10)), isTrue);
      expect(service.isUnlocked('rating_machine', _stats(ratingsGiven: 24)), isFalse);
      expect(service.isUnlocked('rating_machine', _stats(ratingsGiven: 25)), isTrue);
    });

    test('photogenic_life requires a full 8-photo gallery', () {
      expect(service.isUnlocked('photogenic_life', _stats(photoCount: 7)), isFalse);
      expect(service.isUnlocked('photogenic_life', _stats(photoCount: 8)), isTrue);
    });

    test('rising_star requires a 10+ point score improvement', () {
      expect(service.isUnlocked('rising_star', _stats(scoreImprovement: 9)), isFalse);
      expect(service.isUnlocked('rising_star', _stats(scoreImprovement: 10)), isTrue);
    });

    test('social_butterfly requires having shared', () {
      expect(service.isUnlocked('social_butterfly', _stats(hasSharedProfile: false)), isFalse);
      expect(service.isUnlocked('social_butterfly', _stats(hasSharedProfile: true)), isTrue);
    });

    test('established and legendary use their level thresholds', () {
      expect(service.isUnlocked('established', _stats(level: 24)), isFalse);
      expect(service.isUnlocked('established', _stats(level: 25)), isTrue);
      expect(service.isUnlocked('legendary', _stats(level: 74)), isFalse);
      expect(service.isUnlocked('legendary', _stats(level: 75)), isTrue);
    });

    test('streak achievements use their real thresholds', () {
      expect(service.isUnlocked('streak_3', _stats(streakDays: 2)), isFalse);
      expect(service.isUnlocked('streak_3', _stats(streakDays: 3)), isTrue);
      expect(service.isUnlocked('streak_7', _stats(streakDays: 6)), isFalse);
      expect(service.isUnlocked('streak_7', _stats(streakDays: 7)), isTrue);
      expect(service.isUnlocked('streak_30', _stats(streakDays: 29)), isFalse);
      expect(service.isUnlocked('streak_30', _stats(streakDays: 30)), isTrue);
    });

    test('battle_judge requires judging 10 battles', () {
      expect(service.isUnlocked('battle_judge', _stats(battlesVoted: 9)), isFalse);
      expect(service.isUnlocked('battle_judge', _stats(battlesVoted: 10)), isTrue);
    });

    test('unknown achievement ids are never unlocked', () {
      expect(service.isUnlocked('does_not_exist', _stats(hasProfile: true, level: 999)), isFalse);
    });

    test('evaluate returns only newly-met, not-already-unlocked achievements', () {
      final stats = _stats(hasProfile: true, ratingsGiven: 10, photoCount: 8);
      final newlyUnlocked = service.evaluate(stats, {'first_steps'});
      final ids = newlyUnlocked.map((a) => a.id).toSet();

      expect(ids, contains('rating_enthusiast'));
      expect(ids, contains('photogenic_life'));
      expect(ids, isNot(contains('first_steps'))); // already unlocked, excluded
      expect(ids, isNot(contains('rating_machine'))); // condition not met
    });

    test('evaluate returns nothing once everything is already unlocked', () {
      final stats = _stats(
        hasProfile: true,
        ratingsGiven: 100,
        photoCount: 8,
        scoreImprovement: 50,
        level: 100,
        hasSharedProfile: true,
        streakDays: 30,
        battlesVoted: 10,
      );
      final allIds = AchievementService.catalog.map((a) => a.id).toSet();
      expect(service.evaluate(stats, allIds), isEmpty);
    });
  });
}
