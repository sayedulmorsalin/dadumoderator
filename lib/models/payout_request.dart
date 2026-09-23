import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutRequest {
  final String? id;
  final String moderatorId;
  final String moderatorName;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final DateTime? resolvedAt;
  final String note; // moderator's note or admin's reason

  PayoutRequest({
    this.id,
    required this.moderatorId,
    required this.moderatorName,
    required this.amount,
    this.status = 'pending',
    required this.requestedAt,
    this.resolvedAt,
    this.note = '',
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'amount': amount,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'note': note,
    };
  }

  factory PayoutRequest.fromMap(Map<String, dynamic> map, String docId) {
    return PayoutRequest(
      id: docId,
      moderatorId: map['moderatorId'] ?? '',
      moderatorName: map['moderatorName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      note: map['note'] ?? '',
    );
  }
}
