import 'package:flutter/material.dart';

/// Central dark futuristic theme + palette for Saru Bot.
abstract final class AppTheme {
  // ---- Palette ------------------------------------------------------------
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF141B34);
  static const Color surfaceHigh = Color(0xFF1E293B);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentRed = Color(0xFFF87171);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  /// User chat bubble background (cyan) — needs dark text on top.
  static const Color userBubble = Color(0xFF22D3EE);

  /// Saru chat bubble background (slate).
  static const Color saruBubble = Color(0xFF1E293B);

  // ---- Theme --------------------------------------------------------------
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: accentCyan,
      secondary: accentPurple,
      surface: surface,
      error: accentRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
