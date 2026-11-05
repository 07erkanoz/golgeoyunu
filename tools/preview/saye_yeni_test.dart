// Sevimli yeni Sâye taslağı (oyuna bağlı değil): hayal perdesi tasviri gibi
// mürekkep siluet; iri yuvarlak baş, ışığın sızdığı oyma gözler, topuz ve
// ucunda kırmızı kurdeleli örgü, kısa entari, ucu kalkık pabuçlar, eklem
// pimleri. Duruş, göz kırpma, koşu, zıplamanın basılıp gerilmesi, iniş.
//   flutter test tools/preview/saye_yeni_test.dart
//   (çıktı: build/preview/saye_yeni.png)
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'yazi_tipi.dart';

const _ink = ui.Color(0xFF17100D);
const _rim = ui.Color(0xFFFFC27A);
const _hole = ui.Color(0xFFFFE2B0);
const _red = ui.Color(0xFFC8402E);
const _jar = ui.Color(0xFFFFD58A);

/// Bir pozun bütün ayarları (çizim uzayı: 18 x 40, ayaklar y = 40'ta, sağa bakar).
class Pose {
  const Pose(
    this.label, {
    this.sx = 1,
    this.sy = 1,
    this.lean = 0,
    this.lift = 0,
    this.footA = const ui.Offset(7.5, 40),
    this.footB = const ui.Offset(11.5, 40),
    this.hipDrop = 0,
    this.backArm = 0.25,
    this.jarHand = const ui.Offset(13.5, 27),
    this.blink = 0,
    this.braid = 0.2,
    this.scarf = 0.3,
    this.look = 0,
    this.smile = 1,
    this.armsUp = false,
  });

  final String label;
  final double sx;
  final double sy;
  final double lean;
  final double lift;
  final ui.Offset footA;
  final ui.Offset footB;
  final double hipDrop;
  final double backArm;
  final ui.Offset jarHand;
  final double blink;
  final double braid;
  final double scarf;
  final double look;
  final double smile;
  final bool armsUp;
}

