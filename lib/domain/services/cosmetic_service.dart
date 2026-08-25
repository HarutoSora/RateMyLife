import '../../data/models/models.dart';

/// Purchasable profile-photo frames. `'none'` is always free and
/// always "owned" — it's the default, not a real purchase.
class CosmeticService {
  const CosmeticService();

  static const List<CosmeticFrame> catalog = [
    CosmeticFrame(id: 'none', name: 'No Frame', gradientKey: 'none', cost: 0),
    CosmeticFrame(id: 'gold', name: 'Gold Frame', gradientKey: 'gold', cost: 150),
    CosmeticFrame(id: 'purple', name: 'Purple Frame', gradientKey: 'purple', cost: 150),
    CosmeticFrame(id: 'pink', name: 'Pink Frame', gradientKey: 'pink', cost: 150),
    CosmeticFrame(id: 'blue', name: 'Blue Frame', gradientKey: 'blue', cost: 150),
  ];

  CosmeticFrame? frameById(String id) {
    for (final frame in catalog) {
      if (frame.id == id) return frame;
    }
    return null;
  }

  bool isOwned(String frameId, Set<String> ownedIds) => frameId == 'none' || ownedIds.contains(frameId);

  bool canAfford(CosmeticFrame frame, int balance) => balance >= frame.cost;
}
