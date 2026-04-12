import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client.dart';
import 'recipe_model.dart';

part 'recipes_provider.g.dart';

@riverpod
class RecipeListNotifier extends _$RecipeListNotifier {
  @override
  Future<List<Recipe>> build() async {
    final client = ref.watch(apiClientProvider);
    final data = await client.get('/api/recipes') as List<dynamic>;
    return data
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recipe> create() async {
    final client = ref.read(apiClientProvider);
    final data = await client.post('/api/recipes', {}) as Map<String, dynamic>;
    final recipe = Recipe.fromJson(data);
    ref.invalidateSelf();
    return recipe;
  }

  Future<void> delete(String id) async {
    final client = ref.read(apiClientProvider);
    await client.delete('/api/recipes/$id');
    ref.invalidateSelf();
  }
}
