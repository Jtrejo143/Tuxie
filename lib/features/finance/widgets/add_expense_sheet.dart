// lib/features/finance/widgets/add_expense_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddExpenseSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const AddExpenseSheet({super.key, required this.onSaved});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  String? _categoryId;
  DateTime _date    = DateTime.now();
  bool _loading     = false;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    debugPrint('🐱 AddExpenseSheet: loading categories');
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
      setState(() {
        _categories = List<Map<String, dynamic>>.from(cats);
        if (_categories.isNotEmpty) _categoryId = _categories.first['id'];
      });
      debugPrint('🐱 AddExpenseSheet: loaded ${_categories.length} categories');
    } catch (e) {
      debugPrint('🐱 AddExpenseSheet: load categories FAILED — $e');
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() { _error = 'Please enter a valid amount.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    debugPrint('🐱 AddExpenseSheet: saving expense amount=$amount');

    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      await supabase.from('expenses').insert({
        'household_id': member['household_id'],
        'category_id':  _categoryId,
        'amount':        amount,
        'description':   _descCtrl.text.trim().isEmpty
          ? null : _descCtrl.text.trim(),
        'date':          DateFormat('yyyy-MM-dd').format(_date),
        'logged_by':     userId,
      });
      debugPrint('🐱 AddExpenseSheet: insert SUCCESS');
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddExpenseSheet: FAILED — $e');
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
            Text('Log Expense', style: TuxieTextStyles.display(22)),
            const SizedBox(height: 20),

            // Amount
            _Label('Amount'),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Category
            if (_categories.isNotEmpty) ...[
              _Label('Category'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _categoryId == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _categoryId = cat['id']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                            ? TuxieColors.tuxedo
                            : TuxieColors.linen,
                          borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat['emoji'] as String? ?? '💳',
                              style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(cat['name'] as String,
                              style: TuxieTextStyles.body(13,
                                weight: FontWeight.w700,
                                color: isSelected
                                  ? Colors.white
                                  : TuxieColors.textPrimary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            _Label('Description (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: 'What was this for?',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(14),
            ),
            const SizedBox(height: 16),

            // Date
            _Label('Date'),
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
                  : Text('Log expense',
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
