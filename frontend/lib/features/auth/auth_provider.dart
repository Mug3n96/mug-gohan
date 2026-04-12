import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

const _keyStorageKey = 'api_key';
const _storage = FlutterSecureStorage();

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<String?> build() async {
    return _storage.read(key: _keyStorageKey);
  }

  Future<void> login(String apiKey) async {
    await _storage.write(key: _keyStorageKey, value: apiKey);
    state = AsyncData(apiKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _keyStorageKey);
    state = const AsyncData(null);
  }
}
