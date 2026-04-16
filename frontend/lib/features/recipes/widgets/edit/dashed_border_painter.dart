import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, this.radius = 8.0});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        Radius.circular(radius),
      ));

    const dashLen = 7.0;
    const gapLen = 4.0;
    bool draw = true;
    for (final metric in path.computeMetrics()) {
      double pos = 0;
      while (pos < metric.length) {
        final end =
            (pos + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(pos, end), paint);
        pos = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;

  @override
  bool operator ==(Object other) =>
      other is DashedBorderPainter &&
      other.color == color &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(color, radius);
}
