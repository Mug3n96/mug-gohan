import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'core/api/api_client.dart';
import 'core/models/app_config.dart';
import 'core/providers/config_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

Future<AppConfig> _loadConfig() async {
  if (!kIsWeb) return AppConfig.defaults;
  try {
    final res = await http
        .get(Uri.parse('${computeWebBaseUrl()}/api/config'))
        .timeout(const Duration(seconds: 3));
    if (res.statusCode == 200) {
      return AppConfig.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
  } catch (_) {}
  return AppConfig.defaults;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await _loadConfig();
  AppTheme.configure(config.theme);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const MugGohanApp(),
    ),
  );
}

class MugGohanApp extends ConsumerWidget {
  const MugGohanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'mug-gohan',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
