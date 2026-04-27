// lib/features/auth/screens/onboarding_screen.dart
// After signup: create a new household OR join an existing one via invite code

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/auth_text_field.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _creating = true; // true = create, false = join
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
      final userId = supabase.auth.currentUser!.id;

      // 1. Create the household
      final household = await supabase
        .from('households')
        .insert({
          'name': _householdNameCtrl.text.trim(),
          'created_by': userId,
        })
        .select()
        .single();

      // 2. Add current user as owner
      await supabase.from('household_members').insert({
        'household_id': household['id'],
        'profile_id': userId,
        'role': 'owner',
      });

      if (mounted) context.go(Routes.home);
    } catch (e) {
      setState(() { _error = 'Could not create household. Please try again.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // NOTE: Join via invite code will be implemented in a later session
  // For now this shows the UI — the invite system is Milestone 1 polish
  Future<void> _joinHousehold() async {
    setState(() {
      _error = 'Invite system coming soon! Ask your partner to share the household ID from Settings.';
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

              // Header
              Center(child: Text('🐱', style: const TextStyle(fontSize: 56))),
              const SizedBox(height: 16),
              Center(child: Text('Welcome to Tuxie',
                style: TuxieTextStyles.display(28))),
              const SizedBox(height: 8),
              Center(child: Text('Set up your household to get started.',
                style: TuxieTextStyles.body(15,
                  color: TuxieColors.textSecondary),
                textAlign: TextAlign.center,
              )),

              const SizedBox(height: 36),

              // Toggle: Create vs Join
              Container(
                decoration: BoxDecoration(
                  color: TuxieColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TuxieColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: _TabButton(
                      label: 'Create household',
                      active: _creating,
                      onTap: () => setState(() { _creating = true; _error = null; }),
                    )),
                    Expanded(child: _TabButton(
                      label: 'Join household',
                      active: !_creating,
                      onTap: () => setState(() { _creating = false; _error = null; }),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form
              if (_creating) ...[
                Text('Household name',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w700,
                    color: TuxieColors.textSecondary)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _householdNameCtrl,
                  hint: 'e.g. The Johnson Household',
                  darkMode: false,
                ),
                const SizedBox(height: 8),
                Text('You can always rename this in Settings.',
                  style: TuxieTextStyles.body(12,
                    color: TuxieColors.textMuted)),
              ] else ...[
                Text('Invite code',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w700,
                    color: TuxieColors.textSecondary)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _inviteCodeCtrl,
                  hint: 'Paste invite code from your partner',
                  darkMode: false,
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                    style: TuxieTextStyles.body(13,
                      color: TuxieColors.blushDark)),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                    ? null
                    : (_creating ? _createHousehold : _joinHousehold),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
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
