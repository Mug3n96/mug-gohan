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
    final isMobile = screen.width < 600;

    if (isMobile) {
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

    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      right: open ? 0 : -368,
      top: topPad,
      bottom: 0,
      width: 360,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChatSheet(
          recipeId: recipeId,
          onProposalAccepted: () {},
          onClose: onClose,
        ),
      ),
    );
  }
}
