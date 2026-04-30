import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readBytesFromPath(String path) => File(path).readAsBytes();

String tempAudioPath() => '${Directory.systemTemp.path}/mug_gohan_rec.opus';
