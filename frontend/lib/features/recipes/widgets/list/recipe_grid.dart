import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import 'recipe_card.dart';

class RecipeGridSliver extends StatelessWidget {
  const RecipeGridSliver({super.key, required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Keine Rezepte für diese Tags',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.crossAxisExtent;
        final crossAxisCount = w > 1100
            ? 4
            : w > 800
                ? 3
                : w > 520
                    ? 2
                    : 1;
        final aspectRatio = crossAxisCount == 1
            ? 1.0
            : crossAxisCount == 2
                ? 0.95
                : 0.86;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => RecipeCard(recipe: recipes[index]),
              childCount: recipes.length,
            ),
          ),
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
      height: 52,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          overscroll: false,
          physics: const ClampingScrollPhysics(),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 24, 10),
          itemCount: tags.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final tag = tags[i];
            final active = selected.contains(tag);
            return FilterChip(
              label: Text(
                tag,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
              selected: active,
              onSelected: (_) => onToggle(tag),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              pressElevation: 0,
              shadowColor: Colors.transparent,
              selectedShadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              showCheckmark: false,
              backgroundColor: Colors.transparent,
              selectedColor: AppTheme.primary.withAlpha(35),
              labelStyle: TextStyle(
                fontSize: 12,
                color: active ? AppTheme.primary : null,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: BorderSide(
                color:
                    active ? AppTheme.primary : AppTheme.primary.withAlpha(50),
                width: 1,
              ),
              shape: const StadiumBorder(),
            );
          },
        ),
      ),
    );
  }
}
