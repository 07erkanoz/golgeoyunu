// IX · Kar Yolu: Erzurum Damları (tools/kar_yolu_damlar.py).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/erzurum.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/winter.dart';

const _karYolu = 8;

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> load(GolgeGame game, double col, int row) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(_karYolu);
  await game.ready();
  game.cinematic = false;
  for (final w in game.world.children.whereType<Wolf>().toList()) {
    w.removeFromParent();
  }
  await game.ready();
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  p.velocity.setZero();
  return p;
}

void main() {
  testWithGame<GolgeGame>(
    'baca dumanında açılan kanat yukarı taşır, son dama süzülünür',
    GolgeGame.new,
    (game) async {
      final p = await load(game, 246, 13);
      run(game, 0.3);
      final k = game.controls.keyboard;
      // Fırtınanın dindiği an (15 sn'lik döngünün başı): bacanın dumanına
      // zıpla, kanadı açık tutup sağa süzül.
      k
        ..right = true
        ..jump = true;
      var top = p.center.y;
      for (var i = 0; i < 60 * 7; i++) {
        game.update(1 / 60);
        top = top < p.center.y ? top : p.center.y;
        if (i > 30 && p.onGround) break;
      }
      k
        ..right = false
        ..jump = false;
      run(game, 0.5);
      expect(top, lessThan(9 * kTile), reason: 'dumanla yükseldi');
      expect(p.isDead, isFalse);
      expect(p.center.x, greaterThan(257 * kTile));
      expect(
        p.position.y + Player.h,
        closeTo(11 * kTile, 2),
        reason: 'son damda',
      );
    },
  );

  testWithGame<GolgeGame>(
    'havada donmuş kediye yaklaşan sırrı bulur',
    GolgeGame.new,
    (game) async {
      final p = await load(game, 233, 12);
      final cat = game.world.children.whereType<FrozenCat>().single;
      expect((cat.position.x / kTile).floor(), 238);
      p.position.setValues(236 * kTile, 9 * kTile);
      p.velocity.setZero();
      run(game, 0.2);
      expect(game.secretSeen('donmusKedi'), isTrue);
    },
  );
}
