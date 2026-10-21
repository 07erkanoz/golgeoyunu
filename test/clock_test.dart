import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

/// Uzun düz bir koridor; en sağda bekleyen bir Kandilci.
const _hall = [
  '##################################################',
  '#................................................#',
  '#................................................#',
  '#................................................#',
  '#................................................#',
  '#P...............................................#',
  '##################################################',
  '##################################################',
];

Future<GolgeGame> _load(GolgeGame game, List<String> map) async {
  GolgeGame.debugLevels = [
    LevelDef(title: 'SAAT', subtitle: '', theme: LevelTheme.cistern, map: map),
  ];
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  game.update(1 / 60);
  return game;
}

/// [frames] sırasıyla tekrar eden kare süreleriyle [seconds] kadar oynatır.
void play(GolgeGame game, double seconds, List<double> frames) {
  var t = 0.0;
  var i = 0;
  while (t < seconds - 1e-9) {
    final dt = frames[i++ % frames.length];
    game.update(dt);
    t += dt;
  }
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  // Oyuncunun bir saniyede aldığı yol: kare hızından bağımsız olmalı.
  Future<double> walked(GolgeGame game, List<double> frames) async {
    await _load(game, _hall);
    final p = game.player!;
    play(game, 0.5, const [1 / 60]);
    final x0 = p.position.x;
    game.controls.keyboard.right = true;
    play(game, 1.0, frames);
    game.controls.keyboard.right = false;
    return p.position.x - x0;
  }

  final reference = <double>[];
  for (final (name, frames) in [
    ('60 Hz', const [1 / 60]),
    ('20 FPS', const [1 / 20]),
    ('15 FPS', const [1 / 15]),
    ('sarsıntılı', const [1 / 60, 1 / 60, 0.12, 1 / 30, 0.05]),
  ]) {
    testWithGame<GolgeGame>(
      'yürüyüş yolu kare hızından bağımsız: $name',
      GolgeGame.new,
      (game) async {
        final d = await walked(game, frames);
        if (reference.isEmpty) {
          reference.add(d);
          expect(d, greaterThan(Player.runSpeed * 0.7));
        } else {
          expect(d, closeTo(reference.first, reference.first * 0.05));
        }
      },
    );
  }

  testWithGame<GolgeGame>(
    'Kandilci düşük FPS’te oyuncudan hızlı yaşamaz',
    GolgeGame.new,
    (game) async {
      // Aynı gerçek sürede, 15 FPS ile 60 Hz'te ikisi de aynı yolu alır.
      Future<double> guardWalk(List<double> frames) async {
        await _load(game, _hall);
        final g = Guard(Vector2(40 * kTile, 5 * kTile))..facing = -1;
        game.world.add(g);
        game.player!.position.x = kTile * 2;
        game.update(1 / 60);
        final x0 = g.position.x;
        play(game, 2, frames);
        return x0 - g.position.x;
      }

      final fast = await guardWalk(const [1 / 60]);
      final slow = await guardWalk(const [1 / 15]);
      expect(fast, greaterThan(0));
      expect(slow, closeTo(fast, fast * 0.08));
    },
  );

  testWithGame<GolgeGame>(
    'uzun kesinti (uygulama arka planda) telafi edilmez',
    GolgeGame.new,
    (game) async {
      await _load(game, _hall);
      final p = game.player!;
      game.controls.keyboard.right = true;
      final x0 = p.position.x;
      game.update(5);
      expect(p.position.x - x0, lessThan(Player.runSpeed * 0.2));
      expect(p.position.x.isFinite, isTrue);
    },
  );
}
