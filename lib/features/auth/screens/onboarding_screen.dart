// lib/features/auth/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/auth_text_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _creating = true;
  final _householdNameCtrl = TextEditingController();
  final _inviteCodeCtrl    = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _createHousehold() async {
    if (_householdNameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter a household name.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() { _error = 'ERROR: No authenticated user found. Please sign in again.'; });
        return;
      }

      debugPrint('🐱 User ID: ${user.id}');
      debugPrint('🐱 User email: ${user.email}');
      debugPrint('🐱 User metadata: ${user.userMetadata}');
      debugPrint('🐱 Session token present: ${supabase.auth.currentSession?.accessToken != null}');

      // Step 1 — Upsert profile
      debugPrint('🐱 Step 1: Upserting profile...');
      try {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'display_name': user.userMetadata?['display_name'] ?? 'New User',
        }, onConflict: 'id');
        debugPrint('🐱 Step 1 SUCCESS: Profile upserted');
      } catch (e) {
        debugPrint('🐱 Step 1 FAILED: $e');
        setState(() { _error = 'Step 1 (profile) failed: $e'; });
        return;
      }

      // Step 2 — Create household
      debugPrint('🐱 Step 2: Creating household...');
      Map<String, dynamic> household;
      try {
        household = await supabase
            .from('households')
            .insert({
              'name': _householdNameCtrl.text.trim(),
              'created_by': user.id,
            })
            .select()
            .single();
        debugPrint('🐱 Step 2 SUCCESS: Household created: ${household['id']}');
      } catch (e) {
        debugPrint('🐱 Step 2 FAILED: $e');
        setState(() { _error = 'Step 2 (household) failed: $e'; });
        return;
      }

      // Step 3 — Add household member
      debugPrint('🐱 Step 3: Adding household member...');
      try {
        await supabase.from('household_members').insert({
          'household_id': household['id'],
          'profile_id': user.id,
          'role': 'owner',
        });
        debugPrint('🐱 Step 3 SUCCESS: Member added');
      } catch (e) {
        debugPrint('🐱 Step 3 FAILED: $e');
        setState(() { _error = 'Step 3 (member) failed: $e'; });
        return;
      }

      // Step 4 — Navigate home
      debugPrint('🐱 Step 4: Resolving auth and navigating home...');
      await ref.read(authNotifierProvider).resolve();
      if (mounted) context.go(Routes.home);
      debugPrint('🐱 Step 4 SUCCESS: Navigation complete');

    } catch (e) {
      debugPrint('🐱 Unexpected error: $e');
      setState(() { _error = 'Unexpected error: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _joinHousehold() async {
    setState(() {
      _error = 'Invite system coming in a later session. Ask your partner to share the household ID from Settings.';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Center(child: Text('🐱', style: TextStyle(fontSize: 56))),
              const SizedBox(height: 16),
              Center(child: Text('Welcome to Tuxie',
                style: TuxieTextStyles.display(28))),
              const SizedBox(height: 8),
              Center(child: Text('Set up your household to get started.',
                style: TuxieTextStyles.body(15, color: TuxieColors.textSecondary),
                textAlign: TextAlign.center)),

              const SizedBox(height: 36),

              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: TuxieColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TuxieColors.border),
                ),
                child: Row(children: [
                  Expanded(child: _TabButton(
                    label: 'Create household', active: _creating,
                    onTap: () => setState(() { _creating = true; _error = null; }),
                  )),
                  Expanded(child: _TabButton(
                    label: 'Join household', active: !_creating,
                    onTap: () => setState(() { _creating = false; _error = null; }),
                  )),
                ]),
              ),

              const SizedBox(height: 24),

              if (_creating) ...[
                Text('Household name',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w700,
                    color: TuxieColors.textSecondary)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _householdNameCtrl,
                  hint: 'e.g. The Johnson Household',
                  darkMode: false),
                const SizedBox(height: 8),
                Text('You can always rename this in Settings.',
                  style: TuxieTextStyles.body(12, color: TuxieColors.textMuted)),
              ] else ...[
                Text('Invite code',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w700,
                    color: TuxieColors.textSecondary)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _inviteCodeCtrl,
                  hint: 'Paste invite code from your partner',
                  darkMode: false),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!,
                    style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null
                    : (_creating ? _createHousehold : _joinHousehold),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text(_creating ? 'Create & continue' : 'Join household',
                        style: TuxieTextStyles.body(16,
                          weight: FontWeight.w800, color: Colors.white)),
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

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? TuxieColors.tuxedo : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
            style: TuxieTextStyles.body(13,
              weight: FontWeight.w700,
              color: active ? Colors.white : TuxieColors.textMuted)),
        ),
      ),
    );
  }
}