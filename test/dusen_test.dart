// Düşen buz sarkıtı ve gevşek kaya Sâye'nin hızına göre zamanlanır:
// koşarak gelenin önüne düşer (eskiden hep arkasına düşüyordu), aynı
// hızla süren kırık parçalarına varır, altında duran vurulur.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

void main() {
  testWithGame<GolgeGame>(
    'koşarak gelen: buz önüne düşer, geçen ölmez',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      final li = levels.indexWhere((d) => d.map.any((r) => r.contains('i')));
      game.debugLoadLevel(li);
      await game.ready();
      game.cinematic = false;
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      await game.ready();
      final ice = game.world.children.whereType<FallingIcicle>().first;
      final p = game.player!;
      // Altındaki zemin.
      final col = (ice.position.x / kTile).floor();
      var row = (ice.position.y / kTile).floor() + 1;
      while (!game.level.solid(col, row) && row < game.level.height) {
        row++;
      }
      p.position.setFrom(
        Level.standOn(
          Vector2((col - 8) * kTile.toDouble(), (row - 1) * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setValues(Player.runSpeed, 0);
      game.controls.keyboard.right = true;
      double? landedAt;
      for (var i = 0; i < 60 * 3 && landedAt == null; i++) {
        game.update(1 / 60);
        if (!ice.isMounted || ice.debugFallen) landedAt = p.center.x;
      }
      game.controls.keyboard.right = false;
      expect(landedAt, isNotNull);
      expect(landedAt!, lessThan(ice.position.x), reason: 'önüne düşer');
      expect(landedAt, greaterThan(ice.position.x - 4 * kTile),
          reason: 'çok erken değil: yakında');
      expect(p.isDead, isFalse);
    },
  );
}
