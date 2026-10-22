// Geçici deneme: her kayanın üstünden hangi zıplama anlarında atlanır.
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/ski.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lvl = int.fromEnvironment('LVL', defaultValue: 18);
  testWithGame<GolgeGame>('kaya', GolgeGame.new, (game) async {
    game.debugLoadLevel(lvl);
    await game.ready();
    game.cinematic = false;
    const only = String.fromEnvironment('ROCKS');
    final rocks = only.isEmpty
        ? [...game.level.skiRocks]
        : [for (final r in only.split(',')) int.parse(r)];
    for (final col in rocks) {
      final res = <String>[];
      for (final v in [250.0, 480.0, 650.0]) {
        var ok = 0;
        var tried = 0;
        var line = '';
        for (var d = 20; d <= 200; d += 20) {
          game.debugLoadLevel(lvl);
          await game.ready();
          game.cinematic = false;
          final p = game.player!;
          final s = game.skiSurface!;
          final rock = game.world.children.whereType<SkiRock>().firstWhere(
            (r) => r.col == col,
          );
          final x0 = rock.position.x - 9 * kTile;
          p.position.setValues(x0 - Player.w / 2, s.at(x0)! - Player.h);
          p.skiKick(v);
          var jumped = false;
          tried++;
          for (var i = 0; i < 60 * 4; i++) {
            final k = game.controls.keyboard;
            k.right = false;
            final dist = rock.position.x - (p.position.x + Player.w);
            k.jump = !jumped && dist < d;
            if (k.jump) jumped = true;
            game.update(1 / 60);
            k.jump = false;
            if (p.isDead) break;
            if (p.position.x > rock.position.x + 3 * kTile) break;
          }
          final good = !p.isDead && p.position.x > rock.position.x;
          if (good) ok++;
          line += good ? 'o' : (p.isDead ? 'x' : '-');
        }
        res.add('v${v.toInt()}:$ok/$tried $line');
      }
      // ignore: avoid_print
      print('kaya $col ${res.join(' ')}');
    }
  });
}
