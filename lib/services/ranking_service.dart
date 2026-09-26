import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/moderator_of_month.dart';

class RankingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'moderator_of_month';

  static String docIdFor(int year, int month) {
    return '${year}_${month.toString().padLeft(2, '0')}';
  }

  /// Real-time stream for the winner of a specific month
  Stream<ModeratorOfMonth?> getModeratorOfMonthStream(int year, int month) {
    final docId = docIdFor(year, month);
    return _db.collection(_collection).doc(docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ModeratorOfMonth.fromMap(snap.data()!, snap.id);
    });
  }

  /// Get single record Future
  Future<ModeratorOfMonth?> getModeratorOfMonth(int year, int month) async {
    final docId = docIdFor(year, month);
    final doc = await _db.collection(_collection).doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ModeratorOfMonth.fromMap(doc.data()!, doc.id);
  }

  /// Stream of all past winners for Hall of Fame
  Stream<List<ModeratorOfMonth>> getAllPastWinnersStream() {
    return _db
        .collection(_collection)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ModeratorOfMonth.fromMap(d.data(), d.id)).toList());
  }

  /// Save or update Moderator of the Month
  Future<void> saveModeratorOfMonth(ModeratorOfMonth record) async {
    await _db
        .collection(_collection)
        .doc(record.id)
        .set(record.toMap(), SetOptions(merge: true));
  }

  /// Auto-finalize winner for a completed past month if not yet crowned
  Future<void> autoFinalizePastMonthIfPending({
    required int year,
    required int month,
    required ModeratorOfMonth candidate,
  }) async {
    final now = DateTime.now();
    // Only auto-finalize if month has already finished
    final monthEnd = DateTime(year, month + 1, 1);
    if (!now.isAfter(monthEnd)) return;

    final docId = docIdFor(year, month);
    final doc = await _db.collection(_collection).doc(docId).get();
    if (!doc.exists) {
      await _db.collection(_collection).doc(docId).set(candidate.toMap());
    }
  }
}
