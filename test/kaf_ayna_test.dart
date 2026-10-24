// Kaf, Gözcü'nün gölge köprüsü: ayna köprüden önceki sağlam zeminden
// çevrilir (köprüde ayağa kalkan, kavanozunun ışığıyla köprüyü yok edip
// düşüyordu); ay ışığı köprünün üstünden geçip Gözcü'yü kamaştırır, köprüyü
// söndürmez.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/maps.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

void main() {
  testWithGame<GolgeGame>(
    'Kaf aynası sağlam zeminden çevrilir',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(levels.indexWhere((d) => identical(d.map, kMapKaf)));
      await game.ready();
      final mirror = game.world.children.whereType<Mirror>().reduce(
        (a, b) => a.position.x < b.position.x ? a : b,
      );
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2(mirror.position.x - kTile / 2, 9 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < 30; i++) {
        game.update(1 / 60);
      }
      expect(p.onGround, isTrue);
      expect(
        game.level.solid(mirror.col, 10),
        isTrue,
        reason: 'aynanın altı sağlam zemin, gölge köprüsü değil',
      );
      expect(mirror.canUse(p.center), isTrue);
      final watcher = game.world.children.whereType<Watcher>().reduce(
        (a, b) =>
            (a.position.x - mirror.position.x).abs() <
                (b.position.x - mirror.position.x).abs()
            ? a
            : b,
      );
      mirror.use();
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      expect(
        watcher.dazzled,
        greaterThan(0),
        reason: 'ışık Gözcü\'yü kamaştırır',
      );
      // Ay ışığı köprüye değmez (köprüyü yalnız oyuncunun kavanozu söndürür).
      final beams = game.world.children.whereType<SunBeam>().toList();
      final bridge = game.world.children.whereType<PhasePlank>().where(
        (b) =>
            b.position.x > mirror.position.x - 2 * kTile &&
            b.position.x < watcher.position.x,
      );
      expect(bridge, isNotEmpty);
      for (final b in bridge) {
        for (var x = 6.0; x < b.size.x; x += kTile) {
          final at = b.position + Vector2(x, 4);
          expect(beams.any((s) => s.lights(at.toOffset())), isFalse);
        }
      }
    },
  );
}
