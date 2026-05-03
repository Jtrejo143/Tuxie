// lib/features/finance/screens/finance_screen.dart
// Finance dashboard — budget categories, expenses, bills tracker

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';
import '../widgets/add_category_sheet.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/add_bill_sheet.dart';

// ── PROVIDERS ────────────────────────────────────────────────────

// Budget categories with their monthly spend totals
final budgetCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  debugPrint('🐱 budgetCategoriesProvider: fetching for userId=$userId');
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();
  final householdId = member['household_id'];

  final categories = await supabase
      .from('budget_categories')
      .select('*')
      .eq('household_id', householdId)
      .order('name', ascending: true);

  debugPrint('🐱 budgetCategoriesProvider: got ${categories.length} categories');
  return List<Map<String, dynamic>>.from(categories);
});

// Current month expenses grouped by category
final monthExpensesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();

  final now       = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
  final monthEnd   = DateTime(now.year, now.month + 1, 0).toIso8601String();

  final expenses = await supabase
      .from('expenses')
      .select('*, budget_categories(name, emoji, monthly_limit)')
      .eq('household_id', member['household_id'])
      .gte('date', monthStart.split('T')[0])
      .lte('date', monthEnd.split('T')[0])
      .order('date', ascending: false);

  debugPrint('🐱 monthExpensesProvider: got ${expenses.length} expenses this month');
  return List<Map<String, dynamic>>.from(expenses);
});

// Bills list
final billsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final member = await supabase
      .from('household_members')
      .select('household_id')
      .eq('profile_id', userId)
      .single();

  final bills = await supabase
      .from('bills')
      .select('*')
      .eq('household_id', member['household_id'])
      .order('due_day', ascending: true);

  debugPrint('🐱 billsProvider: got ${bills.length} bills');
  return List<Map<String, dynamic>>.from(bills);
});

