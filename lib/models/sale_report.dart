import 'package:cloud_firestore/cloud_firestore.dart';

class SaleReport {
  final String? id;
  final DateTime date;
  final String moderatorId;
  final String moderatorName;
  final int parcel;
  final double sale;
  final int totalParcel; // Delivered total parcel
  final double totalSale; // Delivered total sale
  final double bkash;
  final double nagad;
  final double appCharge;
  final int returns;
  final double commission; // editable by both admin and moderator
  final double extra; // admin-only: positive = bonus, negative = fine
  final String extraType; // 'bonus', 'fine', or 'none'
  final String extraNote; // admin note for bonus/fine
  final DateTime createdAt;

  // Report approval status: 'pending', 'approved', 'rejected'
  final String status;
  final String adminNote; // admin note for rejection
  final int editCount; // tracks how many times edit was requested (max 1)

  // Delivery charge proof image URLs (Firebase Storage)
  final String? bkashImageUrl;
  final String? nagadImageUrl;
  final String? rocketImageUrl;

  SaleReport({
    this.id,
    required this.date,
    required this.moderatorId,
    required this.moderatorName,
    required this.parcel,
    required this.sale,
    this.totalParcel = 0,
    this.totalSale = 0,
    required this.bkash,
    required this.nagad,
    required this.appCharge,
    required this.returns,
    this.commission = 0,
    this.extra = 0,
    this.extraType = 'none',
    this.extraNote = '',
    required this.createdAt,
    this.status = 'pending',
    this.adminNote = '',
    this.editCount = 0,
    this.bkashImageUrl,
    this.nagadImageUrl,
    this.rocketImageUrl,
  });

  double get totalDeliveryCharge => bkash + nagad + appCharge;

  /// Net amount added to wallet for this report
  double get walletContribution => commission + extra;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// Whether user can request an edit (only 1 time allowed per report)
  bool get canRequestEdit => editCount < 1;

  /// Whether an edit request is currently pending admin approval
  bool get isEditRequested => editCount > 0 && isPending;

  /// Whether delivered data has been submitted and is pending admin approval
  bool get isDeliveredPending => (totalParcel > 0 || totalSale > 0) && isPending;

  /// Effective delivered parcel count (uses totalParcel, or falls back to parcel for legacy approved reports)
  int get deliveredCount {
    if (totalParcel > 0) return totalParcel;
    if (totalSale > 0) return 0;
    if (commission > 0 || returns > 0) return parcel;
    return 0;
  }

  /// Effective delivered sale amount (uses totalSale, or falls back to sale for legacy approved reports)
  double get deliveredSaleAmount {
    if (totalSale > 0) return totalSale;
    if (totalParcel > 0) return 0.0;
    if (commission > 0 || returns > 0) return sale;
    return 0.0;
  }

  /// Whether delivered data has been submitted for this report
  bool get hasDeliveredData =>
      totalParcel > 0 || totalSale > 0 || returns > 0 || commission > 0;

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'parcel': parcel,
      'sale': sale,
      'totalParcel': totalParcel,
      'totalSale': totalSale,
      'bkash': bkash,
      'nagad': nagad,
      'appCharge': appCharge,
      'returns': returns,
      'commission': commission,
      'extra': extra,
      'extraType': extraType,
      'extraNote': extraNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'adminNote': adminNote,
      'editCount': editCount,
      'bkashImageUrl': bkashImageUrl,
      'nagadImageUrl': nagadImageUrl,
      'rocketImageUrl': rocketImageUrl,
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
      totalParcel: (map['totalParcel'] ?? 0).toInt(),
      totalSale: (map['totalSale'] ?? 0).toDouble(),
      bkash: (map['bkash'] ?? 0).toDouble(),
      nagad: (map['nagad'] ?? 0).toDouble(),
      appCharge: (map['appCharge'] ?? 0).toDouble(),
      returns: (map['returns'] ?? 0).toInt(),
      commission: (map['commission'] ?? 0).toDouble(),
      extra: (map['extra'] ?? 0).toDouble(),
      extraType: map['extraType'] ?? 'none',
      extraNote: map['extraNote'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'] ?? '',
      editCount: (map['editCount'] ?? 0).toInt(),
      bkashImageUrl: map['bkashImageUrl'] as String?,
      nagadImageUrl: map['nagadImageUrl'] as String?,
      rocketImageUrl: map['rocketImageUrl'] as String?,
    );
  }

  SaleReport copyWith({
    String? id,
    DateTime? date,
    String? moderatorId,
    String? moderatorName,
    int? parcel,
    double? sale,
    int? totalParcel,
    double? totalSale,
    double? bkash,
    double? nagad,
    double? appCharge,
    int? returns,
    double? commission,
    double? extra,
    String? extraType,
    String? extraNote,
    DateTime? createdAt,
    String? status,
    String? adminNote,
    int? editCount,
    String? bkashImageUrl,
    String? nagadImageUrl,
    String? rocketImageUrl,
  }) {
    return SaleReport(
      id: id ?? this.id,
      date: date ?? this.date,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorName: moderatorName ?? this.moderatorName,
      parcel: parcel ?? this.parcel,
      sale: sale ?? this.sale,
      totalParcel: totalParcel ?? this.totalParcel,
      totalSale: totalSale ?? this.totalSale,
      bkash: bkash ?? this.bkash,
      nagad: nagad ?? this.nagad,
      appCharge: appCharge ?? this.appCharge,
      returns: returns ?? this.returns,
      commission: commission ?? this.commission,
      extra: extra ?? this.extra,
      extraType: extraType ?? this.extraType,
      extraNote: extraNote ?? this.extraNote,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      editCount: editCount ?? this.editCount,
      bkashImageUrl: bkashImageUrl ?? this.bkashImageUrl,
      nagadImageUrl: nagadImageUrl ?? this.nagadImageUrl,
      rocketImageUrl: rocketImageUrl ?? this.rocketImageUrl,
    );
  }
}
