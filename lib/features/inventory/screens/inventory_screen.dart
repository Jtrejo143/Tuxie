// lib/features/inventory/screens/inventory_screen.dart
// Household inventory — item tracking, low stock alerts, purchase history

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/restock_sheet.dart';

// ── PROVIDERS ────────────────────────────────────────────────────

final inventoryFilterProvider = StateProvider<String>((ref) => 'All');

final inventoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 inventoryProvider: fetching for userId=$userId');
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();

  final result = await supabase
      .from('inventory_items')
      .select('*')
      .eq('household_id', member['household_id'])
      .order('category', ascending: true)
      .order('name', ascending: true);

  debugPrint('🐱 inventoryProvider: got ${result.length} items');
  return List<Map<String, dynamic>>.from(result);
});

final purchaseHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();

  // Get all item IDs for this household
  final items = await supabase
      .from('inventory_items')
      .select('id')
      .eq('household_id', member['household_id']);

  if (items.isEmpty) return [];

  final itemIds = items.map((i) => i['id'] as String).toList();

  final history = await supabase
      .from('purchase_history')
      .select('*, inventory_items(name, emoji)')
      .inFilter('item_id', itemIds)
      .order('purchased_at', ascending: false)
      .limit(30);

  debugPrint('🐱 purchaseHistoryProvider: got ${history.length} records');
  return List<Map<String, dynamic>>.from(history);
});

