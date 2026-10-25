// VIII · Gün Doğumu, Şafağın Gölgeleri: Kandilciler gölgeden çıkmaz,
// güneşteki Sâye'yi görmez; güneş yükseldikçe gölgeler kısalır.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/dawn.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<(DawnShadows, List<Guard>)> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(7);
  await game.ready();
  game.cinematic = false;
  final dawn = game.world.children.whereType<DawnShadows>().single;
  final guards = game.world.children
      .whereType<Guard>()
      .where((g) => dawn.covers(g.center.x))
      .toList();
  return (dawn, guards);
}

void main() {
  testWithGame<GolgeGame>('güneş yükseldikçe gölgeler kısalır', GolgeGame.new,
      (game) async {
    final (dawn, guards) = await load(game);
    for (final g in guards) {
      g.removeFromParent();
    }
    final p = game.player!;
    final long = dawn.shadowLength;
    p.position.setFrom(
      Level.standOn(Vector2(131 * kTile, 19 * kTile), Player.w, Player.h),
    );
    run(game, DawnShadows.rise + 1);
    expect(p.isDead, isFalse);
    expect(dawn.shadowLength, lessThan(long * 0.3));
  });

  testWithGame<GolgeGame>('Kandilciler gölgeden çıkmaz', GolgeGame.new,
      (game) async {
    final (dawn, guards) = await load(game);
    expect(guards.length, 3);
    dawn.debugRise = 0.8;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(Vector2(60 * kTile, 19 * kTile), Player.w, Player.h),
    );
    for (var i = 0; i < 60 * 30; i++) {
      game.update(1 / 60);
      for (final g in guards) {
        final front = g.facing > 0 ? g.position.x + Guard.gw : g.position.x;
        expect(dawn.sunlit(front - g.facing * 2), isFalse,
            reason: 'Kandilci güneşe çıktı (${g.center.x / kTile})');
      }
    }
  });

  testWithGame<GolgeGame>(
    'güneşteki Sâye görülmez, gölgedeki görülür',
    GolgeGame.new,
    (game) async {
      final (dawn, guards) = await load(game);
      dawn.debugRise = 0.8;
      final g = guards.first;
      final p = game.player!;
      // Kandilcinin önünde, gölgenin bittiği yerin hemen ötesinde güneşte.
      var x = g.center.x;
      while (dawn.inShadow(x)) {
        x -= 4;
      }
      p.position.setFrom(
        Level.standOn(Vector2(x - kTile, 19 * kTile), Player.w, Player.h),
      );
      g.facing = -1;
      run(game, 3);
      expect(p.isDead, isFalse);
      expect(g.state == GuardState.chase, isFalse);
    },
  );
}
