// Kandilci yolu önizlemesi (Gökyolu, telefon boyu): sönük yol; fenerci
// ateşböceğine dalınca soğuk ışıkta beliren yol; Sâye yolda.
// `flutter test tools/preview/kandilci_yolu_test.dart` → build/preview/yol_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('Kandilci yolu', GolgeGame.new, (game) async {
    final li = levels.indexWhere((d) => d.coldRuns.isNotEmpty);
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(li);
    await game.ready();
    for (final b in game.world.children.whereType<LanternBalloon>().toList()) {
      b.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    final bridge = game.world.children.whereType<PhasePlank>().firstWhere(
      (k) => k.cold,
    );
    final g = game.world.children.whereType<Guard>().reduce(
      (a, b) =>
          (a.center.x - bridge.position.x).abs() <
              (b.center.x - bridge.position.x).abs()
          ? a
          : b,
    );
    final (col, row, _) = levels[li].coldRuns.first;
    p.position.setFrom(
      Level.standOn(
        Vector2((col - 10) * kTile.toDouble(), (row - 1) * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    game.controls.keyboard.down = true;
    var k = 0;
    Future<void> shot() async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/yol_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    var t = 0.0;
    while ((g.facing > 0 || bridge.position.x - g.center.x < 14 * kTile) &&
        t < 60) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    await shot();
    while ((g.facing < 0 || bridge.position.x - g.center.x > 8 * kTile) &&
        t < 120) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    game.fireflies = 3;
    game.releaseFirefly(p.light.$1, 1);
    for (var i = 0; i < 150; i++) {
      game.update(1 / 60);
    }
    await shot();
    game.controls.keyboard.down = false;
    game.controls.keyboard.right = true;
    for (var i = 0; i < 52; i++) {
      game.update(1 / 60);
    }
    await shot();
  });
}
