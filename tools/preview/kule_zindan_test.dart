// II · Kule uzatması: kulenin zindanı (karanlık tırmanış).
// `flutter test tools/preview/kule_zindan_test.dart` → build/preview/kz_<n>.png
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
  testWithGame<GolgeGame>('kule zindan', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(1);
    await game.ready();
    game.cinematic = false;
    var n = 0;
    Future<void> at(double c, double r) async {
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(Vector2(c * kTile, r * kTile), Player.w, Player.h),
      );
      game.debugSnapCamera();
      for (var i = 0; i < 24; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/kz_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await at(6, 209);
    await at(24, 200);
    await at(14, 184);
  });
}
