import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Detects MIME type from magic bytes.
String detectMime(Uint8List bytes) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 && bytes[1] == 0x50 &&
      bytes[2] == 0x4E && bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x47 && bytes[1] == 0x49 &&
      bytes[2] == 0x46 && bytes[3] == 0x38) {
    return 'image/gif';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 &&
      bytes[2] == 0x46 && bytes[3] == 0x46) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

/// Resize image to max 1200px width using dart:ui.
Future<Uint8List> resizeImage(Uint8List input) async {
  final codec = await ui.instantiateImageCodec(input, targetWidth: 1200);
  final frame = await codec.getNextFrame();
  final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  return byteData!.buffer.asUint8List();
}

/// Picks an image (web: FilePicker, native: camera/gallery sheet) and returns
/// a data URL string ready for upload, or null if cancelled.
Future<String?> pickRecipeImage(BuildContext context) async {
  Uint8List? bytes;
  String mime = 'image/jpeg';

  if (kIsWeb) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.bytes == null) {
      throw Exception('Bild konnte nicht geladen werden (Datei zu groß?)');
    }
    bytes = f.bytes!;
    mime = detectMime(bytes);
    if (bytes.length > 3 * 1024 * 1024) {
      bytes = await resizeImage(bytes);
      mime = 'image/png';
    }
  } else {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final file = await ImagePicker().pickImage(
        source: source, imageQuality: 80, maxWidth: 1200);
    if (file == null) return null;
    bytes = await file.readAsBytes();
    mime = file.mimeType ?? 'image/jpeg';
  }

  return 'data:$mime;base64,${base64Encode(bytes)}';
}
