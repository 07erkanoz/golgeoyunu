// Oyundaki Sâye'nin hareket kareleri (açılış perdesinde oyundaki gibi
// oynasın): duruş, yürüyüş, çömelme; kavanozlu ve kavanozsuz.
// Ayrıca Yerebatan'ın Medusa başı (gözleri kapalı).
// `flutter test tools/preview/saye_kareler_cikar_test.dart --dart-define=CARTOON=true`
// → build/preview/saye_kare/<ad>.png (hepsi aynı boyda; ayak noktası
// (16 + w/2, 20 + h) · ölçek)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/legends.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

const scale = 12.0;
const pad = Offset(16, 20);

Future<void> save(
  Component c,
  String name, {
  Offset at = pad,
  ui.Size box = const ui.Size(Player.w + 32, Player.h + 28),
}) async {
  final w = box.width * scale;
  final h = box.height * scale;
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.scale(scale);
  canvas.translate(at.dx, at.dy);
  (c as PositionComponent).render(canvas);
  final img = await rec.endRecording().toImage(w.round(), h.round());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/saye_kare/$name.png')
      .writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWithGame<GolgeGame>('Sâye kareleri', GolgeGame.new, (game) async {
    Directory('build/preview/saye_kare').createSync(recursive: true);
    game.onGameResize(Vector2(960, 540));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    run(4);
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    final p = game.player!;
    p.velocity.setZero();
    run(1.5);
    Settings.lowGraphics = true;
    Player.debugBare = true;

    // Medusa başı: gözleri kapalıyken.
    final medusa = game.world.children.whereType<MedusaHead>().firstOrNull;
    if (medusa != null) {
      for (var i = 0; i < 600 && medusa.eyes > 0; i++) {
        game.update(1 / 60);
      }
      await save(
        medusa,
        'medusa',
        at: const Offset(40, 54),
        box: const ui.Size(80, 96),
      );
    }

    for (final jar in [false, true]) {
      Player.debugNoJar = !jar;
      final tag = jar ? '_kavanoz' : '';
      await save(p, 'dur$tag');
      final k = game.controls.keyboard;
      k.down = true;
      run(0.4);
      await save(p, 'comel$tag');
      k.down = false;
      run(0.4);
      k.right = true;
      run(0.7);
      for (var i = 0; i < 12; i++) {
        await save(p, 'yuru$tag$i');
        run(1 / 20);
      }
      k.right = false;
      run(0.6);
    }
  });
}
