import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Result of an automated photo QUALITY check — resolution, sharpness, and
/// lighting. This intentionally does not, and never should, evaluate the
/// person in the photo (attractiveness, body, face). Rating people's looks
/// algorithmically is a well-documented source of bias and real harm, and
/// it would contradict this app's own rule that scores never measure a
/// person's worth. This only judges the image as a photograph.
class PhotoQualityResult {
  const PhotoQualityResult({
    required this.score,
    required this.tip,
  });

  /// Overall photo quality, 0-100.
  final int score;

  /// One short, constructive suggestion (or a compliment if it's already
  /// a strong photo).
  final String tip;
}

class PhotoQualityService {
  const PhotoQualityService();

  /// Runs on a background isolate via [compute] — decoding and scanning a
  /// full-size photo is too expensive for the UI thread. Must stay pure
  /// Dart (no `dart:ui`/platform channels), which is why this uses the
  /// `image` package rather than `dart:ui`'s Codec.
  Future<PhotoQualityResult> analyze(Uint8List bytes) {
    return compute(_analyzeSync, bytes);
  }
}

PhotoQualityResult _analyzeSync(Uint8List bytes) {
  // `decodeImage` can throw, not just return null, on malformed/truncated
  // bytes (its format-sniffing reads a fixed header size before checking
  // there's enough data) — both cases mean the same thing here: this
  // isn't a readable photo, so fall back rather than crash.
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    return const PhotoQualityResult(score: 50, tip: 'Could not read this image.');
  }

  final resolutionScore = _resolutionScore(decoded.width, decoded.height);

  // Downscale before the pixel scan — sharpness/brightness don't need full
  // resolution, and this keeps the scan fast even for large photos.
  final sample = img.copyResize(decoded, width: 220, maintainAspect: true);
  final gray = img.grayscale(sample);

  final brightness = _averageBrightness(gray);
  final brightnessScore = _brightnessScore(brightness);
  final sharpnessScore = _sharpnessScore(gray);

  final overall = (resolutionScore * 0.25 + brightnessScore * 0.35 + sharpnessScore * 0.40).round().clamp(0, 100);

  return PhotoQualityResult(score: overall, tip: _tipFor(overall, brightnessScore, sharpnessScore, resolutionScore));
}

double _resolutionScore(int width, int height) {
  final megapixels = (width * height) / 1000000;
  // 1.5MP+ (e.g. 1500x1000) is already plenty for a profile photo.
  return (megapixels / 1.5).clamp(0, 1) * 100;
}

double _averageBrightness(img.Image gray) {
  var total = 0;
  for (final pixel in gray) {
    total += pixel.r.toInt();
  }
  return total / (gray.width * gray.height);
}

double _brightnessScore(double brightness) {
  // 0-255 scale; penalize photos that are too dark or blown out, reward
  // a comfortable mid-to-bright range.
  const ideal = 150.0;
  final distance = (brightness - ideal).abs();
  return (1 - (distance / ideal).clamp(0, 1)) * 100;
}

double _sharpnessScore(img.Image gray) {
  // Edge-energy proxy for blur: average absolute gradient between
  // neighboring pixels. Sharp/detailed photos have larger local
  // differences than soft/blurry ones.
  var energy = 0;
  var samples = 0;
  for (var y = 0; y < gray.height - 1; y++) {
    for (var x = 0; x < gray.width - 1; x++) {
      final center = gray.getPixel(x, y).r.toInt();
      final right = gray.getPixel(x + 1, y).r.toInt();
      final down = gray.getPixel(x, y + 1).r.toInt();
      energy += (center - right).abs() + (center - down).abs();
      samples++;
    }
  }
  final averageEnergy = samples == 0 ? 0 : energy / samples;
  // Empirically, in-focus photos average well above ~8-10 per neighbor
  // pair at this sample size; soft/blurry ones fall well below that.
  return (averageEnergy / 14).clamp(0, 1) * 100;
}

String _tipFor(int overall, double brightness, double sharpness, double resolution) {
  if (overall >= 80) return 'Great shot — clear, well-lit, and sharp.';
  if (sharpness < 45) return 'This looks a little blurry — try holding steady or using more light.';
  if (brightness < 45) return 'This photo looks dark — try better lighting.';
  if (resolution < 45) return 'This photo is low resolution — try a higher-quality original.';
  return 'Decent photo — a brighter, steadier shot could score higher.';
}
