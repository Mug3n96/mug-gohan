import 'package:flutter/material.dart';

class AppThemeConfig {
  final Color seedColor;
  final Color? accentColor;

  const AppThemeConfig({required this.seedColor, this.accentColor});

  static Color _hex(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return fallback;
    }
  }

  factory AppThemeConfig.fromJson(Map<String, dynamic> json) => AppThemeConfig(
        seedColor: _hex(json['seedColor'] as String?, const Color(0xFF2D6A4F)),
        accentColor: json['accentColor'] != null
            ? _hex(json['accentColor'] as String?, const Color(0xFF52B788))
            : null,
      );

  static AppThemeConfig get defaults => AppThemeConfig.fromJson({});
}

class AppStringsConfig {
  final String appTitle;
  final String loginTitle;
  final String loginSubtitle;
  final String remyGreeting;
  final String remySubtitle;
  final String remyFooter;
  final String listEmptyTitle;
  final String listEmptySubtitle;
  final String listCreateButton;
  final String recipeEmptyHint;

  const AppStringsConfig({
    required this.appTitle,
    required this.loginTitle,
    required this.loginSubtitle,
    required this.remyGreeting,
    required this.remySubtitle,
    required this.remyFooter,
    required this.listEmptyTitle,
    required this.listEmptySubtitle,
    required this.listCreateButton,
    required this.recipeEmptyHint,
  });

  factory AppStringsConfig.fromJson(Map<String, dynamic> json) => AppStringsConfig(
        appTitle: json['appTitle'] as String? ?? 'mug-gohan',
        loginTitle: json['loginTitle'] as String? ?? 'mug-gohan',
        loginSubtitle: json['loginSubtitle'] as String? ?? '無限ごはん',
        remyGreeting: json['remyGreeting'] as String? ?? 'Hey, ich bin Miso!',
        remySubtitle: json['remySubtitle'] as String? ?? 'Lass uns zusammen Rezepte entwerfen',
        remyFooter: json['remyFooter'] as String? ??
            'Was für ein Rezept möchtest du entwerfen? Sende mir gerne Bilder, Notizen, Fotos oder eine Sprachnachricht und wir erstellen ein tolles Rezept!',
        listEmptyTitle: json['listEmptyTitle'] as String? ?? 'Noch keine Rezepte',
        listEmptySubtitle: json['listEmptySubtitle'] as String? ??
            'Erstelle dein erstes Rezept\nund lass Miso dir helfen.',
        listCreateButton: json['listCreateButton'] as String? ?? 'Rezept erstellen',
        recipeEmptyHint: json['recipeEmptyHint'] as String? ??
            'Noch leer — tippe auf ✏️\num mit Miso loszulegen.',
      );

  static AppStringsConfig get defaults => AppStringsConfig.fromJson({});
}

class AppFeaturesConfig {
  final bool voiceEnabled;
  final bool hasAvatar;
  final bool hasAvatarIcon;

  const AppFeaturesConfig({
    required this.voiceEnabled,
    this.hasAvatar = false,
    this.hasAvatarIcon = false,
  });

  factory AppFeaturesConfig.fromJson(Map<String, dynamic> json) =>
      AppFeaturesConfig(
        voiceEnabled: json['voiceEnabled'] as bool? ?? false,
        hasAvatar: json['hasAvatar'] as bool? ?? false,
        hasAvatarIcon: json['hasAvatarIcon'] as bool? ?? false,
      );

  static AppFeaturesConfig get defaults => AppFeaturesConfig.fromJson({});
}

class AppAssistantConfig {
  final String name;

  const AppAssistantConfig({required this.name});

  factory AppAssistantConfig.fromJson(Map<String, dynamic> json) =>
      AppAssistantConfig(name: json['name'] as String? ?? 'Miso');

  static AppAssistantConfig get defaults => AppAssistantConfig.fromJson({});
}

class AppConfig {
  final AppThemeConfig theme;
  final AppStringsConfig strings;
  final AppFeaturesConfig features;
  final AppAssistantConfig assistant;

  const AppConfig({
    required this.theme,
    required this.strings,
    required this.features,
    required this.assistant,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        theme: AppThemeConfig.fromJson(
            (json['theme'] as Map<String, dynamic>?) ?? {}),
        strings: AppStringsConfig.fromJson(
            (json['strings'] as Map<String, dynamic>?) ?? {}),
        features: AppFeaturesConfig.fromJson(
            (json['features'] as Map<String, dynamic>?) ?? {}),
        assistant: AppAssistantConfig.fromJson(
            (json['assistant'] as Map<String, dynamic>?) ?? {}),
      );

  static AppConfig get defaults => AppConfig(
        theme: AppThemeConfig.defaults,
        strings: AppStringsConfig.defaults,
        features: AppFeaturesConfig.defaults,
        assistant: AppAssistantConfig.defaults,
      );
}
