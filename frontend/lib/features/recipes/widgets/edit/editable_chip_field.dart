import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashed_border_painter.dart';

class EditableChipField extends StatefulWidget {
  const EditableChipField({
    super.key,
    required this.icon,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  State<EditableChipField> createState() => _EditableChipFieldState();
}

class _EditableChipFieldState extends State<EditableChipField> {
  final _focus = FocusNode();
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _active = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = _focus.hasFocus),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: _active
                  ? AppTheme.textSecondary.withAlpha(35)
                  : AppTheme.textSecondary.withAlpha(15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  IntrinsicWidth(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      onChanged: (_) => widget.onChanged(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withAlpha(150),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: AppTheme.primary.withAlpha(60),
                  radius: 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
