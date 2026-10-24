// Yerebatan'ın dev perdesi telefon oranında: kamera perdeyi bütünüyle
// çerçeveler. `flutter test tools/preview/perde_kamera_test.dart`
// → build/preview/perdekam_<n>.png
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
  testWithGame<GolgeGame>('perde kamerası', GolgeGame.new, (game) async {
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
    final g = game.world.children.whereType<GiantPerde>().firstWhere(
      (g) => g.puzzle,
    );
    var k = 0;
    for (final dx in [0.0, 0.5, 0.95]) {
      p.position.setFrom(
        Level.standOn(
          Vector2(g.position.x + g.size.x * dx, g.position.y - kTile),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < 150; i++) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/perdekam_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
