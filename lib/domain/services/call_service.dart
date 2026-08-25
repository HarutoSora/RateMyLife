class CallValidationException implements Exception {
  const CallValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Pure eligibility rules for starting an audio call — no WebRTC, no
/// Firestore, so this is fully unit-testable. The actual signaling and
/// media session live in `CallRepository`, which calls this first.
class CallService {
  const CallService();

  /// Throws [CallValidationException] with a user-facing message if
  /// [callerId] should not be allowed to call [calleeId] right now.
  /// Deliberately stricter than messaging: a call additionally requires
  /// an existing conversation between the two — cold-calling a stranger
  /// with live audio is a materially bigger imposition than a first DM.
  void assertCanCall({
    required String callerId,
    required String calleeId,
    required bool calleeAllowsCalls,
    required bool calleeProfileIsPrivate,
    required bool isBlockedEitherWay,
    required bool hasExistingConversation,
  }) {
    if (callerId == calleeId) {
      throw const CallValidationException('You cannot call yourself.');
    }
    if (isBlockedEitherWay) {
      throw const CallValidationException('You cannot call this person.');
    }
    if (calleeProfileIsPrivate || !calleeAllowsCalls) {
      throw const CallValidationException('This person has calls turned off.');
    }
    if (!hasExistingConversation) {
      throw const CallValidationException('Message this person before calling them.');
    }
  }
}
