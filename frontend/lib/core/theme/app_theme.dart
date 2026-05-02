import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_config.dart';

/// Central theme configuration.
/// Call [AppTheme.configure] once in main() with the loaded config.
/// Flutter's ColorScheme.fromSeed() generates the full palette from seedColor.
class AppTheme {
  const AppTheme._();

  static Color _seedColor = const Color(0xFF2D6A4F);
  static Color? _accentColor;

  static ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2D6A4F),
  );

  static void configure(AppThemeConfig config) {
    _seedColor = config.seedColor;
    _accentColor = config.accentColor;
    _scheme = _buildScheme(Brightness.light);
  }

  static ColorScheme _buildScheme(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(
        seedColor: _seedColor, brightness: brightness);
    if (_accentColor != null) {
      scheme = scheme.copyWith(
        secondary: _accentColor,
        secondaryContainer: _accentColor!.withAlpha(40),
        onSecondary: Colors.white,
      );
    }
    return scheme;
  }

  // Colors derived from the generated light scheme (brand colors for direct use)
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

  static ThemeData get dark => _buildThemeData(_buildScheme(Brightness.dark));
  static ThemeData get light => _buildThemeData(_scheme);

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;
    final serif = GoogleFonts.frauncesTextTheme(base);
    final sans = GoogleFonts.interTextTheme(base);
    return sans.copyWith(
      displayLarge: serif.displayLarge?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      displayMedium: serif.displayMedium?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      displaySmall: serif.displaySmall?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      headlineLarge: serif.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      headlineMedium: serif.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      headlineSmall: serif.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleLarge: serif.titleLarge?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleMedium: serif.titleMedium?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface),
    );
  }

  static ThemeData _buildThemeData(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        textTheme: _buildTextTheme(scheme),
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.fraunces(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: scheme.onSurface),
        ),
        cardTheme: CardThemeData(
          color: scheme.surfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );
}
