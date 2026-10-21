// Tek bir figürü (Medusa, taş dev, kurt, kuş...) büyütüp zaman içinde kare
// kare gösterir.
//   flutter test tools/preview/figure_preview_test.dart --dart-define=FIG=medusa
//   (çıktı: build/gallery/fig_<FIG>.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/winter.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  final file = File('/usr/share/fonts/noto/NotoSans-Regular.ttf');
  if (file.existsSync()) {
    loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
  }
  await loader.load();
}

/// Figür, haritası, kadraj (dünya merkezi ve genişliği), kare aralığı ve
/// her karede yapılacak etki.
class _Spec {
  const _Spec(this.map, this.theme, this.find, this.view, this.step,
      {this.count = 16, this.act});
  final List<String> map;
  final LevelTheme theme;
  final PositionComponent Function(GolgeGame) find;
  final double view;
  final double step;
  final int count;
  final void Function(GolgeGame, int frame)? act;
}

final _specs = <String, _Spec>{
  'medusa': _Spec(
    const [
      '##############################',
      '#............................#',
      '#............................#',
      '#............................#',
      '#............................#',
      '#............................#',
      '#..............U.............#',
      '#............................#',
      '#P...........................#',
      '##############################',
    ],
    LevelTheme.cistern,
    (g) => g.world.children.whereType<MedusaHead>().first,
    110,
    0.45,
    act: (g, i) {
      // Oyuncu kıpırdamadan saklı durur (taşa dönüp bölüm yeniden kurulmasın).
      g.player!.hidden = true;
      if (i == 14) g.world.children.whereType<MedusaHead>().first.sealed = true;
    },
  ),
  'giant': _Spec(
    const [
      '########################################',
      '#......................................#',
      '#......................................#',
      '#......................................#',
      '#......................................#',
      '#......................................#',
      '#......................................#',
      '#......................................#',
      '#......................................#',
      '#...........`..........................#',
      '#P.....................................#',
      '########################################',
    ],
    LevelTheme.nemrut,
    (g) => g.world.children.whereType<StoneGiant>().first,
    330,
    0.3,
    count: 32,
    act: (g, i) {
      if (i == 8 || i == 17 || i == 26) {
        final giant = g.world.children.whereType<StoneGiant>().first;
        g.fireflies = 3;
        g.releaseFirefly(giant.ear, 1);
      }
    },
  ),
  'wolf': _Spec(
    const [
      '##################################################',
      '#................................................#',
      '#................................................#',
      '#................................................#',
      '#P.......................b.......................#',
      '##################################################',
    ],
    LevelTheme.snow,
    (g) => g.world.children.whereType<Wolf>().first,
    150,
    0.12,
    act: (g, i) {
      if (i == 6) {
        final w = g.world.children.whereType<Wolf>().first;
        g.player!.position.setValues(w.position.x - 160, w.position.y - 8);
      }
    },
  ),
};

void main() {
  const fig = String.fromEnvironment('FIG', defaultValue: 'medusa');
  testWithGame<GolgeGame>('figür: $fig', GolgeGame.new, (game) async {
    await _fonts();
    final spec = _specs[fig]!;
    GolgeGame.debugLevels = [
      LevelDef(title: 'F', subtitle: '', theme: spec.theme, map: spec.map),
    ];
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    // Oyuncu köşede saklı ve kıpırtısız: figür kendi hâlinde oynar.
    game.player!.hidden = fig != 'wolf';
    game.update(1 / 60);
    final target = spec.find(game);
    final anchor = target.absoluteCenter.clone();

    const cell = 240.0;
    final frames = <ui.Image>[];
    for (var i = 0; i < spec.count; i++) {
      spec.act?.call(game, i);
      for (var t = 0.0; t < spec.step - 1e-9; t += 1 / 60) {
        game.update(1 / 60);
      }
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
        const ui.Rect.fromLTWH(0, 0, cell, cell),
        ui.Paint()..color = const ui.Color(0xFF1E1612),
      );
      c.translate(cell / 2, cell / 2);
      c.scale(cell / spec.view);
      c.translate(-anchor.x, -anchor.y);
      for (final comp in game.world.children.toList()
        ..sort((a, b) => a.priority.compareTo(b.priority))) {
        if (comp is PositionComponent) comp.renderTree(c);
      }
      frames.add(await rec.endRecording().toImage(cell.toInt(), cell.toInt()));
    }
    GolgeGame.debugLevels = null;

    const cols = 8;
    final rows = (frames.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    for (var i = 0; i < frames.length; i++) {
      final o = ui.Offset((i % cols) * cell, (i ~/ cols) * cell);
      c.drawImage(frames[i], o, ui.Paint());
      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 12, fontFamily: 'Roboto'),
      )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFE0D0B0)))
        ..addText('${i + 1} · ${((i + 1) * spec.step).toStringAsFixed(1)} sn');
      final para = pb.build()..layout(const ui.ParagraphConstraints(width: cell));
      c.drawParagraph(para, o.translate(4, 3));
    }
    final out = await rec.endRecording().toImage(
      (cell * cols).toInt(),
      (cell * rows).toInt(),
    );
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/fig_$fig.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
