// Işık ve derinlik denemesi oyunun içinde: Yerebatan ilk koridoru, eski ve
// deneme görünümünde, kapalı/açık. `flutter test tools/preview/isik_oyunda_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final cartoon in [false, true]) {
    for (final real in [false, true]) {
      final name =
          'oyunda_${cartoon ? 'deneme' : 'eski'}_${real ? 'isik' : 'yok'}';
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        Cartoon.on = cartoon;
        Realism.on = real;
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(0);
        await game.ready();
        game.cinematic = false;
        final g =
            (game.world.children.whereType<Guard>().toList()
                  ..sort((a, b) => a.position.x.compareTo(b.position.x)))
                .first;
        game.player!.position.setFrom(
          Level.standOn(
            Vector2(28.3 * kTile, g.position.y),
            Player.w,
            Player.h,
          ),
        );
        game.debugCloseUp = 1.55;
        for (var i = 0; i < 80; i++) {
          game.update(1 / 60);
        }
        g
          ..state = GuardState.patrol
          ..suspicion = 0.3;
        game.narration.resetScene();
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(1280, 720);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        Cartoon.on = false;
        Realism.on = false;
      });
    }
  }
}
