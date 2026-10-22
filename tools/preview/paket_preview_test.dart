// Yeni karşılaşmalar: Yarasa Galerisi kaçış odası ve haznenin ritim yolu.
// `flutter test tools/preview/paket_preview_test.dart` → build/preview/paket_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

Future<void> shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  for (final (name, col, row) in [
    ('paket_kacis', 86, 13),
    ('paket_ritim', 176, 5),
  ]) {
    testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      game.player!.position.setFrom(
        Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
      );
      game.debugCloseUp = 1.3;
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      await shot(game, name);
    });
  }
}
