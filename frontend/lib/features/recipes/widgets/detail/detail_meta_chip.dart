import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DetailMetaItem {
  final IconData icon;
  final String label;
  final Color? color;
  const DetailMetaItem({required this.icon, required this.label, this.color});
}

class DetailMetaChip extends StatelessWidget {
  const DetailMetaChip({super.key, required this.item});
  final DetailMetaItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(item.label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
