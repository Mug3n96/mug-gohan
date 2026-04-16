import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
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
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
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
                    Icon(Icons.picture_as_pdf,
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
              // Pill group: text field + camera + file menu
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
                          // Camera – nur auf Mobile (nativ + mobile Web)
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
                          // File icon mit Popup-Menü
                          Builder(
                            builder: (ctx) => InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                final box =
                                    ctx.findRenderObject()! as RenderBox;
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
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
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
