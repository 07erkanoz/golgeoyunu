// Gerilim önizlemesi: karanlıktaki gözler, karanlık bölge, şüphe vinyeti.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

Future<void> shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void step(GolgeGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
  }
}

void put(GolgeGame game, int col, int row) {
  game.player!.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
}

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gerilim önizlemeleri', GolgeGame.new, (game) async {
    Directory('build/preview').createSync(recursive: true);
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    game.debugCloseUp = 1.6;
    put(game, 30, 13);
    step(game, 1.4);
    await shot(game, 'gerilim_gozler');

    put(game, 78, 13);
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    game.fireflies = 1;
    step(game, 7);
    await shot(game, 'gerilim_karanlik_bolge');
  });
}
