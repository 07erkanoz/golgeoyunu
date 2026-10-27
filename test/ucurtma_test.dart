// III · Gökyolu uzatması: uçurtmalar rüzgârda salınır, üstündekini taşır;
// lodos ve poyraz Yel düzeneğiyle eser.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/gok_katlari.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kaf_vadi.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void main() {
  testWithGame<GolgeGame>('uçurtma salınır, üstündekini taşır; rüzgâr eser',
      GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(2);
    await game.ready();
    game.cinematic = false;
    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }
    final kites = game.world.children.whereType<KiteDeck>().toList();
    expect(kites.length, 6);
    expect(game.world.children.whereType<YelZone>().length, 3);
    final k = kites.first;
    final p = game.player!;
    p.position.setValues(k.center.x - Player.w / 2, k.position.y - Player.h - 1);
    p.velocity.setZero();
    final xs = <double>[];
    for (var i = 0; i < 60 * 3; i++) {
      game.update(1 / 60);
      xs.add(p.center.x);
    }
    expect(p.isDead, isFalse);
    expect(p.riding, same(k));
    final span = xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b);
    expect(span, greaterThan(40), reason: 'uçurtmayla salınır');
  });

  testWithGame<GolgeGame>(
      'lodos hep arkadan eser: duranı itmez, süzüleni boşluğun öbür yanına taşır',
      GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(2);
    await game.ready();
    game.cinematic = false;
    game.wingsCollected = true;
    final p = game.player!;
    p.position.setFrom(
        Level.standOn(Vector2(290 * kTile, 7 * kTile), Player.w, Player.h));
    p.velocity.setZero();
    for (var i = 0; i < 60 * 3; i++) {
      game.update(1 / 60);
    }
    expect(p.onGround, isTrue, reason: 'lodos adacıktakini itip düşürmez');
    expect(p.center.x, lessThan(291 * kTile));
    final k = game.controls.keyboard;
    k.right = true;
    var jumped = false;
    for (var i = 0; i < 60 * 5 && !p.isDead; i++) {
      if (!jumped && p.position.x + Player.w > 291 * kTile - 6) jumped = true;
      k.jump = jumped;
      game.update(1 / 60);
      if (jumped && p.onGround && p.center.x > 300 * kTile) break;
    }
    k
      ..right = false
      ..jump = false;
    expect(p.isDead, isFalse);
    expect(p.center.x, greaterThan(302 * kTile),
        reason: 'lodos süzüleni ileri taşır');
  });
}
