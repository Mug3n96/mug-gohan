import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config.dart';

/// Populated in main() before runApp — always resolves immediately with no
/// loading state. Override in tests or custom ProviderScope if needed.
final appConfigProvider = Provider<AppConfig>((_) => AppConfig.defaults);
