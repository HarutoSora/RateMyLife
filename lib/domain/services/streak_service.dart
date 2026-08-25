/// Computes activity streaks from the set of days the local user earned
/// any XP on — no separate streak counter to keep in sync or that could
/// drift from what actually happened.
class StreakService {
  const StreakService();

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Current streak length in days, counting backward from [today].
  /// If today has no activity yet, the streak still counts from
  /// yesterday — a streak shouldn't read as broken just because the
  /// user hasn't done anything *yet* today. [activeDays] must already
  /// be date-only (midnight) values.
  int currentStreak(Set<DateTime> activeDays, DateTime today) {
    final day = dateOnly(today);
    var cursor = activeDays.contains(day) ? day : day.subtract(const Duration(days: 1));
    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The last 7 days, oldest first, paired with whether each had
  /// activity — for a Mon..Sun-style row.
  List<MapEntry<DateTime, bool>> lastSevenDays(Set<DateTime> activeDays, DateTime today) {
    final day = dateOnly(today);
    return [
      for (var i = 6; i >= 0; i--)
        MapEntry(day.subtract(Duration(days: i)), activeDays.contains(day.subtract(Duration(days: i)))),
    ];
  }
}
