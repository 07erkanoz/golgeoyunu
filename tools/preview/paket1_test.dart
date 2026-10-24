// Paket 1 önizlemesi (Yerebatan, telefon boyu): ayak altı ışığı, iniş
// tozu, koldan kapıya ışık ve kamera bakışı, çürük tahtada çatlak.
// `flutter test tools/preview/paket1_test.dart` → build/preview/paket1_<n>.png
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
  testWithGame<GolgeGame>('paket 1', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    Future<void> shot(String name) async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/paket1_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
      final g = game.camera.localToGlobal(p.center);
      // ignore: avoid_print
      print('KONUM $name ${g.x.round()} ${g.y.round()}');
    }

    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    // 1-2: yüksekten iniş: toz ve ayak altı ışığı.
    final land = Level.standOn(
      Vector2(40 * kTile, 13 * kTile),
      Player.w,
      Player.h,
    );
    p.position.setFrom(land - Vector2(0, 5 * kTile));
    p.velocity.setZero();
    run(0.2);
    var t = 0.0;
    while (!p.onGround && t < 3) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    run(0.08);
    await shot('1_inis');
    run(1.5);
    await shot('2_ayak');
    // 3-4: kol çekilir: ışık kapıya akar, kamera kapıya bakar.
    p.position.setFrom(
      Level.standOn(Vector2(55 * kTile, 9 * kTile), Player.w, Player.h),
    );
    run(1.5);
    game.world.children.whereType<Lever>().first.pull();
    run(0.3);
    await shot('3_kol');
    run(0.9);
    await shot('4_kapi');
    run(2.0);
    // 5: çürük tahtada yürüyüş: çatlaklar ve talaş.
    // Tahta bir güverte: üstüne doğrudan konur.
    p.position.setValues(149 * kTile.toDouble(), 10 * kTile - Player.h - 1);
    p.velocity.setZero();
    run(0.5);
    game.controls.keyboard.right = true;
    run(0.45);
    game.controls.keyboard.right = false;
    game.controls.keyboard.left = true;
    run(0.45);
    game.controls.keyboard.left = false;
    game.controls.keyboard.right = true;
    run(0.4);
    game.controls.keyboard.right = false;
    await shot('5_tahta');
  });
}
