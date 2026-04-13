import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'chat_model.dart';
import 'chat_provider.dart';
import 'recipe_model.dart';

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({
    super.key,
    required this.recipeId,
    required this.onProposalAccepted,
    required this.onClose,
    this.borderRadius,
  });

  final String recipeId;
  final VoidCallback onProposalAccepted;
  final VoidCallback onClose;
  final BorderRadiusGeometry? borderRadius;

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {
  final _inputCtrl = TextEditingController();
  final _listCtrl = ScrollController();
  bool _sending = false;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(
          _listCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();

    if (text.startsWith('/')) {
      await _handleCommand(text);
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(chatNotifierProvider(widget.recipeId).notifier)
          .sendMessage(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleCommand(String command) async {
    switch (command.toLowerCase()) {
      case '/clear':
        await ref
            .read(chatNotifierProvider(widget.recipeId).notifier)
            .clearChat();
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unbekannter Befehl: $command')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatNotifierProvider(widget.recipeId));

    // Auto-scroll when new messages arrive
    chatAsync.whenData((msgs) {
      if (msgs.length > _lastMessageCount) {
        _lastMessageCount = msgs.length;
        _scrollToBottom();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: widget.borderRadius ??
            const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'KI-Assistent',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Schließen',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Message list
          Expanded(
            child: chatAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (messages) => messages.isEmpty
                  ? _EmptyChat(onSuggestionTap: (s) {
                      _inputCtrl.text = s;
                      _send();
                    })
                  : ListView.builder(
                      controller: _listCtrl,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _MessageBubble(
                        message: messages[i],
                        recipeId: widget.recipeId,
                        onProposalAccepted: widget.onProposalAccepted,
                      ),
                    ),
            ),
          ),
          const Divider(height: 1),
          _ChatInput(
            controller: _inputCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends ConsumerStatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.recipeId,
    required this.onProposalAccepted,
  });

  final ChatMessage message;
  final String recipeId;
  final VoidCallback onProposalAccepted;

  @override
  ConsumerState<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isUser = msg.isUser;
    final theme = Theme.of(context);
    final hasProposalCard = !isUser &&
        (msg.proposal != null || msg.proposalStatus != null);

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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                color: isUser ? Colors.white : null,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (hasProposalCard) ...[
            const SizedBox(height: 8),
            _ProposalCard(
              proposal: msg.proposal,
              proposalStatus: msg.proposalStatus,
              onAccept: () async {
                await ref
                    .read(chatNotifierProvider(widget.recipeId).notifier)
                    .applyProposal(widget.message.id, msg.proposal!);
                widget.onProposalAccepted();
              },
              onReject: () => ref
                  .read(chatNotifierProvider(widget.recipeId).notifier)
                  .rejectProposal(widget.message.id),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Proposal card ─────────────────────────────────────────────────────────────

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.proposalStatus,
    required this.onAccept,
    required this.onReject,
  });

  final Recipe? proposal;
  final String? proposalStatus; // 'accepted' | 'rejected' | null
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (proposalStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withAlpha(60)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
            SizedBox(width: 6),
            Text('Übernommen',
                style: TextStyle(color: Colors.green, fontSize: 13)),
          ],
        ),
      );
    }

    if (proposalStatus == 'rejected') {
      return Text('Abgelehnt',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppTheme.textSecondary));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high,
                    size: 15, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Vorschlag',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildSummary(context),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: proposal != null ? onAccept : null,
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    child: const Text('Übernehmen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final p = proposal;
    final parts = <String>[];
    if (p != null) {
      if (p.title.isNotEmpty) parts.add(p.title);
      if (p.ingredients.isNotEmpty) parts.add('${p.ingredients.length} Zutaten');
      if (p.steps.isNotEmpty) parts.add('${p.steps.length} Schritte');
    }
    return Text(
      parts.join(' · '),
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: AppTheme.textSecondary),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestionTap});
  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'Beschreibe das Rezept kurz',
    'Welche Zutaten fehlen noch?',
    'Mach mir einen vollständigen Vorschlag',
  ];

  static const _commands = ['/clear'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined,
              size: 40, color: AppTheme.primary.withAlpha(120)),
          const SizedBox(height: 12),
          Text('Wie kann ich helfen?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 16),
          ..._suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => onSuggestionTap(s),
                ),
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: _commands
                .map((c) => ActionChip(
                      avatar: const Icon(Icons.terminal, size: 13),
                      label: Text(c,
                          style: const TextStyle(
                              fontSize: 11, fontFamily: 'monospace')),
                      onPressed: () => onSuggestionTap(c),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ─────────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nachricht...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}
