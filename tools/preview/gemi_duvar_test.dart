// Gemi ambarı: arka plan duvarı yürürken ve zıplarken nasıl kayıyor.
// `SURUM=ad flutter test tools/preview/gemi_duvar_test.dart`
// → build/preview/gemi_<ad>_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/maps.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gemi duvarı', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(levels.indexWhere((d) => identical(d.map, kMapGemi)));
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    final name = Platform.environment['SURUM'] ?? 'simdi';
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    var k = 0;
    Future<void> shot() async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/gemi_${name}_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    p.position.setFrom(
      Level.standOn(Vector2(30 * kTile.toDouble(), 25 * kTile.toDouble()),
          Player.w, Player.h),
    );
    run(4);
    await shot(); // 0: duruyor
    game.controls.keyboard.jump = true;
    run(0.1);
    game.controls.keyboard.jump = false;
    run(0.2);
    await shot(); // 1: zıplamanın tepesi
    run(0.8);
    await shot(); // 2: indi
    if (Platform.environment['KARELER'] != null) {
      // Hareketli görüntü için: yürürken saniyede 12 kare, 3 saniye.
      game.controls.keyboard.right = true;
      for (var i = 0; i < 36; i++) {
        run(1 / 12);
        await shot();
      }
      game.controls.keyboard.right = false;
      return;
    }
    game.controls.keyboard.right = true;
    run(0.5);
    await shot(); // 3: yürüyor
    run(0.5);
    await shot(); // 4: yürüyor
    game.controls.keyboard.right = false;
    run(1.5);
    await shot(); // 5: durdu
  });
}
