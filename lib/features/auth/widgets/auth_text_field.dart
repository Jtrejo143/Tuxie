// lib/features/auth/widgets/auth_text_field.dart

import 'package:flutter/material.dart';
import '../../../core/theme/tuxie_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool darkMode;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TuxieTextStyles.body(15,
        color: darkMode ? Colors.white : TuxieColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TuxieTextStyles.body(15,
          color: darkMode
            ? Colors.white.withOpacity(0.35)
            : TuxieColors.textMuted),
        filled: true,
        fillColor: darkMode
          ? Colors.white.withOpacity(0.10)
          : TuxieColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: darkMode
              ? Colors.white.withOpacity(0.15)
              : TuxieColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: darkMode
              ? Colors.white.withOpacity(0.15)
              : TuxieColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: darkMode
              ? TuxieColors.sand
              : TuxieColors.lavenderDark,
            width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// lib/features/shell/screens/main_shell.dart
// Bottom navigation shell — wraps all main screens
// ─────────────────────────────────────────────────────────────────

// (Save as a separate file: lib/features/shell/screens/main_shell.dart)
