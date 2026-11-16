import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/recipe_detail_provider.dart';
import '../../utils/video_frames.dart';

/// Lets the user pick the thumbnail or a scene of a YouTube video as the
/// recipe image.
Future<void> showVideoFramePicker(
  BuildContext context, {
  required String videoId,
  required String recipeId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _VideoFramePickerDialog(videoId: videoId, recipeId: recipeId),
  );
}

class _VideoFramePickerDialog extends ConsumerStatefulWidget {
  const _VideoFramePickerDialog({
    required this.videoId,
    required this.recipeId,
  });

  final String videoId;
  final String recipeId;

  @override
  ConsumerState<_VideoFramePickerDialog> createState() =>
      _VideoFramePickerDialogState();
}

class _VideoFramePickerDialogState
    extends ConsumerState<_VideoFramePickerDialog> {
  late final _options = videoFrameOptions(widget.videoId);
  int? _busy;

  Future<void> _adopt(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = index);
    try {
      final dataUrl = await loadFrameAsDataUrl(_options[index]);
      await ref
          .read(recipeDetailProvider(widget.recipeId).notifier)
          .uploadImage(dataUrl);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Rezeptbild übernommen')),
      );
    } catch (e) {
      if (mounted) setState(() => _busy = null);
      messenger.showSnackBar(
        SnackBar(content: Text('Bild konnte nicht übernommen werden: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rezeptbild aus dem Video'),
      content: SizedBox(
        width: 520,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 16 / 9,
          children: [
            for (var i = 0; i < _options.length; i++)
              _FrameTile(
                option: _options[i],
                busy: _busy == i,
                onTap: _busy == null ? () => _adopt(i) : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy == null ? () => Navigator.of(context).pop() : null,
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}

class _FrameTile extends StatelessWidget {
  const _FrameTile({required this.option, required this.busy, this.onTap});

  final VideoFrameOption option;
  final bool busy;
  final VoidCallback? onTap;

  /// Tries each URL in turn (HD first) until one loads.
  Widget _image(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Text('nicht verfügbar', style: TextStyle(fontSize: 12)),
      );
    }
    return Image.network(
      urls.first,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _image(urls.sublist(1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(option.urls),
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    option.label,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              if (busy)
                const ColoredBox(
                  color: Colors.black38,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
