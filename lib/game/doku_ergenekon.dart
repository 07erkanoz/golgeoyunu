// Ergenekon'un renk ve doku katmanları (CARTOON açıkken): Kule ve kar
// bölümlerindeki kâğıt oyma dil. Dört yanı çeviren aşılmaz dağlar üst üste
// binen tek tek kâğıt doruklar (dişli kar başlıkları, sırt oyukları);
// ortada pas renkli demir dağ, kat kat demir damarları ve közleşen
// çatlakları; önde çayırlı vadi, ırmak, meyve ağaçları. Gece ay soldan,
// bölümün sonunda doğan Nevruz güneşi sağdan vurur. Bulanıklık yok.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _moon = Color(0xFFDCE6FF);
const _sunC = Color(0xFFFFD8A0);
final _drop = Paint()..color = const Color(0x4D000000);

Color _l(int a, int b, double t) => Color.lerp(Color(a), Color(b), t)!;

/// [dawn]: bölümdeki ilerleme (0..1); [sun]: güneşin doğuşu (0..1).
void paintErgenekonBackdrop(
  Canvas c,
  double w,
  double h,
  double camX,
  double camY,
  double dawn,
  double sun,
  double t, {
  required double ironX,
}) {
  final dy = -camY * 0.04;
  _range(
    c,
    w,
    h,
    camX * 0.03,
    h * 0.6 + dy,
    h * 0.36,
    61,
    _l(0xFF3E4A66, 0xFF6A5A66, sun),
    _l(0xFF8E9AB2, 0xFFE8CCB4, sun),
    sun,
    spacing: 90,
  );
  _range(
    c,
    w,
    h,
    camX * 0.06,
    h * 0.68 + dy,
    h * 0.42,
    67,
    _l(0xFF2C3650, 0xFF4E4250, sun),
    _l(0xFFAAB6CC, 0xFFF2D8C0, sun),
    sun,
    spacing: 130,
  );
  _ironMountain(c, w, h, ironX, h * 0.8 + dy, sun, t);
  _valley(c, w, h, camX, dy, sun);
}

