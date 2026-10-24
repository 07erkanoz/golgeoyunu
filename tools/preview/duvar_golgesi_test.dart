// Sâye'nin duvara düşen gölgesi (kapalı mekân): yakın plan.
// `GOLGE=ad flutter test tools/preview/duvar_golgesi_test.dart`
// → build/preview/duvar_golgesi_<ad>_<n>.png
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
  testWithGame<GolgeGame>('duvar gölgesi', GolgeGame.new, (game) async {
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
    final name = Platform.environment['GOLGE'] ?? 'simdi';
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
      c.translate(-at.x + 110, -at.y + 90);
      game.render(c);
      final img = await rec.endRecording().toImage(220, 130);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/duvar_golgesi_${name}_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    p.position.setFrom(
      Level.standOn(
        Vector2(23 * kTile.toDouble(), 13 * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    run(3);
    await shot();
    // Yürürken.
    game.controls.keyboard.right = true;
    run(0.45);
    await shot();
    game.controls.keyboard.right = false;
  });
}
