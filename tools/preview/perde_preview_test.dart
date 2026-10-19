// Perde sahnelerinin önizlemesi: `flutter test tools/preview` ile
// build/preview/ altına PNG yazar (yazılar hariç: test yazı tipi kutu çizer).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

void main() {
  test('perde önizlemeleri', () async {
    Directory('build/preview').createSync(recursive: true);
    const shots = {
      'prolog_kandilciler': (PerdeScene.prologue, 2.4),
      'prolog_golge_duser': (PerdeScene.prologue, 3.45),
      'galata_hezarfen': (PerdeScene.galata, 1.9),
      'galata_saye': (PerdeScene.galata, 3.5),
      'kaf_kuslar': (PerdeScene.kaf, 1.5),
      'kaf_kirik_gunes': (PerdeScene.kaf, 3.5),
      'final_parca': (PerdeScene.epilogue, 2.6),
      'ayna_golge': (PerdeScene.mirror, 1.6),
      'ayna_kandil': (PerdeScene.mirror, 3.5),
    };
    for (final e in shots.entries) {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      PerdePainter.paint(
        canvas,
        const ui.Size(1280, 720),
        e.value.$1,
        e.value.$2 * 5,
        e.value.$2,
        1,
      );
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/${e.key}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