/// Kâğıt doruklar: her biri ayrı oyulmuş, üst üste biner; dişli kar
/// başlığı, sırt oyuğu, ışığa bakan kenarda ince parıltı.
void _range(
  Canvas c,
  double w,
  double h,
  double off,
  double base,
  double height,
  int seed,
  Color body,
  Color snow,
  double sun, {
  required double spacing,
}) {
  final fill = Paint()..color = body;
  final shade = Color.lerp(body, const Color(0xFF000000), 0.35)!;
  final cap = Paint()..color = snow;
  final capShade = Paint()..color = Color.lerp(snow, body, 0.45)!;
  final carve = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = Color.lerp(body, const Color(0xFF000000), 0.5)!;
  final rimL = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..color = _moon.withValues(alpha: 0.4 * (1 - sun));
  final rimR = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..color = _sunC.withValues(alpha: 0.55 * sun);
  final first = ((off - spacing * 2) / spacing).floor();
  for (var i = first; i * spacing - off < w + spacing * 2; i++) {
    final px = i * spacing - off + (_hash(i, seed) - 0.5) * spacing * 0.6;
    final ph = height * (0.5 + _hash(i, seed + 1) * 0.5);
    final wl = ph * (0.55 + _hash(i, seed + 2) * 0.35);
    final wr = ph * (0.55 + _hash(i, seed + 3) * 0.35);
    double j(int k) => (_hash(i * 7 + k, seed + 4) - 0.5) * ph * 0.12;
    final tip = Offset(px, base - ph);
    final l = [
      Offset(px - wl, base + 30),
      Offset(px - wl * 0.62, base - ph * 0.42 + j(1)),
      Offset(px - wl * 0.3, base - ph * 0.74 + j(2)),
      Offset(px - wl * 0.1, base - ph * 0.9 + j(3)),
    ];
    final r = [
      Offset(px + wr * 0.12, base - ph * 0.88 + j(4)),
      Offset(px + wr * 0.35, base - ph * 0.7 + j(5)),
      Offset(px + wr * 0.68, base - ph * 0.38 + j(6)),
      Offset(px + wr, base + 30),
    ];
    final p = Path()..moveTo(l[0].dx, l[0].dy);
    for (final q in [...l.skip(1), tip, ...r]) {
      p.lineTo(q.dx, q.dy);
    }
    p.close();
    c.save();
    c.translate(3, 4);
    c.drawPath(p, _drop);
    c.restore();
    c.drawPath(p, fill);
    // Gölgeli yüz: ışığın ters yanı (gece sağ, şafakta sol).
    final face = Offset(px + (_hash(i, seed + 5) - 0.5) * wl * 0.3, base + 30);
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(r[0].dx, r[0].dy)
        ..lineTo(r[1].dx, r[1].dy)
        ..lineTo(r[2].dx, r[2].dy)
        ..lineTo(r[3].dx, r[3].dy)
        ..lineTo(face.dx, face.dy)
        ..close(),
      Paint()..color = shade.withValues(alpha: 0.55 * (1 - sun)),
    );
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(l[3].dx, l[3].dy)
        ..lineTo(l[2].dx, l[2].dy)
        ..lineTo(l[1].dx, l[1].dy)
        ..lineTo(l[0].dx, l[0].dy)
        ..lineTo(face.dx, face.dy)
        ..close(),
      Paint()..color = shade.withValues(alpha: 0.55 * sun),
    );
    // Kar başlığı: sırtlar boyunca iner, alt kenarı dişli.
    final sl = 0.22 + _hash(i, seed + 6) * 0.14;
    Offset along(List<Offset> e, double f) {
      // Kenar üstünde tepeden f oranında aşağıdaki nokta.
      final y = base - ph * (1 - f);
      for (var k = e.length - 1; k > 0; k--) {
        final a = e[k];
        final b = e[k - 1];
        if (y >= a.dy && y <= b.dy || y <= a.dy && y >= b.dy) {
          final u = (y - a.dy) / (b.dy - a.dy);
          return Offset.lerp(a, b, u.isFinite ? u : 0)!;
        }
      }
      return e.last;
    }

    final le = [l[0], l[1], l[2], l[3], tip];
    final re = [r[3], r[2], r[1], r[0], tip];
    final a = along(le, sl);
    final b = along(re, sl * (0.8 + _hash(i, seed + 7) * 0.4));
    final cp = Path()..moveTo(tip.dx, tip.dy);
    for (final q in le.reversed.skip(1)) {
      if (q.dy < a.dy) cp.lineTo(q.dx, q.dy);
    }
    cp.lineTo(a.dx, a.dy);
    const teeth = 6;
    for (var k = 1; k < teeth; k++) {
      final q = Offset.lerp(a, b, k / teeth)!;
      final down =
          (k.isOdd ? 1 : -0.4) * ph * (0.05 + _hash(i * 5 + k, seed) * 0.07);
      cp.lineTo(q.dx, q.dy + down);
    }
    cp.lineTo(b.dx, b.dy);
    for (final q in re.reversed.skip(1).toList().reversed) {
      if (q.dy < b.dy) cp.lineTo(q.dx, q.dy);
    }
    cp.close();
    c.drawPath(cp, cap);
    // Karın gölgeli yanı.
    c.save();
    c.clipPath(cp);
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(r[0].dx + 40, r[0].dy)
        ..lineTo(r[2].dx + 40, base)
        ..lineTo(face.dx, base)
        ..close(),
      capShade..color = capShade.color.withValues(alpha: 0.7 * (1 - sun) + 0.1),
    );
    c.restore();
    // Sırt oyuğu: kar altından inen kırık çizgi.
    c.drawPath(
      Path()
        ..moveTo(tip.dx + wr * 0.04, base - ph * (1 - sl) + 6)
        ..lineTo(px + wr * 0.12, base - ph * 0.45)
        ..lineTo(px + wr * 0.05, base - ph * 0.15),
      carve,
    );
    // Işığa bakan kenar.
    final lp = Path()..moveTo(l[1].dx, l[1].dy);
    for (final q in [l[2], l[3], tip]) {
      lp.lineTo(q.dx, q.dy);
    }
    c.drawPath(lp, rimL);
    final rp = Path()..moveTo(tip.dx, tip.dy);
    for (final q in [r[0], r[1], r[2]]) {
      rp.lineTo(q.dx, q.dy);
    }
    c.drawPath(rp, rimR);
  }
}

