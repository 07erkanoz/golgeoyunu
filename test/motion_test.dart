import 'dart:ui' as ui;

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/rig.dart';

const _floor = [
  '############################################################',
  '#..........................................................#',
  '#..........................................................#',
  '#..........................................................#',
  '#P.........................................................#',
  '############################################################',
  '############################################################',
];

/// Oyuncuyu bir kez çizer (ayakların yeri kaydedilir).
void _draw(Player p) {
  final rec = ui.PictureRecorder();
  p.renderTree(ui.Canvas(rec));
  rec.endRecording().dispose();
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  for (final (name, hz, sneak) in [
    ('koşu 60 Hz', 60, false),
    ('koşu 144 Hz', 144, false),
    ('koşu 30 Hz', 30, false),
    ('parmak ucu', 60, true),
  ]) {
    testWithGame<GolgeGame>('yerdeki ayak kaymaz: $name', GolgeGame.new, (
      game,
    ) async {
      GolgeGame.debugLevels = [
        const LevelDef(
          title: 'ADIM',
          subtitle: '',
          theme: LevelTheme.cistern,
          map: _floor,
        ),
      ];
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      final keys = game.controls.keyboard;
      keys.right = true;
      keys.sneak = sneak;
      final dt = 1 / hz;
      // Tam hıza çık.
      for (var t = 0.0; t < 0.8; t += dt) {
        game.update(dt);
      }
      final ground = p.position.y + Player.h;
      _draw(p);
      var prev = [...p.debugFeet];
      var worst = 0.0;
      var planted = 0;
      for (var i = 0; i < hz * 2; i++) {
        game.update(dt);
        _draw(p);
        final now = p.debugFeet;
        for (var k = 0; k < 2; k++) {
          // İki karede de yerdeyse aynı yerde durmalı.
          final onFloor =
              (now[k].y - ground).abs() < 0.6 &&
              (prev[k].y - ground).abs() < 0.6;
          if (!onFloor) continue;
          planted++;
          final slip = (now[k].x - prev[k].x).abs();
          if (slip > worst) worst = slip;
        }
        prev = [...now];
      }
      // Gövde karede 1–5 piksel ilerler; basan ayak ancak bir kıpırtı kadar.
      expect(planted, greaterThan(hz * 0.4));
      expect(worst, lessThan(0.6), reason: 'en kötü kayma $worst px');
    });
  }

  test('uzuv hiçbir zaman uzamaz; erişilemeyen hedefe doğru kısalır', () {
    const hip = ui.Offset(0, 0);
    final (knee, end) = solveLimb(hip, const ui.Offset(30, 10), 7.5, 7.5);
    expect((knee - hip).distance, closeTo(7.5, 1e-6));
    expect((end - knee).distance, closeTo(7.5, 0.02));
    // Dizin öne kırılması.
    final (k2, _) = solveLimb(hip, const ui.Offset(0, 12), 7.5, 7.5);
    expect(k2.dx, greaterThan(0));
  });

  test('yay kare hızından bağımsız', () {
    double run(int hz) {
      final s = Spring(stiffness: 70, damping: 6);
      for (var i = 0; i < hz ~/ 2; i++) {
        s.update(1, 1 / hz);
      }
      return s.value;
    }

    expect(run(30), closeTo(run(144), 0.03));
  });
}