// ── SCREEN ───────────────────────────────────────────────────────

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final history   = ref.watch(purchaseHistoryProvider);
    final filter    = ref.watch(inventoryFilterProvider);

    // Count low/out items for the header badge
    final alertCount = inventory.when(
      data: (items) => items.where((i) =>
        (i['current_qty'] as int? ?? 0) <=
        (i['min_qty'] as int? ?? 1)).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Unique categories for filter chips
    final categories = inventory.when(
      data: (items) {
        final cats = items
            .map((i) => i['category'] as String? ?? 'Other')
            .toSet()
            .toList()
          ..sort();
        return cats;
      },
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );

    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('Inventory',
                                  style: TuxieTextStyles.display(28,
                                    color: Colors.white)),
                                if (alertCount > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: TuxieColors.blushDark,
                                      borderRadius: BorderRadius.circular(20)),
                                    child: Text('$alertCount low',
                                      style: TuxieTextStyles.body(11,
                                        weight: FontWeight.w800,
                                        color: Colors.white)),
                                  ),
                                ],
                              ]),
                              Text('Household essentials',
                                style: TuxieTextStyles.body(14,
                                  color: Colors.white.withValues(alpha: 0.55))),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showAddItem(context),
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
                                  Text('Add item',
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

                      // Category filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _FilterChip(
                            label: 'All',
                            selected: filter == 'All',
                            onTap: () => ref
                              .read(inventoryFilterProvider.notifier)
                              .state = 'All',
                          ),
                          const SizedBox(width: 8),
                          ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: cat,
                              selected: filter == cat,
                              onTap: () => ref
                                .read(inventoryFilterProvider.notifier)
                                .state = cat,
                            ),
                          )),
                        ]),
                      ),

                      const SizedBox(height: 12),

                      // Tabs
                      TabBar(
                        controller: _tabController,
                        indicatorColor: TuxieColors.sand,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: TuxieTextStyles.body(13,
                          weight: FontWeight.w700),
                        tabs: const [
                          Tab(text: 'Items'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── ITEMS TAB ─────────────────────────────────────
            inventory.when(
              data: (items) {
                final filtered = filter == 'All'
                  ? items
                  : items.where((i) =>
                      (i['category'] as String? ?? 'Other') == filter)
                    .toList();

                if (filtered.isEmpty) {
                  return _EmptyInventory(
                    message: filter == 'All'
                      ? 'No items yet'
                      : 'No $filter items',
                  );
                }

                // Sort: low/out items first
                final sorted = [...filtered]..sort((a, b) {
                  final aQty = a['current_qty'] as int? ?? 0;
                  final aMin = a['min_qty'] as int? ?? 1;
                  final bQty = b['current_qty'] as int? ?? 0;
                  final bMin = b['min_qty'] as int? ?? 1;
                  final aAlert = aQty <= aMin ? 0 : 1;
                  final bAlert = bQty <= bMin ? 0 : 1;
                  return aAlert.compareTo(bAlert);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) => _InventoryItemCard(
                    item: sorted[i],
                    onTap: () => _showEditItem(context, sorted[i]),
                    onRestock: () => _showRestock(context, sorted[i]),
                    onQuantityChanged: (delta) =>
                      _changeQuantity(sorted[i], delta),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),

            // ── HISTORY TAB ───────────────────────────────────
            history.when(
              data: (records) {
                if (records.isEmpty) {
                  return const _EmptyInventory(
                    message: 'No purchase history yet',
                    sub: 'Tap Restock on any item to log a purchase',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: records.length,
                  itemBuilder: (context, i) {
                    final r    = records[i];
                    final item = r['inventory_items'] as Map<String, dynamic>?;
                    final date = DateTime.parse(r['purchased_at'] as String);
                    final price = r['price'] != null
                      ? '\$${(r['price'] as num).toStringAsFixed(2)}'
                      : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TuxieColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TuxieColors.border)),
                      child: Row(children: [
                        Text(item?['emoji'] as String? ?? '📦',
                          style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item?['name'] as String? ?? 'Item',
                              style: TuxieTextStyles.body(14,
                                weight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(
                              '${_formatDate(date)} · +${r['qty_purchased']} units',
                              style: TuxieTextStyles.body(12,
                                color: TuxieColors.textSecondary)),
                            if (r['notes'] != null)
                              Text(r['notes'] as String,
                                style: TuxieTextStyles.body(12,
                                  color: TuxieColors.textMuted)),
                          ],
                        )),
                        if (price != null)
                          Text(price,
                            style: TuxieTextStyles.body(15,
                              weight: FontWeight.w800)),
                      ]),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────────

  void _showAddItem(BuildContext context) {
    debugPrint('🐱 InventoryScreen: opening add item sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(onSaved: () {
        ref.invalidate(inventoryProvider);
      }),
    );
  }

  void _showEditItem(BuildContext context, Map<String, dynamic> item) {
    debugPrint('🐱 InventoryScreen: editing item id=${item['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(
        existingItem: item,
        onSaved: () => ref.invalidate(inventoryProvider),
      ),
    );
  }

  void _showRestock(BuildContext context, Map<String, dynamic> item) {
    debugPrint('🐱 InventoryScreen: restocking item id=${item['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestockSheet(
        item: item,
        onSaved: () {
          ref.invalidate(inventoryProvider);
          ref.invalidate(purchaseHistoryProvider);
        },
      ),
    );
  }

  Future<void> _changeQuantity(
      Map<String, dynamic> item, int delta) async {
    final currentQty = item['current_qty'] as int? ?? 0;
    final newQty     = (currentQty + delta).clamp(0, 9999);
    debugPrint('🐱 InventoryScreen: qty change id=${item['id']} $currentQty → $newQty');
    try {
      await supabase
          .from('inventory_items')
          .update({'current_qty': newQty})
          .eq('id', item['id']);
      ref.invalidate(inventoryProvider);
    } catch (e) {
      debugPrint('🐱 InventoryScreen: qty change FAILED — $e');
    }
  }
}

// ── ITEM CARD ────────────────────────────────────────────────────

class _InventoryItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onRestock;
  final ValueChanged<int> onQuantityChanged;

  const _InventoryItemCard({
    required this.item,
    required this.onTap,
    required this.onRestock,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final qty    = item['current_qty'] as int? ?? 0;
    final minQty = item['min_qty'] as int? ?? 1;
    final unit   = item['unit'] as String? ?? '';
    final isOut  = qty == 0;
    final isLow  = qty > 0 && qty <= minQty;

    final statusColor = isOut
      ? TuxieColors.blushDark
      : isLow
        ? TuxieColors.sandDark
        : TuxieColors.sageDark;
    final statusBg = isOut
      ? TuxieColors.blush
      : isLow
        ? TuxieColors.sand
        : TuxieColors.sage;
    final statusLabel = isOut ? 'Out' : isLow ? 'Low' : 'OK';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TuxieColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOut
              ? TuxieColors.blushDark.withValues(alpha: 0.35)
              : isLow
                ? TuxieColors.sandDark.withValues(alpha: 0.35)
                : TuxieColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Emoji
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(
              item['emoji'] as String? ?? '📦',
              style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),

          // Name + category
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['name'] as String,
                style: TuxieTextStyles.body(14, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(children: [
                if (item['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: TuxieColors.lavender,
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(item['category'] as String,
                      style: TuxieTextStyles.body(10,
                        weight: FontWeight.w700,
                        color: TuxieColors.lavenderDark)),
                  ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel,
                    style: TuxieTextStyles.body(10,
                      weight: FontWeight.w700,
                      color: statusColor)),
                ),
              ]),
            ],
          )),

          // Quantity controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () => onQuantityChanged(-1)),
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(child: Text(
                    '$qty${unit.isNotEmpty ? ' $unit' : ''}',
                    style: TuxieTextStyles.body(15,
                      weight: FontWeight.w800,
                      color: statusColor),
                    textAlign: TextAlign.center))),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => onQuantityChanged(1)),
              ]),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onRestock,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TuxieColors.tuxedo,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text('Restock',
                    style: TuxieTextStyles.body(11,
                      weight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: TuxieColors.linen,
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: TuxieColors.textSecondary),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────

String _formatDate(DateTime date) {
  final now  = DateTime.now();
  final diff = now.difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  return '${date.day}/${date.month}/${date.year}';
}

// ── SHARED WIDGETS ────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
            ? TuxieColors.white
            : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
        child: Text(label,
          style: TuxieTextStyles.body(12,
            weight: FontWeight.w700,
            color: selected
              ? TuxieColors.tuxedo
              : Colors.white.withValues(alpha: 0.8))),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  final String message;
  final String sub;
  const _EmptyInventory({
    required this.message,
    this.sub = 'Tap + Add item to get started',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(message,
              style: TuxieTextStyles.display(20),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub,
              style: TuxieTextStyles.body(13,
                color: TuxieColors.textSecondary),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
