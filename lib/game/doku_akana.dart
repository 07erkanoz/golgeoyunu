// Ak Ana'nın Denizi'nin renk ve doku katmanları (CARTOON açıkken): kâğıt
// oyma dil, su altında. Uzakta dipten yükselen kaya kuleleri ve kemerler,
// ortada salınan su yosunu ormanı ve mercan yelpazeleri, en yakında
// dipteki kaya sırtı. Işık yukarıdan, su yüzünden süzülür: kenar ışığı
// yalnız üstlerde. Bulanıklık yok.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _surface = Color(0xFFBFE6E0);
final _drop = Paint()..color = const Color(0x40000000);

/// Suyun içinde, ekranı kaplayan [w]x[h] alanda (dünya biriminde de
/// çalışır); [water]: o derinlikteki suyun rengi, katmanlar ondan koyulur.
void paintAkAnaBackdrop(
  Canvas c,
  double w,
  double h,
  double camX,
  double camY,
  double t, {
  required Color water,
}) {
  final dy = -camY * 0.04;
  Color tone(double k) => Color.lerp(water, const Color(0xFF000000), k)!;
  _stacks(c, w, h, camX * 0.05, dy, tone(0.22), 0.16, 0.7, 5);
  _stacks(c, w, h, camX * 0.1, dy, tone(0.38), 0.24, 1.0, 9);
  _kelp(c, w, h, camX * 0.18, dy, t, tone(0.5), 0.8, 3);
  _fans(c, w, h, camX * 0.22, dy, tone(0.55));
  _kelp(c, w, h, camX * 0.3, dy, t, tone(0.68), 1.1, 7);
}

/// Dipten yükselen kaya kuleleri; arada bir kemer. Tepeleri ışık alır.
void _stacks(
  Canvas c,
  double w,
  double h,
  double off,
  double dy,
  Color body,
  double rimA,
  double s,
  int salt,
) {
  final spacing = 220.0 * s;
  final fill = Paint()..color = body;
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeJoin = StrokeJoin.round
    ..color = _surface.withValues(alpha: rimA);
  final base = h * (0.8 + 0.08 * s) + dy;
  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    if (_hash(i, salt) < 0.25) continue;
    final x = i * spacing - off + _hash(i, salt + 1) * spacing * 0.4;
    final sh = h * (0.25 + _hash(i, salt + 2) * 0.3) * s;
    final sw = (30 + _hash(i, salt + 3) * 40) * s;
    final arch = _hash(i, salt + 4) < 0.3;
    // Dalgalı, aşınmış kenarlı kule.
    final left = <Offset>[];
    final right = <Offset>[];
    const n = 8;
    for (var k = 0; k <= n; k++) {
      final f = k / n;
      final y = base - sh * f;
      final taper = 1 - f * 0.45;
      final wob = math.sin(f * 9 + i) * sw * 0.08;
      left.add(Offset(x - sw * taper + wob, y));
      right.add(Offset(x + sw * taper * 0.9 + wob * 0.6, y));
    }
    final p = Path()..moveTo(left.first.dx, base + 40);
    for (final q in left) {
      p.lineTo(q.dx, q.dy);
    }
    // Tepe: yuvarlak, düzensiz.
    final tl = left.last;
    final tr = right.last;
    p.quadraticBezierTo((tl.dx + tr.dx) / 2, tl.dy - sw * 0.35, tr.dx, tr.dy);
    for (final q in right.reversed) {
      p.lineTo(q.dx, q.dy);
    }
    p
      ..lineTo(right.first.dx, base + 40)
      ..close();
    if (arch) {
      // Kemer: kulenin dibinde oyuk (ardındaki su görünür).
      p
        ..fillType = PathFillType.evenOdd
        ..addOval(
          Rect.fromCenter(
            center: Offset(x, base - sh * 0.12),
            width: sw * 1.1,
            height: sh * 0.4,
          ),
        );
    }
    c.save();
    c.translate(3, 4);
    c.drawPath(p, _drop);
    c.restore();
    c.drawPath(p, fill);
    // Oyma katman çizgileri.
    final carve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.lerp(body, const Color(0xFF000000), 0.35)!;
    for (var k = 2; k < n; k += 2) {
      final a = Offset.lerp(left[k], right[k], 0.15)!;
      final b = Offset.lerp(left[k], right[k], 0.7)!;
      c.drawLine(a, b + Offset(0, (_hash(i * 9 + k, salt) - 0.5) * 4), carve);
    }
    final top = Path()..moveTo(left[n - 2].dx, left[n - 2].dy);
    top
      ..lineTo(tl.dx, tl.dy)
      ..quadraticBezierTo((tl.dx + tr.dx) / 2, tl.dy - sw * 0.35, tr.dx, tr.dy);
    c.drawPath(top, rim);
  }
}

