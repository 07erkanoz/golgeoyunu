// Gölgeyi önden göndermek (Derinkuyu): gölge koridora yürür, Kandilci onu
// görüp ona dalar, Sâye onun yanından yakalanmadan geçer; gölge sonra döner.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shadow_decoy.dart';

void main() {
  final withStones = [
    for (var i = 0; i < levels.length; i++)
      if (levels[i].shadowStones.isNotEmpty) i,
  ];
  test('gölge taşı olan bölümler', () => expect(withStones, hasLength(3)));
  for (final li in withStones) {
    testWithGame<GolgeGame>('gölge Kandilciyi oyalar ($li)', GolgeGame.new, (
      game,
    ) async {
      expect(li, greaterThanOrEqualTo(0), reason: 'bir bölümde gölge taşı var');
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(li);
      await game.ready();
      final p = game.player!;
      final stone = game.world.children.whereType<ShadowStone>().first;
      p.position.setFrom(
        Level.standOn(stone.position - Vector2(0, 20), Player.w, Player.h),
      );
      p.facing = 1;
      for (var i = 0; i < 30; i++) {
        game.update(1 / 60);
      }
      expect(stone.canUse(p.center), isTrue);
      stone.use();
      await game.ready();
      expect(p.shadowSent, isTrue);
      // Gölge yürür; en yakın Kandilci onu görünce ona dalar.
      final guards = game.world.children.whereType<Guard>().toList()
        ..sort(
          (a, b) => (a.center.x - stone.position.x).abs().compareTo(
            (b.center.x - stone.position.x).abs(),
          ),
        );
      final g = guards.first;
      var t = 0.0;
      while (!g.distracted && t < 12) {
        game.update(1 / 60);
        t += 1 / 60;
      }
      expect(g.distracted, isTrue, reason: 'Kandilci gölgeye dalar');
      // Sâye Kandilcinin önünden koşarak geçer: yakalanmaz.
      game.controls.keyboard.right = true;
      var passed = false;
      t = 0;
      while (t < 4 && !p.isDead) {
        game.update(1 / 60);
        t += 1 / 60;
        if (p.center.x > g.center.x + 3 * kTile) {
          passed = true;
          break;
        }
      }
      game.controls.keyboard.right = false;
      expect(p.isDead, isFalse, reason: 'dalgın Kandilci görmez');
      expect(passed, isTrue, reason: 'Kandilcinin yanından geçildi');
      // Gölge sonunda geri döner.
      t = 0;
      while (p.shadowSent && t < 20) {
        game.update(1 / 60);
        t += 1 / 60;
      }
      expect(p.shadowSent, isFalse, reason: 'gölge döner');
    });
  }
}
