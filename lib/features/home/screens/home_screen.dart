// lib/features/home/screens/home_screen.dart
// The main daily focus screen — first real data-connected screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../../tasks/widgets/task_card.dart';
import '../../tasks/widgets/add_task_sheet.dart';

// ── PROVIDERS ────────────────────────────────────────────────────
// All providers watch authNotifierProvider so they automatically
// re-fetch when the logged-in user changes (login / logout / switch).
// This fixes the stale name bug where the previous user's data
// was shown after signing in as a different account.

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch auth state — invalidates this provider on every auth change
  ref.watch(authNotifierProvider);

  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 profileProvider: fetching for userId=$userId');
  if (userId == null) {
    debugPrint('🐱 profileProvider: no user — returning null');
    return null;
  }
  final result = await supabase
    .from('profiles')
    .select()
    .eq('id', userId)
    .single();
  debugPrint('🐱 profileProvider: got display_name=${result['display_name']}');
  return result;
});

final householdProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authNotifierProvider);

  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 householdProvider: fetching for userId=$userId');
  if (userId == null) return null;

  final member = await supabase
    .from('household_members')
    .select('household_id, households(name)')
    .eq('profile_id', userId)
    .single();
  final household = member['households'] as Map<String, dynamic>?;
  debugPrint('🐱 householdProvider: got household=${household?['name']}');
  return household;
});

final todayTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);

  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 todayTasksProvider: fetching for userId=$userId');
  if (userId == null) return [];

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();
  final householdId = member['household_id'];

  final tasks = await supabase
    .from('tasks')
    .select('*, profiles!assigned_to(display_name)')
    .eq('household_id', householdId)
    .eq('is_completed', false)
    .lte('due_date', today)
    .order('priority', ascending: false)
    .order('due_date', ascending: true)
    .limit(5);
  debugPrint('🐱 todayTasksProvider: found ${tasks.length} tasks');
  return tasks;
});

final habitSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(authNotifierProvider);

  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 habitSummaryProvider: fetching for userId=$userId');
  if (userId == null) return {'total': 0, 'done': 0};

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();
  final householdId = member['household_id'];

  final habits = await supabase
    .from('habits')
    .select('id')
    .eq('household_id', householdId)
    .eq('is_active', true);

  final logs = await supabase
    .from('habit_logs')
    .select('id')
    .eq('profile_id', userId)
    .eq('logged_date', today)
    .eq('is_completed', true);

  debugPrint('🐱 habitSummaryProvider: ${logs.length}/${habits.length} habits done');
  return {'total': habits.length, 'done': logs.length};
});

