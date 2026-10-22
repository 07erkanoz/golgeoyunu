// Yerebatan ilk koridor ve su başı, ışık-derinlik ve doku açık.
// `flutter test tools/preview/kalite_test.dart --dart-define=AD=once`
// → build/preview/kalite_<AD>_<yer>.png
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

const _ad = String.fromEnvironment('AD', defaultValue: 'simdi');

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final (yer, col) in [('koridor', 28.0), ('su', 160.0)]) {
    testWithGame<GolgeGame>('kalite $yer', GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2(col * kTile, p.position.y - 2 * kTile),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/kalite_${_ad}_$yer.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
      Cartoon.on = false;
      Realism.on = false;
    });
  }
}