/// Su yosunu: dipten yükselen, akıntıyla salınan uzun saplar; sap boyunca
/// yaprakçıklar. Uçları ışığı yakalar.
void _kelp(
  Canvas c,
  double w,
  double h,
  double off,
  double dy,
  double t,
  Color body,
  double s,
  int salt,
) {
  final spacing = 46.0 * s;
  final stem = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.2 * s
    ..color = body;
  final leaf = Paint()..color = body;
  final tipLight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1
    ..color = _surface.withValues(alpha: 0.18 * s);
  final base = h + 6;
  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    if (_hash(i, salt) < 0.35) continue;
    final x0 = i * spacing - off + _hash(i, salt + 1) * spacing * 0.6;
    final len = h * (0.25 + _hash(i, salt + 2) * 0.35) * s;
    final ph = _hash(i, salt + 3) * 6;
    const n = 12;
    final pts = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final f = k / n;
      final sway = math.sin(t * 0.8 + ph + f * 2.5) * 14 * f * f * s;
      pts.add(Offset(x0 + sway, base + dy - len * f));
    }
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    c.drawPath(p, stem);
    for (var k = 2; k < n; k += 2) {
      final q = pts[k];
      final side = k % 4 == 0 ? 1.0 : -1.0;
      final lw = 10 * s * (1 - k / n * 0.5);
      c.drawPath(
        Path()
          ..moveTo(q.dx, q.dy)
          ..quadraticBezierTo(
            q.dx + side * lw,
            q.dy - lw * 0.9,
            q.dx + side * lw * 0.4,
            q.dy - lw * 1.6,
          )
          ..quadraticBezierTo(q.dx + side * 1, q.dy - lw * 0.6, q.dx, q.dy)
          ..close(),
        leaf,
      );
    }
    c.drawLine(pts[n - 1], pts[n], tipLight);
  }
}

/// Mercan yelpazeleri: dipte, dallanan ince kâğıt oyma yelpazeler.
void _fans(Canvas c, double w, double h, double off, double dy, Color body) {
  const spacing = 180.0;
  final branch = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = body;
  final base = h * 0.98 + dy;
  void grow(Offset o, double a, double len, int depth, int seed) {
    if (depth == 0) return;
    final e = o + Offset(math.cos(a), math.sin(a)) * len;
    branch.strokeWidth = 0.8 + depth * 0.6;
    c.drawLine(o, e, branch);
    for (final s in [-1.0, 1.0]) {
      grow(
        e,
        a + s * (0.35 + _hash(seed, depth) * 0.25),
        len * 0.72,
        depth - 1,
        seed * 3 + (s > 0 ? 1 : 2),
      );
    }
  }

  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    if (_hash(i, 61) < 0.4) continue;
    final x = i * spacing - off + _hash(i, 62) * spacing * 0.6;
    grow(
      Offset(x, base),
      -math.pi / 2 + (_hash(i, 63) - 0.5) * 0.4,
      22 + _hash(i, 64) * 12,
      5,
      i,
    );
  }
}

