import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';
import 'recipe_model.dart';
import 'recipes_provider.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipeListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('mug-gohan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(recipeListNotifierProvider),
        ),
        data: (recipes) => recipes.isEmpty
            ? _EmptyState(onCreateTap: () => _createRecipe(context, ref))
            : _RecipeGrid(
                recipes: recipes,
                onCreateTap: () => _createRecipe(context, ref),
              ),
      ),
      floatingActionButton: recipesAsync.hasValue && recipesAsync.value!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _createRecipe(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
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

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid({required this.recipes, required this.onCreateTap});

  final List<Recipe> recipes;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) => _RecipeCard(recipe: recipes[index]),
        );
      },
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recipes/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                ],
              ),
              if (recipe.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
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
                    _MetaChip(
                      icon: Icons.label_outline,
                      label: recipe.tags.first,
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
