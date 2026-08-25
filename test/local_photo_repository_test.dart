import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

ProfilePhoto _photo(String path) => ProfilePhoto(
      id: 'p1',
      ownerId: 'me',
      path: path,
      order: 0,
      createdAt: DateTime(2026),
    );

void main() {
  group('LocalPhotoRepository.readPhotoBytes', () {
    final repo = LocalPhotoRepository();

    test('reads back the real bytes of a local file', () async {
      final dir = await Directory.systemTemp.createTemp('photo_quality_test');
      final file = File('${dir.path}/photo.bin');
      await file.writeAsBytes([1, 2, 3, 4, 5]);
      addTearDown(() => dir.delete(recursive: true));

      final bytes = await repo.readPhotoBytes(_photo(file.path));

      expect(bytes, [1, 2, 3, 4, 5]);
    });

    test('returns null for a missing local file', () async {
      final bytes = await repo.readPhotoBytes(_photo('/no/such/file.jpg'));
      expect(bytes, isNull);
    });

    test('returns null for a mock demo photo', () async {
      final bytes = await repo.readPhotoBytes(_photo('mock://Travel'));
      expect(bytes, isNull);
    });

    test('returns null for a bundled asset photo', () async {
      final bytes = await repo.readPhotoBytes(_photo('assets/mock/people/1.jpg'));
      expect(bytes, isNull);
    });
  });
}
