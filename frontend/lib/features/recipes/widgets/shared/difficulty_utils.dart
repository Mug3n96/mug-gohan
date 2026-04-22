import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const difficultyValues = ['einfach', 'mittel', 'schwer'];

Color difficultyColor(String difficulty) => switch (difficulty) {
      'einfach' => Colors.green,
      'mittel' => Colors.orange,
      'schwer' => Colors.red,
      _ => AppTheme.textSecondary,
    };
