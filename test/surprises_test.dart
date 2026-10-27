// Küçük sürprizler: utangaç gölge (Yerebatan) ve taş bekçi (Nemrut).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/puzzles.dart';
import 'package:golge/game/surprises.dart';
import 'package:golge/settings.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

void main() {
  setUp(Settings.secrets.clear);

  // Sarnıçta sütunlar beş karede bir: hangi sütunun önünde durulursa durulsun
  // sürpriz çıkmalı (önceden önü üç kare sütunsuz olmalıydı, telefonda
  // neredeyse hiç çıkmıyordu).
  for (final start in [20.0, 23.0, 137.0, 143.0]) {
    testWithGame<GolgeGame>(
      'utangaç gölge: $start. sütundan koşup durunca',
      GolgeGame.new,
      (game) async {
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(0);
        await game.ready();
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
        await game.ready();
        final p = game.player!;
        p.position.setFrom(
          Level.standOn(
            Vector2(start * kTile, 13 * kTile.toDouble()),
            Player.w,
            Player.h,
          ),
        );
        run(game, 3);
        game.controls.keyboard.right = true;
        run(game, 0.7);
        game.controls.keyboard.right = false;
        run(game, 0.8);
        expect(
          game.secretSeen('utangac'),
          isTrue,
          reason: 'durduğu yer ${(p.center.x / kTile).toStringAsFixed(1)}',
        );
      },
    );
  }

  testWithGame<GolgeGame>(
    'taş bekçi görmediğinde poz değiştirir, '
    'üçüncüde Sâye\'yi taklit eder',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      final li = levels.indexWhere(
        (d) => d.surprises.any((s) => s.$1 == 'tasBekci'),
      );
      game.debugLoadLevel(li);
      await game.ready();
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      await game.ready();
      final p = game.player!;
      final statue = game.world.children.whereType<TasBekci>().first;
      p.position.setFrom(
        Level.standOn(
          Vector2(statue.position.x - 4 * kTile, statue.position.y - kTile),
          Player.w,
          Player.h,
        ),
      );
      run(game, 3);
      // Bakarken kıpırdamaz.
      p.facing = 1;
      run(game, 2);
      expect(statue.pose, 0);
      for (var turn = 1; turn <= 3; turn++) {
        p.facing = -1; // sırtını döner
        run(game, 1);
        p.facing = 1; // geri bakar
        run(game, 0.3);
        expect(statue.pose, turn, reason: '$turn. dönüşte yeni poz');
      }
      expect(game.secretSeen('tasBekci'), isTrue);
      expect(Settings.secrets, contains('$li:tasBekci'));
      // Sonra hep taklitte kalır.
      p.facing = -1;
      run(game, 2);
      expect(statue.pose, 3);
    },
  );

  testWithGame<GolgeGame>(
    'perde çözülünce zıplayıp çömelen Sâye\'ye '
    'seyirci alkışlar',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      await game.ready();
      final p = game.player!;
      final perde = game.world.children.whereType<GiantPerde>().firstWhere(
        (g) => g.puzzle,
      );
      void stand(double x) {
        p.position.setFrom(
          Level.standOn(
            Vector2(x - kTile / 2, perde.position.y - kTile),
            Player.w,
            Player.h,
          ),
        );
        p.velocity.setZero();
      }

      void bow() {
        game.controls.keyboard.jump = true;
        run(game, 0.1);
        game.controls.keyboard.jump = false;
        var t = 0.0;
        while (!p.onGround && t < 2) {
          game.update(1 / 60);
          t += 1 / 60;
        }
        game.controls.keyboard.down = true;
        run(game, 0.3);
        game.controls.keyboard.down = false;
      }

      stand(perde.position.x + perde.size.x * 0.4);
      run(game, 3);
      // Çözülmeden önce selam bir şey yapmaz.
      bow();
      expect(perde.clapT, -1);
      // Çöz: kandil sola, gölge göze, ışık taşa.
      final cord = game.world.children.whereType<PerdeCord>().first;
      while (perde.stop != perde.goodStop) {
        cord.use();
      }
      run(game, 1.5);
      stand(perde.standFor(perde.goodStop!));
      var t = 0.0;
      while (!perde.solved && t < 5) {
        game.update(1 / 60);
        t += 1 / 60;
      }
      expect(perde.solved, isTrue);
      run(game, 4);
      stand(perde.position.x + perde.size.x * 0.4);
      run(game, 1);
      bow();
      expect(perde.clapT, greaterThanOrEqualTo(0), reason: 'seyirci belirir');
      expect(game.secretSeen('alkis'), isTrue);
    },
  );
}
