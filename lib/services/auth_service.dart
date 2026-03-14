import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper around Firebase Auth for login, registration, and sign-out.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Currently signed-in user (null if not authenticated).
  User? get currentUser => _auth.currentUser;

  /// UID helper — throws if not logged in.
  String get uid {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.uid;
  }

  /// Stream that emits whenever auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Register with email and password, then create a Firestore user doc.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    String location = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Create user profile document (no nulls, server timestamp only)
    try {
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'name': name.trim().isEmpty ? '' : name.trim(),
        'email': email.trim().isEmpty ? '' : email.trim(),
        'location': location.trim().isEmpty ? '' : location.trim(),
        'phone': '',
        'trustScore': 4.0,
        'completedRentals': 0,
        'groupPurchases': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Firestore user profile create error: $e');
      rethrow;
    }

    return cred;
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();
}
