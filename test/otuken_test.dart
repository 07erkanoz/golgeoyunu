// Ötüken Ormanı (bölüm 17): sarmaşıklar, davul kökleri, ışık lekeleri, Ak
// Geyik, Kara Bataklık kovalaması ve Hayat Ağacı'nın tepesi.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/heavens.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/otuken.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

const _dt = 1 / 60;
const _otuken = 17;

Future<Player> _place(GolgeGame game, double col, int row) async {
  game.debugLoadLevel(_otuken);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  return p;
}

void _run(GolgeGame game, double s) {
  for (var t = 0.0; t < s; t += _dt) {
    game.update(_dt);
  }
}

Buttons _keys(GolgeGame g) => g.controls.keyboard;

/// İpe atlar, pompalar, [release] açısında bırakır; [goal] sütununun ötesine
/// basınca durur. Yolda başka ipe tutunursa onda da aynısını yapar.
void _swing(
  GolgeGame game,
  Player p, {
  required double jumpFrom,
  required double release,
  required double goal,
}) {
  var minA = 0.0;
  var held = false;
  for (var i = 0; i < 60 * 25; i++) {
    final sw = p.state == PlayerState.swing;
    if (sw && !held) minA = 0;
    held = sw;
    if (sw) minA = p.ropeAngle < minA ? p.ropeAngle : minA;
    if (!sw && p.onGround && p.position.x > jumpFrom * kTile) {
      _keys(game).jump = true;
    }
    if (sw) {
      _keys(game)
        ..right = p.ropeOmega >= 0
        ..left = p.ropeOmega < 0
        ..jump =
            p.ropeAngle > release && p.ropeOmega > 0 && minA < -release * 0.6;
    } else {
      _keys(game)
        ..right = true
        ..left = false;
      // Zıplayışı tam yapar (tuş basılı); inişte bırakır.
      if (!p.onGround && p.velocity.y > 0) _keys(game).jump = false;
    }
    game.update(_dt);
    if (const bool.fromEnvironment('IPIZ') && i % 6 == 0) {
      // ignore: avoid_print
      print(
        '$i x=${(p.position.x / kTile).toStringAsFixed(2)} y=${(p.position.y / kTile).toStringAsFixed(2)} ${p.state} g=${p.onGround} a=${p.ropeAngle.toStringAsFixed(2)}',
      );
    }
    if (p.isDead || (p.onGround && p.position.x > goal * kTile)) break;
  }
  _keys(game)
    ..right = false
    ..jump = false;
}

