import 'package:cloud_firestore/cloud_firestore.dart';

class ModeratorOfMonth {
  final String id; // format: 'YYYY_MM', e.g. '2026_08'
  final int year;
  final int month;
  final String moderatorId;
  final String moderatorName;
  final String moderatorEmail;
  final double totalSale;
  final int deliveryCount;
  final int returnCount;
  final double deliveryRate;
  final DateTime crownedAt;
  final String note;

  ModeratorOfMonth({
    required this.id,
    required this.year,
    required this.month,
    required this.moderatorId,
    required this.moderatorName,
    required this.moderatorEmail,
    required this.totalSale,
    required this.deliveryCount,
    required this.returnCount,
    required this.deliveryRate,
    required this.crownedAt,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'moderatorEmail': moderatorEmail,
      'totalSale': totalSale,
      'deliveryCount': deliveryCount,
      'returnCount': returnCount,
      'deliveryRate': deliveryRate,
      'crownedAt': Timestamp.fromDate(crownedAt),
      'note': note,
    };
  }

  factory ModeratorOfMonth.fromMap(Map<String, dynamic> map, String docId) {
    return ModeratorOfMonth(
      id: docId,
      year: (map['year'] ?? 0).toInt(),
      month: (map['month'] ?? 0).toInt(),
      moderatorId: map['moderatorId'] ?? '',
      moderatorName: map['moderatorName'] ?? '',
      moderatorEmail: map['moderatorEmail'] ?? '',
      totalSale: (map['totalSale'] ?? 0).toDouble(),
      deliveryCount: (map['deliveryCount'] ?? 0).toInt(),
      returnCount: (map['returnCount'] ?? 0).toInt(),
      deliveryRate: (map['deliveryRate'] ?? 0).toDouble(),
      crownedAt: map['crownedAt'] is Timestamp
          ? (map['crownedAt'] as Timestamp).toDate()
          : DateTime.now(),
      note: map['note'] ?? '',
    );
  }
}