void _drawSaye(ui.Canvas c, Pose p, {required bool rimPass}) {
  final ink = ui.Paint()..color = rimPass ? _rim : _ink;
  final limb = ui.Paint()
    ..color = ink.color
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;

  c.save();
  // Basılma/gerilme ayakların ortasından; öne eğilme kalçadan.
  c.translate(9.5, 40 - p.lift);
  c.scale(p.sx, p.sy);
  c.translate(-9.5, -40);
  c.translate(9.5, 30);
  c.rotate(p.lean);
  c.translate(-9.5, -30);

  final hipY = 31.0 + p.hipDrop;
  const head = ui.Offset(9.8, 12.2);
  const headR = 8.4;

  // Örgü: başın arkasından sarkar, ucunda kurdele.
  final bAng = p.braid;
  var prev = const ui.Offset(3.0, 14.5);
  final braidPts = <ui.Offset>[prev];
  for (var i = 1; i <= 4; i++) {
    final a = bAng * i * 0.55;
    prev = prev + ui.Offset(-math.sin(a) * 2.6, math.cos(a) * 2.6);
    braidPts.add(prev);
  }
  for (var i = 0; i < (rimPass ? 0 : braidPts.length - 1); i++) {
    c.drawCircle(braidPts[i], 1.9 - i * 0.18, ink);
    c.drawLine(braidPts[i], braidPts[i + 1], limb..strokeWidth = 2.2);
  }
  final tip = braidPts.last;
  if (!rimPass) {
    final bow = ui.Paint()..color = _red;
    c.drawOval(ui.Rect.fromCenter(center: tip + const ui.Offset(-1.6, 0.4), width: 2.6, height: 1.8), bow);
    c.drawOval(ui.Rect.fromCenter(center: tip + const ui.Offset(1.4, 0.6), width: 2.6, height: 1.8), bow);
    c.drawCircle(tip + const ui.Offset(0, 0.5), 0.8, bow);
  }

  // Arka kol (salınır) ya da yukarı uzanan kollar.
  const shoulder = ui.Offset(9.0, 21.5);
  limb.strokeWidth = 2.5;
  if (rimPass) {
  } else if (p.armsUp) {
    c.drawLine(shoulder, const ui.Offset(6.0, -2.0), limb);
    c.drawCircle(const ui.Offset(6.0, -2.5), 1.6, ink);
  } else {
    final h = shoulder + ui.Offset(-math.sin(p.backArm) * 7, math.cos(p.backArm) * 7);
    c.drawLine(shoulder, h, limb);
    c.drawCircle(h, 1.3, ink);
  }

  // Bacaklar: kısa, dizden hafif bükük; ucu kalkık pabuçlar.
  limb.strokeWidth = 3.0;
  for (final (hipX, foot) in rimPass ? const <(double, ui.Offset)>[] : [(8.0, p.footA), (11.0, p.footB)]) {
    final hip = ui.Offset(hipX, hipY);
    final mid = ui.Offset((hip.dx + foot.dx) / 2 + 1.0, (hip.dy + foot.dy) / 2);
    c.drawLine(hip, mid, limb);
    c.drawLine(mid, foot + const ui.Offset(0, -1.2), limb);
    final shoe = ui.Path()
      ..moveTo(foot.dx - 2.2, foot.dy)
      ..lineTo(foot.dx - 2.2, foot.dy - 2.0)
      ..quadraticBezierTo(foot.dx + 1.0, foot.dy - 2.8, foot.dx + 2.6, foot.dy - 1.6)
      ..quadraticBezierTo(foot.dx + 4.4, foot.dy - 3.2, foot.dx + 4.0, foot.dy - 1.0)
      ..quadraticBezierTo(foot.dx + 3.2, foot.dy, foot.dx + 1.0, foot.dy)
      ..close();
    c.drawPath(shoe, ink);
  }

  // Entari: boyundan eteğe genişleyen, etek ucu yuvarlak.
  final body = ui.Path()
    ..moveTo(7.2, 19.0)
    ..lineTo(12.6, 19.0)
    ..quadraticBezierTo(14.6, 26.0, 15.0, hipY + 1.2)
    ..quadraticBezierTo(9.8, hipY + 3.0, 4.4, hipY + 1.2)
    ..quadraticBezierTo(5.0, 26.0, 7.2, 19.0)
    ..close();
  c.drawPath(body, ink);

  // Baş: iri, yuvarlak; arkada topuz, önde küçük burun, çene.
  c.drawCircle(const ui.Offset(3.6, 6.0), 3.0, ink); // topuz
  c.drawCircle(head, headR, ink);
  c.drawCircle(head + const ui.Offset(8.2, 1.4), 1.2, ink); // burun
  // Kâkül: alnın üstünde dalgalı uçlar (siluetin kenarı).
  c.drawPath(
    ui.Path()
      ..moveTo(9.0, 3.8)
      ..quadraticBezierTo(15.5, 3.2, 18.0, 8.6)
      ..lineTo(16.4, 8.0)
      ..lineTo(15.8, 9.6)
      ..lineTo(14.2, 8.2)
      ..close(),
    ink,
  );

  // Atkı: boyunda kırmızı bant, arkada uçuşan iki uç.
  if (!rimPass) {
    final red = ui.Paint()..color = _red;
    c.drawRRect(
      ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(6.4, 18.6, 7.4, 2.6), const ui.Radius.circular(1.2)),
      red,
    );
    final w = p.scarf;
    for (final (dy, len0) in [(0.0, 7.0), (1.4, 5.6)]) {
      final len = len0 * (0.45 + 0.55 * w.abs());
      c.drawPath(
        ui.Path()
          ..moveTo(7.0, 19.2 + dy)
          ..quadraticBezierTo(7.0 - len * 0.5, 19.0 + dy + 3 * (1 - w), 7.0 - len, 20.5 + dy + 5 * (1 - w) - 2 * w)
          ..lineTo(7.0 - len + 0.6, 21.8 + dy + 5 * (1 - w) - 2 * w)
          ..quadraticBezierTo(7.0 - len * 0.5, 20.6 + dy + 3 * (1 - w), 7.6, 20.8 + dy)
          ..close(),
        red,
      );
    }
  }

  // Ön kol ve kavanoz.
  limb.strokeWidth = 2.5;
  if (rimPass) {
  } else if (p.armsUp) {
    c.drawLine(const ui.Offset(11, 21.5), const ui.Offset(13.0, -2.0), limb);
    c.drawCircle(const ui.Offset(13.0, -2.5), 1.6, ink);
  } else {
    c.drawLine(const ui.Offset(11, 21.5), p.jarHand, limb);
    c.drawCircle(p.jarHand, 1.3, ink);
  }

  if (!rimPass) {
    // Oyma gözler: ışığın sızdığı iki yumuşak oval (bebek yok); başın alt
    // yarısında, birbirine yakın. Bakış, gözleri hafifçe kaydırır.
    final open = 1 - p.blink;
    final gaze = ui.Offset(p.look.abs() * 0.3, -p.look * 0.7);
    for (final (ctr, rw, rh) in [
      (head + const ui.Offset(3.4, 1.2), 1.45, 2.05),
      (head + const ui.Offset(6.5, 1.0), 1.05, 1.8),
    ]) {
      final at = ctr + gaze;
      final glow = ui.Paint()
        ..color = _hole
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 0.9);
      if (open < 0.15) {
        // Kapalı göz: aşağı kıvrık ince bir yay (gülen göz).
        c.drawArc(
          ui.Rect.fromCenter(center: at + const ui.Offset(0, 0.4), width: rw * 2.2, height: 1.8),
          math.pi + 0.3,
          math.pi - 0.6,
          false,
          ui.Paint()
            ..color = _hole
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 0.7
            ..strokeCap = ui.StrokeCap.round,
        );
        continue;
      }
      final r = ui.Rect.fromCenter(center: at, width: rw * 2, height: rh * 2 * open);
      c.drawOval(r.inflate(0.5), glow..color = _hole.withValues(alpha: 0.45));
      c.drawOval(r, ui.Paint()..color = _hole);
    }
    // Küçük gülümseme (oyma çizgi).
    final m = head + const ui.Offset(5.4, 5.0);
    c.drawArc(
      ui.Rect.fromCenter(center: m, width: 2.2, height: 1.2 * p.smile + 0.3),
      0.25,
      math.pi - 0.5,
      false,
      ui.Paint()
        ..color = _hole.withValues(alpha: 0.85)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..strokeCap = ui.StrokeCap.round,
    );
    // Eklem pimleri: tasvirin perçinleri (omuz, kalça).
    final pin = ui.Paint()..color = const ui.Color(0xFF8A6448);
    c.drawCircle(const ui.Offset(10.2, 21.6), 0.55, pin);
    c.drawCircle(ui.Offset(9.6, hipY - 0.4), 0.55, pin);
  }
  c.restore();

  // Kavanoz (dönüşlerin dışında, ele asılı): sıcak ışık.
  if (!rimPass && !p.armsUp) {
    c.save();
    c.translate(9.5, 40 - p.lift);
    c.scale(p.sx, p.sy);
    c.translate(-9.5, -40);
    c.translate(9.5, 30);
    c.rotate(p.lean);
    c.translate(-9.5, -30);
    final j = p.jarHand + const ui.Offset(0, 4.2);
    c.drawCircle(
      j,
      10,
      ui.Paint()
        ..shader = ui.Gradient.radial(j, 10, [_jar.withValues(alpha: 0.30), _jar.withValues(alpha: 0)]),
    );
    final body = ui.RRect.fromRectAndRadius(ui.Rect.fromCenter(center: j, width: 4.6, height: 5.4), const ui.Radius.circular(1.6));
    c.drawRRect(body, ui.Paint()..color = _jar);
    c.drawRRect(body, ui.Paint()
      ..color = const ui.Color(0xFF3A2414)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.6);
    c.drawLine(j + const ui.Offset(-1.6, -2.9), j + const ui.Offset(1.6, -2.9), ui.Paint()
      ..color = const ui.Color(0xFF3A2414)
      ..strokeWidth = 0.9);
    for (final d in [const ui.Offset(-0.8, 0.4), const ui.Offset(0.9, -0.6), const ui.Offset(0.4, 1.4)]) {
      c.drawCircle(j + d, 0.45, ui.Paint()..color = const ui.Color(0xFFFFF6E0));
    }
    c.restore();
  }
}

