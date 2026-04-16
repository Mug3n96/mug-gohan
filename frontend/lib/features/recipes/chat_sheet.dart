import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  // Image/file attachment state
  Uint8List? _pendingImageBytes;
  String? _pendingMime;
  String? _pendingFileName;

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

  Future<void> _pickGalleryImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _pendingImageBytes = bytes;
      _pendingMime = xFile.mimeType ?? 'image/jpeg';
      _pendingFileName = xFile.name;
    });
  }

  Future<void> _takeCameraPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _pendingImageBytes = bytes;
      _pendingMime = xFile.mimeType ?? 'image/jpeg';
      _pendingFileName = xFile.name;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() {
      _pendingImageBytes = bytes;
      _pendingMime = 'application/pdf';
      _pendingFileName = file.name;
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if ((text.isEmpty && _pendingImageBytes == null) || _sending) return;

    String? imageData;
    if (_pendingImageBytes != null) {
      imageData = base64Encode(_pendingImageBytes!);
    }

    _inputCtrl.clear();
    final mime = _pendingMime;
    setState(() {
      _sending = true;
      _pendingImageBytes = null;
      _pendingMime = null;
      _pendingFileName = null;
    });

    // Skip /command handling if there's an image
    if (text.startsWith('/') && imageData == null) {
      await _handleCommand(text);
      return;
    }

    try {
      await ref
          .read(chatNotifierProvider(widget.recipeId).notifier)
          .sendMessage(text, imageData: imageData, imageMime: mime);
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
                    size: 18, color: AppTheme.primaryLight),
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
          _ChatInput(
            controller: _inputCtrl,
            sending: _sending,
            onSend: _send,
            onPickGallery: _pickGalleryImage,
            onPickCamera: _takeCameraPhoto,
            onPickPdf: _pickPdf,
            pendingImageBytes: _pendingImageBytes,
            pendingMime: _pendingMime,
            pendingFileName: _pendingFileName,
            onClearAttachment: () => setState(() {
              _pendingImageBytes = null;
              _pendingMime = null;
              _pendingFileName = null;
            }),
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
                            color: isUser ? Colors.white70 : AppTheme.primaryLight,
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
        color: AppTheme.primaryLight.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high,
                    size: 15, color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                Text(
                  'Vorschlag',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryLight,
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: proposal != null ? onAccept : null,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.primaryLight,
                    ),
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
              size: 40, color: AppTheme.primaryLight.withAlpha(160)),
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

class _ChatInput extends StatefulWidget {
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickPdf,
    required this.pendingImageBytes,
    required this.pendingMime,
    required this.pendingFileName,
    required this.onClearAttachment,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickPdf;
  final Uint8List? pendingImageBytes;
  final String? pendingMime;
  final String? pendingFileName;
  final VoidCallback onClearAttachment;

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment preview
          if (widget.pendingImageBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLight.withAlpha(80)),
              ),
              child: Row(
                children: [
                  if (widget.pendingMime == 'application/pdf')
                    const Icon(Icons.picture_as_pdf,
                        color: AppTheme.primaryLight, size: 36)
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        widget.pendingImageBytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.pendingFileName ?? '',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onClearAttachment,
                  ),
                ],
              ),
            ),
          // WhatsApp-style input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Pill group: text field + file menu + camera
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    color: AppTheme.primaryLight.withAlpha(22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Text field
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Nachricht...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        // Camera icon – nur auf Mobile (nativ + mobile Web)
                        if (!kIsWeb ||
                            defaultTargetPlatform == TargetPlatform.android ||
                            defaultTargetPlatform == TargetPlatform.iOS)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: widget.onPickCamera,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Icon(Icons.camera_alt_outlined,
                                  size: 20, color: AppTheme.textSecondary),
                            ),
                          ),
                        // File icon – InkWell + showMenu für runden Hover
                        Builder(
                          builder: (ctx) => InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final box = ctx.findRenderObject()! as RenderBox;
                              final overlay = Navigator.of(ctx)
                                  .overlay!
                                  .context
                                  .findRenderObject()! as RenderBox;
                              final pos = RelativeRect.fromRect(
                                Rect.fromPoints(
                                  box.localToGlobal(Offset.zero,
                                      ancestor: overlay),
                                  box.localToGlobal(
                                      box.size.bottomRight(Offset.zero),
                                      ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );
                              final result = await showMenu<String>(
                                context: ctx,
                                position: pos,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                items: const [
                                  PopupMenuItem(
                                    value: 'image',
                                    child: Row(children: [
                                      Icon(Icons.image_outlined, size: 18),
                                      SizedBox(width: 10),
                                      Text('Bild'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(children: [
                                      Icon(Icons.picture_as_pdf_outlined,
                                          size: 18),
                                      SizedBox(width: 10),
                                      Text('PDF'),
                                    ]),
                                  ),
                                ],
                              );
                              if (result == 'image') widget.onPickGallery();
                              if (result == 'pdf') widget.onPickPdf();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Icon(Icons.attach_file_rounded,
                                  size: 20, color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mic → Send button
              if (widget.sending)
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, _) {
                    final hasContent = value.text.trim().isNotEmpty ||
                        widget.pendingImageBytes != null;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: IconButton.filled(
                        key: ValueKey(hasContent),
                        onPressed: hasContent
                            ? widget.onSend
                            : () {
                                // TODO: Sprachnachricht
                              },
                        icon: Icon(
                          hasContent
                              ? Icons.send_rounded
                              : Icons.mic_rounded,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
