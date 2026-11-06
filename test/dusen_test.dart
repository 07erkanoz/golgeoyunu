// Düşen buz sarkıtı Sâye'nin hızına göre zamanlanır: koşmayı sürdüren
// vurulur (eskiden önüne düşüyordu, koşan hepsinden rahatça geçiyordu);
// çatırtıyı duyup duran kurtulur, buz önüne düşer.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

Future<(FallingIcicle, Player)> _kur(GolgeGame game) async {
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
  return (ice, p);
}

void main() {
  testWithGame<GolgeGame>('koşmayı sürdüren: buz başına iner', GolgeGame.new, (
    game,
  ) async {
    final (_, p) = await _kur(game);
    game.controls.keyboard.right = true;
    for (var i = 0; i < 60 * 3 && !p.isDead; i++) {
      game.update(1 / 60);
    }
    game.controls.keyboard.right = false;
    expect(p.isDead, isTrue, reason: 'koşan da vurulabilmeli');
  });

  testWithGame<GolgeGame>(
    'çatırtıyı duyup duran: buz önüne düşer',
    GolgeGame.new,
    (game) async {
      final (ice, p) = await _kur(game);
      game.controls.keyboard.right = true;
      var stopped = false;
      var heard = 0;
      for (var i = 0; i < 60 * 3 && !ice.debugFallen && ice.isMounted; i++) {
        game.update(1 / 60);
        // Çatırtıyı duyup bir insan tepkisi kadar (0,2 sn) sonra durur.
        if (ice.debugShaking) heard++;
        if (!stopped && heard >= 12) {
          stopped = true;
          game.controls.keyboard.right = false;
        }
      }
      for (var i = 0; i < 30; i++) {
        game.update(1 / 60);
      }
      expect(stopped, isTrue);
      expect(p.isDead, isFalse);
      expect(p.center.x, lessThan(ice.position.x), reason: 'önünde kaldı');
    },
  );
}
