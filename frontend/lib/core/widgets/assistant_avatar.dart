import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api/api_client.dart';
import '../providers/config_provider.dart';

/// The AI assistant's avatar.
///
/// Shows a custom avatar when the deployer dropped `avatar.svg` /
/// `avatar-icon.svg` next to `config.json` (advertised via /api/config and
/// served by the backend at /api/branding/...). Otherwise falls back to the
/// bundled neutral onigiri default. Custom avatars are web-only, like the rest
/// of the runtime config; on Android the bundled asset is always used.
class AssistantAvatar extends ConsumerWidget {
  const AssistantAvatar({
    super.key,
    required this.size,
    this.colorFilter,
    this.icon = false,
  });

  /// Rendered height in logical pixels.
  final double size;

  /// Tint applied to the SVG (the avatars are drawn as monochrome silhouettes).
  final ColorFilter? colorFilter;

  /// Use the compact icon variant instead of the larger illustration.
  final bool icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = icon
        ? 'assets/icons/assistant_icon.svg'
        : 'assets/icons/assistant.svg';
    final bundled = SvgPicture.asset(
      asset,
      height: size,
      colorFilter: colorFilter,
    );

    final features = ref.watch(appConfigProvider).features;
    final hasCustom = icon ? features.hasAvatarIcon : features.hasAvatar;
    if (!hasCustom || !kIsWeb) return bundled;

    final url =
        '${computeWebBaseUrl()}/api/branding/${icon ? 'avatar-icon' : 'avatar'}';
    return SvgPicture.network(
      url,
      height: size,
      colorFilter: colorFilter,
      placeholderBuilder: (_) => bundled,
    );
  }
}
