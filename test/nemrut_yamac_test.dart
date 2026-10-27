// VII · Nemrut: Tümülüsün Yamacı (tools/nemrut_yamac.py).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/mechanics.dart';
import 'package:golge/game/player.dart';

void main() {
  testWithGame<GolgeGame>(
    'yamacın kayan taşları basana dayanmaz, sonra yerine gelir',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(6);
      await game.ready();
      game.cinematic = false;
      final rocks = game.world.children
          .whereType<CrumbleRock>()
          .where((r) => r.x > 204 * kTile && r.x < 264 * kTile)
          .toList();
      expect(rocks.length, 11);
      final first = rocks.reduce((a, b) => a.x < b.x ? a : b);
      final p = game.player!;
      p.position.setValues(first.x + 4, first.y - Player.h - 1);
      p.velocity.setZero();
      var fell = false;
      for (var i = 0; i < 60 * 4 && !fell; i++) {
        game.update(1 / 60);
        fell = !first.active;
      }
      expect(fell, isTrue, reason: 'basılan taş kayar');
      // Sâye yamacın dibindeki zemine (uçuruma düşüp yeniden doğmasın).
      p.position.setFrom(
        Level.standOn(Vector2(206 * kTile, 19 * kTile), Player.w, Player.h),
      );
      p.velocity.setZero();
      for (var i = 0; i < 60 * 8 && !first.active; i++) {
        game.update(1 / 60);
      }
      expect(first.active, isTrue, reason: 'yerine döner');
    },
  );
}