/// Demir dağ: köşeli pas kütlesi, kat kat koyu demir damarları, közleşen
/// kızıl çatlaklar (bulanıklık yerine geniş, soluk bir ikinci çizgi).
void _ironMountain(
  Canvas c,
  double w,
  double h,
  double x,
  double base,
  double sun,
  double t,
) {
  final hw = w * 0.36;
  final mh = h * 0.5;
  final pts = <Offset>[Offset(x - hw, base + 40)];
  const n = 24;
  for (var k = 1; k < n; k++) {
    final f = k / n;
    final env = 1 - (2 * f - 1).abs();
    // Dişli, birkaç doruklu sırt: tek düze tepe değil.
    final bumps = 0.12 * math.sin(f * 19 + 1) + 0.08 * math.sin(f * 41);
    final jag = k.isEven ? 0.0 : -0.06;
    final y =
        base -
        mh *
            (math.pow(env, 1.1) * (0.8 + bumps + _hash(k, 71) * 0.12) +
                jag * env);
    pts.add(Offset(x - hw + 2 * hw * f + (_hash(k, 72) - 0.5) * 10, y));
  }
  pts.add(Offset(x + hw, base + 40));
  final p = Path()..addPolygon(pts, true);
  c.save();
  c.translate(4, 5);
  c.drawPath(p, _drop);
  c.restore();
  c.drawPath(
    p,
    Paint()
      ..shader = Gradient.linear(
        Offset(x, base - mh),
        Offset(x, base),
        [
          _l(0xFF6A3E2E, 0xFF8A4E36, sun),
          _l(0xFF4A2A20, 0xFF5E3424, sun),
          const Color(0xFF1E100C),
        ],
        const [0, 0.5, 1],
      ),
  );
  c.save();
  c.clipPath(p);
  // Çıplak demir doruk: üstte soğuk gri, aşağı doğru pasa karışır.
  c.drawRect(
    Rect.fromLTRB(x - hw, base - mh * 1.1, x + hw, base - mh * 0.55),
    Paint()
      ..shader = Gradient.linear(
        Offset(x, base - mh),
        Offset(x, base - mh * 0.55),
        [
          _l(0xFF6E6C76, 0xFF9A8C88, sun),
          _l(0xFF6E6C76, 0xFF9A8C88, sun).withValues(alpha: 0),
        ],
      ),
  );
  // Köşeli yüzeyler: tepeden inen kırık sırtlar, bir yanı gölgede.
  for (var k = 3; k < n - 1; k += 4) {
    final top = pts[k];
    final foot = Offset(top.dx + (k < n / 2 ? -1 : 1) * hw * 0.18, base + 10);
    c.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(pts[k + 1].dx, pts[k + 1].dy)
        ..lineTo(foot.dx + hw * 0.2, base + 10)
        ..lineTo(foot.dx, foot.dy)
        ..close(),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.22),
    );
  }
  // Demir katmanları: dalgalı, kopuk koyu bantlar.
  final iron = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF2A2426).withValues(alpha: 0.7);
  final glint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFF9A9098).withValues(alpha: 0.25);
  for (var k = 0; k < 7; k++) {
    final y0 = base - mh * (0.12 + k * 0.11);
    final sp = Path();
    final gp = Path();
    var pen = false;
    for (var xx = x - hw; xx <= x + hw; xx += 8) {
      if (math.sin(xx * 0.03 + k * 2.3) < -0.2) {
        pen = false;
        continue;
      }
      final y = y0 + math.sin(xx * 0.02 + k) * 5;
      if (pen) {
        sp.lineTo(xx, y);
        gp.lineTo(xx, y - 2.2);
      } else {
        sp.moveTo(xx, y);
        gp.moveTo(xx, y - 2.2);
        pen = true;
      }
    }
    c.drawPath(sp, iron);
    c.drawPath(gp, glint);
  }
  c.restore();
  // Közleşen çatlaklar.
  final pulse = 0.35 + 0.2 * math.sin(t * 0.7);
  final glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 6
    ..color = const Color(0xFFFF8A40).withValues(alpha: pulse * 0.25);
  final vein = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.bevel
    ..strokeWidth = 2
    ..color = const Color(0xFFE0603A).withValues(alpha: pulse + 0.15);
  for (var i = 0; i < 6; i++) {
    final x0 = x - hw * 0.55 + i * hw * 0.22;
    var px = x0;
    var py = base - 4;
    final top = base - mh * (0.35 + (i % 3) * 0.12);
    final vp = Path()..moveTo(px, py);
    var k = 0;
    while (py > top) {
      px += (_hash(i * 11 + k, 73) - 0.5) * 16 + (x - px) * 0.06;
      py -= 10 + _hash(i * 11 + k, 74) * 10;
      vp.lineTo(px, py);
      k++;
    }
    c.drawPath(vp, glow);
    c.drawPath(vp, vein);
  }
  // Işığa bakan kenarlar.
  final lp = Path()..moveTo(pts[1].dx, pts[1].dy);
  for (var k = 2; k <= n ~/ 2; k++) {
    lp.lineTo(pts[k].dx, pts[k].dy);
  }
  c.drawPath(
    lp,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _moon.withValues(alpha: 0.3 * (1 - sun)),
  );
  final rp = Path()..moveTo(pts[n ~/ 2].dx, pts[n ~/ 2].dy);
  for (var k = n ~/ 2 + 1; k < n; k++) {
    rp.lineTo(pts[k].dx, pts[k].dy);
  }
  c.drawPath(
    rp,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _sunC.withValues(alpha: 0.6 * sun),
  );
}

