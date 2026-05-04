// lib/core/providers/shared_providers.dart
// Global providers shared across multiple screens.
// Centralised here so any screen can invalidate them.
// Import this file anywhere you need finance or inventory stats.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_config.dart';
import '../router/app_router.dart';

// Finance summary — used on Home + Finance screens
final financeSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return {'spent': 0, 'budget': 0, 'billsDue': 0};

  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();
  final householdId = member['household_id'];

  final now        = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
  final monthEnd   = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

  // Parallel queries for speed
  final results = await Future.wait([
    supabase.from('expenses').select('amount')
      .eq('household_id', householdId)
      .gte('date', monthStart)
      .lte('date', monthEnd),
    supabase.from('budget_categories').select('monthly_limit')
      .eq('household_id', householdId),
    supabase.from('bills').select('due_day, last_paid_at')
      .eq('household_id', householdId),
  ]);

  final expenses   = results[0] as List;
  final categories = results[1] as List;
  final bills      = results[2] as List;

  final spent  = expenses.fold<double>(0, (s, e) => s + (e['amount'] as num).toDouble());
  final budget = categories.fold<double>(0, (s, c) => s + (c['monthly_limit'] as num).toDouble());

  double billsDue = 0;
  for (final bill in bills) {
    final dueDay      = bill['due_day'] as int? ?? 1;
    final lastPaid    = bill['last_paid_at'] as String?;
    bool paidThisMonth = false;
    if (lastPaid != null) {
      final paid = DateTime.parse(lastPaid);
      paidThisMonth = paid.year == now.year && paid.month == now.month;
    }
    if (!paidThisMonth && dueDay <= now.day) billsDue++;
  }

  debugPrint('🐱 financeSummaryProvider: spent=$spent budget=$budget billsDue=$billsDue');
  return {'spent': spent, 'budget': budget, 'billsDue': billsDue};
});

// Low stock count — used on Home + Inventory screens
final lowStockCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authNotifierProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 0;

  final member = await supabase
    .from('household_members')
    .select('household_id')
    .eq('profile_id', userId)
    .single();

  final items = await supabase
    .from('inventory_items')
    .select('current_qty, min_qty')
    .eq('household_id', member['household_id']);

  final count = items.where((i) =>
    (i['current_qty'] as int? ?? 0) <= (i['min_qty'] as int? ?? 1)).length;

  debugPrint('🐱 lowStockCountProvider: $count items low/out');
  return count;
});
