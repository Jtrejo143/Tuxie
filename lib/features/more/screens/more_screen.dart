// lib/features/more/screens/more_screen.dart
// Hub screen — household profile, member info, and navigation to sub-screens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';

// ── PROVIDERS ────────────────────────────────────────────────────

final householdDetailProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 householdDetailProvider: fetching for userId=$userId');
  if (userId == null) return null;

  final member = await supabase
      .from('household_members')
      .select('household_id, role, households(name, created_by)')
      .eq('profile_id', userId)
      .single();

  debugPrint('🐱 householdDetailProvider: got household=${member['households']['name']}');
  return member;
});

final householdMembersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();

  final members = await supabase
      .from('household_members')
      .select('profile_id, role, profiles(display_name)')
      .eq('household_id', member['household_id']);

  debugPrint('🐱 householdMembersProvider: got ${members.length} members');
  return List<Map<String, dynamic>>.from(members);
});

// ── SCREEN ───────────────────────────────────────────────────────

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdDetail  = ref.watch(householdDetailProvider);
    final householdMembers = ref.watch(householdMembersProvider);

    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: CustomScrollView(
        slivers: [

          // ── HEADER ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [TuxieColors.tuxedo, TuxieColors.tuxedoSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Mascot + household info row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Mascot avatar
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text('🐱',
                                style: TextStyle(fontSize: 36))),
                          ),
                          const SizedBox(width: 16),

                          // Household name + members
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                householdDetail.when(
                                  data: (d) => Text(
                                    d?['households']['name'] ?? 'My Household',
                                    style: TuxieTextStyles.display(22,
                                      color: Colors.white)),
                                  loading: () => Text('Loading...',
                                    style: TuxieTextStyles.display(22,
                                      color: Colors.white)),
                                  error: (_, __) => Text('Household',
                                    style: TuxieTextStyles.display(22,
                                      color: Colors.white)),
                                ),
                                const SizedBox(height: 6),
                                // Member role chips
                                householdMembers.when(
                                  data: (members) => Wrap(
                                    spacing: 6,
                                    children: members.map((m) {
                                      final profile = m['profiles']
                                          as Map<String, dynamic>?;
                                      final name = profile?['display_name']
                                          as String? ?? '?';
                                      final role = m['role'] as String? ?? '';
                                      final isMe = m['profile_id'] ==
                                          supabase.auth.currentUser?.id;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isMe
                                            ? TuxieColors.sand
                                            : Colors.white
                                                .withValues(alpha: 0.15),
                                          borderRadius:
                                            BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${name.split(' ').first} · $role',
                                          style: TuxieTextStyles.body(11,
                                            weight: FontWeight.w700,
                                            color: isMe
                                              ? TuxieColors.sandDark
                                              : Colors.white
                                                  .withValues(alpha: 0.85))),
                                      );
                                    }).toList(),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── MENU ITEMS ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                _SectionLabel('Features'),
                const SizedBox(height: 10),

                _MenuItem(
                  emoji: '🎯',
                  label: 'Goals & Vision',
                  sub: 'Vision board, goals, and projects',
                  color: TuxieColors.blush,
                  onTap: () => context.go(Routes.goals),
                ),
                _MenuItem(
                  emoji: '💪',
                  label: 'Health & Habits',
                  sub: 'Appointments and daily habits',
                  color: TuxieColors.sage,
                  onTap: () => context.go(Routes.health),
                ),
                _MenuItem(
                  emoji: '📦',
                  label: 'Inventory',
                  sub: 'Household essentials tracker',
                  color: TuxieColors.sand,
                  onTap: () => context.go(Routes.inventory),
                ),
                _MenuItem(
                  emoji: '🤖',
                  label: 'Ask Tuxie',
                  sub: 'Chat with your AI household butler',
                  color: TuxieColors.lavender,
                  onTap: () => context.go(Routes.chat),
                ),

                const SizedBox(height: 24),
                _SectionLabel('Household'),
                const SizedBox(height: 10),

                _MenuItem(
                  emoji: '⚙️',
                  label: 'Settings',
                  sub: 'Preferences and household config',
                  color: TuxieColors.linen,
                  onTap: () {
                    // Settings — Milestone 6
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings coming in Milestone 6'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _SectionLabel('Account'),
                const SizedBox(height: 10),

                // Sign out
                _SignOutTile(ref: ref),

                const SizedBox(height: 40),

                // Version tag
                Center(
                  child: Text('Tuxie · Milestone 2',
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textMuted)),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: TuxieTextStyles.body(12,
        weight: FontWeight.w700,
        color: TuxieColors.textMuted));
  }
}

class _MenuItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TuxieColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TuxieColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(emoji,
                style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TuxieTextStyles.body(15,
                      weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub,
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
              color: TuxieColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  final WidgetRef ref;
  const _SignOutTile({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        debugPrint('🐱 MoreScreen: signing out');
        await supabase.auth.signOut();
        // AuthNotifier listens to auth stream — handles redirect automatically
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TuxieColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TuxieColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: TuxieColors.blush,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.logout_rounded,
                  color: TuxieColors.blushDark, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign out',
                    style: TuxieTextStyles.body(15,
                      weight: FontWeight.w700,
                      color: TuxieColors.blushDark)),
                  const SizedBox(height: 2),
                  Text('Sign out of your account',
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
              color: TuxieColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
