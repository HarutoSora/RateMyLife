/// Real percentile computation against an actual comparison pool — no
/// fabricated formula. This project's honesty stance (see
/// `docs/FEATURE_STATUS.md`) means a percentile must be computed from
/// real, currently-known profiles (the local device's loaded
/// `profiles`, mock seed + real synced users), not invented.
class PercentileService {
  const PercentileService();

  /// The share of [others] strictly below [value], as a whole number.
  /// Clamped to 1-99 — a local sample can never honestly claim "no one"
  /// (0) or "everyone" (100) scored lower. Returns 50 (the only honest
  /// answer with nothing to compare against) when [others] is empty.
  int percentileOf(int value, Iterable<int> others) {
    final pool = others.toList();
    if (pool.isEmpty) return 50;
    final below = pool.where((other) => other < value).length;
    return ((below / pool.length) * 100).round().clamp(1, 99);
  }
}
