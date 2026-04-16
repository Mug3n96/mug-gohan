import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashed_border_painter.dart';

class InlineTagInput extends StatefulWidget {
  const InlineTagInput({super.key, required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  State<InlineTagInput> createState() => _InlineTagInputState();
}

class _InlineTagInputState extends State<InlineTagInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _active = _focus.hasFocus));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final tag = _ctrl.text.trim();
    if (tag.isNotEmpty) {
      widget.onAdd(tag);
      _ctrl.clear();
    }
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
                  Icon(Icons.add, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: const TextStyle(fontSize: 13),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Tag hinzufügen...',
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
