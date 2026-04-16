import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';

class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.step, required this.index});

  final RecipeStep step;
  final int index;

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
            decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text('${index + 1}',
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
                if (step.durationMin != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text('${step.durationMin} Min',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                Text(step.description,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
                if (step.tip != null && step.tip!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.amber.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(step.tip!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
