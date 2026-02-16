
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Force sign out to ensure account picker appears
      await _googleSignIn.signOut();
      
      // 2. Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 3. Get authentication details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // 4. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      debugPrint('✅ مرحبا بك: ${userCredential.user?.email}');
      return userCredential.user;
      
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ: $e');
      debugPrint('📚 StackTrace: $stackTrace');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

