// XVII · Göğün Katları, Kuş Yolu Katı: ışık nehri Sâye'yi taşır; Ülker'in
// yedi yıldızı yanınca köprü belirir.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kus_yolu.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> load(GolgeGame game, double c, double r) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(16);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(Level.standOn(Vector2(c * kTile, r * kTile), Player.w, Player.h));
  return p;
}

void main() {
  testWithGame<GolgeGame>('ışık nehri adadan Ülker\'in bulutuna taşır',
      GolgeGame.new, (game) async {
    final p = await load(game, 293, 23);
    game.controls.keyboard.right = true;
    var carried = false;
    for (var i = 0; i < 60 * 8; i++) {
      game.update(1 / 60);
      if (game.world.children.whereType<StarStream>().any((s) => s.carrying)) {
        carried = true;
      }
      if (p.onGround && p.center.x > 325 * kTile) break;
    }
    game.controls.keyboard.right = false;
    expect(carried, isTrue);
    expect(p.isDead, isFalse);
    expect(p.center.x, greaterThan(324 * kTile));
    expect(p.position.y + Player.h, closeTo(12 * kTile, 3));
  });

  testWithGame<GolgeGame>('yedi yıldız yanınca köprü belirir; köprüden geçilir',
      GolgeGame.new, (game) async {
    final p = await load(game, 327, 11);
    final u = game.world.children.whereType<UlkerCluster>().single;
    final planks = game.world.children.whereType<UlkerPlank>().toList();
    expect(planks.every((pl) => !pl.active), isTrue);
    for (final s in u.stars) {
      p.position.setValues(s.dx - Player.w / 2, s.dy - Player.h / 2);
      game.update(1 / 60);
    }
    expect(u.complete, isTrue);
    p.position.setFrom(Level.standOn(Vector2(328 * kTile, 11 * kTile), Player.w, Player.h));
    p.velocity.setZero();
    run(game, 2);
    expect(planks.every((pl) => pl.active), isTrue);
    // Köprünün başından öbür buluta yürü.
    p.position.setValues(334 * kTile.toDouble(), 12 * kTile - Player.h - 1);
    p.velocity.setZero();
    game.controls.keyboard.right = true;
    for (var i = 0; i < 60 * 6 && p.center.x < 358 * kTile; i++) {
      game.update(1 / 60);
    }
    game.controls.keyboard.right = false;
    expect(p.isDead, isFalse);
    expect(p.center.x, greaterThan(357 * kTile));
  });

  testWithGame<GolgeGame>('ikinci nehir son adaya indirir', GolgeGame.new,
      (game) async {
    final p = await load(game, 360, 11);
    game.controls.keyboard.right = true;
    for (var i = 0; i < 60 * 8; i++) {
      game.update(1 / 60);
      if (p.onGround && p.center.x > 386 * kTile) break;
    }
    game.controls.keyboard.right = false;
    expect(p.isDead, isFalse);
    expect(p.center.x, greaterThan(385 * kTile));
  });
}
