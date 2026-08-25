import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/data/models/models.dart';
import 'package:rate_my_life/data/repositories/repositories.dart';

CosmeticPurchase _purchase(String id, {String profileId = 'me', String cosmeticId = 'gold'}) => CosmeticPurchase(
      id: id,
      profileId: profileId,
      cosmeticId: cosmeticId,
      purchasedAt: DateTime(2026, 1, 1),
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'me'), signedIn: true);
  });

  group('RemoteCosmeticRepository', () {
    test('saves and round-trips purchases', () async {
      final repo = RemoteCosmeticRepository(firestore: firestore, auth: auth);
      await repo.loadPurchases();
      await repo.savePurchases([_purchase('p1')]);

      final loaded = await repo.loadPurchases();
      expect(loaded.single.cosmeticId, 'gold');
    });

    test('does not rewrite an already-known purchase', () async {
      final repo = RemoteCosmeticRepository(firestore: firestore, auth: auth);
      await repo.loadPurchases();
      await repo.savePurchases([_purchase('p1')]);
      await repo.savePurchases([_purchase('p1'), _purchase('p2', cosmeticId: 'purple')]);

      expect(await firestore.collection('cosmeticPurchases').get().then((s) => s.docs), hasLength(2));
    });

    test('only loads this device\'s own purchases', () async {
      final otherAuth = MockFirebaseAuth(mockUser: MockUser(uid: 'other'), signedIn: true);
      final otherRepo = RemoteCosmeticRepository(firestore: firestore, auth: otherAuth);
      await otherRepo.loadPurchases();
      await otherRepo.savePurchases([_purchase('theirs', profileId: 'other')]);

      final repo = RemoteCosmeticRepository(firestore: firestore, auth: auth);
      await repo.loadPurchases();
      await repo.savePurchases([_purchase('mine')]);

      final mine = await repo.loadPurchases();
      expect(mine.map((p) => p.id), ['mine']);
    });
  });
}
