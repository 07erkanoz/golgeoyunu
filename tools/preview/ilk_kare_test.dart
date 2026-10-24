// Perdeden oyuna geçiş: bölüm kurulduktan sonraki ilk karelerin süresi
// (önbelleklerin dolduğu, uzak katmanların pişirildiği anlar).
// `flutter test tools/preview/ilk_kare_test.dart`
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  for (final li in [2, 3, 4, 5]) {
    testWithGame<GolgeGame>('ilk kare $li', GolgeGame.new, (game) async {
      Realism.on = true;
      game.onGameResize(Vector2(870, 391));
      // Önce başka bir bölüm (önbellekler o bölüme göre dolu).
      game.debugLoadLevel(li - 1);
      await game.ready();
      for (var i = 0; i < 3; i++) {
        game.update(1 / 60);
        final r = ui.PictureRecorder();
        game.render(ui.Canvas(r));
        final pic = r.endRecording();
        (await pic.toImage(870, 391)).dispose();
      }
      final swp = Stopwatch()..start();
      game.debugPrewarm(li);
      // ignore: avoid_print
      print('HAZIRLIK $li ${swp.elapsedMilliseconds}ms');
      final sw = Stopwatch()..start();
      game.debugLoadLevel(li);
      await game.ready();
      final build = sw.elapsedMilliseconds;
      // İlk karede bileşen bileşen çizim süresi.
      game.update(1 / 60);
      final costs = <(String, int)>[];
      void timeIt(String name, void Function(ui.Canvas) f) {
        final r = ui.PictureRecorder();
        final c = ui.Canvas(r);
        final s3 = Stopwatch()..start();
        f(c);
        costs.add((name, s3.elapsedMicroseconds));
        r.endRecording().dispose();
      }

      timeIt('arkaplan', (c) => game.camera.backdrop.renderTree(c));
      for (final ch in game.world.children.toList()) {
        timeIt(ch.runtimeType.toString(), (c) => ch.renderTree(c));
      }
      for (final ch in game.camera.viewport.children.toList()) {
        timeIt('hud:${ch.runtimeType}', (c) => ch.renderTree(c));
      }
      costs.sort((a, b) => b.$2.compareTo(a.$2));
      // ignore: avoid_print
      print(
        'PAHALI $li ${costs.take(6).map((e) => '${e.$1} ${(e.$2 / 1000).toStringAsFixed(1)}ms').join(', ')}',
      );
      final frames = <String>[];
      for (var i = 0; i < 6; i++) {
        final s2 = Stopwatch()..start();
        game.update(1 / 60);
        final r = ui.PictureRecorder();
        game.render(ui.Canvas(r));
        final pic = r.endRecording();
        final rec = s2.elapsedMilliseconds;
        (await pic.toImage(870, 391)).dispose();
        frames.add('$rec/${s2.elapsedMilliseconds}');
      }
      // ignore: avoid_print
      print(
        'İLK $li ${levels[li].title.padRight(20)} kurulum ${build}ms  kareler (kayıt/ızgara) ${frames.join(' ')}',
      );
    });
  }
}
