import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/config_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final url = await ref.read(serverUrlNotifierProvider.future);
        if (url != null && mounted) {
          _urlController.text = url;
        }
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    if (!kIsWeb && _urlController.text.trim().isEmpty) {
      setState(() => _error = 'Bitte Server-URL eingeben');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final serverUrl = kIsWeb
          ? computeWebBaseUrl()
          : _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
      final client = ApiClient(key, serverUrl);
      await client.post('/api/auth/login', {'key': key});
      if (!kIsWeb) {
        await ref.read(serverUrlNotifierProvider.notifier).save(serverUrl);
      }
      await ref.read(authNotifierProvider.notifier).login(key);
      if (mounted) context.go('/recipes');
    } on ApiException catch (e) {
      setState(() { _error = e.statusCode == 401 ? 'Ungültiger API Key' : e.message; });
    } catch (e) {
      setState(() { _error = 'Verbindung fehlgeschlagen. URL prüfen.' ; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: Icon(ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  tooltip: 'Dark Mode',
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                    foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ref.watch(appConfigProvider).strings.loginTitle,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: AppTheme.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref.watch(appConfigProvider).strings.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (!kIsWeb) ...[
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://meine-domain.de',
                      ),
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Zugangscode eingeben',
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}
