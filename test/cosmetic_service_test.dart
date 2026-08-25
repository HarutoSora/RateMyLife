import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/cosmetic_service.dart';

void main() {
  group('CosmeticService', () {
    const service = CosmeticService();

    test('catalog ids are unique', () {
      final ids = CosmeticService.catalog.map((f) => f.id).toSet();
      expect(ids, hasLength(CosmeticService.catalog.length));
    });

    test('"none" is always free', () {
      final none = service.frameById('none');
      expect(none, isNotNull);
      expect(none!.cost, 0);
    });

    test('frameById returns null for an unknown id', () {
      expect(service.frameById('does_not_exist'), isNull);
    });

    test('"none" is always owned, even with an empty owned set', () {
      expect(service.isOwned('none', {}), isTrue);
    });

    test('a real frame is owned only if its id is in the owned set', () {
      expect(service.isOwned('gold', {}), isFalse);
      expect(service.isOwned('gold', {'gold'}), isTrue);
    });

    test('canAfford compares balance against the frame cost', () {
      final gold = service.frameById('gold')!;
      expect(service.canAfford(gold, gold.cost - 1), isFalse);
      expect(service.canAfford(gold, gold.cost), isTrue);
      expect(service.canAfford(gold, gold.cost + 1), isTrue);
    });
  });
}
