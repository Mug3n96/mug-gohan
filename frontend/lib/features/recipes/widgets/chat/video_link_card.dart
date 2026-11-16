import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/chat_model.dart';

/// Clickable YouTube thumbnail shown in a chat bubble. Opens the video.
class VideoLinkCard extends StatelessWidget {
  const VideoLinkCard({super.key, required this.video, required this.onDark});

  final ChatVideo video;

  /// True inside the (dark) user bubble.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final caption = video.title ?? 'YouTube-Video';
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(video.url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.black26,
                        child: const Icon(Icons.smart_display, size: 40),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 52,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onDark ? Colors.white : null,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
