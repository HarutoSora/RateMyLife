import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/streak_service.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

void main() {
  group('StreakService', () {
    const service = StreakService();

    test('no activity at all is a zero streak', () {
      expect(service.currentStreak({}, _d(2026, 6, 10)), 0);
    });

    test('active today only is a 1-day streak', () {
      final activeDays = {_d(2026, 6, 10)};
      expect(service.currentStreak(activeDays, _d(2026, 6, 10)), 1);
    });

    test('consecutive days ending today count fully', () {
      final activeDays = {_d(2026, 6, 8), _d(2026, 6, 9), _d(2026, 6, 10)};
      expect(service.currentStreak(activeDays, _d(2026, 6, 10)), 3);
    });

    test('a gap breaks the streak', () {
      final activeDays = {_d(2026, 6, 5), _d(2026, 6, 9), _d(2026, 6, 10)};
      expect(service.currentStreak(activeDays, _d(2026, 6, 10)), 2);
    });

    test('no activity yet today still counts yesterday\'s streak, not zero', () {
      final activeDays = {_d(2026, 6, 8), _d(2026, 6, 9)};
      expect(service.currentStreak(activeDays, _d(2026, 6, 10)), 2);
    });

    test('a streak broken more than a day ago from today (with no activity today) is zero', () {
      final activeDays = {_d(2026, 6, 5)};
      expect(service.currentStreak(activeDays, _d(2026, 6, 10)), 0);
    });

    test('lastSevenDays returns 7 entries, oldest first, ending today', () {
      final activeDays = {_d(2026, 6, 10), _d(2026, 6, 8)};
      final week = service.lastSevenDays(activeDays, _d(2026, 6, 10));

      expect(week, hasLength(7));
      expect(week.first.key, _d(2026, 6, 4));
      expect(week.last.key, _d(2026, 6, 10));
      expect(week.last.value, isTrue);
      expect(week[week.length - 3].value, isTrue); // June 8
      expect(week[week.length - 2].value, isFalse); // June 9
    });
  });
}
