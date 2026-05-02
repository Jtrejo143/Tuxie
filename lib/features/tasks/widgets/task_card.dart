// lib/features/tasks/widgets/task_card.dart
// Reusable task card widget used on Tasks screen and Home screen

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tuxie_theme.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final domain   = task['domain'] as String? ?? 'household';
    final priority = task['priority'] as String? ?? 'medium';
    final dueDate  = task['due_date'] as String?;
    final assignee = task['profiles'] as Map<String, dynamic>?;
    final recurrence = task['recurrence'] as String? ?? 'none';
    final isOverdue = dueDate != null &&
      DateTime.parse(dueDate).isBefore(DateTime.now()) &&
      !DateTime.parse(dueDate).isAtSameMomentAs(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    final priorityColors = {
      'high':   TuxieColors.priorityHigh,
      'medium': TuxieColors.priorityMedium,
      'low':    TuxieColors.priorityLow,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TuxieColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOverdue
              ? TuxieColors.blushDark.withValues(alpha: 0.4)
              : TuxieColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Complete button
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: priorityColors[priority] ?? TuxieColors.textMuted,
                    width: 2),
                  color: Colors.transparent,
                ),
                child: const Icon(Icons.check,
                  size: 14, color: Colors.transparent),
              ),
            ),
            const SizedBox(width: 12),

            // Domain icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: TuxieColors.domainColor(domain),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(
                TuxieColors.domainEmoji(domain),
                style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['title'] ?? '',
                    style: TuxieTextStyles.body(14, weight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Priority dot
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: priorityColors[priority],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(priority,
                            style: TuxieTextStyles.body(11,
                              color: TuxieColors.textMuted)),
                        ],
                      ),
                      // Due date
                      if (dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue
                              ? TuxieColors.blush
                              : TuxieColors.linen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(dueDate),
                            style: TuxieTextStyles.body(11,
                              weight: FontWeight.w700,
                              color: isOverdue
                                ? TuxieColors.blushDark
                                : TuxieColors.textSecondary)),
                        ),
                      // Recurring badge
                      if (recurrence != 'none')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: TuxieColors.lavender,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('↻ $recurrence',
                            style: TuxieTextStyles.body(10,
                              weight: FontWeight.w700,
                              color: TuxieColors.lavenderDark)),
                        ),
                      // Assignee
                      if (assignee != null)
                        Text(assignee['display_name'] ?? '',
                          style: TuxieTextStyles.body(11,
                            color: TuxieColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
              color: TuxieColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final diff = taskDate.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < -1) return '${diff.abs()}d overdue';
    if (diff < 7) return 'In ${diff}d';
    return DateFormat('MMM d').format(date);
  }
}
