import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/hints.dart';
import 'package:golge/game/konya.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/mechanics.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/ski.dart';
import 'package:golge/game/winter.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

/// Kare hızı: `--dart-define=HZ=120` ile yüksek yenileme hızında da denenir.
const int _hz = int.fromEnvironment('HZ', defaultValue: 60);
const double _dt = 1 / _hz;

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
  for (var t = 0.0; t < seconds; t += _dt) {
    game.update(_dt);
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
      for (var i = 0; i < 60 * _hz ~/ 60; i++) {
        game.update(_dt);
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
          i < 300 * _hz ~/ 60 && p.position.x + Player.w < 14 * kTile - 4;
          i++
        ) {
          game.update(_dt);
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
        for (var i = 0; i < 90 * _hz ~/ 60 && !grabbed; i++) {
          game.update(_dt);
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
        for (var i = 0; i < 60 * _hz ~/ 60 && !onChain; i++) {
          game.update(_dt);
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
        for (var i = 0; i < _hz * 14; i++) {
          game.update(_dt);
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
        for (var i = 0; i < 90 * _hz ~/ 60 && !grabbed; i++) {
          game.update(_dt);
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
      'raftaki sandığı it: kefeye düşer, kefe iner, öteki kalkar, karşıya geçilir',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 96, 9);
        final crate = nearest<Crate>(game, 98 * kTile);
        final pans = game.world.children.whereType<LiftPan>().toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        // Sandığı rafın ucundan iter; düşmeye başlayınca durur.
        keys(game).right = true;
        for (var i = 0; i < _hz * 6 && crate.position.y < 9.3 * kTile; i++) {
          game.update(_dt);
        }
        keys(game).right = false;
        run(game, 4);
        expect(p.isDead, isFalse);
        expect(crate.riding, same(pans.first), reason: 'sandık kefeye inmedi');
        // İnen kefe suya gömülmez; öteki raf hizasının bir kare altına kalkar.
        expect(pans.first.position.y, closeTo(17 * kTile, 1));
        expect(pans.last.position.y, closeTo(11 * kTile, 1));
        // Koşarak rafın ucundan kalkan kefeye, oradan karşı rafa.
        p.position.setFrom(
          Level.standOn(Vector2(98 * kTile, 9 * kTile), Player.w, Player.h),
        );
        p.velocity.setZero();
        var onPan = false;
        keys(game).right = true;
        for (var i = 0; i < _hz * 4; i++) {
          final x = p.position.x / kTile;
          keys(game).jump =
              (p.onGround &&
                  (x > 101.45 && x < 101.7 || x > 106.0 && x < 106.6)) ||
              (!p.onGround && p.velocity.y < 0);
          game.update(_dt);
          if (p.riding == pans.last) onPan = true;
          if (p.isDead || p.position.x > 109.5 * kTile) break;
        }
        keys(game)
          ..right = false
          ..jump = false;
        run(game, 0.3);
        expect(onPan, isTrue, reason: 'kalkan kefeye inemedi');
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(108 * kTile));
        expect(p.position.y + Player.h, closeTo(10 * kTile, 2));
      },
    );

    testWithGame<GolgeGame>(
      'kefeye atlayan taşınır; inen kefeden düşülmez',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 100, 9);
        final pans = game.world.children.whereType<LiftPan>().toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        keys(game).right = true;
        for (var i = 0; i < _hz * 2; i++) {
          keys(game).right = p.center.x < 102.8 * kTile;
          keys(game).jump = i < 4;
          game.update(_dt);
        }
        keys(game)
          ..right = false
          ..jump = false;
        run(game, 5);
        expect(p.isDead, isFalse);
        expect(p.riding, same(pans.first));
        expect(pans.first.position.y, closeTo(17 * kTile, 1));
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
        for (
          var i = 0;
          i < 400 * _hz ~/ 60 && crate.position.x > 12 * kTile - 20;
          i++
        ) {
          game.update(_dt);
        }
        expect(
          crate.position.x,
          lessThan(12 * kTile),
          reason: 'sandık düşmedi',
        );
        // Tahtanın ucuna gel ve yükselen kefeye zıpla.
        for (
          var i = 0;
          i < 120 * _hz ~/ 60 && p.position.x > 12 * kTile + 1;
          i++
        ) {
          game.update(_dt);
        }
        keys(game).jump = true;
        var onPan = false;
        for (var i = 0; i < 120 * _hz ~/ 60 && !onPan; i++) {
          game.update(_dt);
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
        for (var i = 0; i < _hz * 14 && !died; i++) {
          game.update(_dt);
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
        // Açılış perdesi satır uzunluğuna göre sürer.
        for (var i = 0; i < _hz * 150 && game.narration.inCinematic; i++) {
          game.update(_dt);
        }
        run(game, 1);
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
        for (var i = 0; i < _hz * 3 && p.position.x < 134 * kTile; i++) {
          game.update(_dt);
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
        for (var i = 0; i < _hz * 8 && p.position.x < 142 * kTile; i++) {
          game.update(_dt);
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
        for (var i = 0; i < _hz * 4 && p.position.x < 163 * kTile; i++) {
          game.update(_dt);
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
        for (
          var i = 0;
          i < 60 * _hz ~/ 60 && p.position.x < 166.2 * kTile;
          i++
        ) {
          game.update(_dt);
        }
        keys(game)
          ..right = false
          ..jump = false;
        for (var i = 0; i < 60 * _hz ~/ 60 && p.riding is! FloatPlank; i++) {
          game.update(_dt);
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
      for (var i = 0; i < _hz * 25; i++) {
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
        game.update(_dt);
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
      for (var i = 0; i < _hz * 6 && !p.isDead; i++) {
        keys(game).jump = true;
        game.update(_dt);
      }
      // Ya düşer ya da bir ipe tutunup kalır: karşıya süzülemez.
      expect(p.isDead || p.position.x < 59 * kTile, isTrue);
    });
  });

  group('Medusa Salonu', () {
    testWithGame<GolgeGame>(
      'Sal Kanalı: sala bin, sonuna it, karşı kıyıya zıplayarak in',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 0, 225, 13);
        final raft = game.world.children.whereType<Raft>().first;
        keys(game).right = true;
        for (var i = 0; i < _hz * 30 && raft.position.x < 259.9 * kTile; i++) {
          game.update(_dt);
        }
        expect(p.riding, same(raft));
        expect(p.isDead, isFalse);
        keys(game).jump = true;
        run(game, 0.2);
        keys(game).jump = false;
        run(game, 1.2);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(263 * kTile));
      },
    );
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
        for (var i = 0; i < _hz * 60 && !front.sealed && !p.isDead; i++) {
          // Arkadaki baş açılırken ve onun bakışındayken kıpırdama; kalkan
          // başın dibine gelince bekle.
          final danger = back.eyes > 0 && back.inGaze(p.center);
          final shield = game.world.children.whereType<ShieldCrate>().first;
          final close = front.position.x - shield.toRect().right < kTile * 2;
          keys(game).right = !danger && !close;
          game.update(_dt);
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
      'yanan adadan raftaki sarmaşığa zıplanır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 1, 14, 149);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          if ((g.position.y / kTile - 149).abs() < 3) g.removeFromParent();
        }
        final vent = nearest<FireVent>(game, 15 * kTile);
        // Baca sönükken kenara koş, sola zıpla.
        for (var i = 0; i < 600 * _hz ~/ 60 && vent.heat > 0; i++) {
          game.update(_dt);
        }
        keys(game).left = true;
        for (
          var i = 0;
          i < 60 * _hz ~/ 60 && p.position.x > 14 * kTile + 2;
          i++
        ) {
          game.update(_dt);
        }
        keys(game).jump = true;
        run(game, 0.5);
        keys(game).jump = false;
        run(game, 0.6);
        expect(p.isDead, isFalse);
        expect(p.position.y + Player.h, closeTo(148 * kTile, 2));
        // Rafın ucundan sarmaşığa, oradan yukarı.
        for (
          var i = 0;
          i < 240 * _hz ~/ 60 && p.state != PlayerState.vine;
          i++
        ) {
          game.update(_dt);
        }
        keys(game)
          ..left = false
          ..up = true;
        run(game, 3);
        expect(p.isDead, isFalse);
        expect(p.position.y, lessThan(140 * kTile));
      },
    );
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
        for (var i = 0; i < 400 * _hz ~/ 60 && !vents.first.plugged; i++) {
          game.update(_dt);
        }
        keys(game).right = false;
        expect(vents.first.plugged, isTrue);
        // Kalan iki baca sönükken koş.
        var tries = 0;
        while (p.position.x < 22 * kTile && !p.isDead && tries < _hz * 30) {
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
          game.update(_dt);
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
          i < _hz * 90 && p.position.x < 218 * kTile && !p.isDead;
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
          game.update(_dt);
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
          game.update(_dt);
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
          for (var i = 0; i < _hz * 15; i++) {
            final feet = p.position.y + Player.h;
            if (p.onGround && targetTop() > feet - 70) break;
            game.update(_dt);
          }
          keys(game)
            ..right = true
            ..jump = true;
          for (var i = 0; i < 90 * _hz ~/ 60 && p.position.x < targetX; i++) {
            game.update(_dt);
          }
          keys(game)
            ..right = false
            ..jump = false;
          for (var i = 0; i < 60 * _hz ~/ 60 && !p.onGround; i++) {
            game.update(_dt);
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
        for (var i = 0; i < _hz * 4 && p.position.x < 232 * kTile; i++) {
          game.update(_dt);
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
        for (var i = 0; i < _hz * 12 && !p.isDead; i++) {
          game.update(_dt);
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
          for (var i = 0; i < _hz * 20; i++) {
            final cx = c.position.x + Crate.side / 2;
            if (cx >= targetCenter - 3) break;
            keys(game).right = true;
            game.update(_dt);
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
          for (var i = 0; i < _hz * 3; i++) {
            final dx = x * kTile - p.center.x;
            keys(game)
              ..right = dx > 6
              ..left = dx < -6
              ..jump =
                  (p.onGround &&
                      (p.position.y + Player.h) > r * kTile + 2 &&
                      dx.abs() < 4.2 * kTile) ||
                  (!p.onGround && p.velocity.y < 0);
            game.update(_dt);
            if (p.onGround && (p.position.y + Player.h - r * kTile).abs() < 2) {
              break;
            }
          }
          expect(
            p.isDead,
            isFalse,
            reason:
                'satır $r ${p.deathCause} ${p.position} su ${basin.surface}',
          );
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
          for (var i = 0; i < _hz * 3; i++) {
            final dx = x * kTile - p.center.x;
            final feetRow = (p.position.y + Player.h) / kTile;
            keys(game)
              ..right = dx > 4
              ..left = dx < -4
              ..jump =
                  (p.onGround && feetRow > row + 0.1) ||
                  (!p.onGround && p.velocity.y < 0);
            game.update(_dt);
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
            game.update(_dt);
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

  group('Gün Doğumu', () {
    testWithGame<GolgeGame>(
      'raftan devin yoluna ateşböceği bırak: üçüncüsünde yıkılır',
      GolgeGame.new,
      (game) async {
        expect(levels[7].title, 'VIII · GÜN DOĞUMU');
        final p = await place(game, 7, 77, 14);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        final giant = game.world.children.whereType<StoneGiant>().first;
        final gate = nearest<Gate>(game, 125 * kTile);
        for (var i = 0; i < _hz * 90 && !giant.fallen && !p.isDead; i++) {
          final lures = game.world.children.whereType<FireflyLure>();
          if (lures.isEmpty && game.fireflies < 3) game.fireflies = 3;
          if (lures.isEmpty && p.onGround) {
            p.facing = 1;
            game.controls.queueLure();
          }
          game.update(_dt);
        }
        expect(
          p.isDead,
          isFalse,
          reason: '${p.deathCause} ${p.center / kTile}',
        );
        expect(giant.fallen, isTrue);
        run(game, 4);
        expect(gate.solid, isFalse);
      },
    );
  });

  group('Kar Yolu', () {
    testWithGame<GolgeGame>(
      'kurt kokuyu izler; ağaca çıkan kurtulur',
      GolgeGame.new,
      (game) async {
        expect(levels[8].title, 'IX · KAR YOLU');
        final p = await place(game, 8, 73, 19);
        final wolf = nearest<Wolf>(game, 78 * kTile);
        keys(game).left = true;
        for (var i = 0; i < _hz * 5 && !p.isDead; i++) {
          if (p.center.x <= 72.6 * kTile) {
            keys(game)
              ..left = false
              ..up = true;
          }
          game.update(_dt);
        }
        expect(wolf.hunting, isTrue);
        expect(p.isDead, isFalse);
        expect(p.position.y, lessThan(16 * kTile));
      },
    );

    testWithGame<GolgeGame>(
      'kurt ince buzda düşer, hafif olan geçer',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 8, 129, 19);
        final wolf = nearest<Wolf>(game, 123 * kTile);
        keys(game).right = true;
        for (
          var i = 0;
          i < _hz * 18 && p.position.x < 191 * kTile && !p.isDead;
          i++
        ) {
          final hole = game.world.children.whereType<ThinIce>().any(
            (t) =>
                t.broken &&
                t.position.x - p.center.x > 0 &&
                t.position.x - p.center.x < 40,
          );
          final block = game.level.solid(
            ((p.center.x + 26) / kTile).floor(),
            F - 1,
          );
          keys(game).jump = hole || block;
          game.update(_dt);
        }
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(190 * kTile));
        expect(wolf.isMounted, isFalse, reason: 'kurt buzdan düşmeliydi');
      },
    );
  });

  group('Palandöken', () {
    /// Kayakçı: hep sağa; kaya ya da (kütüksüz) uçurum yaklaşınca zıplar.
    int skiRun(GolgeGame game, double seconds, double goalX) {
      final s = game.skiSurface!;
      final rails = game.world.children.whereType<SkiRail>().toList();
      bool railAt(double xx) =>
          rails.any((r) => xx > r.position.x && xx < r.position.x + r.size.x);
      var deaths = 0;
      var wasDead = false;
      keys(game).right = true;
      for (var i = 0; i < _hz * seconds; i++) {
        final pl = game.player!;
        if (pl.center.x > goalX) break;
        final x = pl.center.x;
        final rock = game.world.children.whereType<SkiRock>().any(
          (r) => r.position.x - x > 0 && r.position.x - x < 70,
        );
        final gap =
            (s.at(x + 50) == null && !railAt(x + 50)) ||
            (s.at(x + 90) == null && !railAt(x + 90));
        keys(game).jump = pl.onGround && (rock || gap);
        game.update(_dt);
        if (pl.isDead && !wasDead) deaths++;
        wasDead = pl.isDead;
      }
      keys(game)
        ..right = false
        ..jump = false;
      return deaths;
    }

    testWithGame<GolgeGame>('pist baştan sona kayılır', GolgeGame.new, (
      game,
    ) async {
      expect(levels[9].title, 'X · PALANDÖKEN');
      await place(game, 9, 3, 7);
      final end = game.level.exitCell.x;
      final deaths = skiRun(game, 150, end - kTile);
      expect(game.player!.center.x, greaterThan(end - kTile * 2));
      expect(deaths, lessThanOrEqualTo(3));
    });

    testWithGame<GolgeGame>('çığdan kaçarak sığınağa varılır', GolgeGame.new, (
      game,
    ) async {
      expect(levels[10].title, 'XI · ÇIĞ');
      await place(game, 10, 4, 7);
      final end = game.level.exitCell.x;
      final deaths = skiRun(game, 150, end - kTile);
      expect(game.player!.center.x, greaterThan(end - kTile * 2));
      expect(deaths, lessThanOrEqualTo(4));
    });

    testWithGame<GolgeGame>('takla atıp ters inen düşer', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 9, 3, 7);
      keys(game).right = true;
      run(game, 2);
      keys(game).jump = true;
      run(game, 0.2);
      keys(game).jump = false;
      // Yere değmeden hemen önce beden ters döner.
      final surface = game.skiSurface!;
      for (var t = 0.0; t < 2 && !p.isDead; t += _dt) {
        final ground = surface.at(p.center.x);
        if (ground != null && ground - (p.position.y + Player.h) < 24) {
          p.skiAngle = surface.slope(p.center.x) + 3.0;
        }
        game.update(_dt);
      }
      expect(p.isDead, isTrue);
    });
  });

  group('Peri Bacaları', () {
    testWithGame<GolgeGame>('peri halkası göğe fırlatır', GolgeGame.new, (
      game,
    ) async {
      expect(levels[11].title, 'XII · PERİ BACALARI');
      final p = await place(game, 11, 49, 21);
      final y0 = p.position.y;
      var top = y0;
      for (var i = 0; i < 60 * _hz ~/ 60; i++) {
        game.update(_dt);
        top = math.min(top, p.position.y);
      }
      expect(y0 - top, greaterThan(4 * kTile));
    });

    testWithGame<GolgeGame>(
      'Güvercinlik Vadisi iplerle geçilir',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 11, 111, 17);
        run(game, 0.3);
        for (final goal in [151.5, 192.5]) {
          for (var i = 0; i < _hz * 30; i++) {
            if (p.isDead || (p.onGround && p.position.x > goal * kTile)) break;
            final inSwing = p.state == PlayerState.swing;
            if (!inSwing &&
                p.onGround &&
                game.level.cellAt(p.center.x + 40, 18.5 * kTile) == '.') {
              keys(game).jump = true;
            }
            if (inSwing) {
              keys(game)
                ..right = p.ropeOmega >= 0
                ..left = p.ropeOmega < 0
                ..jump = p.ropeAngle > 0.8 && p.ropeOmega > 0;
            } else {
              keys(game)
                ..right = true
                ..left = false;
            }
            game.update(_dt);
          }
          keys(game)
            ..jump = false
            ..right = false;
          run(game, 0.3);
          expect(p.isDead, isFalse, reason: 'hedef $goal');
        }
        expect(p.position.x, greaterThan(192 * kTile));
      },
    );
  });

  group('Derinkuyu', () {
    testWithGame<GolgeGame>(
      'sürgü taşını aşağı kata düşür, yüksek kapıya basamak yap',
      GolgeGame.new,
      (game) async {
        expect(levels[12].title, 'XIII · DERİNKUYU');
        final p = await place(game, 12, 84, 15);
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        final stone = game.world.children.whereType<MillStone>().first;
        keys(game).right = true;
        for (var i = 0; i < _hz * 6 && stone.position.y < 22 * kTile; i++) {
          game.update(_dt);
        }
        run(game, 1.5);
        expect(stone.position.y, greaterThan(22 * kTile));
        // Taşı yüksek kapının dibine it.
        for (var i = 0; i < _hz * 20 && stone.position.x < 106.9 * kTile; i++) {
          if (p.center.x > stone.position.x) {
            p.position.setFrom(
              Level.standOn(
                Vector2(stone.position.x - kTile, 23 * kTile),
                Player.w,
                Player.h,
              ),
            );
          }
          game.update(_dt);
        }
        keys(game).right = false;
        expect(stone.position.x, greaterThan(106 * kTile));
        // Taşın üstüne çık, yukarı geçide zıpla.
        p.position.setFrom(
          Vector2(stone.position.x + 8, stone.position.y - Player.h - 1),
        );
        run(game, 0.3);
        keys(game)
          ..right = true
          ..jump = true;
        run(game, 0.8);
        keys(game)
          ..right = false
          ..jump = false;
        run(game, 0.5);
        expect(p.isDead, isFalse);
        expect(p.position.y + Player.h, lessThanOrEqualTo(21 * kTile + 1));
      },
    );

    testWithGame<GolgeGame>(
      'kuyuyu doldur, yüzen tahtayla üst geçide çık',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 12, 188, 39);
        final basin = game.world.children.whereType<WaterBasin>().first;
        run(game, 0.3);
        keys(game).up = true;
        run(game, 0.1);
        keys(game).up = false;
        expect(basin.target, closeTo(basin.high, 1));
        // Tahtaya geç.
        keys(game)
          ..right = true
          ..jump = true;
        for (var i = 0; i < 180 * _hz ~/ 60 && p.riding is! FloatPlank; i++) {
          if (p.position.x > 193.6 * kTile) keys(game).right = false;
          game.update(_dt);
        }
        keys(game)
          ..right = false
          ..jump = false;
        expect(p.riding, isA<FloatPlank>());
        run(game, 20);
        expect(p.isDead, isFalse, reason: '${p.deathCause} ${p.position}');
        keys(game)
          ..right = true
          ..jump = true;
        // Geçide varınca durur (ileride devriye gezen Kandilci var).
        for (
          var i = 0;
          i < 120 * _hz ~/ 60 && p.position.x < 199.5 * kTile;
          i++
        ) {
          game.update(_dt);
        }
        keys(game)
          ..right = false
          ..jump = false;
        // Geçide varılır; ileride Kandilci var, beklemeden bakılır.
        expect(p.isDead, isFalse, reason: '${p.deathCause} ${p.position}');
        expect(p.position.x, greaterThan(199 * kTile));
        expect(p.position.y + Player.h, lessThanOrEqualTo(24 * kTile + 1));
      },
    );
  });

  group('ipuçları', () {
    testWithGame<GolgeGame>(
      'ilk Kandilci\'de ateşböceği, gölge tahtasında çömelme anlatılır',
      GolgeGame.new,
      (game) async {
        // Sütunun ardında çömel: önce saklanma, ekran boşalınca Kandilci
        // ipucu gelir; ikisi aynı anda gösterilmez.
        final p = await place(game, 0, 26, 13);
        keys(game).down = true;
        run(game, 0.6);
        expect(game.hintShown('hide'), isTrue);
        expect(game.hintShown('guard'), isFalse);
        for (var i = 0; i < _hz * 20 && !game.hintShown('guard'); i++) {
          game.update(_dt);
        }
        expect(p.isDead, isFalse);
        expect(game.hintShown('guard'), isTrue);
        keys(game).down = false;
        await place(game, 0, 135, 9);
        for (var i = 0; i < _hz * 30 && !game.hintShown('shadePlank'); i++) {
          game.update(_dt);
        }
        expect(game.hintShown('shadePlank'), isTrue);
        expect(Hints.text('shadePlank'), contains('Çömel'));
      },
    );
  });

  group('Konya', () {
    testWithGame<GolgeGame>(
      'İkonion: kalkanı iterek Medusa mühürlenir',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 13, 88, 37);
        final m = game.world.children.whereType<MedusaHead>().first;
        run(game, 0.3);
        keys(game).right = true;
        for (var i = 0; i < _hz * 25 && !m.sealed && !p.isDead; i++) {
          game.update(_dt);
        }
        keys(game).right = false;
        expect(p.isDead, isFalse);
        expect(m.sealed, isTrue);
      },
    );

    testWithGame<GolgeGame>(
      'önden geçen semâzenin eteğinde saklanılır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 13, 330, 33);
        keys(game).down = true;
        final s = game.world.children.whereType<Semazen>().first;
        for (
          var i = 0;
          i < 600 * _hz ~/ 60 &&
              !(s.inFront && (s.position.x - 342 * kTile).abs() < 20);
          i++
        ) {
          game.update(_dt);
        }
        expect(s.inFront, isTrue);
        p.position.setValues(
          s.position.x - Player.w / 2,
          34 * kTile - Player.h,
        );
        run(game, 0.2);
        expect(p.hidden, isTrue);
        // Semâzen arkaya dönünce saklamaz.
        for (var i = 0; i < 1200 * _hz ~/ 60 && s.inFront; i++) {
          game.update(_dt);
        }
        p.position.setValues(
          s.position.x - Player.w / 2,
          34 * kTile - Player.h,
        );
        run(game, 0.1);
        expect(p.hidden, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'avizenin mum tablası binene taşır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 13, 377, 33);
        run(game, 0.1);
        final tray = game.world.children
            .whereType<Chandelier>()
            .first
            .planks
            .first;
        p.position.setValues(
          tray.position.x + tray.size.x / 2 - Player.w / 2,
          tray.position.y - Player.h - 2,
        );
        p.velocity.setZero();
        run(game, 0.2);
        expect(p.riding, same(tray));
        final before = p.position.clone();
        run(game, 1.0);
        expect(p.isDead, isFalse);
        expect(p.riding, same(tray));
        expect((p.position - before).length, greaterThan(30));
      },
    );

    testWithGame<GolgeGame>(
      'Semâhane: avizeden avizeye çıkışa varılır',
      GolgeGame.new,
      (game) async {
        // Avizeler belirlenimci döner: her atlayış için uygun an aranır.
        // plan[i]: i. atlayışın zamanı (bölüm yüklendikten sonra, saniye).
        final plan = <double>[];
        final k = keys(game);

        /// Planı baştan oynatır; son atlayışın sonucunu döndürür:
        /// 1 hedefe kondu, 0 kondu ama yanlış yere, -1 düştü/öldü.
        Future<int> play(List<double> times, int target) async {
          final p = await place(game, 13, 380, 33);
          final wheels = game.world.children.whereType<Chandelier>().toList()
            ..sort((a, b) => a.position.x.compareTo(b.position.x));
          var t = 0.0;
          for (var j = 0; j < times.length; j++) {
            k
              ..left = false
              ..right = false
              ..jump = false;
            while (t < times[j]) {
              game.update(_dt);
              t += _dt;
              if (p.isDead) return -1;
            }
            final goal = j < wheels.length ? wheels[j] : null;
            k
              ..right = true
              ..jump = true;
            game.update(_dt);
            t += _dt;
            var landed = false;
            for (var i = 0; i < 240 * _hz ~/ 60; i++) {
              // Hedef tablanın üstüne gelince sağa basmayı bırakır.
              if (goal != null) {
                final tray = goal.planks.reduce(
                  (a, b) =>
                      (a.center.x - p.center.x).abs() <
                          (b.center.x - p.center.x).abs()
                      ? a
                      : b,
                );
                k.right = p.center.x < tray.center.x - 4;
              }
              k.jump = !p.onGround;
              game.update(_dt);
              t += _dt;
              if (p.isDead) return -1;
              if (p.onGround && i > 3) {
                landed = true;
                break;
              }
            }
            if (!landed) return -1;
            final ok = goal == null
                ? p.position.y + Player.h <= 22 * kTile + 1 &&
                      p.position.x > 411 * kTile
                : p.riding is CandleTray &&
                      (p.riding! as CandleTray).owner == goal;
            if (j == times.length - 1) return ok ? 1 : 0;
            if (!ok) return 0;
          }
          return 0;
        }

        for (var stage = 0; stage < 4; stage++) {
          final from = plan.isEmpty ? 0.3 : plan.last + 0.6;
          var found = false;
          for (var t = from; t < from + 7; t += 0.1) {
            if (await play([...plan, t], stage) == 1) {
              plan.add(t);
              found = true;
              break;
            }
          }
          expect(found, isTrue, reason: 'atlayış ${stage + 1}: $plan');
        }
      },
    );

    testWithGame<GolgeGame>(
      'büyük fenerin huzmesi açıktakini siler',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 13, 255, 27);
        run(game, 8);
        expect(p.isDead, isTrue);
        expect(p.deathCause, DeathCause.light);
      },
    );

    testWithGame<GolgeGame>('revakın altında fener görmez', GolgeGame.new, (
      game,
    ) async {
      final p = await place(game, 13, 242, 27);
      run(game, 8);
      expect(p.isDead, isFalse);
    });

    testWithGame<GolgeGame>(
      'Yeşil Kubbe: ışık seli yükselirken tepeye tırmanılır',
      GolgeGame.new,
      (game) async {
        final p = await place(game, 13, 418, 21);
        run(game, 0.3);
        final k = keys(game);
        final flood = game.world.children.whereType<LightFlood>().first;
        // Sıçrama adımları: (yön, sıçrama kenarı).
        final jumps = <(int, double)>[
          (1, 437 * kTile - 3),
          (1, 441 * kTile - 3),
          (1, 445 * kTile - 3),
          (1, 448 * kTile - 3),
        ];
        Future<void> leap(int dir, double edge) async {
          k
            ..left = dir < 0
            ..right = dir > 0;
          for (var i = 0; i < 600 * _hz ~/ 60; i++) {
            final front = dir > 0 ? p.position.x + Player.w : p.position.x;
            if (p.onGround && (front - edge) * dir >= 0) break;
            game.update(_dt);
          }
          k.jump = true;
          game.update(_dt);
          for (var i = 0; i < 240 * _hz ~/ 60; i++) {
            k.jump = p.velocity.y < 0;
            game.update(_dt);
            if (p.onGround && p.velocity.y >= 0) break;
          }
          k.jump = false;
        }

        for (final (d, e) in jumps) {
          await leap(d, e);
          expect(p.isDead, isFalse, reason: 'sıçrama $e');
        }
        // Merdiven: sütun 453.
        k
          ..right = true
          ..left = false;
        for (
          var i = 0;
          i < 300 * _hz ~/ 60 && p.center.x < 453.5 * kTile;
          i++
        ) {
          game.update(_dt);
        }
        k
          ..right = false
          ..up = true;
        for (
          var i = 0;
          i < 400 * _hz ~/ 60 && p.position.y + Player.h > 7 * kTile;
          i++
        ) {
          game.update(_dt);
        }
        k.up = false;
        expect(p.isDead, isFalse, reason: 'merdiven');
        // Merdivenden sola, rafa atla.
        k
          ..left = true
          ..jump = true;
        game.update(_dt);
        for (var i = 0; i < 240 * _hz ~/ 60 && !p.onGround; i++) {
          k.jump = p.velocity.y < 0;
          game.update(_dt);
        }
        k.jump = false;
        expect(p.position.y + Player.h, closeTo(8 * kTile, 2));
        for (final (d, e) in <(int, double)>[
          (-1, 446 * kTile + 3),
          (-1, 441 * kTile + 3),
          (-1, 436 * kTile + 3),
        ]) {
          await leap(d, e);
          expect(p.isDead, isFalse, reason: 'sıçrama $e');
        }
        // ignore: avoid_print
        print(
          'sel payı: ${(flood.surface - p.position.y - Player.h) / kTile} kare',
        );
        expect(p.position.y + Player.h, lessThanOrEqualTo(3 * kTile + 1));
        expect(flood.awake, isFalse);
      },
    );
  });
}

const F = 20;
