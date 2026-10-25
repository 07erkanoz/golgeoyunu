// IV · Kaf'ın vadileri: Hayret Vadisi (yalnız yansımada görünen
// basamaklar, rüzgârla bozulan yansıma) ve Otuz Kuş (kuşlardan köprü,
// Gözcü'nün feneri kuşu ürkütür, ateşböceği feneri oyalar).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kaf_vadi.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<void> load(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(3);
  await game.ready();
  game.cinematic = false;
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
}

void main() {
  testWithGame<GolgeGame>('görünmeyen basamak taşır; göl arada dalgalanır',
      GolgeGame.new, (game) async {
    await load(game);
    final step = game.world.children.whereType<MirrorStep>().first;
    final lake = game.world.children.whereType<MirrorLake>().single;
    final p = game.player!;
    p.position.setValues(step.position.x + 10, step.position.y - Player.h - 2);
    p.velocity.setZero();
    var waved = false;
    for (var i = 0; i < 60 * (MirrorLake.period + 1); i++) {
      game.update(1 / 60);
      if (lake.wave > 0.5) waved = true;
    }
    expect(p.isDead, isFalse);
    expect(p.riding, same(step));
    expect(waved, isTrue);
  });

  testWithGame<GolgeGame>('kuşun sırtındaki Sâye sürüyle taşınır',
      GolgeGame.new, (game) async {
    await load(game);
    for (final w in game.world.children.whereType<Watcher>().toList()) {
      w.removeFromParent();
    }
    run(game, 1);
    final birds = game.world.children.whereType<BirdDeck>().toList();
    final bird = birds.firstWhere(
      (b) => b.active && b.position.x > 278 * kTile && b.position.x < 290 * kTile,
    );
    final p = game.player!;
    p.position.setValues(bird.center.x - Player.w / 2, bird.position.y - Player.h - 1);
    p.velocity.setZero();
    final x0 = p.center.x;
    run(game, 1);
    expect(p.isDead, isFalse);
    expect(onBird(p), isTrue);
    expect(p.center.x, greaterThan(x0 + 30));
  });

  testWithGame<GolgeGame>(
    'Gözcü\'nün feneri kuşu ürkütür; ateşböceği feneri oyalarken ürkmez',
    GolgeGame.new,
    (game) async {
      await load(game);
      final birds = game.world.children.whereType<BirdDeck>().toList();
      final w = game.world.children
          .whereType<Watcher>()
          .firstWhere((w) => w.position.x > 270 * kTile);
      // Sâye uzakta, fenere görünmesin.
      game.player!.position.setValues(258 * kTile, 10 * kTile);
      var scared = false;
      for (var i = 0; i < 60 * 20 && !scared; i++) {
        game.update(1 / 60);
        scared = birds.any((b) => b.scared);
      }
      expect(scared, isTrue, reason: 'fener sürüyü tarar');
      run(game, 3);
      // Ateşböceği fenerin yanında, yukarıda: feneri oyalar.
      final lure = FireflyLure(w.lamp + Vector2(-60, -90), -1);
      game.world.add(lure);
      await game.ready();
      run(game, 0.6);
      var again = false;
      for (var i = 0; i < 60 * 4; i++) {
        game.update(1 / 60);
        if (lure.glowing && birds.any((b) => b.scared)) again = true;
      }
      expect(again, isFalse);
    },
  );

  testWithGame<GolgeGame>('Ayna Salonu\'nun önünde otuz kuş havalanır',
      GolgeGame.new, (game) async {
    await load(game);
    final ring = game.world.children.whereType<BirdRing>().single;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(ring.position - Vector2(3 * kTile, kTile.toDouble()),
          Player.w, Player.h),
    );
    run(game, 0.5);
    expect(ring.flying, isTrue);
  });
}
