import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/narration.dart';

import 'physics_test.dart' show run;

void main() {
  testWithGame<GolgeGame>(
    'az önce: anlatılan hikâye ve ipucu saklanır; panel açılınca oyun bekler',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      run(game, 0.2);
      game.narration.whisper('Bir fısıltı.');
      game.narration.hint('Bir ipucu', queue: true);
      run(game, 1);
      final kinds = game.narration.recent.map((l) => l.kind).toList();
      expect(kinds, containsAll([RecentKind.story, RecentKind.hint]));
      expect(
        game.narration.recent.any((l) => l.text == 'Bir fısıltı.'),
        isTrue,
      );
      game.toggleRecent();
      expect(game.paused, isTrue);
      expect(game.settingsOpen.value, isTrue);
      game.toggleRecent();
      expect(game.paused, isFalse);
      expect(game.settingsOpen.value, isFalse);
    },
  );
  testWithGame<GolgeGame>(
    'iki panel: biri kapanınca öbürü açıkken oyun duraklı kalır',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      run(game, 0.2);
      game.toggleSettings();
      expect(game.paused, isTrue);
      // Ayarlar açıkken "Az önce" açılmaz.
      game.toggleRecent();
      expect(game.recentOpen, isFalse);
      game.toggleSettings();
      expect(game.paused, isFalse);
      game.toggleRecent();
      expect(game.paused, isTrue);
      // "Az önce" açıkken ayarlar açılıp kapanırsa oyun yine bekler.
      game.toggleSettings();
      game.toggleSettings();
      expect(game.paused, isTrue);
      expect(game.settingsOpen.value, isTrue);
      game.toggleRecent();
      expect(game.paused, isFalse);
      expect(game.settingsOpen.value, isFalse);
    },
  );
}
