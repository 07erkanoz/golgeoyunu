// Kullanma işareti önizlemesi (Yerebatan, telefon boyu): perde ipi uzaktan
// parlar; önüne gelince Sâye'nin başı hizasında "↑" belirir. Kolda da aynı.
// `flutter test tools/preview/isaret_test.dart` → build/preview/isaret_<n>.png
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
import 'package:golge/game/puzzles.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('işaret', GolgeGame.new, (game) async {
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
    Future<void> shot(String name) async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/isaret_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    final cord = game.world.children.whereType<PerdeCord>().first;
    // 1: ipe birkaç kare uzakta: ip parlıyor, işaret yok.
    p.position.setFrom(
      Level.standOn(
        cord.position - Vector2(-3 * kTile, 20),
        Player.w,
        Player.h,
      ),
    );
    run(1.2);
    await shot('1_uzak');
    // 2: ipin önünde: işaret.
    p.position.setFrom(
      Level.standOn(cord.position - Vector2(0, 20), Player.w, Player.h),
    );
    run(0.8);
    await shot('2_ip');
    // 3: kolun önünde.
    final lever = game.world.children.whereType<Lever>().first;
    p.position.setFrom(
      Level.standOn(lever.position - Vector2(0, 20), Player.w, Player.h),
    );
    run(0.8);
    await shot('3_kol');
  });
}
