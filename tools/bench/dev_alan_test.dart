// Gün Doğumu: devin yürüdüğü alan ve yakınındaki ateşböceği yerleri.
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';

void main() {
  testWithGame<GolgeGame>('alan', GolgeGame.new, (game) async {
    game.debugLoadLevel(7);
    await game.ready();
    final g = game.world.children.whereType<StoneGiant>().first;
    final c0 = (g.position.x / kTile).floor();
    // ignore: avoid_print
    print('dev sütun $c0..${c0 + 11 + 5}, satır ${(g.position.y / kTile).floor()}');
    for (final f in game.level.fireflyCells) {
      final c = (f.x / kTile).floor();
      if ((c - c0).abs() < 40) {
        // ignore: avoid_print
        print('ateşböceği $c,${(f.y / kTile).floor()}');
      }
    }
  });
}
