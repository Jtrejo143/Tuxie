// lib/features/tasks/widgets/add_task_sheet.dart
// Bottom sheet for creating and editing tasks

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final Map<String, dynamic>? existingTask;
  final VoidCallback onSaved;

  const AddTaskSheet({super.key, this.existingTask, required this.onSaved});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _domain     = 'household';
  String _priority   = 'medium';
  String _recurrence = 'none';
  DateTime? _dueDate;
  String? _assignedTo;
  bool _isPrivate = false;
  bool _loading   = false;
  String? _error;

  // Household members for assignee picker
  List<Map<String, dynamic>> _members = [];
  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    if (_isEditing) _populateExisting();
  }

  void _populateExisting() {
    final t = widget.existingTask!;
    _titleCtrl.text  = t['title'] ?? '';
    _notesCtrl.text  = t['notes'] ?? '';
    _domain      = t['domain'] ?? 'household';
    _priority    = t['priority'] ?? 'medium';
    _recurrence  = t['recurrence'] ?? 'none';
    _isPrivate   = t['is_private'] ?? false;
    _assignedTo  = t['assigned_to'];
    if (t['due_date'] != null) {
      _dueDate = DateTime.parse(t['due_date']);
    }
  }

  Future<void> _loadMembers() async {
    debugPrint('🐱 AddTaskSheet: loading household members');
    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      final members = await supabase
        .from('household_members')
        .select('profile_id, profiles(display_name)')
        .eq('household_id', member['household_id']);

      setState(() {
        _members = List<Map<String, dynamic>>.from(members);
      });
      debugPrint('🐱 AddTaskSheet: loaded ${_members.length} members');
    } catch (e) {
      debugPrint('🐱 AddTaskSheet: failed to load members — $e');
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter a task title.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    debugPrint('🐱 AddTaskSheet: _save started — editing=$_isEditing');

    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      final payload = {
        'title': _titleCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'domain': _domain,
        'priority': _priority,
        'recurrence': _recurrence,
        'is_private': _isPrivate,
        'assigned_to': _assignedTo,
        'due_date': _dueDate != null
          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
          : null,
      };

      if (_isEditing) {
        debugPrint('🐱 AddTaskSheet: updating task id=${widget.existingTask!['id']}');
        await supabase.from('tasks')
          .update(payload)
          .eq('id', widget.existingTask!['id']);
        debugPrint('🐱 AddTaskSheet: update SUCCESS');
      } else {
        debugPrint('🐱 AddTaskSheet: inserting new task');
        await supabase.from('tasks').insert({
          ...payload,
          'household_id': member['household_id'],
          'created_by': userId,
        });
        debugPrint('🐱 AddTaskSheet: insert SUCCESS');
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddTaskSheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    debugPrint('🐱 AddTaskSheet: deleting task id=${widget.existingTask!['id']}');
    try {
      await supabase.from('tasks')
        .delete()
        .eq('id', widget.existingTask!['id']);
      debugPrint('🐱 AddTaskSheet: delete SUCCESS');
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddTaskSheet: delete FAILED — $e');
      setState(() { _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TuxieColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TuxieColors.border,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(_isEditing ? 'Edit Task' : 'New Task',
              style: TuxieTextStyles.display(22)),
            const SizedBox(height: 20),

            // Task title field
            _Label('Task'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEditing,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                filled: true,
                fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              ),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            // Notes field
            _Label('Notes (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Any extra details...',
                filled: true,
                fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              ),
              style: TuxieTextStyles.body(14),
            ),
            const SizedBox(height: 16),

            // Domain picker
            _Label('Domain'),
            const SizedBox(height: 8),
            _SegmentRow(
              options: ['household', 'goals', 'finance',
                        'health', 'social', 'work_commitments'],
              labels:  ['Home', 'Goals', 'Finance',
                        'Health', 'Social', 'Work'],
              selected: _domain,
              onSelect: (v) => setState(() => _domain = v),
              colorOf: (v) => TuxieColors.domainColor(v),
            ),
            const SizedBox(height: 16),

            // Priority picker
            _Label('Priority'),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final colors = {
                  'low': TuxieColors.sage,
                  'medium': TuxieColors.sand,
                  'high': TuxieColors.blush,
                };
                final textColors = {
                  'low': TuxieColors.sageDark,
                  'medium': TuxieColors.sandDark,
                  'high': TuxieColors.blushDark,
                };
                final selected = _priority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? colors[p] : TuxieColors.linen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(
                        p[0].toUpperCase() + p.substring(1),
                        style: TuxieTextStyles.body(13,
                          weight: FontWeight.w700,
                          color: selected
                            ? textColors[p]!
                            : TuxieColors.textMuted))),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Due date picker
            _Label('Due date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: TuxieColors.linen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                      color: TuxieColors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                        ? DateFormat('EEE, MMM d yyyy').format(_dueDate!)
                        : 'No due date',
                      style: TuxieTextStyles.body(14,
                        color: _dueDate != null
                          ? TuxieColors.textPrimary
                          : TuxieColors.textMuted)),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close,
                          color: TuxieColors.textMuted, size: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recurrence
            _Label('Repeats'),
            const SizedBox(height: 8),
            _SegmentRow(
              options: ['none', 'daily', 'weekly', 'biweekly', 'monthly'],
              labels:  ['Never', 'Daily', 'Weekly', 'Every 2w', 'Monthly'],
              selected: _recurrence,
              onSelect: (v) => setState(() => _recurrence = v),
              colorOf: (_) => TuxieColors.lavender,
            ),
            const SizedBox(height: 16),

            // Assignee
            if (_members.isNotEmpty) ...[
              _Label('Assigned to'),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Shared option
                  _AssigneeChip(
                    label: 'Shared',
                    selected: _assignedTo == null,
                    onTap: () => setState(() => _assignedTo = null),
                  ),
                  const SizedBox(width: 8),
                  ..._members.map((m) {
                    final profile = m['profiles'] as Map<String, dynamic>?;
                    final name = profile?['display_name'] as String? ?? '?';
                    final id   = m['profile_id'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _AssigneeChip(
                        label: name.split(' ').first,
                        selected: _assignedTo == id,
                        onTap: () => setState(() => _assignedTo = id),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Private toggle
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Private task',
                      style: TuxieTextStyles.body(14, weight: FontWeight.w700)),
                    Text('Only visible to you',
                      style: TuxieTextStyles.body(12,
                        color: TuxieColors.textSecondary)),
                  ],
                )),
                Switch(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                  activeColor: TuxieColors.tuxedo,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuxieColors.blush,
                  borderRadius: BorderRadius.circular(12)),
                child: Text(_error!,
                  style: TuxieTextStyles.body(13,
                    color: TuxieColors.blushDark)),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(children: [
              if (_isEditing) ...[
                GestureDetector(
                  onTap: _delete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: TuxieColors.blush,
                      borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline,
                      color: TuxieColors.blushDark, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Save changes' : 'Create task',
                        style: TuxieTextStyles.body(16,
                          weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: TuxieTextStyles.body(13,
      weight: FontWeight.w700, color: TuxieColors.textSecondary));
}

class _SegmentRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;
  final Color Function(String) colorOf;

  const _SegmentRow({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.colorOf,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = selected == options[i];
          return GestureDetector(
            onTap: () => onSelect(options[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorOf(options[i]) : TuxieColors.linen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(labels[i],
                style: TuxieTextStyles.body(12,
                  weight: FontWeight.w700,
                  color: isSelected
                    ? TuxieColors.textPrimary
                    : TuxieColors.textMuted)),
            ),
          );
        }),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AssigneeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TuxieColors.tuxedo : TuxieColors.linen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TuxieTextStyles.body(13,
            weight: FontWeight.w700,
            color: selected ? Colors.white : TuxieColors.textMuted)),
      ),
    );
  }
}
