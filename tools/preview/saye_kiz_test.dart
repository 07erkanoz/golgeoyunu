// Sâye taslağı II (oyuna bağlı değil): sevimli bir kız çocuğu, yandan.
// A · renkli tasvir (Karagöz tasvirleri gibi ışığı geçiren renkli deri),
// B · gölge siluet (yüz hatları yandan, kirpik ve burun siluetten taşar).
// Her biri büyük ve oyundaki boyutunda.
//   flutter test tools/preview/saye_kiz_test.dart
//   (çıktı: build/preview/saye_kiz.png)
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'yazi_tipi.dart';

const _ink = ui.Color(0xFF17100D);
const _rim = ui.Color(0xFFFFC27A);
const _red = ui.Color(0xFFC8402E);
const _jar = ui.Color(0xFFFFD58A);

class _Style {
  const _Style({
    required this.skin,
    required this.hair,
    required this.dress,
    required this.legs,
    required this.shoe,
    required this.colored,
  });
  final ui.Color skin;
  final ui.Color hair;
  final ui.Color dress;
  final ui.Color legs;
  final ui.Color shoe;
  final bool colored;
}

const _tasvir = _Style(
  skin: ui.Color(0xFFF2B98A),
  hair: ui.Color(0xFF2A1810),
  dress: ui.Color(0xFF34506E),
  legs: ui.Color(0xFF3A2418),
  shoe: ui.Color(0xFF8E3A24),
  colored: true,
);

const _golge = _Style(
  skin: _ink,
  hair: _ink,
  dress: _ink,
  legs: _ink,
  shoe: _ink,
  colored: false,
);

ui.Paint _p(ui.Color c) => ui.Paint()..color = c;

/// Baş: kafatası ve yandan yüz (alın, kalkık küçük burun, dudak, yuvarlak
/// çene). Çizim uzayı 18 x 40, ayaklar y = 40'ta, sağa bakar.
ui.Path _headPath() => ui.Path()
  ..addOval(ui.Rect.fromCircle(center: const ui.Offset(9.4, 11.4), radius: 6.9))
  ..moveTo(12.0, 5.6)
  ..quadraticBezierTo(15.6, 6.6, 16.1, 9.8)
  ..quadraticBezierTo(16.2, 10.7, 16.9, 11.5)
  ..quadraticBezierTo(17.6, 12.2, 16.9, 12.6)
  ..quadraticBezierTo(16.4, 12.8, 16.5, 13.4)
  ..quadraticBezierTo(16.8, 13.9, 16.4, 14.3)
  ..quadraticBezierTo(16.7, 14.8, 16.3, 15.6)
  ..quadraticBezierTo(15.7, 17.1, 13.6, 17.4)
  ..quadraticBezierTo(11.2, 17.8, 9.6, 17.0)
  ..close();

