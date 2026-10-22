// Kare çizim süresi (yazılım çizici; göreli karşılaştırma için): Yerebatan
// ilk koridor ve su başı; ışık-derinlik ve doku açık/kapalı.
// `flutter test tools/bench/kare_suresi_test.dart`
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

Future<double> _frame(GolgeGame game) async {
  final sw = Stopwatch()..start();
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  await img.toByteData();
  img.dispose();
  return sw.elapsedMicroseconds / 1000;
}

void main() {
  const only = String.fromEnvironment('YER');
  for (final (lv, col, ad) in [
    (0, 28.0, 'yerebatan'),
    (0, 160.0, 'su'),
    (5, 20.0, 'gemi'),
    (5, 60.0, 'gemi2'),
    (5, 110.0, 'gemi3'),
  ]) {
    if (only.isNotEmpty && !ad.startsWith(only)) continue;
    for (final (tag, cartoon, real, off) in [
      ('sade', false, false, ''),
      ('hepsi', true, true, ''),
      ('-uzak', true, true, 'far'),
      ('-isik', true, true, 'light'),
      ('-yakin', true, true, 'near'),
      ('-yansi', true, true, 'reflect'),
    ]) {
      testWithGame<GolgeGame>('$ad $tag', GolgeGame.new, (game) async {
        Cartoon.on = cartoon;
        Realism.on = real;
        Realism.debugNoFar = off == 'far';
        Realism.debugNoLight = off == 'light';
        Realism.debugNoNear = off == 'near';
        Realism.debugNoReflect = off == 'reflect';
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(lv);
        await game.ready();
        game.cinematic = false;
        final p = game.player!;
        p.position.setFrom(
          Level.standOn(
            Vector2(col * kTile, p.position.y - 2 * kTile),
            Player.w,
            Player.h,
          ),
        );
        for (var i = 0; i < 60; i++) {
          game.update(1 / 60);
        }
        for (var i = 0; i < 3; i++) {
          await _frame(game);
        }
        final times = <double>[];
        for (var i = 0; i < 12; i++) {
          game.update(1 / 60);
          times.add(await _frame(game));
        }
        times.sort();
        // ignore: avoid_print
        print(
          '$ad ${tag.padRight(6)} ortanca ${times[6].toStringAsFixed(1)} ms',
        );
        Cartoon.on = false;
        Realism.on = false;
      });
    }
  }
}
