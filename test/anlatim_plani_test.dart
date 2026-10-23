// Anlatımın yeni düzeni: oynanış sırasında az söz; rivayetler Umay ağacında
// (Sâye durup dinlerse), fazlası Defter'de.
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/anlatim_plani.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/strings.dart';

void main() {
  test('her bölümün her fısıltısının bir yeri var; az söz', () {
    S.lang = Lang.tr;
    for (final l in levelOrder) {
      final n = levels[l].whisperTexts.length;
      final places = [for (var i = 0; i < n; i++) whisperPlace(l, i).$1];
      expect(whisperPlan[l]?.length, n, reason: 'bölüm $l');
      expect(
        places.where((p) => p == WhisperPlace.yazi).length,
        lessThanOrEqualTo(4),
        reason: 'bölüm $l: oynanış sırasında en çok dört yazı',
      );
      expect(
        places.where((p) => p == WhisperPlace.tehlike).length,
        lessThanOrEqualTo(2),
        reason: 'bölüm $l: en çok iki tehlike sözü',
      );
    }
  });

  testWithGame<GolgeGame>(
    'Umay ağacında durunca rivayet anlatılır, bir kez',
    GolgeGame.new,
    (game) async {
      // Yerebatan: ağaçta anlatılacak ilk rivayet.
      const lv = 0;
      final tale = whisperPlan[lv]!.entries.firstWhere(
        (e) => e.value.$1 == WhisperPlace.agac,
      );
      final col = tale.value.$2!;
      game.debugLoadLevel(lv);
      await game.ready();
      game.narration.resetScene();
      final tree = game.level.checkpointCells.firstWhere(
        (c) => (c.x / kTile).round() == col,
      );
      final p = game.player!;
      p.position.setFrom(Level.standOn(tree, Player.w, Player.h));
      final text = levels[lv].whisperTexts[tale.key];
      var heard = false;
      for (var i = 0; i < 60 * 4 && !heard; i++) {
        game.update(1 / 60);
        heard = game.narration.debugWhispers.contains(text);
      }
      expect(heard, isTrue, reason: 'ağacın yanında durunca anlatılır');
      // Uzaklaşıp geri gelince aynı rivayet yeniden anlatılmaz.
      game.narration.resetScene();
      for (var i = 0; i < 60 * 4; i++) {
        game.update(1 / 60);
      }
      expect(game.narration.debugWhispers.contains(text), isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'ağaca ya da Defter\'e taşınan fısıltı haritadaki yerinde söylenmez',
    GolgeGame.new,
    (game) async {
      const lv = 0;
      game.debugLoadLevel(lv);
      await game.ready();
      final moved = [
        for (final (i, cell) in game.level.triggers)
          if (whisperPlace(lv, i).$1 == WhisperPlace.agac) (i, cell),
      ];
      expect(moved, isNotEmpty);
      final (i, cell) = moved.first;
      game.narration.resetScene();
      final p = game.player!;
      p.position.setFrom(Level.standOn(cell, Player.w, Player.h));
      for (var k = 0; k < 30; k++) {
        game.update(1 / 60);
      }
      expect(
        game.narration.debugWhispers.contains(levels[lv].whisperTexts[i]),
        isFalse,
      );
    },
  );
}
