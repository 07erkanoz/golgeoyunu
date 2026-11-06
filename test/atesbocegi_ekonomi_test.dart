// Ateşböceği ekonomisi: öbekler seyrek (haritadakilerin yaklaşık yarısı),
// gerekli yerlerdekiler kalır; kavanozu boş gelen Umay ağacından bir tane
// alır; sürpriz alanlar ödül verir.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';

void main() {
  test('öbekler seyrelir ama hiçbir bölümde sıfıra inmez', () {
    for (final d in levels) {
      final lv = Level(d);
      final all = lv.fireflyCells.length;
      if (all == 0) continue;
      final kept = keptFireflies(lv).length;
      expect(kept, greaterThanOrEqualTo((all / 2).floor()), reason: d.title);
      expect(kept, greaterThan(0), reason: d.title);
      expect(kept, lessThanOrEqualTo(all), reason: d.title);
    }
  });

  testWithGame<GolgeGame>(
    'kavanozu boş gelen ağaçtan bir ateşböceği alır',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.fireflies = 0;
      game.debugCheckpoint();
      expect(game.fireflies, 1);
      game.debugCheckpoint();
      expect(game.fireflies, 1, reason: 'doluyken vermez');
    },
  );

  testWithGame<GolgeGame>(
    'sır ilk bulunuşta bir ateşböceği verir',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.fireflies = 1;
      game.foundSecret('denemeSir');
      expect(game.fireflies, 2);
      game.foundSecret('denemeSir');
      expect(game.fireflies, 2, reason: 'ikinci kez vermez');
    },
  );
}
