// lib/features/brain/widgets/add_capture_sheet.dart
// Quick capture sheet — text notes and links with optional tags

import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class AddCaptureSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final String? initialType;
  const AddCaptureSheet({super.key, required this.onSaved, this.initialType});

  @override
  State<AddCaptureSheet> createState() => _AddCaptureSheetState();
}

class _AddCaptureSheetState extends State<AddCaptureSheet> {
  final _contentCtrl = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _tagCtrl     = TextEditingController();

  String _type      = 'text';
  bool   _isPrivate = false;
  bool   _loading   = false;
  String? _error;
  // ignore: prefer_final_fields
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'text';
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim()
      .toLowerCase()
      .replaceAll(' ', '-')
      .replaceAll('#', '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    final url     = _urlCtrl.text.trim();

    if (content.isEmpty && url.isEmpty) {
      setState(() { _error = 'Please enter some content or a URL.'; });
      return;
    }
    if (_type == 'link' && url.isEmpty) {
      setState(() { _error = 'Please enter a URL for a link capture.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    debugPrint('🐱 AddCaptureSheet: saving type=$_type');
    try {
      final userId = supabase.auth.currentUser!.id;
      final member = await supabase
        .from('household_members')
        .select('household_id')
        .eq('profile_id', userId)
        .single();

      // Normalize URL
      String? finalUrl;
      if (url.isNotEmpty) {
        finalUrl = url.startsWith('http') ? url : 'https://$url';
      }

      await supabase.from('brain_captures').insert({
        'household_id': member['household_id'],
        'profile_id':   userId,
        'capture_type': _type,
        'content':      content.isEmpty ? null : content,
        'url':          finalUrl,
        'tags':         _tags,
        'is_private':   _isPrivate,
      });

      debugPrint('🐱 AddCaptureSheet: insert SUCCESS');
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 AddCaptureSheet: FAILED — $e');
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

            // Type selector
            Row(children: [
              Text('Capture', style: TuxieTextStyles.display(22)),
              const Spacer(),
              // Type toggle
              Container(
                decoration: BoxDecoration(
                  color: TuxieColors.linen,
                  borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeToggle(emoji: '📝', type: 'text',
                      selected: _type == 'text',
                      onTap: () => setState(() => _type = 'text')),
                    _TypeToggle(emoji: '🔗', type: 'link',
                      selected: _type == 'link',
                      onTap: () => setState(() => _type = 'link')),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Content field
            if (_type == 'text') ...[
              _Label('Note'),
              const SizedBox(height: 6),
              TextField(
                controller: _contentCtrl,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  filled: true, fillColor: TuxieColors.linen,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none)),
                style: TuxieTextStyles.body(15),
              ),
            ],

            if (_type == 'link') ...[
              _Label('URL'),
              const SizedBox(height: 6),
              TextField(
                controller: _urlCtrl,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.link,
                    color: TuxieColors.textSecondary, size: 18),
                  filled: true, fillColor: TuxieColors.linen,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none)),
                style: TuxieTextStyles.body(15),
              ),
              const SizedBox(height: 12),
              _Label('Notes (optional)'),
              const SizedBox(height: 6),
              TextField(
                controller: _contentCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Why are you saving this?',
                  filled: true, fillColor: TuxieColors.linen,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none)),
                style: TuxieTextStyles.body(14),
              ),
            ],

            const SizedBox(height: 16),

            // Tags
            _Label('Tags'),
            const SizedBox(height: 8),

            // Existing tags
            if (_tags.isNotEmpty) ...[
              Wrap(spacing: 6, runSpacing: 6, children: _tags.map((tag) =>
                GestureDetector(
                  onTap: () => setState(() => _tags.remove(tag)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TuxieColors.lavender,
                      borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$tag',
                          style: TuxieTextStyles.body(12,
                            weight: FontWeight.w700,
                            color: TuxieColors.lavenderDark)),
                        const SizedBox(width: 4),
                        const Icon(Icons.close,
                          size: 12, color: TuxieColors.lavenderDark),
                      ],
                    ),
                  ),
                )
              ).toList()),
              const SizedBox(height: 8),
            ],

            // Tag input
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    filled: true, fillColor: TuxieColors.linen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10)),
                  style: TuxieTextStyles.body(14),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addTag,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TuxieColors.lavender,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add,
                    color: TuxieColors.lavenderDark, size: 20)),
              ),
            ]),

            const SizedBox(height: 16),

            // Private toggle
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Private capture',
                    style: TuxieTextStyles.body(14,
                      weight: FontWeight.w700)),
                  Text('Only visible to you',
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textSecondary)),
                ],
              )),
              Switch(
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
                activeThumbColor: TuxieColors.tuxedo),
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
                  : Text('Save capture',
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

class _TypeToggle extends StatelessWidget {
  final String emoji;
  final String type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeToggle({
    required this.emoji, required this.type,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TuxieColors.tuxedo : Colors.transparent,
          borderRadius: BorderRadius.circular(14)),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}