// Ötüken'de davul kökleri ışık huzmelerinin önünde seçiliyor mu.
// `flutter test tools/preview/orman_kok_test.dart` → build/preview/orman_kok.png
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
  testWithGame<GolgeGame>('orman kökleri', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(1000, 450));
    game.debugLoadLevel(17);
    await game.ready();
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(
        Vector2(209 * kTile.toDouble(), 39 * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    for (var i = 0; i < 240; i++) {
      game.update(1 / 60);
    }
    game.narration.resetScene();
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(1000, 450);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/orman_kok.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
