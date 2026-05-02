import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.iconSize = 48,
    this.title,
  });

  final double iconSize;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final base = AppTheme.primary;
    final hsl = HSLColor.fromColor(base);
    final bgColor = hsl
        .withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
        .withLightness(0.78)
        .toColor();
    final stripeCol = hsl
        .withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0))
        .withLightness(0.62)
        .toColor()
        .withAlpha(70);

    return CustomPaint(
      painter: _DiagonalStripesPainter(
        baseColor: bgColor,
        stripeColor: stripeCol,
      ),
      child: Center(
        child: hasTitle
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hsl.withLightness(0.25).toColor(),
                    fontSize: iconSize * 0.42,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0.2,
                  ),
                ),
              )
            : Icon(
                Icons.restaurant,
                size: iconSize,
                color: base.withAlpha(110),
              ),
      ),
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  _DiagonalStripesPainter({
    required this.baseColor,
    required this.stripeColor,
  });

  final Color baseColor;
  final Color stripeColor;
  static const double stripeWidth = 2.0;
  static const double gap = 10.0;
  static const double angle = -math.pi / 4;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);

    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    final extent = diag;
    final step = stripeWidth + gap;
    for (double x = -extent; x <= extent; x += step) {
      canvas.drawLine(Offset(x, -extent), Offset(x, extent), stripePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter old) =>
      old.baseColor != baseColor || old.stripeColor != stripeColor;
}
