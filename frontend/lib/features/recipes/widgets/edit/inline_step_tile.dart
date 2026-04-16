import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import 'dashed_border_painter.dart';
import 'inline_text_field.dart';

class InlineStepTile extends StatefulWidget {
  const InlineStepTile({
    super.key,
    required this.step,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  final RecipeStep step;
  final int index;
  final ValueChanged<RecipeStep> onChanged;
  final VoidCallback onDelete;

  @override
  State<InlineStepTile> createState() => _InlineStepTileState();
}

class _InlineStepTileState extends State<InlineStepTile> {
  late TextEditingController _desc;
  late TextEditingController _duration;
  late TextEditingController _tip;

  @override
  void initState() {
    super.initState();
    final s = widget.step;
    _desc = TextEditingController(text: s.description);
    _duration =
        TextEditingController(text: s.durationMin?.toString() ?? '');
    _tip = TextEditingController(text: s.tip ?? '');
  }

  @override
  void didUpdateWidget(InlineStepTile old) {
    super.didUpdateWidget(old);
    final s = widget.step;
    if (_desc.text != s.description) _desc.text = s.description;
    final dur = s.durationMin?.toString() ?? '';
    if (_duration.text != dur) _duration.text = dur;
    final tip = s.tip ?? '';
    if (_tip.text != tip) _tip.text = tip;
  }

  @override
  void dispose() {
    _desc.dispose();
    _duration.dispose();
    _tip.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(RecipeStep(
        order: widget.step.order,
        description: _desc.text,
        durationMin: int.tryParse(_duration.text),
        tip: _tip.text.trim().isEmpty ? null : _tip.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text('${widget.index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: 44,
                      child: InlineTextField(
                        controller: _duration,
                        onChanged: _notify,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppTheme.textSecondary),
                        hint: '0',
                      ),
                    ),
                    Text(' Min',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppTheme.textSecondary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: widget.onDelete,
                      color: AppTheme.textSecondary.withAlpha(140),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                InlineTextField(
                  controller: _desc,
                  onChanged: _notify,
                  maxLines: null,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                  hint: 'Schritt beschreiben...',
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TextField(
                        controller: _tip,
                        onChanged: (_) => _notify(),
                        maxLines: null,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.amber.shade800),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lightbulb_outline,
                              size: 15, color: Colors.amber),
                          prefixIconConstraints: const BoxConstraints(
                              minWidth: 34, minHeight: 0),
                          hintText: 'Tipp hinzufügen...',
                          hintStyle: TextStyle(
                            fontSize: theme.textTheme.bodySmall?.fontSize,
                            color: Colors.amber.withAlpha(150),
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.amber.withAlpha(30),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: Colors.amber.withAlpha(100),
                            radius: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
