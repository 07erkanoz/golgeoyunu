// Sâye taslağı III (oyuna bağlı değil), kullanıcının örneklerine göre: saf
// siyah kız çocuğu silueti. Oranlar şemsiyeli kız örneğinden ölçüldü (boy
// ~980 birim): daire baş (r 150), boyun yok denecek kadar kısa; yüzde en öne
// çıkan dolgun yanak ve çene, küçük kalkık burun, minik dudaklar, alında saç
// kıvrımı; kurdeleli at kuyruğu, çan etekli elbise, çizmeler; elde kavanoz.
// Kanatlı hâli: oymalı kelebek kanatları, oyundaki kanat renginde.
//   flutter test tools/preview/saye_siluet_test.dart
//   (çıktı: build/preview/saye_siluet.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'yazi_tipi.dart';

const _ink = ui.Color(0xFF120C0A);
const _rim = ui.Color(0xFFFFC27A);
const _jar = ui.Color(0xFFFFD58A);
const _wing = ui.Color(0xFFE2D2B6);

ui.Paint _p(ui.Color c) => ui.Paint()..color = c;

/// Uçlara doğru incelen uzuv (iki yuvarlak uç arasında dörtgen).
void _limb(ui.Canvas c, ui.Offset a, ui.Offset b, double wa, double wb, ui.Paint p) {
  final d = b - a;
  final n = ui.Offset(-d.dy, d.dx) / d.distance;
  c.drawPath(
    ui.Path()
      ..moveTo(a.dx + n.dx * wa / 2, a.dy + n.dy * wa / 2)
      ..lineTo(b.dx + n.dx * wb / 2, b.dy + n.dy * wb / 2)
      ..lineTo(b.dx - n.dx * wb / 2, b.dy - n.dy * wb / 2)
      ..lineTo(a.dx - n.dx * wa / 2, a.dy - n.dy * wa / 2)
      ..close(),
    p,
  );
  c.drawCircle(a, wa / 2, p);
  c.drawCircle(b, wb / 2, p);
}

/// Çizme: bileğin altında, konçlu; yuvarlak burnu [ang] yönünde.
void _boot(ui.Canvas c, ui.Offset ankle, double ang, ui.Paint p) {
  c.save();
  c.translate(ankle.dx, ankle.dy);
  c.rotate(ang);
  c.scale(0.78);
  c.drawPath(
    ui.Path()
      ..moveTo(-38, -70)
      ..lineTo(34, -70)
      ..lineTo(36, 40)
      ..quadraticBezierTo(70, 46, 96, 66)
      ..quadraticBezierTo(106, 82, 92, 92)
      ..lineTo(-36, 92)
      ..quadraticBezierTo(-46, 88, -44, 70)
      ..close(),
    p,
  );
  c.restore();
}

/// Bacak: kalça, diz, bilek (ince, çocuk bacağı) ve çizme.
void _leg(ui.Canvas c, ui.Offset hip, ui.Offset knee, ui.Offset ankle, double toe, ui.Paint p) {
  _limb(c, hip, knee, 46, 36, p);
  _limb(c, knee, ankle, 36, 34, p);
  _boot(c, ankle, toe, p);
}

/// El: küçük avuç, başparmak.
void _hand(ui.Canvas c, ui.Offset at, double ang, ui.Paint p) {
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(ang);
  c.drawOval(const ui.Rect.fromLTWH(-14, -16, 40, 32), p);
  _limb(c, const ui.Offset(4, -12), const ui.Offset(18, -26), 12, 9, p);
  c.restore();
}