void _figure(ui.Canvas c, Pose p) {
  // Önce ışık renginde, ışığa doğru kaydırılmış siluet; üstüne mürekkep:
  // geriye ince bir kenar ışığı kalır.
  c.save();
  c.translate(0.5, -0.4);
  _drawSaye(c, p, rimPass: true);
  c.restore();
  _drawSaye(c, p, rimPass: false);
}

const _poses = [
  Pose('Duruş'),
  Pose('Göz kırpar', blink: 1, smile: 1.2),
  Pose('Koşu', lean: 0.16, footA: ui.Offset(3.5, 38.5), footB: ui.Offset(14.5, 40), backArm: -0.9, jarHand: ui.Offset(15, 25.5), braid: 0.9, scarf: 0.95, hipDrop: -0.6),
  Pose('Koşu', lean: 0.16, footA: ui.Offset(12.5, 40), footB: ui.Offset(6.0, 37.5), backArm: 0.9, jarHand: ui.Offset(12.5, 27.5), braid: 1.0, scarf: 1.0, lift: 0.5),
  Pose('Hazırlanır', sx: 1.14, sy: 0.84, hipDrop: 1.6, footA: ui.Offset(6.5, 40), footB: ui.Offset(12.5, 40), backArm: -0.6, braid: -0.1, scarf: 0.2),
  Pose('Sıçrar', sx: 0.88, sy: 1.14, lift: 3.0, footA: ui.Offset(8.5, 41), footB: ui.Offset(10.5, 41.5), backArm: 2.6, jarHand: ui.Offset(14.5, 23.5), braid: -0.6, scarf: 0.1, look: 1),
  Pose('Tepede', lift: 5.0, footA: ui.Offset(6.0, 37.5), footB: ui.Offset(12.5, 39), backArm: 1.6, jarHand: ui.Offset(15, 24.5), braid: 0.3, scarf: 0.5, look: 0.4),
  Pose('Düşer', sx: 0.94, sy: 1.06, lift: 3.0, footA: ui.Offset(7.0, 40.5), footB: ui.Offset(12.0, 39.5), backArm: 2.9, jarHand: ui.Offset(15.5, 21.5), braid: -1.1, scarf: -0.3, look: -1, smile: 0.2),
  Pose('Konar', sx: 1.18, sy: 0.82, hipDrop: 2.0, footA: ui.Offset(5.5, 40), footB: ui.Offset(13.5, 40), backArm: -1.0, braid: 0.6, scarf: 0.6),
  Pose('Saklanır', sx: 1.06, sy: 0.74, hipDrop: 2.5, footA: ui.Offset(6.5, 40), footB: ui.Offset(12.0, 40), backArm: 0.2, jarHand: ui.Offset(12.5, 30), braid: 0.1, scarf: 0.1, look: -0.6, smile: 0.3),
  Pose('Tutunur', armsUp: true, sx: 0.96, sy: 1.04, footA: ui.Offset(8.5, 40.5), footB: ui.Offset(10.5, 39.5), braid: 0.05, scarf: 0.05, look: 1),
  Pose('Merak', lean: -0.06, look: 1, backArm: 0.1, jarHand: ui.Offset(15.5, 22.5), braid: 0.15, smile: 1.4),
];

