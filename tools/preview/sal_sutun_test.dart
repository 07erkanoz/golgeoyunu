// Sal sudaki sütunun ardından geçerken (Yerebatan, telefon boyu): sütun suya
// girip derinde solar; sal da Sâye de ardında kalır.
// `flutter test tools/preview/sal_sutun_test.dart` → build/preview/sal_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

void main() {
  testWithGame<GolgeGame>('sal ve sütun', GolgeGame.new, (game) async {
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
    final lv = game.level;
    final raft = game.world.children.whereType<Raft>().first;
    // Salın yolundaki ilk sudaki sütun.
    final r0 = (raft.position.y / kTile).floor();
    var col = -1;
    for (var c = (raft.position.x / kTile).floor(); c < lv.width; c++) {
      if (lv.cell(c, r0) == 'I' || lv.cell(c, r0 - 1) == 'I') {
        col = c;
        break;
      }
    }
    // ignore: avoid_print
    print('sütun $col raft ${raft.position}');
    Future<void> shot(String name, double dx) async {
      raft.position.x = col * kTile + kTile / 2 - raft.size.x / 2 + dx;
      p.position.setValues(
        raft.position.x + raft.size.x / 2 - Player.w / 2,
        raft.position.y - Player.h - 1,
      );
      p.velocity.setZero();
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/sal_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    await shot('1_ardinda', 0);
    await shot('2_yaninda', 70);
  });
}
