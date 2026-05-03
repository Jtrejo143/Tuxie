// lib/features/inventory/widgets/add_item_sheet.dart

import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddItemSheet extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final VoidCallback onSaved;
  const AddItemSheet({super.key, this.existingItem, required this.onSaved});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameCtrl  = TextEditingController();
  final _unitCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _emoji    = '📦';
  String _category = 'General';
  int    _currentQty = 0;
  int    _minQty     = 1;
  bool   _loading    = false;
  String? _error;

  bool get _isEditing => widget.existingItem != null;

  final _emojis = [
    '📦','🧴','🧻','🧼','🌿','💊','☕','🍝','🥫','🧃',
    '🐾','🔧','💡','🧹','🧺','🛒','🥩','🍞','🧀','🥚',
  ];

  final _categories = [
    'Cleaning','Pantry','Health','Pets',
    'Bathroom','Kitchen','Laundry','General',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.existingItem!;
      _nameCtrl.text  = item['name'] ?? '';
      _unitCtrl.text  = item['unit'] ?? '';
      _notesCtrl.text = item['notes'] ?? '';
      _emoji      = item['emoji'] ?? '📦';
      _category   = item['category'] ?? 'General';
      _currentQty = item['current_qty'] as int? ?? 0;
      _minQty     = item['min_qty'] as int? ?? 1;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please enter an item name.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    debugPrint('🐱 AddItemSheet: saving item name=${_nameCtrl.text}');

    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      final payload = {
        'name':        _nameCtrl.text.trim(),
        'emoji':       _emoji,
        'category':    _category,
        'current_qty': _currentQty,
        'min_qty':     _minQty,
        'unit':        _unitCtrl.text.trim().isEmpty
          ? null : _unitCtrl.text.trim(),
        'notes':       _notesCtrl.text.trim().isEmpty
          ? null : _notesCtrl.text.trim(),
      };

      if (_isEditing) {
        await supabase.from('inventory_items')
          .update(payload)
          .eq('id', widget.existingItem!['id']);
        debugPrint('🐱 AddItemSheet: update SUCCESS');
      } else {
        await supabase.from('inventory_items').insert({
          ...payload,
          'household_id': member['household_id'],
        });
        debugPrint('🐱 AddItemSheet: insert SUCCESS');
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddItemSheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    debugPrint('🐱 AddItemSheet: deleting item');
    try {
      await supabase.from('inventory_items')
        .delete()
        .eq('id', widget.existingItem!['id']);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddItemSheet: delete FAILED — $e');
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
            Text(_isEditing ? 'Edit Item' : 'New Item',
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
                      ? TuxieColors.tuxedo : TuxieColors.linen,
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(e,
                    style: const TextStyle(fontSize: 20)))),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Name
            _Label('Item name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: !_isEditing,
              decoration: InputDecoration(
                hintText: 'e.g. Dish Soap',
                filled: true, fillColor: TuxieColors.linen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)),
              style: TuxieTextStyles.body(15),
            ),
            const SizedBox(height: 16),

            // Category
            _Label('Category'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? TuxieColors.tuxedo : TuxieColors.linen,
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(cat,
                        style: TuxieTextStyles.body(12,
                          weight: FontWeight.w700,
                          color: isSelected
                            ? Colors.white : TuxieColors.textMuted)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Quantities
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Current qty'),
                  const SizedBox(height: 8),
                  _QtyField(
                    value: _currentQty,
                    onChanged: (v) => setState(() => _currentQty = v),
                  ),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Min qty (alert below)'),
                  const SizedBox(height: 8),
                  _QtyField(
                    value: _minQty,
                    onChanged: (v) => setState(() => _minQty = v),
                    min: 0,
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 16),

            // Unit
            _Label('Unit (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _unitCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. rolls, bottles, kg',
                filled: true, fillColor: TuxieColors.linen,
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
              decoration: InputDecoration(
                hintText: 'Brand preference, where to buy, etc.',
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
                    : Text(_isEditing ? 'Save changes' : 'Add item',
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

class _QtyField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  const _QtyField({required this.value, required this.onChanged, this.min = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TuxieColors.linen,
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          color: TuxieColors.textSecondary),
        Expanded(child: Center(child: Text('$value',
          style: TuxieTextStyles.body(18, weight: FontWeight.w800)))),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => onChanged(value + 1),
          color: TuxieColors.textSecondary),
      ]),
    );
  }
}
