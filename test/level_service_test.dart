import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/level_service.dart';

void main() {
  group('LevelService', () {
    const service = LevelService();

    test('starts at level 1, Beginner, with 0 XP', () {
      final info = service.levelFor(0);
      expect(info.level, 1);
      expect(info.rank, 'Beginner');
      expect(info.xpIntoLevel, 0);
      expect(info.progress, 0);
    });

    test('XP just below the next level threshold stays on the current level', () {
      final floor = service.xpFloorForLevel(2);
      final info = service.levelFor(floor - 1);
      expect(info.level, 1);
    });

    test('XP exactly at a level floor advances to that level', () {
      final floor = service.xpFloorForLevel(5);
      final info = service.levelFor(floor);
      expect(info.level, 5);
      expect(info.xpIntoLevel, 0);
    });

    test('rank titles match the named breakpoints', () {
      expect(service.rankFor(1), 'Beginner');
      expect(service.rankFor(9), 'Beginner');
      expect(service.rankFor(10), 'Rising');
      expect(service.rankFor(24), 'Rising');
      expect(service.rankFor(25), 'Established');
      expect(service.rankFor(49), 'Established');
      expect(service.rankFor(50), 'Elite');
      expect(service.rankFor(74), 'Elite');
      expect(service.rankFor(75), 'Legendary');
      expect(service.rankFor(99), 'Legendary');
      expect(service.rankFor(100), 'Mythic');
    });

    test('progress is 0-1 and reflects XP earned into the current level', () {
      final floor = service.xpFloorForLevel(10);
      final nextFloor = service.xpFloorForLevel(11);
      final halfway = floor + ((nextFloor - floor) / 2).round();
      final info = service.levelFor(halfway);
      expect(info.level, 10);
      expect(info.progress, closeTo(0.5, 0.05));
    });

    test('clamps at level 100 and reports max level with zero XP remaining', () {
      final farBeyond = service.xpFloorForLevel(100) + 1000000;
      final info = service.levelFor(farBeyond);
      expect(info.level, 100);
      expect(info.isMaxLevel, isTrue);
      expect(info.xpForNextLevel, 0);
      expect(info.xpRemaining, 0);
      expect(info.progress, 1.0);
    });

    test('negative XP is treated as zero', () {
      final info = service.levelFor(-500);
      expect(info.level, 1);
      expect(info.totalXp, 0);
    });

    test('level requirement grows monotonically', () {
      for (var level = 1; level < 100; level++) {
        final costNow = service.xpFloorForLevel(level + 1) - service.xpFloorForLevel(level);
        final costNext = service.xpFloorForLevel(level + 2) - service.xpFloorForLevel(level + 1);
        expect(costNext, greaterThanOrEqualTo(costNow));
      }
    });
  });
}