/// Vadi: çimenli sırtlar (tepesi ışıkta, otlu kenar), ırmak, kâğıt oyma
/// meyve ağaçları.
void _valley(Canvas c, double w, double h, double camX, double dy, double sun) {
  _meadow(
    c,
    w,
    h,
    camX * 0.25,
    h * 0.74 + dy,
    26,
    22,
    _l(0xFF30523A, 0xFF4A6A3E, sun),
    sun,
  );
  // Irmak: dalgalı bant, üstünde ışık kırpıntıları.
  final ry = h * 0.8 + dy;
  final water = Path()..moveTo(0, ry);
  for (var x = 0.0; x <= w; x += 10) {
    water.lineTo(x, ry + math.sin((x + camX * 0.28) * 0.02) * 1.5);
  }
  water
    ..lineTo(w, ry + 7)
    ..lineTo(0, ry + 7)
    ..close();
  c.drawPath(
    water,
    Paint()..color = _l(0xFF4A6A84, 0xFFE0B888, sun).withValues(alpha: 0.6),
  );
  final glint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..color = (sun > 0 ? _sunC : _moon).withValues(alpha: 0.35);
  for (var i = 0; i < 30; i++) {
    final gx = ((i * 97.0 - camX * 0.28) % (w + 40) + w + 40) % (w + 40) - 20;
    c.drawLine(
      Offset(gx, ry + 2.5),
      Offset(gx + 6 + (i % 3) * 3, ry + 2.5),
      glint,
    );
  }
  _trees(c, w, h, camX * 0.32, h * 0.79 + dy, sun);
  _meadow(
    c,
    w,
    h,
    camX * 0.45,
    h * 0.9 + dy,
    20,
    23,
    _l(0xFF16261A, 0xFF22341E, sun),
    sun,
  );
}

