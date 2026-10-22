// Semâzen: dönüş kareleri (yakın) ve oyun boyunda.
// `flutter test tools/preview/semazen_test.dart` → build/gallery/semazen.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/konya.dart';

void main() {
  test('semazen', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, 1800, 700),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(0, 0),
          const ui.Offset(0, 700),
          const [ui.Color(0xFF1A2236), ui.Color(0xFF0C0A10)],
        ),
    );
    for (var i = 0; i < 6; i++) {
      c.save();
      c.translate(150 + i * 300.0, 430);
      c.scale(5);
      drawSemazen(c, i * 0.55);
      c.restore();
    }
    for (var i = 0; i < 8; i++) {
      c.save();
      c.translate(120 + i * 220.0, 680);
      c.scale(2);
      drawSemazen(c, i * 0.8, alpha: i.isEven ? 1 : 0.6);
      c.restore();
    }
    final img = await rec.endRecording().toImage(1800, 700);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/semazen.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
