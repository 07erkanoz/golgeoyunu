// Ergenekon'un ritimli ocağı: oklu körük, vuruş korları, daralan halka.
// `flutter test tools/preview/ocak_ritim_test.dart` → build/preview/ocak_ritim.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/ergenekon.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('ocak ritim', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(1000, 450));
    game.debugLoadLevel(15);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(
        Vector2(60 * kTile.toDouble(), 34 * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    final vs = game.world.children.whereType<IronVein>().toList()
      ..sort((a, b) => a.forge.dx.compareTo(b.forge.dx));
    final v = vs.first..lit = true;
    for (var i = 0; i < 180; i++) {
      game.update(1 / 60);
    }
    // İki denk vuruş.
    final a = v.anvil!;
    for (var k = 0; k < 2; k++) {
      while (!a.onBeat) {
        game.update(1 / 60);
      }
      v.activeBellows!.use();
      while (a.onBeat) {
        game.update(1 / 60);
      }
    }
    // Halka daralırken.
    while (a.phase < 0.75) {
      game.update(1 / 60);
    }
    game.narration.resetScene();
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(1000, 450);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/ocak_ritim.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
