// Kandilci hareket şeridi: devriye, dönüş, şüphe ve kovalama.
//   flutter test tools/preview/guard_preview_test.dart  (build/gallery/guard.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';

const _floor = [
  '############################################################',
  '#..........................................................#',
  '#..........................................................#',
  '#..........................................................#',
  '#..........................................................#',
  '#P.........................................................#',
  '############################################################',
  '############################################################',
];

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  final file = File('/usr/share/fonts/noto/NotoSans-Regular.ttf');
  if (file.existsSync()) {
    loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
  }
  await loader.load();
}

void main() {
  testWithGame<GolgeGame>('Kandilci şeridi', GolgeGame.new, (game) async {
    await _fonts();
    GolgeGame.debugLevels = [
      const LevelDef(
        title: 'K',
        subtitle: '',
        theme: LevelTheme.cistern,
        map: _floor,
      ),
    ];
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    p.hidden = true;
    final g = Guard(Vector2(30 * kTile, 5 * kTile));
    game.world.add(g);
    game.update(1 / 60);
    final ground = g.position.y + Guard.gh;

    const cell = 200.0;
    const zoom = 3.0;
    final frames = <(ui.Image, String)>[];
    Future<void> snap(String label) async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
        const ui.Rect.fromLTWH(0, 0, cell, cell),
        ui.Paint()..color = const ui.Color(0xFF1E1612),
      );
      c.translate(cell / 2, cell * 0.9);
      c.scale(zoom);
      final cx = g.position.x + Guard.gw / 2;
      c.translate(-cx, -ground);
      final tick = ui.Paint()
        ..color = const ui.Color(0xFF8A6A4A)
        ..strokeWidth = 0.3;
      c.drawLine(ui.Offset(cx - 40, ground), ui.Offset(cx + 40, ground), tick);
      for (var x = (cx / 4).floor() * 4.0 - 40; x < cx + 40; x += 4) {
        c.drawLine(ui.Offset(x, ground), ui.Offset(x, ground + 1.5), tick);
      }
      g.renderTree(c);
      final img = await rec.endRecording().toImage(cell.toInt(), cell.toInt());
      frames.add((img, label));
    }

    void play(double s) {
      for (var t = 0.0; t < s - 1e-9; t += 1 / 60) {
        game.update(1 / 60);
      }
    }

    for (var i = 0; i < 8; i++) {
      play(0.12);
      await snap('devriye');
    }
    // Arkasında bir ses: döner, bakar.
    g.hear(Vector2(g.center.x + 200 * -g.facing, g.center.y), 400);
    for (var i = 0; i < 6; i++) {
      play(0.07);
      await snap('ses');
    }
    // Görür ve kovalar.
    p.hidden = false;
    p.position.setValues(g.position.x + g.facing * 160, g.position.y + 22);
    for (var i = 0; i < 10; i++) {
      play(0.1);
      if (g.state == GuardState.chase) {
        // Oyuncu hep önde kalsın.
        p.position.x = g.position.x + g.facing * 150;
      }
      await snap(g.state.name);
    }
    GolgeGame.debugLevels = null;

    const cols = 8;
    final rows = (frames.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    for (var i = 0; i < frames.length; i++) {
      final (img, label) = frames[i];
      final o = ui.Offset((i % cols) * cell, (i ~/ cols) * cell);
      c.drawImage(img, o, ui.Paint());
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(fontSize: 12, fontFamily: 'Roboto'),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFE0D0B0)))
            ..addText('${i + 1} $label');
      final para = pb.build()
        ..layout(const ui.ParagraphConstraints(width: cell));
      c.drawParagraph(para, o.translate(4, 3));
    }
    final out = await rec.endRecording().toImage(
      (cell * cols).toInt(),
      (cell * rows).toInt(),
    );
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/guard.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
