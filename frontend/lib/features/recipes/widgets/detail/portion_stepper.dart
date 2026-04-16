import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PortionStepper extends StatelessWidget {
  const PortionStepper({
    super.key,
    required this.portions,
    required this.onChanged,
  });

  final int portions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: portions > 1 ? () => onChanged(portions - 1) : null,
          visualDensity: VisualDensity.compact,
          color: AppTheme.primary,
        ),
        Text('$portions Portion${portions != 1 ? 'en' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(portions + 1),
          visualDensity: VisualDensity.compact,
          color: AppTheme.primary,
        ),
      ],
    );
  }
}
