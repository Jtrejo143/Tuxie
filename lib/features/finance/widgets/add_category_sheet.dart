// lib/features/finance/widgets/add_category_sheet.dart

import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddCategorySheet extends StatefulWidget {
  final Map<String, dynamic>? existingCategory;
  final VoidCallback onSaved;
  const AddCategorySheet({super.key, this.existingCategory, required this.onSaved});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameCtrl  = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _emoji    = '💳';
  bool _loading    = false;
  String? _error;

  final _emojis = ['💳','🛒','🏠','🚗','🍔','💊','🎮','✈️',
                   '👕','📚','🐾','⚡','📱','🎬','🏋️','🎁'];

  bool get _isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text  = widget.existingCategory!['name'] ?? '';
      _limitCtrl.text = widget.existingCategory!['monthly_limit']?.toString() ?? '';
      _emoji          = widget.existingCategory!['emoji'] ?? '💳';
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter a category name.'; });
      return;
    }
    final limit = double.tryParse(_limitCtrl.text);
    if (limit == null || limit <= 0) {
      setState(() { _error = 'Please enter a valid monthly budget.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    debugPrint('🐱 AddCategorySheet: _save started — editing=$_isEditing');
    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      final payload = {
        'name': _nameCtrl.text.trim(),
        'monthly_limit': limit,
        'emoji': _emoji,
      };

      if (_isEditing) {
        await supabase.from('budget_categories')
          .update(payload)
          .eq('id', widget.existingCategory!['id']);
        debugPrint('🐱 AddCategorySheet: update SUCCESS');
      } else {
        await supabase.from('budget_categories').insert({
          ...payload,
          'household_id': member['household_id'],
        });
        debugPrint('🐱 AddCategorySheet: insert SUCCESS');
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddCategorySheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    debugPrint('🐱 AddCategorySheet: deleting category');
    try {
      await supabase.from('budget_categories')
        .delete()
        .eq('id', widget.existingCategory!['id']);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddCategorySheet: delete FAILED — $e');
      setState(() { _error = e.toString(); });
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
            Text(_isEditing ? 'Edit Category' : 'New Category',
              style: TuxieTextStyles.display(22)),
            const SizedBox(height: 20),

            // Emoji picker
            _Label('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _emojis.map((e) => GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _emoji == e
                      ? TuxieColors.tuxedo
                      : TuxieColors.linen,
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(e,
                    style: const TextStyle(fontSize: 20)))),
              )).toList(),
            ),
            const SizedBox(height: 16),

            _Label('Category name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Groceries',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            _Label('Monthly budget (\$)'),
            const SizedBox(height: 6),
            TextField(
              controller: _limitCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 500',
                prefixText: '\$ ',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
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
                      color: TuxieColors.blushDark, size: 20))),
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
                    : Text(_isEditing ? 'Save changes' : 'Create category',
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
