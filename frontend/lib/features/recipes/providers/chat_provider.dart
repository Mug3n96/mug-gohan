import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../models/chat_model.dart';
import 'recipe_detail_provider.dart';
import '../models/recipe_model.dart';

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

  Future<void> sendMessage(String message, {String? imageData, String? imageMime}) async {
    final current = state.valueOrNull ?? [];

    // Optimistic: show user message immediately
    final optimisticUser = ChatMessage(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
      recipeId: recipeId,
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
      imageData: imageData,
      imageMime: imageMime,
    );
    state = AsyncData([...current, optimisticUser]);

    final client = ref.read(apiClientProvider);
    final body = <String, dynamic>{'message': message};
    if (imageData != null) body['imageData'] = imageData;
    if (imageMime != null) body['imageMime'] = imageMime;

    try {
      final data = await client.post(
        '/api/recipes/$recipeId/chat',
        body,
      ) as Map<String, dynamic>;

      Recipe? proposal;
      if (data['proposal'] is Map<String, dynamic>) {
        try {
          proposal = Recipe.fromJson(data['proposal'] as Map<String, dynamic>);
        } catch (_) {}
      }

      // If new proposal arrived, mark all previous unresolved proposals as rejected
      final updated = proposal != null
          ? current.map((m) =>
              m.proposal != null && m.proposalStatus == null
                  ? m.copyWith(proposalStatus: 'rejected')
                  : m).toList()
          : List<ChatMessage>.from(current);

      final assistantMsg = ChatMessage(
        id: data['id'] as String,
        recipeId: recipeId,
        role: 'assistant',
        content: data['text'] as String,
        proposal: proposal,
        createdAt: DateTime.now().toIso8601String(),
      );

      state = AsyncData([...updated, optimisticUser, assistantMsg]);
    } on ApiException catch (e) {
      final errorText = switch (e.statusCode) {
        502 || 503 => 'Ich bin noch in der Küche, bin gleich da! 🍳 Versuch\'s in einem Moment nochmal.',
        500 => 'Hoppla, mir ist etwas aus den Pfoten gefallen. Versuch\'s nochmal!',
        _ => 'Da ist etwas schiefgelaufen (${e.statusCode}). Versuch\'s nochmal!',
      };
      final errorMsg = ChatMessage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        recipeId: recipeId,
        role: 'assistant',
        content: errorText,
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncData([...current, optimisticUser, errorMsg]);
    } catch (_) {
      final errorMsg = ChatMessage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        recipeId: recipeId,
        role: 'assistant',
        content: 'Keine Verbindung zum Server. Netz prüfen und nochmal versuchen!',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncData([...current, optimisticUser, errorMsg]);
    }
  }

  Future<void> applyProposal(String messageId, Recipe proposal) async {
    await ref
        .read(recipeDetailProvider(recipeId).notifier)
        .save(proposal.toJson());
    final client = ref.read(apiClientProvider);
    await client.patch(
      '/api/recipes/$recipeId/chat/$messageId',
      {'proposal_status': 'accepted'},
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current
          .map((m) => m.id == messageId
              ? m.copyWith(proposalStatus: 'accepted')
              : m)
          .toList(),
    );
  }

  Future<void> clearChat() async {
    final client = ref.read(apiClientProvider);
    await client.delete('/api/recipes/$recipeId/chat');
    state = const AsyncData([]);
  }

  Future<void> rejectProposal(String messageId) async {
    final client = ref.read(apiClientProvider);
    await client.patch(
      '/api/recipes/$recipeId/chat/$messageId',
      {'proposal_status': 'rejected'},
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current
          .map((m) => m.id == messageId
              ? m.copyWith(proposalStatus: 'rejected')
              : m)
          .toList(),
    );
  }
}
