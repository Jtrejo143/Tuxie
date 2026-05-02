// lib/features/tasks/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_sheet.dart';

// ── PROVIDERS ────────────────────────────────────────────────────

final selectedDomainProvider  = StateProvider<String?>((ref) => null);
final showCompletedProvider    = StateProvider<bool>((ref) => false);

final allTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final selectedDomain = ref.watch(selectedDomainProvider);
  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 allTasksProvider: fetching for userId=$userId domain=$selectedDomain');
  if (userId == null) return [];

  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();
  final householdId = member['household_id'];

  var query = supabase
    .from('tasks')
    .select('*, profiles!assigned_to(display_name)')
    .eq('household_id', householdId)
    .eq('is_completed', false);

  if (selectedDomain != null) {
    query = query.eq('domain', selectedDomain);
  }

  final result = await query
    .order('priority', ascending: false)
    .order('due_date', ascending: true);
  debugPrint('🐱 allTasksProvider: got ${result.length} tasks');
  return result;
});

final completedTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();
  final result = await supabase
    .from('tasks')
    .select('*, profiles!assigned_to(display_name)')
    .eq('household_id', member['household_id'])
    .eq('is_completed', true)
    .order('completed_at', ascending: false)
    .limit(20);
  debugPrint('🐱 completedTasksProvider: got ${result.length} completed');
  return result;
});

// ── SCREEN ───────────────────────────────────────────────────────

class TasksScreen extends ConsumerWidget {
  // No const — _completingIds is a non-const field
  // ignore: prefer_const_constructors_in_immutables
  TasksScreen({super.key});

