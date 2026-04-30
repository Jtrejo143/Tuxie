// lib/features/auth/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/auth_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter your name.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: { 'display_name': _nameCtrl.text.trim() },
      );
      await ref.read(authNotifierProvider).resolve();
      if (mounted) context.go(Routes.onboarding);
    } catch (e) {
      setState(() { _error = e.toString(); });
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
              Center(child: Text('Create Account',
                style: TuxieTextStyles.display(32, color: Colors.white))),
              Center(child: Text('Let\'s set up your household',
                style: TuxieTextStyles.body(15,
                  color: Colors.white.withValues(alpha: 0.55)))),
              const Spacer(),
              AuthTextField(controller: _nameCtrl, hint: 'Your name (e.g. Alex)'),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _emailCtrl,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _passwordCtrl,
                hint: 'Password (min 8 characters)',
                obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!,
                    style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TuxieColors.sand,
                    foregroundColor: TuxieColors.sandDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Create account',
                        style: TuxieTextStyles.body(16,
                          weight: FontWeight.w800, color: TuxieColors.sandDark)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: Text('Already have an account? Sign in',
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