// Bölüme giriş anları: düşüş, süzülüş, iniş, beliriş biter; Sâye bölümün
// başında ayakta ve canlı, denetim ona geçer.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entrance.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';

void main() {
  for (final lv in [0, 3, 16, 17, 18]) {
    testWithGame<GolgeGame>(
      'giriş $lv: ${entranceFor(lv)!.name}',
      GolgeGame.new,
      (game) async {
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(lv);
        await game.ready();
        final p = game.player!;
        final start = p.position.clone();
        game.debugEntrance();
        await game.ready();
        game.update(1 / 60);
        expect(game.cinematic, isTrue, reason: 'giriş sırasında denetim yok');
        if (entranceFor(lv) != EntranceKind.emerge) {
          expect(
            p.position.y,
            lessThan(start.y - 2 * kTile),
            reason: 'yukarıdan başlar',
          );
        }
        var t = 0.0;
        while (game.cinematic && t < 8) {
          game.update(1 / 60);
          t += 1 / 60;
        }
        expect(game.cinematic, isFalse, reason: 'denetim oyuncuya geçer');
        expect(t, lessThan(5));
        expect(p.isDead, isFalse);
        expect(p.onGround, isTrue);
        expect((p.position.x - start.x).abs(), lessThan(4));
        expect((p.position.y - start.y).abs(), lessThan(4));
        expect(p.entranceAlpha, 1);
        for (var i = 0; i < 180; i++) {
          game.update(1 / 60);
        }
        expect(
          game.world.children.whereType<Entrance>(),
          isEmpty,
          reason: 'ışık söner, giriş kalkar',
        );
      },
    );
  }
}
