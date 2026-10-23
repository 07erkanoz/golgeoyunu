// Ötüken Ormanı önizlemesi: gerçek bölümden kesitler, oyun kamerasıyla.
// `flutter test tools/preview/otuken_test.dart` → build/preview/otuken_N.png
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

Future<void> _shot(GolgeGame game, String name) async {
  game.narration.resetScene();
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  // (ad, sütun, satır, ön koşum saniyesi)
  for (final (name, col, row, warm) in [
    ('otuken_1_esik', 27, 39, 1.5),
    ('otuken_2_ip', 60, 39, 1.0),
    ('otuken_3_kokler', 110, 39, 2.0),
    ('otuken_4_geyik', 233, 39, 1.0),
    ('otuken_5_gecit', 255, 33, 1.0),
    ('otuken_6_bataklik', 356, 39, 1.0),
    ('otuken_7_agac', 405, 30, 1.0),
    ('otuken_8_tepe', 418, 16, 1.0),
    ('otuken_9_kok_isik', 199, 32, 1.5),
    ('otuken_10_agac_dibi', 410, 39, 0.5),
  ]) {
    testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(17);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
      );
      for (var i = 0; i < (warm * 60).round(); i++) {
        game.update(1 / 60);
        if (p.isDead) {
          p.position.setFrom(
            Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
          );
        }
      }
      await _shot(game, name);
      Cartoon.on = false;
      Realism.on = false;
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
