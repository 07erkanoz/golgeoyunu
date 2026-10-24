// Gölgeyi önden göndermek (Derinkuyu, telefon boyu): taş, yürüyen gölge,
// gölgeye dalan Kandilci. `flutter test tools/preview/golge_gonder_test.dart`
// → build/preview/gonder_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shadow_decoy.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gölge gönder', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(levels.indexWhere((d) => d.shadowStones.isNotEmpty));
    await game.ready();
    final p = game.player!;
    final stone = game.world.children.whereType<ShadowStone>().first;
    p.position.setFrom(
      Level.standOn(stone.position - Vector2(0, 20), Player.w, Player.h),
    );
    p.facing = 1;
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
      File('build/preview/gonder_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    run(1.2);
    await shot();
    stone.use();
    run(1.4);
    await shot();
    final g = game.world.children.whereType<Guard>().reduce(
      (a, b) =>
          (a.center.x - stone.position.x).abs() <
              (b.center.x - stone.position.x).abs()
          ? a
          : b,
    );
    var t = 0.0;
    while (!g.distracted && t < 10) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    run(1.0);
    await shot();
  });
}
