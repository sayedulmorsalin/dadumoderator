import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      // Re-throw so callers can inspect and display specific error
      rethrow;
    }
  }

  Future<AppUser?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return null;
    return getUserData(cred.user!.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> updateName(String uid, String newName) async {
    await _firestore.collection('users').doc(uid).update({'name': newName});
    return getUserData(uid);
  }

  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final appUser = AppUser(uid: uid, name: name, email: email, role: role);
    await _firestore.collection('users').doc(uid).set(appUser.toMap());
    return appUser;
  }
}
