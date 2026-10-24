// S1b · Taş bekçi (Nemrut): dört poz yakından.
// `flutter test tools/preview/tas_bekci_test.dart` → build/preview/bekci_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/surprises.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('taş bekçi', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(
      levels.indexWhere((d) => d.surprises.any((s) => s.$1 == 'tasBekci')),
    );
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    final statue = game.world.children.whereType<TasBekci>().first;
    p.position.setFrom(
      Level.standOn(
        Vector2(statue.position.x - 2 * kTile, statue.position.y - kTile),
        Player.w,
        Player.h,
      ),
    );
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    for (var k = 0; k < 4; k++) {
      statue.pose = k;
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      final at = game.camera.localToGlobal(statue.position);
      c.translate(-at.x + 110, -at.y + 120);
      game.render(c);
      final img = await rec.endRecording().toImage(200, 150);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/bekci_$k.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
