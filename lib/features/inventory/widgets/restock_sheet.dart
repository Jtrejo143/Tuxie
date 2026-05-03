// lib/features/inventory/widgets/restock_sheet.dart
// Log a restock — updates quantity and records purchase history

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class RestockSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSaved;
  const RestockSheet({super.key, required this.item, required this.onSaved});

  @override
  State<RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends State<RestockSheet> {
  int      _qty      = 1;
  final    _priceCtrl = TextEditingController();
  final    _notesCtrl = TextEditingController();
  DateTime _date      = DateTime.now();
  bool     _loading   = false;
  String?  _error;

  Future<void> _save() async {
    if (_qty <= 0) {
      setState(() { _error = 'Quantity must be at least 1.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    debugPrint('🐱 RestockSheet: restocking item=${widget.item['name']} qty=$_qty');
    try {
      final userId     = supabase.auth.currentUser!.id;
      final currentQty = widget.item['current_qty'] as int? ?? 0;
      final newQty     = currentQty + _qty;
      final price      = double.tryParse(_priceCtrl.text);

      // Step 1 — Update current quantity
      debugPrint('🐱 RestockSheet: Step 1 — updating qty $currentQty → $newQty');
      await supabase.from('inventory_items')
        .update({'current_qty': newQty})
        .eq('id', widget.item['id']);
      debugPrint('🐱 RestockSheet: Step 1 SUCCESS');

      // Step 2 — Log purchase history
      debugPrint('🐱 RestockSheet: Step 2 — logging purchase history');
      await supabase.from('purchase_history').insert({
        'item_id':       widget.item['id'],
        'qty_purchased': _qty,
        'purchased_at':  DateFormat('yyyy-MM-dd').format(_date),
        'purchased_by':  userId,
        'price':         price,
        'notes':         _notesCtrl.text.trim().isEmpty
          ? null : _notesCtrl.text.trim(),
      });
      debugPrint('🐱 RestockSheet: Step 2 SUCCESS');

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 RestockSheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQty = widget.item['current_qty'] as int? ?? 0;
    final unit       = widget.item['unit'] as String? ?? '';

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

            // Item header
            Row(children: [
              Text(widget.item['emoji'] as String? ?? '📦',
                style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Restock',
                  style: TuxieTextStyles.display(22)),
                Text(widget.item['name'] as String,
                  style: TuxieTextStyles.body(14,
                    color: TuxieColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 8),

            // Current qty info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TuxieColors.linen,
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.inventory_2_outlined,
                  color: TuxieColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Current stock: $currentQty'
                  '${unit.isNotEmpty ? ' $unit' : ''}',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w600,
                    color: TuxieColors.textSecondary)),
                const Spacer(),
                Text('→ ${currentQty + _qty}'
                  '${unit.isNotEmpty ? ' $unit' : ''}',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w800,
                    color: TuxieColors.sageDark)),
              ]),
            ),
            const SizedBox(height: 20),

            // Qty to add
            _Label('Quantity added'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: TuxieColors.linen,
                borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _qty > 1
                    ? () => setState(() => _qty--)
                    : null,
                  color: TuxieColors.textSecondary),
                Expanded(child: Center(child: Text('$_qty',
                  style: TuxieTextStyles.body(24,
                    weight: FontWeight.w800)))),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _qty++),
                  color: TuxieColors.textSecondary),
              ]),
            ),
            const SizedBox(height: 16),

            // Price paid (optional)
            _Label('Price paid (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Total amount spent',
                prefixText: '\$ ',
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
            _Label('Notes (optional)'),
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
                  : Text('Log restock',
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
