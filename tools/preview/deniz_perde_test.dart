// Ak Ana'nın Denizi: bölümün perdesi, köprüsü ve Erlik perdesinin açılışı.
// `flutter test tools/preview/deniz_perde_test.dart` → build/preview/dp_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/perde.dart';

Future<void> _shot(String name, void Function(ui.Canvas) paint) async {
  final rec = ui.PictureRecorder();
  paint(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(640, 360);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('deniz perdeleri', () async {
    Directory('build/preview').createSync(recursive: true);
    for (var k = 0; k < interludeText(20).length; k++) {
      await _shot('dp_perde_$k', (c) {
        PerdePainter.paint(c, const ui.Size(640, 360), PerdeScene.akAna,
            (k + 0.6) * 4, k + 0.6, 1);
      });
    }
    for (var k = 0; k < interludeText(14).length; k++) {
      await _shot('dp_erlik_$k', (c) {
        PerdePainter.paint(c, const ui.Size(640, 360), PerdeScene.erlik,
            (k + 0.6) * 4, k + 0.6, 1);
      });
    }
    for (var k = 0; k < bridges[20].length; k++) {
      for (final f in [0.4, 0.8]) {
        await _shot('dp_kopru_${k}_${(f * 10).round()}', (c) {
          PerdePainter.paint(c, const ui.Size(640, 360), PerdeScene.galata,
              (k + f) * 4, k + f, 1, bridge: 20, bridgeLines: 3);
        });
      }
    }
  });
}
