import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/mechanics.dart';
import 'package:golge/game/perde.dart';
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

/// Verilen x konumuna en yakın bileşen.
T nearest<T extends PositionComponent>(GolgeGame g, double x) {
  final all = g.world.children.whereType<T>().toList()
    ..sort(
      (a, b) => (a.position.x - x).abs().compareTo((b.position.x - x).abs()),
    );
  return all.first;
}

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

  group('ateşböceği ve rehber', () {
    testWithGame<GolgeGame>(
      'ateşböceğine dalan Kandilci değince bile yakalamaz',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 3, 13);
        run(game, 0.2);
        final guard = guardOf(game);
        game.releaseFirefly(guard.center + Vector2(-60, -10), -1);
        run(game, 0.3);
        expect(guard.distracted, isTrue);
        p.position.setValues(
          guard.position.x + 4,
          guard.position.y + Guard.gh - Player.h,
        );
        run(game, 0.5);
        expect(p.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'ateşböceği sürüsünden kavanoza ateşböceği alınır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 5, 13);
        final before = game.fireflies;
        keys(game).right = true;
        run(game, 0.6);
        expect(p.isDead, isFalse);
        expect(game.fireflies, before + 1);
      },
    );

    testWithGame<GolgeGame>(
      'güvercin yaklaşınca bir sonraki konağa uçar',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 3, 13);
        final bird = game.world.children.whereType<Bird>().first;
        final x0 = bird.position.x;
        keys(game).right = true;
        run(game, 2.5);
        expect(bird.position.x, greaterThan(x0 + 4 * kTile));
      },
    );
  });

  group('bulmaca', () {
    testWithGame<GolgeGame>(
      'uzun bir karede sandık zeminden düşmez',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 3, 13);
        final crate = nearest<Crate>(game, 49 * kTile);
        final y0 = crate.position.y;
        game.update(0.6);
        run(game, 0.5);
        expect(crate.isMounted, isTrue);
        expect(crate.position.y, closeTo(y0, 0.5));
      },
    );

    testWithGame<GolgeGame>('sandık itilir', GolgeGame.new, (game) async {
      await place(game, 0, 48, 13);
      final crate = nearest<Crate>(game, 49 * kTile);
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
        final crate = nearest<Crate>(game, 49 * kTile);
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
        expect(nearest<Lever>(game, 55 * kTile).pulled, isTrue);
        run(game, 2.5);
        expect(nearest<Gate>(game, 60 * kTile).solid, isFalse);
      },
    );
  });

  group('Yerebatan: yeni bölümler', () {
    testWithGame<GolgeGame>(
      'galeride koşan yarasaları uyandırır, Kandilci duyar',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 68, 13);
        keys(game).right = true;
        run(game, 1.0);
        expect(nearest<BatRoost>(game, 72 * kTile).flown, isTrue);
        expect(
          nearest<Guard>(game, 82 * kTile).state,
          isNot(GuardState.patrol),
        );
      },
    );

    testWithGame<GolgeGame>('parmak ucunda yarasalar uyanmaz', GolgeGame.new, (
      game,
    ) async {
      await place(game, 0, 68, 13);
      keys(game)
        ..sneak = true
        ..right = true;
      run(game, 1.5);
      expect(nearest<BatRoost>(game, 72 * kTile).flown, isFalse);
    });

    testWithGame<GolgeGame>(
      'raftaki sandık düşünce kefe iner, öteki oyuncuyu taşır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 99, 9);
        final crate = nearest<Crate>(game, 98 * kTile);
        crate.position.x = 102 * kTile + 1;
        run(game, 0.6);
        final pans = game.world.children.whereType<LiftPan>().toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        expect(pans.first.position.y, greaterThan(pans.first.base.y));
        p.position.setValues(
          pans.last.position.x + 8,
          pans.last.position.y - Player.h - 1,
        );
        run(game, 4);
        expect(p.onGround, isTrue);
        expect(p.position.y + Player.h, closeTo(10 * kTile, 3));
      },
    );

    testWithGame<GolgeGame>('Karabasan duranı yakalar', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 0, 111, 9);
      run(game, 0.2);
      expect(game.world.children.whereType<Karabasan>().first.awake, isTrue);
      run(game, 6);
      expect(p.isDead, isTrue);
    });

    testWithGame<GolgeGame>(
      'Karabasan bitiş çizgisinde dağılır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 111, 9);
        run(game, 0.2);
        p.position.setFrom(
          Level.standOn(Vector2(127 * kTile, 7 * kTile), Player.w, Player.h),
        );
        run(game, 2.5);
        expect(game.world.children.whereType<Karabasan>(), isEmpty);
      },
    );
  });

  group('Kule', () {
    testWithGame<GolgeGame>('dikey kaya oyuncuyu taşır', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 1, 3, 91);
      final rock = nearest<MovingRock>(game, 9 * kTile);
      p.position.setValues(
        rock.position.x + 10,
        rock.position.y - Player.h - 1,
      );
      run(game, 2.6);
      expect(p.onGround, isTrue);
      expect(p.riding, same(rock));
      expect(p.position.y + Player.h, lessThan(91 * kTile));
    });

    testWithGame<GolgeGame>('basılan kaya kopar ve düşer', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 1, 13, 87);
      final rock = nearest<CrumbleRock>(game, 17 * kTile);
      p.position.setValues(
        rock.position.x + 10,
        rock.position.y - Player.h - 1,
      );
      run(game, 1.4);
      expect(rock.position.y, greaterThan(86 * kTile + 20));
    });

    testWithGame<GolgeGame>(
      'karga koşan oyuncuyu görünce havalanır',
      GolgeGame.new,
      (game) async {
        await place(game, 1, 20, 83);
        final crow = nearest<Crow>(game, 23 * kTile);
        final y0 = crow.position.y;
        keys(game).right = true;
        run(game, 0.8);
        expect(crow.position.y, lessThan(y0 - 10));
      },
    );

    testWithGame<GolgeGame>(
      'kanatlarla rüzgâra atlayan yükselir',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 1, 11, 10);
        run(game, 0.3);
        expect(game.wingsCollected, isTrue, reason: 'kanatlar alınmalı');
        p.position.setValues(15 * kTile, 9 * kTile);
        p.velocity.setZero();
        keys(game).jump = true;
        final y0 = p.position.y;
        run(game, 1.0);
        expect(p.gliding, isTrue);
        expect(p.position.y, lessThan(y0 - kTile));
      },
    );
  });

  group('Kule asansörü', () {
    testWithGame<GolgeGame>(
      'sandığı it, düşünce yükselen kefeye atla, yukarı çık',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 1, 17, 37);
        run(game, 0.2);
        final crate = nearest<Crate>(game, 15 * kTile);
        // Sandığı sola, tahtanın ucundan kefeye it.
        keys(game).left = true;
        for (var i = 0; i < 400 && crate.position.x > 12 * kTile - 20; i++) {
          game.update(1 / 60);
        }
        expect(
          crate.position.x,
          lessThan(12 * kTile),
          reason: 'sandık düşmedi',
        );
        // Tahtanın ucuna gel ve yükselen kefeye zıpla.
        for (var i = 0; i < 120 && p.position.x > 12 * kTile + 1; i++) {
          game.update(1 / 60);
        }
        keys(game).jump = true;
        var onPan = false;
        for (var i = 0; i < 120 && !onPan; i++) {
          game.update(1 / 60);
          onPan = p.riding is LiftPan;
        }
        expect(onPan, isTrue, reason: 'kefeye inemedi');
        keys(game)
          ..left = false
          ..jump = false;
        run(game, 4);
        expect(
          p.position.y + Player.h,
          closeTo(37 * kTile, 3),
          reason: 'kefe yukarı çıkmadı',
        );
        // Kefeden soldaki tahtaya geç.
        keys(game)
          ..left = true
          ..jump = true;
        run(game, 1.0);
        expect(p.isDead, isFalse);
        expect(p.position.y + Player.h, closeTo(35 * kTile, 1));
      },
    );
  });

  group('Gökyolu', () {
    testWithGame<GolgeGame>(
      'Gözcü\'nün ışığında kalan yakalanır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 2, 67, 11);
        final w = game.world.children.whereType<Watcher>().first;
        var died = false;
        for (var i = 0; i < 60 * 14 && !died; i++) {
          game.update(1 / 60);
          died = p.isDead;
        }
        expect(w.facing, 1);
        expect(died, isTrue, reason: 'ışık süpürürken eninde sonunda görmeli');
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

  group('perde', () {
    test('her sahne baştan sona çizilebilir', () {
      for (final scene in PerdeScene.values) {
        for (var u = 0.0; u <= 5.0; u += 0.1) {
          final rec = PictureRecorder();
          PerdePainter.paint(
            Canvas(rec),
            const Size(1280, 720),
            scene,
            u * 5,
            u,
            u < 0.3 ? 0.5 : 1,
          );
          rec.endRecording().dispose();
        }
      }
    });

    testWithGame<GolgeGame>(
      'bölüm sonunda perde oynar, sonra yeni bölüm başlar',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 3, 13);
        game.onExitReached();
        run(game, 2);
        expect(game.narration.inCinematic, isTrue);
        expect(game.levelIndex, 0);
        run(game, 24);
        expect(game.narration.inCinematic, isFalse);
        expect(game.levelIndex, 1);
        expect(game.cinematic, isFalse);
      },
    );
  });

  group('gerilim', () {
    testWithGame<GolgeGame>(
      'karanlık bölge ateşböceklerini söndürür, sonra yutar',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 74, 13);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        for (final b in game.world.children.whereType<BatRoost>().toList()) {
          b.removeFromParent();
        }
        game.fireflies = 1;
        run(game, GolgeGame.darkDrain + 0.2);
        expect(game.fireflies, 0);
        expect(p.isDead, isFalse);
        run(game, GolgeGame.darkSwallow + 0.3);
        expect(p.isDead, isTrue);
        expect(p.deathCause, DeathCause.dark);
        run(game, 4);
        expect(game.player!.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'Kandilci yakalayınca ışıkla ölür ve yeniden doğulur',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 3, 13);
        final g = guardOf(game);
        final p = game.player!;
        p.position.setFrom(g.position + Vector2(4, 22));
        run(game, 0.5);
        expect(p.isDead, isTrue);
        expect(p.deathCause, DeathCause.light);
        run(game, 3);
        expect(game.player!.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>('karanlıktaki gözler bir kez açılır', GolgeGame.new, (
      game,
    ) async {
      await place(game, 0, 30, 13);
      final eyes = nearest<KarabasanGlimpse>(game, 38 * kTile);
      expect(eyes.seen, isFalse);
      run(game, 0.2);
      expect(eyes.seen, isTrue);
      run(game, KarabasanGlimpse.duration + 0.5);
      expect(eyes.isMounted, isFalse);
    });
  });
}
