import 'recipe_model.dart';

class ChatMessage {
  final String id;
  final String recipeId;
  final String role;
  final String content;
  final Recipe? proposal;
  final String? proposalStatus; // 'accepted' | 'rejected' | null
  final String createdAt;
  final String? imageData;   // raw base64, no prefix
  final String? imageMime;   // 'image/jpeg' | 'image/png' | 'application/pdf'

  const ChatMessage({
    required this.id,
    required this.recipeId,
    required this.role,
    required this.content,
    this.proposal,
    this.proposalStatus,
    required this.createdAt,
    this.imageData,
    this.imageMime,
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
        imageData: j['image_data'] as String?,
        imageMime: j['image_mime'] as String?,
      );

  ChatMessage copyWith({String? proposalStatus}) => ChatMessage(
        id: id,
        recipeId: recipeId,
        role: role,
        content: content,
        proposal: proposal,
        proposalStatus: proposalStatus ?? this.proposalStatus,
        createdAt: createdAt,
        imageData: imageData,
        imageMime: imageMime,
      );

  bool get proposalAccepted => proposalStatus == 'accepted';
  bool get proposalRejected => proposalStatus == 'rejected';
  bool get hasImage => imageData != null;
  bool get isPdf => imageMime == 'application/pdf';
  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
