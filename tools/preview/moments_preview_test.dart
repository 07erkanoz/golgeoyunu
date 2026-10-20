// Oyun anlarının önizlemesi (gerçek yazı tipiyle): hikâye fısıltısı, ipucu,
// Medusa'nın bakışı, Karabasan'ın gelişi.
// `flutter test tools/preview/moments_preview_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/strings.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  for (final f in [
    'NotoSans-Regular.ttf',
    'NotoSans-Italic.ttf',
    'NotoSans-Light.ttf',
    'NotoSans-LightItalic.ttf',
    'NotoSans-Black.ttf',
  ]) {
    final file = File('/usr/share/fonts/noto/$f');
    if (file.existsSync()) {
      loader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await loader.load();
}

Future<void> _shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void place(GolgeGame game, int col, int row) {
  game.player!.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
}

void run(GolgeGame game, double s) {
  for (var t = 0.0; t < s; t += 1 / 60) {
    game.update(1 / 60);
  }
}

void main() {
  testWithGame<GolgeGame>('anlar', GolgeGame.new, (game) async {
    await _fonts();
    S.lang = Lang.tr;
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;

    // 1) Bölüm başı: hikâye fısıltısı altta, ipucu sol üstte.
    place(game, 4, 13);
    run(game, 2.0);
    await _shot(game, 'an_hikaye_ipucu');

    // 2) Medusa'nın gözleri açık.
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    for (final g in game.world.children.whereType<Guard>().toList()) {
      if (g.position.x > 170 * kTile && g.position.x < 225 * kTile) {
        g.removeFromParent();
      }
    }
    place(game, 195, 13);
    final head = game.world.children.whereType<MedusaHead>().first;
    for (var i = 0; i < 60 * 12 && head.eyes < 1; i++) {
      game.update(1 / 60);
    }
    run(game, 0.6);
    await _shot(game, 'an_medusa');

    // 3) Karabasan geliyor: korku anı.
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    place(game, 268, 9);
    game.controls.keyboard.right = true;
    for (var i = 0; i < 60 * 3; i++) {
      game.update(1 / 60);
      if (game.player!.position.x > 271 * kTile) break;
    }
    game.controls.keyboard.right = false;
    run(game, 0.05);
    await _shot(game, 'an_karabasan_cakma');
    run(game, 0.6);
    await _shot(game, 'an_karabasan');
  });
}
