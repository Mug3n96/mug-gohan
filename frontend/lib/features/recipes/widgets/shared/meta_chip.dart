import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Kleines Icon+Label-Widget für Metadaten (Zeit, Portionen etc.)
/// Wird in RecipeCard und RecipeDetailScreen verwendet.
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}
