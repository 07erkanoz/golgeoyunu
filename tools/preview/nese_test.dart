// Neşe paketi önizlemesi: parkurlar (zıpzıp + ışık dizisi), Umay'ın
// kuşları, Karagöz ile Hacivat.
// `flutter test tools/preview/nese_test.dart` → build/preview/nese_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/joy.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

Future<void> save(ui.Picture pic, int w, int h, String name) async {
  final img = await pic.toImage(w, h);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> load(GolgeGame game, int li) async {
  Cartoon.on = true;
  Realism.on = true;
  Cartoon.tone = 0.35;
  game.onGameResize(Vector2(870, 391));
  game.debugLoadLevel(li);
  await game.ready();
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
  return game.player!;
}

void main() {
  setUpAll(yaziTipiYukle);
  for (final li in [5, 13, 17, 11]) {
    testWithGame<GolgeGame>('parkur $li', GolgeGame.new, (game) async {
      final p = await load(game, li);
      final pads = game.world.children.whereType<Bouncer>().toList()
        ..sort((a, b) => a.position.x.compareTo(b.position.x));
      final first = pads.first;
      p.position.setValues(
        first.position.x - Player.w / 2 - 60,
        first.position.y - Player.h,
      );
      run(game, 2);
      p.position.setValues(
        first.position.x - Player.w / 2 - 30,
        first.position.y - first.top - Player.h - 40,
      );
      p.velocity.setValues(Player.runSpeed, 0);
      game.controls.keyboard.right = true;
      // İkinci sıçrayışın tepesi.
      run(game, 1.45);
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      await save(rec.endRecording(), 870, 391, 'nese_parkur_$li');
      run(game, 0.8);
      game.controls.keyboard.right = false;
      run(game, 0.5);
      final rec2 = ui.PictureRecorder();
      game.narration.resetScene();
      game.render(ui.Canvas(rec2));
      await save(rec2.endRecording(), 870, 391, 'nese_parkur_${li}_son');
    });
  }

  testWithGame<GolgeGame>('karagöz', GolgeGame.new, (game) async {
    final p = await load(game, 0);
    final stage = game.world.children.whereType<KaragozSahne>().first;
    p.position.setFrom(
      Level.standOn(
        stage.position - Vector2(kTile * 1.5, kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    var k = 0;
    for (final t in [0.6, 1.5, 2.6, 3.8, 4.4, 5.4, 7.0]) {
      run(game, t - (k == 0 ? -0.9 : [0.6, 1.5, 2.6, 3.8, 4.4, 5.4][k - 1]));
      game.narration.resetScene();
      c.save();
      c.translate((k % 4) * 300.0, (k ~/ 4) * 200.0);
      c.clipRect(const ui.Rect.fromLTWH(0, 0, 300, 200));
      final at = game.camera.localToGlobal(stage.position);
      c.translate(-at.x + 150, -at.y + 150);
      game.render(c);
      c.restore();
      k++;
    }
    await save(rec.endRecording(), 1200, 400, 'nese_karagoz');
  });

  testWithGame<GolgeGame>('kuşlar', GolgeGame.new, (game) async {
    final p = await load(game, 17);
    final cell = game.level.checkpointCells[1];
    p.position.setFrom(
      Level.standOn(cell + Vector2(kTile * 1.0, 0), Player.w, Player.h),
    );
    run(game, 4.2);
    game.narration.resetScene();
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    final at = game.camera.localToGlobal(p.center);
    c.scale(2);
    c.translate(-at.x + 100, -at.y + 60);
    game.render(c);
    await save(rec.endRecording(), 400, 200, 'nese_kuslar');
  });
}
