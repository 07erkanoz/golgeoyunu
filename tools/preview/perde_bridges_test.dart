// Köprü sahneleri: her bölümün her satırı: build/preview/bridges/
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/perde.dart';

void main() {
  test('köprüler', () async {
    Directory('build/preview/bridges').createSync(recursive: true);
    for (var lv = 0; lv < bridges.length; lv++) {
      final n = bridges[lv].length;
      for (var k = 0; k < n; k++) {
        for (final f in [0.35, 0.75]) {
          final rec = ui.PictureRecorder();
          PerdePainter.paint(
            ui.Canvas(rec),
            const ui.Size(640, 360),
            PerdeScene.galata,
            (k + f) * 4,
            k + f,
            1,
            bridge: lv,
            bridgeLines: n,
          );
          final img = await rec.endRecording().toImage(640, 360);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          final name = 'b${lv.toString().padLeft(2, '0')}_${k}_${(f * 100).round()}';
          File('build/preview/bridges/$name.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
      }
    }
  });
}
