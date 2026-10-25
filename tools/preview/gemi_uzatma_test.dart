// VI · Nuh'un Gemisi uzatması: Delikli Ambar ve Yalpalayan Ambar.
// `flutter test tools/preview/gemi_uzatma_test.dart` → build/preview/gemi_u<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gemi uzatma', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(5);
    await game.ready();
    game.cinematic = false;
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
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
      File('build/preview/gemi_u${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await at(186, 25);
    await at(204, 25);
    await at(268, 22);
    await at(296, 22, run: 1.5);
  });
}
