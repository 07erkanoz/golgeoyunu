// Koşan at: Çalkuyruk ve Tulpar'ın dörtnala kareleri, duruş ve sıçrayış.
// `flutter test tools/preview/horse_run_test.dart` → build/gallery/at_kosu.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('at koşusu', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, 1800, 560),
      ui.Paint()..color = const ui.Color(0xFF1A1428),
    );
    for (var i = 0; i < 6; i++) {
      c.save();
      c.translate(150 + i * 290.0, 230);
      c.scale(1.6);
      MythFigures.calkuyruk(c, 1, shape: MythFigures.horseRun(i / 6));
      c.restore();
    }
    for (final (i, w, leap) in [(0, 0.0, 0.0), (1, 1.0, 0.6), (2, 1.0, 1.0)]) {
      c.save();
      c.translate(300 + i * 560.0, 520);
      c.scale(1.6);
      if (i == 2) {
        MythFigures.tulpar(
          c,
          1,
          shape: MythFigures.horseRun(0.3, weight: w, leap: leap),
        );
      } else {
        MythFigures.calkuyruk(
          c,
          1,
          shape: MythFigures.horseRun(0.3, weight: w, leap: leap),
        );
      }
      c.restore();
    }
    final img = await rec.endRecording().toImage(1800, 560);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/at_kosu.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
