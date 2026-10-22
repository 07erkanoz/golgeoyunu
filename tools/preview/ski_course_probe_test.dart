// Pisti insan gibi kayan biriyle baştan sona dener: her engelde zıplama
// engele [d] piksel kala basılır (her koşuda başka d). Ölüm yerlerini yazar.
import 'dart:math' as math;

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/ski.dart';

const _flips = bool.fromEnvironment('FLIPS');
const _trace = int.fromEnvironment('TRACE');
const _onlyD = int.fromEnvironment('D');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lvl = int.fromEnvironment('LVL', defaultValue: 9);
  testWithGame<GolgeGame>('pist', GolgeGame.new, (game) async {
    for (final d in [40.0, 80.0, 120.0]) {
      if (_onlyD > 0 && d != _onlyD) continue;
      var traced = 0;
      game.debugLoadLevel(lvl);
      await game.ready();
      game.cinematic = false;
      final deaths = <String>[];
      final k = game.controls.keyboard;
      var wasDead = false;
      var flipping = false;
      final end = game.level.exitCell.x;
      for (var i = 0; i < 60 * 400; i++) {
        final p = game.player!;
        if (p.center.x > end - kTile) break;
        final s = game.skiSurface!;
        final x = p.center.x;
        k.right = true;
        var jump = false;
        if (p.onGround || p.velocity.y.abs() < 1e9) {
          final rails = game.world.children.whereType<SkiRail>();
          bool rail(double xx) => rails.any(
            (r) => xx > r.position.x && xx < r.position.x + r.size.x,
          );
          final rock = game.world.children.whereType<SkiRock>().any(
            (r) =>
                r.position.x - (p.position.x + Player.w) > 0 &&
                r.position.x - (p.position.x + Player.w) < d,
          );
          var gap = false;
          for (var dx = 0.0; dx <= d; dx += 8) {
            if (s.at(x + dx) == null && !rail(x + dx)) gap = true;
          }
          jump = rock || gap;
        }
        if (!p.onGround) {
          // Havada: uzun uçuşta bir takla dener (insan gibi: kalkışta basar,
          // dönüş tamamlanınca bırakır).
          var t = 0.0;
          var xx = x;
          var yy = p.position.y + Player.h;
          var vy = p.velocity.y;
          for (; t < 3; t += 1 / 60) {
            vy = math.min(vy + 1500 / 60, 900);
            xx += p.velocity.x / 60;
            yy += vy / 60;
            final g = s.at(xx);
            if (g != null && yy >= g) break;
          }
          final spin = p.skiAirSpin % (2 * math.pi);
          if (_flips && !flipping && spin < 0.1 && t > 0.95) flipping = true;
          if (flipping && p.skiAirSpin > 2 * math.pi - 0.3) flipping = false;
          jump = flipping;
        } else {
          flipping = false;
        }
        k.jump = jump;
        game.update(1 / 60);
        if (_trace > 0 && traced < 1 && (x / kTile - _trace).abs() < 14) {
          // ignore: avoid_print
          print(
            '  x=${(p.center.x / kTile).toStringAsFixed(2)} y=${((p.position.y + Player.h) / kTile).toStringAsFixed(2)} yer=${p.onGround} tuş=$jump hız=${p.skiSpeed.toInt()} vy=${p.velocity.y.toInt()} açı=${p.skiAngle.toStringAsFixed(2)} ölü=${p.isDead}',
          );
        }
        if (p.isDead && (x / kTile - _trace).abs() < 14) traced++;
        if (p.isDead && !wasDead) {
          deaths.add('${(x / kTile).toStringAsFixed(0)}:${p.deathCause.name}');
        }
        wasDead = p.isDead;
      }
      // ignore: avoid_print
      print('d=$d ölüm ${deaths.length}: ${deaths.join(' ')}');
    }
  });
}
