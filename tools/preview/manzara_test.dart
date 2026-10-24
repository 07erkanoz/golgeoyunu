// Manzara anları (telefon boyu): Kule'den Haliç, Gün Doğumu, Ötüken vadisi.
// `flutter test tools/preview/manzara_test.dart` → build/preview/manzara_<tür>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  for (var li = 0; li < levels.length; li++) {
    for (final (c, r, kind) in levels[li].vistas) {
      testWithGame<GolgeGame>('manzara $kind', GolgeGame.new, (game) async {
        game.onGameResize(Vector2(870, 391));
        game.debugLoadLevel(li);
        await game.ready();
        final p = game.player!;
        p.position.setFrom(
          Level.standOn(
            Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
            Player.w,
            Player.h,
          ),
        );
        var t = 0.0;
        while ((game.vistaKind == null || game.vistaT < 2.6) && t < 8) {
          game.update(1 / 60);
          t += 1 / 60;
        }
        // ignore: avoid_print
        print('$kind ${game.vistaKind} ${game.vistaT.toStringAsFixed(1)}');
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(870, 391);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/manzara_$kind.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  }
}
