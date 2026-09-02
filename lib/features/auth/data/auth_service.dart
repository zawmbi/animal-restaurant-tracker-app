import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Cryptographically random string used to tie an Apple ID token to this
/// specific sign-in attempt. Apple receives its SHA-256 hash; Firebase receives
/// the raw value and checks that they match. Without this, Firebase rejects the
/// credential.
String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256OfString(String input) => sha256.convert(utf8.encode(input)).toString();

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;

    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(cred);
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();

    final result = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256OfString(rawNonce),
    );

    final oauth = OAuthProvider('apple.com').credential(
      idToken: result.identityToken,
      rawNonce: rawNonce,
      accessToken: result.authorizationCode,
    );

    return _auth.signInWithCredential(oauth);
  }

  /// Permanently deletes the signed-in account and the Firestore document that
  /// holds its progress. Required by App Store Review Guideline 5.1.1(v) for
  /// any app that offers account creation.
  ///
  /// Throws [FirebaseAuthException] with code `requires-recent-login` when the
  /// session is too old; the caller should ask the user to sign in again.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No user is signed in.');
    }

    // Remove stored progress first — once the auth user is gone the security
    // rules will no longer permit writes as that uid.
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    } catch (_) {
      // A missing or unreadable document must not block account deletion.
    }

    await user.delete();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  Future<void> signOut() async {
    // Also sign out of Google session if present.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    await _auth.signOut();
  }
}
