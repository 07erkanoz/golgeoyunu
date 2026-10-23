// Yerebatan'ın kuyusu telefonda: vana çevrilince su çekilir; kamera yüzeyi
// izler, dibe varınca halkalar yayılır.
// `flutter test tools/preview/kuyu_test.dart` → build/preview/kuyu_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';
import 'package:golge/game/entities.dart';

void main() {
  testWithGame<GolgeGame>('kuyu', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    // Önizlemede Kandilci'ler çıkarılır (Sâye kuyunun başında beklerken
    // yakalanmasın).
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(Vector2(159 * kTile, 9 * kTile), Player.w, Player.h),
    );
    for (var i = 0; i < 180; i++) {
      game.update(1 / 60);
    }
    final basin = game.world.children.whereType<WaterBasin>().first;
    game.world.children
        .whereType<Valve>()
        .firstWhere((v) => !v.fill)
        .use();
    var n = 0;
    Future<void> shot() async {
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/preview/kuyu_${n++}.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    }

    await shot();
    var t = 0.0;
    while ((basin.moving || t < 0.5) && t < 20) {
      game.update(1 / 60);
      t += 1 / 60;
      if ((t - 4).abs() < 1 / 120) await shot();
    }
    for (var i = 0; i < 20; i++) {
      game.update(1 / 60);
    }
    await shot();
    // ignore: avoid_print
    print(
      'çekilme ${t.toStringAsFixed(1)} sn, halkalar ${basin.settledFlash}, '
      'yüzey ${basin.surface.toStringAsFixed(0)} hedef ${basin.target}, '
      'ölü ${p.isDead} hazne takılı ${basin.isMounted}',
    );
  });
}
