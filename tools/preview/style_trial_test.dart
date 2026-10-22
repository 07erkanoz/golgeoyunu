// Görsel yön denemesi: aynı Yerebatan karesi bugünkü ve karikatürize
// görünümle, oyun kamerasında ve yakın planda: build/preview/stil_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

Future<void> shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void step(GolgeGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
  }
}

Future<void> loadFont() async {
  final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
      .readAsBytesSync();
  final loader = FontLoader('Roboto')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(loadFont);
  for (final cartoon in [false, true]) {
    testWithGame<GolgeGame>(
      'stil ${cartoon ? 'yeni' : 'eski'}',
      GolgeGame.new,
      (game) async {
        Cartoon.on = cartoon;
        Directory('build/preview').createSync(recursive: true);
        game.onGameResize(Vector2(1280, 720));
        game.debugLoadLevel(0);
        await game.ready();
        game.cinematic = false;
        final p = game.player!;
        final g = game.world.children.whereType<Guard>().first;
        p.position.setFrom(
          Level.standOn(
            Vector2(g.position.x - 6 * kTile, g.position.y),
            Player.w,
            Player.h,
          ),
        );
        step(game, 1.0);
        g
          ..state = GuardState.patrol
          ..suspicion = 0.4;
        final tag = cartoon ? 'yeni' : 'eski';
        await shot(game, 'stil_${tag}_oyun');
        game.debugCloseUp = 2.6;
        step(game, 1.2);
        g
          ..state = GuardState.patrol
          ..suspicion = 0.4;
        await shot(game, 'stil_${tag}_yakin');
        Cartoon.on = false;
      },
    );
  }
  // Sâye'nin yeni görünüşü başka bir bölümde (Kar Yolu).
  testWithGame<GolgeGame>('stil kar yolu', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(8);
    await game.ready();
    game.cinematic = false;
    game.debugCloseUp = 2.6;
    step(game, 1.5);
    await shot(game, 'stil_saye_karyolu');
  });
}
