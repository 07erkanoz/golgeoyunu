// Su İyesi vanayı gösterir; vana açılınca suya çekilip kaybolur (eskiden su
// inip kalkarken suyun üstünde bekliyordu).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/cameos.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/puzzles.dart';

void main() {
  testWithGame<GolgeGame>('vana açılınca Su İyesi kaybolur', GolgeGame.new, (
    game,
  ) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    final basin = game.world.children.whereType<WaterBasin>().first;
    game.world.add(WaterFace(basin));
    await game.ready();
    for (var i = 0; i < 60 * 3; i++) {
      game.update(1 / 60);
    }
    expect(game.world.children.whereType<WaterFace>(), isNotEmpty);
    game.world.children.whereType<Valve>().first.use();
    for (var i = 0; i < 60 * 3; i++) {
      game.update(1 / 60);
    }
    expect(game.world.children.whereType<WaterFace>(), isEmpty);
  });
}