// ── SCREEN ───────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile   = ref.watch(profileProvider);
    final household = ref.watch(householdProvider);
    final tasks     = ref.watch(todayTasksProvider);
    final habits    = ref.watch(habitSummaryProvider);

    final now      = DateTime.now();
    final hour     = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr  = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(householdProvider);
          ref.invalidate(todayTasksProvider);
          ref.invalidate(habitSummaryProvider);
        },
        color: TuxieColors.lavenderDark,
        child: CustomScrollView(
          slivers: [

            // ── DARK HEADER ──────────────────────────────────────
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

                        // Date + sign out row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr,
                              style: TuxieTextStyles.body(13,
                                weight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.55))),
                            const Icon(Icons.notifications_outlined,
                              color: Colors.white54, size: 22),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Greeting + mascot row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: profile.when(
                                data: (p) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$greeting,',
                                      style: TuxieTextStyles.body(16,
                                        color: Colors.white.withValues(alpha: 0.7))),
                                    Text(p?['display_name'] ?? 'Welcome',
                                      style: TuxieTextStyles.display(30,
                                        color: TuxieColors.sand)),
                                  ],
                                ),
                                loading: () => const SizedBox(height: 60),
                                error: (_, __) => Text('Welcome back',
                                  style: TuxieTextStyles.display(30,
                                    color: Colors.white)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('🐱',
                                style: TextStyle(fontSize: 36)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Daily brief card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✦ ',
                                style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                              Expanded(
                                child: tasks.when(
                                  data: (taskList) {
                                    final count = taskList.length;
                                    final briefText = count > 0
                                      ? 'You have $count item${count == 1 ? "" : "s"} needing attention today.'
                                      : 'You\'re all caught up for today! Enjoy the day. 🎉';
                                    return Text(briefText,
                                      style: TuxieTextStyles.body(13,
                                        color: Colors.white.withValues(alpha: 0.8)));
                                  },
                                  loading: () => Text('Checking your day...',
                                    style: TuxieTextStyles.body(13,
                                      color: Colors.white.withValues(alpha: 0.6))),
                                  error: (_, __) => Text('Pull down to refresh.',
                                    style: TuxieTextStyles.body(13,
                                      color: Colors.white.withValues(alpha: 0.6))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── BODY ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  _SectionHeader(title: "Today's Focus", action: "See all"),
                  const SizedBox(height: 10),

                  tasks.when(
                    data: (taskList) {
                      if (taskList.isEmpty) {
                        return _EmptyState(
                          emoji: '✅',
                          message: 'Nothing due today — you\'re on top of it!',
                          color: TuxieColors.sage,
                        );
                      }
                      return Column(
                        children: taskList.map((task) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskCard(
                              task: task,
                              onComplete: () async {
                                final userId = supabase.auth.currentUser!.id;
                                await supabase.from('tasks').update({
                                  'is_completed': true,
                                  'completed_at': DateTime.now().toIso8601String(),
                                  'completed_by': userId,
                                }).eq('id', task['id']);
                                ref.invalidate(todayTasksProvider);
                              },
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddTaskSheet(
                                  existingTask: task,
                                  onSaved: () => ref.invalidate(todayTasksProvider),
                                ),
                              ),
                            ),
                          )
                        ).toList(),
                      );
                    },
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                  ),

                  const SizedBox(height: 24),

                  _SectionHeader(title: "At a glance"),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: tasks.when(
                          data: (t) => _StatCard(
                            value: '${t.length}',
                            label: 'Tasks due',
                            sub: t.isEmpty ? 'all clear!' : 'today',
                            color: t.isEmpty ? TuxieColors.sage : TuxieColors.blush,
                            tc: t.isEmpty ? TuxieColors.sageDark : TuxieColors.blushDark,
                          ),
                          loading: () => const _StatCard(value: '...', label: 'Tasks', sub: '',
                            color: TuxieColors.blush, tc: TuxieColors.blushDark),
                          error: (_, __) => const _StatCard(value: '?', label: 'Tasks', sub: '',
                            color: TuxieColors.blush, tc: TuxieColors.blushDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: habits.when(
                          data: (h) => _StatCard(
                            value: '${h["done"]}/${h["total"]}',
                            label: 'Habits',
                            sub: 'done today',
                            color: TuxieColors.sage,
                            tc: TuxieColors.sageDark,
                          ),
                          loading: () => const _StatCard(value: '...', label: 'Habits', sub: '',
                            color: TuxieColors.sage, tc: TuxieColors.sageDark),
                          error: (_, __) => const _StatCard(value: '?', label: 'Habits', sub: '',
                            color: TuxieColors.sage, tc: TuxieColors.sageDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: household.when(
                          data: (h) => _StatCard(
                            value: '🏠',
                            label: 'Household',
                            sub: h?['name']?.toString().split(' ').first ?? 'Home',
                            color: TuxieColors.lavender,
                            tc: TuxieColors.lavenderDark,
                          ),
                          loading: () => const _StatCard(value: '🏠', label: 'Home', sub: '...',
                            color: TuxieColors.lavender, tc: TuxieColors.lavenderDark),
                          error: (_, __) => const _StatCard(value: '🏠', label: 'Home', sub: '',
                            color: TuxieColors.lavender, tc: TuxieColors.lavenderDark),
                        ),
                      ),
                    ],
                  ),

                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TuxieTextStyles.display(18)),
        if (action != null)
          Text(action!,
            style: TuxieTextStyles.body(12,
              weight: FontWeight.w700,
              color: TuxieColors.lavenderDark)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String sub;
  final Color color;
  final Color tc;
  const _StatCard({
    required this.value,
    required this.label,
    required this.sub,
    required this.color,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TuxieColors.border),
      ),
      child: Column(
        children: [
          Text(value,
            style: TuxieTextStyles.body(22,
              weight: FontWeight.w800, color: tc)),
          const SizedBox(height: 2),
          Text(label,
            style: TuxieTextStyles.body(11, weight: FontWeight.w700)),
          Text(sub,
            style: TuxieTextStyles.body(10,
              color: TuxieColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  final Color color;
  const _EmptyState({
    required this.emoji,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(child: Text(message,
            style: TuxieTextStyles.body(14, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: TuxieColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuxieColors.blush,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Could not load tasks. Pull down to retry.',
        style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
    );
  }
}