// lib/features/auth/data/auth_error_messages.dart

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

/// What to put on screen when a sign-in or registration attempt fails.
///
/// The sign-in screen used to render `e.toString()`, which for anything
/// coming out of Firebase reads like
/// `[firebase_auth/invalid-credential] The supplied auth credential is
/// malformed or has expired.` — a string written for whoever wrote the app,
/// shown to whoever is trying to use it.
///
/// Returns null when there is nothing worth saying. That is the cancellation
/// case: someone who dismissed the Google or Apple sheet does not need to be
/// told they dismissed it.
///
/// [fallback] is used for anything unrecognised, so the caller can say
/// "Could not sign you in" or "Could not create your account" as appropriate.
/// Unrecognised errors are deliberately not shown verbatim: a plugin failure
/// or a code Firebase added last month is not something a player can act on,
/// and the raw text is as likely to alarm as to inform.
String? authErrorMessage(Object error, {required String fallback}) {
  if (error is AuthCancelled) return null;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That does not look like an email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      // Firebase returns `invalid-credential` for both a wrong password and
      // an unknown email when email enumeration protection is on, which is
      // the default. Saying which one was wrong would defeat that, so all
      // three say the same thing.
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email or password is incorrect.';

      case 'email-already-in-use':
        return 'That email already has an account. Try signing in instead.';

      case 'weak-password':
        return 'Please choose a longer password — at least 6 characters.';

      case 'account-exists-with-different-credential':
        return 'You already have an account with that email. Sign in the way '
            'you did the first time.';

      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';

      case 'network-request-failed':
        return 'No connection. Check your network and try again.';

      case 'operation-not-allowed':
        return 'That way of signing in is not available right now.';
    }
  }

  return fallback;
}

/// The two fallbacks, kept here so they read alike.
const String signInFallback = 'Could not sign you in. Please try again.';
const String registerFallback =
    'Could not create your account. Please try again.';
