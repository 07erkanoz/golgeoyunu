// Efsane kartı ve hikâye satırı aynı anda: üst üste binmezler.
// `flutter test tools/preview/kart_ve_satir_test.dart` → build/preview/kart_ve_satir_<alt|ust>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final cardFirst in [true, false]) {
    final name = 'kart_ve_satir_${cardFirst ? 'kart_once' : 'satir_once'}';
    testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      for (var i = 0; i < 420; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      const line =
          'Sâye ak gövdeli ağaca dokundu; dallardaki çaputlar rüzgârsız kıpırdadı.';
      if (cardFirst) {
        game.meetMyth('umay');
        game.update(0.1);
        game.narration.whisper(line);
      } else {
        game.narration.whisper(line);
        game.update(0.1);
        game.meetMyth('umay');
      }
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}
