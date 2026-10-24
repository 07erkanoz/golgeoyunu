// Göğün Katları I ve II'den kesitler (gerçek bölümler).
// `flutter test tools/preview/gok_katlari_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

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
  setUpAll(yaziTipiYukle);
  for (final (name, level, col, row, t) in [
    ('gok1_yildiz', 16, 139.0, 21, 3.0),
    ('gok1_kazik', 16, 163.0, 8, 3.0),
    ('gok1_yel', 16, 225.0, 15, 3.9),
    ('gok2_simsek', 18, 112.0, 30, 3.2),
  ]) {
    testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(level);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      final at = Level.standOn(
        Vector2(col * kTile, row * kTile),
        Player.w,
        Player.h,
      );
      for (var i = 0; i < (t * 60).round(); i++) {
        p.position.setFrom(at);
        p.velocity.setZero();
        game.update(1 / 60);
      }
      await _shot(game, name);
      Cartoon.on = false;
      Realism.on = false;
    });
  }
}
