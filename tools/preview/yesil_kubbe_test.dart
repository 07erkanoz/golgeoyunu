// XX · Yeşil Kubbe: dört alanın görüntüsü.
// `flutter test tools/preview/yesil_kubbe_test.dart` → build/preview/yk_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/final.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/konya.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('yeşil kubbe', GolgeGame.new, (game) async {
    KandilciBasi.debugHarmless = true;
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(19);
    await game.ready();
    game.cinematic = false;
    // Önizleme: Kandilciler, fenerler ve sel yakalamasın (görüntü için).
    for (final c in game.world.children.toList()) {
      if (c is Guard || c is GreatLamp || c is LightFlood) {
        c.removeFromParent();
      }
    }
    await game.ready();
    final p = game.player!;
    var n = 0;
    Future<void> at(double c, double r, {double run = 2.5}) async {
      p.position.setFrom(
        Level.standOn(
          Vector2(c * kTile, r * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < (run * 60).round(); i++) {
        game.update(1 / 60);
        if (p.isDead) {
          // ignore: avoid_print
          print('öldü $c,$r: ${p.deathCause} y=${(p.position.y / kTile).toStringAsFixed(1)}');
          break;
        }
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/yk_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    // Avlu: aynalar çevrilince ay ışığı kilide.
    for (final m in game.world.children.whereType<Mirror>()) {
      if (m.col < 70) m.use();
    }
    await at(45, 51);
    // Koridor.
    await at(120, 51);
    // Kubbe tırmanışı.
    await at(212, 35);
    // Final: iki ayna çevrilmiş.
    final ms = game.world.children.whereType<Mirror>().where((m) => m.col > 250);
    for (final m in ms.take(2)) {
      m.use();
    }
    await at(262, 9);
    await at(280, 9, run: 3);
    // Bitiş: üçüncü ayna.
    for (final m in ms.skip(2)) {
      m.use();
    }
    await at(280, 9, run: 1.5);
    await at(280, 9, run: 4);
    final k = game.world.children.whereType<KandilciBasi>().first;
    expect(k.solved, isTrue);
  });
}
