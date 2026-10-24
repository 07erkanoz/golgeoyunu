// Yol gösteren gölge: hareketli önizleme kareleri.
// `BOLUM=0 flutter test tools/preview/yol_goster_test.dart`
// → build/preview/yol_<bölüm>_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/guide.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/maps.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('yol göster', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    game.onGameResize(Vector2(870, 391));
    final which = Platform.environment['BOLUM'] ?? 'perde';
    final li = which == 'nemrut'
        ? levels.indexWhere((d) => identical(d.map, kMapNemrut))
        : 0;
    game.debugLoadLevel(li);
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    final at = which == 'nemrut' ? Vector2(56, 19) : Vector2(114, 9);
    p.position.setFrom(
      Level.standOn(at * kTile, Player.w, Player.h),
    );
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    var k = 0;
    Future<void> shot() async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/yol_${which}_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    run(3);
    final t = game.guide.debugNext()!;
    // ignore: avoid_print
    print('hedef ${t.key} ${t.hint}');
    // Önce kamera gösterir (1. basamak), sonra gölge (2. basamak).
    game.guide
      ..stuck = Guide.showAfter + 0.1
      ..current = t;
    for (var i = 0; i < 40; i++) {
      run(0.1);
      await shot();
    }
    game.guide.stuck = Guide.walkAfter + 0.1;
    for (var i = 0; i < 110; i++) {
      run(0.1);
      await shot();
    }
  });
}
