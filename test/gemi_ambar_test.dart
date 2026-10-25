// VI · Nuh'un Gemisi ambarları: deliklerden fışkıran su savurur, sandıkla
// tıkanır, üçü tıkanınca kapı açılır; yalpayla yuvarlanan fıçı ezer,
// yığının üstündeki güvende.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/gemi_ambar.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<void> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(5);
  await game.ready();
  game.cinematic = false;
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
}

void main() {
  testWithGame<GolgeGame>('fışkıran su yaklaşanı geri savurur', GolgeGame.new,
      (game) async {
    await load(game);
    final jet = game.world.children.whereType<LeakJet>().first;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(Vector2(jet.position.x - 3 * kTile, 25 * kTile.toDouble()),
          Player.w, Player.h),
    );
    game.controls.keyboard.right = true;
    run(game, 3);
    game.controls.keyboard.right = false;
    expect(p.center.x, lessThan(jet.position.x), reason: 'geçemez');
  });

  testWithGame<GolgeGame>(
    'sandıkla tıkanan delik susar; üçü tıkanınca kapı açılır',
    GolgeGame.new,
    (game) async {
      await load(game);
      final jets = game.world.children.whereType<LeakJet>().toList()
        ..sort((a, b) => a.position.x.compareTo(b.position.x));
      final gate = game.world.children.whereType<Gate>().firstWhere(
        (g) => (g.position.x / kTile).round() == 232,
      );
      final crates = game.world.children
          .whereType<Crate>()
          .where((c) => c.position.x > 176 * kTile && c.position.x < 232 * kTile)
          .toList()
        ..sort((a, b) => a.position.x.compareTo(b.position.x));
      expect(crates.length, 3);
      final p = game.player!;
      for (var i = 0; i < 3; i++) {
        // Sandığın soluna geç, sağa it.
        p.position.setFrom(
          Level.standOn(
            Vector2(crates[i].position.x - kTile, 25 * kTile.toDouble()),
            Player.w,
            Player.h,
          ),
        );
        p.velocity.setZero();
        game.controls.keyboard.right = true;
        for (var t = 0; t < 60 * 6 && !jets[i].plugged; t++) {
          game.update(1 / 60);
        }
        game.controls.keyboard.right = false;
        expect(jets[i].plugged, isTrue, reason: 'delik $i');
        expect(p.isDead, isFalse);
      }
      run(game, 2);
      expect(gate.opening, isTrue);
    },
  );

  testWithGame<GolgeGame>('yuvarlanan fıçı ezer, yığının üstü güvende',
      GolgeGame.new, (game) async {
    await load(game);
    final barrel = game.world.children.whereType<RollingBarrel>().first;
    final p = game.player!;
    // Yığının üstünde (bölmenin solundaki yığın).
    p.position.setFrom(
      Level.standOn(Vector2((barrel.c0 - 2) * kTile.toDouble(),
          22 * kTile.toDouble()), Player.w, Player.h),
    );
    run(game, RollingBarrel.period + 0.5);
    expect(p.isDead, isFalse, reason: 'yığının üstü');
    // Bölmenin ortasında, yerde: fıçı geçerken ezer.
    final q = game.player!;
    q.position.setFrom(
      Level.standOn(Vector2((barrel.c0 + barrel.c1) / 2 * kTile,
          25 * kTile.toDouble()), Player.w, Player.h),
    );
    var died = false;
    for (var i = 0; i < 60 * RollingBarrel.period && !died; i++) {
      game.update(1 / 60);
      died = q.isDead;
    }
    expect(died, isTrue);
  });
}