// ── SCREEN ───────────────────────────────────────────────────────

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});
  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(budgetCategoriesProvider);
    final expenses   = ref.watch(monthExpensesProvider);
    final bills      = ref.watch(billsProvider);

    // Calculate totals
    final totalSpent = expenses.when(
      data: (list) => list.fold<double>(
        0, (sum, e) => sum + (e['amount'] as num).toDouble()),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    final totalBudget = categories.when(
      data: (list) => list.fold<double>(
        0, (sum, c) => sum + (c['monthly_limit'] as num).toDouble()),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Finances',
                                style: TuxieTextStyles.display(28,
                                  color: Colors.white)),
                              Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: TuxieTextStyles.body(14,
                                  color: Colors.white.withValues(alpha: 0.55))),
                            ],
                          ),
                          // Quick add expense button
                          GestureDetector(
                            onTap: () => _showAddExpense(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: TuxieColors.sand,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add,
                                    color: TuxieColors.sandDark, size: 18),
                                  const SizedBox(width: 4),
                                  Text('Expense',
                                    style: TuxieTextStyles.body(13,
                                      weight: FontWeight.w800,
                                      color: TuxieColors.sandDark)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Summary cards
                      Row(children: [
                        Expanded(child: _SummaryCard(
                          label: 'Spent',
                          value: NumberFormat.currency(
                            symbol: '\$').format(totalSpent),
                          sub: 'this month',
                          color: TuxieColors.blush,
                          tc: TuxieColors.blushDark,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _SummaryCard(
                          label: 'Remaining',
                          value: NumberFormat.currency(
                            symbol: '\$').format(
                              (totalBudget - totalSpent).clamp(0, double.infinity)),
                          sub: 'of \$${NumberFormat.compact().format(totalBudget)} budget',
                          color: TuxieColors.sage,
                          tc: TuxieColors.sageDark,
                        )),
                      ]),

                      const SizedBox(height: 16),

                      // Tab bar
                      TabBar(
                        controller: _tabController,
                        indicatorColor: TuxieColors.sand,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: TuxieTextStyles.body(13,
                          weight: FontWeight.w700),
                        tabs: const [
                          Tab(text: 'Budget'),
                          Tab(text: 'Expenses'),
                          Tab(text: 'Bills'),
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
            // ── BUDGET TAB ─────────────────────────────────────
            _BudgetTab(
              categories: categories,
              expenses: expenses,
              onAddCategory: () => _showAddCategory(context),
              onEditCategory: (c) => _showEditCategory(context, c),
              onAddExpense: () => _showAddExpense(context),
            ),

            // ── EXPENSES TAB ───────────────────────────────────
            _ExpensesTab(
              expenses: expenses,
              onDelete: (id) => _deleteExpense(id),
            ),

            // ── BILLS TAB ──────────────────────────────────────
            _BillsTab(
              bills: bills,
              onAddBill: () => _showAddBill(context),
              onMarkPaid: (bill) => _markBillPaid(bill),
              onDelete: (id) => _deleteBill(id),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────────

  void _showAddCategory(BuildContext context) {
    debugPrint('🐱 FinanceScreen: opening add category sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(onSaved: () {
        ref.invalidate(budgetCategoriesProvider);
      }),
    );
  }

  void _showEditCategory(BuildContext context, Map<String, dynamic> category) {
    debugPrint('🐱 FinanceScreen: editing category id=${category['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(
        existingCategory: category,
        onSaved: () => ref.invalidate(budgetCategoriesProvider),
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    debugPrint('🐱 FinanceScreen: opening add expense sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(onSaved: () {
        ref.invalidate(monthExpensesProvider);
      }),
    );
  }

  void _showAddBill(BuildContext context) {
    debugPrint('🐱 FinanceScreen: opening add bill sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBillSheet(onSaved: () {
        ref.invalidate(billsProvider);
      }),
    );
  }

  Future<void> _deleteExpense(String id) async {
    debugPrint('🐱 FinanceScreen: deleting expense id=$id');
    try {
      await supabase.from('expenses').delete().eq('id', id);
      ref.invalidate(monthExpensesProvider);
      debugPrint('🐱 FinanceScreen: expense deleted');
    } catch (e) {
      debugPrint('🐱 FinanceScreen: delete expense FAILED — $e');
    }
  }

  Future<void> _markBillPaid(Map<String, dynamic> bill) async {
    debugPrint('🐱 FinanceScreen: marking bill paid id=${bill['id']}');
    try {
      await supabase.from('bills').update({
        'last_paid_at': DateTime.now().toIso8601String().split('T')[0],
      }).eq('id', bill['id']);
      ref.invalidate(billsProvider);
      debugPrint('🐱 FinanceScreen: bill marked paid');
    } catch (e) {
      debugPrint('🐱 FinanceScreen: mark paid FAILED — $e');
    }
  }

  Future<void> _deleteBill(String id) async {
    debugPrint('🐱 FinanceScreen: deleting bill id=$id');
    try {
      await supabase.from('bills').delete().eq('id', id);
      ref.invalidate(billsProvider);
      debugPrint('🐱 FinanceScreen: bill deleted');
    } catch (e) {
      debugPrint('🐱 FinanceScreen: delete bill FAILED — $e');
    }
  }
}

// ── BUDGET TAB ───────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> categories;
  final AsyncValue<List<Map<String, dynamic>>> expenses;
  final VoidCallback onAddCategory;
  final ValueChanged<Map<String, dynamic>> onEditCategory;
  final VoidCallback onAddExpense;

  const _BudgetTab({
    required this.categories,
    required this.expenses,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget Categories',
              style: TuxieTextStyles.display(18)),
            GestureDetector(
              onTap: onAddCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: TuxieColors.tuxedo,
                  borderRadius: BorderRadius.circular(20)),
                child: Text('+ Category',
                  style: TuxieTextStyles.body(12,
                    weight: FontWeight.w700,
                    color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        categories.when(
          data: (catList) {
            if (catList.isEmpty) {
              return _EmptyFinance(
                emoji: '💳',
                message: 'No budget categories yet',
                sub: 'Tap + Category to add your first one',
              );
            }

            // Calculate spend per category
            final spendMap = <String, double>{};
            expenses.whenData((expList) {
              for (final e in expList) {
                final catId = e['category_id'] as String?;
                if (catId != null) {
                  spendMap[catId] = (spendMap[catId] ?? 0) +
                    (e['amount'] as num).toDouble();
                }
              }
            });

            return Column(
              children: catList.map((cat) {
                final spent = spendMap[cat['id']] ?? 0.0;
                final limit = (cat['monthly_limit'] as num).toDouble();
                final pct   = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                final isOver = spent > limit;

                return GestureDetector(
                  onTap: () => onEditCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TuxieColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOver
                          ? TuxieColors.blushDark.withValues(alpha: 0.4)
                          : TuxieColors.border),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(cat['emoji'] as String? ?? '💳',
                            style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(cat['name'] as String,
                            style: TuxieTextStyles.body(15,
                              weight: FontWeight.w700))),
                          Text(
                            '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                            style: TuxieTextStyles.body(14,
                              weight: FontWeight.w700,
                              color: isOver
                                ? TuxieColors.blushDark
                                : TuxieColors.textSecondary)),
                        ]),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: isOver
                              ? TuxieColors.blush
                              : TuxieColors.linen,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver
                                ? TuxieColors.blushDark
                                : TuxieColors.sageDark),
                          ),
                        ),
                        if (isOver) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Over budget by \$${(spent - limit).toStringAsFixed(0)}',
                            style: TuxieTextStyles.body(11,
                              weight: FontWeight.w700,
                              color: TuxieColors.blushDark)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e',
            style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
        ),
      ],
    );
  }
}