/// Ormanda koşan bot: sağa koşar; önünde boşluk varsa zıplar; davul köküne
/// vuruşu bekleyerek geçer; sarmaşığa tutunup sallanır ve [release]
/// açısında bırakır. [goal] sütununu geçip yere basınca durur.
void _runForest(
  GolgeGame game,
  Player p, {
  required double goal,
  double release = 0.6,
  double seconds = 40,
  bool eager = false,
}) {
  final drum = game.world.children.whereType<KamDrum>().firstOrNull;
  final roots = game.world.children.whereType<DrumCloud>().toList()
    ..sort((a, b) => a.position.x.compareTo(b.position.x));
  var minA = 0.0;
  var held = false;
  var lureT = 0.0;
  for (var i = 0; i < 60 * seconds; i++) {
    final k = _keys(game);
    // Karabasan yetişirse ardına ateşböceği salar (ipucunun dediği gibi).
    lureT -= _dt;
    for (final z in game.world.children.whereType<GladeZone>()) {
      if (z.dread > 0.55 && lureT <= 0 && game.fireflies > 0) {
        game.releaseFirefly(Vector2(p.center.x, p.center.y - 8), 1);
        lureT = 2.0;
      }
    }
    for (final kb in game.world.children.whereType<Karabasan>()) {
      if (kb.awake &&
          lureT <= 0 &&
          game.fireflies > 0 &&
          p.center.x - kb.position.x < 7 * kTile) {
        game.releaseFirefly(Vector2(p.center.x, p.center.y - 8), -1);
        lureT = 2.0;
      }
    }
    final sw = p.state == PlayerState.swing;
    if (sw && !held) minA = 0;
    held = sw;
    if (sw) {
      minA = p.ropeAngle < minA ? p.ropeAngle : minA;
      k
        ..right = p.ropeOmega >= 0
        ..left = p.ropeOmega < 0
        ..jump =
            p.ropeAngle > release &&
            p.ropeOmega > 0 &&
            (eager || minA < -release * 0.6);
    } else if (p.state == PlayerState.hang) {
      k
        ..up = true
        ..right = true;
    } else if (p.onGround) {
      k
        ..up = false
        ..jump = false
        ..right = true
        ..left = false;
      final right = p.position.x + Player.w;
      final foot = p.position.y + Player.h + 4;
      // Sıradaki kök (önde, 5 kare içinde).
      DrumCloud? next;
      for (final d in roots) {
        if (d.position.x > right - 2 &&
            d.position.x - right < 5 * kTile &&
            (d.position.y - foot).abs() < 3 * kTile) {
          next = d;
          break;
        }
      }
      final c = ((right + 6) / kTile).floor();
      final r = (foot / kTile).floor();
      final gapAhead =
          !game.level.solid(c, r) &&
          !game.level.solid(c, r + 1) &&
          !roots.any(
            (d) =>
                d.on &&
                right + 6 >= d.position.x &&
                right + 6 <= d.position.x + d.size.x &&
                (d.position.y - foot).abs() < 12,
          );
      // Işık lekeleri: önündeki huzme sönecekse ışıkta bekler.
      var wait = false;
      final onRoot = roots.any(
        (d) =>
            p.center.x >= d.position.x - 4 &&
            p.center.x <= d.position.x + d.size.x + 4 &&
            (d.position.y - (p.position.y + Player.h)).abs() < 14,
      );
      for (final z
          in onRoot
              ? const <GladeZone>[]
              : game.world.children.whereType<GladeZone>()) {
        final at = Offset(p.center.x, p.center.y);
        if (!z.area.contains(at) || !z.lit(at)) continue;
        if (z.lit(Offset(p.center.x + 1.2 * kTile, p.center.y))) continue;
        for (var j = 0; j < z.beams.length; j++) {
          final bx = z.beamX(j);
          if (bx - GladeZone.half <= p.center.x + kTile) continue;
          final dist = bx - GladeZone.half - p.center.x;
          if (dist > 7 * kTile) break;
          wait = !(z.beamOn(j) >= 0.9 && z.litLeft(j) > dist / 150 + 0.6);
          break;
        }
      }
      if (wait) {
        k
          ..right = false
          ..jump = false;
      } else if (next != null && drum != null) {
        // Kenara yaklaş, vuruşu bekle.
        final edge = next.position.x - right;
        if (edge < 1.1 * kTile) {
          final ph = drum.phase;
          final onNow = next.on;
          final go = onNow ? ph < 0.5 : ph > 0.78;
          k.right = go;
          k.jump = go;
        }
      } else if (gapAhead ||
          game.level.solid(c, r - 1) ||
          game.level.solid(c, r - 2)) {
        // Boşluk ya da basamak: zıpla.
        k.jump = true;
      }
    } else {
      k
        ..right = true
        ..left = false;
      if (p.velocity.y > 0) k.jump = false;
    }
    game.update(_dt);
    if (const bool.fromEnvironment('KOS') && i % 15 == 0) {
      final kb = game.world.children.whereType<Karabasan>().firstOrNull;
      // ignore: avoid_print
      print(
        '$i x=${(p.position.x / kTile).toStringAsFixed(1)} y=${(p.position.y / kTile).toStringAsFixed(1)} ${p.state} g=${p.onGround} kb=${kb == null ? '-' : (kb.position.x / kTile).toStringAsFixed(1)} ff=${game.fireflies}',
      );
    }
    if (p.isDead || (p.onGround && p.position.x > goal * kTile)) break;
  }
  _keys(game)
    ..right = false
    ..jump = false
    ..up = false;
}

