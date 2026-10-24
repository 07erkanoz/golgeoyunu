// Okunurluk taraması: telefon boyunda birkaç bölümün başlangıç kesiti
// (zemin ve karakter seçiliyor mu).
// `flutter test tools/preview/okunurluk_test.dart` → build/preview/oku_<bölüm>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  for (final lv in [1, 12]) {
    testWithGame<GolgeGame>('okunurluk $lv', GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(870, 391));
      game.debugLoadLevel(lv);
      await game.ready();
      game.controls.keyboard.right = true;
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
      }
      game.controls.keyboard.right = false;
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/oku_$lv.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}
