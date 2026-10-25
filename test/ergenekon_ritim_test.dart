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

/// Sıradaki (oklu) körüğe vuruşa denk basarak ocak eriyene dek geçen süre
/// (sn) ve basış sayısı; [limit] içinde erimezse null.
(double, int)? _meltTime(
  GolgeGame game,
  IronVein v,
  Anvil a, [
  Set<Bellows>? lit,
]) {
  const dt = 1 / 60;
  var wasOn = false;
  var presses = 0;
  for (var t = 0.0; t < 60; t += dt) {
    game.update(dt);
    if (v.opening) return (t, presses);
    final on = a.onBeat;
    // Vuruş penceresinin başında bir kez basılır.
    if (on && !wasOn) {
      lit?.add(v.activeBellows!);
      v.activeBellows!.use();
      presses++;
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
    'ritimli ocak: oklu körüğe denk basan altı vuruşta eritir, ok körükten '
    'körüğe geçer',
    GolgeGame.new,
    (game) async {
      final (v, pumps, a) = await _forge(game);
      expect(v.rhythmPumps.length, pumps.length);
      final lit = <Bellows>{};
      final r = _meltTime(game, v, a, lit);
      expect(r, isNotNull);
      expect(r!.$2, IronVein.beatsNeeded);
      expect(r.$1, lessThan(12));
      expect(lit.length, pumps.length, reason: 'ok her körüğe uğrar');
    },
  );
  testWithGame<GolgeGame>(
    'ritimli ocak: yanlış an ya da sönük körük vuruş düşürmez, sayılmaz',
    GolgeGame.new,
    (game) async {
      final (v, pumps, a) = await _forge(game);
      const dt = 1 / 60;
      // Bir denk vuruş.
      while (!a.onBeat) {
        game.update(dt);
      }
      v.activeBellows!.use();
      expect(v.beats, 1);
      // Vuruşun dışında oklu körüğe basmak sayılmaz, düşürmez.
      while (a.onBeat) {
        game.update(dt);
      }
      for (var i = 0; i < 20; i++) {
        game.update(dt);
      }
      v.activeBellows!.use();
      expect(v.beats, 1);
      // Sönük körük: vuruşta bile sayılmaz.
      while (!a.onBeat) {
        game.update(dt);
      }
      pumps.firstWhere((b) => !identical(b, v.activeBellows)).use();
      expect(v.beats, 1);
      // Isı kendiliğinden sönmez.
      for (var i = 0; i < 60 * 10; i++) {
        game.update(dt);
      }
      expect(v.beats, 1);
    },
  );
}
