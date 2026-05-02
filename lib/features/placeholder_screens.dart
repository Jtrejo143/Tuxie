// PLACEHOLDER SCREENS
// These allow the app to compile and run immediately.
// Each screen gets fully built in its respective milestone session.
// Save each class in its own file as indicated by the path comment above each class.

import 'package:flutter/material.dart';
import '../core/theme/tuxie_theme.dart';

// ─────────────────────────────────────────────────────────────────
// lib/features/brain/screens/capture_screen.dart
// ─────────────────────────────────────────────────────────────────
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _Placeholder(title: 'Second Brain', emoji: '🧠', color: TuxieColors.sage);
}

// ─────────────────────────────────────────────────────────────────
// lib/features/finance/screens/finance_screen.dart
// ─────────────────────────────────────────────────────────────────
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _Placeholder(title: 'Finances', emoji: '💳', color: TuxieColors.sand);
}

// ─────────────────────────────────────────────────────────────────
// lib/features/goals/screens/goals_screen.dart
// ─────────────────────────────────────────────────────────────────
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _Placeholder(title: 'Goals & Vision', emoji: '🎯', color: TuxieColors.blush);
}

// ─────────────────────────────────────────────────────────────────
// lib/features/health/screens/health_screen.dart
// ─────────────────────────────────────────────────────────────────
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _Placeholder(title: 'Health & Habits', emoji: '💪', color: TuxieColors.sage);
}

// ─────────────────────────────────────────────────────────────────
// lib/features/inventory/screens/inventory_screen.dart
// ─────────────────────────────────────────────────────────────────
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _Placeholder(title: 'Inventory', emoji: '📦', color: TuxieColors.sand);
}

// ─────────────────────────────────────────────────────────────────
// lib/features/ai/screens/chat_screen.dart
// ─────────────────────────────────────────────────────────────────
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _Placeholder(title: 'Ask Tuxie', emoji: '🤖', color: TuxieColors.lavender);
}

// ─────────────────────────────────────────────────────────────────
// Shared placeholder widget — used by all screens above
// ─────────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  const _Placeholder(
      {required this.title, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: SafeArea(
        child: Column(
          children: [
            // Dark header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              decoration: const BoxDecoration(
                color: TuxieColors.tuxedo,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Text(title,
                  style: TuxieTextStyles.display(28, color: Colors.white)),
            ),

            // Coming soon body
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 44))),
                    ),
                    const SizedBox(height: 20),
                    Text('Coming in the next session',
                        style: TuxieTextStyles.body(16,
                            weight: FontWeight.w700,
                            color: TuxieColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      'This screen gets built in its milestone session.',
                      style: TuxieTextStyles.body(13,
                          color: TuxieColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}