void _meadow(
  Canvas c,
  double w,
  double h,
  double off,
  double base,
  double amp,
  int seed,
  Color body,
  double sun,
) {
  double f(double x) =>
      base +
      amp *
          (0.55 * math.sin(x * 0.006 + seed) +
              0.3 * math.sin(x * 0.0138 + seed * 1.7) +
              0.15 * math.sin(x * 0.0306 + seed * 0.3));
  final p = Path()..moveTo(-10, h);
  final top = Path();
  for (var x = -10.0; x <= w + 20; x += 8) {
    final y = f(x + off);
    p.lineTo(x, y);
    x == -10 ? top.moveTo(x, y) : top.lineTo(x, y);
  }
  p
    ..lineTo(w + 20, h)
    ..close();
  c.save();
  c.translate(3, 4);
  c.drawPath(p, _drop);
  c.restore();
  c.drawPath(p, Paint()..color = body);
  // Otlu kenar: sırt boyunca ince ot öbekleri.
  final grass = Paint()
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = body;
  for (var i = ((off - 10) / 7).floor(); i * 7.0 - off < w + 10; i++) {
    final x = i * 7.0 - off;
    final y = f(x + off);
    final hh = 3 + _hash(i, seed) * 5;
    c.drawLine(
      Offset(x, y + 1),
      Offset(x + (_hash(i, seed + 1) - 0.5) * 4, y - hh),
      grass,
    );
  }
  c.drawPath(
    top,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Color.lerp(
        _moon,
        _sunC,
        sun,
      )!.withValues(alpha: 0.18 + 0.2 * sun),
  );
}

void _trees(Canvas c, double w, double h, double off, double base, double sun) {
  const spacing = 150.0;
  final body = _l(0xFF223A26, 0xFF2E4A2A, sun);
  final fill = Paint()..color = body;
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..color = Color.lerp(
      _moon,
      _sunC,
      sun,
    )!.withValues(alpha: 0.25 + 0.2 * sun);
  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    if (_hash(i, 81) < 0.4) continue;
    final x = i * spacing - off + _hash(i, 82) * 60;
    final th = 24 + _hash(i, 83) * 18;
    final crown = Path();
    final lobes = <(Offset, double)>[];
    for (var k = 0; k < 5; k++) {
      final o = Offset(
        x + (k - 2) * 7 + _hash(i * 5 + k, 84) * 4,
        base - th - 4 + (k.isEven ? 0 : -9) - (k == 2 ? 6 : 0),
      );
      final r = 9 + _hash(i * 5 + k, 85) * 5;
      lobes.add((o, r));
      crown.addOval(Rect.fromCircle(center: o, radius: r));
    }
    c.save();
    c.translate(3, 4);
    c.drawPath(crown, _drop);
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(x - 2.5, base + 2)
        ..lineTo(x - 1.5, base - th)
        ..lineTo(x + 1.5, base - th)
        ..lineTo(x + 2.5, base + 2)
        ..close(),
      fill,
    );
    c.drawPath(crown, fill);
    // Taç kenarı ışıkta (gece sol üst, şafakta sağ üst).
    for (final (o, r) in lobes) {
      c.drawArc(
        Rect.fromCircle(center: o, radius: r - 0.5),
        sun > 0.5 ? math.pi * 1.5 : math.pi * 1.1,
        math.pi * 0.45,
        false,
        rim,
      );
    }
    if (_hash(i, 86) < 0.6) {
      final fruit = Paint()
        ..color = const Color(0xFFC8784A).withValues(alpha: 0.8);
      for (var k = 0; k < 5; k++) {
        c.drawCircle(
          Offset(
            x - 12 + _hash(i * 9 + k, 87) * 24,
            base - th - _hash(i * 9 + k, 88) * 18,
          ),
          1.7,
          fruit,
        );
      }
    }
  }
}

