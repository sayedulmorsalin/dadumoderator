import 'package:flutter/material.dart';
import '../models/sale_report.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  bool _isSubmitting = false;
  String? _submitError;
  String? _submitSuccess;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  String? get submitSuccess => _submitSuccess;

  void clearMessages() {
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
  }

  Future<bool> submitReport(SaleReport report) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
    try {
      await _service.addReport(report);
      _isSubmitting = false;
      _submitSuccess = 'রিপোর্ট সফলভাবে সংরক্ষিত হয়েছে!';
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _submitError = 'রিপোর্ট সংরক্ষণ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReport(SaleReport report) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await _service.updateReport(report);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _submitError = 'আপডেট ব্যর্থ হয়েছে।';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      await _service.deleteReport(reportId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<SaleReport>> getModeratorReports(String moderatorId) {
    return _service.getModeratorReports(moderatorId);
  }

  Stream<List<SaleReport>> getDailyReports(DateTime day) {
    return _service.getDailyReports(day);
  }

  Stream<List<SaleReport>> getMonthlyReports(int year, int month) {
    return _service.getMonthlyReports(year, month);
  }

  Stream<List<SaleReport>> getYearlyReports(int year) {
    return _service.getYearlyReports(year);
  }
}

