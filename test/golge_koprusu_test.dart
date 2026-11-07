// Gölge köprüsü (Peri Bacaları): çıkış zincirinin önünde uçurum. Gölge
// boşlukta da yürür, ardında mürekkep tahtalar kalır; Sâye peşinden geçer.
// Gölge dönünce tahtalar az sonra dağılır.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shadow_decoy.dart';

Future<(ShadowStone, List<InkPlank>)> _setup(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  final li = levels.indexWhere((d) => d.shadowBridges.isNotEmpty);
  expect(li, greaterThanOrEqualTo(0));
  game.debugLoadLevel(li);
  await game.ready();
  game.cinematic = false;
  game.update(1 / 60);
  final planks = game.world.children.whereType<InkPlank>().toList()
    ..sort((a, b) => a.position.x.compareTo(b.position.x));
  final stone = game.world.children.whereType<ShadowStone>().reduce(
    (a, b) =>
        (a.position.x - planks.first.position.x).abs() <
            (b.position.x - planks.first.position.x).abs()
        ? a
        : b,
  );
  final p = game.player!;
  p.position.setValues(
    stone.position.x - Player.w / 2,
    stone.position.y - Player.h,
  );
  p.velocity.setZero();
  for (var i = 0; i < 20; i++) {
    game.update(1 / 60);
  }
  expect(p.onGround, isTrue);
  return (stone, planks);
}

void main() {
  testWithGame<GolgeGame>('gölgesiz uçuruma yürüyen düşer', GolgeGame.new, (
    game,
  ) async {
    final (_, planks) = await _setup(game);
    final p = game.player!;
    game.controls.keyboard.right = true;
    var died = false;
    for (var i = 0; i < 60 * 5 && !died; i++) {
      game.update(1 / 60);
      game.cinematic = false;
      if (p.isDead) died = true;
    }
    expect(died, isTrue);
    expect(planks.every((k) => !k.laid), isTrue);
  });

  testWithGame<GolgeGame>(
    'gölge boşlukta yürür, köprü kurulur, Sâye geçer; köprü sonra dağılır',
    GolgeGame.new,
    (game) async {
      final (stone, planks) = await _setup(game);
      final p = game.player!;
      game.controls.keyboard.right = true;
      game.update(1 / 60);
      game.controls.keyboard.right = false;
      p.position.x = stone.position.x - Player.w / 2;
      stone.use();
      for (var i = 0; i < 60 * 8 && !planks.last.laid; i++) {
        game.update(1 / 60);
      }
      expect(planks.every((k) => k.laid), isTrue, reason: 'köprü tamam');
      game.controls.keyboard.right = true;
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
        game.cinematic = false;
      }
      game.controls.keyboard.right = false;
      expect(p.isDead, isFalse);
      expect(
        p.center.x,
        greaterThan(planks.last.position.x + kTile),
        reason: 'uçurumu geçti',
      );
      for (var i = 0; i < 60 * 16 && p.shadowSent; i++) {
        game.update(1 / 60);
      }
      expect(p.shadowSent, isFalse);
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
      }
      expect(planks.every((k) => !k.laid), isTrue, reason: 'köprü dağıldı');
    },
  );
}
