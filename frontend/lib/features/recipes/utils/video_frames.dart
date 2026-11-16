import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// One image YouTube publishes for a video: the thumbnail or one of three
/// automatic scene captures (taken at roughly 25 / 50 / 75 % of the video).
class VideoFrameOption {
  const VideoFrameOption(this.label, this.urls);

  final String label;

  /// Best quality first; not every video has the HD (maxres) versions.
  final List<String> urls;
}

List<VideoFrameOption> videoFrameOptions(String videoId) {
  String url(String name) => 'https://i.ytimg.com/vi/$videoId/$name.jpg';
  return [
    VideoFrameOption('Vorschaubild', [
      url('maxresdefault'),
      url('sddefault'),
      url('hqdefault'),
    ]),
    for (var i = 1; i <= 3; i++)
      VideoFrameOption('Szene $i', [url('maxres$i'), url('sd$i'), url('hq$i')]),
  ];
}

/// Downloads the best available version, cuts off black bars and returns a
/// JPEG data URL for the recipe image.
Future<String> loadFrameAsDataUrl(VideoFrameOption option) async {
  for (final url in option.urls) {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) continue;
    final decoded = img.decodeImage(res.bodyBytes);
    if (decoded == null) continue;
    final jpg = img.encodeJpg(trimBlackBars(decoded), quality: 85);
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  }
  throw Exception('Bild nicht verfügbar');
}

/// Removes letterbox / pillarbox bars (YouTube's 4:3 thumbnails of 16:9
/// videos, Shorts inside 16:9 frames). Leaves (almost) black images alone.
img.Image trimBlackBars(img.Image image, {int threshold = 40}) {
  bool isBar(int index, {required bool row}) {
    final length = row ? image.width : image.height;
    final step = max(1, length ~/ 64);
    var samples = 0;
    var bright = 0;
    for (var i = 0; i < length; i += step) {
      final p = row ? image.getPixel(i, index) : image.getPixel(index, i);
      samples++;
      if (p.r + p.g + p.b > threshold * 3) bright++;
    }
    return bright <= samples ~/ 50; // tolerate JPEG noise / a logo pixel
  }

  var top = 0, bottom = image.height - 1;
  var left = 0, right = image.width - 1;
  while (top < bottom && isBar(top, row: true)) {
    top++;
  }
  while (bottom > top && isBar(bottom, row: true)) {
    bottom--;
  }
  while (left < right && isBar(left, row: false)) {
    left++;
  }
  while (right > left && isBar(right, row: false)) {
    right--;
  }

  final width = right - left + 1;
  final height = bottom - top + 1;
  final unchanged = width == image.width && height == image.height;
  final tooSmall = width < image.width * 0.2 || height < image.height * 0.2;
  if (unchanged || tooSmall) return image;
  return img.copyCrop(image, x: left, y: top, width: width, height: height);
}
