// Taş dev, doku denemesi kapalı ve açık: devin önünde Sâye.
// `flutter test tools/preview/tas_dev_doku_test.dart` →
// build/preview/tas_dev_<bölüm>_<isik|doku>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/nemrut.dart';
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
  for (final lv in [6, 7]) {
    for (final (tag, cartoon) in [('isik', false), ('doku', true)]) {
      final name = 'tas_dev_${lv}_$tag';
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        Cartoon.on = cartoon;
        Realism.on = true;
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(lv);
        await game.ready();
        game.cinematic = false;
        final giants = game.world.children.whereType<StoneGiant>().toList();
        if (giants.isEmpty) {
          // ignore: avoid_print
          print('${levels[lv].title}: taş dev yok');
          return;
        }
        final g = giants.first;
        game.player!.position.setFrom(
          Level.standOn(
            Vector2(g.position.x - 9 * kTile, g.position.y - 2 * kTile),
            Player.w,
            Player.h,
          ),
        );
        for (var i = 0; i < 90; i++) {
          game.update(1 / 60);
        }
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
