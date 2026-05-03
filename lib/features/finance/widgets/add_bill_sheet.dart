// lib/features/finance/widgets/add_bill_sheet.dart

import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddBillSheet extends StatefulWidget {
  final Map<String, dynamic>? existingBill;
  final VoidCallback onSaved;
  const AddBillSheet({super.key, this.existingBill, required this.onSaved});

  @override
  State<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<AddBillSheet> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  int  _dueDay      = 1;
  bool _isAutopay   = false;
  bool _loading     = false;
  String? _error;

  bool get _isEditing => widget.existingBill != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text   = widget.existingBill!['name'] ?? '';
      _amountCtrl.text = widget.existingBill!['amount']?.toString() ?? '';
      _dueDay          = widget.existingBill!['due_day'] as int? ?? 1;
      _isAutopay       = widget.existingBill!['is_autopay'] as bool? ?? false;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter a bill name.'; });
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() { _error = 'Please enter a valid amount.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    debugPrint('🐱 AddBillSheet: saving bill name=${_nameCtrl.text}');

    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      final payload = {
        'name':       _nameCtrl.text.trim(),
        'amount':     amount,
        'due_day':    _dueDay,
        'is_autopay': _isAutopay,
      };

      if (_isEditing) {
        await supabase.from('bills')
          .update(payload)
          .eq('id', widget.existingBill!['id']);
        debugPrint('🐱 AddBillSheet: update SUCCESS');
      } else {
        await supabase.from('bills').insert({
          ...payload,
          'household_id': member['household_id'],
          'is_recurring': true,
        });
        debugPrint('🐱 AddBillSheet: insert SUCCESS');
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddBillSheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TuxieColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TuxieColors.border,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(_isEditing ? 'Edit Bill' : 'New Bill',
              style: TuxieTextStyles.display(22)),
            const SizedBox(height: 20),

            _Label('Bill name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: !_isEditing,
              decoration: InputDecoration(
                hintText: 'e.g. Internet, Rent, Netflix',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            _Label('Monthly amount (\$)'),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            _Label('Due day of month'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Slider(
                  value: _dueDay.toDouble(),
                  min: 1, max: 31,
                  divisions: 30,
                  activeColor: TuxieColors.tuxedo,
                  label: 'Day $_dueDay',
                  onChanged: (v) => setState(() => _dueDay = v.round()),
                ),
              ),
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: TuxieColors.linen,
                  borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('$_dueDay',
                  style: TuxieTextStyles.body(16,
                    weight: FontWeight.w800))),
              ),
            ]),
            const SizedBox(height: 8),

            // Autopay toggle
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Autopay',
                    style: TuxieTextStyles.body(14,
                      weight: FontWeight.w700)),
                  Text('Mark as automatically paid each month',
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textSecondary)),
                ],
              )),
              Switch(
                value: _isAutopay,
                onChanged: (v) => setState(() => _isAutopay = v),
                activeThumbColor: TuxieColors.tuxedo,
              ),
            ]),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuxieColors.blush,
                  borderRadius: BorderRadius.circular(12)),
                child: Text(_error!,
                  style: TuxieTextStyles.body(13,
                    color: TuxieColors.blushDark))),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
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
                  : Text(_isEditing ? 'Save changes' : 'Add bill',
                      style: TuxieTextStyles.body(16,
                        weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: TuxieTextStyles.body(13,
      weight: FontWeight.w700, color: TuxieColors.textSecondary));
}