/// Saç: kâkül, başın üstü ve arkası; yüksekten bağlı at kuyruğu, kurdele.
void _hair(ui.Canvas c, _Style s, {required bool rim}) {
  final hair = _p(rim ? _rim : s.hair);
  // Başı saran saç: alından (kâkül uçları) tepeden enseye.
  c.drawPath(
    ui.Path()
      ..moveTo(15.9, 9.4)
      ..lineTo(15.0, 8.3)
      ..lineTo(14.6, 9.6)
      ..lineTo(13.6, 8.2)
      ..lineTo(12.9, 9.3)
      ..lineTo(12.2, 8.0)
      ..quadraticBezierTo(10.6, 9.0, 9.6, 11.0)
      ..quadraticBezierTo(8.6, 13.4, 8.9, 16.6)
      ..quadraticBezierTo(5.0, 17.0, 3.4, 14.6)
      ..quadraticBezierTo(1.6, 10.6, 3.6, 6.8)
      ..quadraticBezierTo(6.4, 3.2, 10.6, 3.6)
      ..quadraticBezierTo(15.2, 4.2, 15.9, 9.4)
      ..close(),
    hair,
  );
  // At kuyruğu: tepeden arkaya kalkıp dalgalanarak iner, ucu sivrilir.
  c.drawPath(
    ui.Path()
      ..moveTo(4.6, 5.0)
      ..quadraticBezierTo(0.2, 4.6, -1.0, 9.0)
      ..quadraticBezierTo(-2.0, 13.0, 0.2, 16.6)
      ..quadraticBezierTo(1.0, 18.4, 0.0, 20.6)
      ..quadraticBezierTo(2.4, 18.8, 2.4, 16.0)
      ..quadraticBezierTo(2.2, 13.0, 2.6, 10.6)
      ..quadraticBezierTo(3.2, 8.0, 5.6, 7.4)
      ..close(),
    hair,
  );
  if (rim) return;
  // Kurdele: kuyruğun bağında kırmızı fiyonk.
  final bow = _p(_red);
  c.save();
  c.translate(4.4, 5.8);
  c.rotate(-0.5);
  c.drawPath(
    ui.Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-2.6, -2.4, -3.0, 0.2)
      ..quadraticBezierTo(-2.4, 2.2, 0, 0)
      ..moveTo(0, 0)
      ..quadraticBezierTo(2.6, -2.4, 3.0, 0.2)
      ..quadraticBezierTo(2.4, 2.2, 0, 0),
    bow,
  );
  c.drawCircle(ui.Offset.zero, 0.9, bow);
  c.restore();
}

void _face(ui.Canvas c, _Style s) {
  if (s.colored) {
    // Göz: koyu badem, üstte iki kirpik, iri parıltı; kaş; yanak; ağız.
    const eye = ui.Offset(13.9, 11.2);
    c.drawOval(ui.Rect.fromCenter(center: eye, width: 2.0, height: 2.7), _p(const ui.Color(0xFF1E120C)));
    c.drawCircle(eye + const ui.Offset(0.35, -0.55), 0.48, _p(const ui.Color(0xFFFFFFFF)));
    c.drawCircle(eye + const ui.Offset(-0.35, 0.6), 0.22, _p(const ui.Color(0xCCFFFFFF)));
    final line = ui.Paint()
      ..color = const ui.Color(0xFF1E120C)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = ui.StrokeCap.round;
    c.drawLine(eye + const ui.Offset(0.8, -1.0), eye + const ui.Offset(1.7, -1.6), line);
    c.drawLine(eye + const ui.Offset(0.9, -0.4), eye + const ui.Offset(1.9, -0.7), line);
    c.drawArc(ui.Rect.fromCenter(center: eye + const ui.Offset(0.1, -1.9), width: 2.4, height: 1.2), math.pi + 0.4, math.pi - 0.9, false, line);
    c.drawCircle(const ui.Offset(13.4, 14.3), 1.3, _p(const ui.Color(0x66F06A6A)));
    c.drawArc(ui.Rect.fromCenter(center: const ui.Offset(15.6, 14.5), width: 1.4, height: 1.0), 0.3, math.pi - 0.9, false, line..color = const ui.Color(0xFFB0503C));
    // Kulak.
    c.drawCircle(const ui.Offset(9.8, 12.6), 1.2, _p(const ui.Color(0xFFE6A87A)));
  } else {
    // Gölgede yüz yandan okunur; kirpikler siluetten taşar, göz ışığı
    // ince bir yarık (bakışın yeri).
    final lash = ui.Paint()
      ..color = _ink
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..strokeCap = ui.StrokeCap.round;
    c.drawLine(const ui.Offset(15.6, 10.2), const ui.Offset(17.0, 9.4), lash);
    c.drawLine(const ui.Offset(15.8, 10.8), const ui.Offset(17.2, 10.4), lash);
    c.drawPath(
      ui.Path()
        ..moveTo(13.0, 11.3)
        ..quadraticBezierTo(14.2, 10.2, 15.3, 11.0)
        ..quadraticBezierTo(14.2, 11.6, 13.0, 11.3)
        ..close(),
      _p(const ui.Color(0xFFFFD9A8)),
    );
  }
}

