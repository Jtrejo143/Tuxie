// lib/features/calendar/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/add_event_sheet.dart';

// ── PROVIDERS ────────────────────────────────────────────────────

final selectedDateProvider   = StateProvider<DateTime>((ref) => DateTime.now());
final calendarViewProvider   = StateProvider<String>((ref) => 'Month');

final eventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 eventsProvider: fetching for userId=$userId');
  if (userId == null) return [];

  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();

  final from = DateTime.now().subtract(const Duration(days: 30));
  final to   = DateTime.now().add(const Duration(days: 60));

  final result = await supabase
    .from('events')
    .select('*')
    .eq('household_id', member['household_id'])
    .gte('start_at', from.toIso8601String())
    .lte('start_at', to.toIso8601String())
    .order('start_at', ascending: true);

  debugPrint('🐱 eventsProvider: got ${result.length} events');
  return List<Map<String, dynamic>>.from(result);
});

// ── SCREEN ───────────────────────────────────────────────────────

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final view         = ref.watch(calendarViewProvider);
    final events       = ref.watch(eventsProvider);

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Calendar',
                                style: TuxieTextStyles.display(28,
                                  color: Colors.white)),
                              Text(
                                DateFormat('MMMM yyyy').format(selectedDate),
                                style: TuxieTextStyles.body(14,
                                  color: Colors.white.withValues(alpha: 0.55))),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showAddEvent(context, ref, selectedDate),
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
                                  Text('Add event',
                                    style: TuxieTextStyles.body(13,
                                      weight: FontWeight.w800,
                                      color: TuxieColors.sandDark)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: ['Day','Week','Month'].map((v) {
                            final isSelected = view == v;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => ref
                                  .read(calendarViewProvider.notifier)
                                  .state = v,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                      ? TuxieColors.white
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(child: Text(v,
                                    style: TuxieTextStyles.body(13,
                                      weight: FontWeight.w700,
                                      color: isSelected
                                        ? TuxieColors.tuxedo
                                        : Colors.white.withValues(alpha: 0.7)))),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── CALENDAR BODY ─────────────────────────────────────
          SliverToBoxAdapter(
            child: events.when(
              data: (eventList) {
                switch (view) {
                  case 'Day':
                    return _DayView(
                      date: selectedDate,
                      events: eventList,
                      onDateChanged: (d) => ref
                        .read(selectedDateProvider.notifier).state = d,
                      onEdit: (e) => _showEditEvent(context, ref, e),
                    );
                  case 'Week':
                    return _WeekView(
                      date: selectedDate,
                      events: eventList,
                      onDateSelected: (d) => ref
                        .read(selectedDateProvider.notifier).state = d,
                      onEdit: (e) => _showEditEvent(context, ref, e),
                    );
                  default:
                    return _MonthView(
                      date: selectedDate,
                      events: eventList,
                      onDateSelected: (d) {
                        ref.read(selectedDateProvider.notifier).state = d;
                        ref.read(calendarViewProvider.notifier).state = 'Day';
                      },
                      onMonthChanged: (d) => ref
                        .read(selectedDateProvider.notifier).state = d,
                      onEdit: (e) => _showEditEvent(context, ref, e),
                    );
                }
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator())),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load events: $e',
                  style: TuxieTextStyles.body(13,
                    color: TuxieColors.blushDark))),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEvent(BuildContext context, WidgetRef ref, DateTime date) {
    debugPrint('🐱 CalendarScreen: opening add event sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventSheet(
        initialDate: date,
        onSaved: () => ref.invalidate(eventsProvider),
      ),
    );
  }

  void _showEditEvent(BuildContext context, WidgetRef ref,
      Map<String, dynamic> event) {
    debugPrint('🐱 CalendarScreen: editing event id=${event['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventSheet(
        initialDate: DateTime.parse(event['start_at']),
        existingEvent: event,
        onSaved: () => ref.invalidate(eventsProvider),
      ),
    );
  }
}

// ── MONTH VIEW ───────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> events;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _MonthView({
    required this.date, required this.events,
    required this.onDateSelected, required this.onMonthChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay    = DateTime(date.year, date.month, 1);
    final lastDay     = DateTime(date.year, date.month + 1, 0);
    final startOffset = firstDay.weekday % 7;
    final today       = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => onMonthChanged(
                DateTime(date.year, date.month - 1))),
            Text(DateFormat('MMMM yyyy').format(date),
              style: TuxieTextStyles.display(18)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => onMonthChanged(
                DateTime(date.year, date.month + 1))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Su','Mo','Tu','We','Th','Fr','Sa'].map((d) =>
            Expanded(child: Center(child: Text(d,
              style: TuxieTextStyles.body(12,
                weight: FontWeight.w700,
                color: TuxieColors.textMuted))))).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 0.85),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayNum = index - startOffset + 1;
            if (dayNum < 1 || dayNum > lastDay.day) {
              return const SizedBox.shrink();
            }
            final cellDate = DateTime(date.year, date.month, dayNum);
            final isToday  = cellDate.year == today.year &&
                             cellDate.month == today.month &&
                             cellDate.day == today.day;
            final isSelected = cellDate.year == date.year &&
                               cellDate.month == date.month &&
                               cellDate.day == date.day;
            final dayEvents = events.where((e) {
              final start = DateTime.parse(e['start_at']);
              return start.year == cellDate.year &&
                     start.month == cellDate.month &&
                     start.day == cellDate.day;
            }).toList();

            return GestureDetector(
              onTap: () => onDateSelected(cellDate),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                    ? TuxieColors.tuxedo
                    : isToday ? TuxieColors.sand : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum',
                      style: TuxieTextStyles.body(14,
                        weight: FontWeight.w700,
                        color: isSelected
                          ? Colors.white
                          : isToday
                            ? TuxieColors.sandDark
                            : TuxieColors.textPrimary)),
                    if (dayEvents.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: dayEvents.take(3).map((e) {
                          final domain = e['domain'] as String? ?? 'household';
                          return Container(
                            width: 5, height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : TuxieColors.domainColorDark(domain),
                              shape: BoxShape.circle),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (events.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text('This period',
              style: TuxieTextStyles.display(18))),
          const SizedBox(height: 12),
          ...events.map((e) => _EventTile(
            event: e, showDate: true,
            onTap: () => onEdit(e))),
        ] else
          _EmptyEvents(),
      ]),
    );
  }
}

