import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/cistern_water.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWithGame<GolgeGame>(
    'tavandan düşen damla havuzda halka bırakır',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(0);
      await game.ready();
      final p = game.player!;
      p.position.setValues(26 * kTile, 12 * kTile);
      game.debugSnapCamera();
      final drips = game.world.children.whereType<CisternDrips>().single;

      // İlk tahta yolun altındaki sabit su. Yalnız damla katmanını çiziyoruz:
      // dar şeritte görülen piksel bir temas halkasına ait olmalı.
      const column = 22;
      final row = Iterable<int>.generate(game.level.height)
          .firstWhere((row) => game.level.cell(column, row) == 'w');
      final pool = ui.Rect.fromLTRB(
        column * kTile,
        row * kTile + 3,
        (column + 1) * kTile,
        row * kTile + 14,
      );
      var ring = false;
      for (var i = 0; i < 150 && !ring; i++) {
        drips.update(1 / 24);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..translate(-pool.left, -pool.top);
        drips.render(canvas);
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          pool.width.toInt(),
          pool.height.toInt(),
        );
        final bytes = await image.toByteData();
        image.dispose();
        picture.dispose();
        final rgba = bytes!.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
        for (var offset = 3; offset < rgba.length; offset += 4) {
          if (rgba[offset] == 0) continue;
          ring = true;
          break;
        }
      }
      expect(ring, isTrue);

      for (final name in ['drip_1.wav', 'drip_2.wav']) {
        final audio = await rootBundle.load('assets/audio/$name');
        expect(audio.lengthInBytes, greaterThan(1000));
      }
    },
  );
}
