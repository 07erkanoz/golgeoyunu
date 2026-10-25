// III · Gökyolu uzatması: uçurtmalar rüzgârda salınır, üstündekini taşır;
// lodos ve poyraz Yel düzeneğiyle eser.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/gok_katlari.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kaf_vadi.dart';
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
}
