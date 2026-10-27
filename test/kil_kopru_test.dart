// XVI · Erlik'in katı: Kıl Köprü (lib/game/kil_kopru.dart).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/erlik.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kil_kopru.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

const _erlik = 14;

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<(Player, HairBridge)> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(_erlik);
  await game.ready();
  game.cinematic = false;
  for (final k in game.world.children.whereType<Kormos>().toList()) {
    k.removeFromParent();
  }
  await game.ready();
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(254 * kTile, 30 * kTile), Player.w, Player.h),
  );
  p.velocity.setZero();
  final bridges = game.world.children.whereType<HairBridge>().toList()
    ..sort((a, b) => a.x.compareTo(b.x));
  return (p, bridges.first);
}

void main() {
  testWithGame<GolgeGame>('koşan köprüden ırmağa düşer', GolgeGame.new, (
    game,
  ) async {
    final (p, _) = await load(game);
    game.controls.keyboard.right = true;
    run(game, 4);
    game.controls.keyboard.right = false;
    run(game, 2);
    expect(p.isDead, isTrue);
  });

  testWithGame<GolgeGame>(
    'parmak ucunda yürüyen köprüden geçer',
    GolgeGame.new,
    (game) async {
      final (p, bridge) = await load(game);
      game.controls.keyboard
        ..sneak = true
        ..right = true;
      for (var i = 0; i < 60 * 20 && p.center.x < 273 * kTile; i++) {
        game.update(1 / 60);
        expect(bridge.sway, lessThan(1));
      }
      game.controls.keyboard.right = false;
      run(game, 0.5);
      expect(p.isDead, isFalse);
      expect(
        p.center.x,
        greaterThan(272 * kTile),
        reason: 'dinlenme kayasında',
      );
    },
  );

  testWithGame<GolgeGame>('arada durup dinlenen de geçer', GolgeGame.new, (
    game,
  ) async {
    final (p, bridge) = await load(game);
    final k = game.controls.keyboard;
    for (var i = 0; i < 60 * 25 && p.center.x < 273 * kTile; i++) {
      // Salınım artınca dur, durulunca yürü.
      if (bridge.sway > 0.6) k.right = false;
      if (bridge.sway < 0.05) k.right = true;
      game.update(1 / 60);
    }
    k.right = false;
    run(game, 0.5);
    expect(p.isDead, isFalse);
    expect(p.center.x, greaterThan(272 * kTile));
  });
}
