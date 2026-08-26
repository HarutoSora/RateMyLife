import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/nuke_service.dart';

void main() {
  group('NukeService', () {
    const service = NukeService();

    test('randomAttribute always returns one of the 7 known Life Score categories', () {
      final random = Random(1);
      for (var i = 0; i < 50; i++) {
        expect(NukeService.attributes, contains(service.randomAttribute(random)));
      }
    });

    group('assertCanNuke', () {
      test('allows a well-formed attack', () {
        expect(
          () => service.assertCanNuke(
            attackerId: 'me',
            targetId: 'them',
            isBlockedEitherWay: false,
            balance: NukeService.attackCost,
          ),
          returnsNormally,
        );
      });

      test('rejects nuking yourself', () {
        expect(
          () => service.assertCanNuke(
            attackerId: 'me',
            targetId: 'me',
            isBlockedEitherWay: false,
            balance: NukeService.attackCost,
          ),
          throwsA(isA<NukeValidationException>()),
        );
      });

      test('rejects nuking a blocked profile', () {
        expect(
          () => service.assertCanNuke(
            attackerId: 'me',
            targetId: 'them',
            isBlockedEitherWay: true,
            balance: NukeService.attackCost,
          ),
          throwsA(isA<NukeValidationException>()),
        );
      });

      test('rejects an attack without enough coins', () {
        expect(
          () => service.assertCanNuke(
            attackerId: 'me',
            targetId: 'them',
            isBlockedEitherWay: false,
            balance: NukeService.attackCost - 1,
          ),
          throwsA(isA<NukeValidationException>()),
        );
      });
    });

    group('assertCanCure', () {
      test('allows a cure with enough coins', () {
        expect(() => service.assertCanCure(balance: NukeService.curePotionCost), returnsNormally);
      });

      test('rejects a cure without enough coins', () {
        expect(
          () => service.assertCanCure(balance: NukeService.curePotionCost - 1),
          throwsA(isA<NukeValidationException>()),
        );
      });
    });

    group('mergeDamage', () {
      test('accumulates repeated damage to the same attribute', () {
        var damage = const <String, int>{};
        damage = service.mergeDamage(damage, 'career', -5);
        damage = service.mergeDamage(damage, 'career', -5);
        expect(damage['career'], -10);
      });

      test('a cure heals damage but never pushes it above 0', () {
        var damage = service.mergeDamage(const {}, 'career', -5);
        damage = service.mergeDamage(damage, 'career', NukeService.healPerPotion);
        expect(damage['career'], -2);
        damage = service.mergeDamage(damage, 'career', NukeService.healPerPotion);
        expect(damage['career'], 0);
      });

      test('does not mutate the input map', () {
        final original = <String, int>{'career': -5};
        service.mergeDamage(original, 'career', -5);
        expect(original['career'], -5);
      });
    });

    group('mostDamagedAttribute', () {
      test('returns the attribute with the largest negative value', () {
        final worst = service.mostDamagedAttribute({'career': -3, 'social': -10, 'financial': -1});
        expect(worst, 'social');
      });

      test('returns null when nothing is damaged', () {
        expect(service.mostDamagedAttribute(const {}), isNull);
        expect(service.mostDamagedAttribute(const {'career': 0}), isNull);
      });
    });
  });
}
