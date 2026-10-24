// Bölümlerin kare süresi (Dart tarafı: güncelleme + çizim kaydı), haritanın
// birkaç noktasında. `flutter test tools/preview/kare_suresi_test.dart`
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/settings.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  for (var li = 0; li < levels.length; li++) {
    if (levels[li].skiSurface != null) continue;
    testWithGame<GolgeGame>('kare $li', GolgeGame.new, (game) async {
      Settings.lowGraphics = false;
      game.onGameResize(Vector2(870, 391));
      final sw0 = Stopwatch()..start();
      game.debugLoadLevel(li);
      await game.ready();
      final load = sw0.elapsedMilliseconds;
      final p = game.player!;
      final lv = game.level;
      final out = <String>[];
      var worst = 0.0;
      var total = 0.0;
      var n = 0;
      for (final k in [0.1, 0.3, 0.5, 0.7, 0.9]) {
        final c = (lv.width * k).floor();
        p.position.setValues(c * kTile.toDouble(), 2.0 * kTile);
        p.velocity.setZero();
        for (var i = 0; i < 20; i++) {
          game.update(1 / 60);
        }
        final sw = Stopwatch()..start();
        for (var i = 0; i < 30; i++) {
          game.update(1 / 60);
          final rec = ui.PictureRecorder();
          game.render(ui.Canvas(rec));
          rec.endRecording().dispose();
        }
        final ms = sw.elapsedMicroseconds / 1000 / 30;
        worst = ms > worst ? ms : worst;
        total += ms;
        n++;
        out.add(ms.toStringAsFixed(1));
      }
      // ignore: avoid_print
      print(
        'KARE $li ${levels[li].title.padRight(22)} yükleme ${load}ms  '
        'ort ${(total / n).toStringAsFixed(1)}  en kötü ${worst.toStringAsFixed(1)}  [${out.join(' ')}] '
        'bileşen ${game.world.children.length}',
      );
    });
  }
}
