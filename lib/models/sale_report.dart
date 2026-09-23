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
  final double commission; // editable by both admin and moderator
  final double extra; // admin-only: positive = bonus, negative = fine
  final String extraType; // 'bonus', 'fine', or 'none'
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
    this.commission = 0,
    this.extra = 0,
    this.extraType = 'none',
    required this.createdAt,
  });

  double get totalDeliveryCharge => bkash + nagad + appCharge;

  /// Net amount added to wallet for this report
  double get walletContribution => commission + extra;

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
      'commission': commission,
      'extra': extra,
      'extraType': extraType,
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
      commission: (map['commission'] ?? 0).toDouble(),
      extra: (map['extra'] ?? 0).toDouble(),
      extraType: map['extraType'] ?? 'none',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  SaleReport copyWith({
    String? id,
    DateTime? date,
    String? moderatorId,
    String? moderatorName,
    int? parcel,
    double? sale,
    double? bkash,
    double? nagad,
    double? appCharge,
    int? returns,
    double? commission,
    double? extra,
    String? extraType,
    DateTime? createdAt,
  }) {
    return SaleReport(
      id: id ?? this.id,
      date: date ?? this.date,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorName: moderatorName ?? this.moderatorName,
      parcel: parcel ?? this.parcel,
      sale: sale ?? this.sale,
      bkash: bkash ?? this.bkash,
      nagad: nagad ?? this.nagad,
      appCharge: appCharge ?? this.appCharge,
      returns: returns ?? this.returns,
      commission: commission ?? this.commission,
      extra: extra ?? this.extra,
      extraType: extraType ?? this.extraType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
