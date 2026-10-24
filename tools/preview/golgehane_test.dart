// S2a · Unutulmuş Gölgehane (Yerebatan): girişin ve odanın önizlemesi.
// `flutter test tools/preview/golgehane_test.dart` → build/preview/golgehane_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/golgehane.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gölgehane', GolgeGame.new, (game) async {
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
      File('build/preview/golgehane_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    void put(double col, double row) {
      p.position.setFrom(
        Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
      );
      p.velocity.setZero();
    }

    run(4);
    put(41, 13);
    run(2.5);
    await shot('giris');
    // Sahanlığa iner: perde aralanır.
    put(45.5, 15);
    run(1.4);
    await shot('aralanir');
    final sahne = game.world.children.whereType<GolgehaneSahne>().first;
    // Odada: kandil yakında, gölge dev.
    sahne.lampX = 4 * kTile.toDouble();
    put(55.2, 18);
    p.facing = 1;
    run(1.0);
    await shot('oda_dev');
    put(59.5, 18);
    run(0.6);
    await shot('oda_kucuk');
    // Tasvirler: at koşar, ejder kuyruğunu kovalar.
    sahne.play(1);
    run(2.0);
    await shot('at');
    run(3.0);
    sahne.play(2);
    run(2.2);
    await shot('ejder');
    run(3.0);
    sahne.play(0);
    run(4.5);
    await shot('parca');
    // ignore: avoid_print
    print('parça: ${sahne.pieceT} oynanan ${sahne.played}');
  });
}
