// Ötüken Ormanı'nın renk ve doku katmanları (CARTOON açıkken): Kule ve kar
// bölümlerindeki kâğıt oyma dil. Gövdelerde oyma kabuk yarıkları, kök
// çıkıntısı ve güneşe bakan kenarda ılık ışık; yaprak tavanında oyma yaprak
// damarları ve alt kenarda süzülen yeşil ışık; zeminde kök sarmış toprak ve
// yosunlu çim örtüsü. Bulanıklık yok.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _sun = Color(0xFFFFF2B0);
const _leafLight = Color(0xFF8AB070);
final _drop = Paint()..color = const Color(0x40000000);

/// Gövdenin gölgesi (çizimden önce).
void paintTrunkShadow(Canvas c, Path trunk) {
  c.save();
  c.translate(3, 4);
  c.drawPath(trunk, _drop);
  c.restore();
}

/// Gövdenin dokusu (çizimden sonra): kabuk yarıkları, kök çıkıntısı,
/// güneşe bakan sağ kenarda ışık. [x0]/[x1]: tabandaki sol/sağ, [t0]/[t1]:
/// tepedeki sol/sağ.
void paintTrunkBark(
  Canvas c,
  Offset b0,
  Offset b1,
  Offset t0,
  Offset t1,
  Color body,
  double scale,
  int seed, {
  required bool birch,
}) {
  final groove = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2 * scale
    ..strokeCap = StrokeCap.round
    ..color = Color.lerp(body, const Color(0xFF000000), 0.4)!;
  if (!birch) {
    // Kabuk yarıkları: gövde boyunca inen, yer yer kopan dalgalı çizgiler.
    for (var k = 1; k <= 3; k++) {
      final f = k / 4 + (_hash(seed, k) - 0.5) * 0.08;
      final p = Path();
      var pen = false;
      for (var s = 0; s <= 30; s++) {
        final v = s / 30;
        final l = Offset.lerp(b0, t0, v)!;
        final r = Offset.lerp(b1, t1, v)!;
        final q =
            Offset.lerp(l, r, f)! +
            Offset(math.sin(v * 40 + k * 2 + seed) * 1.2 * scale, 0);
        if (math.sin(v * 23 + k * 3.7 + seed) < -0.6) {
          pen = false;
          continue;
        }
        if (pen) {
          p.lineTo(q.dx, q.dy);
        } else {
          p.moveTo(q.dx, q.dy);
          pen = true;
        }
      }
      c.drawPath(p, groove);
    }
  } else {
    // Kayının gölgeli sol yanı.
    final shade = Path()
      ..moveTo(b0.dx, b0.dy)
      ..lineTo(t0.dx, t0.dy)
      ..lineTo(Offset.lerp(t0, t1, 0.3)!.dx, t0.dy)
      ..lineTo(Offset.lerp(b0, b1, 0.3)!.dx, b0.dy)
      ..close();
    c.drawPath(
      shade,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.16),
    );
  }
  // Kök çıkıntısı: tabanda iki yana yayılan kökler.
  final w = (b1.dx - b0.dx);
  final root = Paint()
    ..color = birch ? Color.lerp(body, const Color(0xFF000000), 0.5)! : body;
  for (final s in [-1.0, 1.0]) {
    final ex = s < 0 ? b0.dx : b1.dx;
    c.drawPath(
      Path()
        ..moveTo(ex, b0.dy - w * 0.9)
        ..quadraticBezierTo(
          ex + s * w * 0.15,
          b0.dy - w * 0.2,
          ex + s * w * 0.9,
          b0.dy + 2,
        )
        ..lineTo(ex - s * w * 0.1, b0.dy + 2)
        ..close(),
      root,
    );
  }
  // Güneşe bakan kenar.
  c.drawLine(
    b1 + Offset(-0.8 * scale, 0),
    t1 + Offset(-0.8 * scale, 0),
    Paint()
      ..strokeWidth = 1.2 * scale
      ..color = _sun.withValues(alpha: birch ? 0.3 : 0.2),
  );
}