// ── EXPENSES TAB ─────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> expenses;
  final ValueChanged<String> onDelete;

  const _ExpensesTab({required this.expenses, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return expenses.when(
      data: (list) {
        if (list.isEmpty) {
          return _EmptyFinance(
            emoji: '🧾',
            message: 'No expenses logged yet',
            sub: 'Tap + Expense to log your first one',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final e      = list[i];
            final cat    = e['budget_categories'] as Map<String, dynamic>?;
            final amount = (e['amount'] as num).toDouble();
            final date   = DateTime.parse(e['date']);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TuxieColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TuxieColors.border),
              ),
              child: Row(children: [
                Text(cat?['emoji'] as String? ?? '💳',
                  style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['description'] as String? ??
                      cat?['name'] as String? ?? 'Expense',
                      style: TuxieTextStyles.body(14,
                        weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      '${cat?['name'] ?? 'Uncategorised'} · ${DateFormat('MMM d').format(date)}',
                      style: TuxieTextStyles.body(12,
                        color: TuxieColors.textSecondary)),
                  ],
                )),
                Text('\$${amount.toStringAsFixed(2)}',
                  style: TuxieTextStyles.body(16,
                    weight: FontWeight.w800,
                    color: TuxieColors.textPrimary)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onDelete(e['id'] as String),
                  child: const Icon(Icons.close,
                    color: TuxieColors.textMuted, size: 18)),
              ]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── BILLS TAB ────────────────────────────────────────────────────

class _BillsTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> bills;
  final VoidCallback onAddBill;
  final ValueChanged<Map<String, dynamic>> onMarkPaid;
  final ValueChanged<String> onDelete;

  const _BillsTab({
    required this.bills,
    required this.onAddBill,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bills', style: TuxieTextStyles.display(18)),
            GestureDetector(
              onTap: onAddBill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: TuxieColors.tuxedo,
                  borderRadius: BorderRadius.circular(20)),
                child: Text('+ Bill',
                  style: TuxieTextStyles.body(12,
                    weight: FontWeight.w700,
                    color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        bills.when(
          data: (billList) {
            if (billList.isEmpty) {
              return _EmptyFinance(
                emoji: '📄',
                message: 'No bills added yet',
                sub: 'Tap + Bill to track your recurring bills',
              );
            }

            final now = DateTime.now();
            return Column(
              children: billList.map((bill) {
                final dueDay     = bill['due_day'] as int? ?? 1;
                final lastPaid   = bill['last_paid_at'] as String?;
                final amount     = (bill['amount'] as num).toDouble();
                final isAutopay  = bill['is_autopay'] as bool? ?? false;

                // Determine if paid this month
                bool paidThisMonth = false;
                if (lastPaid != null) {
                  final paid = DateTime.parse(lastPaid);
                  paidThisMonth = paid.year == now.year &&
                                  paid.month == now.month;
                }

                // Due date this month
                final dueDate = DateTime(now.year, now.month, dueDay);
                final isDueToday = dueDate.day == now.day &&
                                   dueDate.month == now.month;
                final isOverdue  = !paidThisMonth && dueDate.isBefore(now);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TuxieColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOverdue
                        ? TuxieColors.blushDark.withValues(alpha: 0.4)
                        : paidThisMonth
                          ? TuxieColors.sageDark.withValues(alpha: 0.3)
                          : TuxieColors.border),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    // Paid indicator
                    GestureDetector(
                      onTap: paidThisMonth ? null : () => onMarkPaid(bill),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: paidThisMonth
                            ? TuxieColors.sage
                            : TuxieColors.linen,
                          border: Border.all(
                            color: paidThisMonth
                              ? TuxieColors.sageDark
                              : TuxieColors.border,
                            width: 2)),
                        child: paidThisMonth
                          ? const Icon(Icons.check,
                              color: TuxieColors.sageDark, size: 16)
                          : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bill['name'] as String,
                          style: TuxieTextStyles.body(15,
                            weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(
                            paidThisMonth
                              ? 'Paid this month'
                              : isDueToday
                                ? 'Due TODAY'
                                : isOverdue
                                  ? 'Overdue — due ${DateFormat('MMM d').format(dueDate)}'
                                  : 'Due ${DateFormat('MMM d').format(dueDate)}',
                            style: TuxieTextStyles.body(12,
                              weight: FontWeight.w600,
                              color: paidThisMonth
                                ? TuxieColors.sageDark
                                : isOverdue || isDueToday
                                  ? TuxieColors.blushDark
                                  : TuxieColors.textSecondary)),
                          if (isAutopay) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: TuxieColors.lavender,
                                borderRadius: BorderRadius.circular(8)),
                              child: Text('Auto',
                                style: TuxieTextStyles.body(10,
                                  weight: FontWeight.w700,
                                  color: TuxieColors.lavenderDark)),
                            ),
                          ],
                        ]),
                      ],
                    )),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${amount.toStringAsFixed(2)}',
                          style: TuxieTextStyles.body(16,
                            weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => onDelete(bill['id'] as String),
                          child: const Icon(Icons.close,
                            color: TuxieColors.textMuted, size: 16)),
                      ],
                    ),
                  ]),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e',
            style: TuxieTextStyles.body(13, color: TuxieColors.blushDark)),
        ),
      ],
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color tc;

  const _SummaryCard({
    required this.label, required this.value,
    required this.sub, required this.color, required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: TuxieTextStyles.body(11,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55))),
        const SizedBox(height: 4),
        Text(value,
          style: TuxieTextStyles.body(22,
            weight: FontWeight.w800,
            color: Colors.white)),
        Text(sub,
          style: TuxieTextStyles.body(11,
            color: Colors.white.withValues(alpha: 0.5))),
      ]),
    );
  }
}

class _EmptyFinance extends StatelessWidget {
  final String emoji;
  final String message;
  final String sub;

  const _EmptyFinance({
    required this.emoji,
    required this.message,
    required this.sub,
  });

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
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(message,
          style: TuxieTextStyles.display(20),
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(sub,
          style: TuxieTextStyles.body(13,
            color: TuxieColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }
}
