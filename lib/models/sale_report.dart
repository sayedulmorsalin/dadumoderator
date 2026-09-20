import 'package:cloud_firestore/cloud_firestore.dart';

class SaleReport {
  final String? id;
  final DateTime date;
  final String moderatorId;
  final String moderatorName;
  final int parcel;
  final double sale;
  final double bkash;
  final double nagad;
  final double appCharge;
  final int returns;
  final DateTime createdAt;

  SaleReport({
    this.id,
    required this.date,
    required this.moderatorId,
    required this.moderatorName,
    required this.parcel,
    required this.sale,
    required this.bkash,
    required this.nagad,
    required this.appCharge,
    required this.returns,
    required this.createdAt,
  });

  double get totalDeliveryCharge => bkash + nagad + appCharge;

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'parcel': parcel,
      'sale': sale,
      'bkash': bkash,
      'nagad': nagad,
      'appCharge': appCharge,
      'returns': returns,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SaleReport.fromMap(Map<String, dynamic> map, String docId) {
    return SaleReport(
      id: docId,
      date: (map['date'] as Timestamp).toDate(),
      moderatorId: map['moderatorId'] ?? '',
      moderatorName: map['moderatorName'] ?? '',
      parcel: (map['parcel'] ?? 0).toInt(),
      sale: (map['sale'] ?? 0).toDouble(),
      bkash: (map['bkash'] ?? 0).toDouble(),
      nagad: (map['nagad'] ?? 0).toDouble(),
      appCharge: (map['appCharge'] ?? 0).toDouble(),
      returns: (map['returns'] ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