/// Zemin: vadinin toprağı. Dünyada süren dalgalı toprak katmanları, yer
/// yer demir cevheri taşları; yüzeye yakın renk, derinde mürekkep. Üstte
/// çim örtüsü ve ot öbekleri.
void paintErgenekonTile(
  Canvas c,
  Level lv,
  int col,
  int row,
  double x,
  double y,
) {
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
      Paint()..color = const Color(0xFF221812).withValues(alpha: 0.7 * a),
    );
    final strata = Paint()
      ..color = const Color(0xFF0C0806).withValues(alpha: 0.6 * a)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const gap = 10.0;
    for (var n = ((y - 6) / gap).floor(); n * gap < y + t + 6; n++) {
      double ly(double wx) => n * gap + math.sin(wx * 0.05 + n * 1.3) * 2.5;
      for (var dx = 0.0; dx < t; dx += 4) {
        final wx = x + dx;
        if (math.sin(wx * 0.08 + n * 2.9) < -0.3) continue;
        c.drawLine(Offset(wx, ly(wx)), Offset(wx + 4, ly(wx + 4)), strata);
      }
    }
    // Demir cevheri: köşeli koyu taş, üstü pas parıltılı.
    if (_hash(seed, 1) < 0.35) {
      final o = Offset(
        x + 6 + _hash(seed, 2) * (t - 12),
        y + 8 + _hash(seed, 3) * (t - 14),
      );
      final s = 3 + _hash(seed, 4) * 3;
      final stone = Path()
        ..moveTo(o.dx - s, o.dy)
        ..lineTo(o.dx - s * 0.4, o.dy - s * 0.8)
        ..lineTo(o.dx + s * 0.7, o.dy - s * 0.6)
        ..lineTo(o.dx + s, o.dy + s * 0.3)
        ..lineTo(o.dx + s * 0.2, o.dy + s * 0.8)
        ..close();
      c.drawPath(
        stone,
        Paint()..color = const Color(0xFF2A2428).withValues(alpha: a),
      );
      c.drawLine(
        Offset(o.dx - s * 0.4, o.dy - s * 0.8),
        Offset(o.dx + s * 0.7, o.dy - s * 0.6),
        Paint()
          ..color = const Color(0xFFC8643A).withValues(alpha: 0.5 * a)
          ..strokeWidth = 1,
      );
    }
    c.restore();
  }
  if (left) {
    c.drawLine(
      Offset(x + 0.7, y + (top ? 6 : 0)),
      Offset(x + 0.7, y + t),
      Paint()
        ..color = _moon.withValues(alpha: 0.14)
        ..strokeWidth = 1,
    );
  }
  if (!top) return;
  // Çim örtüsü: alt kenarı dünyada kesintisiz dalgalı, kenarlardan sarkar.
  double lower(double wx) =>
      y + 5 + math.sin(wx * 0.27) * 1.3 + math.sin(wx * 0.11 + 1) * 1.1;
  final x0 = left ? x - 2 : x - 0.5;
  final x1 = right ? x + t + 2 : x + t + 0.5;
  final turf = Path()..moveTo(x0, y - 1);
  turf.lineTo(x1, y - 1);
  if (right) turf.quadraticBezierTo(x1 + 1, y + 4, x1 - 1, y + 9);
  for (var wx = x1 - 1; wx >= x0; wx -= 2) {
    turf.lineTo(wx, lower(wx));
  }
  if (left) turf.quadraticBezierTo(x0 - 1, y + 4, x0, y - 1);
  turf.close();
  c.drawPath(turf, Paint()..color = const Color(0xFF1E3A22));
  c.drawLine(
    Offset(x0, y - 0.6),
    Offset(x1, y - 0.6),
    Paint()
      ..color = const Color(0xFF8AB88A).withValues(alpha: 0.35)
      ..strokeWidth = 1,
  );
}
