import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/config_provider.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/widgets/content_constraint.dart';
import '../../auth/auth_provider.dart';
import '../providers/recipes_provider.dart';
import '../widgets/list/list_empty_state.dart';
import '../widgets/list/recipe_grid.dart';

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
              Expanded(
                child: Text(ref.watch(appConfigProvider).strings.appTitle),
              ),
              IconButton(
                icon: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: 'Dark Mode',
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onInverseSurface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                ),
              ),
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
        error: (e, _) => ListErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(recipeListNotifierProvider),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return ListEmptyState(
              onCreateTap: () => _createRecipe(context, ref),
            );
          }

          final allTags = <String>{for (final r in recipes) ...r.tags}.toList()
            ..sort();

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
                      TagFilterBar(
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
                      child: RecipeGrid(
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
      final recipe = await ref
          .read(recipeListNotifierProvider.notifier)
          .create();
      if (context.mounted) context.push('/recipes/${recipe.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
