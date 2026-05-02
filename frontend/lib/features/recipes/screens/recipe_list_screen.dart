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
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Row(
              children: [
                Expanded(
                  child: Text(ref.watch(appConfigProvider).strings.appTitle),
                ),
                IconButton(
                  icon: Icon(
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  tooltip: 'Dark Mode',
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                ),
              ],
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Deine Rezepte',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        '${filtered.length} ${filtered.length == 1 ? "Rezept" : "Rezepte"}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(140)),
                      ),
                    ),
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
      if (context.mounted) {
        await context.push('/recipes/${recipe.id}');
        ref.invalidate(recipeListNotifierProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
