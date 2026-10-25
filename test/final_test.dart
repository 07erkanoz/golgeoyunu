// Oyunun sonu: son perde atlanmaz, perdeden sonra "Devam et" kalmaz.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/settings.dart';

void main() {
  testWithGame<GolgeGame>(
    'son bölüm bitince kayıt silinir, son perde atlanmaz',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(levelOrder.last);
      await game.ready();
      game.cinematic = false;
      game.debugCheckpoint();
      await game.saveNow();
      expect(SaveGame.current, isNotNull);
      game.onExitReached();
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
      }
      expect(game.narration.inCinematic, isTrue);
      expect(game.narration.skippable, isFalse);
      game.narration.skipAll();
      expect(game.narration.inCinematic, isTrue, reason: 'atlanmaz');
      expect(SaveGame.current, isNull);
      await game.saveNow();
      expect(SaveGame.current, isNull, reason: 'perdede de yazılmaz');
    },
  );
}
