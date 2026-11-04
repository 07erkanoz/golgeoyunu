// Yeni Sâye (A1) kuklası her bölümde: bölümün başında koşar, zıplar,
// çömelir; her karede çizilir (hata vermemeli, kukla çizilmeli).
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/levels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (var i = 0; i < levels.length; i++) {
    testWithGame<GolgeGame>('kukla: ${levels[i].title}', GolgeGame.new, (
      game,
    ) async {
      await SayeKukla.load();
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(i);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      final k = game.controls.keyboard;
      var drawn = 0;
      for (var f = 0; f < 360; f++) {
        final s = f ~/ 40;
        k
          ..right = s.isEven
          ..left = s == 5
          ..jump = f % 40 == 10 || f % 40 == 11
          ..down = s == 3
          ..up = s == 7;
        game.update(1 / 60);
        final rec = ui.PictureRecorder();
        p.renderTree(ui.Canvas(rec));
        rec.endRecording().dispose();
        if (p.kuklaOn) drawn++;
      }
      expect(drawn, greaterThan(300));
    });
  }
}
