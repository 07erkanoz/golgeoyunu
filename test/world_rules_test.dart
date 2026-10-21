import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
