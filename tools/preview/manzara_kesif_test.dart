// Manzara anı keşfi: bölümlerin önemli noktalarında kameranın gördüğü.
// `flutter test tools/preview/manzara_kesif_test.dart` → build/preview/kesif_<ad>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

void main() {
  for (final (name, li, c, r) in [
    ('kule', 1, 22, 8),
    ('nemrut', levels.indexWhere((d) => d.map.length == 26 && d.title.contains('NEMRUT')), 300, 10),
  ]) {
    testWithGame<GolgeGame>('keşif $name', GolgeGame.new, (game) async {
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
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/kesif_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
      // ignore: avoid_print
      print('$name bölüm $li ${levels[li].title}');
    });
  }
}
