// Sâye'nin oyundaki hareketleri, kamera onu izler (5 kat büyük, saniyede 30
// kare): koşu, yürüyüş, zıplama, kenara tutunup çıkma, yüzme, çömelip
// yürüme, kanatla süzülme. Yerebatan'da girişle oynatılır; zemin, iskele
// ve su çizilir (ayak kayıyor mu, eller kenarı tutuyor mu görünsün).
// `flutter test tools/preview/saye_hareket2_test.dart --dart-define=CARTOON=true`
// → build/preview/hareket2/<klip>/%04d.png (KLIP=ad yalnız birini çeker)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/deniz.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/erlik.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

/// Bir klibin adımı: [t] saniye boyunca bu tuşlar basılı.
typedef Step = (double t, Set<String> keys);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const clips = <(String, double, double, List<Step>)>[
    ('kosu', 2, 13, [
      (0.4, {}),
      (2.0, {'right'}),
      (0.7, {}),
    ]),
    ('yuruyus', 2, 13, [
      (0.4, {}),
      (2.4, {'right', 'sneak'}),
      (0.6, {}),
    ]),
    ('ziplama', 2, 13, [
      (0.3, {}),
      (0.4, {'right'}),
      (0.3, {'right', 'jump'}),
      (0.9, {'right'}),
      (0.5, {}),
      (0.3, {'jump'}),
      (1.0, {}),
    ]),
    ('tutunma', 31, 13, [
      (0.3, {}),
      (0.9, {'right'}),
      (0.35, {'right', 'jump'}),
      (1.0, {'right'}),
      (1.2, {'up'}),
      (0.8, {}),
    ]),
    ('comelme', 2, 13, [
      (0.4, {}),
      (0.8, {'down'}),
      (1.6, {'down', 'right'}),
      (0.6, {}),
    ]),
    ('yuzme', 270, 22, [
      (0.6, {}),
      (2.4, {'right'}),
      (0.8, {}),
    ]),
    ('suzulme', 36, 10, [
      (0.3, {}),
      (0.5, {'right'}),
      (0.25, {'right', 'jump'}),
      (0.6, {'right'}),
      (1.6, {'right', 'jump'}),
      (0.8, {}),
    ]),
  ];
  final only = Platform.environment['KLIP'];
  for (final (name, col, row, steps) in clips) {
    if (only != null && only != name) continue;
    testWithGame<GolgeGame>('hareket $name', GolgeGame.new, (game) async {
      game.onGameResize(Vector2(960, 540));
      await SayeKukla.load();
      // Yüzüş Ak Ana'nın Denizi'nde (20), ötekiler Yerebatan'da.
      game.debugLoadLevel(name == 'yuzme' ? 20 : 0);
      await game.ready();
      game.cinematic = false;
      SayeKukla.debugLimbs = Platform.environment['RENKLI'] != null;
      if (name == 'suzulme') game.wingsCollected = true;
      for (final g in game.world.children.toList()) {
        if (g is Guard ||
            g is AnglerHunter ||
            g is StingingJelly ||
            g is LanternBoat ||
            g is Kormos ||
            g is SeaCurrent) {
          g.removeFromParent();
        }
      }
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2(col * kTile, row * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      if (name == 'yuzme') {
        p.position.setValues(
          (col + 0.5) * kTile - Player.w / 2,
          (row + 0.5) * kTile - Player.h / 2,
        );
      }
      p.velocity.setZero();
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      final dir = Directory('build/preview/hareket2/$name')
        ..createSync(recursive: true);
      for (final f in dir.listSync()) {
        f.deleteSync();
      }
      final k = game.controls.keyboard;
      final lv = game.level;
      var frame = 0;
      var tick = 0;
      for (final (t, keys) in steps) {
        k
          ..left = keys.contains('left')
          ..right = keys.contains('right')
          ..up = keys.contains('up')
          ..down = keys.contains('down')
          ..sneak = keys.contains('sneak')
          ..jump = keys.contains('jump');
        for (var i = 0; i < (t * 60).round(); i++) {
          game.update(1 / 60);
          if (tick++ % 2 == 1) continue;
          const sc = 5.0, vw = 480.0, vh = 400.0;
          final cx = p.position.x + Player.w / 2;
          final cy = p.position.y + Player.h / 2;
          final rec = ui.PictureRecorder();
          final c = ui.Canvas(rec);
          c.drawRect(
            const ui.Rect.fromLTWH(0, 0, vw, vh),
            ui.Paint()..color = const ui.Color(0xFFC89A5A),
          );
          c.save();
          c.translate(vw / 2 - cx * sc, vh / 2 + 30 - cy * sc);
          c.scale(sc);
          // Su ve taşlar (hücreler), zeminde 4 birimde bir çentik.
          final water = ui.Paint()..color = const ui.Color(0x553A6A80);
          final stone = ui.Paint()..color = const ui.Color(0xFF6A4A2A);
          final plank = ui.Paint()..color = const ui.Color(0xFF8A5A30);
          final notch = ui.Paint()
            ..color = const ui.Color(0xFF3A2410)
            ..strokeWidth = 0.3;
          final c0 = (cx / kTile).floor() - 4, r0 = (cy / kTile).floor() - 4;
          for (var r = r0; r <= r0 + 8; r++) {
            for (var cc = c0; cc <= c0 + 8; cc++) {
              final x = cc * kTile.toDouble(), y = r * kTile.toDouble();
              if (lv.inWater(x + kTile / 2, y + kTile / 2)) {
                c.drawRect(ui.Rect.fromLTWH(x, y, kTile * 1.0, kTile * 1.0),
                    water);
              }
              final cell = lv.cell(cc, r);
              if (cell == '#') {
                c.drawRect(ui.Rect.fromLTWH(x, y, kTile * 1.0, kTile * 1.0),
                    stone);
              } else if (cell == '=') {
                c.drawRect(ui.Rect.fromLTWH(x, y, kTile * 1.0, 3), plank);
              }
              if (cell == '#' || cell == '=') {
                for (var n = 0; n < kTile; n += 4) {
                  c.drawLine(ui.Offset(x + n, y), ui.Offset(x + n, y + 2),
                      notch);
                }
              }
            }
          }
          c.translate(p.position.x, p.position.y);
          p.render(c);
          c.restore();
          final img = await rec.endRecording().toImage(vw.toInt(), vh.toInt());
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/${(frame++).toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
