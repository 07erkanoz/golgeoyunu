// Görsel gözden geçirme galerisi: her bölümün başı ve karakter yakın
// çekimleri. `flutter test tools/preview/gallery_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/shadow_art.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/settings.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  for (final f in [
    'NotoSans-Regular.ttf',
    'NotoSans-Italic.ttf',
    'NotoSans-Light.ttf',
    'NotoSans-LightItalic.ttf',
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
  Directory('build/gallery').createSync(recursive: true);
  File('build/gallery/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const shots = String.fromEnvironment('SHOTS');
  testWithGame<GolgeGame>('galeri', GolgeGame.new, (game) async {
    await _fonts();
    await NemrutImages.load();
    await ShadowArt.load();
    // ignore: avoid_print
    print('nemrut görselleri: ${NemrutImages.ready} ${NemrutImages.lastError}');
    S.lang = Lang.tr;
    Settings.brightness = double.parse(
      const String.fromEnvironment('BRIGHT', defaultValue: '1'),
    );
    Settings.lowGraphics = const bool.fromEnvironment('LOW');
    game.onGameResize(Vector2(1280, 720));
    // ad:bölüm:sütun:satır:yakınlık:saniye[:korku]
    for (final spec in shots.split(',')) {
      final p = spec.split(':');
      game.debugLoadLevel(int.parse(p[1]));
      await game.ready();
      game.cinematic = false;
      if (const bool.fromEnvironment('NOGUARD')) {
        for (final g in game.world.children.whereType<Guard>().toList()) {
          g.removeFromParent();
        }
      }
      final ski = game.skiSurface;
      if (p[2] != '-' && ski != null) {
        // Kayak: kar yüzeyine konur.
        final x = int.parse(p[2]) * kTile + kTile / 2;
        game.player!.position.setValues(
          x - Player.w / 2,
          (ski.at(x) ?? 0) - Player.h,
        );
      } else if (p[2] != '-') {
        game.player!.position.setFrom(
          Level.standOn(
            Vector2(int.parse(p[2]) * kTile, int.parse(p[3]) * kTile),
            Player.w,
            Player.h,
          ),
        );
      }
      game.debugCloseUp = double.parse(p[4]);
      if (p.length > 6) game.scare(double.parse(p[6]), sting: false);
      game.controls.keyboard.down = const bool.fromEnvironment('CROUCH');
      for (var t = 0.0; t < double.parse(p[5]); t += 1 / 60) {
        game.update(1 / 60);
      }
      // İsteğe bağlı kamera kaydırma (karo): PANX/PANY.
      game.camera.viewfinder.position += Vector2(
        double.parse(const String.fromEnvironment('PANX', defaultValue: '0')),
        double.parse(const String.fromEnvironment('PANY', defaultValue: '0')),
      )..scale(kTile);
      await _shot(game, p[0]);
      game.debugCloseUp = 1;
    }
  });
}
