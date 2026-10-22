// Perdelerin kahraman satırları ve ana iplik: build/preview/k_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

void main() {
  test('kahraman tasvirleri', () async {
    Directory('build/preview').createSync(recursive: true);
    const shots = {
      'k01_hezarfen': (PerdeScene.galata, 1.5),
      'k02_hezarfen_ucar': (PerdeScene.galata, 3.5),
      'k03_lagari': (PerdeScene.skyroad, 1.5),
      'k04_tulpar': (PerdeScene.skyroad, 5.5),
      'k05_hudhud': (PerdeScene.kaf, 2.5),
      'k06_simurg': (PerdeScene.kaf, 4.5),
      'k07_ayna': (PerdeScene.mirror, 1.5),
      'k08_hakob': (PerdeScene.mirror, 4.5),
      'k09_ayaz': (PerdeScene.mirror, 5.5),
      'k10_nuh': (PerdeScene.flood, 2.5),
      'k11_akana': (PerdeScene.flood, 5.6),
      'k12_antiochos': (PerdeScene.gods, 1.5),
      'k13_nemrud': (PerdeScene.dawn, 1.5),
      'k14_sivrisinek': (PerdeScene.dawn, 3.5),
      'k15_tepegoz': (PerdeScene.dawn, 5.5),
      'k16_usta': (PerdeScene.caravan, 1.5),
      'k17_gokboru': (PerdeScene.caravan, 5.5),
      'k18_ejderler': (PerdeScene.dragons, 1.5),
      'k19_dervis': (PerdeScene.dragons, 2.5),
      'k20_ejder_uyanir': (PerdeScene.avalanche, 1.5),
      'k21_peri': (PerdeScene.fairies, 2.5),
      'k22_albasti': (PerdeScene.fairies, 4.5),
      'k23_dev': (PerdeScene.underground, 2.5),
      'k24_erlik': (PerdeScene.underground, 4.6),
      'k25_mevlana': (PerdeScene.sema, 3.5),
      'k26_kayra': (PerdeScene.akAna, 1.5),
      'k27_ertostuk': (PerdeScene.akAna, 5.5),
      'k28_kormos': (PerdeScene.akAna, 6.5),
      'k29_kam': (PerdeScene.gok, 0.5),
      'k30_ulgen': (PerdeScene.gok, 1.5),
      'k31_huma': (PerdeScene.gok, 3.5),
      'k32_kovalama': (PerdeScene.caravan, 2.6),
    };
    for (final MapEntry(key: name, value: (scene, at)) in shots.entries) {
      final rec = ui.PictureRecorder();
      PerdePainter.paint(
        ui.Canvas(rec),
        const ui.Size(640, 360),
        scene,
        at * 3,
        at,
        1,
      );
      final img = await rec.endRecording().toImage(640, 360);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
