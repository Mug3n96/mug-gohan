import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipes_provider.dart';
import '../shared/image_placeholder.dart';
import 'delete_recipe_dialog.dart';

class RecipeCard extends ConsumerWidget {
  const RecipeCard({super.key, required this.recipe});

  final Recipe recipe;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final title = recipe.hasTitle ? recipe.title : 'Neues Rezept';
    final confirmed = await showDeleteRecipeDialog(context, title: title);
    if (confirmed && context.mounted) {
      await ref.read(recipeListNotifierProvider.notifier).delete(recipe.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await context.push('/recipes/${recipe.id}');
              ref.invalidate(recipeListNotifierProvider);
            },
            onLongPress: () => _confirmDelete(context, ref),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image area ──────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: _ImageArea(recipe: recipe),
                ),
                // ── Content area ─────────────────────────────────────────
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.hasTitle ? recipe.title : 'Neues Rezept',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: recipe.hasTitle
                                      ? scheme.onSurface
                                      : scheme.onSurface.withAlpha(80),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              color: scheme.onSurface.withAlpha(60),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Löschen',
                              onPressed: () => _confirmDelete(context, ref),
                            ),
                          ],
                        ),
                        if (recipe.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            recipe.description,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurface.withAlpha(120)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        _MetaRow(recipe: recipe),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final base = recipe.imageUrl != null
        ? SizedBox.expand(
            child: Image.network(
              recipe.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => _Placeholder(recipe: recipe),
            ),
          )
        : _Placeholder(recipe: recipe);

    if (recipe.tags.isEmpty) return base;

    return Stack(
      children: [
        base,
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tag in recipe.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ImagePlaceholder(iconSize: 40)),
        if (recipe.isDraft && !recipe.hasTitle)
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Entwurf',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (recipe.prepTime.isNotEmpty || recipe.cookTime.isNotEmpty) {
      chips.add(_Chip(
        icon: Icons.timer_outlined,
        label: [recipe.prepTime, recipe.cookTime]
            .where((s) => s.isNotEmpty)
            .join(' + '),
      ));
    }
    if (recipe.portions > 0) {
      chips.add(_Chip(
        icon: Icons.people_outline,
        label: '${recipe.portions}',
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: scheme.onSurface.withAlpha(120)),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withAlpha(140),
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
