// Yel'den önce otlar eğilir: durgun, uyarı, esiş.
// `flutter test tools/preview/yel_otlar_test.dart` → build/preview/yel_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/gok_katlari.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';

void main() {
  testWithGame<GolgeGame>('yel otları', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(870, 391));
    final li = levels.indexWhere((d) => d.yel.isNotEmpty);
    game.debugLoadLevel(li);
    await game.ready();
    final z = game.world.children.whereType<YelZone>().first;
    final p = game.player!;
    // Alanın içinde bir zemin bul.
    p.position.setValues(z.area.left + 3 * 32, z.area.top);
    var t = 0.0;
    while (!p.onGround && t < 5) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    var k = 0;
    Future<void> shot() async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/yel_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    // Durgunun sonuna, uyarının ortasına, esişe.
    while (z.warning || z.blowing) {
      game.update(1 / 60);
    }
    await shot();
    while (!z.warning) {
      game.update(1 / 60);
    }
    for (var i = 0; i < 40; i++) {
      game.update(1 / 60);
    }
    await shot();
    while (!z.blowing) {
      game.update(1 / 60);
    }
    for (var i = 0; i < 40; i++) {
      game.update(1 / 60);
    }
    await shot();
    // ignore: avoid_print
    print('bölüm $li alan ${z.area} oyuncu ${p.position}');
  });
}
