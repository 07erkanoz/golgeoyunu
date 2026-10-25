// VIII · Gün Doğumu uzatması: Şafağın Gölgeleri (şafakta ve kuşlukta) ve
// Düşmüş Başlar. `flutter test tools/preview/gun_dogumu_uzatma_test.dart`
// → build/preview/gd_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/dawn.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('gün doğumu uzatma', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(7);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    final dawn = game.world.children.whereType<DawnShadows>().single;
    var n = 0;
    Future<void> at(double c, {double? rise, double run = 0.4}) async {
      dawn.debugRise = rise;
      p.position.setFrom(
        Level.standOn(
          Vector2(c * kTile, 19 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      game.debugSnapCamera();
      for (var i = 0; i < (run * 60).round(); i++) {
        game.update(1 / 60);
        if (p.isDead) {
          // ignore: avoid_print
          print('öldü $c ${p.deathCause}');
          break;
        }
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/gd_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await at(150, rise: 0);
    await at(150, rise: 0.7);
    await at(212);
    await at(245);
  });
}
