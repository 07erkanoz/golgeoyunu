import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/puzzles.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show keys, place, run;

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

    testWithGame<GolgeGame>(
      'ışının dışında, Medusa\'nın dibinde yürüyen taşa dönmez',
      GolgeGame.new,
      (game) async {
        // Medusa 6. satırda; oyuncu iki satır aşağıda, burnunun dibinde.
        final p = await trial(game, hall, col: 25, row: 8);
        final m = game.world.children.whereType<MedusaHead>().first;
        while (!m.gazing) {
          game.update(1 / 60);
        }
        expect(m.inGaze(p.center), isFalse);
        keys(game).right = true;
        run(game, 0.3);
        expect(p.isDead, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'bakışın içinde doğan taşa dönmez (sonsuz ölüm döngüsü yok)',
      GolgeGame.new,
      (game) async {
        GolgeGame.debugLevels = [
          const LevelDef(
            title: 'M',
            subtitle: '',
            theme: LevelTheme.cistern,
            map: [
              '##############################',
              '#............................#',
              '#..............U.............#',
              '#............................#',
              '#P...........................#',
              '##############################',
            ],
          ),
        ];
        game.debugLoadLevel(0);
        await game.ready();
        game.cinematic = false;
        run(game, 1.5);
        expect(game.player!.isDead, isFalse);
      },
    );

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

  group('Sarnıcın iki yüzü', () {
    Future<(GiantPerde, Gate)> load(GolgeGame game) async {
      final p = await place(game, 0, 112, 9);
      p.hidden = false;
      final perde = game.world.children.whereType<GiantPerde>().first;
      final gate = game.world.children
          .whereType<Gate>()
          .where((g) => g.position.x > perde.position.x)
          .reduce((a, b) => a.position.x < b.position.x ? a : b);
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      run(game, 0.2);
      return (perde, gate);
    }

    void standAt(GolgeGame game, double x) {
      final p = game.player!;
      p.position.x = x - Player.w / 2;
      p.velocity.setZero();
      run(game, 0.15);
    }

    testWithGame<GolgeGame>(
      'kandil yanlış duraktayken gölge göze düşse de kapı açılmaz',
      GolgeGame.new,
      (game) async {
        final (perde, gate) = await load(game);
        expect(perde.puzzle, isTrue);
        expect(perde.stop, 2);
        // Başlangıç durağı (sağ): gölge göze düşer, ama ışık taşa yetmez.
        standAt(game, perde.standFor(2));
        run(game, 1.5);
        expect(perde.shadowOnMark, isTrue);
        expect(perde.solved, isFalse);
        expect(gate.solid, isTrue);
        // Orta durak da olmaz.
        perde.pull();
        run(game, 1.5);
        standAt(game, perde.standFor(1));
        run(game, 1.5);
        expect(perde.solved, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'ip iki kez çekilip kandil sola alınınca: gölge göze, ışık taşa, kapı açılır',
      GolgeGame.new,
      (game) async {
        final (perde, gate) = await load(game);
        final cord = game.world.children.whereType<PerdeCord>().first;
        cord.use();
        cord.use();
        expect(perde.stop, 0);
        run(game, 1.5);
        standAt(game, perde.standFor(0));
        // Çömelip ışığı saklarsa olmaz.
        game.controls.keyboard.down = true;
        run(game, 1.2);
        expect(perde.solved, isFalse);
        game.controls.keyboard.down = false;
        run(game, 1.6);
        expect(game.world.children.whereType<EyeStone>().first.lit, isTrue);
        expect(perde.solved, isTrue);
        run(game, 3);
        expect(gate.solid, isFalse);
      },
    );
  });

  group('Perde bulmacası öğretir', () {
    Future<(GiantPerde, Gate)> load(GolgeGame game) async {
      final p = await place(game, 0, 112, 9);
      p.hidden = false;
      final perde = game.world.children.whereType<GiantPerde>().firstWhere(
        (g) => g.puzzle,
      );
      final gate = game.world.children
          .whereType<Gate>()
          .where((g) => g.position.x > perde.position.x)
          .reduce((a, b) => a.position.x < b.position.x ? a : b);
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      run(game, 0.2);
      return (perde, gate);
    }

    testWithGame<GolgeGame>(
      'doğru durak hesaplanır; takılınca yardım kademe kademe gelir',
      GolgeGame.new,
      (game) async {
        final (perde, gate) = await load(game);
        expect(perde.goodStop, 0, reason: 'iki koşul yalnız sol durakta');
        final cord = game.world.children.whereType<PerdeCord>().first;
        // Dört çekiş: ipucu simgesi uyanır.
        for (var i = 0; i < 4; i++) {
          cord.use();
          run(game, 0.2);
        }
        expect(perde.help, 1);
        expect(game.narration.hintReady.value, isTrue);
        // Yedi çekiş: ayak izi ve çağıran ip.
        for (var i = 0; i < 3; i++) {
          cord.use();
          run(game, 0.2);
        }
        expect(perde.help, 2);
        expect(perde.stop == perde.goodStop, perde.beckon == false);
        // Doğru durağa gelince ip susar.
        while (perde.stop != perde.goodStop) {
          cord.use();
        }
        run(game, 0.2);
        expect(perde.beckon, isFalse);
        // Kapıda iki göz: taşın gözü ışık taşa değince yanar.
        expect(gate.emblemGlowStone, greaterThanOrEqualTo(0));
      },
    );
  });

  group('Gemide terazi', () {
    Future<(ArkScale, Gate)> load(GolgeGame game, int col) async {
      await place(game, 5, col, 22);
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      run(game, 0.3);
      final scale = game.world.children.whereType<ArkScale>().first;
      final gate = game.world.children
          .whereType<Gate>()
          .where((g) => g.position.x > scale.lift.b.position.x)
          .reduce((a, b) => a.position.x < b.position.x ? a : b);
      return (scale, gate);
    }

    AnimalCrate crateAt(GolgeGame game, int col) => game.world.children
        .whereType<AnimalCrate>()
        .firstWhere((c) => (c.home.x / kTile).floor() == col);

    void push(GolgeGame game, {required bool right, double seconds = 1.2}) {
      final k = keys(game);
      if (right) {
        k.right = true;
      } else {
        k.left = true;
      }
      run(game, seconds);
      k
        ..left = false
        ..right = false;
      run(game, 1.5);
    }

    testWithGame<GolgeGame>(
      'iki geyik iki kefeye: terazi hizalanır, kapı açılır',
      GolgeGame.new,
      (game) async {
        final (scale, gate) = await load(game, 245);
        expect(scale.kindA, AnimalKind.deer);
        expect(scale.kindB, AnimalKind.deer);
        // Soldaki geyiği sola, sol kefeye.
        push(game, right: false);
        expect(crateAt(game, 244).riding, scale.lift.a);
        // Sağdaki geyiğe git (filin üstünden atla), sağa, sağ kefeye.
        game.player!.position.x = 247 * kTile + 8;
        run(game, 0.3);
        push(game, right: true, seconds: 1.0);
        expect(crateAt(game, 248).riding, scale.lift.b);
        // Sâye kefede durursa ağırlığı dengeyi bozar: rafa geri çekilir.
        game.player!.position.x = 246 * kTile + 20;
        game.player!.position.y = 22 * kTile + kTile - 28;
        run(game, 4);
        expect(scale.lift.level, isTrue);
        expect(scale.solved, isTrue);
        run(game, 3);
        expect(gate.solid, isFalse);
      },
    );

    testWithGame<GolgeGame>(
      'fil ağırdır: geyikle dengelenmez; kol teraziyi boşaltır',
      GolgeGame.new,
      (game) async {
        final (scale, gate) = await load(game, 247);
        // Fili sola iter: önündeki geyiği de iter, ikisi de sol kefeye
        // düşer ya da fil düşer; terazi dengelenmez.
        push(game, right: false, seconds: 2.5);
        game.player!.position.x = 249 * kTile - 20;
        run(game, 0.5);
        run(game, 4);
        expect(scale.solved, isFalse);
        expect(gate.solid, isTrue);
        // Kol: hayvanlar yerine döner, kefeler hizalanır.
        final crank = game.world.children.whereType<ScaleCrank>().first;
        crank.use();
        run(game, 1);
        expect(crateAt(game, 244).position, crateAt(game, 244).home);
        expect(crateAt(game, 246).position, crateAt(game, 246).home);
        expect(scale.lift.level, isTrue);
      },
    );
  });
}
