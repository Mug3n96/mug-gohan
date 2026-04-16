import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import 'proposal_card.dart';

class ChatMessageBubble extends ConsumerWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.recipeId,
    required this.onProposalAccepted,
  });

  final ChatMessage message;
  final String recipeId;
  final VoidCallback onProposalAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = message;
    final isUser = msg.isUser;
    final theme = Theme.of(context);
    final hasProposalCard =
        !isUser && (msg.proposal != null || msg.proposalStatus != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primaryLight
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.hasImage) ...[
                  if (msg.isPdf)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf,
                            color: isUser
                                ? Colors.white70
                                : AppTheme.primaryLight,
                            size: 28),
                        const SizedBox(width: 6),
                        Text('PDF',
                            style: TextStyle(
                                color: isUser
                                    ? Colors.white70
                                    : AppTheme.textSecondary,
                                fontSize: 12)),
                      ],
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(msg.imageData!),
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  if (msg.content.isNotEmpty) const SizedBox(height: 8),
                ],
                if (msg.content.isNotEmpty)
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          if (hasProposalCard) ...[
            const SizedBox(height: 8),
            ChatProposalCard(
              proposal: msg.proposal,
              proposalStatus: msg.proposalStatus,
              onAccept: () async {
                await ref
                    .read(chatNotifierProvider(recipeId).notifier)
                    .applyProposal(message.id, msg.proposal!);
                onProposalAccepted();
              },
              onReject: () => ref
                  .read(chatNotifierProvider(recipeId).notifier)
                  .rejectProposal(message.id),
            ),
          ],
        ],
      ),
    );
  }
}
