// Yerebatan renk karşılaştırması: orijinal görünüm; orijinal renkler +
// deneme ayrıntıları (ton 0); aynısı ışık ve derinlikle.
// `flutter test tools/preview/renk_karsilastir_test.dart` → build/preview/renk_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final (name, cartoon, real, close) in [
    ('renk_orijinal', false, false, 1.0),
    ('renk_ton0', true, false, 1.0),
    ('renk_ton0_isik', true, true, 1.0),
    ('renk_orijinal_yakin', false, false, 1.9),
    ('renk_ton0_yakin', true, false, 1.9),
    ('renk_ton0_isik_yakin', true, true, 1.9),
  ]) {
    testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
      Cartoon.on = cartoon;
      Cartoon.tone = 0;
      Realism.on = real;
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      final g =
          (game.world.children.whereType<Guard>().toList()
                ..sort((a, b) => a.position.x.compareTo(b.position.x)))
              .first;
      game.player!.position.setFrom(
        Level.standOn(Vector2(28.3 * kTile, g.position.y), Player.w, Player.h),
      );
      game.debugCloseUp = close;
      for (var i = 0; i < 80; i++) {
        game.update(1 / 60);
      }
      g
        ..state = GuardState.patrol
        ..suspicion = 0.3;
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
