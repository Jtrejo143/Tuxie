// lib/features/brain/screens/capture_screen.dart
// Second Brain — text and link capture, search, filter by type and tag

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/add_capture_sheet.dart';
import '../widgets/view_capture_sheet.dart';

// ── PROVIDERS ────────────────────────────────────────────────────

final captureSearchProvider   = StateProvider<String>((ref) => '');
final captureTypeProvider     = StateProvider<String>((ref) => 'all');

final capturesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final search = ref.watch(captureSearchProvider);
  final type   = ref.watch(captureTypeProvider);

  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 capturesProvider: fetching userId=$userId type=$type search=$search');
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();

  var query = supabase
      .from('brain_captures')
      .select('*')
      .eq('household_id', member['household_id']);

  if (type != 'all') {
    query = query.eq('capture_type', type);
  }

  if (search.isNotEmpty) {
    query = query.ilike('content', '%$search%');
  }

  final result = await query
      .order('created_at', ascending: false)
      .limit(50);

  debugPrint('🐱 capturesProvider: got ${result.length} captures');
  return List<Map<String, dynamic>>.from(result);
});

// ── SCREEN ───────────────────────────────────────────────────────

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captures    = ref.watch(capturesProvider);
    final activeType  = ref.watch(captureTypeProvider);
    final searchQuery = ref.watch(captureSearchProvider);

    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: CustomScrollView(
        slivers: [

          // ── HEADER ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [TuxieColors.tuxedo, TuxieColors.tuxedoSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Title + add button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Second Brain',
                                style: TuxieTextStyles.display(28,
                                  color: Colors.white)),
                              captures.when(
                                data: (c) => Text(
                                  '${c.length} capture${c.length == 1 ? "" : "s"}',
                                  style: TuxieTextStyles.body(13,
                                    color: Colors.white
                                      .withValues(alpha: 0.55))),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showAddCapture(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: TuxieColors.sand,
                                borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add,
                                    color: TuxieColors.sandDark, size: 18),
                                  const SizedBox(width: 4),
                                  Text('Capture',
                                    style: TuxieTextStyles.body(13,
                                      weight: FontWeight.w800,
                                      color: TuxieColors.sandDark)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: TuxieColors.linen,
                          borderRadius: BorderRadius.circular(16)),
                        child: TextField(
                          controller: _searchCtrl,
                          style: TuxieTextStyles.body(14,
                            color: TuxieColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search captures...',
                            hintStyle: TuxieTextStyles.body(14,
                              color: TuxieColors.textMuted),
                            prefixIcon: const Icon(Icons.search,
                              color: TuxieColors.textSecondary,
                              size: 20),
                            suffixIcon: searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    ref.read(captureSearchProvider.notifier)
                                      .state = '';
                                  },
                                  child: const Icon(Icons.close,
                                    color: TuxieColors.textMuted,
                                    size: 18))
                              : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12)),
                          onChanged: (v) => ref
                            .read(captureSearchProvider.notifier)
                            .state = v,
                          cursorColor: TuxieColors.tuxedo,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Type filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          ...[
                            ('all',  'All',   '🧠'),
                            ('text', 'Notes', '📝'),
                            ('link', 'Links', '🔗'),
                            ('image','Images','📷'),
                            ('file', 'Files', '📎'),
                          ].map((t) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TypeChip(
                              label: t.$2,
                              emoji: t.$3,
                              selected: activeType == t.$1,
                              onTap: () => ref
                                .read(captureTypeProvider.notifier)
                                .state = t.$1,
                            ),
                          )),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── CAPTURE LIST ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: captures.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyBrain(
                      searching: searchQuery.isNotEmpty ||
                        activeType != 'all'));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CaptureCard(
                        capture: list[i],
                        onTap: () => _showViewCapture(context, list[i]),
                        onDelete: () => _deleteCapture(list[i]['id']),
                      ),
                    ),
                    childCount: list.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e'))),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────────

  void _showAddCapture(BuildContext context) {
    debugPrint('🐱 CaptureScreen: opening add capture sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCaptureSheet(
        onSaved: () => ref.invalidate(capturesProvider),
      ),
    );
  }

  void _showViewCapture(BuildContext context, Map<String, dynamic> capture) {
    debugPrint('🐱 CaptureScreen: viewing capture id=${capture['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ViewCaptureSheet(
        capture: capture,
        onDeleted: () => ref.invalidate(capturesProvider),
        onEdited: () => ref.invalidate(capturesProvider),
      ),
    );
  }

  Future<void> _deleteCapture(String id) async {
    debugPrint('🐱 CaptureScreen: deleting capture id=$id');
    try {
      await supabase.from('brain_captures').delete().eq('id', id);
      ref.invalidate(capturesProvider);
      debugPrint('🐱 CaptureScreen: delete SUCCESS');
    } catch (e) {
      debugPrint('🐱 CaptureScreen: delete FAILED — $e');
    }
  }
}

