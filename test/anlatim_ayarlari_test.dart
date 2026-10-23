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
    'ipucu simgede bekler: kendiliğinden yazılmaz, dokununca görünür',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.narration.resetScene();
      game.narration.hint('Çömel.');
      game.narration.hint('Işıkta kal.');
      game.update(0.5);
      expect(game.narration.debugHint, isNull, reason: 'ekran boş kalır');
      expect(game.narration.hintReady.value, isTrue, reason: 'simge yanar');
      expect(game.narration.debugReadyHint, 'Işıkta kal.', reason: 'en yenisi');
      game.narration.revealHint();
      expect(game.narration.debugHint, 'Işıkta kal.');
      expect(game.narration.hintReady.value, isFalse);
      for (var i = 0; i < 60 * 8; i++) {
        game.update(1 / 60);
      }
      expect(game.narration.debugHint, isNull, reason: 'okunup kapanır');
      game.narration.revealHint();
      expect(
        game.narration.debugHint,
        'Işıkta kal.',
        reason: 'simgeye yeniden dokununca son ipucu',
      );
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
      expect(game.narration.hintReady.value, isFalse, reason: 'simge yanmaz');
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
