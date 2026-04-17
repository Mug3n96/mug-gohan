import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipes_provider.dart';

class RecipeCard extends ConsumerWidget {
  const RecipeCard({super.key, required this.recipe});

  final Recipe recipe;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, size: 28, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              Text(
                recipe.hasTitle ? recipe.title : 'Neues Rezept',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Wird unwiderruflich gelöscht.',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => Navigator.pop(ctx, false),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                          child: Text('Abbrechen',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(50),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        splashColor: Colors.white24,
                        onTap: () => Navigator.pop(ctx, true),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Löschen',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
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
          borderRadius: BorderRadius.circular(20),
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
            onTap: () => context.push('/recipes/${recipe.id}'),
            onLongPress: () => _confirmDelete(context, ref),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image area ──────────────────────────────────────────
                Expanded(
                  flex: 2,
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
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.restaurant,
              size: 40,
              color: AppTheme.primary.withAlpha(100),
            ),
          ),
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
      ),
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
