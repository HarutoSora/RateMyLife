import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

class ModerationService {
  ModerationService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Report createReport({
    required String reporterId,
    required String targetUserId,
    String? targetPhotoId,
    String? targetCommentId,
    String? targetMessageId,
    required ReportReason reason,
  }) {
    return Report(
      id: _uuid.v4(),
      reporterId: reporterId,
      targetUserId: targetUserId,
      targetPhotoId: targetPhotoId,
      targetCommentId: targetCommentId,
      targetMessageId: targetMessageId,
      reason: reason,
      createdAt: DateTime.now(),
    );
  }

  BlockedUser block({
    required String blockerId,
    required String blockedUserId,
  }) {
    return BlockedUser(
      blockerId: blockerId,
      blockedUserId: blockedUserId,
      createdAt: DateTime.now(),
    );
  }
}
