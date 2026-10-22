// Gerçekçilik taslağı için taban kare: Yerebatan'ın ilk sütun koridoru
// (deneme tonu açık; --dart-define=ESKI=true ile eski görünüm) ve ışıkların ekrandaki yerleri (build/preview/isik*.json).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/lighting.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shafts.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  testWithGame<GolgeGame>('taban', GolgeGame.new, (game) async {
    Cartoon.on = const bool.fromEnvironment('ESKI') ? false : true;
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    final g =
        (game.world.children.whereType<Guard>().toList()
              ..sort((a, b) => a.position.x.compareTo(b.position.x)))
            .first;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(Vector2(28.3 * kTile, g.position.y), Player.w, Player.h),
    );
    game.debugCloseUp = 1.55;
    for (var i = 0; i < 80; i++) {
      game.update(1 / 60);
    }
    g
      ..state = GuardState.patrol
      ..suspicion = 0.3;
    // Ekrandaki yazılar taslakta dikkat dağıtmasın.
    game.narration.resetScene();
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(1280, 720);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File(
      'build/preview/isik_taban${const bool.fromEnvironment('ESKI') ? '_eski' : ''}.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
    Map<String, double> at(Vector2 w) {
      final s = game.camera.localToGlobal(w);
      return {'x': s.x, 'y': s.y};
    }

    // Suyun yüzü: koridorun altındaki ilk su satırı.
    var waterY = 0.0;
    final lv = game.level;
    final c = (p.center.x / kTile).floor();
    for (var r = 0; r < lv.height; r++) {
      if (lv.cell(c, r) == 'w') {
        waterY = r * kTile.toDouble();
        break;
      }
    }
    File(
      'build/preview/isik${const bool.fromEnvironment('ESKI') ? '_eski' : ''}.json',
    ).writeAsStringSync(
      jsonEncode({
        'lantern': at(g.lanternWorld),
        'jar': at(p.center),
        'water': at(Vector2(p.center.x, waterY))['y'],
        'floor': at(Vector2(p.center.x, p.position.y + Player.h))['y'],
      }),
    );
    // Derinlik taslağı için yalnız oyun katmanı: arka plan, karanlık, ışık
    // hüzmeleri, ekran etkileri ve yazılar olmadan (arkası saydam kalır).
    for (final c in game.world.children.toList()) {
      if (c is LightingLayer || c is LightShafts) c.removeFromParent();
    }
    game.effects.removeFromParent();
    game.narration.removeFromParent();
    game.camera.backdrop = Component();
    await game.ready();
    final rec2 = ui.PictureRecorder();
    game.render(ui.Canvas(rec2));
    final img2 = await rec2.endRecording().toImage(1280, 720);
    final png2 = await img2.toByteData(format: ui.ImageByteFormat.png);
    File(
      'build/preview/isik_dunya${const bool.fromEnvironment('ESKI') ? '_eski' : ''}.png',
    ).writeAsBytesSync(png2!.buffer.asUint8List());
    Cartoon.on = false;
  });
}
