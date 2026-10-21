import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show run, keys;

void main() {
  testWithGame<GolgeGame>(
    'Yerebatan: kolu çekmeden raf ile kapı arasına inen zincirle rafa geri çıkar',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      run(game, 0.2);
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(Vector2(58 * kTile, 13 * kTile), Player.w, Player.h),
      );
      run(game, 0.3);
      // Zincire git, tırman.
      keys(game).left = true;
      run(game, 0.25);
      keys(game).left = false;
      keys(game).up = true;
      run(game, 3);
      keys(game).up = false;
      // Tepede sola atla, rafın üstüne in, kola git.
      keys(game).left = true;
      keys(game).jump = true;
      run(game, 0.1);
      keys(game).jump = false;
      run(game, 0.6);
      keys(game).left = false;
      run(game, 0.5);
      // Rafın üstünde durur (satır 9); kol oradadır.
      expect(p.onGround, isTrue);
      expect(p.position.y + Player.h, closeTo(10 * kTile, 1));
      expect(p.position.x, inInclusiveRange(53 * kTile, 57 * kTile));
    },
  );
}
