import 'recipe_model.dart';

final _youTubeId = RegExp(
  r'(?:youtube\.com/(?:watch\?(?:[^\s#]*&)?v=|shorts/|live/|embed/)|youtu\.be/)([A-Za-z0-9_-]{11})(?![A-Za-z0-9_-])',
);
final _youTubeLink = RegExp(r'\S*(?:youtube\.com|youtu\.be)/\S*');

/// A linked YouTube video (thumbnail + title shown in the chat).
class ChatVideo {
  final String id;
  final String url;
  final String? title;
  final String thumbnailUrl;
  final bool analyzed;

  const ChatVideo({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    this.title,
    this.analyzed = false,
  });

  factory ChatVideo.fromJson(Map<String, dynamic> j) => ChatVideo(
    id: j['id'] as String,
    url: j['url'] as String,
    title: j['title'] as String?,
    thumbnailUrl: j['thumbnail_url'] as String,
    analyzed: j['analyzed'] as bool? ?? false,
  );

  /// Detects a YouTube link locally, so the thumbnail shows up immediately.
  static ChatVideo? fromText(String text) {
    final id = _youTubeId.firstMatch(text)?.group(1);
    if (id == null) return null;
    return ChatVideo(
      id: id,
      url: 'https://www.youtube.com/watch?v=$id',
      thumbnailUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
    );
  }
}

class ChatMessage {
  final String id;
  final String recipeId;
  final String role;
  final String content;
  final Recipe? proposal;
  final String? proposalStatus; // 'accepted' | 'rejected' | null
  final String createdAt;
  final String? imageData; // raw base64, no prefix
  final String? imageMime; // 'image/jpeg' | 'image/png' | 'application/pdf'
  final ChatVideo? video;

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
    this.video,
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
    video: j['video'] is Map<String, dynamic>
        ? ChatVideo.fromJson(j['video'] as Map<String, dynamic>)
        : null,
  );

  ChatMessage copyWith({String? proposalStatus, ChatVideo? video}) =>
      ChatMessage(
        id: id,
        recipeId: recipeId,
        role: role,
        content: content,
        proposal: proposal,
        proposalStatus: proposalStatus ?? this.proposalStatus,
        createdAt: createdAt,
        imageData: imageData,
        imageMime: imageMime,
        video: video ?? this.video,
      );

  /// Message text without the YouTube link (the link is shown as a card).
  String get displayText => video == null
      ? content
      : content
            .replaceAll(_youTubeLink, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

  bool get proposalAccepted => proposalStatus == 'accepted';
  bool get proposalRejected => proposalStatus == 'rejected';
  bool get hasImage => imageData != null;
  bool get isPdf => imageMime == 'application/pdf';
  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
