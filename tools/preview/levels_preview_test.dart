// Bölüm önizlemeleri: `flutter test tools/preview/levels_preview_test.dart
// --dart-define=SHOTS=3:2:17,3:140:12` gibi (bölüm:sütun:satır).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void main() {
  const spec = String.fromEnvironment('SHOTS', defaultValue: '3:2:17');
  testWithGame<GolgeGame>('bölüm önizlemeleri', GolgeGame.new, (game) async {
    Directory('build/preview').createSync(recursive: true);
    game.onGameResize(Vector2(1280, 720));
    for (final s in spec.split(',')) {
      final parts = s.split(':').map(int.parse).toList();
      game.debugLoadLevel(parts[0]);
      await game.ready();
      game.cinematic = false;
      game.player!.position.setFrom(
        Level.standOn(
          Vector2(parts[1] * kTile, parts[2] * kTile),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/bolum_${s.replaceAll(':', '_')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
