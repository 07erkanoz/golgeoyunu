// Bölümdeki küçük Karagöz perdesi, gerçek tasvirlerle (oyun içinde).
// `flutter test tools/preview/karagoz_sahne_test.dart --dart-define=CARTOON=true`
// → build/preview/karagoz_sahne_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/joy.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/tasvir_images.dart';

import 'yazi_tipi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>('Karagöz perdesi', GolgeGame.new, (game) async {
    await TasvirImages.load();
    game.onGameResize(Vector2(960, 540));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    // Bölüm girişi (düşüş) bitsin; yoksa Sâye başlangıca geri konur.
    for (var i = 0; i < 240; i++) {
      game.update(1 / 60);
    }
    // Kandilciler önizlemede yok (Sâye'yi görüp başa döndürmesin).
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final k = game.world.children.whereType<KaragozSahne>().first;
    final p = game.player!;
    final at = k.absolutePosition;
    p.position.setFrom(
      Level.standOn(
        Vector2(
          ((at.x / kTile).floor() - 2) * kTile.toDouble(),
          ((at.y / kTile).round() - 1) * kTile.toDouble(),
        ),
        Player.w,
        Player.h,
      ),
    );

    p.velocity.setZero();
    game.debugSnapCamera();
    var n = 0;
    for (var s = 0; s < 12; s++) {
      for (var i = 0; i < 40; i++) {
        game.update(1 / 60);
      }
      if (s % 3 != 2) continue;
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(960, 540);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/karagoz_sahne_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
