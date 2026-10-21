import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/persist.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';
import 'package:golge/settings.dart';

import 'physics_test.dart' show run;

/// Kol, kapı, kontrol noktası ve sandıklı küçük bir oda.
const _room = [
  '########################################',
  '#......................................#',
  '#......................................#',
  '#......................................#',
  '#......................................#',
  '#......................................#',
  '#.............H........................#',
  '#.............H........................#',
  '#.............H........................#',
  '#P..L.........H.....K..........C.......#',
  '########################################',
  '########################################',
];

Future<void> _load(GolgeGame game) async {
  GolgeGame.debugLevels = [
    const LevelDef(
      title: 'KAYIT',
      subtitle: '',
      theme: LevelTheme.cistern,
      map: _room,
    ),
  ];
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  run(game, 0.2);
}

void _standAt(GolgeGame game, int col) {
  game.player!.position.setFrom(
    Level.standOn(Vector2(col * kTile, 9 * kTile), Player.w, Player.h),
  );
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  testWithGame<GolgeGame>(
    'ölünce kontrol noktasındaki düzen geri gelir: kapı açık, sandık yerinde',
    GolgeGame.new,
    (game) async {
      await _load(game);
      game.world.children.whereType<Lever>().first.pull();
      final crate = game.world.children.whereType<Crate>().first;
      crate.position.x -= 3 * kTile;
      final movedX = crate.position.x;
      run(game, 1);
      game.fireflies = 4;
      _standAt(game, 20);
      run(game, 0.3);

      // Kontrol noktasından sonra her şey harcanır, sonra ölünür.
      game.fireflies = 0;
      _standAt(game, 26);
      run(game, 0.2);
      game.player!.die();
      run(game, 3);

      final gate = game.world.children.whereType<Gate>().first;
      expect(gate.solid, isFalse, reason: 'açılmış kapı kapanmamalı');
      expect(game.world.children.whereType<Lever>().first.pulled, isTrue);
      final again = game.world.children.whereType<Crate>().first;
      expect(again.position.x, closeTo(movedX, 0.5));
      expect(game.fireflies, 4, reason: 'kontrol noktasındaki kadar');
      expect(game.player!.position.x, closeTo(20 * kTile, kTile));
    },
  );

  testWithGame<GolgeGame>(
    'Devam et de bulmaca düzenini kayıttan kurar',
    GolgeGame.new,
    (game) async {
      await _load(game);
      game.world.children.whereType<Lever>().first.pull();
      run(game, 1);
      _standAt(game, 20);
      run(game, 0.3);
      await SaveGame.flush();
      final saved = SaveGame.current!;
      expect(saved.puzzle, isNotEmpty);
      // Kayıt dosyadan okunmuş gibi: JSON'dan geri çözülür.
      SaveGame.current = SaveData.decode(saved.encode());
      expect(SaveGame.current!.puzzle['gate#0'], 1);

      game.backToMenu();
      run(game, 0.2);
      game.continueGame();
      run(game, 0.5);
      expect(game.world.children.whereType<Gate>().first.solid, isFalse);
      expect(game.world.children.whereType<Lever>().first.pulled, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'yeni bölümde ya da bölüm seçince eski düzen taşınmaz',
    GolgeGame.new,
    (game) async {
      await _load(game);
      game.world.children.whereType<Lever>().first.pull();
      run(game, 1);
      _standAt(game, 20);
      run(game, 0.3);
      game.debugLoadLevel(0);
      run(game, 0.3);
      expect(game.world.children.whereType<Gate>().first.solid, isTrue);
    },
  );

  test('bozuk bulmaca durumu parçayı başlangıç hâliyle kurar', () {
    final gate = Gate(3, 2, 5);
    final crate = Crate(Vector2(64, 64));
    final out = restorePuzzle(
      [gate, crate],
      {
        'gate#0': 'saçma',
        'crate#0': ['x', double.nan],
      },
    );
    expect(out, [gate, crate]);
    expect(gate.solid, isTrue);
    expect(crate.position, Vector2(65, 64 + kTile - Crate.side));
  });

  // Her gerçek bölüm: kollar çekilip aynalar çevrilir, saklanır, ölünür;
  // düzen aynen geri kurulmalı.
  for (var i = 0; i < levels.length; i++) {
    testWithGame<GolgeGame>(
      '${levels[i].title}: ölünce çözülmüş düzen geri gelir',
      GolgeGame.new,
      (game) async {
        game.debugLoadLevel(i);
        await game.ready();
        game.cinematic = false;
        run(game, 0.3);
        for (final l in game.world.children.whereType<Lever>()) {
          l.pull();
        }
        for (final m in game.world.children.whereType<Mirror>()) {
          m.use();
        }
        run(game, 0.5);
        game.debugCheckpoint();
        Map<String, Object?> settled() => {
          for (final e in capturePuzzle(game.world.children).entries)
            if (!e.key.startsWith('crate') &&
                !e.key.startsWith('guard') &&
                !e.key.startsWith('lift'))
              e.key: e.value,
        };
        final before = settled();
        game.player!.die();
        run(game, 3);
        expect(game.player!.isDead, isFalse);
        expect(settled(), before);
      },
    );
  }
}
