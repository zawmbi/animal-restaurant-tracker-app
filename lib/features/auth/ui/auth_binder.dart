import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/data/unlocked_store.dart';

class AuthBinder extends StatefulWidget {
  const AuthBinder({super.key, required this.child});
  final Widget child;

  @override
  State<AuthBinder> createState() => _AuthBinderState();
}

class _AuthBinderState extends State<AuthBinder> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();

    UnlockedStore.instance.attachUser(FirebaseAuth.instance.currentUser);

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      UnlockedStore.instance.attachUser(user);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
