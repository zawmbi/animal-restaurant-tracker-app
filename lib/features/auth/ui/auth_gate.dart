import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/data/unlocked_store.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        // Hook user into UnlockedStore for cloud sync.
        UnlockedStore.instance.attachUser(user);

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const LoginPage();
        }

        return child;
      },
    );
  }
}
