import 'package:flutter/material.dart';

import '../shared/difficulty_utils.dart';

class DifficultyChip extends StatelessWidget {
  const DifficultyChip({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  void _cycle() {
    final i = difficultyValues.indexOf(value);
    onChanged(difficultyValues[(i + 1) % difficultyValues.length]);
  }

  @override
  Widget build(BuildContext context) {
    final c = difficultyColor(value);
    return GestureDetector(
      onTap: _cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withAlpha(25),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: c.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_cellular_alt_outlined, size: 14, color: c),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: c,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more, size: 13, color: c.withAlpha(180)),
          ],
        ),
      ),
    );
  }
}
