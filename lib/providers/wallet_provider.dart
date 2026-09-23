import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../models/payout_request.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _service = WalletService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Wallet Streams ────────────────────────────────────────────────────────

  Stream<Wallet?> getWallet(String moderatorId) =>
      _service.getWallet(moderatorId);

  Stream<List<Wallet>> getAllWallets() => _service.getAllWallets();

  // ─── Payout Request Streams ────────────────────────────────────────────────

  Stream<List<PayoutRequest>> getPayoutRequests(String moderatorId) =>
      _service.getPayoutRequests(moderatorId);

  Stream<List<PayoutRequest>> getAllPayoutRequests() =>
      _service.getAllPayoutRequests();

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<bool> requestPayout({
    required String moderatorId,
    required String moderatorName,
    required double amount,
    String note = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final req = PayoutRequest(
        moderatorId: moderatorId,
        moderatorName: moderatorName,
        amount: amount,
        requestedAt: DateTime.now(),
        note: note,
      );
      await _service.requestPayout(req);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'পেআউট রিকোয়েস্ট পাঠানো যায়নি।';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolvePayoutRequest(
      PayoutRequest req, bool approved, String adminNote) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.resolvePayoutRequest(req, approved, adminNote);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'রিকোয়েস্ট প্রক্রিয়া করা যায়নি।';
      notifyListeners();
      return false;
    }
  }
}
