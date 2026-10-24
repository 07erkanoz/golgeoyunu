// S1a · Utangaç gölge (Yerebatan): koşup birden durunca gölge iki adım daha
// gider, döner, utangaçça geri gelir. `flutter test tools/preview/utangac_golge_test.dart`
// → build/preview/utangac_<n>.png
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
  testWithGame<GolgeGame>('utangaç gölge', GolgeGame.new, (game) async {
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
    // İlk kontrol noktasından sonra düz taş yol.
    p.position.setFrom(
      Level.standOn(Vector2(32 * kTile.toDouble(), 13 * kTile.toDouble()), Player.w, Player.h),
    );
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    var k = 0;
    Future<void> shot() async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      final at = game.camera.localToGlobal(p.center);
      c.translate(-at.x + 160, -at.y + 110);
      game.render(c);
      final img = await rec.endRecording().toImage(320, 170);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/utangac_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    run(5.0);
    p.position.x = 944;
    run(0.3);
    game.controls.keyboard.right = true;
    run(0.62);
    game.controls.keyboard.right = false;
    var t = 0.0;
    while (!game.secretSeen('utangac') && t < 1) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    // ignore: avoid_print
    print('sürpriz: ${game.secretSeen('utangac')} x ${(p.center.x / kTile).toStringAsFixed(1)} saklı ${p.hidden}');
    for (final d in [0.2, 0.4, 0.5, 0.5, 0.4, 0.4]) {
      run(d);
      // ignore: avoid_print
      print('kare: oyuncu ${p.center.x.toStringAsFixed(0)} yön ${p.facing} ${p.debugShadow}');
      await shot();
    }
  });
}
