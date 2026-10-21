// Bekçi ve Medusa paketinin önizlemesi (oyuna eklenmeden): paketin renkli
// hâli, gölge oyununa uygun karanlık siluet hâli, yürüyüş kareleri ve
// yılanlı Medusa. Paket verisi: BEKCI_ART (art.json yolu).
// `flutter test tools/preview/bekci_preview_test.dart --dart-define=BEKCI_ART=...`
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'bekci_pkg/character_motion.dart';
import 'bekci_pkg/character_visuals.dart';
import 'bekci_pkg/vector_art.dart';

const _dark = ui.Color(0xFF0B0910);
const _rim = ui.Color(0xFFE0A15F);

void _scene(ui.Canvas c, ui.Rect r) {
  c.drawRect(
    r,
    ui.Paint()
      ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [
        ui.Color(0xFF2A1810),
        ui.Color(0xFF120A07),
      ]),
  );
  // Sarnıç kemerleri ve zemin.
  final arch = ui.Paint()
    ..color = const ui.Color(0xFF3A2216)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 10;
  for (var x = r.left - 40; x < r.right; x += 200) {
    c.drawArc(ui.Rect.fromLTWH(x, r.top + 40, 200, 180), math.pi, math.pi, false, arch);
    c.drawRect(ui.Rect.fromLTWH(x - 8, r.top + 130, 16, r.height), ui.Paint()..color = const ui.Color(0xFF2A170F));
  }
  c.drawRect(ui.Rect.fromLTWH(r.left, r.bottom - 60, r.width, 60), ui.Paint()..color = const ui.Color(0xFF0A0605));
}

/// Paketteki bekçi, gölge oyunu tarzında: gövde koyu siluet, arkadan vuran
/// kandil ışığı kenarı çizer; yalnız fener renkli ve ışıklı.
void silhouetteGuard(ui.Canvas c, CharacterMotion m, VectorArt art) {
  const bounds = ui.Rect.fromLTRB(-100, -100, 900, 950);
  c.saveLayer(
    bounds,
    ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(_rim.withValues(alpha: 0.55), ui.BlendMode.srcIn)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
  );
  c.save();
  c.translate(-4, -3);
  drawGuard(c, m, art, showBeam: false);
  c.restore();
  c.restore();
  c.saveLayer(bounds, ui.Paint()..colorFilter = const ui.ColorFilter.mode(_dark, ui.BlendMode.srcIn));
  drawGuard(c, m, art, showBeam: false);
  c.restore();
  // Yüz: başlığın içinde iki soluk göz.
  final p = m.guardPose();
  c.save();
  c.translate(0, p.bob);
  c.drawCircle(const ui.Offset(282, 258), 4, ui.Paint()..color = const ui.Color(0xFFBFE0FF));
  c.drawCircle(const ui.Offset(296, 258), 4, ui.Paint()..color = const ui.Color(0xFFBFE0FF));
  // Fener: renkli, ışık saçar.
  c.drawCircle(
    p.lamp,
    150,
    ui.Paint()
      ..shader = ui.Gradient.radial(p.lamp, 150, const [ui.Color(0x88FFD08A), ui.Color(0x00FFD08A)]),
  );
  c.save();
  c.translate(p.shift.dx, p.shift.dy);
  c.translate(m.lampPivot.dx, m.lampPivot.dy);
  c.rotate(m.lampAngle);
  c.translate(-m.lampPivot.dx, -m.lampPivot.dy);
  art.draw(c, 'lantern');
  c.restore();
  c.restore();
}

/// Medusa sarnıçtaki taş kaide gibi: soluk, yeşilimsi taş.
void stoneMedusa(ui.Canvas c, CharacterMotion m, VectorArt art) {
  c.saveLayer(
    const ui.Rect.fromLTRB(-100, -100, 900, 950),
    ui.Paint()
      ..colorFilter = const ui.ColorFilter.matrix(<double>[
        0.30, 0.45, 0.10, 0, 0, //
        0.28, 0.45, 0.10, 0, 0, //
        0.24, 0.38, 0.10, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
  );
  drawMedusa(c, m, art);
  c.restore();
}

void main() {
  test('bekçi önizleme', () async {
    final data = jsonDecode(File(const String.fromEnvironment('BEKCI_ART')).readAsStringSync()) as Map<String, dynamic>;
    final guardArt = VectorArt(data['guard'] as Map<String, dynamic>);
    final medusaArt = VectorArt(data['medusa'] as Map<String, dynamic>);
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    const w = 1800.0;
    const h = 1500.0;
    c.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), ui.Paint()..color = const ui.Color(0xFF101014));

    // 1. sıra: aynı sahnede renkli ve siluet bekçi (oyun yakınlığında, 3x).
    _scene(c, const ui.Rect.fromLTWH(0, 0, w, 560));
    final m = CharacterMotion(data);
    for (var i = 0; i < 40; i++) {
      m.update(1 / 60, actualDx: 0.6);
    }
    for (final (x, sil) in [(380.0, false), (1250.0, true)]) {
      c.save();
      c.translate(x, 500);
      c.scale(0.55);
      c.translate(-275, -777);
      if (sil) {
        silhouetteGuard(c, m, guardArt);
      } else {
        drawGuard(c, m, guardArt);
      }
      c.restore();
    }

    // 2. sıra: siluet yürüyüş kareleri.
    _scene(c, const ui.Rect.fromLTWH(0, 560, w, 400));
    final mw = CharacterMotion(data);
    for (var k = 0; k < 6; k++) {
      for (var i = 0; i < 9; i++) {
        mw.update(1 / 60, actualDx: 0.8);
      }
      c.save();
      c.translate(150 + k * 290.0, 920);
      c.scale(0.4);
      c.translate(-275, -777);
      silhouetteGuard(c, mw, guardArt);
      c.restore();
    }

    // 3. sıra: Medusa — paketin renklisi, taş tonunda gözler kapalı ve açık.
    _scene(c, const ui.Rect.fromLTWH(0, 960, w, 540));
    for (final (x, eyes, stone) in [(300.0, 1.0, false), (900.0, 0.0, true), (1500.0, 1.0, true)]) {
      final mm = CharacterMotion(data)..externalEyes = eyes;
      for (var i = 0; i < 30; i++) {
        mm.update(1 / 60, actualDx: 0);
      }
      c.save();
      c.translate(x, 1240);
      c.scale(0.55);
      c.translate(-363, -463);
      if (stone) {
        stoneMedusa(c, mm, medusaArt);
      } else {
        drawMedusa(c, mm, medusaArt);
      }
      c.restore();
    }

    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/bekci_onizleme.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
