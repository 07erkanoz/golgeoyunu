// Çığ: kayarken çığ ekranda arkada görünür mü.
// `flutter test tools/preview/cig_test.dart` → build/preview/cig_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/maps.dart';
import 'package:golge/game/ski.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('çığ', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(levels.indexWhere((d) => identical(d.skiMarks, kSkiMarksCig)));
    await game.ready();
    var k = 0;
    final p = game.player!;
    final x = game.level.chaseStart! + 3 * 32;
    p.position.x = x;
    p.position.y = (game.skiSurface!.at(x) ?? p.position.y) - 40;
    game.controls.keyboard.right = true;
    for (var s = 0; s < 60; s++) {
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      final av = game.world.children.whereType<Avalanche>();
      if (av.isEmpty || !av.first.awake) continue;
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/cig_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
      // ignore: avoid_print
      print('çığ ${av.first.position.x.toStringAsFixed(0)} oyuncu ${game.player!.center.x.toStringAsFixed(0)} ölü ${game.player!.isDead}');
      if (k >= 4) break;
    }
  });
}
