// lib/core/theme/tuxie_theme.dart
// Tuxie design system — all colors, text styles, and theme data

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── COLOR TOKENS ─────────────────────────────────────────────────

class TuxieColors {
  TuxieColors._();

  // Backgrounds
  static const linen        = Color(0xFFF5F0E8);
  static const white        = Color(0xFFFDFCFA);
  static const tuxedo       = Color(0xFF1E1E2E);
  static const tuxedoSoft   = Color(0xFF2C2C3E);

  // Domain accent palette
  static const lavender     = Color(0xFFE8E0F0);
  static const lavenderDark = Color(0xFF9B8EC4);
  static const sage         = Color(0xFFD6EAE0);
  static const sageDark     = Color(0xFF4A8C6A);
  static const sand         = Color(0xFFF5E6D3);
  static const sandDark     = Color(0xFFC47A3A);
  static const blush        = Color(0xFFF0E0E6);
  static const blushDark    = Color(0xFFB05A72);

  // Text
  static const textPrimary   = Color(0xFF1E1E2E);
  static const textSecondary = Color(0xFF6B6680);
  static const textMuted     = Color(0xFFA09CB0);

  // Borders
  static const border        = Color(0x14000000); // rgba(0,0,0,0.08)

  // Priority
  static const priorityHigh   = Color(0xFFE05A5A);
  static const priorityMedium = Color(0xFFE8A030);
  static const priorityLow    = Color(0xFF5DB87A);

  // Domain → color mapping
  static Color domainColor(String domain) {
    switch (domain) {
      case 'household':        return lavender;
      case 'goals':            return blush;
      case 'finance':          return sand;
      case 'health':           return sage;
      case 'social':           return blush;
      case 'work_commitments': return sand;
      default:                 return lavender;
    }
  }

  static Color domainColorDark(String domain) {
    switch (domain) {
      case 'household':        return lavenderDark;
      case 'goals':            return blushDark;
      case 'finance':          return sandDark;
      case 'health':           return sageDark;
      case 'social':           return blushDark;
      case 'work_commitments': return sandDark;
      default:                 return lavenderDark;
    }
  }

  static String domainEmoji(String domain) {
    switch (domain) {
      case 'household':        return '🏠';
      case 'goals':            return '🎯';
      case 'finance':          return '💳';
      case 'health':           return '💪';
      case 'social':           return '🎉';
      case 'work_commitments': return '💼';
      default:                 return '📌';
    }
  }
}

// ── TEXT STYLES ──────────────────────────────────────────────────

class TuxieTextStyles {
  TuxieTextStyles._();

  // Display — DM Serif Display
  static TextStyle display(double size, {Color? color}) =>
    GoogleFonts.dmSerifDisplay(
      fontSize: size,
      color: color ?? TuxieColors.textPrimary,
    );

  // Body — Nunito
  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
    GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color ?? TuxieColors.textPrimary,
    );
}

// ── THEME DATA ───────────────────────────────────────────────────

ThemeData tuxieTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: TuxieColors.linen,
    colorScheme: const ColorScheme.light(
      primary: TuxieColors.tuxedo,
      secondary: TuxieColors.lavenderDark,
      surface: TuxieColors.white,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(fontSize: 40),
      displayMedium: GoogleFonts.dmSerifDisplay(fontSize: 32),
      displaySmall: GoogleFonts.dmSerifDisplay(fontSize: 26),
      headlineMedium: GoogleFonts.dmSerifDisplay(fontSize: 22),
      headlineSmall: GoogleFonts.dmSerifDisplay(fontSize: 18),
    ),
    cardTheme: CardThemeData(
      color: TuxieColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: TuxieColors.border, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TuxieColors.tuxedo,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.dmSerifDisplay(
        fontSize: 22,
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: TuxieColors.white,
      selectedItemColor: TuxieColors.tuxedo,
      unselectedItemColor: TuxieColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 10),
      unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w500, fontSize: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TuxieColors.tuxedo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TuxieColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TuxieColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TuxieColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TuxieColors.lavenderDark, width: 2),
      ),
      hintStyle: GoogleFonts.nunito(color: TuxieColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
