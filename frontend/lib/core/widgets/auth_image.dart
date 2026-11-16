import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

/// Image served by the backend (recipe or chat image). Sends the API key and
/// decodes at [cacheWidth] (logical px, scaled by the device pixel ratio) so
/// small tiles do not decode full-size photos.
class AuthImage extends ConsumerWidget {
  const AuthImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(apiClientProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.network(
      client.resolve(path),
      headers: client.authHeaders,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth == null ? null : (cacheWidth! * dpr).round(),
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }
}