/// Zemin: denizin aşındırdığı kaya. Dünyada süren yumuşak katmanlar, su
/// oyuğu delikler, midye kabukları; üst kenar su yüzünün ışığını alır.
void paintAkAnaTile(Canvas c, Level lv, int col, int row, double x, double y) {
  const t = kTile;
  var depth = 0;
  while (depth < 3 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  final top = row > 0 && !lv.solid(col, row - 1);
  final left = !lv.solid(col - 1, row);
  final right = !lv.solid(col + 1, row);
  final seed = col * 7919 + row * 104729;
  if (depth < 3) {
    final a = 1 - depth / 3;
    final tile = Rect.fromLTWH(x, y, t, t);
    c.save();
    c.clipRect(tile);
    c.drawRect(
      tile,
      Paint()..color = const Color(0xFF10262A).withValues(alpha: 0.65 * a),
    );
    final strata = Paint()
      ..color = const Color(0xFF040C0E).withValues(alpha: 0.6 * a)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    const gap = 12.0;
    for (var n = ((y - 6) / gap).floor(); n * gap < y + t + 6; n++) {
      double ly(double wx) => n * gap + math.sin(wx * 0.03 + n * 1.7) * 3;
      for (var dx = 0.0; dx < t; dx += 4) {
        final wx = x + dx;
        if (math.sin(wx * 0.06 + n * 2.1) < -0.25) continue;
        c.drawLine(Offset(wx, ly(wx)), Offset(wx + 4, ly(wx + 4)), strata);
      }
    }
    // Su oyuğu delikler: içi karanlık, alt dudağı ışıkta.
    for (var k = 0; k < 2; k++) {
      if (_hash(seed, k) < 0.5) continue;
      final o = Offset(
        x + 5 + _hash(seed, k + 2) * (t - 10),
        y + 8 + _hash(seed, k + 4) * (t - 14),
      );
      final r = 1.6 + _hash(seed, k + 6) * 2.2;
      c.drawCircle(
        o,
        r,
        Paint()..color = const Color(0xFF020607).withValues(alpha: 0.9 * a),
      );
      c.drawArc(
        Rect.fromCircle(center: o, radius: r + 0.6),
        math.pi * 0.2,
        math.pi * 0.6,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _surface.withValues(alpha: 0.2 * a),
      );
    }
    c.restore();
  }
  if (left || right) {
    final ex = left ? x + 0.7 : x + t - 0.7;
    c.drawLine(
      Offset(ex, y + (top ? 4 : 0)),
      Offset(ex, y + t),
      Paint()
        ..color = _surface.withValues(alpha: 0.1)
        ..strokeWidth = 1,
    );
  }
  if (!top) return;
  // Üst kenar: su yüzünün ışığı; üstünde birkaç midye kabuğu.
  c.drawLine(
    Offset(x, y + 0.6),
    Offset(x + t, y + 0.6),
    Paint()
      ..color = _surface.withValues(alpha: 0.35)
      ..strokeWidth = 1.1,
  );
  for (var k = 0; k < 2; k++) {
    if (_hash(seed, 20 + k) < 0.55) continue;
    final sx = x + 4 + _hash(seed, 22 + k) * (t - 8);
    final shell = Path()
      ..moveTo(sx - 3, y + 1)
      ..quadraticBezierTo(sx - 2.5, y - 3, sx, y - 3.2)
      ..quadraticBezierTo(sx + 2.5, y - 3, sx + 3, y + 1)
      ..close();
    c.drawPath(shell, Paint()..color = const Color(0xFF1A3438));
    c.drawLine(
      Offset(sx - 1.5, y - 2.4),
      Offset(sx + 0.5, y - 2.9),
      Paint()
        ..color = _surface.withValues(alpha: 0.4)
        ..strokeWidth = 0.8,
    );
  }
}
