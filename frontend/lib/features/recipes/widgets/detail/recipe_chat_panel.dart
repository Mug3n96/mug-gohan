import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../chat/chat_sheet.dart';

class RecipeChatPanel extends ConsumerWidget {
  const RecipeChatPanel({
    super.key,
    required this.open,
    required this.recipeId,
    required this.onClose,
  });

  final bool open;
  final String recipeId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = MediaQuery.of(context).size;
    final hasMessages = ref
            .watch(chatNotifierProvider(recipeId))
            .valueOrNull
            ?.isNotEmpty ??
        false;
    final panelHeight = hasMessages
        ? (screen.height * 0.5).clamp(200.0, 480.0)
        : (screen.height * 0.75).clamp(300.0, 680.0);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      left: 12,
      right: 12,
      bottom: open ? 8 : -(panelHeight + 16),
      height: panelHeight,
      child: ChatSheet(
        recipeId: recipeId,
        onProposalAccepted: () {},
        onClose: onClose,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class EmbeddedRecipeChatPanel extends ConsumerWidget {
  const EmbeddedRecipeChatPanel({
    super.key,
    required this.recipeId,
    required this.onClose,
  });

  final String recipeId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      child: ChatSheet(
        recipeId: recipeId,
        onProposalAccepted: () {},
        onClose: onClose,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
