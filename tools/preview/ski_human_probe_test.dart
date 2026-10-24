// Geçici deneme: insan gibi kayan biri takla uçurumuna yetişir mi?
// Takla rampasında bir kez zıplayıp takla atar (havada basılı tutar,
// dönüş tamamlanınca bırakır), sonra uçurum kenarında zıplar.
import 'dart:math' as math;

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  TestWidgetsFlutterBinding.ensureInitialized();
  const lvl = int.fromEnvironment('LVL', defaultValue: 9);
  testWithGame<GolgeGame>('insan', GolgeGame.new, (game) async {
    game.debugLoadLevel(lvl);
    await game.ready();
    final rows = game.skiSurface!.rows;
    final gaps = <(int, int)>[];
    for (var c = 1; c < rows.length; c++) {
      if (rows[c] < 0 && rows[c - 1] >= 0) {
        var e = c;
        while (e < rows.length && rows[e] < 0) {
          e++;
        }
        gaps.add((c, e));
      }
    }
    final takla = [
      for (final g in gaps)
        if (g.$2 - g.$1 >= 15) g,
    ];
    for (final (g0, g1) in takla) {
      // Önceki (takla rampası) uçurum.
      final ramp = gaps.lastWhere((g) => g.$2 < g0);
      for (final flips in [0.0, 0.7, 0.8, 1.0, 1.15]) {
        for (final hold in [true]) {
          game.debugLoadLevel(lvl);
          await game.ready();
          game.cinematic = false;
          final p = game.player!;
          final s = game.skiSurface!;
          final x0 = (ramp.$1 - 14) * kTile;
          p.position.setValues(x0 - Player.w / 2, s.at(x0)! - Player.h);
          final k = game.controls.keyboard;
          var phase = 0; // 0: rampaya, 1: havada takla, 2: uçuruma
          double maxV = 0;
          double edgeV = 0;
          for (var i = 0; i < 60 * 12; i++) {
            k.right = hold;
            final x = p.center.x;
            k.jump = false;
            if (phase == 0 && p.onGround && (ramp.$1 - 0.5) * kTile - x < 40) {
              k.jump = true;
              phase = 1;
            } else if (phase == 1) {
              k.jump =
                  flips > 0 &&
                  p.skiAirSpin < 2 * math.pi * flips &&
                  !p.onGround;
              if (p.onGround || game.skiFx!.kut > 0) phase = 2;
            } else if (phase == 2) {
              final d = (g0 - 0.5) * kTile - x;
              if (d < 50) {
                k.jump = true;
                edgeV = p.velocity.length;
                phase = 3;
              }
            }
            final spin0 = p.skiAirSpin;
            final air0 = !p.onGround;
            game.update(1 / 60);
            if (air0 && p.onGround && hold && phase == 1) {
              // ignore: avoid_print
              print(
                '  iniş x=${(p.center.x / kTile).toStringAsFixed(1)} faz=$phase dönüş=${spin0.toStringAsFixed(2)} kut=${game.skiFx!.kut.toStringAsFixed(2)} hız=${p.skiSpeed.toInt()}',
              );
            }
            maxV = math.max(maxV, p.skiSpeed);
            if (p.isDead || (p.onGround && p.center.x > g1 * kTile)) break;
          }
          final ok = !p.isDead && p.center.x > g1 * kTile;
          // ignore: avoid_print
          print(
            'uçurum $g0 takla=$flips sağ=$hold kenar hızı ${edgeV.toInt()} '
            'kut ${game.skiFx!.kut.toStringAsFixed(1)} faz=$phase x=${(p.center.x / kTile).toStringAsFixed(1)} ${ok ? "GEÇTİ" : "düştü ${p.deathCause}"}',
          );
        }
      }
    }
  });
}
