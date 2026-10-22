// Yaratıklar yakından: karga, asılı yarasalar, Gözcü (Sâye'nin yanına konur).
// `flutter test tools/preview/creatures_test.dart` → build/gallery/yaratiklar.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

void main() {
  testWithGame<GolgeGame>('yaratıklar', GolgeGame.new, (game) async {
    Settings.brightness = 2.6;
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    // Kule'nin zemin katında boş bir yer.
    p.position.setFrom(
      Level.standOn(Vector2(20 * kTile, 13 * kTile), Player.w, Player.h),
    );
    final feet = p.position.y + Player.h;
    final base = Vector2(p.position.x, feet - kTile);
    game.world.addAll([
      Crow(base + Vector2(2 * kTile, 0)),
      BatRoost(Vector2(base.x + 4 * kTile, feet - 4 * kTile)),
      Watcher(Vector2(base.x + 6 * kTile, feet - 2 * kTile)),
    ]);
    game.debugCloseUp = 4.5;
    p.position.x += 0;
    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
    }
    // Kamera yaratıkların ortasına.
    game.camera.viewfinder.position = Vector2(
      base.x + 3.5 * kTile,
      feet - 2 * kTile,
    );
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(1280, 720);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/yaratiklar.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
