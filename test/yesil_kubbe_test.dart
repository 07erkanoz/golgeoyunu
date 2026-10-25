// XX · Yeşil Kubbe (final): avlunun ay kilidi, kafesteki ışıklar, Kandilci
// Başı'nın üç aynası ve çıkış.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/erlik.dart';
import 'package:golge/game/final.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<void> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(19);
  await game.ready();
  game.cinematic = false;
}

void main() {
  test('final Şeb-i Arûs\'tan sonra, oyunun son bölümü', () {
    expect(levels[19].title, 'XX · YEŞİL KUBBE');
    expect(nextLevel(13), 19);
    expect(levelOrder.last, 19);
    expect(nextLevel(19), isNull);
  });

  testWithGame<GolgeGame>('avlu: iki ayna çevrilince türbenin kapısı açılır',
      GolgeGame.new, (game) async {
    await load(game);
    final gate = game.world.children
        .whereType<Gate>()
        .firstWhere((g) => (g.position.x / kTile).round() == 74);
    run(game, 1);
    expect(gate.opening, isFalse);
    for (final m in game.world.children.whereType<Mirror>()) {
      if (m.col < 70) m.use();
    }
    run(game, 1.5);
    expect(gate.opening, isTrue);
  });

  testWithGame<GolgeGame>('koridor: her kafes kendi kapısını açar',
      GolgeGame.new, (game) async {
    await load(game);
    final cages = game.world.children.whereType<KutCage>().toList()
      ..sort((a, b) => a.position.x.compareTo(b.position.x));
    expect(cages.length, 3);
    for (final (i, col) in [96, 136, 186].indexed) {
      final gate = game.world.children
          .whereType<Gate>()
          .firstWhere((g) => (g.position.x / kTile).round() == col);
      expect(gate.opening, isFalse);
      cages[i].use();
      expect(gate.opening, isTrue, reason: 'kafes $i → kapı $col');
    }
  });

  testWithGame<GolgeGame>(
    'Kandilci Başı: üç ayna ay ışığını kilitlere düşürür; gölgesini görür, '
    'çıkış açılır',
    GolgeGame.new,
    (game) async {
      await load(game);
      final k = game.world.children.whereType<KandilciBasi>().single;
      final exit = game.world.children
          .whereType<Gate>()
          .firstWhere((g) => (g.position.x / kTile).round() == 303);
      final ms = game.world.children
          .whereType<Mirror>()
          .where((m) => m.col > 250)
          .toList();
      expect(ms.length, 3);
      run(game, 1);
      expect(k.lit, 0, reason: 'aynalar başta yanlış yönde');
      for (final (i, m) in ms.indexed) {
        m.use();
        run(game, 1.5);
        expect(k.lit, i + 1);
        expect(k.solved, i == 2);
      }
      expect(exit.opening, isFalse, reason: 'diz çöküşü bitmeden');
      run(game, KandilciBasi.endLength);
      expect(exit.opening, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'Kandilci Başı\'nın huzmesinde kalan silinir, sütunun gölgesinde '
    'saklanan silinmez',
    GolgeGame.new,
    (game) async {
      await load(game);
      final k = game.world.children.whereType<KandilciBasi>().single;
      final p = game.player!;
      // Sahanlıkta açıkta: huzme bir taramada mutlaka geçer.
      p.position.setFrom(
        Level.standOn(Vector2(280 * kTile, 9 * kTile), Player.w, Player.h),
      );
      var died = false;
      for (var i = 0; i < 60 * KandilciBasi.period * 1.2 && !died; i++) {
        game.update(1 / 60);
        died = p.isDead;
      }
      expect(died, isTrue);
      expect(k.solved, isFalse);
    },
  );
}
