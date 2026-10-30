// Yerebatan · Gölge Kapısı: gölge parmaklıktan geçip kolu çekerken.
// `flutter test tools/preview/golge_kapisi_test.dart` → build/preview/gk_<n>.png
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
import 'package:golge/game/shadow_decoy.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gölge kapısı', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(960, 540));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    final stone = game.world.children.whereType<ShadowStone>().single;
    p.position.setFrom(
      Level.standOn(stone.position - Vector2(0, 20), Player.w, Player.h),
    );
    p.facing = 1;
    game.debugSnapCamera();
    Future<void> shot(String n, double secs) async {
      for (var i = 0; i < secs * 60; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(960, 540);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/gk_$n.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await shot('1_tas', 1.0);
    stone.use();
    await game.ready();
    await shot('2_yurur', 1.6);
    final lever = game.world.children.whereType<Lever>().reduce(
      (a, b) =>
          (a.position.x - stone.position.x).abs() <
              (b.position.x - stone.position.x).abs()
          ? a
          : b,
    );
    var t = 0.0;
    while (!lever.pulled && t < 10) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    await shot('3_kol', 0.3);
    await shot('4_kapi', 1.5);
  });
}
