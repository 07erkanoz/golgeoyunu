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
  test('gölge taşı olan bölümler', () => expect(withStones, hasLength(4)));
  // Yerebatan'ın taşı Kandilci için değil, kol için (aşağıda).
  for (final li in withStones.where((i) => i != 0)) {
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

  testWithGame<GolgeGame>(
    'Gölge Kapısı: gölge parmaklıktan geçip kolu çeker',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      final p = game.player!;
      final stone = game.world.children.whereType<ShadowStone>().single;
      final gate = game.world.children.whereType<Gate>().reduce(
        (a, b) =>
            (a.position.x - stone.position.x).abs() <
                (b.position.x - stone.position.x).abs()
            ? a
            : b,
      );
      final lever = game.world.children.whereType<Lever>().reduce(
        (a, b) =>
            (a.position.x - stone.position.x).abs() <
                (b.position.x - stone.position.x).abs()
            ? a
            : b,
      );
      expect(gate.position.x, greaterThan(stone.position.x));
      expect(lever.position.x, greaterThan(gate.position.x));
      // Sâye kapıdan geçemez, kola yetişemez.
      p.position.setFrom(
        Level.standOn(stone.position - Vector2(0, 20), Player.w, Player.h),
      );
      p.facing = 1;
      game.controls.keyboard.right = true;
      for (var i = 0; i < 180; i++) {
        game.update(1 / 60);
      }
      game.controls.keyboard.right = false;
      expect(p.position.x + Player.w, lessThanOrEqualTo(gate.position.x + 2));
      expect(lever.pulled, isFalse);
      // Taşa dönüp gölgeyi gönderir: gölge kola varıp çeker, kapı açılır.
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
      var t = 0.0;
      while (!lever.pulled && t < 10) {
        game.update(1 / 60);
        t += 1 / 60;
      }
      expect(lever.pulled, isTrue, reason: 'gölge kolu çeker');
      expect(gate.opening, isTrue, reason: 'parmaklıklı kapı açılır');
      // Kapı kalkınca Sâye geçer; gölge de döner.
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
      }
      game.controls.keyboard.right = true;
      t = 0;
      while (p.center.x < lever.position.x && t < 6) {
        game.update(1 / 60);
        t += 1 / 60;
      }
      game.controls.keyboard.right = false;
      expect(p.center.x, greaterThanOrEqualTo(lever.position.x));
      t = 0;
      while (p.shadowSent && t < 20) {
        game.update(1 / 60);
        t += 1 / 60;
      }
      expect(p.shadowSent, isFalse, reason: 'gölge döner');
    },
  );
}
