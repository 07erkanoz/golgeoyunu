// Yerebatan'ın öğretim alanı: her durakta kendiliğinden beliren levha.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/lesson.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

void main() {
  const stops = [
    ('move', 3, 13),
    ('pickup', 7, 13),
    ('jump', 12, 13),
    ('climb', 16, 13),
    ('umay', 20, 6),
    ('crate', 26, 13),
    ('ledge', 32, 13),
    ('lever', 49, 13),
    ('hide', 66, 13),
    ('throw', 106, 13),
    ('help', 127, 13),
  ];
  testWithGame<GolgeGame>('öğretim levhaları sırayla belirir', GolgeGame.new, (
    game,
  ) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    final signs = game.world.children.whereType<LessonSigns>().single;
    for (final (key, c, r) in stops) {
      p.position.setFrom(
        Level.standOn(
          Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
      for (var k = 0; k < 60; k++) {
        game.update(1 / 60);
      }
      expect(signs.activeKey, key, reason: 'sütun $c');
    }
    // Öğretim alanının ötesinde levha yok.
    p.position.setFrom(
      Level.standOn(
        Vector2(150 * kTile.toDouble(), 13 * kTile.toDouble()),
        Player.w,
        Player.h,
      ),
    );
    for (var k = 0; k < 60; k++) {
      game.update(1 / 60);
    }
    expect(signs.activeKey, isNull);
  });

  testWithGame<GolgeGame>('ipuçları kapalıysa levha çıkmaz', GolgeGame.new, (
    game,
  ) async {
    Settings.hints = false;
    addTearDown(() => Settings.hints = true);
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    for (var k = 0; k < 60; k++) {
      game.update(1 / 60);
    }
    expect(
      game.world.children.whereType<LessonSigns>().single.activeKey,
      isNull,
    );
  });
}
