// Ötüken'de Karabasan kovalamacası: kare başına güncelleme ve çizim kaydı
// süresi; neşe paketi açık ve kapalı.
// `flutter test tools/bench/karabasan_test.dart`
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/joy.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

void main() {
  for (final joy in [true, false]) {
    testWithGame<GolgeGame>('karabasan neşe=$joy', GolgeGame.new, (
      game,
    ) async {
      joyEnabled = joy;
      Cartoon.on = true;
      Realism.on = true;
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(17);
      await game.ready();
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2(488 * kTile.toDouble(), 39 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      final keys = game.controls.keyboard;
      final up = <double>[];
      final rec = <double>[];
      final ras = <double>[];
      for (var f = 0; f < 900; f++) {
        keys.right = f > 60;
        if (p.isDead) break;
        final sw = Stopwatch()..start();
        game.update(1 / 60);
        final a = sw.elapsedMicroseconds;
        final r = ui.PictureRecorder();
        game.render(ui.Canvas(r));
        final pic = r.endRecording();
        final b = sw.elapsedMicroseconds;
        if (f % 20 == 0 && f > 30) {
          final s2 = Stopwatch()..start();
          final img = await pic.toImage(1280, 720);
          img.dispose();
          ras.add(s2.elapsedMicroseconds / 1000);
        }
        pic.dispose();
        if (f >= 30) {
          up.add(a / 1000);
          rec.add((b - a) / 1000);
        }
      }
      double pct(List<double> l, double q) =>
          (l.toList()..sort())[(l.length * q).floor()];
      double mx(List<double> l) => l.reduce((a, b) => a > b ? a : b);
      // ignore: avoid_print
      print(
        'neşe=$joy x=${(p.center.x / kTile).round()} ölü=${p.isDead} '
        'güncelleme ${pct(up, 0.5).toStringAsFixed(2)} / %95 '
        '${pct(up, 0.95).toStringAsFixed(2)} / en çok ${mx(up).toStringAsFixed(1)} ms | '
        'kayıt ${pct(rec, 0.5).toStringAsFixed(2)} / %95 '
        '${pct(rec, 0.95).toStringAsFixed(2)} / en çok ${mx(rec).toStringAsFixed(1)} ms | '
        'tarama ${pct(ras, 0.5).toStringAsFixed(1)} / en çok ${mx(ras).toStringAsFixed(1)} ms',
      );
    });
  }
}