void _body(ui.Canvas c, _Style s, {required bool rim}) {
  final ink = _p(rim ? _rim : s.dress);
  final limb = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;
  if (!rim) {
    // Arka kol, bacaklar, pabuçlar (kalkık uçlu).
    limb
      ..color = s.colored ? s.skin.withValues(alpha: 1) : _ink
      ..strokeWidth = 1.9;
    c.drawLine(const ui.Offset(8.6, 20.6), const ui.Offset(6.4, 26.6), limb..color = s.colored ? s.dress : _ink);
    c.drawCircle(const ui.Offset(6.3, 27.0), 1.1, _p(s.skin));
    limb
      ..color = s.legs
      ..strokeWidth = 2.4;
    for (final (hx, fx) in [(8.0, 7.2), (11.0, 11.6)]) {
      c.drawLine(ui.Offset(hx, 31.0), ui.Offset(fx, 38.2), limb);
      c.drawPath(
        ui.Path()
          ..moveTo(fx - 1.8, 40)
          ..lineTo(fx - 1.8, 38.2)
          ..quadraticBezierTo(fx + 0.6, 37.4, fx + 2.2, 38.4)
          ..quadraticBezierTo(fx + 3.8, 37.2, fx + 3.6, 39.0)
          ..quadraticBezierTo(fx + 3.0, 40, fx + 0.8, 40)
          ..close(),
        _p(s.shoe),
      );
    }
  }
  // Entari: omuzdan çan gibi açılır, etek ucu dalgalı.
  c.drawPath(
    ui.Path()
      ..moveTo(7.6, 18.6)
      ..quadraticBezierTo(10.2, 17.8, 12.2, 18.6)
      ..quadraticBezierTo(13.6, 24.6, 15.6, 32.0)
      ..quadraticBezierTo(14.2, 33.2, 12.6, 32.4)
      ..quadraticBezierTo(11.0, 33.4, 9.4, 32.6)
      ..quadraticBezierTo(7.8, 33.4, 6.2, 32.6)
      ..quadraticBezierTo(4.6, 33.2, 3.6, 32.0)
      ..quadraticBezierTo(5.8, 24.6, 7.6, 18.6)
      ..close(),
    ink,
  );
  if (rim) return;
  if (s.colored) {
    // Etekte altın şerit ve benekler; omuz ve kalçada perçin.
    final gold = _p(const ui.Color(0xFFE2B060));
    c.drawPath(
      ui.Path()
        ..moveTo(4.2, 30.6)
        ..quadraticBezierTo(9.6, 31.6, 15.0, 30.6)
        ..lineTo(15.2, 31.3)
        ..quadraticBezierTo(9.6, 32.3, 4.0, 31.3)
        ..close(),
      gold,
    );
    for (final d in const [ui.Offset(8.2, 24.0), ui.Offset(11.4, 25.6), ui.Offset(9.4, 28.2), ui.Offset(12.8, 28.8), ui.Offset(6.6, 28.0)]) {
      c.drawCircle(d, 0.35, gold);
    }
  }
  // Atkı: boyunda kırmızı, arkada iki ucu.
  final red = _p(_red);
  c.drawRRect(ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(7.0, 17.6, 6.2, 2.4), const ui.Radius.circular(1.1)), red);
  c.drawPath(
    ui.Path()
      ..moveTo(7.6, 18.8)
      ..quadraticBezierTo(5.4, 20.6, 4.6, 24.0)
      ..lineTo(5.8, 23.8)
      ..quadraticBezierTo(6.6, 21.4, 8.2, 19.8)
      ..close(),
    red,
  );
  // Ön kol ve kavanoz.
  limb
    ..color = s.colored ? s.dress : _ink
    ..strokeWidth = 1.9;
  c.drawLine(const ui.Offset(11.2, 20.4), const ui.Offset(13.6, 26.0), limb);
  c.drawCircle(const ui.Offset(13.8, 26.4), 1.1, _p(s.skin));
  const j = ui.Offset(14.0, 30.0);
  c.drawCircle(j, 10, ui.Paint()..shader = ui.Gradient.radial(j, 10, [_jar.withValues(alpha: 0.30), _jar.withValues(alpha: 0)]));
  final jar = ui.RRect.fromRectAndRadius(ui.Rect.fromCenter(center: j, width: 4.2, height: 4.8), const ui.Radius.circular(1.5));
  c.drawRRect(jar, _p(_jar));
  c.drawRRect(jar, ui.Paint()
    ..color = const ui.Color(0xFF3A2414)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 0.5);
  c.drawLine(j + const ui.Offset(-1.5, -2.6), j + const ui.Offset(1.5, -2.6), ui.Paint()
    ..color = const ui.Color(0xFF3A2414)
    ..strokeWidth = 0.8);
  c.drawLine(const ui.Offset(13.8, 26.6), j + const ui.Offset(0, -2.6), ui.Paint()
    ..color = const ui.Color(0xFF3A2414)
    ..strokeWidth = 0.4);
  for (final d in const [ui.Offset(-0.7, 0.4), ui.Offset(0.8, -0.5), ui.Offset(0.3, 1.3)]) {
    c.drawCircle(j + d, 0.4, _p(const ui.Color(0xFFFFF6E0)));
  }
}