// ── WEEK VIEW ────────────────────────────────────────────────────

class _WeekView extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> events;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _WeekView({
    required this.date, required this.events,
    required this.onDateSelected, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = date.subtract(Duration(days: date.weekday % 7));
    final today     = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(children: [
        Row(
          children: List.generate(7, (i) {
            final d = weekStart.add(Duration(days: i));
            final isToday = d.year == today.year &&
                            d.month == today.month && d.day == today.day;
            final isSelected = d.year == date.year &&
                               d.month == date.month && d.day == date.day;
            final hasEvent = events.any((e) {
              final start = DateTime.parse(e['start_at']);
              return start.year == d.year && start.month == d.month &&
                     start.day == d.day;
            });
            return Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(d),
                child: Column(children: [
                  Text(DateFormat('E').format(d),
                    style: TuxieTextStyles.body(11,
                      weight: FontWeight.w700,
                      color: TuxieColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                        ? TuxieColors.tuxedo
                        : isToday ? TuxieColors.sand : Colors.transparent,
                      shape: BoxShape.circle),
                    child: Center(child: Text('${d.day}',
                      style: TuxieTextStyles.body(14,
                        weight: FontWeight.w700,
                        color: isSelected
                          ? Colors.white
                          : isToday
                            ? TuxieColors.sandDark
                            : TuxieColors.textPrimary))),
                  ),
                  const SizedBox(height: 4),
                  if (hasEvent)
                    Container(
                      width: 5, height: 5,
                      decoration: const BoxDecoration(
                        color: TuxieColors.lavenderDark,
                        shape: BoxShape.circle))
                  else
                    const SizedBox(height: 5),
                ]),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        const Divider(color: TuxieColors.border),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          final dayEvents = events.where((e) {
            final start = DateTime.parse(e['start_at']);
            return start.year == date.year && start.month == date.month &&
                   start.day == date.day;
          }).toList();

          if (dayEvents.isEmpty) {
            return _EmptyEvents(
              message: 'No events ${DateFormat('EEEE, MMM d').format(date)}');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, MMMM d').format(date),
                style: TuxieTextStyles.display(18)),
              const SizedBox(height: 12),
              ...dayEvents.map((e) => _EventTile(
                event: e, onTap: () => onEdit(e))),
            ],
          );
        }),
      ]),
    );
  }
}

// ── DAY VIEW ─────────────────────────────────────────────────────

class _DayView extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> events;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _DayView({
    required this.date, required this.events,
    required this.onDateChanged, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dayEvents = events.where((e) {
      final start = DateTime.parse(e['start_at']);
      return start.year == date.year && start.month == date.month &&
             start.day == date.day;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => onDateChanged(
                date.subtract(const Duration(days: 1)))),
            Expanded(child: Center(child: Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: TuxieTextStyles.display(20)))),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => onDateChanged(
                date.add(const Duration(days: 1)))),
          ]),
          const SizedBox(height: 16),
          if (dayEvents.isEmpty)
            _EmptyEvents()
          else
            ...dayEvents.map((e) => _EventTile(
              event: e, onTap: () => onEdit(e))),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool showDate;
  final VoidCallback? onTap;

  const _EventTile({required this.event, this.showDate = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final domain   = event['domain'] as String? ?? 'household';
    final startAt  = DateTime.parse(event['start_at']);
    final endAt    = event['end_at'] != null
      ? DateTime.parse(event['end_at']) : null;
    final isAllDay = event['is_all_day'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TuxieColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TuxieColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 4, height: 44,
            decoration: BoxDecoration(
              color: TuxieColors.domainColorDark(domain),
              borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: TuxieColors.domainColor(domain),
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              TuxieColors.domainEmoji(domain),
              style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] ?? '',
                  style: TuxieTextStyles.body(14, weight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  isAllDay
                    ? showDate
                      ? '${DateFormat('MMM d').format(startAt)} · All day'
                      : 'All day'
                    : showDate
                      ? DateFormat('MMM d · h:mm a').format(startAt)
                      : DateFormat('h:mm a').format(startAt) +
                        (endAt != null
                          ? ' – ${DateFormat('h:mm a').format(endAt)}'
                          : ''),
                  style: TuxieTextStyles.body(12,
                    color: TuxieColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TuxieColors.domainColor(domain),
              borderRadius: BorderRadius.circular(8)),
            child: Text(
              domain.replaceAll('_', ' '),
              style: TuxieTextStyles.body(10,
                weight: FontWeight.w700,
                color: TuxieColors.domainColorDark(domain))),
          ),
        ]),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final String message;
  const _EmptyEvents({this.message = 'No events scheduled'});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TuxieColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TuxieColors.border)),
      child: Column(children: [
        const Text('📅', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(message,
          style: TuxieTextStyles.display(18),
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Tap + Add event to create one.',
          style: TuxieTextStyles.body(13,
            color: TuxieColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }
}