import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';

class ChatProposalCard extends StatelessWidget {
  const ChatProposalCard({
    super.key,
    required this.proposal,
    required this.proposalStatus,
    required this.onAccept,
    required this.onReject,
  });

  final Recipe? proposal;
  final String? proposalStatus; // 'accepted' | 'rejected' | null
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (proposalStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withAlpha(60)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
            SizedBox(width: 6),
            Text('Übernommen',
                style: TextStyle(color: Colors.green, fontSize: 13)),
          ],
        ),
      );
    }

    if (proposalStatus == 'rejected') {
      return Text('Abgelehnt',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppTheme.textSecondary));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high,
                    size: 15, color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                Text(
                  'Vorschlag',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildSummary(context),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: proposal != null ? onAccept : null,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.primaryLight,
                    ),
                    child: const Text('Übernehmen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final p = proposal;
    final parts = <String>[];
    if (p != null) {
      if (p.title.isNotEmpty) parts.add(p.title);
      if (p.ingredients.isNotEmpty) parts.add('${p.ingredients.length} Zutaten');
      if (p.steps.isNotEmpty) parts.add('${p.steps.length} Schritte');
    }
    return Text(
      parts.join(' · '),
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: AppTheme.textSecondary),
    );
  }
}
