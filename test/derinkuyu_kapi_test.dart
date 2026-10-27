// XIII · Derinkuyu: yuvarlak taş kapı (yalnız içeriden yuvarlanır) ve
// altındaki Ahırlar'dan dolaşan yol.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/derinkuyu.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

const _derinkuyu = 12;

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<(Player, RollingDoor)> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(_derinkuyu);
  await game.ready();
  game.cinematic = false;
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
  return (game.player!, game.world.children.whereType<RollingDoor>().single);
}

void stand(Player p, double col, int row) {
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  p.velocity.setZero();
}

void main() {
  testWithGame<GolgeGame>(
    'dışarıdan kıpırdamaz; içeriden yuvasına yuvarlanır, geçilir',
    GolgeGame.new,
    (game) async {
      final (p, door) = await load(game);
      expect(door.solid, isTrue);
      stand(p, 60, 15);
      run(game, 0.3);
      expect(door.canUse(p.center), isTrue);
      door.use();
      run(game, 2);
      expect(door.solid, isTrue, reason: 'dışarıdan açılmaz');
      // Sağa yürüyen kapıda durur.
      game.controls.keyboard.right = true;
      run(game, 1.5);
      expect(p.center.x, lessThan(62 * kTile));
      game.controls.keyboard.right = false;
      // İçeriden (64. sütun zincirin deliği).
      stand(p, 63, 15);
      run(game, 0.3);
      door.use();
      run(game, 2);
      expect(door.solid, isFalse);
      game.controls.keyboard.left = true;
      run(game, 1.5);
      game.controls.keyboard.left = false;
      expect(p.center.x, lessThan(61 * kTile), reason: 'açık kapıdan geçti');
    },
  );

  testWithGame<GolgeGame>(
    'dışarıdan gelen ahırlardan dolaşıp zincirle içeri çıkar',
    GolgeGame.new,
    (game) async {
      final (p, door) = await load(game);
      stand(p, 66, 25);
      run(game, 0.3);
      final k = game.controls.keyboard..left = true;
      for (var i = 0; i < 60 * 3 && p.state != PlayerState.vine; i++) {
        game.update(1 / 60);
        k.jump = p.onGround && p.center.x < 65.5 * kTile;
      }
      k
        ..left = false
        ..jump = false
        ..up = true;
      run(game, 4);
      // Zincirin tepesinden yana zıplayıp koridora çıkar.
      k
        ..up = false
        ..right = true
        ..jump = true;
      run(game, 0.15);
      k.jump = false;
      run(game, 0.6);
      k.right = false;
      run(game, 0.5);
      expect(p.isDead, isFalse);
      expect(p.position.y + Player.h, lessThan(16.2 * kTile));
      expect(door.isInside(p.center), isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'kapanan kapı Kandilci\'yi dışarıda bırakır',
    GolgeGame.new,
    (game) async {
      final (p, door) = await load(game);
      stand(p, 66, 15);
      run(game, 0.3);
      door.want = true;
      run(game, 2);
      // Kapının dışında bir Kandilci, içeri doğru yürüyor.
      final guard = Guard(Vector2(58 * kTile, 15 * kTile))..facing = 1;
      game.world.add(guard);
      await game.ready();
      p.position.y -= 30 * kTile; // görmesin
      run(game, 0.2);
      door.want = false;
      run(game, 2);
      expect(door.solid, isTrue);
      run(game, 10);
      expect(guard.toRect().right, lessThanOrEqualTo(62 * kTile + 1));
    },
  );
}
