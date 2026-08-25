import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/percentile_service.dart';

void main() {
  group('PercentileService', () {
    const service = PercentileService();

    test('returns 50 with an empty comparison pool', () {
      expect(service.percentileOf(80, const []), 50);
    });

    test('computes the real share of others scoring lower', () {
      // 3 of 4 others (30, 40, 50) are below 60 -> 75%.
      expect(service.percentileOf(60, [30, 40, 50, 90]), 75);
    });

    test('never claims 0 or 100 even at the extremes', () {
      expect(service.percentileOf(100, [10, 20, 30]), lessThanOrEqualTo(99));
      expect(service.percentileOf(0, [10, 20, 30]), greaterThanOrEqualTo(1));
    });

    test('a middling score against a spread pool lands near 50', () {
      final pct = service.percentileOf(50, [10, 20, 30, 40, 60, 70, 80, 90]);
      expect(pct, closeTo(50, 15));
    });
  });
}
