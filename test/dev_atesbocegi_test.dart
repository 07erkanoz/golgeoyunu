// Taş dev Nemrud'un alanında ateşböceği bitmez: oyuncunun bulunduğu yanda
// (devi geçmeden varılacak yerde) yeni sürü çıkar. Eskiden yeni sürü hep
// devden en uzak yere, öbür yana konuyordu; oyuncu ateşböceksiz kalıyordu.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/maps.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/player.dart';

void main() {
  testWithGame<GolgeGame>(
    'dev alanında ateşböceği oyuncunun yanında çıkar',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(
        levels.indexWhere((d) => identical(d.map, kMapGunDogumu)),
      );
      await game.ready();
      final giant = game.world.children.whereType<StoneGiant>().first;
      final p = game.player!;
      // Devin solunda, kontrol noktasının yanında; elinde ateşböceği yok,
      // sol yandaki sürüler alınmış.
      p.position.setFrom(
        Level.standOn(
          Vector2(67 * kTile.toDouble(), 19 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      final gx = giant.position.x + giant.size.x / 2;
      for (final s in game.world.children.whereType<FireflySwarm>().toList()) {
        if (s.position.x < gx) s.removeFromParent();
      }
      await game.ready();
      game.fireflies = 0;
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
        game.fireflies = 0;
      }
      final left = game.world.children
          .whereType<FireflySwarm>()
          .where((s) => s.position.x < gx)
          .toList();
      expect(left, isNotEmpty, reason: 'devin bu yanında yeni sürü');
    },
  );
}
