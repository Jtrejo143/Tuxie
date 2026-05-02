// lib/features/calendar/widgets/add_event_sheet.dart
// Bottom sheet for creating calendar events

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddEventSheet extends StatefulWidget {
  final DateTime initialDate;
  final VoidCallback onSaved;
  final Map<String, dynamic>? existingEvent;

  const AddEventSheet({
    super.key,
    required this.initialDate,
    required this.onSaved,
    this.existingEvent,
  });

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();

  String    _domain   = 'household';
  bool      _isAllDay = false;
  bool      _loading  = false;
  String?   _error;
  DateTime? _startDate;
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay _endTime   = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute);

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
    _endDate   = widget.initialDate;
    if (_isEditing) _populateExisting();
  }

  void _populateExisting() {
    final e = widget.existingEvent!;
    _titleCtrl.text    = e['title'] ?? '';
    _notesCtrl.text    = e['notes'] ?? '';
    _locationCtrl.text = e['location'] ?? '';
    _domain    = e['domain'] ?? 'household';
    _isAllDay  = e['is_all_day'] ?? false;

    if (e['start_at'] != null) {
      final start = DateTime.parse(e['start_at']);
      _startDate = start;
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    }
    if (e['end_at'] != null) {
      final end = DateTime.parse(e['end_at']);
      _endDate = end;
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter an event title.'; });
      return;
    }
    if (_startDate == null) {
      setState(() { _error = 'Please select a start date.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    debugPrint('🐱 AddEventSheet: _save started — editing=$_isEditing');

    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      // Build start datetime
      DateTime startAt;
      DateTime? endAt;

      if (_isAllDay) {
        // All day — use midnight start, no time component
        // End date defaults to same day if not explicitly set differently
        startAt = DateTime.utc(_startDate!.year, _startDate!.month,
          _startDate!.day, 0, 0, 0);
        final effectiveEnd = _endDate ?? _startDate!;
        endAt = DateTime.utc(effectiveEnd.year, effectiveEnd.month,
          effectiveEnd.day, 23, 59, 59);
        debugPrint('🐱 AddEventSheet: all-day event ${startAt.toIso8601String()} → ${endAt.toIso8601String()}');
      } else {
        startAt = DateTime(_startDate!.year, _startDate!.month,
          _startDate!.day, _startTime.hour, _startTime.minute);
        if (_endDate != null) {
          endAt = DateTime(_endDate!.year, _endDate!.month,
            _endDate!.day, _endTime.hour, _endTime.minute);
          // Guard: end must be after start
          if (endAt.isBefore(startAt)) {
            endAt = startAt.add(const Duration(hours: 1));
            debugPrint('🐱 AddEventSheet: end before start — adjusted to +1hr');
          }
        }
      }

      final payload = {
        'title':    _titleCtrl.text.trim(),
        'notes':    _notesCtrl.text.trim().isEmpty
          ? null : _notesCtrl.text.trim(),
        'location': _locationCtrl.text.trim().isEmpty
          ? null : _locationCtrl.text.trim(),
        'domain':   _domain,
        'start_at': startAt.toIso8601String(),
        'end_at':   endAt?.toIso8601String(),
        'is_all_day': _isAllDay,
      };

      if (_isEditing) {
        debugPrint('🐱 AddEventSheet: updating event id=${widget.existingEvent!['id']}');
        await supabase.from('events')
          .update(payload)
          .eq('id', widget.existingEvent!['id']);
        debugPrint('🐱 AddEventSheet: update SUCCESS');
      } else {
        debugPrint('🐱 AddEventSheet: inserting new event');
        await supabase.from('events').insert({
          ...payload,
          'household_id': member['household_id'],
          'created_by': userId,
        });
        debugPrint('🐱 AddEventSheet: insert SUCCESS');
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddEventSheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    debugPrint('🐱 AddEventSheet: deleting event');
    try {
      await supabase.from('events')
        .delete()
        .eq('id', widget.existingEvent!['id']);
      debugPrint('🐱 AddEventSheet: delete SUCCESS');
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddEventSheet: delete FAILED — $e');
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
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TuxieColors.border,
                borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),

            Text(_isEditing ? 'Edit Event' : 'New Event',
              style: TuxieTextStyles.display(22)),
            const SizedBox(height: 20),

            // Title
            _Label('Event title'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEditing,
              decoration: InputDecoration(
                hintText: 'What\'s happening?',
                filled: true,
                fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            // Domain
            _Label('Domain'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['household','goals','finance',
                           'health','social','work_commitments']
                  .map((d) {
                    final isSelected = _domain == d;
                    return GestureDetector(
                      onTap: () => setState(() => _domain = d),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                            ? TuxieColors.domainColor(d)
                            : TuxieColors.linen,
                          borderRadius: BorderRadius.circular(20)),
                        child: Text(_domainLabel(d),
                          style: TuxieTextStyles.body(12,
                            weight: FontWeight.w700,
                            color: isSelected
                              ? TuxieColors.domainColorDark(d)
                              : TuxieColors.textMuted)),
                      ),
                    );
                  }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // All day toggle
            Row(children: [
              Expanded(child: Text('All day event',
                style: TuxieTextStyles.body(14,
                  weight: FontWeight.w700))),
              Switch(
                value: _isAllDay,
                onChanged: (v) => setState(() => _isAllDay = v),
                activeThumbColor: TuxieColors.tuxedo,
              ),
            ]),
            const SizedBox(height: 8),

            // Start date/time
            _Label('Start'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _DateButton(
                label: _startDate != null
                  ? DateFormat('EEE, MMM d').format(_startDate!)
                  : 'Select date',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      if (_endDate == null ||
                          _endDate!.isBefore(picked)) {
                        _endDate = picked;
                      }
                    });
                  }
                },
              )),
              if (!_isAllDay) ...[
                const SizedBox(width: 10),
                _DateButton(
                  label: _startTime.format(context),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (picked != null) {
                      setState(() => _startTime = picked);
                    }
                  },
                ),
              ],
            ]),
            const SizedBox(height: 12),

            // End date/time
            _Label('End'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _DateButton(
                label: _endDate != null
                  ? DateFormat('EEE, MMM d').format(_endDate!)
                  : 'Select date',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              )),
              if (!_isAllDay) ...[
                const SizedBox(width: 10),
                _DateButton(
                  label: _endTime.format(context),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (picked != null) {
                      setState(() => _endTime = picked);
                    }
                  },
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // Location
            _Label('Location (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: 'Where is this?',
                filled: true,
                fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(14),
            ),
            const SizedBox(height: 16),

            // Notes
            _Label('Notes (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Any details...',
                filled: true,
                fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(14),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuxieColors.blush,
                  borderRadius: BorderRadius.circular(12)),
                child: Text(_error!,
                  style: TuxieTextStyles.body(13,
                    color: TuxieColors.blushDark)),
              ),
            ],

            const SizedBox(height: 20),

            // Buttons
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
                      borderRadius: BorderRadius.circular(16))),
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Save changes' : 'Create event',
                        style: TuxieTextStyles.body(16,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────

String _domainLabel(String domain) {
  const labels = {
    'household': 'Home', 'goals': 'Goals',
    'finance': 'Finance', 'health': 'Health',
    'social': 'Social', 'work_commitments': 'Work',
  };
  return labels[domain] ?? domain;
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: TuxieTextStyles.body(13,
      weight: FontWeight.w700,
      color: TuxieColors.textSecondary));
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TuxieColors.linen,
          borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
              size: 16, color: TuxieColors.textSecondary),
            const SizedBox(width: 8),
            Text(label,
              style: TuxieTextStyles.body(13,
                color: TuxieColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}