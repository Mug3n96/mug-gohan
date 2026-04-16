import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final val = await _storage.read(key: _kKey);
    if (val == 'dark') state = ThemeMode.dark;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage.write(
        key: _kKey, value: state == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((_) => ThemeModeNotifier());
