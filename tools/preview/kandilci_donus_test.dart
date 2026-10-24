// Kandilcinin dönüşü kare kare (kâğıt gibi incelmeden döner).
// `flutter test tools/preview/kandilci_donus_test.dart` → build/preview/donus_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/palette.dart';

void main() {
  testWithGame<GolgeGame>('dönüş', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    final g = game.world.children.whereType<Guard>().first;
    final p = game.player!;
    p.position.setValues(g.position.x - 200, g.position.y - 40);
    p.hidden = true;
    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }
    var k = 0;
    Future<void> shot() async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      final at = game.camera.localToGlobal(g.position);
      c.translate(-at.x + 40, -at.y + 60);
      game.render(c);
      final img = await rec.endRecording().toImage(130, 130);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/donus_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await shot();
    g.facing = -g.facing;
    for (var i = 0; i < 6; i++) {
      game.update(0.045);
      await shot();
    }
  });
}