/// Baş: daire kafa; önde yüz (alın, gözün hafif çukuru, küçük kalkık burun,
/// minik dudaklar, en önde dolgun yanak ve çene). Alında saç kıvrımı; tepede
/// bağlı at kuyruğu ve fiyonk. Merkez (0, 0), yarıçap 150.
void _head(ui.Canvas c, ui.Paint p, {double tail = 0}) {
  c.drawCircle(ui.Offset.zero, 150, p);
  c.drawPath(
    ui.Path()
      ..moveTo(60, -140)
      ..quadraticBezierTo(126, -112, 140, -54) // alın
      ..quadraticBezierTo(146, -36, 143, -28) // gözün hafif çukuru
      ..quadraticBezierTo(160, -26, 172, -16) // burun sırtı
      ..quadraticBezierTo(180, -8, 168, -2) // burun ucu (kalkık)
      ..quadraticBezierTo(158, 2, 160, 8) // burun altı
      ..quadraticBezierTo(172, 12, 168, 20) // üst dudak
      ..quadraticBezierTo(160, 24, 164, 30) // ağız
      ..quadraticBezierTo(172, 36, 168, 42) // alt dudak
      ..quadraticBezierTo(190, 56, 184, 80) // dolgun yanak / çene
      ..quadraticBezierTo(176, 110, 140, 124) // çenenin altı
      ..quadraticBezierTo(100, 138, 60, 140)
      ..close(),
    p,
  );
  // Alında öne kıvrılan bir tutam.
  c.drawPath(
    ui.Path()
      ..moveTo(70, -146)
      ..quadraticBezierTo(128, -150, 140, -104)
      ..quadraticBezierTo(146, -84, 134, -76)
      ..quadraticBezierTo(138, -96, 124, -104)
      ..quadraticBezierTo(126, -88, 116, -84)
      ..quadraticBezierTo(116, -110, 70, -120)
      ..close(),
    p,
  );
  // At kuyruğu: kafanın arka üstünde bağlı; dolgun, uçları kıvrık.
  c.save();
  c.translate(-128, -50);
  c.rotate(tail);
  c.drawPath(
    ui.Path()
      ..moveTo(10, -26)
      ..quadraticBezierTo(-60, -66, -118, -24)
      ..quadraticBezierTo(-166, 18, -160, 104)
      ..quadraticBezierTo(-178, 130, -196, 134) // uç 1
      ..quadraticBezierTo(-160, 152, -136, 126)
      ..quadraticBezierTo(-138, 170, -160, 196) // uç 2
      ..quadraticBezierTo(-112, 182, -100, 136)
      ..quadraticBezierTo(-90, 160, -70, 168) // uç 3
      ..quadraticBezierTo(-84, 120, -80, 60)
      ..quadraticBezierTo(-70, 10, 12, 20)
      ..close(),
    p,
  );
  // Fiyonk.
  c.drawPath(
    ui.Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-16, -60, -50, -36)
      ..quadraticBezierTo(-58, 0, 0, 0)
      ..moveTo(0, 0)
      ..quadraticBezierTo(40, -54, 56, -20)
      ..quadraticBezierTo(44, 14, 0, 0)
      ..moveTo(0, 0)
      ..lineTo(-26, 46)
      ..lineTo(-12, 50)
      ..close()
      ..moveTo(0, 0)
      ..lineTo(14, 48)
      ..lineTo(28, 42)
      ..close(),
    p,
  );
  c.drawCircle(ui.Offset.zero, 16, p);
  c.restore();
}

/// Elbise: dar omuzdan geniş çan eteğe; etek ucu hafif kavisli. Merkez
/// omuzların ortası (0, 0).
void _dress(ui.Canvas c, ui.Paint p, {double flare = 0}) {
  c.drawPath(
    ui.Path()
      ..moveTo(-44, -10)
      ..quadraticBezierTo(0, -24, 50, -10)
      ..quadraticBezierTo(84, 2, 86, 40) // ön omuz
      ..quadraticBezierTo(150 + flare, 220, 196 + flare, 350) // ön etek
      ..quadraticBezierTo(80, 386, -30, 374)
      ..quadraticBezierTo(-130, 366, -176 - flare, 344) // etek ucu
      ..quadraticBezierTo(-110 - flare, 210, -76, 40) // arka etek
      ..quadraticBezierTo(-74, 4, -44, -10) // arka omuz
      ..close(),
    p,
  );
}

