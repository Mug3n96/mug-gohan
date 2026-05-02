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

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _ImageArea(recipe: recipe),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.hasTitle ? recipe.title : 'Neues Rezept',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: recipe.hasTitle
                              ? scheme.onSurface
                              : scheme.onSurface.withAlpha(80),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (recipe.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          recipe.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withAlpha(150),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 10),
                      _MetaRow(recipe: recipe),
                    ],
                  ),
                ),
              ),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ],
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

    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        if (recipe.difficulty.isNotEmpty)
          Positioned(
            top: 10,
            right: 10,
            child: _DifficultyPill(label: recipe.difficulty),
          ),
        if (recipe.tags.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: _TagsRow(tags: recipe.tags),
            ),
          ),
      ],
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});
  final List<String> tags;

  static const _spacing = 5.0;
  static const _hPad = 10.0; // matches _TagPill horizontal padding
  static const _textStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  double _pillWidth(String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: _textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width + _hPad * 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final visible = <String>[];
        double used = 0;

        for (var i = 0; i < tags.length; i++) {
          final tag = tags[i];
          final pillW = _pillWidth(tag);
          final sep = visible.isEmpty ? 0.0 : _spacing;
          final remaining = tags.length - i - 1;
          final reserveOverflow = remaining > 0
              ? _spacing + _pillWidth('+$remaining')
              : 0.0;

          if (used + sep + pillW + reserveOverflow <= maxW) {
            visible.add(tag);
            used += sep + pillW;
          } else {
            break;
          }
        }

        final overflow = tags.length - visible.length;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final tag in visible) _TagPill(label: tag),
            if (overflow > 0) _TagPill(label: '+$overflow', emphasized: true),
          ],
        );
      },
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, this.emphasized = false});
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? AppTheme.primary
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized ? Colors.white : AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
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
        Positioned.fill(
          child: ImagePlaceholder(
            iconSize: 40,
            title: recipe.hasTitle ? recipe.title : null,
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
        icon: Icons.schedule_outlined,
        label: [recipe.prepTime, recipe.cookTime]
            .where((s) => s.isNotEmpty)
            .join(' + '),
      ));
    }
    if (recipe.portions > 0) {
      chips.add(_Chip(
        icon: Icons.person_outline,
        label:
            '${recipe.portions} ${recipe.portions == 1 ? 'Portion' : 'Portionen'}',
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 14,
      runSpacing: 6,
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
        Icon(icon, size: 14, color: scheme.onSurface.withAlpha(140)),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withAlpha(160),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
