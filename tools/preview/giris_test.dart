// Bölüm girişlerinin kareleri: düşüş (Yerebatan), süzülüş (Kaf), iniş
// (Göğün Katları), beliriş (Ötüken).
// `flutter test tools/preview/giris_test.dart` → build/preview/giris_<bölüm>_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';

void main() {
  for (final (lv, times) in [
    (0, [0.35, 0.75, 1.15]),
    (3, [0.4, 1.4, 2.6]),
    (16, [0.4, 1.4, 2.6]),
    (17, [0.2, 0.6, 1.0]),
  ]) {
    testWithGame<GolgeGame>('giriş $lv', GolgeGame.new, (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(lv);
      await game.ready();
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      game.debugEntrance();
      await game.ready();
      var t = 0.0;
      var n = 0;
      for (final at in times) {
        while (t < at) {
          game.update(1 / 60);
          t += 1 / 60;
        }
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(1280, 720);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/preview/giris_${lv}_${n++}.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  }
}
