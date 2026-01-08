import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    await _run(() async {
      final email = _email.text.trim();
      final password = _password.text;

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required.');
      }

      if (_isLogin) {
        await AuthService.instance.signInWithEmail(email: email, password: password);
      } else {
        await AuthService.instance.registerWithEmail(email: email, password: password);
      }
    });
  }

  Future<void> _google() async {
    await _run(() async {
      await AuthService.instance.signInWithGoogle();
    });
  }

  Future<void> _apple() async {
    await _run(() async {
      await AuthService.instance.signInWithApple();
    });
  }

  Future<void> _anon() async {
    await _run(() async {
      await AuthService.instance.signInAnonymously();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Sign in' : 'Create account';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submitEmail,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(title),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          }),
                  child: Text(
                    _isLogin
                        ? 'Need an account? Create one'
                        : 'Already have an account? Sign in',
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _google,
                    child: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _apple,
                    child: const Text('Continue with Apple'),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _busy ? null : _anon,
                    child: const Text('Continue without an account'),
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  'Without an account, progress is saved on this device only. '
                  'With an account, progress can sync across devices.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
