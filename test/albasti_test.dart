// XII · Peri Bacaları: Kızıl Vadi'nin Albastısı (lib/game/albasti.dart).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/albasti.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

const _peri = 11;

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<(Player, AlbastiHunter)> load(GolgeGame game, double col) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(_peri);
  await game.ready();
  game.cinematic = false;
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  final hunters = game.world.children.whereType<AlbastiHunter>().toList()
    ..sort((a, b) => a.x.compareTo(b.x));
  // Yalnız ilki kalsın.
  for (final h in hunters.skip(1)) {
    h.removeFromParent();
  }
  await game.ready();
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, 25 * kTile), Player.w, Player.h),
  );
  p.velocity.setZero();
  return (p, hunters.first);
}

void main() {
  testWithGame<GolgeGame>('açıkta ışığı görüneni yakalar', GolgeGame.new, (
    game,
  ) async {
    final (p, a) = await load(game, 230);
    run(game, 0.2);
    expect(a.hunting, isTrue);
    run(game, 6);
    expect(p.isDead, isTrue);
  });

  testWithGame<GolgeGame>('demir nalın yanındakine yaklaşamaz', GolgeGame.new, (
    game,
  ) async {
    final (p, a) = await load(game, 237);
    run(game, 8);
    expect(p.isDead, isFalse);
    final iron = game.world.children.whereType<IronCharm>().firstWhere(
      (i) => (i.x / kTile).floor() == 237,
    );
    expect(
      (a.position - iron.position).length,
      greaterThan(IronCharm.guard - 2),
    );
  });

  testWithGame<GolgeGame>('çömelip ışığını örtenden vazgeçer', GolgeGame.new, (
    game,
  ) async {
    final (p, a) = await load(game, 229);
    game.controls.keyboard.down = true;
    run(game, 0.3);
    expect(a.hunting, isFalse);
    run(game, 6);
    expect(p.isDead, isFalse);
    game.controls.keyboard.down = false;
  });
}
