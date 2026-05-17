
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // ───────── EMAIL LOGIN ─────────
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    }
  }

  // ───────── EMAIL SIGNUP ─────────
  Future<User?> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(fullName);

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'selectedPlan': 'free',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    }
  }

  // ───────── GOOGLE LOGIN (FIXED) ─────────
  Future<User?> signInWithGoogle() async {
    try {
      // مهم: force account picker
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        final doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'selectedPlan': 'free',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return null;
    }
  }

  // ───────── SAVE PLAN ─────────
Future<void> setPlan(String plan) async {
  final uid = currentUser?.uid;
  if (uid == null) return;

  await _firestore.collection('users').doc(uid).update({
    'selectedPlan': plan,
  });
}
  // ───────── LOGOUT ─────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ───────── ERRORS ─────────
  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'Email already used.';
      case 'invalid-email':
        return 'Invalid email.';
      case 'weak-password':
        return 'Weak password.';
      default:
        return 'Authentication error.';
    }
  }
}