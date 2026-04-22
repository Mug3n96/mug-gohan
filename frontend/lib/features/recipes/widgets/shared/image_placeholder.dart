import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, this.iconSize = 48});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(50),
            AppTheme.primaryLight.withAlpha(30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: iconSize,
          color: AppTheme.primary.withAlpha(80),
        ),
      ),
    );
  }
}
