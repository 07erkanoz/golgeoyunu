// Gölge oyunları: Sâye durunca gölgesi hayvanlara dönüşür.
// `flutter test tools/preview/golge_oyunu_test.dart`
// → build/preview/golge_oyunu.png (her hayvan iki anda)
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
  testWithGame<GolgeGame>('gölge oyunları', GolgeGame.new, (game) async {
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
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    const cw = 300.0, ch = 170.0;
    final kinds = ShadowAnimal.values;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    p.position.setFrom(
      Level.standOn(
        Vector2(23 * kTile.toDouble(), 13 * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    run(2);
    for (var i = 0; i < kinds.length; i++) {
      run(1);
      expect(p.shadowPlay(kinds[i]), isTrue);
      for (var j = 0; j < 3; j++) {
        run(j == 0 ? 0.35 : (j == 1 ? 1.0 : 1.1));
        game.narration.resetScene();
        c.save();
        c.translate(j * cw, i * ch);
        c.clipRect(const ui.Rect.fromLTWH(0, 0, cw, ch));
        final at = game.camera.localToGlobal(p.center);
        c.translate(-at.x + cw / 2, -at.y + ch * 0.62);
        game.render(c);
        c.restore();
      }
      // Oyun kendi kendine de başlayabilir (Sâye duruyor): bitmesini bekle.
      for (var t = 0; t < 200 && p.shadowPlaying; t++) {
        run(0.1);
      }
      expect(p.shadowPlaying, isFalse);
    }
    final img = await rec.endRecording().toImage(
      (cw * 3).toInt(),
      (ch * kinds.length).toInt(),
    );
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/golge_oyunu.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
