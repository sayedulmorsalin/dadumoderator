import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet.dart';
import '../models/payout_request.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _walletsCol = 'wallets';
  final String _payoutsCol = 'payout_requests';

  // ─── Wallet ────────────────────────────────────────────────────────────────

  Stream<Wallet?> getWallet(String moderatorId) {
    return _db.collection(_walletsCol).doc(moderatorId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Wallet.fromMap(snap.data()!);
    });
  }

  Stream<List<Wallet>> getAllWallets() {
    return _db
        .collection(_walletsCol)
        .orderBy('moderatorName')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Wallet.fromMap(d.data())).toList());
  }

  /// Recalculate and sync wallet balance from Firestore reports.
  /// Called after any report add/update to keep wallet in sync.
  Future<void> syncWalletFromReports(
      String moderatorId, String moderatorName) async {
    final snap = await _db
        .collection('reports')
        .where('moderatorId', isEqualTo: moderatorId)
        .get();

    double totalEarned = 0;
    for (final doc in snap.docs) {
      final commission = (doc.data()['commission'] ?? 0).toDouble();
      final extra = (doc.data()['extra'] ?? 0).toDouble();
      totalEarned += commission + extra;
    }

    // Get total withdrawn (approved payouts)
    final payoutSnap = await _db
        .collection(_payoutsCol)
        .where('moderatorId', isEqualTo: moderatorId)
        .where('status', isEqualTo: 'approved')
        .get();

    double totalWithdrawn = 0;
    for (final doc in payoutSnap.docs) {
      totalWithdrawn += (doc.data()['amount'] ?? 0).toDouble();
    }

    final balance = totalEarned - totalWithdrawn;

    await _db.collection(_walletsCol).doc(moderatorId).set({
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'balance': balance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  // ─── Payout Requests ───────────────────────────────────────────────────────

  Future<void> requestPayout(PayoutRequest req) async {
    await _db.collection(_payoutsCol).add(req.toMap());
  }

  Stream<List<PayoutRequest>> getPayoutRequests(String moderatorId) {
    return _db
        .collection(_payoutsCol)
        .where('moderatorId', isEqualTo: moderatorId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PayoutRequest.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<PayoutRequest>> getAllPayoutRequests() {
    return _db
        .collection(_payoutsCol)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PayoutRequest.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> resolvePayoutRequest(
      PayoutRequest req, bool approved, String adminNote) async {
    if (req.id == null) return;

    final newStatus = approved ? 'approved' : 'rejected';

    await _db.collection(_payoutsCol).doc(req.id).update({
      'status': newStatus,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'note': adminNote,
    });

    // If approved, sync wallet to update balance (totalWithdrawn increases)
    if (approved) {
      await syncWalletFromReports(req.moderatorId, req.moderatorName);
    }
  }
}
