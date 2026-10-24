// Her bölümde yol göstermenin gösterebileceği düzenekler (tür ve sayı).
// `flutter test tools/bench/yol_sayim_test.dart`
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/puzzles.dart';

void main() {
  for (var i = 0; i < levels.length; i++) {
    testWithGame<GolgeGame>('bölüm $i', GolgeGame.new, (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(i);
      await game.ready();
      final counts = <String, int>{};
      for (final c in game.world.children) {
        final name = switch (c) {
          Lever _ => 'kol',
          Usable u => u.runtimeType.toString(),
          _ => null,
        };
        if (name != null) counts[name] = (counts[name] ?? 0) + 1;
      }
      // ignore: avoid_print
      print('SAYIM $i ${levels[i].titleText}: $counts');
    });
  }
}
