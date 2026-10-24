// Yumuşak ışık önizlemesi (Yerebatan, telefon boyu): Sâye'nin ışığı kayanın
// kenarında yarı gölgeyle kesilir; fenerci ve Medusa huzmelerinin ucu ve
// yanı yumuşak. `flutter test tools/preview/yumusak_isik_test.dart`
// → build/preview/isik_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('yumuşak ışık', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    final p = game.player!;
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    Future<void> shot(String name) async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/isik_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    void place(Vector2 at) {
      p.position.setFrom(at);
      p.velocity.setZero();
    }

    // 1: yüksek bloğun kenarı (kol): ışık bloğun altına yarı gölgeyle düşer.
    final guards = game.world.children.whereType<Guard>().toList();
    for (final g in guards) {
      g.removeFromParent();
    }
    await game.ready();
    final lever = game.world.children.whereType<Lever>().first;
    place(
      Level.standOn(
        lever.position - Vector2(-kTile * 0.4, 20),
        Player.w,
        Player.h,
      ),
    );
    run(1.5);
    // ignore: avoid_print
    print('kenar ${p.position} ${p.onGround}');
    await shot('1_kenar');
    SoftEdge.force = false;
    SoftEdge.on = false;
    game.render(ui.Canvas(ui.PictureRecorder()));
    final r1 = ui.PictureRecorder();
    game.render(ui.Canvas(r1));
    final i1 = await r1.endRecording().toImage(870, 391);
    File('build/preview/isik_1b.png').writeAsBytesSync(
      (await i1.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    SoftEdge.force = null;
    SoftEdge.on = true;
    // 2: fenerci huzmesi.
    final g = guards.first;
    game.world.add(g);
    await game.ready();
    place(g.position + Vector2(-g.facing * 2 * kTile, g.size.y - Player.h - 2));
    run(1.5);
    // ignore: avoid_print
    print(
      'fenerci ${g.position} oyuncu ${p.position} ${p.onGround} yön ${g.facing}',
    );
    await shot('2_fenerci');
    SoftEdge.force = false;
    SoftEdge.on = false;
    game.render(ui.Canvas(ui.PictureRecorder()));
    final rec2 = ui.PictureRecorder();
    game.render(ui.Canvas(rec2));
    final im2 = await rec2.endRecording().toImage(870, 391);
    File('build/preview/isik_2b.png').writeAsBytesSync(
      (await im2.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    SoftEdge.force = null;
    // 3: Medusa gözü açıkken.
    final m = game.world.children.whereType<MedusaHead>().first;
    // ignore: avoid_print
    print('medusa ${m.position} yön ${m.facing}');
    place(m.position + Vector2(m.facing * 9 * kTile, -10));
    run(1.5);
    var t = 0.0;
    while (m.eyes < 0.9 && t < 20) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    await shot('3_medusa');
  });
}
