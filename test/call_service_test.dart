import 'package:flutter_test/flutter_test.dart';
import 'package:rate_my_life/domain/services/call_service.dart';

void main() {
  group('CallService.assertCanCall', () {
    const service = CallService();

    void assertOk({
      String callerId = 'a',
      String calleeId = 'b',
      bool calleeAllowsCalls = true,
      bool calleeProfileIsPrivate = false,
      bool isBlockedEitherWay = false,
      bool hasExistingConversation = true,
    }) {
      service.assertCanCall(
        callerId: callerId,
        calleeId: calleeId,
        calleeAllowsCalls: calleeAllowsCalls,
        calleeProfileIsPrivate: calleeProfileIsPrivate,
        isBlockedEitherWay: isBlockedEitherWay,
        hasExistingConversation: hasExistingConversation,
      );
    }

    test('allows a normal call', () {
      expect(() => assertOk(), returnsNormally);
    });

    test('refuses calling yourself', () {
      expect(() => assertOk(callerId: 'a', calleeId: 'a'), throwsA(isA<CallValidationException>()));
    });

    test('refuses when blocked either way', () {
      expect(() => assertOk(isBlockedEitherWay: true), throwsA(isA<CallValidationException>()));
    });

    test('refuses when the callee disabled calls', () {
      expect(() => assertOk(calleeAllowsCalls: false), throwsA(isA<CallValidationException>()));
    });

    test('refuses when the callee profile is private', () {
      expect(() => assertOk(calleeProfileIsPrivate: true), throwsA(isA<CallValidationException>()));
    });

    test('refuses without an existing conversation', () {
      expect(() => assertOk(hasExistingConversation: false), throwsA(isA<CallValidationException>()));
    });
  });
}
