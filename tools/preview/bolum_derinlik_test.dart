// Renk ve derinlik denemesinin öteki bölümlerdeki hali: Kar Yolu, Peri
// Bacaları, Konya; ışık-derinlik kapalı ve açık.
// `flutter test tools/preview/bolum_derinlik_test.dart` →
// build/preview/derinlik_<bölüm>_<yok|isik>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

/// (ad, bölüm, oyuncunun başlangıçtan kaç sütun ilerde durduğu)
const _yerler = [
  ('karyolu', 8, 14.0),
  ('karyolu2', 8, 40.0),
  ('peri', 11, 14.0),
  ('peri2', 11, 44.0),
  ('konya', 13, 14.0),
  ('konya2', 13, 38.0),
];

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final (ad, lv, sutun) in _yerler) {
    for (final real in [false, true]) {
      final name = 'derinlik_${ad}_${real ? 'isik' : 'yok'}';
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        Cartoon.on = true;
        Realism.on = real;
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(lv);
        await game.ready();
        game.cinematic = false;
        final p = game.player!;
        final x = p.position.x / kTile + sutun;
        p.position.setFrom(
          Level.standOn(
            Vector2(x * kTile, p.position.y - 2 * kTile),
            Player.w,
            Player.h,
          ),
        );
        game.debugCloseUp = 1.55;
        for (var i = 0; i < 90; i++) {
          game.update(1 / 60);
        }
        game.narration.resetScene();
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(1280, 720);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        Cartoon.on = false;
        Realism.on = false;
      });
    }
  }
}
