import 'package:flutter/material.dart';

import '../models/app_config.dart';

/// Central theme configuration.
/// Call [AppTheme.configure] once in main() with the loaded config.
/// Flutter's ColorScheme.fromSeed() generates the full palette from seedColor.
class AppTheme {
  const AppTheme._();

  static ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2D6A4F),
  );

  static void configure(AppThemeConfig config) {
    var scheme = ColorScheme.fromSeed(seedColor: config.seedColor);
    if (config.accentColor != null) {
      scheme = scheme.copyWith(
        secondary: config.accentColor,
        secondaryContainer: config.accentColor!.withAlpha(40),
        onSecondary: Colors.white,
      );
    }
    _scheme = scheme;
  }

  // Colors derived from the generated scheme
  static Color get primary => _scheme.primary;
  static Color get primaryLight => _scheme.secondary;
  static Color get surface => _scheme.surfaceContainerLow;
  static Color get background => _scheme.surface;
  static Color get error => _scheme.error;

  // Signal colors — fixed sensible defaults, not seed-generated
  static const Color success = Color(0xFF4A7C59);
  static const Color warning = Color(0xFFC47A2A);
  static const Color info = Color(0xFF4A6FA5);

  // Non-configurable constants
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _scheme,
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: _scheme.outlineVariant),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: _scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: _scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );
}
