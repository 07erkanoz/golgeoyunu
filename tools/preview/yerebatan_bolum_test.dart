// I · Yerebatan: bölüm boyunca her 18 sütunda bir kare.
// `flutter test tools/preview/yerebatan_bolum_test.dart` → build/preview/yb_<n>.png
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
    'yerebatan bölümü',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 6)),
    (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(0);
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
        File('build/preview/yb_${n++}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }

      // Tanıtım kesitleri: Eski Depo ve Fener Dersi.
      for (final c in [30.0, 44.0, 54.0, 64.0, 80.0, 96.0, 110.0, 120.0]) {
        await at(c, 12);
      }
    },
  );
}
