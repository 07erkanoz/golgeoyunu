// II · Kule: zindandaki kayan kayaların kenarına tutunulur; kaçıran
// altındaki tahtaya düşer (uzun düşüş yok).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/mechanics.dart';
import 'package:golge/game/player.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<(Player, CrumbleRock)> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(1);
  await game.ready();
  game.cinematic = false;
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
  final rock = game.world.children.whereType<CrumbleRock>().firstWhere(
    (r) => (r.x / kTile).round() == 9 && (r.y / kTile).round() == 183,
  );
  return (game.player!, rock);
}

void main() {
  testWithGame<GolgeGame>(
    'kayan kayanın kenarına tutunup üstüne çıkılır',
    GolgeGame.new,
    (game) async {
      final (p, rock) = await load(game);
      // Kayanın sağ kenarının hemen yanında, el hizasında düşerken.
      p.position.setValues(11 * kTile + 2.0, 183 * kTile + 6.0);
      p.velocity.setValues(-40, 60);
      p.facing = -1;
      final k = game.controls.keyboard..left = true;
      var hung = false;
      for (var i = 0; i < 30 && !hung; i++) {
        game.update(1 / 60);
        hung = p.state == PlayerState.hang;
      }
      expect(hung, isTrue, reason: 'kayanın kenarına tutundu');
      k
        ..left = false
        ..up = true;
      run(game, 0.6);
      k.up = false;
      expect(p.isDead, isFalse);
      expect(
        p.position.y + Player.h,
        closeTo(183 * kTile, 2),
        reason: 'kayanın üstünde',
      );
      expect(rock.atRest, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'tutunulan kaya düşünce eller boşalır, altındaki tahtaya iner',
    GolgeGame.new,
    (game) async {
      final (p, rock) = await load(game);
      p.position.setValues(11 * kTile + 2.0, 183 * kTile + 6.0);
      p.velocity.setValues(-40, 60);
      p.facing = -1;
      game.controls.keyboard.left = true;
      run(game, 0.2);
      game.controls.keyboard.left = false;
      expect(p.state, PlayerState.hang);
      // Kaya kopar (üstüne başkası basmış gibi).
      for (var i = 0; i < 60 * 2 && rock.atRest; i++) {
        rock.stoodOn = true;
        game.update(1 / 60);
      }
      run(game, 1.5);
      expect(p.isDead, isFalse);
      expect(p.onGround, isTrue);
      expect(
        p.position.y + Player.h,
        closeTo(185 * kTile, 2),
        reason: 'tahtada',
      );
    },
  );
}
