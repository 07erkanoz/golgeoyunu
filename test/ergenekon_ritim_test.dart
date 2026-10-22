import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/ergenekon.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';

/// Ergenekon'un ilk (ritimli) ocağı: körüğe çekicin vuruşunda basan biri
/// ocağı makul sürede eritir; Demirci körüklerin yanında durur.
Future<(IronVein, List<Bellows>, Anvil)> _forge(GolgeGame game) async {
  game.debugLoadLevel(15);
  await game.ready();
  game.cinematic = false;
  final vein = game.world.children.whereType<IronVein>().firstWhere(
    (v) => v.rhythm,
  );
  final pumps = game.world.children
      .whereType<Bellows>()
      .where((b) => b.vein == vein && b.order > 0)
      .toList();
  vein.lit = true;
  return (vein, pumps, vein.anvil!);
}

/// Körüklerden [use] sırayla, vuruşa denk ve dolu olanına basarak ocak
/// eriyene dek geçen süre (sn); [limit] içinde erimezse null.
double? _meltTime(GolgeGame game, IronVein v, List<Bellows> use, Anvil a) {
  const dt = 1 / 60;
  var wasOn = false;
  var i = 0;
  for (var t = 0.0; t < 90; t += dt) {
    game.update(dt);
    if (v.opening) return t;
    final on = a.onBeat;
    // Vuruş penceresinin başında bir kez basılır.
    if (on && !wasOn) {
      for (var k = 0; k < use.length; k++) {
        final b = use[(i + k) % use.length];
        if (b.ready) {
          b.use();
          i = (i + k + 1) % use.length;
          break;
        }
      }
    }
    wasOn = on;
  }
  return null;
}

void main() {
  testWithGame<GolgeGame>(
    'ritimli ocak: Demirci körüklerin yanında, vuruşu görülür',
    GolgeGame.new,
    (game) async {
      final (_, pumps, anvil) = await _forge(game);
      final far = pumps
          .map((b) => (b.position.x - anvil.position.x).abs())
          .reduce((a, b) => a > b ? a : b);
      expect(far, lessThan(14 * kTile), reason: 'örs ekranda, sesi duyulur');
    },
  );
  testWithGame<GolgeGame>(
    'ritimli ocak: tek körükle denk basan 45 sn içinde eritir',
    GolgeGame.new,
    (game) async {
      final (v, pumps, a) = await _forge(game);
      final t = _meltTime(game, v, [pumps.first], a);
      expect(t, isNotNull);
      expect(t, lessThan(45));
    },
  );
  testWithGame<GolgeGame>(
    'ritimli ocak: iki körüğü sırayla basan daha çabuk eritir',
    GolgeGame.new,
    (game) async {
      final (v, pumps, a) = await _forge(game);
      final one = _meltTime(game, v, [pumps.first], a)!;
      final (v2, pumps2, a2) = await _forge(game);
      final two = _meltTime(game, v2, pumps2.take(2).toList(), a2)!;
      expect(two, lessThan(one * 0.7));
      expect(two, lessThan(20));
    },
  );
}
