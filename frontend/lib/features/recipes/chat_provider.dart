import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client.dart';
import 'chat_model.dart';
import 'recipe_detail_provider.dart';
import 'recipe_model.dart';

part 'chat_provider.g.dart';

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  Future<List<ChatMessage>> build(String recipeId) async {
    final client = ref.watch(apiClientProvider);
    final data =
        await client.get('/api/recipes/$recipeId/chat') as List<dynamic>;
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(String message) async {
    final current = state.valueOrNull ?? [];

    // Optimistic: show user message immediately
    final optimisticUser = ChatMessage(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
      recipeId: recipeId,
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = AsyncData([...current, optimisticUser]);

    final client = ref.read(apiClientProvider);
    final data = await client.post(
      '/api/recipes/$recipeId/chat',
      {'message': message},
    ) as Map<String, dynamic>;

    Recipe? proposal;
    if (data['proposal'] is Map<String, dynamic>) {
      try {
        proposal = Recipe.fromJson(data['proposal'] as Map<String, dynamic>);
      } catch (_) {}
    }

    final assistantMsg = ChatMessage(
      id: 'resp-${DateTime.now().millisecondsSinceEpoch}',
      recipeId: recipeId,
      role: 'assistant',
      content: data['text'] as String,
      proposal: proposal,
      createdAt: DateTime.now().toIso8601String(),
    );

    state = AsyncData([...current, optimisticUser, assistantMsg]);
  }

  Future<void> applyProposal(Recipe proposal) async {
    await ref
        .read(recipeDetailProvider(recipeId).notifier)
        .save(proposal.toJson());
  }
}
