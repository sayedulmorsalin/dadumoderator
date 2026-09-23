import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_report.dart';
import 'wallet_service.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'reports';
  final WalletService _walletService = WalletService();

  Future<void> addReport(SaleReport report) async {
    await _db.collection(_collection).add(report.toMap());
    // Sync wallet after adding report
    await _walletService.syncWalletFromReports(
        report.moderatorId, report.moderatorName);
  }

  Future<void> updateReport(SaleReport report) async {
    if (report.id == null) return;
    await _db.collection(_collection).doc(report.id).update(report.toMap());
    // Sync wallet after updating report
    await _walletService.syncWalletFromReports(
        report.moderatorId, report.moderatorName);
  }

  /// Partial field update (used for inline edits)
  Future<void> updateReportField(
      String reportId, String moderatorId, String moderatorName,
      Map<String, dynamic> fields) async {
    await _db.collection(_collection).doc(reportId).update(fields);
    await _walletService.syncWalletFromReports(moderatorId, moderatorName);
  }

  Future<void> deleteReport(String reportId) async {
    // Get report data before deleting to sync wallet
    final doc = await _db.collection(_collection).doc(reportId).get();
    String moderatorId = '';
    String moderatorName = '';
    if (doc.exists) {
      moderatorId = doc.data()?['moderatorId'] ?? '';
      moderatorName = doc.data()?['moderatorName'] ?? '';
    }
    await _db.collection(_collection).doc(reportId).delete();
    if (moderatorId.isNotEmpty) {
      await _walletService.syncWalletFromReports(moderatorId, moderatorName);
    }
  }

  /// Reports submitted by a specific moderator
  Stream<List<SaleReport>> getModeratorReports(String moderatorId) {
    return _db
        .collection(_collection)
        .where('moderatorId', isEqualTo: moderatorId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => SaleReport.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// All reports for a given date range (admin)
  Stream<List<SaleReport>> getReportsByDateRange(
      DateTime start, DateTime end) {
    return _db
        .collection(_collection)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SaleReport.fromMap(d.data(), d.id)).toList());
  }

  /// Reports for a specific day (admin)
  Stream<List<SaleReport>> getDailyReports(DateTime day) {
    final start = DateTime(day.year, day.month, day.day, 0, 0, 0);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return getReportsByDateRange(start, end);
  }

  /// Reports for a specific month (admin)
  Stream<List<SaleReport>> getMonthlyReports(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1)
        .subtract(const Duration(seconds: 1));
    return getReportsByDateRange(start, end);
  }

  /// Reports for a specific year (admin)
  Stream<List<SaleReport>> getYearlyReports(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    return getReportsByDateRange(start, end);
  }
}

