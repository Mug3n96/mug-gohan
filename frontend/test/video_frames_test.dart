import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/recipes/utils/video_frames.dart';
import 'package:image/image.dart' as img;

/// 160x90 black frame with a bright [w]x[h] picture in the middle.
img.Image framed(int w, int h) {
  final image = img.Image(width: 160, height: 90);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));
  img.fillRect(
    image,
    x1: (160 - w) ~/ 2,
    y1: (90 - h) ~/ 2,
    x2: (160 - w) ~/ 2 + w - 1,
    y2: (90 - h) ~/ 2 + h - 1,
    color: img.ColorRgb8(200, 120, 60),
  );
  return image;
}

void main() {
  test('removes pillarbox bars (Short inside a 16:9 frame)', () {
    final out = trimBlackBars(framed(50, 90));
    expect([out.width, out.height], [50, 90]);
  });

  test('removes letterbox bars', () {
    final out = trimBlackBars(framed(160, 60));
    expect([out.width, out.height], [160, 60]);
  });

  test('keeps images without bars and (almost) black images', () {
    expect(trimBlackBars(framed(160, 90)).width, 160);
    expect(trimBlackBars(framed(10, 10)).width, 160);
  });

  test('offers thumbnail + 3 scenes, HD first', () {
    final options = videoFrameOptions('dQw4w9WgXcQ');
    expect(options.map((o) => o.label), [
      'Vorschaubild',
      'Szene 1',
      'Szene 2',
      'Szene 3',
    ]);
    expect(
      options[2].urls.first,
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/maxres2.jpg',
    );
    expect(options[2].urls.last, 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hq2.jpg');
  });
}
