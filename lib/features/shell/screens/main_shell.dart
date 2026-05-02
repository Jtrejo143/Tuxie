// lib/features/shell/screens/main_shell.dart
// Bottom nav shell — persists across all main screens

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tuxie_theme.dart';
import '../../../core/router/app_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).fullPath ?? '';
    if (location.startsWith('/calendar'))  return 1;
    if (location.startsWith('/capture'))   return 2;
    if (location.startsWith('/finance'))   return 3;
    if (location.startsWith('/more'))      return 4;
    return 0; // home
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      backgroundColor: TuxieColors.linen,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TuxieColors.white,
          border: Border(top: BorderSide(color: TuxieColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_rounded,      label: 'Home',     index: 0, selected: selectedIndex, onTap: () => context.go(Routes.home)),
                _NavItem(icon: Icons.calendar_month,    label: 'Calendar', index: 1, selected: selectedIndex, onTap: () => context.go(Routes.calendar)),
                _CaptureButton(onTap: () => context.go(Routes.capture)),
                _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance', index: 3, selected: selectedIndex, onTap: () => context.go(Routes.finance)),
                _NavItem(icon: Icons.more_horiz_rounded, label: 'More',    index: 4, selected: selectedIndex, onTap: () => context.go(Routes.more)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
              size: 24,
              color: isSelected
                ? TuxieColors.tuxedo
                : TuxieColors.textMuted),
            const SizedBox(height: 3),
            Text(label,
              style: TuxieTextStyles.body(10,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                  ? TuxieColors.tuxedo
                  : TuxieColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CaptureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: TuxieColors.tuxedo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TuxieColors.tuxedo.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}