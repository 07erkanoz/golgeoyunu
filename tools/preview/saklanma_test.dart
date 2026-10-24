// Saklanınca ekran: gri değil koyu; Sâye'nin çevresi seçilir.
// `flutter test tools/preview/saklanma_test.dart` → build/preview/saklanma.png
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
  testWithGame<GolgeGame>('saklanma', GolgeGame.new, (game) async {
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
    final lv = game.level;
    Vector2? spot;
    for (var c = 0; c < lv.width && spot == null; c++) {
      for (var r = 0; r < lv.height; r++) {
        if (lv.cell(c, r) == 'I') {
          spot = Vector2(c * kTile.toDouble(), r * kTile.toDouble());
          break;
        }
      }
    }
    final p = game.player!;
    var rr = (spot!.y / kTile).floor();
    while (rr < lv.height && !lv.solid((spot.x / kTile).floor(), rr + 1)) {
      rr++;
    }
    p.position.setFrom(
      Level.standOn(Vector2(spot.x, rr * kTile.toDouble()), Player.w, Player.h),
    );
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    // ignore: avoid_print
    print('saklı ${p.hidden} ${game.hideAmount.toStringAsFixed(2)}');
    game.hideAmount = 1;
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(870, 391);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/saklanma.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
