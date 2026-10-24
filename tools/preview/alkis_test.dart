// S1c · Gizli alkış: perdenin ardında seyirci gölgeleri.
// `flutter test tools/preview/alkis_test.dart` → build/preview/alkis.png
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
  testWithGame<GolgeGame>('alkış', GolgeGame.new, (game) async {
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
    final perde = game.world.children.whereType<GiantPerde>().firstWhere(
      (g) => g.puzzle,
    );
    p.position.setFrom(
      Level.standOn(
        Vector2(perde.position.x + perde.size.x * 0.4, perde.position.y - kTile),
        Player.w,
        Player.h,
      ),
    );
    perde.solved = true;
    for (var i = 0; i < 90; i++) {
      game.update(1 / 60);
    }
    perde.clapT = 1.1;
    game.controls.keyboard.down = true;
    for (var i = 0; i < 12; i++) {
      game.update(1 / 60);
    }
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(870, 391);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/alkis.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
