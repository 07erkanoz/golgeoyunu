import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show run;

Future<StoneGiant> _load(GolgeGame game) async {
  game.debugLoadLevel(7);
  await game.ready();
  game.cinematic = false;
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  final giant = game.world.children.whereType<StoneGiant>().first;
  giant.throws = false;
  // Sâye uzakta, devin yolunun dışında.
  game.player!.position.setFrom(
    Level.standOn(
      Vector2(giant.position.x - 14 * kTile, 19 * kTile),
      Player.w,
      Player.h,
    ),
  );
  run(game, 0.2);
  return giant;
}

void main() {
  testWithGame<GolgeGame>(
    'taş dev yürürken kulağını korur: ışığı savurur, vuruş sayılmaz',
    GolgeGame.new,
    (game) async {
      final giant = await _load(game);
      for (var k = 0; k < 60 * 10 && giant.earOpen; k++) {
        run(game, 1 / 60);
      }
      expect(giant.earOpen, isFalse, reason: 'yürüyor');
      game.fireflies = 3;
      game.releaseFirefly(giant.ear + Vector2(-60, 10), 1);
      run(game, 0.8);
      expect(giant.hits, 0);
      expect(game.world.children.whereType<FireflyLure>(), isEmpty);
    },
  );
  testWithGame<GolgeGame>(
    'devin alanında ateşböceği bitmez: alınanın yerine devden uzakta yenisi',
    GolgeGame.new,
    (game) async {
      final giant = await _load(game);
      final gx = giant.position.x + giant.size.x / 2;
      bool near(FireflySwarm s) => (s.position.x - gx).abs() < 30 * kTile;
      // Alandaki bütün sürüler alınmış gibi kaldırılır.
      for (final s in game.world.children.whereType<FireflySwarm>().toList()) {
        if (near(s)) s.removeFromParent();
      }
      run(game, 0.1);
      expect(
        game.world.children.whereType<FireflySwarm>().where(near),
        isEmpty,
      );
      run(game, 10);
      final back = game.world.children.whereType<FireflySwarm>().where(near);
      expect(back, isNotEmpty, reason: 'yenileri çıktı');
      expect(back.length, lessThanOrEqualTo(GiantFireflies.alive));
    },
  );
}
