// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/auth_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await ref.read(authNotifierProvider).resolve();
      if (mounted) context.go(Routes.home);
    } catch (e) {
      setState(() { _error = 'Invalid email or password. Please try again.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuxieColors.tuxedo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Logo / mascot area
              Center(
                child: Column(children: [
                  const Text('🐱', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text('Tuxie',
                    style: TuxieTextStyles.display(42, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Your household butler',
                    style: TuxieTextStyles.body(15,
                      color: Colors.white.withValues(alpha: 0.55))),
                ]),
              ),

              const Spacer(),

              // Form
              AuthTextField(
                controller: _emailCtrl,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _passwordCtrl,
                hint: 'Password',
                obscure: true,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                    style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TuxieColors.sand,
                    foregroundColor: TuxieColors.sandDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Sign in',
                        style: TuxieTextStyles.body(16,
                          weight: FontWeight.w800,
                          color: TuxieColors.sandDark)),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.signup),
                  child: Text('New household? Create an account',
                    style: TuxieTextStyles.body(14,
                      color: Colors.white.withValues(alpha: 0.6))),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}