void main() {
  setUpAll(yaziTipiYukle);
  test('sevimli Sâye', () async {
    const cell = 300.0;
    const cols = 6;
    const zoom = 5.6;
    final rows = (_poses.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      ui.Rect.fromLTWH(0, 0, cell * cols, cell * rows),
      ui.Paint()..color = const ui.Color(0xFF2A1A12),
    );
    for (var i = 0; i < _poses.length; i++) {
      final p = _poses[i];
      final o = ui.Offset((i % cols) * cell, (i ~/ cols) * cell);
      // Perde ışığı: hücrenin ortasında ılık bir hare, ayak altında zemin.
      c.drawCircle(
        o + const ui.Offset(cell / 2, cell * 0.5),
        cell * 0.42,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            o + const ui.Offset(cell / 2, cell * 0.5),
            cell * 0.42,
            const [ui.Color(0xFF5A3A24), ui.Color(0x002A1A12)],
          ),
      );
      final floorY = o.dy + cell * 0.86;
      c.drawLine(
        ui.Offset(o.dx + 20, floorY),
        ui.Offset(o.dx + cell - 20, floorY),
        ui.Paint()
          ..color = const ui.Color(0xFF8A6A4A)
          ..strokeWidth = 1.2,
      );
      c.save();
      c.translate(o.dx + cell / 2 - 9.5 * zoom, floorY - 40 * zoom);
      c.scale(zoom);
      _figure(c, p);
      c.restore();
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 18, fontFamily: 'Roboto'))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFE0D0B0)))
        ..addText('${i + 1} · ${p.label}');
      final para = pb.build()..layout(const ui.ParagraphConstraints(width: cell));
      c.drawParagraph(para, o + const ui.Offset(10, 8));
    }
    final img = await rec.endRecording().toImage((cell * cols).toInt(), (cell * rows).toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/saye_yeni.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