/// Yaprak tavanı: oyma yaprak damarları (yaprak demetleri) ve alt kenarda
/// süzülen yeşil ışık. [lobes]: (merkez, yarıçap).
void paintCanopyDetail(Canvas c, List<(Offset, double)> lobes, Color body) {
  final vein = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = Color.lerp(body, const Color(0xFF000000), 0.35)!;
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..color = _leafLight.withValues(alpha: 0.35);
  for (var i = 0; i < lobes.length; i++) {
    final (o, r) = lobes[i];
    // Alt kenarda ışık.
    c.drawArc(
      Rect.fromCircle(center: o, radius: r - 0.7),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      rim,
    );
    // Oyma yaprak: ortadan inen damar ve iki yana çıkan kısa çizgiler.
    if (_hash(i, 5) < 0.5 || r < 22) continue;
    final a = math.pi * (0.35 + _hash(i, 6) * 0.3);
    final tip = o + Offset(math.cos(a), math.sin(a)) * r * 0.65;
    final root = o + Offset(math.cos(a), math.sin(a)) * -r * 0.2;
    c.drawLine(root, tip, vein);
    for (var k = 1; k <= 3; k++) {
      final m = Offset.lerp(root, tip, k / 4)!;
      for (final s in [-1.0, 1.0]) {
        final b = a + s * 0.7;
        c.drawLine(m, m + Offset(math.cos(b), math.sin(b)) * r * 0.18, vein);
      }
    }
  }
}

/// Zemin: kök sarmış orman toprağı. Dünyada süren dalgalı katmanlar,
/// kıvrılan ince kökler, yer yer taş; yüzeye yakın renk, derinde mürekkep.
/// Üstte yosunlu çim örtüsü.
void paintOtukenTile(Canvas c, Level lv, int col, int row, double x, double y) {
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
      Paint()..color = const Color(0xFF1C2416).withValues(alpha: 0.7 * a),
    );
    final strata = Paint()
      ..color = const Color(0xFF080A06).withValues(alpha: 0.55 * a)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    const gap = 11.0;
    for (var n = ((y - 6) / gap).floor(); n * gap < y + t + 6; n++) {
      double ly(double wx) => n * gap + math.sin(wx * 0.045 + n * 1.9) * 2.5;
      for (var dx = 0.0; dx < t; dx += 4) {
        final wx = x + dx;
        if (math.sin(wx * 0.07 + n * 2.3) < -0.2) continue;
        c.drawLine(Offset(wx, ly(wx)), Offset(wx + 4, ly(wx + 4)), strata);
      }
    }
    // Kökler: yukarıdan sarkan, kıvrılan ince çizgiler (dünyada sürer:
    // her kök kendi sütununda başlar, komşu karoya taşar).
    final rootP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3A2E1E).withValues(alpha: 0.8 * a);
    for (var k = -1; k <= 1; k++) {
      final cc = col + k;
      if (_hash(cc * 31 + row, 7) < 0.5) continue;
      var px = cc * t + 6 + _hash(cc * 31 + row, 8) * 20;
      var py = y - 2;
      final p = Path()..moveTo(px, py);
      for (var s = 0; s < 6; s++) {
        px += (_hash(cc * 7 + row * 3 + s, 9) - 0.5) * 9;
        py += 6;
        p.lineTo(px, py);
      }
      c.drawPath(p, rootP);
    }
    if (_hash(seed, 3) < 0.3) {
      final o = Offset(
        x + 6 + _hash(seed, 4) * (t - 12),
        y + 10 + _hash(seed, 5) * (t - 16),
      );
      c.drawOval(
        Rect.fromCenter(center: o, width: 7, height: 4.5),
        Paint()..color = const Color(0xFF2E3428).withValues(alpha: a),
      );
      c.drawArc(
        Rect.fromCenter(center: o, width: 7, height: 4.5),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _leafLight.withValues(alpha: 0.3 * a),
      );
    }
    c.restore();
  }
  if (right) {
    c.drawLine(
      Offset(x + t - 0.7, y + (top ? 6 : 0)),
      Offset(x + t - 0.7, y + t),
      Paint()
        ..color = _sun.withValues(alpha: 0.14)
        ..strokeWidth = 1,
    );
  }
  if (!top) return;
  // Yosunlu çim örtüsü: alt kenarı dünyada kesintisiz dalgalı, kenarlardan
  // sarkar; üst kenarda süzülen ışık.
  double lower(double wx) =>
      y + 5.5 + math.sin(wx * 0.25) * 1.4 + math.sin(wx * 0.1 + 2) * 1.2;
  final x0 = left ? x - 2 : x - 0.5;
  final x1 = right ? x + t + 2 : x + t + 0.5;
  final turf = Path()
    ..moveTo(x0, y - 1)
    ..lineTo(x1, y - 1);
  if (right) turf.quadraticBezierTo(x1 + 1.2, y + 4, x1 - 1, y + 10);
  for (var wx = x1 - 1; wx >= x0; wx -= 2) {
    turf.lineTo(wx, lower(wx));
  }
  if (left) turf.quadraticBezierTo(x0 - 1.2, y + 4, x0, y - 1);
  turf.close();
  c.drawPath(turf, Paint()..color = const Color(0xFF223E24));
  c.drawLine(
    Offset(x0, y - 0.6),
    Offset(x1, y - 0.6),
    Paint()
      ..color = _leafLight.withValues(alpha: 0.4)
      ..strokeWidth = 1,
  );
}
