import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show keys, run;

/// Küçük bir deneme haritası yükler, oyuncuyu (col,row) hücresine koyar.
Future<Player> trial(
  GolgeGame game,
  List<String> map, {
  int col = 2,
  int? row,
  LevelTheme theme = LevelTheme.cistern,
  bool storm = false,
}) async {
  GolgeGame.debugLevels = [
    LevelDef(
      title: 'DENEME',
      subtitle: '',
      theme: theme,
      storm: storm,
      map: map,
    ),
  ];
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(
      Vector2(col * kTile, (row ?? map.length - 3) * kTile),
      Player.w,
      Player.h,
    ),
  );
  run(game, 0.2);
  return p;
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  const hall = [
    '##############################',
    '#............................#',
    '#............................#',
    '#............................#',
    '#............................#',
    '#............................#',
    '#...........................U#',
    '#............................#',
    '#P...........................#',
    '##############################',
    '##############################',
  ];

  group('Medusa', () {
    testWithGame<GolgeGame>('bakarken kıpırdayan taşa döner', GolgeGame.new, (
      game,
    ) async {
      final p = await trial(game, hall, col: 18, row: 8);
      final m = game.world.children.whereType<MedusaHead>().first;
      // Gözler açılana dek bekle, sonra yürü.
      while (!m.gazing) {
        game.update(1 / 60);
      }
      keys(game).right = true;
      run(game, 0.5);
      expect(p.isDead, isTrue);
      expect(p.deathCause, DeathCause.stone);
    });

    testWithGame<GolgeGame>('kıpırdamadan duran kurtulur', GolgeGame.new, (
      game,
    ) async {
      final p = await trial(game, hall, col: 18, row: 8);
      run(game, MedusaHead.period * 1.5);
      expect(p.isDead, isFalse);
    });

    testWithGame<GolgeGame>(
      'kalkanın ardında yürünür; kalkan yaklaşınca Medusa taşlaşır',
      GolgeGame.new,
      (game) async {
        final map = [...hall];
        map[8] = '#P.......@...................#';
        final p = await trial(game, map, col: 7, row: 8);
        final m = game.world.children.whereType<MedusaHead>().first;
        keys(game).right = true;
        for (var i = 0; i < 60 * 40 && !m.sealed && !p.isDead; i++) {
          game.update(1 / 60);
        }
        expect(p.isDead, isFalse);
        expect(m.sealed, isTrue);
      },
    );

    testWithGame<GolgeGame>(
      'Kandilci bakışa girince heykele döner',
      GolgeGame.new,
      (game) async {
        final map = [...hall];
        map[8] = '#P......................G....#';
        await trial(game, map, col: 2, row: 8);
        run(game, MedusaHead.period + 0.5);
        expect(game.world.children.whereType<Guard>(), isEmpty);
        expect(game.world.children.whereType<StoneGuard>(), isNotEmpty);
      },
    );
  });

  group('sal, baca, balon, tüy', () {
    testWithGame<GolgeGame>(
      'sal üstündekini suyun öbür ucuna taşır',
      GolgeGame.new,
      (game) async {
        const map = [
          '##############################',
          '#............................#',
          '#............................#',
          '#............................#',
          '#............................#',
          '#............................#',
          '#............................#',
          '#P.._........................#',
          '####wwwwwwwwwwwwwwwwwwwwww####',
          '####wwwwwwwwwwwwwwwwwwwwww####',
        ];
        final p = await trial(game, map, col: 2, row: 7);
        keys(game).right = true;
        run(game, 12);
        expect(p.isDead, isFalse);
        expect(p.position.x, greaterThan(22 * kTile));
      },
    );

    testWithGame<GolgeGame>('alevli baca yakar, sandık tıkar', GolgeGame.new, (
      game,
    ) async {
      const map = [
        '##############################',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#P........!..................#',
        '##############################',
        '##############################',
      ];
      var p = await trial(game, map, col: 10, row: 5);
      run(game, FireVent.rest + FireVent.warn + FireVent.burn + 0.5);
      expect(p.isDead, isTrue);

      final plugged = [...map];
      plugged[5] = '#P.......C!..................#';
      p = await trial(game, plugged, col: 6, row: 5);
      final vent = game.world.children.whereType<FireVent>().first;
      keys(game).right = true;
      for (var i = 0; i < 180 && !vent.plugged; i++) {
        game.update(1 / 60);
      }
      keys(game).right = false;
      expect(vent.plugged, isTrue);
      run(game, 5);
      expect(p.isDead, isFalse);
    });

    testWithGame<GolgeGame>(
      'fener balonunun ışığında kalan yakalanır',
      GolgeGame.new,
      (game) async {
        const map = [
          '##############################',
          '#............................#',
          '#............N...............#',
          '#............................#',
          '#............................#',
          '#............................#',
          '#P...........................#',
          '##############################',
          '##############################',
        ];
        final p = await trial(
          game,
          map,
          col: 14,
          row: 6,
          theme: LevelTheme.sky,
        );
        run(game, 8);
        expect(p.isDead, isTrue);
        expect(p.deathCause, DeathCause.light);
      },
    );

    testWithGame<GolgeGame>(
      'bütün tüyler toplanınca sunak kapıyı açar',
      GolgeGame.new,
      (game) async {
        const map = [
          '##############################',
          '#............................#',
          '#............................#',
          '#.........................H..#',
          '#.........................H..#',
          '#P...T.....T.........s....H..#',
          '##############################',
          '##############################',
        ];
        final p = await trial(game, map, col: 2, row: 5, theme: LevelTheme.kaf);
        keys(game).right = true;
        run(game, 6);
        expect(p.isDead, isFalse);
        final gate = game.world.children.whereType<Gate>().first;
        run(game, 3);
        expect(gate.solid, isFalse);
      },
    );
  });
}
