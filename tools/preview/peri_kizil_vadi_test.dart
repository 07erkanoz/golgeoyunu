// XII · Peri Bacaları: Kızıl Vadi.
// `flutter test tools/preview/peri_kizil_vadi_test.dart` → build/preview/kv_<n>.png
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
    'peri kizil vadi',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 6)),
    (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(11);
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
        File('build/preview/kv_${n++}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }

      // Kızıl Vadi.
      await at(221, 24, vx: 0);
      await at(250, 24, vx: 0);
    },
  );
}
