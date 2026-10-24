// Perde bulmacasının öğretici geri bildirimi (Yerebatan, telefon boyu):
// kirişte kandilin durakları, ısınan göz, takılınca yerde ayak izi, kapıda
// iki göz. `flutter test tools/preview/perde_ogretici_test.dart`
// → build/preview/ogretici_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    for (final f in ['NotoSans-Regular', 'NotoSans-Italic']) {
      final b = File('/usr/share/fonts/noto/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(b.buffer)));
    }
    await loader.load();
  });
  testWithGame<GolgeGame>('perde öğretici', GolgeGame.new, (game) async {
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
    final perde = game.world.children.whereType<GiantPerde>().firstWhere(
      (g) => g.puzzle,
    );
    final cord = game.world.children.whereType<PerdeCord>().first;
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
      File('build/preview/ogretici_${k++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    void stand(double x) {
      p.position.setFrom(
        Level.standOn(
          Vector2(x - kTile / 2, perde.position.y - kTile),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
    }

    // 1: gölgenin başı göze yaklaşıyor (sıcak), kirişte durak.
    stand(perde.standFor(2) - 70);
    run(1.5);
    await shot();
    // 2: takılan oyuncu: ayak izi doğru durakta.
    for (var i = 0; i < 7; i++) {
      cord.use();
      run(0.1);
    }
    while (perde.stop != perde.goodStop) {
      cord.use();
    }
    stand(perde.standFor(perde.goodStop!) - 3 * kTile);
    run(2);
    await shot();
    // 3: kapı: doğru yerde, iki göz birden.
    stand(perde.standFor(perde.goodStop!));
    var t = 0.0;
    while (!perde.shadowOnMark && t < 4) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    run(0.25);
    // ignore: avoid_print
    print(
      'göz ${perde.shadowOnMark} çözüldü ${perde.solved} durak ${perde.stop} oyuncu ${p.center.x} hedef ${perde.standFor(perde.goodStop!)} çömelik ${p.crouching}',
    );
    await shot();
  });
}
