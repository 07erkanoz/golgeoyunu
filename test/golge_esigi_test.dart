// Gölge eşiği (Ergenekon): salonun çıkış kapısı yalnız gölge eşikte
// durdukça açıktır. Sâye eşiğe basınca bir şey olmaz; gölgesini eşiğe
// gönderip kapıya koşarsa geçer ve kapı açık kalır; geç kalırsa kapı iner.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shadow_decoy.dart';

Future<(ShadowStone, ShadowPlate, Gate)> _setup(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  final li = levels.indexWhere((d) => d.shadowPlates.isNotEmpty);
  expect(li, greaterThanOrEqualTo(0));
  game.debugLoadLevel(li);
  await game.ready();
  game.cinematic = false;
  game.update(1 / 60);
  final plate = game.world.children.whereType<ShadowPlate>().single;
  final stone = game.world.children.whereType<ShadowStone>().reduce(
    (a, b) =>
        (a.position.x - plate.position.x).abs() <
            (b.position.x - plate.position.x).abs()
        ? a
        : b,
  );
  final gate = plate.gate!;
  expect(gate.tied, isTrue);
  return (stone, plate, gate);
}

void _standAt(GolgeGame game, double x) {
  final p = game.player!;
  p.position.setValues(x - Player.w / 2, 34 * kTile + kTile - Player.h);
  p.velocity.setZero();
  for (var i = 0; i < 20; i++) {
    game.update(1 / 60);
  }
  expect(p.onGround, isTrue);
}

/// Gölgeyi [x]'e yürütür (oyuncunun eli: yön tuşu).
void _steerTo(GolgeGame game, double x) {
  final p = game.player!;
  final k = game.controls.keyboard;
  for (var i = 0; i < 60 * 6; i++) {
    final dx = x - p.shadowFeet.x;
    if (dx.abs() < 3) break;
    k.left = dx < 0;
    k.right = dx > 0;
    game.update(1 / 60);
  }
  k.left = k.right = false;
  game.update(1 / 60);
}

void _face(GolgeGame game, {required bool left}) {
  final k = game.controls.keyboard;
  if (left) {
    k.left = true;
  } else {
    k.right = true;
  }
  game.update(1 / 60);
  k.left = k.right = false;
}

void main() {
  testWithGame<GolgeGame>('Sâye eşiğe basınca kapı açılmaz', GolgeGame.new, (
    game,
  ) async {
    final (_, plate, gate) = await _setup(game);
    _standAt(game, plate.position.x);
    for (var i = 0; i < 60 * 2; i++) {
      game.update(1 / 60);
    }
    expect(gate.solid, isTrue);
    // Kapıya yürür: geçemez.
    game.controls.keyboard.right = true;
    for (var i = 0; i < 60 * 6; i++) {
      game.update(1 / 60);
      game.cinematic = false;
    }
    game.controls.keyboard.right = false;
    expect(game.player!.position.x, lessThan(gate.position.x));
  });

  testWithGame<GolgeGame>(
    'gölge eşikte, Sâye kapıda: geçer, kapı açık kalır',
    GolgeGame.new,
    (game) async {
      final (stone, plate, gate) = await _setup(game);
      _standAt(game, stone.position.x);
      _face(game, left: true);
      game.player!.position.x = stone.position.x - Player.w / 2;
      stone.use();
      _steerTo(game, plate.position.x);
      expect(plate.pressed, isTrue, reason: 'gölge eşiğe vardı');
      // Gölgeyi eşikte bırak, Sâye'yle kapıya koş.
      game.controls.queueShadow();
      game.update(1 / 60);
      final p = game.player!;
      game.controls.keyboard.right = true;
      for (var i = 0; i < 60 * 4; i++) {
        game.update(1 / 60);
        game.cinematic = false;
      }
      game.controls.keyboard.right = false;
      expect(p.isDead, isFalse);
      expect(
        p.position.x,
        greaterThan(gate.position.x + gate.size.x),
        reason: 'kapıdan geçti',
      );
      expect(gate.opening, isTrue, reason: 'geçince kapı açık kalır');
      for (var i = 0; i < 60 * 8; i++) {
        game.update(1 / 60);
      }
      expect(gate.solid, isFalse);
    },
  );

  testWithGame<GolgeGame>('geç kalana kapı iner', GolgeGame.new, (
    game,
  ) async {
    final (stone, plate, gate) = await _setup(game);
    _standAt(game, stone.position.x);
    _face(game, left: true);
    game.player!.position.x = stone.position.x - Player.w / 2;
    stone.use();
    _steerTo(game, plate.position.x);
    game.controls.queueShadow();
    var opened = false;
    for (var i = 0; i < 60 * 14; i++) {
      game.update(1 / 60);
      if (!gate.solid) opened = true;
    }
    expect(opened, isTrue, reason: 'gölge eşikteyken kapı kalktı');
    expect(plate.pressed, isFalse);
    expect(gate.solid, isTrue, reason: 'gölge dönünce kapı indi');
    expect(gate.opening, isFalse);
  });
}
