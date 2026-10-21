import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/gokboru.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/winter.dart';

import 'physics_test.dart' show run, keys;

/// Kurtlu, ince buzlu küçük bir kar ovası.
const _plain = [
  '##########################################################',
  '#........................................................#',
  '#........................................................#',
  '#........................................................#',
  '#........................................................#',
  '#........................................................#',
  '#.P..................b...........................B.....E.#',
  '############################--////----////---#############',
  '##########################################################',
];

Future<void> _load(
  GolgeGame game, {
  bool guard = true,
  bool help = false,
  List<(int, int)> watch = const [],
}) async {
  GolgeGame.debugLevels = [
    LevelDef(
      title: 'KURT',
      subtitle: '',
      theme: LevelTheme.snow,
      map: _plain,
      pawTrails: const [(26, 45, 6)],
      gokboruGuard: guard,
      gokboruHelp: help,
      gokboruWatch: watch,
      gokboruLead: 26,
    ),
  ];
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  run(game, 0.2);
}

void _standAt(GolgeGame game, int col) {
  game.player!.position.setFrom(
    Level.standOn(Vector2(col * kTile, 6 * kTile), Player.w, Player.h),
  );
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  testWithGame<GolgeGame>(
    'kurtlar Sâye\'ye atılacakken Gökbörü araya girer, kurtlar kaçar; bir kez',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final wolf = game.world.children.whereType<Wolf>().single;
      _standAt(game, 15);
      run(game, 0.6);
      final spirit = game.world.children.whereType<GokboruSpirit>().single;
      // Kurt Sâye'ye ulaşamadan kaçar.
      final before = wolf.center.x;
      run(game, 2.5);
      expect(game.player!.isDead, isFalse);
      expect(wolf.center.x, greaterThan(before), reason: 'kurt uzaklaşmalı');
      expect(game.mythsSeen, contains('gokboru'));
      // Uluduktan sonra yolun ilerisine (göl kıyısına) yürür; Sâye'den çok
      // uzaklaşmaz, onu bekler.
      run(game, 4);
      expect(spirit.position.x, lessThan(24 * kTile));
      _standAt(game, 20);
      run(game, 3);
      expect(spirit.position.x, closeTo(26.5 * kTile, 3));
      // İkinci kez araya girmez.
      spirit.removeFromParent();
      run(game, 0.1);
      wolf.position.x = 18 * kTile;
      wolf.hunting = true;
      run(game, 0.5);
      expect(game.world.children.whereType<GokboruSpirit>(), isEmpty);
    },
  );

  testWithGame<GolgeGame>(
    'pençe izleri ince buza düşmez; yalnız kavanoz örtülünce parlar',
    GolgeGame.new,
    (game) async {
      await _load(game, guard: false);
      game.world.children.whereType<Wolf>().single.removeFromParent();
      final trail = game.world.children.whereType<PawTrail>().single;
      // 26–45 arası: 30–33 ve 38–41 ince buz; geri kalanı sağlam.
      final cols = [for (final p in trail.prints) (p.x / kTile).floor()];
      expect(cols, [26, 27, 28, 29, 34, 35, 36, 37, 42, 43, 44, 45]);
      _standAt(game, 24);
      run(game, 1);
      expect(trail.cover, lessThan(0.05));
      keys(game).down = true;
      run(game, 1.5);
      expect(game.player!.crouching, isTrue, reason: "çömelmeli");
      expect(trail.cover, greaterThan(0.9));
      keys(game).down = false;
    },
  );

  testWithGame<GolgeGame>(
    'uzun süre ilerlenemezse Gökbörü yolun ilerisinde belirip ulur',
    GolgeGame.new,
    (game) async {
      await _load(game, guard: false, help: true);
      game.world.children.whereType<Wolf>().single.removeFromParent();
      _standAt(game, 4);
      run(game, 30);
      expect(game.world.children.whereType<GokboruSpirit>(), isEmpty);
      run(game, GokboruWarden.stuckAfter - 28);
      final s = game.world.children.whereType<GokboruSpirit>().single;
      expect(s.position.x, greaterThan(40 * kTile), reason: 'ileride, konakta');
    },
  );

  testWithGame<GolgeGame>(
    'uzak tepede bir an belirir, ulur ve söner',
    GolgeGame.new,
    (game) async {
      await _load(game, guard: false, watch: const [(30, 6)]);
      game.world.children.whereType<Wolf>().single.removeFromParent();
      _standAt(game, 4);
      run(game, 0.5);
      expect(game.world.children.whereType<GokboruSpirit>(), isEmpty);
      _standAt(game, 20);
      run(game, 0.5);
      expect(game.world.children.whereType<GokboruSpirit>(), hasLength(1));
      run(game, 8);
      expect(game.world.children.whereType<GokboruSpirit>(), isEmpty);
      expect(
        game.mythsSeen,
        isNot(contains('gokboru')),
        reason: 'uzaktan sezilir, Defter\'e yazılmaz',
      );
    },
  );
}
