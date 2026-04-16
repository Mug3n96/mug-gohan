import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import 'chat_empty_state.dart';
import 'chat_input.dart';
import 'message_bubble.dart';

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
                SvgPicture.asset(
                  'assets/icons/remy.svg',
                  height: 28,
                  colorFilter: const ColorFilter.mode(AppTheme.primaryLight, BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remy',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (messages) => messages.isEmpty
                  ? ChatEmptyState(onSuggestionTap: (s) {
                      _inputCtrl.text = s;
                      _send();
                    })
                  : ListView.builder(
                      controller: _listCtrl,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => ChatMessageBubble(
                        message: messages[i],
                        recipeId: widget.recipeId,
                        onProposalAccepted: widget.onProposalAccepted,
                      ),
                    ),
            ),
          ),
          ChatInput(
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
