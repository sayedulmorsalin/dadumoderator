import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.signIn(email, password);
      _isLoading = false;
      if (_user == null) {
        final current = _authService.currentUser;
        if (current != null) {
          _errorMessage =
              'অ্যাকাউন্ট পাওয়া গেছে কিন্তু Firestore-এ রোল তৈরি করা নেই। Firestore-এ users/${current.uid} তৈরি করুন।';
        } else {
          _errorMessage = 'লগইন ব্যর্থ হয়েছে। অ্যাকাউন্ট পাওয়া যায়নি।';
        }
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    await Future.microtask(() {});
    _isLoading = true;
    notifyListeners();
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserData(currentUser.uid);
      }
    } catch (e) {
      // ignore
    }
    _isLoading = false;
    notifyListeners();
  }

  String _parseError(String e) {
    final lower = e.toLowerCase();
    if (lower.contains('operation-not-allowed')) {
      return 'Firebase Console-এ Authentication > Sign-in method-এ Email/Password চালু করুন।';
    }
    if (lower.contains('user-not-found')) {
      return 'এই ইমেইলে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';
    }
    if (lower.contains('wrong-password') || lower.contains('invalid-credential')) {
      return 'ইমেইল বা পাসওয়ার্ড ভুল।';
    }
    if (lower.contains('invalid-email')) {
      return 'ইমেইল এড্রেসটি সঠিক নয়।';
    }
    if (lower.contains('email-already-in-use')) {
      return 'এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট রয়েছে।';
    }
    if (lower.contains('weak-password')) {
      return 'পাসওয়ার্ডটি অত্যন্ত দুর্বল (কমপক্ষে ৬ ডিজিট দিন)।';
    }
    if (lower.contains('network-request-failed')) {
      return 'ইন্টারনেট সংযোগ নেই। নেট চেক করুন।';
    }
    if (lower.contains('permission-denied')) {
      return 'Firestore পারমিশন নেই (Firebase Console-এ Rules চেক করুন)।';
    }
    if (lower.contains('too-many-requests')) {
      return 'অতিরিক্ত চেষ্টা করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
    }
    return 'ত্রুটি: $e';
  }
}
