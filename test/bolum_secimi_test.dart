// Menüdeki bölüm listesinden her bölüm başlatılabilmeli.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/settings.dart';
import 'package:golge/game/otuken.dart';

void main() {
  for (final id in levelOrder) {
    testWithGame<GolgeGame>('bölüm listesinden başlar: $id', GolgeGame.new, (
      game,
    ) async {
      game.onGameResize(Vector2(1280, 720));
      await game.ready();
      Settings.unlocked = levelOrder.length - 1;
      expect(game.menuMode.value, isTrue);
      game.startChapter(id);
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
      }
      expect(game.menuMode.value, isFalse);
      expect(game.levelIndex, id);
      expect(game.player, isNotNull);
    });
  }
  testWithGame<GolgeGame>(
    'ormanı bitirmiş kayıtla (eski olay anahtarı) bölümler yine başlar',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      await game.ready();
      Settings.unlocked = levelOrder.length - 1;
      SaveGame.current = SaveData(
        level: 14,
        x: 73,
        y: 964,
        memories: const ['17:0'],
        whispers: const [
          'event:karabasanEnd',
          'event:karabasanEnd:17',
          'event:glimpse:17:528',
          '17:0',
        ],
        fireflies: 3,
        wings: true,
      );
      game.startChapter(17);
      for (var i = 0; i < 60 * 2; i++) {
        game.update(1 / 60);
      }
      expect(game.menuMode.value, isFalse);
      expect(game.levelIndex, 17);
      // Baştan oynanınca finalin Karabasan'ı yeniden dağılır.
      expect(game.world.children.whereType<KarabasanEnd>(), hasLength(1));
      SaveGame.current = null;
    },
  );
}
