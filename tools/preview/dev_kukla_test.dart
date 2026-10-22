// Yeni taş dev kuklası tek başına: yürüyüş, iki elle kaya kaldırıp atma,
// sendeleme, devrilme. `flutter test tools/preview/dev_kukla_test.dart`
// → build/preview/dev_kukla/kare_NNN.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/giant_puppet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('dev kukla', () async {
    final puppet = await GiantPuppet.load();
    final dir = Directory('build/preview/dev_kukla');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    const dt = 1 / 12;
    var f = 0;
    Future<void> shot(
      GiantPose p, {
      ui.Offset? boulder,
      double fallA = 0,
    }) async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
        const ui.Rect.fromLTWH(0, 0, 640, 420),
        ui.Paint()..color = const ui.Color(0xFF2A1E2A),
      );
      c.drawRect(
        const ui.Rect.fromLTWH(0, 380, 640, 40),
        ui.Paint()..color = const ui.Color(0xFF0E0A10),
      );
      c.save();
      c.translate(240, 380);
      c.scale(1.0);
      c.translate(GiantPuppet.pivotX, 0);
      c.rotate(fallA);
      c.translate(-GiantPuppet.pivotX, 0);
      puppet.drawPose(c, p, boulderAt: boulder);
      c.restore();
      final img = await rec.endRecording().toImage(640, 420);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/kare_${(f++).toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    for (var t = 0.0; t < 2.2; t += dt) {
      puppet.walk(26 * dt);
      await shot(puppet.pose());
    }
    const windup = 1.4;
    for (var t = 0.0; t < windup; t += dt) {
      final p = puppet.pose(throwStage: 1, throwK: t / windup);
      await shot(p, boulder: puppet.boulder(p, 1, t / windup));
    }
    for (var t = 0.0; t < .35; t += dt) {
      await shot(puppet.pose(throwStage: 2, throwK: t / .35));
    }
    for (var t = 0.0; t < 1.6; t += dt) {
      await shot(puppet.pose(throwStage: 3, throwK: t / 1.6));
    }
    for (var s = 2.4; s > 0; s -= dt) {
      await shot(puppet.pose(stagger: s));
    }
    final fp = puppet.pose();
    for (var t = 0.0; t < 1.0; t += dt / 1.25) {
      await shot(fp, fallA: GiantPuppet.fallAngle(t, 0));
    }
    for (var a = 0.0; a < 1.0; a += dt) {
      await shot(fp, fallA: GiantPuppet.fallAngle(1, a));
    }
  });
}
