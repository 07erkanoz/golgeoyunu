// Gün Katı: kanat çırpan Hüma, net gölgesi, güneşte yanan Sâye'nin dumanı.
// `flutter test tools/preview/huma_test.dart` → build/preview/huma/kare_NNN.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/heavens.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  testWithGame<GolgeGame>(
    'huma',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 4)),
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(16);
      await game.ready();
      game.cinematic = false;
      final z = game.world.children.whereType<ScorchZone>().first;
      final p = game.player!;
      // Girişin hemen yanında: kuş uyanır.
      p.position.setFrom(
        Level.standOn(
          Vector2(z.area.left + 3 * kTile, z.area.bottom - 2 * kTile),
          Player.w,
          Player.h,
        ),
      );
      for (var i = 0; i < 30; i++) {
        game.update(1 / 60);
      }
      final dir = Directory('build/preview/huma');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      var f = 0;
      for (var i = 0; i < 48; i++) {
        // Sâye kuşun gölgesinde onunla yürür; son yarıda gölgeden çıkar.
        final inside = i < 28;
        final x = inside ? z.birdX : z.birdX + 4 * kTile;
        p.position.x = x - Player.w / 2;
        for (var k = 0; k < 6; k++) {
          game.update(1 / 60);
        }
        game.narration.resetScene();
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        final img = await rec.endRecording().toImage(1280, 720);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/kare_${(f++).toString().padLeft(3, '0')}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        if (p.isDead) break;
      }
    },
  );
}
