// I · Yerebatan'ın tanıtım kesitleri (tools/yerebatan_ders.py): Eski Depo
// (sandık, kol ve kapı) ve Fener Dersi (sütunlar arasında tek Kandilci,
// sonra ateşböceğiyle çekilen Kandilci).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> place(GolgeGame game, double col, int row) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  return p;
}

T near<T extends PositionComponent>(GolgeGame g, double col) {
  final all = g.world.children.whereType<T>().toList()
    ..sort(
      (a, b) => (a.position.x - col * kTile).abs().compareTo(
        (b.position.x - col * kTile).abs(),
      ),
    );
  return all.first;
}

void main() {
  testWithGame<GolgeGame>(
    'Eski Depo: sandık sete itilir, üstünden sete çıkılır',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 26, 13);
      final crate = near<Crate>(game, 29);
      expect((crate.position.x / kTile).round(), 29);
      final k = game.controls.keyboard..right = true;
      for (var i = 0; i < 60 * 8 && crate.position.x < 33.9 * kTile; i++) {
        game.update(1 / 60);
      }
      expect(
        crate.position.x,
        greaterThan(33.9 * kTile),
        reason: 'sete dayandı',
      );
      // Sandığın üstüne, oradan sete.
      k.jump = true;
      run(game, 0.1);
      k.jump = false;
      run(game, 0.8);
      k.jump = true;
      run(game, 0.1);
      k.jump = false;
      run(game, 1.2);
      k.right = false;
      run(game, 0.5);
      expect(p.isDead, isFalse);
      expect(
        p.position.y + Player.h,
        closeTo(11 * kTile, 1),
        reason: 'setin üstünde',
      );
    },
  );

  testWithGame<GolgeGame>(
    'Eski Depo: kol yanındaki kapıyı açar',
    GolgeGame.new,
    (game) async {
      await place(game, 50, 13);
      final lever = near<Lever>(game, 50);
      final gate = near<Gate>(game, 56);
      expect((gate.position.x / kTile).round(), 56);
      expect(gate.solid, isTrue);
      lever.pull();
      run(game, 4);
      expect(gate.solid, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'Fener Dersi: Kandilci iki alçak duvarın arasında döner',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 62, 13);
      p.position.y -= 40 * kTile; // gözünün önünde durmasın
      final guard = near<Guard>(game, 86);
      var lo = guard.position.x, hi = guard.position.x;
      for (var i = 0; i < 60 * 40; i++) {
        game.update(1 / 60);
        lo = lo < guard.position.x ? lo : guard.position.x;
        hi = hi > guard.position.x ? hi : guard.position.x;
      }
      expect(lo, greaterThan(68 * kTile));
      expect(hi, lessThan(104 * kTile));
      expect(hi - lo, greaterThan(20 * kTile), reason: 'devriye geniş');
    },
  );
}
