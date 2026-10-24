// Kamera odağı: perde ipi çekilince kamera ip ile perdeyi tek karede
// gösterir; kol çekilince kapıya gider, açılışı gösterip döner.
// `flutter test tools/preview/kamera_odak_test.dart` → build/preview/odak_<n>.png
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
import 'package:golge/game/puzzles.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('odak', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    var k = 0;
    Future<void> shot() async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/odak_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    final cord = game.world.children.whereType<PerdeCord>().first;
    p.position.setFrom(
      Level.standOn(cord.position - Vector2(0, 20), Player.w, Player.h),
    );
    run(1.5);
    await shot();
    cord.use();
    run(0.8);
    await shot();
    run(1.6);
    await shot();
    final lever = game.world.children.whereType<Lever>().first;
    p.position.setFrom(
      Level.standOn(lever.position - Vector2(0, 20), Player.w, Player.h),
    );
    run(1.5);
    lever.pull();
    run(0.9);
    await shot();
    run(1.4);
    await shot();
    run(1.6);
    await shot();
  });
}
