// IV · Kaf uzatması: Hayret Vadisi (aynalı göl, durgun ve dalgalı) ve
// Otuz Kuş (kuşlardan köprü). `flutter test tools/preview/kaf_uzatma_test.dart`
// → build/preview/kaf_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kaf_vadi.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('kaf uzatma', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(3);
    await game.ready();
    game.cinematic = false;
    for (final c in game.world.children.toList()) {
      if (c is Guard || c is Watcher) c.removeFromParent();
    }
    await game.ready();
    var n = 0;
    Future<void> at(double c, double r, {double? wave}) async {
      final p = game.player!;
      final lake = game.world.children.whereType<MirrorLake>().single;
      p.position.setFrom(
        Level.standOn(Vector2(c * kTile, r * kTile), Player.w, Player.h),
      );
      game.debugSnapCamera();
      for (var i = 0; i < 24; i++) {
        game.update(1 / 60);
        if (p.isDead) {
          // ignore: avoid_print
          print('öldü $c,$r ${p.deathCause} ${p.position / kTile}');
          break;
        }
      }
      if (wave != null) lake.debugTime = wave;
      game.update(1 / 60);
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/kaf_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await at(142, 16, wave: 1);
    await at(142, 16, wave: MirrorLake.period - MirrorLake.ripple / 2);
    await at(271, 17);
    await at(271, 17);
  });
}
