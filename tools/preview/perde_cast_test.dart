// Perde kadrosu: bütün kişiler yan yana: build/preview/cast.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

void main() {
  test('kadro', () async {
    Directory('build/preview').createSync(recursive: true);
    const size = ui.Size(1600, 720);
    final rec = ui.PictureRecorder();
    paintCast(ui.Canvas(rec), size, 0);
    final img = await rec.endRecording().toImage(1600, 720);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/cast.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
