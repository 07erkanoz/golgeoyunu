// Ötüken'de anlatımın sırası: bölüm başından yürüyünce ekrana ne geliyor.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/otuken.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('anlatım', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(17);
    await game.ready();
    final p = game.player!;
    var seen = 0;
    for (var i = 0; i < 60 * 70; i++) {
      final k = game.controls.keyboard;
      // Işıkta yürü; huzme sönükse bekle (kabaca).
      k.right = !game.cinematic && i % 240 < 200;
      k.jump = p.onGround && i % 50 == 0;
      game.update(1 / 60);
      final g = game.world.children.whereType<GladeZone>();
      if (p.isDead) {
        // ignore: avoid_print
        print('ÖLDÜ x=${(p.position.x / 32).toStringAsFixed(1)}');
      }
      while (seen < game.narration.recent.length) {
        final r = game.narration.recent[seen++];
        // ignore: avoid_print
        print(
          '${(i / 60).toStringAsFixed(1)}s x=${(p.position.x / 32).toStringAsFixed(0)} ${r.kind.name}: ${r.text.split('\n').first}',
        );
      }
      if (g.isEmpty) break;
    }
  });
}
