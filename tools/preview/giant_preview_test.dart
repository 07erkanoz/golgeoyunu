// Taş devin üç teması: sendeleme, çatlaklar, yıkılış.
// `flutter test tools/preview/giant_preview_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

Future<void> shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/gallery').createSync(recursive: true);
  File('build/gallery/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('dev', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(7);
    await game.ready();
    game.cinematic = false;
    final giant = game.world.children.whereType<StoneGiant>().first;
    game.player!.position.setFrom(
      Level.standOn(
        Vector2(giant.position.x - 6 * kTile, 19 * kTile),
        Player.w,
        Player.h,
      ),
    );
    game.debugCloseUp = 1.6;
    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }
    Future<void> hit() async {
      game.world.add(FireflyLure(giant.ear.clone(), 1));
      for (var i = 0; i < 3; i++) {
        game.update(1 / 60);
      }
    }

    await hit();
    for (var i = 0; i < 40; i++) {
      game.update(1 / 60);
    }
    await shot(game, 'dev1');
    for (var i = 0; i < 200; i++) {
      game.update(1 / 60);
    }
    await hit();
    for (var i = 0; i < 200; i++) {
      game.update(1 / 60);
    }
    await shot(game, 'dev2');
    await hit();
    game.debugCloseUp = 1;
    for (var i = 0; i < 150; i++) {
      game.update(1 / 60);
    }
    await shot(game, 'dev3');
    // ignore: avoid_print
    print('DEV temas=${giant.hits} yıkıldı=${giant.fallen}');
  });
}