void _jarAt(ui.Canvas c, ui.Offset hand) {
  final j = hand + const ui.Offset(6, 92);
  c.drawCircle(j, 260, ui.Paint()..shader = ui.Gradient.radial(j, 260, [_jar.withValues(alpha: 0.30), _jar.withValues(alpha: 0)]));
  c.drawLine(hand, j + const ui.Offset(0, -58), ui.Paint()
    ..color = _ink
    ..strokeWidth = 8);
  final body = ui.RRect.fromRectAndRadius(ui.Rect.fromCenter(center: j, width: 92, height: 106), const ui.Radius.circular(32));
  c.drawRRect(body, _p(_jar));
  c.drawRRect(body, ui.Paint()
    ..color = const ui.Color(0xFF2A1810)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 10);
  c.drawRRect(
    ui.RRect.fromRectAndRadius(ui.Rect.fromCenter(center: j + const ui.Offset(0, -58), width: 72, height: 20), const ui.Radius.circular(8)),
    _p(const ui.Color(0xFF2A1810)),
  );
  for (final d in const [ui.Offset(-18, 10), ui.Offset(20, -14), ui.Offset(8, 30), ui.Offset(-22, -24)]) {
    c.drawCircle(j + d, 9, _p(const ui.Color(0xFFFFF6E0)));
  }
}

/// Oymalı kelebek kanadı: büyük üst, küçük alt kanat; oymalardan ışık geçer.
void _butterfly(ui.Canvas c) {
  final upper = ui.Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-60, -230, -230, -380)
    ..quadraticBezierTo(-380, -440, -410, -320)
    ..quadraticBezierTo(-430, -170, -280, -70)
    ..quadraticBezierTo(-150, 0, 0, 0)
    ..close();
  final lower = ui.Path()
    ..moveTo(0, 20)
    ..quadraticBezierTo(-190, 20, -280, 120)
    ..quadraticBezierTo(-340, 210, -250, 250)
    ..quadraticBezierTo(-130, 270, -60, 150)
    ..quadraticBezierTo(-20, 80, 0, 20)
    ..close();
  final both = ui.Path()
    ..addPath(upper, ui.Offset.zero)
    ..addPath(lower, ui.Offset.zero);
  c.saveLayer(both.getBounds().inflate(30), ui.Paint());
  c.drawPath(both, _p(_wing.withValues(alpha: 0.9)));
  c.drawPath(both, ui.Paint()
    ..color = _ink
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 14);
  final cut = ui.Paint()
    ..blendMode = ui.BlendMode.dstOut
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;
  for (final (a, b, ctl, w) in [
    (const ui.Offset(-70, -80), const ui.Offset(-280, -330), const ui.Offset(-130, -250), 28.0),
    (const ui.Offset(-130, -60), const ui.Offset(-360, -260), const ui.Offset(-230, -110), 26.0),
    (const ui.Offset(-190, -46), const ui.Offset(-340, -130), const ui.Offset(-280, -56), 20.0),
    (const ui.Offset(-60, 60), const ui.Offset(-230, 170), const ui.Offset(-110, 150), 24.0),
    (const ui.Offset(-110, 46), const ui.Offset(-260, 96), const ui.Offset(-200, 46), 18.0),
  ]) {
    c.drawPath(ui.Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(ctl.dx, ctl.dy, b.dx, b.dy), cut..strokeWidth = w);
  }
  final dot = ui.Paint()..blendMode = ui.BlendMode.dstOut;
  for (final (d, r) in const [
    (ui.Offset(-320, -370), 14.0),
    (ui.Offset(-375, -310), 12.0),
    (ui.Offset(-392, -240), 10.0),
    (ui.Offset(-372, -175), 8.0),
    (ui.Offset(-255, 205), 11.0),
    (ui.Offset(-290, 150), 8.0),
  ]) {
    c.drawCircle(d, r, dot);
  }
  c.restore();
}

enum _Pose { stand, glide }

