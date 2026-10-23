// Anlatım ayarları: hikâye fısıltıları ve ipuçları kapatılabilir (panelde
// kalır, oynanışı anlatan sözler yine söylenir); izlenmiş perde atlanır.
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/narration.dart';
import 'package:golge/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Settings.debugReopen();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    Settings.storyWhispers = true;
    Settings.hints = true;
    Settings.skipSeenPerde = false;
    Settings.seenPerde.clear();
  });

  testWithGame<GolgeGame>(
    'fısıltılar kapalı: hikâye satırı ekrana gelmez, panelde okunur; oyunu anlatan söz gelir',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.narration.resetScene();
      Settings.storyWhispers = false;
      game.narration.whisper('Hikâye satırı.');
      game.update(0.1);
      expect(game.narration.debugWhispers, isEmpty);
      expect(
        game.narration.recent.any(
          (l) => l.kind == RecentKind.story && l.text == 'Hikâye satırı.',
        ),
        isTrue,
      );
      game.narration.whisper('Kural şiiri.', story: false);
      game.update(0.1);
      expect(game.narration.debugWhispers, ['Kural şiiri.']);
    },
  );

  testWithGame<GolgeGame>(
    'ipuçları kapalı: ekrana gelmez, panelde okunur, gösterilmiş sayılır',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.narration.resetScene();
      Settings.hints = false;
      var shown = false;
      game.narration.hint('Çömel.', onShown: () => shown = true);
      game.narration.hint('Sıradaki.', queue: true);
      game.update(0.1);
      expect(game.narration.debugHint, isNull);
      expect(shown, isTrue);
      final hints = game.narration.recent
          .where((l) => l.kind == RecentKind.hint)
          .map((l) => l.text);
      expect(hints, containsAll(['Çömel.', 'Sıradaki.']));
    },
  );

  testWithGame<GolgeGame>(
    'gördüğüm perdeleri atla: izlenmiş açılış perdesi oynamaz, ilk kez izlenen oynar',
    GolgeGame.new,
    (game) async {
      await game.ready();
      Settings.skipSeenPerde = true;
      Settings.seenPerde.clear();
      game.startNewGame();
      game.update(0.1);
      expect(game.narration.inCinematic, isTrue, reason: 'ilk kez: oynar');
      expect(Settings.seenPerde, contains('prologue'));
      game.backToMenu();
      game.update(0.1);
      game.startNewGame();
      game.update(0.1);
      expect(game.narration.inCinematic, isFalse, reason: 'izlendi: atlanır');
    },
  );
}
