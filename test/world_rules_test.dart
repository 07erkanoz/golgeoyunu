import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/winter.dart';

import 'physics_test.dart' show run;

Future<void> _load(
  GolgeGame game,
  List<String> map, {
  LevelTheme? theme,
}) async {
  GolgeGame.debugLevels = [
    LevelDef(
      title: 'KURAL',
      subtitle: '',
      theme: theme ?? LevelTheme.cistern,
      map: map,
    ),
  ];
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  run(game, 0.1);
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  testWithGame<GolgeGame>(
    'Kandilci kapalı kapıdan geçemez; kapı açılınca geçer',
    GolgeGame.new,
    (game) async {
      await _load(game, const [
        '########################################',
        '#......................................#',
        '#......................................#',
        '#.................H....................#',
        '#.................H....................#',
        '#.................H....................#',
        '#P................H.........G..........#',
        '########################################',
        '########################################',
      ]);
      final guard = game.world.children.whereType<Guard>().first;
      final gate = game.world.children.whereType<Gate>().first;
      // Oyuncu uzakta, görünmez bir köşede: Kandilci devriye gezer.
      game.player!.position.setValues(kTile * 1.0, kTile * 1.0);
      game.player!.hidden = true;
      var leftMost = guard.position.x;
      for (var i = 0; i < 60 * 20; i++) {
        game.update(1 / 60);
        if (guard.position.x < leftMost) leftMost = guard.position.x;
      }
      expect(
        leftMost,
        greaterThanOrEqualTo(gate.position.x + gate.size.x - 1),
        reason: 'kapalı kapının soluna geçmemeli',
      );
      gate.opening = true;
      for (var i = 0; i < 60 * 30; i++) {
        game.update(1 / 60);
        if (guard.position.x < leftMost) leftMost = guard.position.x;
      }
      expect(leftMost, lessThan(gate.position.x));
    },
  );

  testWithGame<GolgeGame>(
    'duvarın ardındaki noktaya kavanoz ışığı değmez',
    GolgeGame.new,
    (game) async {
      await _load(game, const [
        '##############################',
        '#............................#',
        '#............................#',
        '#.........#..................#',
        '#.........#..................#',
        '#.........#..................#',
        '#.......P.#..................#',
        '##############################',
        '##############################',
      ]);
      final p = game.player!;
      final (light, _) = p.light;
      // Aynı uzaklıkta: duvarın bu yanı aydınlık, öte yanı karanlık.
      final open = light + Vector2(-100, 0);
      final behind = light + Vector2(100, 0);
      expect(game.litAt(open), isTrue);
      expect(game.litAt(behind), isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'kurt kapalı kapıda durur, yerinde koşmaz',
    GolgeGame.new,
    (game) async {
      await _load(game, theme: LevelTheme.snow, const [
        '########################################',
        '#......................................#',
        '#......................................#',
        '#..........H...........................#',
        '#..........H...........................#',
        '#P.........H.........b.................#',
        '########################################',
        '########################################',
      ]);
      final wolf = game.world.children.whereType<Wolf>().first;
      final gate = game.world.children.whereType<Gate>().first;
      // Oyuncu kapının ardında: kurt koku alır, kapıya koşar.
      game.player!.position.x = gate.position.x - 3 * kTile;
      run(game, 6);
      expect(wolf.position.x, greaterThanOrEqualTo(gate.position.x));
      expect(game.player!.isDead, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'kamera zıplamada inip çıkmaz; görünen alan ekranla kesintisiz değişir',
    GolgeGame.new,
    (game) async {
      await _load(game, const [
        '############################################################',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#..........................................................#',
        '#P.........................................................#',
        '############################################################',
      ]);
      game.onGameResize(Vector2(1280, 720));
      run(game, 1);
      final y0 = game.camera.viewfinder.position.y;
      var drift = 0.0;
      game.controls.keyboard.jump = true;
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
        if (i == 5) game.controls.keyboard.jump = false;
        final d = (game.camera.viewfinder.position.y - y0).abs();
        if (d > drift) drift = d;
      }
      expect(drift, lessThan(6), reason: 'zıplarken kamera $drift px oynadı');

      double tiles(double h) {
        game.onGameResize(Vector2(h * 16 / 9, h));
        return game.tilesTall;
      }

      final a = tiles(500);
      final b = tiles(530);
      expect(b - a, lessThan(1.0), reason: 'eşikte sıçrama yok');
      expect(tiles(360), 13);
      expect(tiles(900), 20);
    },
  );

  testWithGame<GolgeGame>(
    'geciken ayak sesi: yürüyüp durunca bir kez olur, hareketi etkilemez',
    GolgeGame.new,
    (game) async {
      GolgeGame.debugLevels = [
        const LevelDef(
          title: 'YANKI',
          subtitle: '',
          theme: LevelTheme.cistern,
          echoes: [(3, 30)],
          map: [
            '########################################',
            '#......................................#',
            '#......................................#',
            '#P.....................................#',
            '########################################',
          ],
        ),
      ];
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      run(game, 0.2);
      final p = game.player!;
      p.position.x = 4 * kTile;
      game.controls.keyboard.right = true;
      run(game, 1.2);
      game.controls.keyboard.right = false;
      run(game, 0.9);
      expect(p.lookingBack, isTrue);
      expect(game.eventSeen('echo:0:3'), isTrue);
      // Oyuncu hâlâ serbest: yürüyebilir.
      final x = p.position.x;
      game.controls.keyboard.right = true;
      run(game, 0.3);
      expect(p.position.x, greaterThan(x + 20));
      // Bir daha olmaz.
      game.controls.keyboard.right = false;
      run(game, 2.5);
      game.debugLoadLevel(0);
      run(game, 0.2);
      expect(game.world.children.whereType<EchoSteps>(), isEmpty);
    },
  );
}
