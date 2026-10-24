// Yol gösterme: bulmacada takılan oyuncuya önce kamera sıradaki adımı
// gösterir (ılık halka), sonra gölge oraya yürüyüp zıplar ve döner.
// Kullanılan düzenek artık sıradaki adım değildir.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/guide.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> _atPerde(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(0);
  await game.ready();
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
  final p = game.player!;
  final cord = game.world.children.whereType<PerdeCord>().first;
  p.position.setFrom(
    Level.standOn(
      Vector2(cord.position.x + 5 * kTile, cord.position.y - kTile),
      Player.w,
      Player.h,
    ),
  );
  return p;
}

void main() {
  testWithGame<GolgeGame>(
    'perdede takılana önce kamera, sonra gölge',
    GolgeGame.new,
    (game) async {
      final p = await _atPerde(game);
      run(game, 1);
      expect(game.guide.current?.hint, 'cord', reason: 'sıradaki adım ip');
      run(game, Guide.showAfter - 1);
      expect(game.world.children.whereType<GuideMark>(), isEmpty);
      run(game, 1.5);
      expect(game.guide.stage, 1);
      expect(
        game.world.children.whereType<GuideMark>(),
        isNotEmpty,
        reason: 'gösterilen yerde halka',
      );
      run(game, Guide.walkAfter - Guide.showAfter);
      expect(p.shadowGuiding, isTrue, reason: 'gölge yola çıkar');
      run(game, 12);
      expect(p.shadowGuiding, isFalse, reason: 'gösterip döner');
    },
  );

  testWithGame<GolgeGame>(
    'aynı yerde iki ölüm: beklemeden gösterir',
    GolgeGame.new,
    (game) async {
      await _atPerde(game);
      run(game, 1);
      final at = game.guide.current!.at;
      game.guide.onDeath(at);
      game.guide.onDeath(at);
      run(game, 0.6);
      expect(game.guide.stage, 1);
    },
  );

  testWithGame<GolgeGame>(
    'kullanılan düzenek sıradaki adım olmaz',
    GolgeGame.new,
    (game) async {
      await _atPerde(game);
      run(game, 1);
      final valves = game.world.children.whereType<Valve>().toList();
      for (final v in valves) {
        game.guide.markUsed(v);
      }
      final next = game.guide.debugNext();
      expect(next?.key.startsWith('Valve'), isNot(isTrue));
    },
  );
}
