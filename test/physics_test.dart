import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/mechanics.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

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

/// Oyuncuya en yakın Kandilci.
Guard guardOf(GolgeGame g) => nearest<Guard>(g, g.player!.position.x);

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
      final p = await place(game, 0, 271, 9);
      run(game, 0.2);
      expect(game.world.children.whereType<Karabasan>().first.awake, isTrue);
      run(game, 6);
      expect(p.isDead, isTrue);
    });

    testWithGame<GolgeGame>(
      'Karabasan bitiş çizgisinde dağılır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 271, 9);
        run(game, 0.2);
        p.position.setFrom(
          Level.standOn(Vector2(287 * kTile, 7 * kTile), Player.w, Player.h),
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
      final p = await place(game, 1, 3, 125);
      final rock = nearest<MovingRock>(game, 9 * kTile);
      p.position.setValues(
        rock.position.x + 10,
        rock.position.y - Player.h - 1,
      );
      final y0 = rock.position.y;
      run(game, 1.4);
      expect(p.onGround, isTrue);
      expect(p.riding, same(rock));
      // Kaya nereye gittiyse oyuncu da onunla gitti.
      expect((rock.position.y - y0).abs(), greaterThan(10));
      expect((p.position.y + Player.h - rock.position.y).abs(), lessThan(2));
    });

    testWithGame<GolgeGame>('basılan kaya kopar ve düşer', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 1, 13, 121);
      final rock = game.world.children.whereType<CrumbleRock>().firstWhere(
        (r) => (r.position.y - 120 * kTile).abs() < kTile,
      );
      final y0 = rock.position.y;
      p.position.setValues(
        rock.position.x + 10,
        rock.position.y - Player.h - 1,
      );
      run(game, 1.4);
      expect(rock.position.y, greaterThan(y0 + 20));
    });

    testWithGame<GolgeGame>(
      'karga koşan oyuncuyu görünce havalanır',
      GolgeGame.new,
      (game) async {
        await place(game, 1, 20, 117);
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
        final p = await place(game, 1, 11, 44);
        run(game, 0.3);
        expect(game.wingsCollected, isTrue, reason: 'kanatlar alınmalı');
        p.position.setValues(15 * kTile, 43 * kTile);
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
        final p = await place(game, 1, 17, 71);
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
          closeTo(71 * kTile, 3),
          reason: 'kefe yukarı çıkmadı',
        );
        // Kefeden soldaki tahtaya geç.
        keys(game)
          ..left = true
          ..jump = true;
        run(game, 1.0);
        expect(p.isDead, isFalse);
        expect(p.position.y + Player.h, closeTo(69 * kTile, 1));
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

    testWithGame<GolgeGame>(
      'karanlıktaki gözler bir kez açılır',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 30, 13);
        final eyes = nearest<KarabasanGlimpse>(game, 38 * kTile);
        expect(eyes.seen, isFalse);
        run(game, 0.2);
        expect(eyes.seen, isTrue);
        run(game, KarabasanGlimpse.duration + 0.5);
        expect(eyes.isMounted, isFalse);
      },
    );
  });

  group('Yerebatan bulmacaları', () {
    testWithGame<GolgeGame>(
      'ışık tahtası açık kavanozla geçilir',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 126, 9);
        keys(game).right = true;
        for (var i = 0; i < 60 * 3 && p.position.x < 134 * kTile; i++) {
          game.update(1 / 60);
        }
        keys(game).right = false;
        run(game, 0.5);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThanOrEqualTo(134 * kTile));
      },
    );

    testWithGame<GolgeGame>('ışık tahtasında çömelen düşer', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 0, 130, 9);
      run(game, 0.4);
      expect(p.isDead, isFalse);
      keys(game).down = true;
      run(game, 1.5);
      expect(p.isDead, isTrue);
    });

    testWithGame<GolgeGame>(
      'gölge tahtası ışıkla kaybolur, çömelerek geçilir',
      GolgeGame.new,
      (game) async {
        var p = await place(game, 0, 135, 9);
        keys(game).right = true;
        run(game, 1.5);
        expect(p.isDead, isTrue, reason: 'açık ışıkla gölge tahtası durmaz');

        p = await place(game, 0, 135, 9);
        keys(game)
          ..right = false
          ..down = true;
        run(game, 0.3);
        keys(game).right = true;
        for (var i = 0; i < 60 * 8 && p.position.x < 142 * kTile; i++) {
          game.update(1 / 60);
        }
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThanOrEqualTo(142 * kTile));
      },
    );

    testWithGame<GolgeGame>(
      'çürük köprü Sâye\'yi taşır, ateşböceğine gelen Kandilci\'yi taşımaz',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 142, 9);
        final guard = nearest<Guard>(game, 156 * kTile);
        run(game, 0.2);
        // Sahanlığın başından köprüye bir ateşböceği salınır.
        keys(game).down = true;
        run(game, 0.2);
        game.releaseFirefly(p.light.$1, 1);
        run(game, 7);
        expect(guard.isMounted, isFalse, reason: 'Kandilci düşmeliydi');
        expect(game.level.cell(149, 10), '.', reason: 'köprü çökmeliydi');
        expect(p.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'su haznesi: boşalt, in, doldur, tahtayla çık',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 159, 9);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        final basin = game.world.children.whereType<WaterBasin>().first;
        run(game, 0.2);
        // Boşaltan vana.
        keys(game).up = true;
        run(game, 0.1);
        keys(game).up = false;
        run(game, 10);
        expect(basin.surface, closeTo(basin.low, 1));
        // Haznenin dibine in, dolduran vanaya yürü.
        keys(game).right = true;
        for (var i = 0; i < 60 * 4 && p.position.x < 163 * kTile; i++) {
          game.update(1 / 60);
        }
        keys(game).right = false;
        run(game, 0.6);
        expect(p.isDead, isFalse);
        keys(game).up = true;
        run(game, 0.1);
        keys(game).up = false;
        // Su yükselmeden yüzen tahtaya atla.
        keys(game)
          ..right = true
          ..jump = true;
        for (var i = 0; i < 60 && p.position.x < 166.2 * kTile; i++) {
          game.update(1 / 60);
        }
        keys(game)
          ..right = false
          ..jump = false;
        for (var i = 0; i < 60 && p.riding is! FloatPlank; i++) {
          game.update(1 / 60);
        }
        expect(p.riding, isA<FloatPlank>());
        run(game, 18);
        expect(p.isDead, isFalse);
        expect(p.position.y + Player.h, lessThan(7 * kTile));
        // Çıkış rafına atla.
        keys(game)
          ..right = true
          ..jump = true;
        run(game, 1.2);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(169 * kTile));
      },
    );

    testWithGame<GolgeGame>(
      'dev perdede gölge bir kez geç kalır',
      GolgeGame.new,
      (game) async {
        await place(game, 0, 117, 9);
        final perde = game.world.children.whereType<GiantPerde>().first;
        run(game, 1.0);
        expect(perde.lagT, greaterThanOrEqualTo(0));
        run(game, GiantPerde.lagLength + 0.2);
        expect(perde.lagT, greaterThanOrEqualTo(GiantPerde.lagLength));
      },
    );
  });

  group('ayna ve huzme', () {
    void press(GolgeGame game) {
      keys(game).up = true;
      run(game, 0.1);
      keys(game).up = false;
      run(game, 0.1);
    }

    testWithGame<GolgeGame>(
      'Kule: aynayı çeviren Gözcü\'nün gözünü kamaştırır',
      GolgeGame.new,
      (game) async {
        await place(game, 1, 20, 56);
        run(game, 0.3);
        final w = game.world.children.whereType<Watcher>().first;
        expect(w.dazzled, lessThanOrEqualTo(0));
        press(game);
        run(game, 0.3);
        expect(w.dazzled, greaterThan(0));
      },
    );

    testWithGame<GolgeGame>(
      'Kaf: üç ayna ve sandıkla ışık kilidi kapıyı açar',
      GolgeGame.new,
      (game) async {
        expect(levels[3].title, 'IV · KAF');
        var p = await place(game, 3, 215, 12);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        run(game, 0.3);
        press(game);
        p.position.setFrom(
          Level.standOn(Vector2(224 * kTile, 12 * kTile), Player.w, Player.h),
        );
        run(game, 0.3);
        press(game);
        p.position.setFrom(
          Level.standOn(Vector2(224 * kTile, 17 * kTile), Player.w, Player.h),
        );
        run(game, 0.4);
        press(game);
        final lock = game.world.children.whereType<SunLock>().first;
        run(game, 1.5);
        expect(lock.open, isFalse, reason: 'sandık huzmeyi kesiyor olmalı');
        // Sandığı çukura it.
        p = game.player!;
        p.position.setFrom(
          Level.standOn(Vector2(225.6 * kTile, 17 * kTile), Player.w, Player.h),
        );
        keys(game).right = true;
        run(game, 1.5);
        keys(game).right = false;
        run(game, 2);
        expect(p.isDead, isFalse);
        expect(lock.open, isTrue);
        run(game, 3);
        expect(nearest<Gate>(game, lock.position.x).solid, isFalse);
      },
    );
  });

  group('Ağrı: ipler', () {
    /// İpe atlar, salınım yönünde güç verir, [release] açısında bırakır;
    /// [goal] sütununun ötesinde yere basınca durur.
    void swingAcross(
      GolgeGame game,
      Player p, {
      required double jumpFrom,
      required double release,
      required double goal,
    }) {
      for (var i = 0; i < 60 * 25; i++) {
        final inSwing = p.state == PlayerState.swing;
        if (!inSwing &&
            p.onGround &&
            p.position.x > jumpFrom * kTile &&
            p.position.x < (jumpFrom + 2) * kTile) {
          keys(game).jump = true;
        }
        if (inSwing) {
          keys(game)
            ..right = p.ropeOmega >= 0
            ..left = p.ropeOmega < 0
            ..jump = p.ropeAngle > release && p.ropeOmega > 0;
        } else {
          keys(game)
            ..right = true
            ..left = false;
        }
        game.update(1 / 60);
        if (const bool.fromEnvironment('IPIZ') && i % 10 == 0) {
          // ignore: avoid_print
          print(
            '$i x=${(p.position.x / kTile).toStringAsFixed(2)} y=${(p.position.y / kTile).toStringAsFixed(2)} ${p.state} a=${p.ropeAngle.toStringAsFixed(2)} j=${keys(game).jump}',
          );
        }
        if (p.isDead || (p.onGround && p.position.x > goal * kTile)) break;
      }
      keys(game)
        ..right = false
        ..jump = false;
    }

    testWithGame<GolgeGame>(
      'buzlu dereden ilk ipe, karşı kayaya',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 4, 19, 19);
        run(game, 0.3);
        swingAcross(game, p, jumpFrom: 21.6, release: 0.75, goal: 31);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(31 * kTile));
      },
    );

    testWithGame<GolgeGame>('üç iple uçurumun karşısına', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 4, 33, 16);
      run(game, 0.3);
      swingAcross(game, p, jumpFrom: 34.6, release: 0.8, goal: 59);
      expect(p.isDead, isFalse);
      expect(p.position.x, greaterThan(59 * kTile));
    });

    testWithGame<GolgeGame>(
      'tufanın eşiğinde iple yukarı rafa',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 4, 271, 14);
        run(game, 0.3);
        swingAcross(game, p, jumpFrom: 273.6, release: 0.8, goal: 283);
        expect(p.isDead, isFalse);
        expect(p.position.y, lessThan(12 * kTile));
      },
    );

    testWithGame<GolgeGame>('tipide kanatla uçurum geçilmez', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 4, 33, 16);
      run(game, 0.3);
      keys(game).right = true;
      for (var i = 0; i < 60 * 6 && !p.isDead; i++) {
        keys(game).jump = true;
        game.update(1 / 60);
      }
      // Ya düşer ya da bir ipe tutunup kalır: karşıya süzülemez.
      expect(p.isDead || p.position.x < 59 * kTile, isTrue);
    });
  });

  group('Medusa Salonu', () {
    testWithGame<GolgeGame>(
      'kalkanı iterek öndeki başı taşlaştır, arkadaki bakınca dur',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 201, 13);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        final heads = game.world.children.whereType<MedusaHead>().toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        final back = heads.first;
        final front = heads.last;
        for (var i = 0; i < 60 * 60 && !front.sealed && !p.isDead; i++) {
          // Arkadaki baş açılırken ve onun bakışındayken kıpırdama; kalkan
          // başın dibine gelince bekle.
          final danger = back.eyes > 0 && back.inGaze(p.center);
          final shield = game.world.children.whereType<ShieldCrate>().first;
          final close = front.position.x - shield.toRect().right < kTile * 2;
          keys(game).right = !danger && !close;
          game.update(1 / 60);
        }
        keys(game).right = false;
        expect(p.isDead, isFalse);
        expect(front.sealed, isTrue);
        // Artık başın altından geçilir.
        keys(game).right = true;
        run(game, 3);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(224 * kTile));
      },
    );
  });

  group('Kule uzantısı', () {
    testWithGame<GolgeGame>(
      'çanı çalınca Kandilci çürük tahtadan düşer',
      GolgeGame.new,
      (game) async {
        await place(game, 1, 4, 25);
        final guard = nearest<Guard>(game, 26 * kTile);
        expect((guard.position.y / kTile).round(), closeTo(24, 1));
        keys(game).up = true;
        run(game, 0.1);
        keys(game).up = false;
        run(game, 10);
        expect(guard.isMounted, isFalse);
        expect(game.level.cell(23, 26), '.');
      },
    );

    testWithGame<GolgeGame>(
      'mahzende bir bacayı sandıkla tıkayıp alevlerin arasından geç',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 1, 9, 167);
        final vents = game.world.children.whereType<FireVent>().toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        // Sandığı ilk bacanın üstüne it.
        keys(game).right = true;
        for (var i = 0; i < 400 && !vents.first.plugged; i++) {
          game.update(1 / 60);
        }
        keys(game).right = false;
        expect(vents.first.plugged, isTrue);
        // Kalan iki baca sönükken koş.
        var tries = 0;
        while (p.position.x < 22 * kTile && !p.isDead && tries < 60 * 30) {
          final next = vents.where(
            (v) => !v.plugged && v.position.x > p.center.x - 10,
          );
          final safe = next.every((v) => v.heat == 0 && !v.burning);
          keys(game)
            ..jump = false
            ..right = safe || p.center.x > vents.first.position.x + 40;
          // Sandığın üstünden atla.
          if (p.center.x > vents.first.position.x - 50 &&
              p.center.x < vents.first.position.x) {
            keys(game).jump = true;
          }
          game.update(1 / 60);
          tries++;
        }
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThanOrEqualTo(22 * kTile));
      },
    );
  });

  group('Gökyolu uzantısı', () {
    testWithGame<GolgeGame>(
      'sağanakta gölge köprüsü: balonun ışığını kollayıp çömelerek geç',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 2, 203, 9);
        final balloon = nearest<LanternBalloon>(game, 210 * kTile);
        keys(game).down = true;
        var prevX = balloon.position.x;
        for (
          var i = 0;
          i < 60 * 90 && p.position.x < 218 * kTile && !p.isDead;
          i++
        ) {
          final bx = balloon.position.x;
          final movingRight = bx > prevX;
          prevX = bx;
          final px = p.center.x;
          bool go;
          if (px < 210 * kTile) {
            // Sol yarı: balon sağda ve sağa giderken.
            go = bx > 212.5 * kTile && (movingRight || px > 206 * kTile);
          } else if (px < 212 * kTile) {
            // Taş ayak: balon solda kalınca çık.
            go = bx < 208.5 * kTile && !movingRight;
          } else {
            go = true;
          }
          keys(game).right = go;
          game.update(1 / 60);
        }
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThanOrEqualTo(218 * kTile));
      },
    );

    testWithGame<GolgeGame>('sağanakta kanat açılmaz', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 2, 203, 9);
      run(game, 0.2);
      expect(p.hasWings, isFalse);
      final q = await place(game, 2, 199, 9);
      run(game, 0.2);
      expect(q.hasWings, isTrue);
    });
  });

  group('Kaf uzantısı', () {
    testWithGame<GolgeGame>(
      'üç tüy toplanınca sunak tüy kapısını açar',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 3, 186, 17);
        final feathers = game.world.children
            .whereType<SimurgFeather>()
            .toList();
        expect(feathers.length, 3);
        final gate = nearest<Gate>(game, 194 * kTile);
        // Tüyleri tek tek al (sınavlar ayrı testlerde); sonra sunağa dön.
        final safe = p.position.clone();
        for (final f in feathers) {
          p.position.setFrom(f.position - Vector2(Player.w / 2, Player.h / 2));
          game.update(1 / 60);
          p.position.setFrom(safe);
          p.velocity.setZero();
          run(game, 0.2);
        }
        expect(feathers.every((f) => f.taken), isTrue);
        run(game, 3);
        expect(gate.solid, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'kayan kayalarla yüksek buluta çıkılır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 3, 164, 17);
        final rocks =
            game.world.children
                .whereType<MovingRock>()
                .where(
                  (r) =>
                      r.position.x > 160 * kTile && r.position.x < 180 * kTile,
                )
                .toList()
              ..sort((a, b) => a.position.x.compareTo(b.position.x));
        expect(rocks.length, 3);
        // Hedef zemin şu ankinden alçak ya da en çok yarım kare yüksekken atla.
        void hopTo(double targetX, double Function() targetTop) {
          for (var i = 0; i < 60 * 15; i++) {
            final feet = p.position.y + Player.h;
            if (p.onGround && targetTop() > feet - 70) break;
            game.update(1 / 60);
          }
          keys(game)
            ..right = true
            ..jump = true;
          for (var i = 0; i < 90 && p.position.x < targetX; i++) {
            game.update(1 / 60);
          }
          keys(game)
            ..right = false
            ..jump = false;
          for (var i = 0; i < 60 && !p.onGround; i++) {
            game.update(1 / 60);
          }
        }

        for (final r in rocks) {
          hopTo(r.position.x + 12, () => r.position.y);
          expect(p.isDead, isFalse);
        }
        hopTo(176.3 * kTile, () => 7 * kTile.toDouble());
        run(game, 0.5);
        expect(p.isDead, isFalse);
        expect(p.position.y + Player.h, lessThanOrEqualTo(7 * kTile + 2));
      },
    );
  });

  group('Aziz Hakob Manastırı', () {
    testWithGame<GolgeGame>(
      'revakta koşan sarkıtlardan kurtulur',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 4, 205, 16);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        keys(game).right = true;
        for (var i = 0; i < 60 * 4 && p.position.x < 232 * kTile; i++) {
          game.update(1 / 60);
        }
        run(game, 1);
        expect(p.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'parmak ucunda yürüyeni sarkıt bulur',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 4, 205, 16);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        keys(game)
          ..right = true
          ..sneak = true;
        for (var i = 0; i < 60 * 12 && !p.isDead; i++) {
          game.update(1 / 60);
        }
        expect(p.isDead, isTrue);
      },
    );
  });

  group('Nuh\'un Gemisi', () {
    testWithGame<GolgeGame>(
      'önce raftaki sandık çukura, sonra zürafa ve fil eşlerine: kapı açılır',
      GolgeGame.new,
      (game) async {
        expect(levels[5].map, isNotEmpty);
        final p = await place(game, 5, 79, 25);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        final gate = nearest<Gate>(game, 108 * kTile);
        // Rafa çık, sandığı çukura it.
        p.position.setFrom(
          Level.standOn(Vector2(80 * kTile, 22 * kTile), Player.w, Player.h),
        );
        keys(game).right = true;
        run(game, 2.5);
        keys(game).right = false;
        final plain = game.world.children.whereType<Crate>().firstWhere(
          (c) => c is! AnimalCrate,
        );
        expect(plain.position.x, closeTo(84 * kTile, 6));
        expect(plain.position.y, greaterThan(25 * kTile));
        // Zürafayı (öndeki) ve sonra fili eşlerine it.
        final animals = game.world.children.whereType<AnimalCrate>().toList();
        final giraffe = animals.firstWhere((a) => a.kind == AnimalKind.giraffe);
        final elephant = animals.firstWhere(
          (a) => a.kind == AnimalKind.elephant,
        );
        Future<void> pushTo(Crate c, double targetCenter) async {
          p.position.setFrom(
            Level.standOn(
              Vector2(c.position.x - kTile, 25 * kTile),
              Player.w,
              Player.h,
            ),
          );
          run(game, 0.2);
          for (var i = 0; i < 60 * 20; i++) {
            final cx = c.position.x + Crate.side / 2;
            if (cx >= targetCenter - 3) break;
            keys(game).right = true;
            game.update(1 / 60);
          }
          keys(game).right = false;
          run(game, 0.3);
        }

        await pushTo(giraffe, 102.5 * kTile);
        await pushTo(elephant, 96.5 * kTile);
        expect(p.isDead, isFalse);
        run(game, 4);
        expect(gate.solid, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'ambar kuyusunda tufandan önce tepeye çık',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 5, 193, 25);
        keys(game).right = true;
        run(game, 0.6);
        final basin = game.world.children.whereType<WaterBasin>().first;
        expect(basin.flooding, isTrue);
        // Tahtalara zikzak tırman.
        for (final r in [24, 22, 20, 18, 16, 14, 12, 10]) {
          final left = ((24 - r) ~/ 2).isEven;
          final x = left ? 205.6 : 206.4;
          for (var i = 0; i < 60 * 3; i++) {
            final dx = x * kTile - p.center.x;
            keys(game)
              ..right = dx > 6
              ..left = dx < -6
              ..jump =
                  (p.onGround &&
                      (p.position.y + Player.h) > r * kTile + 2 &&
                      dx.abs() < 3.6 * kTile) ||
                  (!p.onGround && p.velocity.y < 0);
            game.update(1 / 60);
            if (p.onGround && (p.position.y + Player.h - r * kTile).abs() < 2) {
              break;
            }
          }
          expect(p.isDead, isFalse, reason: 'satır $r');
        }
        keys(game)
          ..left = false
          ..right = false
          ..jump = false;
        expect(basin.surface, greaterThan(p.position.y + Player.h));
      },
    );
  });

  group('Nemrut', () {
    testWithGame<GolgeGame>(
      'tanrıların omuzlarındaki yıldız taşları horoskoba dizilince kapı açılır',
      GolgeGame.new,
      (game) async {
        expect(levels[6].title, 'VII · NEMRUT');
        final p = await place(game, 6, 50, 19);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        final stones = game.world.children.whereType<StarStone>().toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        expect(stones.length, 4);
        final gate = nearest<Gate>(game, 91 * kTile);
        // İlk tanrıya gerçekten tırman: diz, taht, kol, omuz.
        void climbTo(double x, int row) {
          for (var i = 0; i < 60 * 3; i++) {
            final dx = x * kTile - p.center.x;
            final feetRow = (p.position.y + Player.h) / kTile;
            keys(game)
              ..right = dx > 4
              ..left = dx < -4
              ..jump =
                  (p.onGround && feetRow > row + 0.1) ||
                  (!p.onGround && p.velocity.y < 0);
            game.update(1 / 60);
            if (p.onGround && (feetRow - row).abs() < 0.05 && dx.abs() < 8) {
              break;
            }
          }
          keys(game)
            ..right = false
            ..left = false
            ..jump = false;
        }

        climbTo(52.5, 18); // tabure
        climbTo(55.0, 16); // taht
        climbTo(58.5, 14); // kol
        climbTo(56.5, 12); // omuzlar
        climbTo(55.6, 12); // taşın yanı
        expect(p.isDead, isFalse);
        expect((p.position.y + Player.h) / kTile, closeTo(12, 0.05));
        // Taşı horoskobun istediği işarete çevir.
        Future<void> setStone(StarStone st) async {
          for (var n = 0; n < 12 && st.sign != horoscope[st.index]; n++) {
            keys(game).up = true;
            game.update(1 / 60);
            keys(game).up = false;
            run(game, 0.1);
          }
        }

        await setStone(stones[0]);
        expect(stones[0].correct, isTrue);
        // Ötekileri (aynı tırmanış) doğrudan omuzlarına konarak çevir.
        for (final st in stones.skip(1)) {
          p.position.setFrom(st.position - Vector2(Player.w / 2, Player.h));
          run(game, 0.2);
          await setStone(st);
        }
        run(game, 3);
        expect(gate.solid, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'taş devin kulağına üç ateşböceği: yıkılır',
      GolgeGame.new,
      (game) async {
        GolgeGame.debugLevels = [
          const LevelDef(
            title: 'DEV',
            subtitle: '',
            theme: LevelTheme.nemrut,
            map: [
              '########################################',
              '#......................................#',
              '#......................................#',
              '#......................................#',
              '#......................................#',
              '#......................................#',
              '#......................................#',
              '#......................................#',
              '#......................................#',
              '#...........`..........................#',
              '#P.....................................#',
              '########################################',
            ],
          ),
        ];
        game.debugLoadLevel(0);
        await game.ready();
        game.cinematic = false;
        run(game, 0.2);
        final giant = game.world.children.whereType<StoneGiant>().first;
        for (var i = 0; i < 3; i++) {
          game.fireflies = 3;
          run(game, 2.6);
          final ear = giant.ear;
          game.releaseFirefly(ear + Vector2(-60, 10), 1);
          run(game, 0.6);
        }
        GolgeGame.debugLevels = null;
        expect(giant.hits, 3);
        expect(giant.fallen, isTrue);
        expect(game.world.children.whereType<GiantBridge>(), isNotEmpty);
      },
    );
  });
}
