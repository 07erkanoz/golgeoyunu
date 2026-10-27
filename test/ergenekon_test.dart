import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/ergenekon.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show run;

/// Ocaklı, iki körüklü küçük vadi ve akan demirli çukur.
const _vale = [
  '##############################',
  '#..............#.............#',
  '#..............#.............#',
  '#..............d.............#',
  '#..............d.............#',
  '#..............d.............#',
  '#.P............d......K......#',
  '##################uuuu########',
  '##################....########',
  '##################^^^^########',
];

Future<void> _load(GolgeGame game) async {
  GolgeGame.debugLevels = [
    const LevelDef(
      title: 'VADİ',
      subtitle: '',
      theme: LevelTheme.ergenekon,
      map: _vale,
      bellows: [(5, 6, 1), (9, 6, 2), (12, 6, 0)],
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

void _press(GolgeGame game) {
  game.controls.keyboard.up = true;
  run(game, 0.05);
  game.controls.keyboard.up = false;
  run(game, 0.1);
}

Bellows _bellows(GolgeGame game, int order) => game.world.children
    .whereType<Bellows>()
    .firstWhere((b) => b.order == order);

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  testWithGame<GolgeGame>(
    'ocak sönükken körük işe yaramaz; ateşböceği yakar; doğru sırayla damar erir',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final vein = game.world.children.whereType<IronVein>().single;
      expect(vein.bellowsCount, 2, reason: 'süs körük sayılmaz');
      expect(_bellows(game, 1).vein, vein);
      _standAt(game, 5);
      run(game, 0.2);
      _press(game);
      expect(vein.heat, 0, reason: 'ocak sönük');
      // Ateşböceği ocağa salınır.
      game.world.add(FireflyLure(Vector2(14 * kTile, 6 * kTile), 1));
      run(game, 1);
      expect(vein.lit, isTrue);
      // Yanlış sıra ateşi söndürür.
      _standAt(game, 9);
      run(game, 0.2);
      _press(game);
      expect(vein.heat, 0);
      // Doğru sıra: 1, sonra 2.
      _standAt(game, 5);
      run(game, 0.2);
      _press(game);
      expect(vein.heat, closeTo(0.5, 0.01));
      _standAt(game, 9);
      run(game, 0.2);
      _press(game);
      expect(vein.opening, isTrue);
      expect(vein.solid, isTrue, reason: 'erimesi zaman alır');
      // Son körükte kamera damara döner: kapının açıldığı görülür.
      final look = game.focusTarget;
      expect(look, isNotNull);
      expect((look!.x - vein.position.x).abs(), lessThan(kTile));
      run(game, 2.5);
      expect(vein.solid, isFalse, reason: 'erimiş damardan geçilir');
      // Kontrol noktasında saklanır, ölünce erimiş kalır.
      game.player!.position.setFrom(
        Level.standOn(Vector2(22 * kTile, 6 * kTile), Player.w, Player.h),
      );
      run(game, 0.5);
      game.player!.die();
      run(game, 3);
      final again = game.world.children.whereType<IronVein>().single;
      expect(again.solid, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'oyunda: ocağa doğru salınan ateşböceği ocağa çekilir ve yakar',
    GolgeGame.new,
    (game) async {
      GolgeGame.debugLevels = null;
      game.debugLoadLevel(15);
      await game.ready();
      game.cinematic = false;
      final vein = game.world.children.whereType<IronVein>().first;
      final forge = vein.forge;
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2(forge.dx - 7 * kTile, forge.dy - kTile),
          Player.w,
          Player.h,
        ),
      );
      run(game, 0.3);
      game.releaseFirefly(p.center.clone(), 1);
      run(game, 3);
      expect(vein.lit, isTrue);
    },
  );

  test('oyunda: ilk damarla akan demir arasında Umay ağacı var', () {
    // Akan demirde ölen körüklerin başına dönmesin.
    final lv = Level(levels[15]);
    final vein = lv.def.map[34].indexOf('d');
    expect(vein, greaterThan(0));
    final channel = lv.def.map[35].indexOf('u');
    expect(
      lv.checkpointCells.any((c) {
        final col = (c.x / kTile).round();
        return col > vein && col < channel;
      }),
      isTrue,
    );
  });

  testWithGame<GolgeGame>(
    'körükler arasında geç kalınırsa ateş söner',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final vein = game.world.children.whereType<IronVein>().single;
      vein.lit = true;
      _standAt(game, 5);
      run(game, 0.2);
      _press(game);
      expect(vein.heat, greaterThan(0));
      run(game, IronVein.window + 0.5);
      expect(vein.heat, 0);
      expect(vein.next, 1);
    },
  );

  testWithGame<GolgeGame>(
    'akan demir yakar; soğuyunca üstünden geçilir',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final m = game.world.children.whereType<MoltenChannel>().single;
      // Soğuk olduğu bir an bekle, üstüne bas.
      var guard = 0;
      while (m.molten && guard++ < 1000) {
        run(game, 0.05);
      }
      // Soğuma ve kara köprü süresince üstünde durulur.
      run(game, 0.9);
      _standAt(game, 19);
      run(game, 0.5);
      expect(game.player!.isDead, isFalse);
      expect(m.molten, isFalse);
      // Akmaya başlayınca yanar.
      var died = false;
      for (var i = 0; i < 600 && !died; i++) {
        run(game, 1 / 60);
        died = game.player!.isDead;
      }
      expect(died, isTrue);
    },
  );
}
