// lib/features/inventory/widgets/edit_history_sheet.dart
// Edit or delete a purchase history record

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class EditHistorySheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final VoidCallback onSaved;
  const EditHistorySheet({
    super.key,
    required this.record,
    required this.onSaved,
  });

  @override
  State<EditHistorySheet> createState() => _EditHistorySheetState();
}

class _EditHistorySheetState extends State<EditHistorySheet> {
  final _notesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int      _qty     = 1;
  DateTime _date    = DateTime.now();
  bool     _loading = false;
  String?  _error;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _qty              = r['qty_purchased'] as int? ?? 1;
    _notesCtrl.text   = r['notes'] as String? ?? '';
    _priceCtrl.text   = r['price'] != null
        ? (r['price'] as num).toStringAsFixed(2) : '';
    if (r['purchased_at'] != null) {
      _date = DateTime.parse(r['purchased_at'] as String);
    }
  }

  Future<void> _save() async {
    if (_qty <= 0) {
      setState(() { _error = 'Quantity must be at least 1.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    debugPrint('🐱 EditHistorySheet: saving record id=${widget.record['id']}');

    try {
      final price = double.tryParse(_priceCtrl.text);
      await supabase.from('purchase_history').update({
        'qty_purchased': _qty,
        'purchased_at':  DateFormat('yyyy-MM-dd').format(_date),
        'price':         price,
        'notes':         _notesCtrl.text.trim().isEmpty
            ? null : _notesCtrl.text.trim(),
      }).eq('id', widget.record['id']);

      debugPrint('🐱 EditHistorySheet: update SUCCESS');
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 EditHistorySheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete() async {
    debugPrint('🐱 EditHistorySheet: deleting record id=${widget.record['id']}');
    try {
      await supabase.from('purchase_history')
          .delete()
          .eq('id', widget.record['id']);
      debugPrint('🐱 EditHistorySheet: delete SUCCESS');
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 EditHistorySheet: delete FAILED — $e');
      setState(() { _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.record['inventory_items'] as Map<String, dynamic>?;

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

            // Header
            Row(children: [
              Text(item?['emoji'] as String? ?? '📦',
                style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Edit Purchase',
                  style: TuxieTextStyles.display(22)),
                Text(item?['name'] as String? ?? 'Item',
                  style: TuxieTextStyles.body(14,
                    color: TuxieColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 24),

            // Quantity
            _Label('Quantity purchased'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: TuxieColors.linen,
                borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  color: TuxieColors.textSecondary),
                Expanded(child: Center(child: Text('$_qty',
                  style: TuxieTextStyles.body(24, weight: FontWeight.w800)))),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _qty++),
                  color: TuxieColors.textSecondary),
              ]),
            ),
            const SizedBox(height: 16),

            // Price
            _Label('Price paid'),
            const SizedBox(height: 6),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: r'$ ',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            // Date
            _Label('Date purchased'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: TuxieColors.linen,
                  borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                    color: TuxieColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Text(DateFormat('EEE, MMM d yyyy').format(_date),
                    style: TuxieTextStyles.body(14)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _Label('Notes'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText: 'Where did you buy it?',
                filled: true, fillColor: TuxieColors.linen,
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
                    color: TuxieColors.blushDark))),
            ],
            const SizedBox(height: 20),

            Row(children: [
              GestureDetector(
                onTap: _delete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush,
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline,
                    color: TuxieColors.blushDark, size: 20))),
              const SizedBox(width: 10),
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
                    : Text('Save changes',
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: TuxieTextStyles.body(13,
      weight: FontWeight.w700, color: TuxieColors.textSecondary));
}