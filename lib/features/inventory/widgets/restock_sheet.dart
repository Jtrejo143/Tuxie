// lib/features/inventory/widgets/restock_sheet.dart

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
  int      _qty        = 1;
  final    _priceCtrl  = TextEditingController();
  final    _notesCtrl  = TextEditingController();
  DateTime _date       = DateTime.now();
  bool     _loading    = false;
  bool     _logExpense = false;
  String?  _categoryId;
  String?  _error;

  // Loaded async — starts empty, populated in initState
  List<Map<String, dynamic>> _categories = [];
  bool _catsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    debugPrint('🐱 RestockSheet: loading categories');
    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
          .from('household_members')
          .select('household_id')
          .eq('profile_id', userId)
          .single();
      final cats = await supabase
          .from('budget_categories')
          .select('*')
          .eq('household_id', member['household_id'])
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _categories  = List<Map<String, dynamic>>.from(cats);
          _catsLoading = false;
        });
        debugPrint('🐱 RestockSheet: loaded ${_categories.length} categories');
      }
    } catch (e) {
      debugPrint('🐱 RestockSheet: load categories FAILED — $e');
      if (mounted) setState(() { _catsLoading = false; });
    }
  }

  Future<void> _save() async {
    if (_qty <= 0) {
      setState(() { _error = 'Quantity must be at least 1.'; });
      return;
    }
    if (_logExpense && _categoryId == null) {
      setState(() { _error = 'Please select a budget category for the expense.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    debugPrint('🐱 RestockSheet: Step 1 — updating qty');
    try {
      final userId     = supabase.auth.currentUser!.id;
      final currentQty = widget.item['current_qty'] as int? ?? 0;
      final newQty     = currentQty + _qty;
      final price      = double.tryParse(_priceCtrl.text);

      // Step 1 — Update quantity
      await supabase.from('inventory_items')
          .update({'current_qty': newQty})
          .eq('id', widget.item['id']);
      debugPrint('🐱 RestockSheet: Step 1 SUCCESS — $currentQty → $newQty');

      // Step 2 — Log purchase history
      debugPrint('🐱 RestockSheet: Step 2 — logging history');
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

      // Step 3 — Optionally log as expense
      // price can be null — we use 0 as fallback so the expense still logs
      if (_logExpense && _categoryId != null) {
        final expenseAmount = price ?? 0.0;
        debugPrint('🐱 RestockSheet: Step 3 — logging expense amount=$expenseAmount category=$_categoryId');
        final member = await supabase
            .from('household_members')
            .select('household_id')
            .eq('profile_id', userId)
            .single();
        await supabase.from('expenses').insert({
          'household_id': member['household_id'],
          'category_id':  _categoryId,
          'amount':        expenseAmount,
          'description':   'Restock: ${widget.item['name']}',
          'date':          DateFormat('yyyy-MM-dd').format(_date),
          'logged_by':     userId,
        });
        debugPrint('🐱 RestockSheet: Step 3 SUCCESS');
      }

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

            // Header
            Row(children: [
              Text(widget.item['emoji'] as String? ?? '📦',
                style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Restock', style: TuxieTextStyles.display(22)),
                Text(widget.item['name'] as String,
                  style: TuxieTextStyles.body(14,
                    color: TuxieColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 16),

            // Current stock info
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
                  'Current: $currentQty${unit.isNotEmpty ? " $unit" : ""}',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w600,
                    color: TuxieColors.textSecondary)),
                const Spacer(),
                Text(
                  '→ ${currentQty + _qty}${unit.isNotEmpty ? " $unit" : ""}',
                  style: TuxieTextStyles.body(13,
                    weight: FontWeight.w800,
                    color: TuxieColors.sageDark)),
              ]),
            ),
            const SizedBox(height: 20),

            // Quantity
            _Label('Quantity to add'),
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
            _Label('Price paid (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Amount spent (used for expense if logging)',
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
            const SizedBox(height: 16),

            // Log as expense toggle
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log as expense',
                    style: TuxieTextStyles.body(14, weight: FontWeight.w700)),
                  Text('Add to budget tracking',
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textSecondary)),
                ],
              )),
              Switch(
                value: _logExpense,
                onChanged: (v) => setState(() => _logExpense = v),
                activeThumbColor: TuxieColors.tuxedo),
            ]),

            // Category picker — shown when toggle is on
            if (_logExpense) ...[
              const SizedBox(height: 12),
              _catsLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator()))
                : _categories.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TuxieColors.sand,
                        borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'No budget categories yet. Add one in Finances first.',
                        style: TuxieTextStyles.body(13,
                          color: TuxieColors.sandDark)))
                  : DropdownButtonFormField<String?>(
                      initialValue: _categoryId,
                      hint: const Text('Select budget category'),
                      decoration: InputDecoration(
                        filled: true, fillColor: TuxieColors.linen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14)),
                      items: _categories.map((cat) => DropdownMenuItem<String?>(
                        value: cat['id'] as String,
                        child: Row(children: [
                          Text(cat['emoji'] as String? ?? '💳',
                            style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(cat['name'] as String,
                            style: TuxieTextStyles.body(14)),
                        ]),
                      )).toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
            ],

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
                  : const Text('Log restock',
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
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