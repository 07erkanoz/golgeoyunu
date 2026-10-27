import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/cameos.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';

import 'physics_test.dart' show run;

Future<void> _level(GolgeGame game, int index) async {
  game.debugLoadLevel(index);
  await game.ready();
  game.cinematic = false;
  // Kandilciler bu sınamaların konusu değil (bekleyeni yakalamasınlar).
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  run(game, 0.2);
}

void _standAt(GolgeGame game, int col, int row) {
  game.player!.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
}

void main() {
  testWithGame<GolgeGame>(
    'Yerebatan: haznenin başında bekleyene Su İyesi görünür, vanaları gösterir',
    GolgeGame.new,
    (game) async {
      await _level(game, 0);
      _standAt(game, 267, 9);
      run(game, 1.5);
      expect(
        game.world.children.whereType<WaterFace>(),
        isEmpty,
        reason: 'hemen değil, beklemeyle',
      );
      run(game, 2);
      expect(game.world.children.whereType<WaterFace>(), hasLength(1));
      expect(game.mythsSeen, contains('suIyesi'));
      final face = game.world.children.whereType<WaterFace>().single;
      expect(face.pointsAt?.fill, isFalse, reason: 'önce suyu boşaltan vana');
      // Vana açılınca görevi biter: suya çekilip kaybolur (kullanıcı
      // isteği; eskiden su inerken suyun üstünde bekliyordu).
      final drain = game.world.children.whereType<Valve>().firstWhere(
        (v) => !v.fill,
      );
      drain.use();
      run(game, 3);
      expect(face.isMounted, isFalse, reason: 'vana açılınca kaybolur');
    },
  );

  testWithGame<GolgeGame>(
    'Yerebatan: boşaltılmış haznenin dibinden Su İyesi yükselmez',
    GolgeGame.new,
    (game) async {
      await _level(game, 0);
      final basin = game.world.children.whereType<WaterBasin>().first;
      basin
        ..target = basin.area.bottom - 6
        ..surface = basin.area.bottom - 6;
      _standAt(game, 267, 9);
      run(game, 4);
      expect(game.world.children.whereType<WaterFace>(), isEmpty);
      expect(game.mythsSeen, isNot(contains('suIyesi')));
    },
  );

  testWithGame<GolgeGame>(
    'Gökyolu: sütun geçilince Tulpar gökte geçer',
    GolgeGame.new,
    (game) async {
      await _level(game, 2);
      game.player!.position.x = 141 * kTile;
      run(game, 0.3);
      expect(game.world.children.whereType<TulparFlight>(), hasLength(1));
      expect(game.mythsSeen, contains('tulpar'));
      run(game, TulparFlight.duration + 0.5);
      expect(game.world.children.whereType<TulparFlight>(), isEmpty);
    },
  );

  testWithGame<GolgeGame>(
    'Ağrı: donmuş çanın yanında Ayaz Ata bir an belirir',
    GolgeGame.new,
    (game) async {
      await _level(game, 4);
      _standAt(game, 236, 16);
      run(game, 0.5);
      expect(game.world.children.whereType<Apparition>(), hasLength(1));
      expect(game.mythsSeen, contains('ayazAta'));
      run(game, 9);
      expect(game.world.children.whereType<Apparition>(), isEmpty);
    },
  );

  testWithGame<GolgeGame>(
    'Gemi: tufan başlayınca Ak Ana sudan yükselir',
    GolgeGame.new,
    (game) async {
      await _level(game, 5);
      final flood = game.world.children.whereType<WaterBasin>().reduce(
        (a, b) =>
            (a.area.center.dx - 195 * kTile).abs() <
                (b.area.center.dx - 195 * kTile).abs()
            ? a
            : b,
      );
      flood.startFlood();
      run(game, 0.5);
      expect(game.world.children.whereType<AkAnaRise>(), hasLength(1));
      expect(game.mythsSeen, contains('akAna'));
    },
  );

  testWithGame<GolgeGame>(
    'Gün Doğumu: dev yıkılınca Basat\'ın dizesi',
    GolgeGame.new,
    (game) async {
      await _level(game, 7);
      game.world.children.whereType<StoneGiant>().first.fallen = true;
      run(game, 0.3);
      expect(game.mythsSeen, contains('basat'));
    },
  );

  testWithGame<GolgeGame>(
    'Peri: uzun kıpırdamayanın ışığını Albastı çeker; uzaklaşınca dağılır; '
    'demir nalın yanına yaklaşamaz',
    GolgeGame.new,
    (game) async {
      await _level(game, 11);
      // Nalın yanında beklemek güvenli.
      _standAt(game, 203, 25);
      run(game, 6);
      expect(game.world.children.whereType<Horseshoe>(), hasLength(1));
      expect(game.world.children.whereType<AlbastiShade>(), isEmpty);
      // Mağaranın derinliğinde kıpırdamadan bekleyince belirir.
      _standAt(game, 226, 25);
      run(game, 5);
      expect(game.world.children.whereType<AlbastiShade>(), hasLength(1));
      run(game, 2);
      expect(game.jarSteal, greaterThan(0.5));
      expect(game.jarStrength, lessThan(0.75));
      _standAt(game, 230, 25);
      run(game, 2);
      expect(game.world.children.whereType<AlbastiShade>(), isEmpty);
      expect(game.jarSteal, 0);
    },
  );

  testWithGame<GolgeGame>(
    'bölüm başlığından sonra ozanın dizesi bir kez söylenir',
    GolgeGame.new,
    (game) async {
      await _level(game, 0);
      game.debugShowTitle();
      run(game, 0.5);
      expect(game.onceShown('bard:0'), isFalse);
      run(game, 6.5);
      expect(game.onceShown('bard:0'), isTrue);
    },
  );
}
