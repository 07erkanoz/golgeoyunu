// Kandilci feneri: kayada kesilen huzme (kırpmasız yol kesişimi).
// `flutter test tools/preview/fener_kirpma_test.dart` → build/preview/fener_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('fener', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    for (final g in <Guard>[]) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    Future<void> shot(String name) async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      game.render(c);
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/fener_${Platform.environment['SURUM'] ?? 'yeni'}_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    void put(double col, double row) {
      p.position.setFrom(
        Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
      );
      p.velocity.setZero();
    }

    run(4);
    put(28, 13);
    run(1.5);
    await shot('yerebatan');
    put(80, 13);
    run(1.5);
    await shot('galeri');
  });
}
