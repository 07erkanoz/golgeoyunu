import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/ergenekon.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/konya.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show place, run, keys, nearest;

const _dt = 1 / 60;

/// Ergenekon'un gerçek haritası: kömür, yetmiş körük ritmi, tutuşan
/// sandık, Nevruz örsü ve demir dağın içindeki tırmanış.
void main() {
  const level = 15;

  IronVein firstVein(GolgeGame g) {
    final vs = g.world.children.whereType<IronVein>().toList()
      ..sort((a, b) => a.forge.dx.compareTo(b.forge.dx));
    return vs.first;
  }

  void fuelUp(GolgeGame g, IronVein v) {
    final crates = g.world.children.whereType<Crate>().toList()
      ..sort((a, b) => b.position.x.compareTo(a.position.x));
    // Ocağın önündeki iki karelik çukur (88-89. sütunlar).
    for (var i = 0; i < 2; i++) {
      crates[i].position.setValues(
        (88 + i) * kTile + 1.0,
        36 * kTile - Crate.side,
      );
    }
    run(g, 0.5);
  }

  testWithGame<GolgeGame>(
    'kömür yığılmadan ocak yanmaz; iki sandık çukura girince yanar',
    GolgeGame.new,
    (game) async {
      expect(levels[level].title, 'XVII · ERGENEKON');
      await place(game, level, 84, 34);
      final v = firstVein(game);
      expect(v.rhythm, isTrue);
      expect(v.fuelNeeded, 2);
      expect(v.fueled, isFalse);
      fuelUp(game, v);
      expect(v.fueled, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'yetmiş körük: vuruşa denk basan damarı eritir, vuruşu kaçıran eritemez',
    GolgeGame.new,
    (game) async {
      await place(game, level, 60, 34);
      final v = firstVein(game);
      fuelUp(game, v);
      v.lit = true;
      final anvil = v.anvil!;
      final bellows = game.world.children
          .whereType<Bellows>()
          .where((b) => b.vein == v && b.order > 0)
          .toList();
      expect(bellows.length, 3);
      // Vuruşu kaçıran: hep vuruşların ortasında basar.
      var wasOn = anvil.onBeat;
      var offPumps = 0;
      for (var i = 0; i < 60 * 15; i++) {
        game.update(_dt);
        final on = anvil.onBeat;
        if (wasOn && !on) {
          // Vuruştan çıkıldı: yarım vuruş sonra (ortada) bas.
          run(game, Anvil.beat / 2 - Anvil.grace);
          final b = v.activeBellows!;
          if (b.ready) {
            b.use();
            offPumps++;
          }
        }
        wasOn = anvil.onBeat;
      }
      expect(offPumps, greaterThan(5));
      expect(v.opening, isFalse);
      expect(v.beats, 0);
      // Vuruşa denk basan: her vuruşta dolu bir körüğe.
      wasOn = anvil.onBeat;
      for (var i = 0; i < 60 * 30 && !v.opening; i++) {
        game.update(_dt);
        final on = anvil.onBeat;
        if (on && !wasOn) {
          run(game, Anvil.grace * 0.8);
          final b = v.activeBellows!;
          if (b.ready) b.use();
        }
        wasOn = anvil.onBeat;
      }
      expect(v.opening, isTrue);
      run(game, 3);
      expect(v.solid, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'bacayı tıkayan sandık ateşin üstünde tutuşup yanar',
    GolgeGame.new,
    (game) async {
      await place(game, level, 296, 34);
      final vent = game.world.children.whereType<FireVent>().firstWhere(
        (v) =>
            (v.position.x / kTile).floor() == 305 &&
            (v.position.y / kTile).round() == 23,
      );
      final crate = nearest<Crate>(game, 307 * kTile);
      crate.position.setValues(
        vent.position.x - Crate.side / 2,
        23 * kTile - Crate.side,
      );
      run(game, 0.2);
      expect(vent.plugged, isTrue);
      run(game, 15);
      expect(crate.isMounted, isFalse);
      expect(vent.plugged, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'sisli çayır kanatsız: çukur kenarından adacığa, adacıktan karşıya',
    GolgeGame.new,
    (game) async {
      final p = await place(game, level, 153, 34);
      expect(p.hasWings, isFalse);
      keys(game).right = true;
      for (var i = 0; i < 60 * 20 && p.center.x < 213 * kTile; i++) {
        // Önündeki zemin boşsa (çukur) kenardan zıpla.
        final ahead = game.level.solid(
          ((p.position.x + Player.w + 6) / kTile).floor(),
          35,
        );
        keys(game).jump =
            (p.onGround && !ahead) || (!p.onGround && p.velocity.y < 0);
        game.update(_dt);
        expect(
          p.isDead,
          isFalse,
          reason: '${p.deathCause} ${p.center / kTile}',
        );
      }
      keys(game)
        ..right = false
        ..jump = false;
      expect(p.center.x, greaterThan(212 * kTile));
    },
  );

  testWithGame<GolgeGame>(
    'Nevruz: örste demire üç kez vurulunca kapı açılır',
    GolgeGame.new,
    (game) async {
      await place(game, level, 316, 6);
      final anvil = game.world.children.whereType<NevruzAnvil>().single;
      final gate = nearest<Gate>(game, 322 * kTile);
      expect(gate.solid, isTrue);
      for (var i = 0; i < 3; i++) {
        anvil.use();
        run(game, 0.6);
      }
      run(game, 3);
      expect(gate.solid, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'demir dağın içi: kat kat, bacaları bekleyerek akkor demirden önce çıkılır',
    GolgeGame.new,
    (game) async {
      final p = await place(game, level, 297, 34);
      // Katlar ve açıklıkları (sağ: 309-310, sol: 300-301).
      const floors = [
        (31, true),
        (27, false),
        (23, true),
        (19, false),
        (15, true),
        (11, false),
        (7, true),
      ];
      final vents = game.world.children.whereType<FireVent>().toList();
      var elapsed = 0;
      bool safeAhead(double x, int dir, double feet) {
        for (final v in vents) {
          if ((v.position.y - feet).abs() > 4) continue;
          final dx = (v.position.x - x) * dir;
          if (dx < -16 || dx > 46) continue;
          if (!v.plugged && v.heat > 0.2) return false;
        }
        return true;
      }

      var floorY = 35 * kTile.toDouble();
      for (final (row, right) in floors) {
        // Açıklıktaki zincirin altına yürü (bacaları bekleyerek).
        final chain = (right ? 310.5 : 300.5) * kTile;
        var lastX = p.center.x;
        var hold = 0;
        for (var i = 0; i < 60 * 25; i++) {
          final dx = chain - p.center.x;
          if (dx.abs() < 5) break;
          final dir = dx > 0 ? 1 : -1;
          final go = safeAhead(p.center.x, dir, floorY);
          // Yarım saniyedir ilerlemiyorsa (önü tıkalı) zıpla.
          if (i % 30 == 0) lastX = p.center.x;
          // Öndeki sandık: arkasındaki bacayı tıkayana dek itilir, sonra
          // üstünden atlanır.
          final crateAhead = game.world.children.whereType<Crate>().any((c) {
            final rel = (c.center.x - p.center.x) * dir;
            if ((c.position.y + Crate.side - p.position.y - Player.h).abs() >
                    4 ||
                rel <= 0 ||
                rel >= 30) {
              return false;
            }
            return !vents.any(
              (v) =>
                  !v.plugged &&
                  (v.position.y - c.position.y - Crate.side).abs() < 4 &&
                  (v.position.x - c.center.x) * dir > 0 &&
                  (v.position.x - c.center.x) * dir < 60,
            );
          });
          final stuck =
              go &&
              p.onGround &&
              (crateAhead || (i % 30 == 29 && (p.center.x - lastX).abs() < 2));
          // Zıplayınca tuşu bir süre basılı tutar (tam zıplayış).
          if (stuck) hold = 18;
          if (hold > 0) hold--;
          keys(game)
            ..right = go && dir > 0
            ..left = go && dir < 0
            ..jump = hold > 0
            ..up = (p.center.x - chain).abs() < 12;
          game.update(_dt);
          elapsed++;
          expect(
            p.isDead,
            isFalse,
            reason:
                'kat $row yürürken ${p.deathCause} ${p.center / kTile} sel=${game.world.children.whereType<LightFlood>().map((f) => (f.surface / kTile).toStringAsFixed(2)).join()} t=${(elapsed * _dt).toStringAsFixed(1)}',
          );
        }
        // Zincire tırman; kat hizasını geçince kata in.
        keys(game)
          ..left = false
          ..right = false;
        for (var i = 0; i < 60 * 4; i++) {
          final above = p.position.y + Player.h <= row * kTile + 1;
          // Son katta zincirin tepesinden sağdaki çıkış koridoruna inilir.
          final last = row == floors.last.$1;
          final toLeft = right && !last;
          keys(game)
            ..up = !above
            ..left = above && toLeft
            ..right = above && !toLeft
            ..jump = above && i % 20 == 0;
          game.update(_dt);
          if (p.onGround &&
              p.position.y + Player.h <= row * kTile + 1 &&
              (p.center.x - chain).abs() > kTile) {
            break;
          }
        }
        keys(game)
          ..jump = false
          ..up = false
          ..left = false
          ..right = false;
        run(game, 0.1);
        expect(
          p.isDead,
          isFalse,
          reason: 'kat $row tırmanırken ${p.deathCause} ${p.center / kTile}',
        );
        expect(
          p.position.y + Player.h,
          lessThanOrEqualTo(row * kTile + 1),
          reason: 'kat $row: ${p.center / kTile}',
        );
        floorY = row * kTile.toDouble();
        final fl = game.world.children.whereType<LightFlood>().firstOrNull;
        // ignore: avoid_print
        print(
          'kat $row t=${(elapsed * _dt).toStringAsFixed(1)} ara=${fl == null || !fl.awake ? '-' : ((fl.surface - p.position.y - Player.h) / kTile).toStringAsFixed(1)}',
        );
      }
      // Koridora çık.
      keys(game).right = true;
      for (var i = 0; i < 60 * 3 && p.center.x < 313 * kTile; i++) {
        keys(game).jump = p.onGround && p.center.x > 309 * kTile;
        game.update(_dt);
      }
      keys(game)
        ..right = false
        ..jump = false;
      expect(p.isDead, isFalse, reason: '${p.deathCause}');
      expect(p.center.x, greaterThan(312 * kTile));
    },
  );
}
