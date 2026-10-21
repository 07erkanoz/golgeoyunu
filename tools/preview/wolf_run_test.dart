// Koşan Ak Kurt (Gökbörü): dörtnala döngüsünden kareler ve sıçrayış.
// `flutter test tools/preview/wolf_run_test.dart` → build/gallery/kurt_kosu.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('kurt koşusu', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, 1800, 520),
      ui.Paint()..color = const ui.Color(0xFF1A2440),
    );
    for (var i = 0; i < 6; i++) {
      c.save();
      c.translate(150 + i * 290.0, 220);
      c.scale(1.6);
      MythFigures.gokboruRun(c, 1, i / 6);
      c.restore();
    }
    for (var i = 0; i < 3; i++) {
      c.save();
      c.translate(300 + i * 560.0, 470);
      c.scale(1.6);
      MythFigures.gokboruRun(c, 1, 0.3, leap: (i + 1) / 3);
      c.restore();
    }
    final img = await rec.endRecording().toImage(1800, 520);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/kurt_kosu.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
