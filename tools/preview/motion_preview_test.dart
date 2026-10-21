// Hareket şeridi: bir karakterin koşu, duruş, dönüş ve zıplamasını kare kare
// tek görüntüde gösterir. Ayağın yerde kayıp kaymadığı, poz geçişleri ve
// kavanozun salınımı buradan gözden geçirilir.
//
//   flutter test tools/preview/motion_preview_test.dart
//   (çıktı: build/gallery/motion.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/settings.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  for (final f in ['NotoSans-Regular.ttf']) {
    final file = File('/usr/share/fonts/noto/$f');
    if (file.existsSync()) {
      loader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await loader.load();
}

const _floor = [
  '##################################################',
  '#................................................#',
  '#................................................#',
  '#................................................#',
  '#................................................#',
  '#................................................#',
  '#.................P..............................#',
  '##################################################',
  '##################################################',
];

void main() {
  testWithGame<GolgeGame>('hareket şeridi', GolgeGame.new, (game) async {
    await _fonts();
    Settings.lowGraphics = false;
    GolgeGame.debugLevels = [
      const LevelDef(
        title: 'HAREKET',
        subtitle: '',
        theme: LevelTheme.cistern,
        map: _floor,
      ),
    ];
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    final keys = game.controls.keyboard;

    final zoom = double.parse(
      const String.fromEnvironment('ZOOM', defaultValue: '3'),
    );
    final cell = zoom > 4 ? 300.0 : 150.0;
    const cols = 8;
    final frames = <(ui.Image, String)>[];

    // Yalnızca Sâye, büyütülmüş; zeminde dünyaya çakılı işaretler: yerdeki
    // ayak bu işaretlere göre kıpırdamamalı.
    final ground = game.player!.position.y + 28;
    Future<void> snap(String label) async {
      final p = game.player!;
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
        ui.Rect.fromLTWH(0, 0, cell, cell),
        ui.Paint()..color = const ui.Color(0xFF2A1A12),
      );
      c.translate(cell / 2, cell * 0.86);
      c.scale(zoom);
      final feet = ground;
      final cx = p.position.x + 8;
      c.translate(-cx, -feet);
      final tick = ui.Paint()
        ..color = const ui.Color(0xFF8A6A4A)
        ..strokeWidth = 0.3;
      c.drawLine(ui.Offset(cx - 40, feet), ui.Offset(cx + 40, feet), tick);
      for (var x = (cx / 4).floor() * 4.0 - 40; x < cx + 40; x += 4) {
        c.drawLine(ui.Offset(x, feet), ui.Offset(x, feet + 1.5), tick);
      }
      p.renderTree(c);
      final img = await rec.endRecording().toImage(cell.toInt(), cell.toInt());
      frames.add((img, label));
    }

    void play(double s) {
      for (var t = 0.0; t < s - 1e-9; t += 1 / 60) {
        game.update(1 / 60);
      }
    }

    play(0.6);
    await snap('dur');
    keys.right = true;
    for (var i = 0; i < 11; i++) {
      play(0.05);
      await snap('koş ${(i + 1) * 50}ms');
    }
    keys.right = false;
    for (var i = 0; i < 4; i++) {
      play(0.06);
      await snap('fren');
    }
    keys.left = true;
    for (var i = 0; i < 4; i++) {
      play(0.05);
      await snap('dönüş');
    }
    keys.jump = true;
    for (var i = 0; i < 8; i++) {
      play(0.08);
      if (i == 1) keys.jump = false;
      await snap(i < 3 ? 'kalkış' : 'hava');
    }
    keys.left = false;
    for (var i = 0; i < 4; i++) {
      play(0.07);
      await snap('iniş');
    }
    GolgeGame.debugLevels = null;

    // Her kareden oyuncunun çevresi kırpılır (kamera onu ortada tutar).
    final rows = (frames.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      ui.Rect.fromLTWH(0, 0, cell * cols, 4000),
      ui.Paint()..color = const ui.Color(0xFF000000),
    );
    for (var i = 0; i < frames.length; i++) {
      final (img, label) = frames[i];
      final dst = ui.Rect.fromLTWH(
        (i % cols) * cell,
        (i ~/ cols) * cell,
        cell,
        cell,
      );
      c.drawImage(img, dst.topLeft, ui.Paint());
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(fontSize: 11, fontFamily: 'Roboto'),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFE0D0B0)))
            ..addText('${i + 1} $label');
      final para = pb.build()..layout(ui.ParagraphConstraints(width: cell));
      c.drawParagraph(para, dst.topLeft.translate(4, 3));
    }
    final out = await rec.endRecording().toImage(
      (cell * cols).toInt(),
      (cell * rows).toInt(),
    );
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/motion.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
