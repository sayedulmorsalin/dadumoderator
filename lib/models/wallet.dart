import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String moderatorId;
  final String moderatorName;
  final double balance;
  final double totalEarned;
  final double totalWithdrawn;
  final DateTime lastUpdated;

  Wallet({
    required this.moderatorId,
    required this.moderatorName,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'balance': balance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      moderatorId: map['moderatorId'] ?? '',
      moderatorName: map['moderatorName'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      totalEarned: (map['totalEarned'] ?? 0).toDouble(),
      totalWithdrawn: (map['totalWithdrawn'] ?? 0).toDouble(),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Wallet copyWith({
    String? moderatorId,
    String? moderatorName,
    double? balance,
    double? totalEarned,
    double? totalWithdrawn,
    DateTime? lastUpdated,
  }) {
    return Wallet(
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorName: moderatorName ?? this.moderatorName,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
