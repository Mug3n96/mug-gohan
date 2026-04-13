import 'recipe_model.dart';

class ChatMessage {
  final String id;
  final String recipeId;
  final String role;
  final String content;
  final Recipe? proposal;
  final String? proposalStatus; // 'accepted' | 'rejected' | null
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.recipeId,
    required this.role,
    required this.content,
    this.proposal,
    this.proposalStatus,
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
        proposalStatus: j['proposal_status'] as String?,
        createdAt: j['created_at'] as String,
      );

  ChatMessage copyWith({String? proposalStatus}) => ChatMessage(
        id: id,
        recipeId: recipeId,
        role: role,
        content: content,
        proposal: proposal,
        proposalStatus: proposalStatus ?? this.proposalStatus,
        createdAt: createdAt,
      );

  bool get proposalAccepted => proposalStatus == 'accepted';
  bool get proposalRejected => proposalStatus == 'rejected';
  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
