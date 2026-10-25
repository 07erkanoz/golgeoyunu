// XVII · Göğün Katları uzatması: Kuş Yolu (ışık nehri) ve Ülker.
// `flutter test tools/preview/kus_yolu_test.dart` → build/preview/ky_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kus_yolu.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('kuş yolu', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(16);
    await game.ready();
    game.cinematic = false;
    var n = 0;
    Future<void> shot() async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/ky_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    final p = game.player!;
    p.position.setFrom(Level.standOn(Vector2(293 * kTile, 23 * kTile), Player.w, Player.h));
    game.debugSnapCamera();
    game.controls.keyboard.right = true;
    for (var i = 0; i < 60 * 2.2; i++) {
      game.update(1 / 60);
    }
    await shot(); // nehirde
    for (var i = 0; i < 60 * 4; i++) {
      game.update(1 / 60);
      if (p.onGround && p.center.x > 325 * kTile) break;
    }
    game.controls.keyboard.right = false;
    final u = game.world.children.whereType<UlkerCluster>().single;
    for (final s in u.stars.take(4)) {
      p.position.setValues(s.dx - Player.w / 2, s.dy - Player.h / 2);
      game.update(1 / 60);
    }
    p.position.setFrom(Level.standOn(Vector2(328 * kTile, 11 * kTile), Player.w, Player.h));
    p.velocity.setZero();
    for (var i = 0; i < 20; i++) {
      game.update(1 / 60);
    }
    await shot(); // dört yıldız yanmış
    for (final s in u.stars.skip(4)) {
      p.position.setValues(s.dx - Player.w / 2, s.dy - Player.h / 2);
      game.update(1 / 60);
    }
    p.position.setFrom(Level.standOn(Vector2(331 * kTile, 11 * kTile), Player.w, Player.h));
    p.velocity.setZero();
    for (var i = 0; i < 90; i++) {
      game.update(1 / 60);
    }
    await shot(); // köprü
  });
}
