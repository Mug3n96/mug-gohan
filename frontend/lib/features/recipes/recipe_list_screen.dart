import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/content_constraint.dart';
import '../../features/auth/auth_provider.dart';
import 'recipe_model.dart';
import 'recipes_provider.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipeListNotifierProvider);

    final showFab = recipesAsync.hasValue && recipesAsync.value!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: ContentConstraint(
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Expanded(child: Text('mug-gohan')),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(recipeListNotifierProvider),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return _EmptyState(onCreateTap: () => _createRecipe(context, ref));
          }

          final allTags = {
            for (final r in recipes) ...r.tags,
          }.toList()..sort();

          final filtered = _selectedTags.isEmpty
              ? recipes
              : recipes
                  .where((r) => _selectedTags.any((t) => r.tags.contains(t)))
                  .toList();

          return ContentConstraint(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (allTags.isNotEmpty)
                      _TagFilterBar(
                        tags: allTags,
                        selected: _selectedTags,
                        onToggle: (tag) => setState(() {
                          if (_selectedTags.contains(tag)) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        }),
                      ),
                    Expanded(
                      child: _RecipeGrid(
                        recipes: filtered,
                        onCreateTap: () => _createRecipe(context, ref),
                      ),
                    ),
                  ],
                ),
                if (showFab)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: () => _createRecipe(context, ref),
                      child: const Icon(Icons.add),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createRecipe(BuildContext context, WidgetRef ref) async {
    try {
      final recipe = await ref.read(recipeListNotifierProvider.notifier).create();
      if (context.mounted) context.push('/recipes/${recipe.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ─── Tag filter bar ────────────────────────────────────────────────────────────

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
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

// ─── Grid ──────────────────────────────────────────────────────────────────────

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid({required this.recipes, required this.onCreateTap});

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
          itemBuilder: (context, index) => _RecipeCard(recipe: recipes[index]),
        );
      },
    );
  }
}

// ─── Card ──────────────────────────────────────────────────────────────────────

class _RecipeCard extends ConsumerWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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
                child: const Icon(Icons.delete_outline,
                    size: 28, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              Text(
                recipe.hasTitle ? recipe.title : 'Neues Rezept',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Wird unwiderruflich gelöscht.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Pill button group
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 11),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 11),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Löschen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recipes/${recipe.id}'),
        onLongPress: () => _confirmDelete(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.hasTitle ? recipe.title : 'Neues Rezept',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: recipe.hasTitle ? null : theme.disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (recipe.isDraft)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Entwurf',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: theme.disabledColor,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Löschen',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              // Description
              if (recipe.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  recipe.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              // Bottom row: meta + tags
              Row(
                children: [
                  if (recipe.prepTime.isNotEmpty || recipe.cookTime.isNotEmpty)
                    _MetaChip(
                      icon: Icons.timer_outlined,
                      label: [recipe.prepTime, recipe.cookTime]
                          .where((s) => s.isNotEmpty)
                          .join(' + '),
                    ),
                  if (recipe.portions > 0) ...[
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: Icons.people_outline,
                      label: '${recipe.portions}',
                    ),
                  ],
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TagRow(tags: recipe.tags),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tag row on card ───────────────────────────────────────────────────────────

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: tags
          .take(3)
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontSize: 10,
                      ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Meta chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: AppTheme.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Rezepte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle dein erstes Rezept\nund lass die KI dir helfen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: const Text('Rezept erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}
