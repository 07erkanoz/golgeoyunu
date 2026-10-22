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
      'prolog_umay': (PerdeScene.prologue, 4.5),
      'galata_hezarfen': (PerdeScene.galata, 3.5),
      'galata_saye': (PerdeScene.galata, 5.5),
      'galata_kalabalik': (PerdeScene.galata, 3.5),
      'galata_dagilir': (PerdeScene.galata, 4.6),
      'kaf_kuslar': (PerdeScene.kaf, 1.5),
      'kaf_kirik_gunes': (PerdeScene.kaf, 3.5),
      'tufan_guvercin': (PerdeScene.flood, 2.7),
      'tufan_kandilciler': (PerdeScene.flood, 3.6),
      'nemrut_deprem': (PerdeScene.gods, 2.2),
      'nemrut_gun_dogumu': (PerdeScene.dawn, 2.8),
      'kervan_palan': (PerdeScene.caravan, 1.3),
      'cig': (PerdeScene.avalanche, 1.8),
      'periler': (PerdeScene.fairies, 1.5),
      'periler_bacalar': (PerdeScene.fairies, 3.5),
      'derinkuyu_kesit': (PerdeScene.underground, 2.8),
      'sema': (PerdeScene.sema, 4.5),
      'son_kandil': (PerdeScene.epilogue, 6.5),
      'son_karanlik': (PerdeScene.epilogue, 9.2),
      'son_isik': (PerdeScene.epilogue, 11.3),
      'son_yol': (PerdeScene.epilogue, 13.8),
      'ayna_golge': (PerdeScene.mirror, 1.5),
      'ayna_kandil': (PerdeScene.mirror, 2.6),
      'ayna_agri': (PerdeScene.mirror, 4.2),
      'akana_kayra': (PerdeScene.akAna, 1.3),
      'akana_yukselir': (PerdeScene.akAna, 2.6),
      'akana_dunya': (PerdeScene.akAna, 3.7),
      'akana_isiklar': (PerdeScene.akAna, 4.7),
      'efs_tulpar': (PerdeScene.kaf, 5.5),
      'efs_ayaz': (PerdeScene.mirror, 5.5),
      'efs_akana': (PerdeScene.flood, 5.6),
      'efs_basat': (PerdeScene.dawn, 5.6),
      'efs_gokboru': (PerdeScene.caravan, 5.5),
      'efs_cig': (PerdeScene.avalanche, 4.5),
      'efs_albasti': (PerdeScene.fairies, 4.5),
      'efs_erlik': (PerdeScene.underground, 4.5),
      'efs_konya': (PerdeScene.sema, 5.5),
      'efs_ertostuk': (PerdeScene.akAna, 5.5),
      'efs_kormos': (PerdeScene.akAna, 6.5),
      'erg_kiyan': (PerdeScene.ergenekon, 0.6),
      'erg_vadi': (PerdeScene.ergenekon, 2.5),
      'erg_korukler': (PerdeScene.ergenekon, 3.5),
      'erg_kurt': (PerdeScene.ergenekon, 4.7),
      'erg_ors': (PerdeScene.ergenekon, 5.5),
      'erg_ocak': (PerdeScene.ergenekon, 6.5),
      'erg_demirci': (PerdeScene.ergenekon, 3.5),
      'erg_bozkurt': (PerdeScene.ergenekon, 4.5),
      'erg_kovalama': (PerdeScene.ergenekon, 6.6),
      'gok_kam': (PerdeScene.gok, 0.6),
      'gok_ulgen': (PerdeScene.gok, 1.6),
      'gok_ay_gun': (PerdeScene.gok, 2.6),
      'gok_huma': (PerdeScene.gok, 3.5),
      'gok_yukselis': (PerdeScene.gok, 4.6),
      'son_akana': (PerdeScene.epilogue, 9.5),
      'son_caputlar': (PerdeScene.epilogue, 11.5),
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
