// Yerebatan bulmacalarının önizlemesi.
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
  testWithGame<GolgeGame>('bulmaca önizlemeleri', GolgeGame.new, (game) async {
    Directory('build/preview').createSync(recursive: true);
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    game.debugCloseUp = 1.3;
    put(game, 116, 9);
    step(game, 2.2);
    await shot(game, 'bulmaca_dev_perde');

    put(game, 126, 9);
    game.controls.keyboard.right = true;
    for (var i = 0; i < 200 && game.player!.position.x < 130 * kTile; i++) {
      game.update(1 / 60);
    }
    game.controls.keyboard.right = false;
    step(game, 0.3);
    await shot(game, 'bulmaca_isik_tahtasi');
    put(game, 135, 9);
    game.controls.keyboard.down = true;
    step(game, 0.4);
    game.controls.keyboard.right = true;
    for (var i = 0; i < 400 && game.player!.position.x < 138 * kTile; i++) {
      game.update(1 / 60);
    }
    game.controls.keyboard.right = false;
    await shot(game, 'bulmaca_golge_tahtasi');
    game.controls.keyboard.down = false;

    put(game, 143, 9);
    game.controls.keyboard.down = true;
    step(game, 0.6);
    await shot(game, 'bulmaca_curuk_kopru');
    game.controls.keyboard.down = false;

    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    put(game, 159, 9);
    step(game, 0.5);
    await shot(game, 'bulmaca_hazne');
  });
}
