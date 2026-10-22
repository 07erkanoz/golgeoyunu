// Yeni taş dev gerçek oyunda: yürür, Sâye'yi görünce kaya atar, üç
// ateşböceğiyle devrilir, köprü olur. `flutter test tools/preview/dev_oyunda_test.dart`
// → build/preview/dev_oyunda/kare_NNN.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/player.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  testWithGame<
    GolgeGame
  >('dev oyunda', GolgeGame.new, timeout: const Timeout(Duration(minutes: 6)), (
    game,
  ) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(7);
    await game.ready();
    game.cinematic = false;
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    final giant = game.world.children.whereType<StoneGiant>().first;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(
        Vector2(giant.position.x - 9 * kTile, 19 * kTile),
        Player.w,
        Player.h,
      ),
    );
    final dir = Directory('build/preview/dev_oyunda');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    const dt = 1 / 12;
    var f = 0;
    var hits = 0;
    var t = 0.0;
    var lastHitT = -10.0;
    Future<void> shot() async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/kare_${(f++).toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    while (t < 26 && f < 330) {
      // Sâye ölmesin diye işaretten uzak durur (test sahnesi).
      if (p.isDead) break;
      for (final m in game.world.children.whereType<ThrowMark>()) {
        if ((m.position.x - p.center.x).abs() < 2 * kTile) {
          p.position.x -= 3 * kTile;
        }
      }
      // 9. saniyeden sonra kulağa ateşböceği.
      if (t > 9 && !giant.fallen && t - lastHitT > 3.2 && giant.earOpen) {
        game.fireflies = 3;
        game.releaseFirefly(giant.ear + Vector2(-50, 8), 1);
        lastHitT = t;
        hits++;
      }
      for (var k = 0; k < 5; k++) {
        game.cinematic = false;
        game.update(dt / 5);
      }
      game.narration.resetScene();
      await shot();
      t += dt;
    }
    // ignore: avoid_print
    print(
      'kare $f, vuruş ${giant.hits}, devrildi ${giant.fallen}, ölü ${p.isDead}',
    );
  });
}
