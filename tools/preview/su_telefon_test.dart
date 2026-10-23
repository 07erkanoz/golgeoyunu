// Telefon ekranında Yerebatan'ın suyu: yolun kenarında su yüzeyi görünür mü?
// `flutter test tools/preview/su_telefon_test.dart` → build/preview/su_<sütun>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/realism.dart';
import 'package:golge/game/player.dart';

void main() {
  for (final col in [12, 44, 97]) {
    testWithGame<GolgeGame>('su $col', GolgeGame.new, (game) async {
      // 2000×900 telefon ekranı (yoğunluk ≈ 2.3).
      // Cihazdaki gibi: renk ve doku, ışık ve derinlik açık, ton 35.
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(870, 391));
      game.debugLoadLevel(0);
      await game.ready();
      final p = game.player!;
      // Yürüme yolu: üst duvarın altındaki ilk boşluktan aşağı, ilk zemin.
      var row = 2;
      while (game.level.solid(col, row)) {
        row++;
      }
      while (row < game.level.height - 1 &&
          !(game.level.solid(col, row + 1) ||
              game.level.cell(col, row + 1) == '=')) {
        row++;
      }
      p.position.setFrom(
        Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
      );
      for (var i = 0; i < 240; i++) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/su_$col.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}