// ── CAPTURE CARD ─────────────────────────────────────────────────

class _CaptureCard extends StatelessWidget {
  final Map<String, dynamic> capture;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CaptureCard({
    required this.capture,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type    = capture['capture_type'] as String? ?? 'text';
    final content = capture['content'] as String? ?? '';
    final url     = capture['url'] as String?;
    final tags    = (capture['tags'] as List?)?.cast<String>() ?? [];
    final created = DateTime.parse(capture['created_at'] as String);

    final typeConfig = _typeConfig(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TuxieColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TuxieColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + time row
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeConfig.$2,
                  borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(typeConfig.$1,
                      style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(type,
                      style: TuxieTextStyles.body(10,
                        weight: FontWeight.w700,
                        color: typeConfig.$3)),
                  ],
                ),
              ),
              const Spacer(),
              Text(_formatAge(created),
                style: TuxieTextStyles.body(11,
                  color: TuxieColors.textMuted)),
            ]),

            if (content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(content,
                style: TuxieTextStyles.body(14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            ],

            if (url != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TuxieColors.linen,
                  borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.link,
                    size: 14, color: TuxieColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    _cleanUrl(url),
                    style: TuxieTextStyles.body(12,
                      color: TuxieColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],

            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 4, children: tags.map((tag) =>
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TuxieColors.lavender,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('#$tag',
                    style: TuxieTextStyles.body(11,
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

  // (emoji, bgColor, textColor)
  (String, Color, Color) _typeConfig(String type) {
    switch (type) {
      case 'text':  return ('📝', TuxieColors.lavender, TuxieColors.lavenderDark);
      case 'link':  return ('🔗', TuxieColors.sand, TuxieColors.sandDark);
      case 'image': return ('📷', TuxieColors.sage, TuxieColors.sageDark);
      case 'file':  return ('📎', TuxieColors.blush, TuxieColors.blushDark);
      default:      return ('📝', TuxieColors.lavender, TuxieColors.lavenderDark);
    }
  }

  String _formatAge(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  String _cleanUrl(String url) {
    return url
      .replaceFirst('https://', '')
      .replaceFirst('http://', '')
      .replaceFirst('www.', '');
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label, required this.emoji,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
            ? TuxieColors.white
            : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(label,
              style: TuxieTextStyles.body(12,
                weight: FontWeight.w700,
                color: selected
                  ? TuxieColors.tuxedo
                  : Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _EmptyBrain extends StatelessWidget {
  final bool searching;
  const _EmptyBrain({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TuxieColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TuxieColors.border)),
      child: Column(children: [
        const Text('🧠', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          searching ? 'Nothing found' : 'Your Second Brain is empty',
          style: TuxieTextStyles.display(20),
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          searching
            ? 'Try a different search or filter'
            : 'Tap + Capture to save your first thought, link, or note',
          style: TuxieTextStyles.body(13,
            color: TuxieColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }
}