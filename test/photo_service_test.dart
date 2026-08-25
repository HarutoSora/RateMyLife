import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/domain/services/photo_service.dart';

void main() {
  group('PhotoService', () {
    final service = PhotoService();

    test('adds first photo as profile photo', () {
      final photos = service.addPhoto(const [], _photo('1', 0));
      expect(photos.single.isProfilePhoto, isTrue);
    });

    test('deletes and normalizes order', () {
      final photos = [
        _photo('1', 0, isProfile: true),
        _photo('2', 1),
        _photo('3', 2),
      ];
      final next = service.deletePhoto(photos, '2');
      expect(next.map((p) => p.order), [0, 1]);
    });

    test('sets profile photo', () {
      final photos = service.setProfilePhoto([
        _photo('1', 0, isProfile: true),
        _photo('2', 1),
      ], '2');
      expect(photos.first.isProfilePhoto, isFalse);
      expect(photos.last.isProfilePhoto, isTrue);
    });

    test('reorders photos', () {
      final photos = service.reorder([
        _photo('1', 0),
        _photo('2', 1),
        _photo('3', 2),
      ], 0, 3);
      expect(photos.map((p) => p.id), ['2', '3', '1']);
      expect(photos.map((p) => p.order), [0, 1, 2]);
    });

    test('sets a photo\'s category without touching the others', () {
      final photos = service.setCategory([
        _photo('1', 0, isProfile: true),
        _photo('2', 1),
      ], '2', 'Car');
      expect(photos.first.category, 'Lifestyle');
      expect(photos.last.category, 'Car');
    });

    test('every offered category is a real, distinct option', () {
      expect(PhotoService.categories.toSet(), hasLength(PhotoService.categories.length));
      expect(PhotoService.categories, contains('Car'));
      expect(PhotoService.categories, contains('Home'));
      expect(PhotoService.categories, contains('Travel'));
    });
  });
}

ProfilePhoto _photo(String id, int order, {bool isProfile = false}) {
  return ProfilePhoto(
    id: id,
    ownerId: 'user',
    path: 'mock://Photo',
    isProfilePhoto: isProfile,
    order: order,
    createdAt: DateTime(2026),
  );
}
