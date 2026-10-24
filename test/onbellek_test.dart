// Arazi önbelleği iki yuvalı: perdenin altında eski bölüm çizilirken sıradaki
// bölümün önceden hazırlanmış dilimleri silinmez.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/terrain.dart';

void main() {
  testWithGame<GolgeGame>('sıradaki bölümün hazırlığı eski bölüm çizilince '
      'silinmez', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    void frame() {
      game.update(1 / 60);
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      rec.endRecording().dispose();
    }

    frame();
    game.debugPrewarm(1);
    final warmed = debugTerrainChunks(levels[1]);
    expect(warmed, isNotNull);
    // Perde sürerken alttaki eski bölüm çizilmeye devam eder.
    for (var i = 0; i < 5; i++) {
      frame();
    }
    expect(identical(debugTerrainChunks(levels[1]), warmed), isTrue);
    expect(debugTerrainChunks(levels[0]), isNotNull);
    // Üçüncü bölüm hazırlanınca en eski (kullanılmayan) bırakılır, oynanan
    // kalır.
    frame();
    game.debugPrewarm(2);
    frame();
    expect(debugTerrainChunks(levels[0]), isNotNull);
    expect(debugTerrainChunks(levels[2]), isNotNull);
    expect(debugTerrainChunks(levels[1]), isNull);
  });
}
