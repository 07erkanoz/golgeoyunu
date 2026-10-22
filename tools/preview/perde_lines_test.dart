// Her perdenin her satırından bir kare: build/preview/l_<sahne>_<satır>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/perde.dart';

void main() {
  test('perde satırları', () async {
    Directory('build/preview/lines').createSync(recursive: true);
    final acts = <(String, PerdeScene, int)>[
      ('00prolog', PerdeScene.prologue, prologue.length),
      for (var lv = 1; lv < 17; lv++)
        if (interludeScene(lv) != null)
          (
            '${lv.toString().padLeft(2, '0')}${interludeScene(lv)!.name}',
            interludeScene(lv)!,
            interludes[lv].length,
          ),
      ('99son', PerdeScene.epilogue, epilogue.length),
    ];
    for (final (name, scene, n) in acts) {
      for (var k = 0; k < n; k++) {
        final rec = ui.PictureRecorder();
        PerdePainter.paint(
          ui.Canvas(rec),
          const ui.Size(320, 180),
          scene,
          k * 3.0 + 1.5,
          k + 0.55,
          1,
        );
        final img = await rec.endRecording().toImage(320, 180);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/lines/${name}_$k.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }
    }
  });
}
