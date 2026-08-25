import '../../data/models/models.dart';

class PhotoService {
  /// The categories a user can tag a photo with. Matches the set
  /// `PhotoGrid`'s own empty-state copy already promised ("Add travel,
  /// home, hobbies, food, fitness, or achievements") plus Car, so the
  /// picker finally delivers what the UI was already describing.
  static const categories = ['Lifestyle', 'Travel', 'Home', 'Car', 'Food', 'Fitness', 'Hobby', 'Achievement'];

  List<ProfilePhoto> addPhoto(List<ProfilePhoto> photos, ProfilePhoto photo) {
    final normalized = photo.copyWith(
      order: photos.length,
      isProfilePhoto: photos.isEmpty ? true : photo.isProfilePhoto,
    );
    if (normalized.isProfilePhoto) {
      return [
        ...photos.map((item) => item.copyWith(isProfilePhoto: false)),
        normalized,
      ];
    }
    return [...photos, normalized];
  }

  List<ProfilePhoto> deletePhoto(List<ProfilePhoto> photos, String photoId) {
    final remaining = photos.where((photo) => photo.id != photoId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(
          order: i,
          isProfilePhoto: i == 0
              ? true
              : remaining[i].isProfilePhoto &&
                  remaining.any((photo) => photo.isProfilePhoto),
        ),
    ];
  }

  List<ProfilePhoto> setProfilePhoto(List<ProfilePhoto> photos, String id) {
    return [
      for (final photo in photos)
        photo.copyWith(isProfilePhoto: photo.id == id),
    ];
  }

  List<ProfilePhoto> setCategory(List<ProfilePhoto> photos, String id, String category) {
    return [
      for (final photo in photos)
        if (photo.id == id) photo.copyWith(category: category) else photo,
    ];
  }

  List<ProfilePhoto> reorder(
    List<ProfilePhoto> photos,
    int oldIndex,
    int newIndex,
  ) {
    final sorted = [...photos]..sort((a, b) => a.order.compareTo(b.order));
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);
    return [
      for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(order: i),
    ];
  }
}
