// Kapadokya zemininin renk ve doku katmanı (CARTOON açıkken): Kule ve kar
// bölümlerindeki kâğıt oyma dil. Yumuşak tüf kat kat çökelti bantlarıyla
// iner; açık yüzlerde güvercinlik oyukları ve aşınma yarıkları, güneşe
// bakan kenarda gün batımı ışığı, üstte ufalanan açık renk tüf dudağı.
// Karanlık korunur: renk yalnız yüzeye yakın karolarda, derine indikçe
// mürekkebe döner.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _sun = Color(0xFFFFC890);

void paintPeriTile(Canvas c, Level lv, int col, int row, double x, double y) {
  const t = kTile;
  var depth = 0;
  while (depth < 4 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  final top = row > 0 && !lv.solid(col, row - 1);
  final left = !lv.solid(col - 1, row);
  final right = !lv.solid(col + 1, row);
  var side = 4;
  for (var k = 0; k < 4; k++) {
    if (!lv.solid(col - k - 1, row) || !lv.solid(col + k + 1, row)) {
      side = k;
      break;
    }
  }
  final near = math.min(depth, side);
  final seed = col * 7919 + row * 104729;
  if (near < 4) {
    final a = 1 - near / 4;
    final tile = Rect.fromLTWH(x, y, t, t);
    c.save();
    c.clipRect(tile);
    c.drawRect(
      tile,
      Paint()..color = const Color(0xFF2E1D15).withValues(alpha: 0.7 * a),
    );
    // Çökelti bantları: dünyada süren dalgalı şeritler, biri açık; aradaki
    // dikiş yer yer kopuk.
    const gap = 9.0;
    final band = Paint()
      ..color = const Color(0xFF4A3024).withValues(alpha: 0.4 * a);
    final seam = Paint()
      ..color = const Color(0xFF0E0806).withValues(alpha: 0.7 * a)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var n = ((y - 8) / gap).floor(); n * gap < y + t + 8; n++) {
      double ly(double wx) =>
          n * gap +
          math.sin(wx * 0.04 + n * 1.7) * 2.2 +
          math.sin(wx * 0.17 + n) * 0.6;
      if (_hash(n, 3) < 0.5) {
        final bp = Path()..moveTo(x, ly(x));
        for (var dx = 4.0; dx <= t; dx += 4) {
          bp.lineTo(x + dx, ly(x + dx));
        }
        for (var dx = t; dx >= 0; dx -= 4) {
          bp.lineTo(x + dx, ly(x + dx) + gap * 0.45);
        }
        bp.close();
        c.drawPath(bp, band);
      }
      for (var dx = 0.0; dx < t; dx += 4) {
        final wx = x + dx;
        if (math.sin(wx * 0.11 + n * 3.1) < -0.3) continue;
        c.drawLine(Offset(wx, ly(wx)), Offset(wx + 4, ly(wx + 4)), seam);
      }
    }
    // Ufak oyuklar.
    final pock = Paint()
      ..color = const Color(0xFF0E0806).withValues(alpha: 0.6 * a);
    for (var i = 0; i < 2; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(
            x + 4 + _hash(seed, i) * (t - 8),
            y + 4 + _hash(seed, i + 9) * (t - 8),
          ),
          width: 2.5 + _hash(seed, i + 4) * 2,
          height: 1.8,
        ),
        pock,
      );
    }
    c.restore();
  }
  // Açık yan yüzde aşınma yarığı ve güvercinlik oyuğu.
  if ((left || right) && depth >= 1) {
    final ex = left ? x : x + t;
    final dir = left ? 1.0 : -1.0;
    if (_hash(seed, 21) < 0.5) {
      var gx = ex + dir * (4 + _hash(seed, 22) * 6);
      var gy = y;
      final g = Path()..moveTo(gx, gy);
      for (var s = 0; s < 4; s++) {
        gx += (_hash(seed, 30 + s) - 0.5) * 3;
        gy += t / 4;
        g.lineTo(gx, gy);
      }
      c.drawPath(
        g,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = const Color(0xFF0E0806).withValues(alpha: 0.75),
      );
    }
    if (_hash(seed, 23) < 0.15) {
      final hx = ex + dir * (10 + _hash(seed, 24) * 8);
      final hole = RRect.fromRectAndCorners(
        Rect.fromLTWH(hx - 3.5, y + 9, 7, 10),
        topLeft: const Radius.circular(3.5),
        topRight: const Radius.circular(3.5),
      );
      c.drawRRect(hole, Paint()..color = const Color(0xFF050302));
      c.drawLine(
        Offset(hx - 4.5, y + 19.6),
        Offset(hx + 4.5, y + 19.6),
        Paint()
          ..color = _sun.withValues(alpha: 0.3)
          ..strokeWidth = 1.2,
      );
    }
  }
  if (left) {
    c.drawLine(
      Offset(x + 0.7, y + (top ? 5 : 0)),
      Offset(x + 0.7, y + t),
      Paint()
        ..color = _sun.withValues(alpha: 0.2)
        ..strokeWidth = 1.2,
    );
  }
  if (!top) return;
  // Üstte ufalanan açık tüf dudağı: alt kenarı dünyada kesintisiz dalgalı,
  // üst kenarı gün batımında.
  double lower(double wx) =>
      y + 4.5 + math.sin(wx * 0.23) * 1.2 + math.sin(wx * 0.09 + 2) * 1.0;
  double upper(double wx) =>
      y -
      1 -
      math.max(0, math.sin(wx * 0.07)) * 1.6 -
      math.max(0, math.sin(wx * 0.29)) * 0.8;
  final x0 = left ? x - 1.5 : x - 0.5;
  final x1 = right ? x + t + 1.5 : x + t + 0.5;
  final lip = Path()..moveTo(x0, upper(x0));
  for (var wx = x0; wx <= x1; wx += 2) {
    lip.lineTo(wx, upper(wx));
  }
  lip.lineTo(x1, upper(x1));
  if (right) lip.quadraticBezierTo(x1 + 1, y + 2, x1 - 1.5, y + 6);
  for (var wx = x1 - 1; wx >= x0; wx -= 2) {
    lip.lineTo(wx, lower(wx));
  }
  if (left) lip.quadraticBezierTo(x0 - 1, y + 2, x0, upper(x0));
  lip.close();
  c.drawPath(lip, Paint()..color = const Color(0xFF5A3C2C));
  final rim = Path()..moveTo(x0, upper(x0));
  for (var wx = x0; wx <= x1; wx += 2) {
    rim.lineTo(wx, upper(wx));
  }
  c.drawPath(
    rim,
    Paint()
      ..color = _sun.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke,
  );
  // Kenardan kopan ufak taneler.
  if (right && _hash(seed, 40) < 0.7) {
    c.drawCircle(
      Offset(x + t + 1 + _hash(seed, 41) * 2, y + 9 + _hash(seed, 42) * 6),
      1.2,
      Paint()..color = const Color(0xFF5A3C2C),
    );
  }
}
