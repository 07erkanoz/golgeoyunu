// Erlik'in katının renk ve doku katmanları (CARTOON açıkken): kâğıt oyma
// dil, ama karanlık oyunun kendisi; hiçbir katman sahneyi aydınlatmaz.
// Uzakta kara taştan, sivri burçlu Erlik sarayı; ortada yeraltı ırmağının
// soğuk ışığını yakalayan obsidyen sivriler; tavandan sarkan kayalar ve
// zincirle sarkan kafeslerde kut ışıkları. Işık aşağıdan, ırmaktan gelir.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';
import 'palette.dart' show glowDot;

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _rim = Color(0xFF8A7ACF);
const _river = Color(0xFF6A8AE0);
final _drop = Paint()..color = const Color(0x66000000);

void paintErlikBackdrop(
  Canvas c,
  double w,
  double h,
  double camX,
  double camY,
  double t, {
  bool lights = true,
}) {
  final dy = -camY * 0.05;
  _palace(c, w, h, camX * 0.05, dy);
  _riverGlow(c, w, h, camX * 0.12, dy, t);
  _spires(c, w, h, camX * 0.2, dy, const Color(0xFF130D1E), 0.75, 3);
  if (lights) _cages(c, w, h, camX * 0.2, dy, t);
  _ceiling(c, w, h, camX * 0.3, dy);
  _spires(c, w, h, camX * 0.35, dy, const Color(0xFF0C0814), 1.0, 8);
}

/// Erlik'in sarayı: kara taştan, sivri burçlu; kapısı kapalı, mazgallarında
/// ışık yok.
void _palace(Canvas c, double w, double h, double off, double dy) {
  const span = 1400.0;
  for (var i = ((off - span) / span).floor(); i * span - off < w + span; i++) {
    final cx = i * span - off + span * (0.3 + _hash(i, 1) * 0.4);
    final base = h * 0.72 + dy;
    final p = Path();
    // Sur ve burçlar.
    p.addRect(Rect.fromLTRB(cx - 150, base - 70, cx + 150, base + 40));
    for (var k = -3; k <= 3; k++) {
      final bx = cx + k * 46;
      final bh = 90 + (3 - k.abs()) * 38.0 + _hash(i * 7 + k, 2) * 20;
      final bw = 16 + (3 - k.abs()) * 3.0;
      p
        ..addRect(Rect.fromLTRB(bx - bw / 2, base - bh, bx + bw / 2, base))
        ..addPath(
          Path()
            ..moveTo(bx - bw / 2 - 3, base - bh)
            ..lineTo(bx, base - bh - bw * 2.2)
            ..lineTo(bx + bw / 2 + 3, base - bh)
            ..close(),
          Offset.zero,
        );
    }
    c.drawPath(p, Paint()..color = const Color(0xFF150F22));
    // Kapı: kapalı, sivri kemer; tepesinde ırmağın soluk yansıması.
    final gate = Path()
      ..moveTo(cx - 18, base)
      ..lineTo(cx - 18, base - 34)
      ..quadraticBezierTo(cx, base - 58, cx + 18, base - 34)
      ..lineTo(cx + 18, base)
      ..close();
    c.drawPath(gate, Paint()..color = const Color(0xFF07050C));
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _rim.withValues(alpha: 0.14),
    );
  }
}

/// Yeraltı ırmağı: dipte ağır ağır kıpırdayan soğuk ışık çizgileri.
void _riverGlow(Canvas c, double w, double h, double off, double dy, double t) {
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 4; k++) {
    final y0 = h * (0.8 + k * 0.035) + dy;
    line.color = _river.withValues(alpha: 0.16 - k * 0.03);
    final p = Path();
    var pen = false;
    for (var x = 0.0; x <= w; x += 6) {
      final u = x + off * (1 + k * 0.2);
      if (math.sin(u * 0.021 + k * 2 + t * 0.3) < 0.1) {
        pen = false;
        continue;
      }
      final y = y0 + math.sin(u * 0.05 + t * 0.8 + k) * 1.5;
      if (pen) {
        p.lineTo(x, y);
      } else {
        p.moveTo(x, y);
        pen = true;
      }
    }
    c.drawPath(p, line);
  }
}

