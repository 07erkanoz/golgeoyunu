// Sâye'nin hareketleri oyundaki çizimiyle (6 kat büyük), saniyede 60 kare: yürüyüş,
// duruş, zıplama, çömelme, zincire tırmanma, sandık itme, kenara tutunma.
// Yerebatan'ın öğretim duraklarında girişle oynatılır.
// `flutter test tools/preview/saye_hareket_video_test.dart --dart-define=CARTOON=true`
// → build/preview/hareket/<klip>/%04d.png (ffmpeg ile videoya)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

/// Bir klibin adımı: [t] saniye boyunca bu tuşlar basılı.
typedef Step = (double t, Set<String> keys);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const clips = <(String, int, int, List<Step>)>[
    ('yuruyus', 2, 13, [
      (0.6, {}),
      (2.4, {'right'}),
      (0.8, {}),
    ]),
    ('ziplama', 9, 13, [
      (0.3, {}),
      (0.5, {'right'}),
      (0.25, {'right', 'jump'}),
      (1.2, {'right'}),
      (0.6, {}),
      (0.25, {'jump'}),
      (1.0, {}),
    ]),
    ('comelme', 4, 13, [
      (0.5, {}),
      (0.9, {'down'}),
      (1.2, {'down', 'right'}),
      (0.6, {}),
    ]),
    ('tirmanma', 15, 13, [
      (0.3, {}),
      (0.4, {'right'}),
      (2.2, {'up'}),
      (0.6, {}),
    ]),
    ('itme', 23, 13, [
      (0.4, {}),
      (2.8, {'right'}),
      (0.6, {}),
    ]),
    ('tutunma', 29, 13, [
      (0.4, {}),
      (0.6, {'right'}),
      (0.3, {'right', 'jump'}),
      (1.0, {'right'}),
      (1.2, {'up'}),
      (0.8, {}),
    ]),
  ];
  for (final (name, col, row, steps) in clips) {
    testWithGame<GolgeGame>('hareket $name', GolgeGame.new, (game) async {
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      final p = game.player!;
      void place() {
        p.position.setFrom(
          Level.standOn(
            Vector2(col * kTile.toDouble(), row * kTile.toDouble()),
            Player.w,
            Player.h,
          ),
        );
        p.velocity.setZero();
      }

      place();
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
      }
      final dir = Directory('build/preview/hareket/$name')
        ..createSync(recursive: true);
      for (final f in dir.listSync()) {
        f.deleteSync();
      }
      final k = game.controls.keyboard;
      final y0 = p.position.y;
      var frame = 0;
      for (final (t, keys) in steps) {
        k
          ..left = keys.contains('left')
          ..right = keys.contains('right')
          ..up = keys.contains('up')
          ..down = keys.contains('down')
          ..jump = keys.contains('jump');
        for (var i = 0; i < (t * 60).round(); i++) {
          game.update(1 / 60);
          // Yalnız Sâye, 6 kat büyük; zeminde dünyayla kayan çentikler
          // (ayak kayıyor mu görünsün).
          final rec = ui.PictureRecorder();
          final c = ui.Canvas(rec);
          const sc = 6.0;
          c.drawRect(
            const ui.Rect.fromLTWH(0, 0, 480, 400),
            ui.Paint()..color = const ui.Color(0xFFC89A5A),
          );
          final groundY = 300.0;
          final tick = ui.Paint()
            ..color = const ui.Color(0xFF5A3A20)
            ..strokeWidth = 2;
          c.drawLine(ui.Offset(0, groundY), ui.Offset(480, groundY), tick);
          final px = p.position.x;
          for (var x = -((px * sc) % 48); x < 480; x += 48) {
            c.drawLine(
              ui.Offset(x, groundY),
              ui.Offset(x, groundY + 14),
              tick,
            );
          }
          c.save();
          c.translate(
            240 - Player.w / 2 * sc,
            groundY - Player.h * sc + (p.position.y - y0) * sc,
          );
          c.scale(sc);
          p.render(c);
          c.restore();
          final img = await rec.endRecording().toImage(480, 400);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/${(frame++).toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
