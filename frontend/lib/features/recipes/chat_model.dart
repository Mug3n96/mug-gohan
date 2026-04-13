import 'recipe_model.dart';

class ChatMessage {
  final String id;
  final String recipeId;
  final String role;
  final String content;
  final Recipe? proposal;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.recipeId,
    required this.role,
    required this.content,
    this.proposal,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        recipeId: j['recipe_id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        proposal: j['proposal'] != null
            ? Recipe.fromJson(j['proposal'] as Map<String, dynamic>)
            : null,
        createdAt: j['created_at'] as String,
      );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