void _saye(ui.Canvas c, _Style s) {
  // Kenar ışığı: aynı siluet ışık renginde, ışığa doğru biraz kaydırılmış.
  c.save();
  c.translate(0.45, -0.35);
  _hair(c, s, rim: true);
  c.drawPath(_headPath(), _p(_rim));
  _body(c, s, rim: true);
  c.restore();
  _body(c, s, rim: false);
  c.drawPath(_headPath(), _p(s.skin));
  _hair(c, s, rim: false);
  _face(c, s);
}

void main() {
  setUpAll(yaziTipiYukle);
  test('Sâye kız', () async {
    const big = 9.0;
    const cellW = 520.0;
    const cellH = 440.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, cellW * 2, cellH), _p(const ui.Color(0xFF2A1A12)));
    for (final (i, s, label) in [(0, _tasvir, 'A · Renkli tasvir'), (1, _golge, 'B · Gölge siluet')]) {
      final o = ui.Offset(i * cellW, 0);
      final mid = o + const ui.Offset(cellW * 0.42, cellH * 0.48);
      c.drawCircle(mid, 220, ui.Paint()..shader = ui.Gradient.radial(mid, 220, const [ui.Color(0xFF6A4428), ui.Color(0x002A1A12)]));
      final floor = o.dy + cellH - 50;
      c.drawLine(ui.Offset(o.dx + 20, floor), ui.Offset(o.dx + cellW - 20, floor), _p(const ui.Color(0xFF8A6A4A))..strokeWidth = 1.2);
      c.save();
      c.translate(o.dx + 120, floor - 40 * big);
      c.scale(big);
      _saye(c, s);
      c.restore();
      // Oyundaki boyutu (perdede ~ 2 kat büyütülmüş 28 piksel).
      const small = 1.4;
      c.save();
      c.translate(o.dx + cellW - 70, floor - 40 * small);
      c.scale(small);
      _saye(c, s);
      c.restore();
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 20, fontFamily: 'Roboto'))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFE0D0B0)))
        ..addText(label);
      c.drawParagraph(pb.build()..layout(const ui.ParagraphConstraints(width: cellW)), o + const ui.Offset(14, 10));
      final pb2 = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13, fontFamily: 'Roboto'))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFB09878)))
        ..addText('oyunda');
      c.drawParagraph(pb2.build()..layout(const ui.ParagraphConstraints(width: 80)), ui.Offset(o.dx + cellW - 76, floor + 8));
    }
    final img = await rec.endRecording().toImage((cellW * 2).toInt(), cellH.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/saye_kiz.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