  final Set<String> _completingIds = {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks          = ref.watch(allTasksProvider);
    final completed      = ref.watch(completedTasksProvider);
    final selectedDomain = ref.watch(selectedDomainProvider);
    final showCompleted  = ref.watch(showCompletedProvider);

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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tasks',
                            style: TuxieTextStyles.display(28,
                              color: Colors.white)),
                          Row(children: [
                            // Show completed toggle
                            GestureDetector(
                              onTap: () => ref
                                .read(showCompletedProvider.notifier)
                                .state = !showCompleted,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: showCompleted
                                    ? TuxieColors.sage
                                    : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  showCompleted
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                  color: showCompleted
                                    ? TuxieColors.sageDark
                                    : Colors.white.withValues(alpha: 0.7),
                                  size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Add task button
                            GestureDetector(
                              onTap: () => _showAddTask(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: TuxieColors.sand,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add,
                                      color: TuxieColors.sandDark, size: 18),
                                    const SizedBox(width: 4),
                                    Text('Add task',
                                      style: TuxieTextStyles.body(13,
                                        weight: FontWeight.w800,
                                        color: TuxieColors.sandDark)),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      tasks.when(
                        data: (t) => Text(
                          '${t.length} task${t.length == 1 ? "" : "s"} remaining',
                          style: TuxieTextStyles.body(13,
                            color: Colors.white.withValues(alpha: 0.55))),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _DomainChip(
                            label: 'All',
                            selected: selectedDomain == null,
                            onTap: () => ref
                              .read(selectedDomainProvider.notifier)
                              .state = null,
                          ),
                          const SizedBox(width: 8),
                          ...['household','goals','finance',
                              'health','social','work_commitments']
                            .map((d) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _DomainChip(
                                label: _domainLabel(d),
                                domain: d,
                                selected: selectedDomain == d,
                                onTap: () => ref
                                  .read(selectedDomainProvider.notifier)
                                  .state = d,
                              ),
                            )),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── TASK + COMPLETED LIST ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Active tasks
                tasks.when(
                  data: (taskList) {
                    if (taskList.isEmpty && !showCompleted) {
                      return _EmptyState(domain: selectedDomain);
                    }
                    if (taskList.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: taskList.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskCard(
                          task: t,
                          onComplete: () => _completeTask(context, ref, t),
                          onTap: () => _showEditTask(context, ref, t),
                        ),
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator())),
                  error: (e, _) => _ErrorCard(message: e.toString()),
                ),

                // Completed tasks section
                if (showCompleted)
                  completed.when(
                    data: (completedList) {
                      if (completedList.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(child: Text('No completed tasks yet',
                            style: TuxieTextStyles.body(13,
                              color: TuxieColors.textMuted))),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Row(children: [
                            const Icon(Icons.check_circle,
                              color: TuxieColors.sageDark, size: 16),
                            const SizedBox(width: 6),
                            Text('Completed (${completedList.length})',
                              style: TuxieTextStyles.body(13,
                                weight: FontWeight.w700,
                                color: TuxieColors.textSecondary)),
                          ]),
                          const SizedBox(height: 10),
                          ...completedList.take(15).map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Opacity(
                              opacity: 0.5,
                              child: TaskCard(
                                task: t,
                                onComplete: () async {
                                  await supabase.from('tasks').update({
                                    'is_completed': false,
                                    'completed_at': null,
                                    'completed_by': null,
                                  }).eq('id', t['id']);
                                  ref.invalidate(allTasksProvider);
                                  ref.invalidate(completedTasksProvider);
                                },
                                onTap: () => _showEditTask(context, ref, t),
                              ),
                            ),
                          )),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────────

  void _showAddTask(BuildContext context, WidgetRef ref) {
    debugPrint('🐱 TasksScreen: opening add task sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(onSaved: () {
        ref.invalidate(allTasksProvider);
        ref.invalidate(completedTasksProvider);
      }),
    );
  }

  void _showEditTask(BuildContext context, WidgetRef ref,
      Map<String, dynamic> task) {
    debugPrint('🐱 TasksScreen: editing task id=${task['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        existingTask: task,
        onSaved: () {
          ref.invalidate(allTasksProvider);
          ref.invalidate(completedTasksProvider);
        },
      ),
    );
  }

  Future<void> _completeTask(BuildContext context, WidgetRef ref,
      Map<String, dynamic> task) async {
    final taskId = task['id'] as String;
    if (_completingIds.contains(taskId)) {
      debugPrint('🐱 _completeTask: already completing $taskId — skipping');
      return;
    }
    _completingIds.add(taskId);
    debugPrint('🐱 _completeTask: started id=$taskId');
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('tasks').update({
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'completed_by': userId,
      }).eq('id', taskId);
      debugPrint('🐱 _completeTask: marked complete');

      final recurrence = task['recurrence'] as String? ?? 'none';
      if (recurrence != 'none') {
        await _generateNextRecurrence(task, userId);
      }

      ref.invalidate(allTasksProvider);
      ref.invalidate(completedTasksProvider);
    } catch (e) {
      debugPrint('🐱 _completeTask: FAILED — $e');
    } finally {
      _completingIds.remove(taskId);
    }
  }

  Future<void> _generateNextRecurrence(
      Map<String, dynamic> task, String userId) async {
    final recurrence = task['recurrence'] as String;
    final dueDateStr = task['due_date'] as String?;
    if (dueDateStr == null) return;
    final dueDate = DateTime.parse(dueDateStr);
    DateTime nextDate;
    switch (recurrence) {
      case 'daily':   nextDate = dueDate.add(const Duration(days: 1)); break;
      case 'weekly':  nextDate = dueDate.add(const Duration(days: 7)); break;
      case 'biweekly':nextDate = dueDate.add(const Duration(days: 14)); break;
      case 'monthly': nextDate = DateTime(dueDate.year, dueDate.month + 1, dueDate.day); break;
      default: return;
    }
    await supabase.from('tasks').insert({
      'household_id': task['household_id'],
      'title': task['title'],
      'notes': task['notes'],
      'domain': task['domain'],
      'priority': task['priority'],
      'due_date': nextDate.toIso8601String().split('T')[0],
      'assigned_to': task['assigned_to'],
      'created_by': userId,
      'is_private': task['is_private'] ?? false,
      'recurrence': recurrence,
      'recurrence_config': task['recurrence_config'],
      'parent_task_id': task['parent_task_id'] ?? task['id'],
    });
    debugPrint('🐱 _generateNextRecurrence: next due ${nextDate.toIso8601String().split('T')[0]}');
  }
}

// ── HELPERS ──────────────────────────────────────────────────────

String _domainLabel(String domain) {
  const labels = {
    'household': 'Household', 'goals': 'Goals',
    'finance': 'Finance',     'health': 'Health',
    'social': 'Social',       'work_commitments': 'Work',
  };
  return labels[domain] ?? domain;
}

// ── WIDGETS ──────────────────────────────────────────────────────

class _DomainChip extends StatelessWidget {
  final String label;
  final String? domain;
  final bool selected;
  final VoidCallback onTap;
  const _DomainChip({required this.label, this.domain,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = domain != null
      ? TuxieColors.domainColor(domain!) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TuxieTextStyles.body(12,
            weight: FontWeight.w700,
            color: selected
              ? (domain != null
                  ? TuxieColors.domainColorDark(domain!)
                  : TuxieColors.tuxedo)
              : Colors.white.withValues(alpha: 0.8))),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? domain;
  const _EmptyState({this.domain});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TuxieColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TuxieColors.border),
      ),
      child: Column(children: [
        const Text('✅', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(domain != null
          ? 'No ${_domainLabel(domain!).toLowerCase()} tasks!'
          : 'All tasks complete!',
          style: TuxieTextStyles.display(20),
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Tap + Add task to create one.',
          style: TuxieTextStyles.body(14,
            color: TuxieColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
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
      child: Text('Could not load tasks: $message',
        style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
    );
  }
}