void _saye(ui.Canvas c, _Pose pose, {required bool rim}) {
  final p = _p(rim ? _rim : _ink);
  final glide = pose == _Pose.glide;
  const neck = ui.Offset(430, 700);
  if (!rim && glide) {
    c.save();
    c.translate(390, 740);
    c.scale(0.72);
    _butterfly(c);
    c.restore();
  }
  // Arka kol.
  if (glide) {
    _limb(c, const ui.Offset(380, 740), const ui.Offset(220, 830), 40, 28, p);
    _hand(c, const ui.Offset(206, 838), 2.7, p);
  } else {
    _limb(c, const ui.Offset(380, 740), const ui.Offset(352, 900), 40, 28, p);
    _hand(c, const ui.Offset(350, 920), 1.7, p);
  }
  // Bacaklar.
  if (glide) {
    _leg(c, const ui.Offset(470, 1040), const ui.Offset(476, 1160), const ui.Offset(486, 1240), 0.25, p);
    _leg(c, const ui.Offset(380, 1040), const ui.Offset(320, 1150), const ui.Offset(220, 1120), 1.3, p);
  } else {
    _leg(c, const ui.Offset(384, 1040), const ui.Offset(380, 1170), const ui.Offset(378, 1290), 0, p);
    _leg(c, const ui.Offset(468, 1040), const ui.Offset(472, 1170), const ui.Offset(476, 1290), 0, p);
  }
  c.save();
  c.translate(neck.dx, neck.dy);
  _dress(c, p, flare: glide ? 30 : 0);
  c.restore();
  // Kısa boyun ve baş (hafif yukarı bakar).
  _limb(c, const ui.Offset(436, 670), const ui.Offset(432, 706), 60, 66, p);
  c.save();
  c.translate(420, 560);
  c.rotate(glide ? -0.18 : -0.08);
  _head(c, p, tail: glide ? -0.3 : 0);
  c.restore();
  // Ön kol ve kavanoz.
  if (glide) {
    _limb(c, const ui.Offset(486, 740), const ui.Offset(640, 790), 40, 28, p);
    _hand(c, const ui.Offset(660, 796), 0.3, p);
    if (!rim) _jarAt(c, const ui.Offset(672, 806));
  } else {
    _limb(c, const ui.Offset(486, 740), const ui.Offset(530, 880), 40, 28, p);
    _hand(c, const ui.Offset(536, 900), 1.4, p);
    if (!rim) _jarAt(c, const ui.Offset(542, 914));
  }
}

void _figure(ui.Canvas c, _Pose pose) {
  // İnce kenar ışığı (oyundaki gibi): ışığa doğru kaydırılmış siluet.
  c.save();
  c.translate(5, -4);
  _saye(c, pose, rim: true);
  c.restore();
  _saye(c, pose, rim: false);
}

void main() {
  setUpAll(yaziTipiYukle);
  test('Sâye siluet', () async {
    const cellW = 560.0;
    const cellH = 520.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, cellW * 2, cellH), _p(const ui.Color(0xFF2A1A12)));
    for (final (i, pose, label) in [(0, _Pose.stand, 'Duruş'), (1, _Pose.glide, 'Kanatlı süzülüş')]) {
      final o = ui.Offset(i * cellW, 0);
      final mid = o + const ui.Offset(cellW * 0.42, cellH * 0.5);
      c.drawCircle(mid, 250, ui.Paint()..shader = ui.Gradient.radial(mid, 250, const [ui.Color(0xFF6A4428), ui.Color(0x002A1A12)]));
      final floor = o.dy + cellH - 40;
      c.drawLine(ui.Offset(o.dx + 20, floor), ui.Offset(o.dx + cellW - 20, floor), _p(const ui.Color(0xFF8A6A4A))..strokeWidth = 1.2);
      // Çizim uzayında boy: 410 (baş tepesi) .. 1382 (çizme altı).
      final big = pose == _Pose.glide ? 0.37 : 0.42;
      final lift = pose == _Pose.glide ? 20.0 : 0.0;
      c.save();
      c.translate(o.dx + 40, floor - 1382 * big - lift);
      c.scale(big);
      _figure(c, pose);
      c.restore();
      // Oyundaki boyutu: perdede ~56 piksel boy.
      const small = 0.058;
      c.save();
      c.translate(o.dx + cellW - 90, floor - 1382 * small - lift * 0.15);
      c.scale(small);
      _figure(c, pose);
      c.restore();
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 20, fontFamily: 'Roboto'))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFE0D0B0)))
        ..addText(label);
      c.drawParagraph(pb.build()..layout(const ui.ParagraphConstraints(width: cellW)), o + const ui.Offset(14, 10));
      final pb2 = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13, fontFamily: 'Roboto'))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFB09878)))
        ..addText('oyunda');
      c.drawParagraph(pb2.build()..layout(const ui.ParagraphConstraints(width: 80)), ui.Offset(o.dx + cellW - 80, floor + 8));
    }
    final img = await rec.endRecording().toImage((cellW * 2).toInt(), cellH.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/saye_siluet.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