void main() {
  test('Ötüken Derinkuyu ile Erlik arasında; kanatsız orman', () {
    final d = levels[_otuken];
    expect(d.theme, LevelTheme.forest);
    expect(d.noWings, isTrue);
    expect(d.title, 'XIV · ÖTÜKEN ORMANI');
    expect(levelOrder.indexOf(_otuken), levelOrder.indexOf(12) + 1);
    expect(interludes[_otuken].last, 'BEŞİNCİ PERDE · ÖTÜKEN');
    expect(interludes[14].contains('BEŞİNCİ PERDE · ÖTÜKEN'), isFalse);
  });

  group('sarmaşıklar', () {
    for (final (name, from, jump, goal) in [
      ('dere', 55.0, 60.4, 70.0),
      ('dikenli yar', 129.0, 134.4, 151.0),
      ('bataklık', 366.0, 370.4, 383.0),
    ]) {
      for (final rel in [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]) {
        testWithGame<GolgeGame>('$name (bırakış $rel)', GolgeGame.new, (
          game,
        ) async {
          final p = await _place(game, from, 39);
          for (final k in game.world.children.whereType<Karabasan>().toList()) {
            k.removeFromParent();
          }
          _run(game, 0.3);
          _swing(game, p, jumpFrom: jump, release: rel, goal: goal);
          // ignore: avoid_print
          print(
            'IP $name $rel: ${p.state} x=${(p.position.x / kTile).toStringAsFixed(1)} y=${(p.position.y / kTile).toStringAsFixed(1)} dead=${p.isDead} cause=${p.deathCause}',
          );
          expect(p.isDead, isFalse);
          expect(p.position.x, greaterThan(goal * kTile));
        });
      }
    }
  });

  group('davul kökleri', () {
    for (final (name, from, row, goal) in [
      ('bataklık kökleri', 106.0, 39, 129.0),
      ('kök merdiveni', 165.0, 39, 189.0),
      ('kökler ve ışık', 189.0, 32, 214.0),
    ]) {
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        final p = await _place(game, from, row);
        _run(game, 0.2);
        _runForest(game, p, goal: goal);
        // ignore: avoid_print
        print(
          'KOK $name: ${p.state} x=${(p.position.x / kTile).toStringAsFixed(1)} y=${(p.position.y / kTile).toStringAsFixed(1)} dead=${p.isDead} ${p.deathCause}',
        );
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(goal * kTile));
      });
    }
  });

  testWithGame<
    GolgeGame
  >('Kara Bataklık: Karabasan kovalarken ağacın dibine varılır', GolgeGame.new, (
    game,
  ) async {
    final p = await _place(game, 334, 39);
    _run(game, 0.2);
    _runForest(game, p, goal: 397, eager: true);
    final k = game.world.children.whereType<Karabasan>().firstOrNull;
    // ignore: avoid_print
    print(
      'KOVALAMA: x=${(p.position.x / kTile).toStringAsFixed(1)} dead=${p.isDead} ${p.deathCause} kara=${k == null ? '-' : (k.position.x / kTile).toStringAsFixed(1)}',
    );
    expect(p.isDead, isFalse);
    expect(p.position.x, greaterThan(396 * kTile));
  });

  group('ışık lekeleri', () {
    for (final (name, from, goal) in [
      ('durgun lekeler', 6.0, 59.0),
      ('rüzgârlı lekeler', 71.0, 101.0),
    ]) {
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        final p = await _place(game, from, 39);
        _run(game, 0.2);
        final before = game.fireflies;
        _runForest(game, p, goal: goal);
        // ignore: avoid_print
        print(
          'LEKE $name: x=${(p.position.x / kTile).toStringAsFixed(1)} dead=${p.isDead} ${p.deathCause} ateşböceği ${before - game.fireflies}',
        );
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(goal * kTile));
      });
    }

    testWithGame<GolgeGame>(
      'gölgede durulursa Karabasan yutar',
      GolgeGame.new,
      (game) async {
        final p = await _place(game, 27, 39);
        _run(game, 4);
        expect(p.isDead, isTrue);
        expect(p.deathCause, DeathCause.dark);
      },
    );

    testWithGame<GolgeGame>('huzmenin içinde durmak güvenli', GolgeGame.new, (
      game,
    ) async {
      final p = await _place(game, 22.6, 39);
      _run(game, 6);
      expect(p.isDead, isFalse);
    });
  });

  group('Ak Geyik', () {
    void walkTo(GolgeGame game, Player p, double col, {double max = 12}) {
      for (var t = 0.0; t < max; t += _dt) {
        final dx = col * kTile - p.center.x;
        if (dx.abs() < 6) break;
        _keys(game)
          ..right = dx > 0
          ..left = dx < 0;
        game.update(_dt);
      }
      _keys(game)
        ..right = false
        ..left = false;
    }

    void lure(GolgeGame game, Player p, int dir) {
      game.releaseFirefly(Vector2(p.center.x, p.center.y - 8), dir);
    }

    Gate gateAt(GolgeGame game, int col) => game.world.children
        .whereType<Gate>()
        .firstWhere((g) => (g.position.x / kTile).floor() == col);

    testWithGame<
      GolgeGame
    >('ateşböceğini izler, köke basar, kapı açılır; karanlığa girmez', GolgeGame.new, (
      game,
    ) async {
      final p = await _place(game, 222, 39);
      final deer = game.world.children.whereType<AkGeyik>().single;
      _run(game, 0.5);
      expect(gateAt(game, 242).solid, isTrue);
      // 1) Kök: Sâye geyiğin önünde durup ateşböceğini köke salar.
      walkTo(game, p, 231);
      lure(game, p, 1);
      _run(game, 4);
      // ignore: avoid_print
      print(
        'GEYIK ilk: ${(deer.position.x / kTile).toStringAsFixed(2)} sâye ${(p.center.x / kTile).toStringAsFixed(2)}',
      );
      expect(deer.position.x, greaterThan(235 * kTile));
      _run(game, 2);
      expect(gateAt(game, 242).solid, isFalse);
      // 2) Geçit: geyik aşağıda, Sâye üst yolda.
      walkTo(game, p, 248.3);
      _run(game, 1);
      // Sarmaşıktan üst yola tırman.
      p.position.setFrom(
        Level.standOn(Vector2(250 * kTile, 33 * kTile), Player.w, Player.h),
      );
      _run(game, 0.3);
      walkTo(game, p, 251);
      // ignore: avoid_print
      print(
        'GEYIK geçit önü: ${(deer.position.x / kTile).toStringAsFixed(2)} sâye ${(p.center.x / kTile).toStringAsFixed(2)} ${(p.center.y / kTile).toStringAsFixed(2)}',
      );
      lure(game, p, 1);
      for (var i = 0; i < 5; i++) {
        _run(game, 1);
        final l = game.world.children.whereType<FireflyLure>().firstOrNull;
        // ignore: avoid_print
        print(
          'GEYIK ${(deer.position.x / kTile).toStringAsFixed(2)} lure ${l == null ? '-' : (l.position.x / kTile).toStringAsFixed(2)}',
        );
      }
      expect(gateAt(game, 260).solid, isFalse, reason: 'geyik köke basmalı');
      walkTo(game, p, 276.5);
      _keys(game).up = true;
      _run(game, 0.3);
      _keys(game).up = false;
      _run(game, 3);
      expect(gateAt(game, 268).solid, isFalse);
      // Sâye inip geyiği alır; geyik ardından gelir.
      p.position.setFrom(
        Level.standOn(Vector2(298 * kTile, 39 * kTile), Player.w, Player.h),
      );
      _run(game, 0.3);
      walkTo(game, p, 262, max: 20);
      _run(game, 1);
      walkTo(game, p, 297, max: 20);
      _run(game, 3);
      // ignore: avoid_print
      print(
        'GEYIK geçitten sonra: ${(deer.position.x / kTile).toStringAsFixed(1)}',
      );
      expect(deer.position.x, greaterThan(290 * kTile));
      // 3) Işıksız yol: geyik karanlığa girmez.
      walkTo(game, p, 305);
      _run(game, 4);
      // ignore: avoid_print
      print(
        'GEYIK karanlık önü: ${(deer.position.x / kTile).toStringAsFixed(2)} sâye ${(p.center.x / kTile).toStringAsFixed(2)} ölü=${p.isDead}',
      );
      expect(deer.position.x, lessThan(300 * kTile));
      // Ateşböcekleriyle ışık köprüsü kur: her ışığa önce Sâye yürür.
      game.fireflies = 5;
      // Sâye ateşböceğini salar, ışığın altına yürür, geyiği bekler.
      walkTo(game, p, 298);
      for (final at in [304.0, 310.0, 316.0, 322.0, 328.0]) {
        lure(game, p, 1);
        _run(game, 0.6);
        walkTo(game, p, at);
        _run(game, 1.6);
        // ignore: avoid_print
        print(
          'GEYIK köprü $at: geyik ${(deer.position.x / kTile).toStringAsFixed(2)} sâye ${(p.center.x / kTile).toStringAsFixed(2)} ölü=${p.isDead} ${p.deathCause}',
        );
      }
      // ignore: avoid_print
      print(
        'GEYIK sonda: ${(deer.position.x / kTile).toStringAsFixed(1)} ölü=${p.isDead}',
      );
      expect(gateAt(game, 330).solid, isFalse);
      walkTo(game, p, 333);
      _run(game, 4);
      expect(deer.gone || deer.leaving, isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  testWithGame<
    GolgeGame
  >('Hayat Ağacı: ışık sırayla düşerken dallardan tepeye', GolgeGame.new, (
    game,
  ) async {
    final p = await _place(game, 401, 39);
    _run(game, 0.2);
    final z = game.world.children.whereType<GladeZone>().last;
    final k = _keys(game);
    // Dallar: (satır, sol mu); en son ağacın tepesindeki salon (satır 17).
    final branches = [
      for (var r = 38, i = 0; r > 17; r -= 2, i++) (r, i.isOdd),
    ];
    var next = 0;
    var targetX = 0.0;
    var steps = 0;
    for (var i = 0; i < 60 * 80; i++) {
      k
        ..left = false
        ..right = false;
      final feet = (p.position.y + Player.h) / kTile;
      if (p.onGround) {
        k.jump = false;
        while (next < branches.length && feet <= branches[next].$1 + 0.2) {
          next++;
        }
        if (next >= branches.length) {
          // En üst daldan salona.
          k.right = true;
          targetX = 417 * kTile;
          if (p.center.x > 410.8 * kTile) k.jump = true;
        } else {
          final (_, left) = branches[next];
          final beam = left ? 0 : 1;
          final x = p.center.x / kTile;
          // Işıkta bekle; hedef dala ışık düşünce kenara yürü ve zıpla.
          final ground = feet > 39.5;
          final waitX = ground ? 410.0 : (left ? 409.6 : 405.4);
          final jumpX = ground ? 410.0 : (left ? 408.4 : 406.6);
          final go = z.beamOn(beam) >= 0.9 && z.litLeft(beam) > 1.0;
          final want = go ? jumpX : waitX;
          if ((x - want).abs() > 0.3) {
            k.right = x < want;
            k.left = x > want;
          } else if (go) {
            k.jump = true;
            targetX = (left ? 404.8 : 409.6) * kTile;
            steps++;
          }
        }
      } else {
        final dx = targetX - p.center.x;
        k
          ..right = dx > 6
          ..left = dx < -6;
        if (p.velocity.y > 0) k.jump = false;
      }
      if (z.dread > 0.6 && game.fireflies > 0) {
        game.releaseFirefly(Vector2(p.center.x, p.center.y - 8), 1);
      }
      game.update(_dt);
      if (p.isDead) break;
      if (p.onGround && feet < 17.5 && p.center.x > 414 * kTile) break;
    }
    // ignore: avoid_print
    print(
      'AGAC: x=${(p.center.x / kTile).toStringAsFixed(1)} satır=${((p.position.y + Player.h) / kTile).toStringAsFixed(1)} ölü=${p.isDead} ${p.deathCause} adım=$steps ateşböceği=${game.fireflies}',
    );
    expect(p.isDead, isFalse);
    expect(p.center.x, greaterThan(414 * kTile));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWithGame<
    GolgeGame
  >('tepede güneş aynalarla iner; Karabasan dağılır, kapı açılır', GolgeGame.new, (
    game,
  ) async {
    void press() {
      _keys(game).up = true;
      _run(game, 0.1);
      _keys(game).up = false;
      _run(game, 0.1);
    }

    var p = await _place(game, 418, 12);
    expect(game.world.children.whereType<GladeZone>(), isNotEmpty);
    expect(game.world.children.whereType<KarabasanEnd>(), hasLength(1));
    _run(game, 0.3);
    press();
    // İkinci ayna sağdaki raftan, üçüncüsü yerden çevrilir.
    p.position.setFrom(
      Level.standOn(Vector2(428 * kTile, 12 * kTile), Player.w, Player.h),
    );
    _run(game, 0.3);
    press();
    p.position.setFrom(
      Level.standOn(Vector2(426 * kTile, 16 * kTile), Player.w, Player.h),
    );
    _run(game, 0.3);
    press();
    final lock = game.world.children.whereType<SunLock>().first;
    _run(game, 1.5);
    expect(lock.open, isFalse, reason: 'sandık huzmeyi kesiyor olmalı');
    p = game.player!;
    p.position.setFrom(
      Level.standOn(Vector2(428.6 * kTile, 16 * kTile), Player.w, Player.h),
    );
    _keys(game).right = true;
    _run(game, 1.5);
    _keys(game).right = false;
    _run(game, 2);
    // ignore: avoid_print
    print(
      'TEPE: ${(p.center.x / kTile).toStringAsFixed(1)},${(p.center.y / kTile).toStringAsFixed(1)} ${p.state} ${p.deathCause} kilit=${lock.open}',
    );
    for (final m in game.world.children.whereType<Mirror>()) {
      // ignore: avoid_print
      print(
        'TEPE ayna ${(m.position.x / kTile).toStringAsFixed(1)},${(m.position.y / kTile).toStringAsFixed(1)} slash=${m.slash}',
      );
    }
    for (final b in game.world.children.whereType<SunBeam>()) {
      for (final (a0, a1) in b.segments) {
        // ignore: avoid_print
        print(
          'TEPE ışın ${(a0.dx / kTile).toStringAsFixed(1)},${(a0.dy / kTile).toStringAsFixed(1)} -> ${(a1.dx / kTile).toStringAsFixed(1)},${(a1.dy / kTile).toStringAsFixed(1)}',
        );
      }
    }
    final c = game.world.children.whereType<Crate>().first;
    // ignore: avoid_print
    print(
      'TEPE sandık ${(c.position.x / kTile).toStringAsFixed(1)},${(c.position.y / kTile).toStringAsFixed(1)}',
    );
    expect(p.isDead, isFalse);
    expect(lock.open, isTrue);
    expect(game.world.children.whereType<GladeZone>(), isEmpty);
    _run(game, 3);
    final gate = game.world.children.whereType<Gate>().reduce(
      (a, b) =>
          (a.position.x - lock.position.x).abs() <
              (b.position.x - lock.position.x).abs()
          ? a
          : b,
    );
    expect(gate.solid, isFalse);
    expect(game.world.children.whereType<KarabasanEnd>(), isEmpty);
  });

  testWithGame<GolgeGame>(
    'kökler ve ışık ateşböceği olmadan da geçilir',
    GolgeGame.new,
    (game) async {
      final p = await _place(game, 189, 32);
      _run(game, 0.2);
      game.fireflies = 0;
      _runForest(game, p, goal: 214);
      expect(p.isDead, isFalse);
    },
  );
}
