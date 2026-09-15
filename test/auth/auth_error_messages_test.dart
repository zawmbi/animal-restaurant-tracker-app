// The sign-in screen used to print `e.toString()` straight to the user, so a
// mistyped password read
// "[firebase_auth/invalid-credential] The supplied auth credential is
// malformed or has expired." These pin that nothing like that reaches a
// player again.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/auth/data/auth_error_messages.dart';
import 'package:animal_restaurant_tracker/features/auth/data/auth_service.dart';

String? _message(String code) => authErrorMessage(
      FirebaseAuthException(code: code),
      fallback: signInFallback,
    );

void main() {
  group('authErrorMessage', () {
    test('a cancelled sheet says nothing at all', () {
      expect(
        authErrorMessage(const AuthCancelled(), fallback: signInFallback),
        isNull,
      );
    });

    test('a wrong password does not say which half was wrong', () {
      // Firebase returns invalid-credential for both an unknown email and a
      // wrong password when email enumeration protection is on. Naming which
      // one failed would undo that protection.
      const expected = 'Email or password is incorrect.';
      expect(_message('invalid-credential'), expected);
      expect(_message('user-not-found'), expected);
      expect(_message('wrong-password'), expected);
    });

    test('the cases a new user actually hits read like sentences', () {
      expect(_message('email-already-in-use'), contains('already has an account'));
      expect(_message('weak-password'), contains('at least 6 characters'));
      expect(_message('invalid-email'), contains('email address'));
      expect(_message('network-request-failed'), contains('No connection'));
      expect(_message('too-many-requests'), contains('Wait a moment'));
    });

    test('an unrecognised Firebase code falls back', () {
      expect(_message('some-code-firebase-added-last-month'), signInFallback);
    });

    test('a non-Firebase error falls back, and registering says so', () {
      expect(
        authErrorMessage(StateError('boom'), fallback: signInFallback),
        signInFallback,
      );
      expect(
        authErrorMessage(Exception('boom'), fallback: registerFallback),
        registerFallback,
      );
    });

    test('no message ever leaks the plumbing', () {
      const codes = [
        'invalid-credential',
        'user-not-found',
        'wrong-password',
        'email-already-in-use',
        'weak-password',
        'invalid-email',
        'user-disabled',
        'network-request-failed',
        'too-many-requests',
        'operation-not-allowed',
        'account-exists-with-different-credential',
        'anything-unrecognised',
      ];
      for (final code in codes) {
        final message = _message(code)!;
        expect(message, isNot(contains('firebase')));
        expect(message, isNot(contains('[')));
        expect(message, isNot(contains('Exception')));
        expect(message, isNot(contains(code)));
        expect(message.endsWith('.'), isTrue, reason: '"$message" is a sentence');
      }
    });
  });
}
