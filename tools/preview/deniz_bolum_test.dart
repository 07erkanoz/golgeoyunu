// XV · Ak Ana'nın Denizi: bölümün kesitlerinden kareler.
// `flutter test tools/preview/deniz_bolum_test.dart` → build/preview/db_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>(
    'deniz bölümü',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 6)),
    (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(20);
      await game.ready();
      game.cinematic = false;
      var n = 0;
      Future<void> at(double c, double r, {double vx = 60}) async {
        final p = game.player!;
        p.position.setValues(c * kTile, r * kTile);
        p.velocity.setValues(vx, 0);
        game.debugSnapCamera();
        for (var i = 0; i < 50; i++) {
          game.update(1 / 60);
        }
        game.narration.resetScene();
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(960, 540);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/db_${n++}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }

      await at(4, 3, vx: 0); // kıyı
      await at(36, 15); // sığlık, sandallar
      await at(98, 12); // Yunus Koyu: yunuslar, balık sürüsü
      await at(118, 24); // taş sütunlar, midye
      await at(150, 40); // batık gemi ve sandık
      await at(176, 12); // kayalık sırt, tünel
      await at(196, 3, vx: 0); // adacıktaki Umay ağacı
      await at(214, 34); // ikinci havza, midyeler
      await at(270, 26); // yosun ormanı, fenerbalığı
      await at(250, 8, vx: 0); // hava cebi
      await at(372, 26); // denizanası mağarası
      await at(420, 27); // akıntı koridoru
      await at(495, 12); // Kişi'nin taşı
      await at(535, 55); // karanlık dip
      await at(552, 68); // yarık
    },
  );
}
