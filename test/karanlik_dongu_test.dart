// Karanlık bölge: ateşböcekleri tükenince karanlık Sâye'yi yutar. Yeniden
// doğarken kavanoz dolar; yoksa kontrol noktasındaki az ateşböceğiyle aynı
// karanlıkta yeniden yutulurdu (bitmeyen döngü). Kulenin zindanı karanlık
// değildir: oyun orada başlar, ateşböcekleri sönmez.
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

void main() {
  testWithGame<GolgeGame>('karanlık yutunca kavanoz dolu doğulur',
      GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(5);
    await game.ready();
    game.cinematic = false;
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    final zone = game.level.darkZones.first;
    final p = game.player!;
    p.position.setFrom(Level.standOn(
        Vector2(zone.center.dx, zone.bottom - kTile), Player.w, Player.h));
    game.debugCheckpoint();
    game.fireflies = 0;
    run(game, GolgeGame.darkSwallow + 0.5);
    expect(p.isDead, isTrue, reason: 'karanlık yuttu');
    run(game, 4);
    await game.ready();
    expect(game.player!.isDead, isFalse);
    expect(game.fireflies, GolgeGame.maxFireflies);
  });

  testWithGame<GolgeGame>('kulenin zindanında ateşböcekleri sönmez',
      GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(1);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    expect(game.level.inDarkZone(p.center), isFalse);
    final before = game.fireflies;
    run(game, 20);
    expect(game.fireflies, before);
  });
}
