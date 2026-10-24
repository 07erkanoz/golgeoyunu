// Kandilci yolu (Gökyolu): soğuk ışık tahtaları Sâye'nin ışığıyla belirmez;
// ateşböceği atılınca Kandilci kenarda ona dalar, feneri yolu gösterir,
// Sâye onun ışığında yakalanmadan karşıya geçer.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

void main() {
  final li = levels.indexWhere((d) => d.coldRuns.isNotEmpty);

  testWithGame<GolgeGame>(
    'Sâye\'nin ışığı Kandilci yolunu yakmaz',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(li);
      await game.ready();
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      await game.ready();
      final p = game.player!;
      final (col, row, _) = levels[li].coldRuns.first;
      p.position.setFrom(
        Level.standOn(
          Vector2((col - 1) * kTile.toDouble(), (row - 1) * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      final bridge = game.world.children.whereType<PhasePlank>().firstWhere(
        (k) => k.cold,
      );
      expect(p.isDead, isFalse);
      expect(bridge.active, isFalse);
    },
  );

  testWithGame<GolgeGame>('Kandilci yolu', GolgeGame.new, (game) async {
    expect(li, greaterThanOrEqualTo(0));
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(li);
    await game.ready();
    final p = game.player!;
    final bridge = game.world.children.whereType<PhasePlank>().firstWhere(
      (k) => k.cold,
    );
    final g = game.world.children.whereType<Guard>().reduce(
      (a, b) =>
          (a.center.x - bridge.position.x).abs() <
              (b.center.x - bridge.position.x).abs()
          ? a
          : b,
    );
    // Saklanma sütununda (I) çömelip bekle.
    final (col, row, _) = levels[li].coldRuns.first;
    p.position.setFrom(
      Level.standOn(
        Vector2((col - 10) * kTile.toDouble(), (row - 1) * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    game.controls.keyboard.down = true;
    var t = 0.0;
    while (t < 1) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    // Kandilci kenara dönünce (sırtı Sâye'ye) ateşböceği atılır.
    t = 0;
    while ((g.facing < 0 || bridge.position.x - g.center.x > 8 * kTile) &&
        t < 60) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    expect(p.isDead, isFalse);
    game.fireflies = 3;
    game.releaseFirefly(p.light.$1, 1);
    t = 0;
    while (!g.distracted && t < 4) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    expect(g.distracted, isTrue, reason: 'Kandilci ateşböceğine dalar');
    t = 0;
    while (!bridge.active && t < 3) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    expect(bridge.active, isTrue, reason: 'fener yolu gösterir');
    // Koşup karşıya geç.
    game.controls.keyboard.down = false;
    game.controls.keyboard.right = true;
    t = 0;
    final far = bridge.position.x + bridge.size.x + kTile;
    while (p.center.x < far && t < 5 && !p.isDead) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    game.controls.keyboard.right = false;
    expect(p.isDead, isFalse, reason: 'dalgın Kandilci görmez, yol taşır');
    expect(p.center.x, greaterThanOrEqualTo(far), reason: 'karşıya geçildi');
  });
}
