// İşlemci tarafı: kare başına güncelleme (oyun mantığı) ve çizim kaydı
// (ekran kartına gidecek listeyi hazırlama) süresi. Ekran kartı işi dahil
// değil. `flutter test tools/bench/islemci_test.dart`
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/palette.dart';

void main() {
  for (final lv in [0, 5, 11, 13]) {
    testWithGame<GolgeGame>('islemci $lv', GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(lv);
      await game.ready();
      game.cinematic = false;
      final keys = game.controls.keyboard;
      final up = <double>[];
      final rec = <double>[];
      for (var f = 0; f < 600; f++) {
        keys.right = (f ~/ 120).isEven;
        keys.left = !keys.right;
        game.cinematic = false;
        final sw = Stopwatch()..start();
        game.update(1 / 60);
        final a = sw.elapsedMicroseconds;
        final r = ui.PictureRecorder();
        game.render(ui.Canvas(r));
        r.endRecording().dispose();
        final b = sw.elapsedMicroseconds;
        if (f >= 60) {
          up.add(a / 1000);
          rec.add((b - a) / 1000);
        }
      }
      double pct(List<double> l, double q) =>
          (l.toList()..sort())[(l.length * q).floor()];
      // ignore: avoid_print
      print(
        'bölüm $lv  güncelleme ortanca ${pct(up, 0.5).toStringAsFixed(2)} '
        '%95 ${pct(up, 0.95).toStringAsFixed(2)} ms  |  kayıt ortanca '
        '${pct(rec, 0.5).toStringAsFixed(2)} %95 ${pct(rec, 0.95).toStringAsFixed(2)} ms',
      );
    });
  }
}