/// Obsidyen sivriler: köşeli, kırık uçlu; ırmağa bakan sol yüzleri soğuk
/// ışığı yakalar, gövdelerinde kırık yüzey çizgileri.
void _spires(
  Canvas c,
  double w,
  double h,
  double off,
  double dy,
  Color body,
  double s,
  int salt,
) {
  final spacing = 150.0 * s;
  final fill = Paint()..color = body;
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeJoin = StrokeJoin.bevel
    ..color = _rim.withValues(alpha: 0.32 * s);
  final facet = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = _rim.withValues(alpha: 0.1 * s);
  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    if (_hash(i, salt) < 0.3) continue;
    final x = i * spacing - off + _hash(i, salt + 1) * spacing * 0.5;
    final base = h * (0.86 + 0.04 * s) + dy;
    final sh = (90 + _hash(i, salt + 2) * 150) * s;
    final sw = (22 + _hash(i, salt + 3) * 26) * s;
    final lean = (_hash(i, salt + 4) - 0.5) * sw * 0.8;
    // Köşeli gövde: iki yanda kırıklı kenarlar, kırık uç.
    final tip = Offset(x + lean, base - sh);
    final l1 = Offset(x - sw * 0.55, base - sh * 0.35);
    final l2 = Offset(x - sw * 0.25, base - sh * 0.72);
    final r1 = Offset(x + sw * 0.5, base - sh * 0.4);
    final r2 = Offset(x + sw * 0.2, base - sh * 0.78);
    final broke = _hash(i, salt + 5) < 0.4;
    final tipL = broke ? tip + Offset(-sw * 0.12, sh * 0.04) : tip;
    final tipR = broke ? tip + Offset(sw * 0.1, sh * 0.07) : tip;
    final p = Path()
      ..moveTo(x - sw, base + 40)
      ..lineTo(x - sw, base)
      ..lineTo(l1.dx, l1.dy)
      ..lineTo(l2.dx, l2.dy)
      ..lineTo(tipL.dx, tipL.dy)
      ..lineTo(tipR.dx, tipR.dy)
      ..lineTo(r2.dx, r2.dy)
      ..lineTo(r1.dx, r1.dy)
      ..lineTo(x + sw, base)
      ..lineTo(x + sw, base + 40)
      ..close();
    c.save();
    c.translate(3, 4);
    c.drawPath(p, _drop);
    c.restore();
    c.drawPath(p, fill);
    // Yüzey kırıkları: uçtan dibe inen iki köşeli çizgi.
    c.drawPath(
      Path()
        ..moveTo(tipL.dx, tipL.dy)
        ..lineTo(x - sw * 0.05, base - sh * 0.5)
        ..lineTo(x - sw * 0.3, base),
      facet,
    );
    c.drawPath(
      Path()
        ..moveTo(r2.dx, r2.dy)
        ..lineTo(x + sw * 0.15, base - sh * 0.3),
      facet,
    );
    // Sol yüz ışığı.
    c.drawPath(
      Path()
        ..moveTo(x - sw, base)
        ..lineTo(l1.dx, l1.dy)
        ..lineTo(l2.dx, l2.dy)
        ..lineTo(tipL.dx, tipL.dy),
      rim,
    );
  }
}

/// Tavandan sarkan kara kayalar: alt kenarları ırmağın ışığını yakalar.
void _ceiling(Canvas c, double w, double h, double off, double dy) {
  const cw = 46.0;
  final p = Path()..moveTo(-10, 0);
  final edge = Path();
  var first = true;
  for (var i = ((off - cw) / cw).floor(); i * cw - off < w + cw * 2; i++) {
    final x = i * cw - off;
    final y = h * (0.05 + _hash(i, 41) * 0.05) + dy;
    final drip = _hash(i, 42) < 0.35;
    final pts = [
      Offset(x, y),
      if (drip) ...[
        Offset(x + cw * 0.3, y + 4),
        Offset(x + cw * 0.45, y + 26 + _hash(i, 43) * 34),
        Offset(x + cw * 0.6, y + 6),
      ],
    ];
    for (final pt in pts) {
      p.lineTo(pt.dx, pt.dy);
      if (first) {
        edge.moveTo(pt.dx, pt.dy);
        first = false;
      } else {
        edge.lineTo(pt.dx, pt.dy);
      }
    }
  }
  p
    ..lineTo(w + 10, 0)
    ..close();
  c.save();
  c.translate(3, 4);
  c.drawPath(p, _drop);
  c.restore();
  c.drawPath(p, Paint()..color = const Color(0xFF09060E));
  c.drawPath(
    edge,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.bevel
      ..color = _rim.withValues(alpha: 0.2),
  );
}

