// Gölge yarığı (Kar Yolu): kapının kolu kapalı bir odada; yarıktan yalnız
// gölge geçer. Setin üstündeki gölge taşından gönderilen gölge kolu çeker,
// kapı açılır; Sâye setin altından kapıya, kapıdan öteye geçer.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shadow_decoy.dart';

void main() {
  testWithGame<GolgeGame>(
    'gölge yarıktan geçer, kolu çeker; Sâye geçer',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      final li = levels.indexWhere((d) => d.shadowCracks.isNotEmpty);
      expect(li, greaterThanOrEqualTo(0));
      game.debugLoadLevel(li);
      await game.ready();
      game.cinematic = false;
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      await game.ready();
      final (c, r0, _) = game.level.def.shadowCracks.first;
      // Sâye yarıktan geçemez.
      expect(game.level.solid(c, r0), isTrue);
      final stone = game.world.children.whereType<ShadowStone>().firstWhere(
        (s) => (s.position.x / kTile).floor() == c - 3,
      );
      final p = game.player!;
      p.position.setValues(
        stone.position.x - Player.w / 2,
        stone.position.y - Player.h,
      );
      p.velocity.setZero();
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      expect(p.onGround, isTrue);
      // Sağa bakarak gölgeyi taştan gönder.
      game.controls.keyboard.right = true;
      game.update(1 / 60);
      game.controls.keyboard.right = false;
      p.position.x = stone.position.x - Player.w / 2;
      stone.use();
      final lever = game.world.children.whereType<Lever>().reduce(
        (a, b) =>
            (a.position.x - stone.position.x).abs() <
                (b.position.x - stone.position.x).abs()
            ? a
            : b,
      );
      for (var i = 0; i < 60 * 6 && !lever.pulled; i++) {
        game.update(1 / 60);
      }
      expect(lever.pulled, isTrue, reason: 'gölge yarıktan geçip kolu çekti');
      // Kapı açılsın; Sâye setin altından kapıya yürüyüp geçer.
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
      }
      p.position.setFrom(
        Level.standOn(
          // Setin altındaki geçitte (basamağın ardında).
        Vector2((c - 4) * kTile.toDouble(), 19 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
      game.controls.keyboard.right = true;
      for (var i = 0; i < 60 * 6; i++) {
        game.update(1 / 60);
      }
      game.controls.keyboard.right = false;
      expect(p.isDead, isFalse);
      expect(p.position.x, greaterThan(333 * kTile), reason: 'kapıdan geçti');
    },
  );
}
