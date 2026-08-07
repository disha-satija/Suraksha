import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';
import 'main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isInitialized) return const MainShell();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (Supabase.instance.client.auth.currentSession != null) return const MainShell();
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; _message = null; });
    try {
      final client = Supabase.instance.client;
      if (_register) {
        final result = await client.auth.signUp(email: _email.text.trim(), password: _password.text);
        if (result.session == null) {
          _message = 'Account created. Check your email if confirmation is enabled.';
        }
      } else {
        await client.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Authentication failed: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 54),
                    const SizedBox(height: 12),
                    Text(_register ? 'Create your Suraksha account' : 'Welcome to Suraksha', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 22),
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 12),
                    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.dangerRed)),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, style: const TextStyle(color: AppColors.safeGreen)),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading ? const CircularProgressIndicator() : Text(_register ? 'Create account' : 'Sign in'),
                    ),
                    TextButton(onPressed: _loading ? null : () => setState(() { _register = !_register; _error = null; _message = null; }), child: Text(_register ? 'Already have an account? Sign in' : 'Create an account')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
