import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/heavens.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show run;

/// Bulut adaları: iki davul bulutu, yakıcı ışık, Tulpar ve fırtına.
const _sky = [
  '..................................................................',
  '..................................................................',
  '..................................................................',
  '..................................................................',
  '..................................................................',
  '..................................................................',
  '.P..........................................W.z..............Z..E.',
  '########.uuu.uuu.##########################################.#######',
  '########.........##########################################.#######',
];

Future<void> _load(GolgeGame game) async {
  GolgeGame.debugLevels = [
    const LevelDef(
      title: 'GÖK',
      subtitle: '',
      theme: LevelTheme.heavens,
      map: _sky,
      scorch: [(20, 2, 40, 7)],
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
    'davul bulutları vuruşla yer değiştirir: biri belirince öbürü söner',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final clouds = game.world.children.whereType<DrumCloud>().toList();
      expect(clouds, hasLength(2));
      expect(clouds[0].group, isNot(clouds[1].group));
      final a0 = clouds[0].active;
      expect(clouds[1].active, !a0);
      run(game, KamDrum.beat);
      expect(clouds[0].active, !a0, reason: 'bir vuruş sonra takımlar değişir');
      expect(clouds[1].active, a0);
    },
  );

  testWithGame<GolgeGame>(
    'gün katında güneşte kalan yanar; Hüma\'nın gölgesinde güvende',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final z = game.world.children.whereType<ScorchZone>().single;
      // Gölgenin uzağında dur.
      var col = 22;
      if (z.inShade((col + 0.5) * kTile)) col = 38;
      _standAt(game, col);
      var died = false;
      for (var i = 0; i < 180 && !died; i++) {
        run(game, 1 / 60);
        died = game.player!.isDead;
        // Kuş yaklaşırsa öbür uca geç.
        if (!died && z.inShade(game.player!.center.x)) break;
      }
      expect(died || z.burn > 0.3, isTrue);
      expect(game.mythsSeen, contains('umayKusu'));
      run(game, 3);
      // Ölünce bölüm yeniden kurulur: yeni zonun kuşu.
      final z2 = game.world.children.whereType<ScorchZone>().single;
      // Kuşun gölgesinde yürü: yanma birikmez.
      for (var i = 0; i < 120; i++) {
        game.player!.position.x = z2.birdX - Player.w / 2;
        game.player!.position.y = 7 * kTile - Player.h;
        run(game, 1 / 60);
      }
      expect(game.player!.isDead, isFalse);
      expect(z2.burn, lessThan(0.05));
    },
  );

  testWithGame<GolgeGame>(
    'Hüma, Sâye gün katına yaklaşana dek girişte bekler',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final z = game.world.children.whereType<ScorchZone>().single;
      final start = z.birdX;
      run(game, 4);
      expect(z.birdX, start, reason: 'uzaktayken uçmaz');
      _standAt(game, 19);
      run(game, 1);
      expect(z.birdX, greaterThan(start));
    },
  );

  testWithGame<GolgeGame>(
    'Tulpar\'ın sırtında havada zıplayınca kanat çırpılır; fırtına gelir',
    GolgeGame.new,
    (game) async {
      await _load(game);
      _standAt(game, 44);
      run(game, 0.3);
      expect(game.onHorse, isTrue);
      expect(game.flying, isTrue);
      expect(game.mythsSeen, contains('tulpar'));
      final storm = game.world.children.whereType<StormWall>().single;
      run(game, 0.1);
      expect(storm.awake, isTrue, reason: 'binince fırtına gelir');
      // Zıpla, tepeye yaklaşınca yeniden zıpla: daha yükseğe çıkar.
      final p = game.player!;
      final y0 = p.position.y;
      game.controls.keyboard.jump = true;
      run(game, 0.05);
      game.controls.keyboard.jump = false;
      run(game, 0.3);
      game.controls.keyboard.jump = true;
      run(game, 0.05);
      game.controls.keyboard.jump = false;
      var top = p.position.y;
      for (var i = 0; i < 30; i++) {
        run(game, 1 / 60);
        if (p.position.y < top) top = p.position.y;
      }
      final once =
          (Player.jumpVelocity * 1.0) *
          (Player.jumpVelocity * 1.0) /
          (2 * Player.gravity);
      expect(
        y0 - top,
        greaterThan(once * 1.1),
        reason: 'kanat çırpış yükseltir',
      );
      // Kıpırdamayanı fırtına söndürür.
      var died = false;
      for (var i = 0; i < 60 * 12 && !died; i++) {
        run(game, 1 / 60);
        died = p.isDead;
      }
      expect(died, isTrue);
    },
  );
}
