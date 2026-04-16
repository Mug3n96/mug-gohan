import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashed_border_painter.dart';

class InlineTextField extends StatelessWidget {
  const InlineTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.style,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextStyle? style;
  final String? hint;
  final int? maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: style,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withAlpha(140),
                fontStyle: FontStyle.italic,
                fontSize: style?.fontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DashedBorderPainter(
                  color: AppTheme.primary.withAlpha(55)),
            ),
          ),
        ),
      ],
    );
  }
}
