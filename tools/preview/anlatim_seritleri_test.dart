// Anlatımın sabit şeritleri: yer adı, ipucu, efsane kartı ve fısıltı aynı
// anda; masaüstü ve telefon boyutunda, iki yazı büyüklüğüyle.
// `flutter test tools/preview/anlatim_seritleri_test.dart`
// → build/preview/seritler_<boyut>_<yazı>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/settings.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final (label, w, h) in [
    ('masaustu', 1280, 720),
    ('telefon', 844, 390),
  ]) {
    for (final scale in [1.0, 1.4]) {
      final name = 'seritler_${label}_${(scale * 100).round()}';
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        Settings.textScale = scale;
        game.onGameResize(Vector2(w.toDouble(), h.toDouble()));
        game.debugLoadLevel(0);
        await game.ready();
        game.cinematic = false;
        for (var i = 0; i < 420; i++) {
          game.update(1 / 60);
        }
        game.narration.resetScene();
        game.narration.showArea('Sarnıcın Ağzı');
        game.narration.whisper(
          'Sâye ak gövdeli ağaca dokundu; dallardaki çaputlar rüzgârsız '
          'kıpırdadı. Kökler, toprağın altında bir şey söylüyordu.',
        );
        for (var i = 0; i < 72; i++) {
          game.update(1 / 60);
        }
        // İkinci satır beklemeden alta gelir, ilki yukarı kayar.
        game.narration.whisper('Uzakta bir kandil yandı.');
        game.meetMyth('umay');
        game.narration.hint('Işıkta kal: gölge seni ışıkta tutamaz.');
        for (var i = 0; i < 120; i++) {
          game.update(1 / 60);
        }
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(w, h);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  }
}
