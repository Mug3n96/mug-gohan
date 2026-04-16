import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import 'recipe_card.dart';

class RecipeGrid extends StatelessWidget {
  const RecipeGrid({
    super.key,
    required this.recipes,
    required this.onCreateTap,
  });

  final List<Recipe> recipes;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Text(
          'Keine Rezepte für diese Tags',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.0 : 1.7,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) =>
              RecipeCard(recipe: recipes[index]),
        );
      },
    );
  }
}

class TagFilterBar extends StatelessWidget {
  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final tag = tags[i];
          final active = selected.contains(tag);
          return FilterChip(
            label: Text(tag, style: const TextStyle(fontSize: 12)),
            selected: active,
            onSelected: (_) => onToggle(tag),
            visualDensity: VisualDensity.compact,
            selectedColor: AppTheme.primary.withAlpha(30),
            checkmarkColor: AppTheme.primary,
            side: BorderSide(
              color: active ? AppTheme.primary : Colors.transparent,
              width: 1,
            ),
          );
        },
      ),
    );
  }
}