/// Kut Zindanı: zincirle sarkan kafeslerde, Erlik'in çaldığı canlar;
/// ağır ağır yanıp söner.
void _cages(Canvas c, double w, double h, double off, double dy, double t) {
  const spacing = 260.0;
  final bar = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xFF07050C);
  final chain = Paint()
    ..strokeWidth = 1
    ..color = const Color(0xFF07050C);
  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    if (_hash(i, 51) < 0.35) continue;
    final x = i * spacing - off + _hash(i, 52) * spacing * 0.6;
    final y = h * (0.26 + _hash(i, 53) * 0.2) + dy + math.sin(t * 0.4 + i) * 4;
    final a = 0.25 + 0.2 * math.sin(t * 0.9 + i * 1.7);
    c.drawLine(Offset(x, 0), Offset(x, y - 14), chain);
    glowDot(c, Offset(x, y), 14, const Color(0xFFFFE8B0), a);
    // Kafes: yuvarlak tepe, dikey çubuklar, taban.
    final r = Rect.fromCenter(center: Offset(x, y), width: 18, height: 26);
    c.drawArc(
      Rect.fromLTWH(r.left, r.top, r.width, 14),
      math.pi,
      math.pi,
      false,
      bar,
    );
    for (var k = 0; k <= 3; k++) {
      final bx = r.left + k * r.width / 3;
      c.drawLine(Offset(bx, r.top + 7), Offset(bx, r.bottom), bar);
    }
    c.drawLine(
      Offset(r.left - 2, r.bottom),
      Offset(r.right + 2, r.bottom),
      bar..strokeWidth = 2,
    );
    bar.strokeWidth = 1.2;
  }
}

/// Zemin: kara obsidyen. Dünyada süren köşeli yüzey kırıkları, soğuk
/// parıltılı ince kenarlar; yüzeye yakın mor-kara, derinde mürekkep. Sol
/// kenar ve üst yüz ırmağın ışığını alır.
void paintErlikTile(Canvas c, Level lv, int col, int row, double x, double y) {
  const t = kTile;
  var depth = 0;
  while (depth < 3 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  final top = row > 0 && !lv.solid(col, row - 1);
  final left = !lv.solid(col - 1, row);
  if (depth < 3) {
    final a = 1 - depth / 3;
    final tile = Rect.fromLTWH(x, y, t, t);
    c.save();
    c.clipRect(tile);
    c.drawRect(
      tile,
      Paint()..color = const Color(0xFF17102A).withValues(alpha: 0.6 * a),
    );
    // Köşeli yüzeyler: 24'lük dünya ızgarasında oynatılmış noktaları
    // birleştiren kırık çizgiler (her karo komşusuyla aynı noktaları
    // kullanır, çizgiler kesintisiz sürer).
    const g = 24.0;
    Offset pt(int i, int j) => Offset(
      i * g + (_hash(i * 31 + j, 61) - 0.5) * g * 0.7,
      j * g + (_hash(i * 17 + j, 62) - 0.5) * g * 0.7,
    );
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF040208).withValues(alpha: 0.85 * a);
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _rim.withValues(alpha: 0.16 * a);
    final i0 = (x / g).floor() - 1;
    final j0 = (y / g).floor() - 1;
    for (var i = i0; i <= i0 + 3; i++) {
      for (var j = j0; j <= j0 + 3; j++) {
        final p0 = pt(i, j);
        final right = pt(i + 1, j);
        final down = _hash(i * 13 + j, 63) < 0.5
            ? pt(i, j + 1)
            : pt(i + 1, j + 1);
        c.drawLine(p0, right, crack);
        c.drawLine(p0, down, crack);
        c.drawLine(p0 + const Offset(0, 1), right + const Offset(0, 1), glint);
      }
    }
    c.restore();
  }
  if (left) {
    c.drawLine(
      Offset(x + 0.7, y + (top ? 3 : 0)),
      Offset(x + 0.7, y + t),
      Paint()
        ..color = _rim.withValues(alpha: 0.2)
        ..strokeWidth = 1.1,
    );
  }
  if (top) {
    // Keskin üst kenar: kırık kırık, soğuk ışıkta.
    final p = Path()..moveTo(x, y + 0.5);
    for (var dx = 4.0; dx <= t; dx += 4) {
      final wx = x + dx;
      p.lineTo(wx, y + 0.5 + (_hash(wx.round(), 64) - 0.5) * 1.4);
    }
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _rim.withValues(alpha: 0.4),
    );
  }
}
