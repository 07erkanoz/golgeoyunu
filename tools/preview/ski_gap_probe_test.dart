// Geçici deneme: takla uçurumunda hangi zıplama anları karşıya varır.
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWithGame<GolgeGame>('uçurum', GolgeGame.new, (game) async {
    game.debugLoadLevel(9);
    await game.ready();
    final rows = game.skiSurface!.rows;
    // 15 karelik ve daha geniş uçurumlar.
    final gaps = <(int, int)>[];
    for (var c = 1; c < rows.length; c++) {
      if (rows[c] < 0 && rows[c - 1] >= 0) {
        var e = c;
        while (e < rows.length && rows[e] < 0) {
          e++;
        }
        if (e - c >= 15) gaps.add((c, e));
      }
    }
    for (final (g0, g1) in gaps) {
      for (final v in [640.0, 760.0, 800.0]) {
        var line = '';
        for (var d = -60; d <= 200; d += 20) {
          game.debugLoadLevel(9);
          await game.ready();
          game.cinematic = false;
          final p = game.player!;
          final s = game.skiSurface!;
          final edge = (g0 - 0.5) * kTile;
          final x0 = edge - 6 * kTile;
          p.position.setValues(x0 - Player.w / 2, s.at(x0)! - Player.h);
          p.skiKick(v);
          if (v > 640) game.skiFx!.kut = 3;
          var jumped = false;
          for (var i = 0; i < 60 * 4; i++) {
            final k = game.controls.keyboard;
            final dist = edge - p.center.x;
            k.jump = !jumped && dist < d;
            if (k.jump) jumped = true;
            game.update(1 / 60);
            k.jump = false;
            if (p.isDead || (p.onGround && p.center.x > g1 * kTile)) break;
          }
          line += (!p.isDead && p.center.x > g1 * kTile) ? 'o' : 'x';
        }
        // ignore: avoid_print
        print('uçurum $g0-$g1 v${v.toInt()} $line  (d=-60..200 adım 20)');
      }
    }
  });
}
