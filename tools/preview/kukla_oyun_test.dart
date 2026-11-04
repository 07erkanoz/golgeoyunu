// Yeni Sâye (A1) kuklası oyunda: Yerebatan'ın başında yürür, koşar, zıplar,
// çömelir, zincire tırmanır, sandık iter, kenara tutunur. Oyunun kendi
// görüntüsü, saniyede 60 kare.
// `flutter test tools/preview/kukla_oyun_test.dart --dart-define=CARTOON=true`
// → build/preview/kukla_oyun/%04d.png (ffmpeg ile videoya)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>(
    'kukla oyunda',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 20)),
    (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(960, 540));
      await SayeKukla.load();
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      if (Platform.environment['HARITA'] != null) {
        final l = game.level;
        for (var r = 0; r < 18; r++) {
          final b = StringBuffer();
          for (var c = 0; c < 60; c++) {
            b.write(l.cell(c, r));
          }
          // ignore: avoid_print
          print('${r.toString().padLeft(2)} $b');
        }
        return;
      }
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      // ignore: avoid_print
      print([
        for (final o in game.world.children)
          if (o is Crate || o is Lever) '${o.runtimeType} ${(o as PositionComponent).position / kTile}',
      ]);
      final p = game.player!;
      game.update(1 / 60);
      // ignore: avoid_print
      print('kukla ${p.kuklaOn} hazır ${SayeKukla.ready} ${SayeKukla.lastError} '
          'bölüm ${game.levelIndex} ${p.state} yüzüyor ${p.swimming} '
          'süzülüyor ${p.gliding} ölü ${p.isDead} kayak ${p.skiing}');
      final shoot = Platform.environment['KARE'] != null;
      final dir = Directory('build/preview/kukla_oyun')
        ..createSync(recursive: true);
      if (shoot) {
        for (final f in dir.listSync()) {
          f.deleteSync();
        }
      }
      final k = game.controls.keyboard;
      var frame = 0;
      var t = 0.0;
      Future<void> play(double secs, Set<String> keys) async {
        k
          ..left = keys.contains('left')
          ..right = keys.contains('right')
          ..up = keys.contains('up')
          ..down = keys.contains('down')
          ..jump = keys.contains('jump')
          ..sneak = keys.contains('sneak');
        for (var i = 0; i < (secs * 60).round(); i++) {
          game.update(1 / 60);
          t += 1 / 60;
          if (i % 30 == 0 && !shoot) {
            // ignore: avoid_print
            print('${t.toStringAsFixed(2)} ${(p.position / kTile)} ${p.state} '
                'yer=${p.onGround} v=${p.velocity}');
          }
          if (!shoot) continue;
          game.narration.resetScene();
          // Solda oyunun kendi görüntüsü, sağda Sâye 4 kat yakından.
          final rec = ui.PictureRecorder();
          final c = ui.Canvas(rec);
          game.render(c);
          final vf = game.camera.viewfinder;
          final at = (p.center - vf.position) * vf.zoom + Vector2(480, 270);
          c.save();
          c.clipRect(const ui.Rect.fromLTWH(960, 0, 480, 540));
          c.translate(1200, 330);
          c.scale(4);
          c.translate(-at.x, -at.y);
          game.render(c);
          c.restore();
          c.drawRect(
            const ui.Rect.fromLTWH(959, 0, 2, 540),
            ui.Paint()..color = const ui.Color(0xFF000000),
          );
          final img = await rec.endRecording().toImage(1440, 540);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/${(frame++).toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
      }

      await play(1.2, {});
      // Parmak ucunda yürür, durur; koşar, boşluğa düşer, kenara tutunup
      // çıkar.
      await play(1.4, {'right', 'sneak'});
      await play(0.5, {});
      await play(1.6, {'right'});
      await play(0.25, {'right', 'jump'});
      await play(1.3, {'right'});
      await play(0.3, {});
      // Zincire: tırmanır, iner.
      await play(0.2, {'up', 'jump'});
      await play(1.5, {'up'});
      await play(0.6, {});
      await play(1.3, {'down'});
      await play(0.4, {});
      // Çömelip yürür, koşar, sandığı iter.
      await play(1.3, {'right', 'down'});
      await play(0.4, {});
      await play(1.0, {'right'});
      await play(2.6, {'right'});
      await play(0.4, {});
      // Sandığa, oradan yüksek taşa zıplar, kenarına tutunup çıkar.
      await play(0.3, {'right', 'jump'});
      await play(0.7, {'right'});
      await play(0.3, {'right', 'jump'});
      await play(0.9, {'right'});
      await play(0.9, {'up'});
      await play(1.6, {'right'});
      await play(1.2, {});
    },
  );
}
