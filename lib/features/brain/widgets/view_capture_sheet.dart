// lib/features/brain/widgets/view_capture_sheet.dart
// Full view + edit + delete for a capture

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';

class ViewCaptureSheet extends StatefulWidget {
  final Map<String, dynamic> capture;
  final VoidCallback onDeleted;
  final VoidCallback onEdited;
  const ViewCaptureSheet({
    super.key,
    required this.capture,
    required this.onDeleted,
    required this.onEdited,
  });

  @override
  State<ViewCaptureSheet> createState() => _ViewCaptureSheetState();
}

class _ViewCaptureSheetState extends State<ViewCaptureSheet> {
  bool _editing  = false;
  bool _loading  = false;
  String? _error;

  late final _contentCtrl = TextEditingController(
    text: widget.capture['content'] as String? ?? '');
  late final _urlCtrl = TextEditingController(
    text: widget.capture['url'] as String? ?? '');
  List<String> _tags = [];
  final _tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from((widget.capture['tags'] as List?) ?? []);
  }

  String get _type => widget.capture['capture_type'] as String? ?? 'text';
  DateTime get _created =>
    DateTime.parse(widget.capture['created_at'] as String);

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
    setState(() { _loading = true; _error = null; });
    debugPrint('🐱 ViewCaptureSheet: saving edits id=${widget.capture['id']}');
    try {
      await supabase.from('brain_captures').update({
        'content': _contentCtrl.text.trim().isEmpty
          ? null : _contentCtrl.text.trim(),
        'url':     _urlCtrl.text.trim().isEmpty
          ? null : _urlCtrl.text.trim(),
        'tags':    _tags,
      }).eq('id', widget.capture['id']);

      debugPrint('🐱 ViewCaptureSheet: update SUCCESS');
      widget.onEdited();
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      debugPrint('🐱 ViewCaptureSheet: FAILED — $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete() async {
    debugPrint('🐱 ViewCaptureSheet: deleting id=${widget.capture['id']}');
    try {
      await supabase.from('brain_captures')
        .delete()
        .eq('id', widget.capture['id']);
      debugPrint('🐱 ViewCaptureSheet: delete SUCCESS');
      widget.onDeleted();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🐱 ViewCaptureSheet: delete FAILED — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.capture['content'] as String?;
    final url     = widget.capture['url'] as String?;

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
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TuxieColors.border,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header row
            Row(children: [
              Text(_typeEmoji(_type),
                style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                DateFormat('MMM d, yyyy · h:mm a').format(_created),
                style: TuxieTextStyles.body(13,
                  color: TuxieColors.textSecondary))),
              // Edit toggle
              GestureDetector(
                onTap: () => setState(() => _editing = !_editing),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _editing
                      ? TuxieColors.tuxedo : TuxieColors.linen,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(_editing ? 'Cancel' : 'Edit',
                    style: TuxieTextStyles.body(13,
                      weight: FontWeight.w700,
                      color: _editing
                        ? Colors.white : TuxieColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: _delete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush,
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline,
                    color: TuxieColors.blushDark, size: 18)),
              ),
            ]),
            const SizedBox(height: 20),

            // Content
            if (_editing) ...[
              if (_type == 'link') ...[
                _Label('URL'),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    filled: true, fillColor: TuxieColors.linen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none)),
                  style: TuxieTextStyles.body(14),
                ),
                const SizedBox(height: 12),
              ],
              _Label('Content'),
              const SizedBox(height: 6),
              TextField(
                controller: _contentCtrl,
                maxLines: 6,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true, fillColor: TuxieColors.linen,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none)),
                style: TuxieTextStyles.body(15),
              ),
              const SizedBox(height: 16),

              // Tags editor
              _Label('Tags'),
              const SizedBox(height: 8),
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
              Row(children: [
                Expanded(child: TextField(
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
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TuxieColors.lavender,
                      borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.add,
                      color: TuxieColors.lavenderDark, size: 20))),
              ]),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TuxieColors.blush,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!,
                    style: TuxieTextStyles.body(13,
                      color: TuxieColors.blushDark))),
                const SizedBox(height: 12),
              ],

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
                    : Text('Save changes',
                        style: TuxieTextStyles.body(16,
                          weight: FontWeight.w800, color: Colors.white)),
                ),
              ),

            ] else ...[
              // Read mode
              if (url != null) ...[
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copied to clipboard'),
                        behavior: SnackBarBehavior.floating));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TuxieColors.linen,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TuxieColors.border)),
                    child: Row(children: [
                      const Icon(Icons.link,
                        color: TuxieColors.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(url,
                        style: TuxieTextStyles.body(13,
                          color: TuxieColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.copy,
                        color: TuxieColors.textMuted, size: 16),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (content != null && content.isNotEmpty) ...[
                SelectableText(content,
                  style: TuxieTextStyles.body(16).copyWith(height: 1.6)),
                const SizedBox(height: 16),
              ],
              if (_tags.isNotEmpty)
                Wrap(spacing: 6, runSpacing: 6, children: _tags.map((tag) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TuxieColors.lavender,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text('#$tag',
                      style: TuxieTextStyles.body(12,
                        weight: FontWeight.w700,
                        color: TuxieColors.lavenderDark)),
                  )
                ).toList()),
            ],
          ],
        ),
      ),
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'text':  return '📝';
      case 'link':  return '🔗';
      case 'image': return '📷';
      case 'file':  return '📎';
      default:      return '🧠';
    }
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