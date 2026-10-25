// III · Gökyolu uzatması: Lodos ile Poyraz, Uçurtmalar.
// `flutter test tools/preview/gokyolu_uzatma_test.dart` → build/preview/gy_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gökyolu uzatma', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(2);
    await game.ready();
    game.cinematic = false;
    var n = 0;
    Future<void> at(double c, double r, {double run = 0.4}) async {
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(Vector2(c * kTile, r * kTile), Player.w, Player.h),
      );
      game.debugSnapCamera();
      for (var i = 0; i < (run * 60).round(); i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/gy_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await at(302, 7, run: 4.6);
    await at(346, 7);
    await at(372, 7, run: 0.2);
  });
}
