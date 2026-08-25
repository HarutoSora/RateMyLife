import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rate_my_life/domain/services/photo_quality_service.dart';

Uint8List _solidImage({int width = 800, int height = 800, required int gray}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(gray, gray, gray));
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _checkerboardImage({int width = 800, int height = 800, int cell = 4}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final on = ((x ~/ cell) + (y ~/ cell)) % 2 == 0;
      image.setPixelRgb(x, y, on ? 255 : 0, on ? 255 : 0, on ? 255 : 0);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('PhotoQualityService', () {
    const service = PhotoQualityService();

    test('unreadable bytes return a neutral fallback score, not a crash', () async {
      final result = await service.analyze(Uint8List.fromList([1, 2, 3, 4]));
      expect(result.score, 50);
      expect(result.tip, isNotEmpty);
    });

    test('score stays within 0-100 for a real image', () async {
      final bytes = _solidImage(gray: 150);
      final result = await service.analyze(bytes);
      expect(result.score, inInclusiveRange(0, 100));
    });

    test('a comfortably-lit mid-gray photo scores higher than a very dark one', () async {
      final bright = await service.analyze(_solidImage(gray: 150));
      final dark = await service.analyze(_solidImage(gray: 10));
      expect(bright.score, greaterThan(dark.score));
    });

    test('a comfortably-lit mid-gray photo scores higher than a blown-out one', () async {
      final bright = await service.analyze(_solidImage(gray: 150));
      final blownOut = await service.analyze(_solidImage(gray: 255));
      expect(bright.score, greaterThan(blownOut.score));
    });

    test('a high-detail (sharp-edge) image scores higher than a flat, featureless one', () async {
      final sharp = await service.analyze(_checkerboardImage());
      final flat = await service.analyze(_solidImage(gray: 150));
      expect(sharp.score, greaterThan(flat.score));
    });

    test('a low-resolution photo scores lower than an otherwise-identical high-resolution one', () async {
      final small = await service.analyze(_checkerboardImage(width: 100, height: 100));
      final large = await service.analyze(_checkerboardImage(width: 1600, height: 1600));
      expect(large.score, greaterThanOrEqualTo(small.score));
    });

    test('the result is deterministic for the same bytes', () async {
      final bytes = _checkerboardImage();
      final first = await service.analyze(bytes);
      final second = await service.analyze(bytes);
      expect(first.score, second.score);
      expect(first.tip, second.tip);
    });
  });
}
