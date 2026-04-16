import 'package:flutter/material.dart';

class AppThemeConfig {
  final Color primary;
  final Color primaryLight;
  final Color surface;
  final Color background;
  final Color error;

  const AppThemeConfig({
    required this.primary,
    required this.primaryLight,
    required this.surface,
    required this.background,
    required this.error,
  });

  static Color _hex(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return fallback;
    }
  }

  factory AppThemeConfig.fromJson(Map<String, dynamic> json) => AppThemeConfig(
        primary: _hex(json['primary'] as String?, const Color(0xFF2D6A4F)),
        primaryLight: _hex(json['primaryLight'] as String?, const Color(0xFF52B788)),
        surface: _hex(json['surface'] as String?, const Color(0xFFF8F5F0)),
        background: _hex(json['background'] as String?, const Color(0xFFFFFBF5)),
        error: _hex(json['error'] as String?, const Color(0xFFB5332E)),
      );

  static AppThemeConfig get defaults => AppThemeConfig.fromJson({});
}

class AppStringsConfig {
  final String remyGreeting;
  final String remySubtitle;
  final String listEmptyTitle;
  final String listEmptySubtitle;
  final String listCreateButton;
  final String recipeEmptyHint;

  const AppStringsConfig({
    required this.remyGreeting,
    required this.remySubtitle,
    required this.listEmptyTitle,
    required this.listEmptySubtitle,
    required this.listCreateButton,
    required this.recipeEmptyHint,
  });

  factory AppStringsConfig.fromJson(Map<String, dynamic> json) => AppStringsConfig(
        remyGreeting: json['remyGreeting'] as String? ?? 'Hey, ich bin Ramy!',
        remySubtitle: json['remySubtitle'] as String? ?? 'Lass uns zusammen Rezepte entwerfen',
        listEmptyTitle: json['listEmptyTitle'] as String? ?? 'Noch keine Rezepte',
        listEmptySubtitle: json['listEmptySubtitle'] as String? ??
            'Erstelle dein erstes Rezept\nund lass Remy dir helfen.',
        listCreateButton: json['listCreateButton'] as String? ?? 'Rezept erstellen',
        recipeEmptyHint: json['recipeEmptyHint'] as String? ??
            'Noch leer — tippe auf ✏️\num mit Remy loszulegen.',
      );

  static AppStringsConfig get defaults => AppStringsConfig.fromJson({});
}

class AppConfig {
  final AppThemeConfig theme;
  final AppStringsConfig strings;

  const AppConfig({required this.theme, required this.strings});

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        theme: AppThemeConfig.fromJson(
            (json['theme'] as Map<String, dynamic>?) ?? {}),
        strings: AppStringsConfig.fromJson(
            (json['strings'] as Map<String, dynamic>?) ?? {}),
      );

  static AppConfig get defaults =>
      AppConfig(theme: AppThemeConfig.defaults, strings: AppStringsConfig.defaults);
}
