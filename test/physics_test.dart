import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

/// Sabit adımlı simülasyon: oyuncuyu bir hücreye koyar, girişi uygular.
Future<Player> place(GolgeGame game, int levelIndex, int col, int row) async {
  game.debugLoadLevel(levelIndex);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  return p;
}

void run(GolgeGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
  }
}

Buttons keys(GolgeGame g) => g.controls.keyboard;

Guard guardOf(GolgeGame g) => g.world.children.whereType<Guard>().first;

void main() {
  group('hareket', () {
    testWithGame<GolgeGame>('zıplama yaklaşık 3 kare yükselir', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 0, 3, 13);
      run(game, 0.3);
      final ground = p.position.y;
      keys(game).jump = true;
      var minY = ground;
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
        if (p.position.y < minY) minY = p.position.y;
      }
      expect(ground - minY, inInclusiveRange(80, 100));
    });

    testWithGame<GolgeGame>(
      'iskeledeki boşluğun üstünden atlanır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 10, 13);
        run(game, 0.2);
        keys(game).right = true;
        for (
          var i = 0;
          i < 300 && p.position.x + Player.w < 14 * kTile - 4;
          i++
        ) {
          game.update(1 / 60);
        }
        keys(game).jump = true;
        run(game, 1.0);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(16 * kTile));
      },
    );

    testWithGame<GolgeGame>('suya düşen boğulur', GolgeGame.new, (game) async {
      final p = await place(game, 0, 14, 13);
      run(game, 1.5);
      expect(p.isDead, isTrue);
    });

    testWithGame<GolgeGame>(
      '3 karelik basamakta kenara tutunup tırmanır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 62, 13);
        run(game, 0.2);
        keys(game).right = true;
        run(game, 0.4);
        keys(game).jump = true;
        var grabbed = false;
        for (var i = 0; i < 90 && !grabbed; i++) {
          game.update(1 / 60);
          grabbed = p.state == PlayerState.hang;
        }
        expect(grabbed, isTrue, reason: 'kenara tutunamadı');
        keys(game).jump = false;
        run(game, 0.1);
        keys(game).up = true;
        run(game, 0.6);
        keys(game).up = false;
        run(game, 0.2);
        expect(p.onGround, isTrue);
        expect(p.position.y + Player.h, closeTo(11 * kTile, 0.5));
      },
    );

    testWithGame<GolgeGame>(
      'zincire tutunup kemerlerin üstüne çıkar',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 17, 13);
        run(game, 0.2);
        keys(game).jump = true;
        var onChain = false;
        for (var i = 0; i < 60 && !onChain; i++) {
          game.update(1 / 60);
          onChain = p.state == PlayerState.vine;
        }
        expect(onChain, isTrue, reason: 'zinciri yakalayamadı');
        keys(game)
          ..jump = false
          ..up = true;
        run(game, 3);
        keys(game)
          ..up = false
          ..right = true
          ..jump = true;
        run(game, 1.2);
        expect(p.onGround, isTrue);
        expect(p.position.y + Player.h, closeTo(7 * kTile, 0.5));
      },
    );
  });

  group('Kandilci', () {
    testWithGame<GolgeGame>(
      'sütunun ardında saklananın önünden geçip gider',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 21, 13);
        run(game, 0.3);
        expect(p.hidden, isTrue);
        final guard = guardOf(game);
        var passed = false;
        for (var i = 0; i < 60 * 14; i++) {
          game.update(1 / 60);
          if (guard.position.x + Guard.gw < p.position.x) passed = true;
        }
        expect(p.isDead, isFalse);
        expect(passed, isTrue, reason: 'Kandilci oyuncunun önünden geçmeliydi');
      },
    );

    testWithGame<GolgeGame>('arkasından koşan oyuncuyu duyar', GolgeGame.new, (
      game,
    ) async {
      await place(game, 0, 39, 13);
      keys(game).left = true;
      run(game, 0.6);
      expect(guardOf(game).state, isNot(GuardState.patrol));
    });

    testWithGame<GolgeGame>('parmak ucunda yürüyeni duymaz', GolgeGame.new, (
      game,
    ) async {
      await place(game, 0, 39, 13);
      keys(game)
        ..sneak = true
        ..left = true;
      run(game, 0.6);
      expect(guardOf(game).state, GuardState.patrol);
    });

    testWithGame<GolgeGame>(
      'görünce hemen saldırmaz, önce şüphelenir',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 27, 13);
        run(game, 0.15);
        final guard = guardOf(game);
        expect(guard.suspicion, greaterThan(0));
        expect(guard.state, isNot(GuardState.chase));
        expect(p.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'salınan ateşböceği Kandilciyi kendine çeker',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 3, 13);
        run(game, 0.2);
        final guard = guardOf(game);
        final before = game.fireflies;
        game.releaseFirefly(guard.position + Vector2(-120, 10), -1);
        run(game, 0.5);
        expect(game.fireflies, before - 1);
        expect(guard.state, GuardState.investigate);
      },
    );
  });

  group('bulmaca', () {
    testWithGame<GolgeGame>('uzun bir karede sandık zeminden düşmez', GolgeGame.new, (game) async {
      await place(game, 0, 3, 13);
      final crate = game.world.children.whereType<Crate>().first;
      final y0 = crate.position.y;
      game.update(0.6);
      run(game, 0.5);
      expect(crate.isMounted, isTrue);
      expect(crate.position.y, closeTo(y0, 0.5));
    });

    testWithGame<GolgeGame>('sandık itilir', GolgeGame.new, (game) async {
      await place(game, 0, 48, 13);
      final crate = game.world.children.whereType<Crate>().first;
      final x0 = crate.position.x;
      keys(game).right = true;
      run(game, 1.5);
      expect(crate.position.x, greaterThan(x0 + kTile));
    });

    testWithGame<GolgeGame>(
      'sandığın üstünden kolun çıkıntısına tutunulur',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 48, 13);
        final crate = game.world.children.whereType<Crate>().first;
        crate.position.x = 52 * kTile + 1;
        run(game, 0.1);
        p.position.setValues(crate.position.x + 6, crate.position.y - Player.h);
        run(game, 0.2);
        expect(p.onGround, isTrue, reason: 'sandığın üstünde durmalı');
        keys(game)
          ..jump = true
          ..right = true;
        var grabbed = false;
        for (var i = 0; i < 90 && !grabbed; i++) {
          game.update(1 / 60);
          grabbed = p.state == PlayerState.hang;
        }
        expect(grabbed, isTrue, reason: 'çıkıntıya tutunamadı');
      },
    );

    testWithGame<GolgeGame>(
      'kapı kapalıyken geçilmez, kol çekilince açılır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 58, 13);
        keys(game).right = true;
        run(game, 1.0);
        expect(p.position.x + Player.w, lessThanOrEqualTo(60 * kTile + 8.5));
        keys(game).right = false;

        p.position.setFrom(
          Level.standOn(Vector2(55 * kTile, 9 * kTile), Player.w, Player.h),
        );
        run(game, 0.2);
        keys(game).up = true;
        run(game, 0.05);
        keys(game).up = false;
        expect(game.world.children.whereType<Lever>().first.pulled, isTrue);
        run(game, 2.5);
        expect(game.world.children.whereType<Gate>().first.solid, isFalse);
      },
    );
  });

  group('kayalıklar', () {
    testWithGame<GolgeGame>(
      'kayadan koşarak sarmaşığa atlar ve tırmanır',
      GolgeGame.new,
      (game) async {
        // Kaya çıkıntısının sağ ucundan (satır 38) sola koşup kenarda zıplar.
        final p = await place(game, 1, 17, 37);
        run(game, 0.2);
        expect(p.onGround, isTrue);
        keys(game).left = true;
        for (var i = 0; i < 120 && p.position.x > 14 * kTile + 2; i++) {
          game.update(1 / 60);
        }
        keys(game).jump = true;
        var onVine = false;
        for (var i = 0; i < 90 && !onVine; i++) {
          game.update(1 / 60);
          onVine = p.state == PlayerState.vine;
        }
        expect(onVine, isTrue, reason: 'sarmaşığı yakalayamadı');
        keys(game)
          ..left = false
          ..jump = false
          ..up = true;
        run(game, 5);
        expect(p.position.y + Player.h / 2, lessThan(26 * kTile));
      },
    );
  });

  testWithGame<GolgeGame>(
    'parmak ucunda yavaşlar ve ışığı kısılır',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 0, 3, 13);
      run(game, 0.2);
      final open = p.light.$2;
      keys(game)
        ..sneak = true
        ..right = true;
      run(game, 0.6);
      expect(p.sneaking, isTrue);
      expect(p.velocity.x, lessThanOrEqualTo(Player.sneakSpeed + 0.01));
      expect(p.light.$2, lessThan(open));
    },
  );
}
