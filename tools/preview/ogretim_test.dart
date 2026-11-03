// Yerebatan öğretim alanı: her durakta kendiliğinden beliren levha.
// `flutter test tools/preview/ogretim_test.dart --dart-define=CARTOON=true`
// → build/preview/ogretim_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/lesson.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/strings.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  const stops = [
    ('move', 3, 13),
    ('pickup', 7, 13),
    ('jump', 12, 13),
    ('climb', 16, 13),
    ('umay', 20, 6),
    ('crate', 26, 13),
    ('ledge', 32, 13),
    ('lever', 49, 13),
    ('hide', 66, 13),
    ('throw', 106, 13),
    ('help', 127, 13),
  ];
  for (final (i, (key, c, r)) in stops.indexed) {
    testWithGame<GolgeGame>('ders $key', GolgeGame.new, (game) async {
      // Klavyeli bilgisayar; DOKUNMATIK=1 ile telefon düğmeleri.
      debugDefaultTargetPlatformOverride =
          Platform.environment['DOKUNMATIK'] == '1'
          ? TargetPlatform.android
          : TargetPlatform.linux;
      if (Platform.environment['DIL'] == 'en') S.lang = Lang.en;
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
      game.debugSnapCamera();
      for (var k = 0; k < 90; k++) {
        game.update(1 / 60);
      }
      final signs = game.world.children.whereType<LessonSigns>().single;
      expect(signs.activeKey, key);
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(960, 540);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/preview/ogretim_${Platform.environment['DIL'] ?? 'tr'}_${(i + 1).toString().padLeft(2, '0')}.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
      debugDefaultTargetPlatformOverride = null;
      S.lang = Lang.tr;
    });
  }
}
