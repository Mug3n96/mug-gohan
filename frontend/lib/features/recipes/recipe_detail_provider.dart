import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client.dart';
import 'recipe_model.dart';

part 'recipe_detail_provider.g.dart';

@riverpod
class RecipeDetail extends _$RecipeDetail {
  @override
  Future<Recipe> build(String id) async {
    final client = ref.watch(apiClientProvider);
    final data = await client.get('/api/recipes/$id') as Map<String, dynamic>;
    return Recipe.fromJson(data);
  }

  Future<void> save(Map<String, dynamic> updates) async {
    final current = await future;
    final client = ref.read(apiClientProvider);
    final merged = {...current.toJson(), ...updates};
    final data = await client.put('/api/recipes/$id', merged) as Map<String, dynamic>;
    state = AsyncData(Recipe.fromJson(data));
  }
}
