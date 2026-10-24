// Kaf, Galata ve ayna perdelerinin bütün anları (figür denetimi).
// `flutter test tools/preview/perde_kaf_test.dart` → build/preview/pk_<sahne>_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

void main() {
  test('kaf perdeleri', () async {
    Directory('build/preview').createSync(recursive: true);
    for (final (name, scene, lines) in [
      ('kaf', PerdeScene.kaf, 6),
      ('galata', PerdeScene.galata, 7),
      ('ayna', PerdeScene.mirror, 7),
    ]) {
      for (var i = 0; i < lines * 2; i++) {
        final p = 0.25 + i * 0.5;
        final rec = ui.PictureRecorder();
        PerdePainter.paint(ui.Canvas(rec), const ui.Size(960, 540), scene,
            p * 5, p, 1);
        final img = await rec.endRecording().toImage(960, 540);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/pk_${name}_${i.toString().padLeft(2, '0')}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }
    }
  });
}
