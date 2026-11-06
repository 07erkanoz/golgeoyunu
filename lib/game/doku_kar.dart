// Kar bölümlerinin renk ve doku katmanları (CARTOON açıkken): Kule ve
// Gökyolu'ndaki gibi kâğıt oyma siluet dili. Her dağ sırası ayrı bir kâğıt
// katmanı: ardındakine ince bir gölge düşürür, sol yamaçlarında ayın dar
// kenar ışığı, doruklarında dişli kenarlı oyma buzul, buzulda oyulmuş
// yarıklar. Gece ve pus olduğu gibi kalır; bulanıklık yok.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

/// Ayın kenar ışığı (soldan vurur).
const _moonRim = Color(0xFFDCE6FF);

/// Kâğıt katmanının ardındakine düşen gölge.
final _drop = Paint()..color = const Color(0x59000000);

/// Kar bölümünün dağları, ay ve gökten sonra (ekran uzayında). [rise]:
/// kamera yükseldikçe sıralar aşağı iner. [variant] 0 Ağrı'nın iki tepesi,
/// 1 Palandöken'in iki doruğu, 2 tipi (doruk görünmez).
void paintKarBackdrop(
  Canvas canvas,
  double w,
  double h,
  Offset cam, {
  required double rise,
  required int variant,
}) {
  final storm = variant == 2;
  // Uzak sıradağlar.
  _range(
    canvas,
    w,
    offset: cam.dx * 0.03,
    base: h * 0.72 + rise * 0.4,
    height: h * 0.22,
    step: 120,
    seed: 3,
    body: const Color(0xFF2A3A55),
    cap: const Color(0xFF8E9EBA),
    capDepth: 0.42,
    rim: 0.35,
  );
  if (variant == 0) {
    // Büyük ve Küçük Ağrı: geniş volkan koniler, doruklarında buzul.
    final dx = -cam.dx * 0.035;
    _cone(
      canvas,
      Offset(w * 0.95 + dx, h * 0.8 + rise * 0.5),
      h * 0.36,
      w * 0.17,
      seed: 23,
    );
    _cone(
      canvas,
      Offset(w * 0.58 + dx, h * 0.8 + rise * 0.5),
      h * 0.62,
      w * 0.38,
      seed: 11,
    );
  } else if (!storm) {
    final dx = -cam.dx * 0.035;
    _cone(
      canvas,
      Offset(w * 0.78 + dx, h * 0.82 + rise * 0.5),
      h * 0.34,
      w * 0.26,
      seed: 17,
      sharp: true,
    );
    _cone(
      canvas,
      Offset(w * 0.42 + dx, h * 0.82 + rise * 0.5),
      h * 0.42,
      w * 0.3,
      seed: 5,
      sharp: true,
    );
  }
  // Pus: dağların eteğinde yatay sis bandı (katmanları birbirinden ayırır).
  final hazeY = h * 0.62 + rise * 0.6;
  canvas.drawRect(
    Rect.fromLTWH(0, hazeY, w, h * 0.2),
    Paint()
      ..shader = Gradient.linear(
        Offset(0, hazeY),
        Offset(0, hazeY + h * 0.2),
        const [Color(0x00AAB8D0), Color(0x40AAB8D0), Color(0x00AAB8D0)],
        const [0, 0.5, 1],
      ),
  );
  // Orta sıra: yakın sırtlar, ağıl ve çoban ışıkları.
  _range(
    canvas,
    w,
    offset: cam.dx * 0.12,
    base: h * 0.82 + rise,
    height: h * 0.15,
    step: 90,
    seed: 21,
    body: const Color(0xFF18212F),
    cap: const Color(0xFF5E6E88),
    capDepth: 0.3,
    rim: 0.25,
    lights: !storm,
  );
  // Çamlık: kar tutmuş oyma çamlar.
  _pines(
    canvas,
    w,
    offset: cam.dx * 0.25,
    base: h * 0.87 + rise * 1.3,
    seed: 3,
  );
  // Yakın kar kuşağı: tırtıllı kâğıt kenar.
  _drift(
    canvas,
    w,
    h,
    offset: cam.dx * 0.4,
    base: h * 0.93 + rise * 1.6,
    seed: 22,
  );
}

/// Kırıklı tepeli dağ sırası: kâğıt katman, ardına gölge, sol yamaçta ay
/// ışığı, doruklarda dişli oyma kar.
void _range(
  Canvas c,
  double w, {
  required double offset,
  required double base,
  required double height,
  required double step,
  required int seed,
  required Color body,
  required Color cap,
  required double capDepth,
  required double rim,
  bool lights = false,
}) {
  // Tepeler ve vadiler: (vadi, tepe) çiftleri soldan sağa.
  final pts = <Offset>[];
  final peaks = <(Offset, Offset, Offset, int)>[];
  var i = (offset / step).floor() - 2;
  Offset? lastValley;
  while (true) {
    final x0 = i * step - offset;
    if (x0 > w + step * 2) break;
    final u = _hash(i, seed);
    final valley = Offset(
      x0 + (_hash(i, seed + 1) - 0.5) * step * 0.3,
      base - height * (0.05 + 0.15 * _hash(i, seed + 2)),
    );
    final peak = Offset(
      x0 + step * (0.4 + 0.2 * _hash(i, seed + 3)),
      base - height * (0.45 + 0.55 * u),
    );
    if (lastValley != null) {
      final (pv, pp) = (lastValley, pts.last);
      peaks.add((pv, pp, valley, i - 1));
    }
    // Yamaçta küçük bir kırık (kayalık görünsün).
    if (lastValley != null) {
      final m = Offset.lerp(pts.last, valley, 0.5)!;
      pts.add(m + Offset(0, -height * 0.08 * _hash(i, seed + 4)));
    }
    pts.add(valley);
    final m2 = Offset.lerp(valley, peak, 0.55)!;
    pts.add(m2 + Offset(-step * 0.04, height * 0.04 * _hash(i, seed + 5)));
    pts.add(peak);
    lastValley = valley;
    i++;
  }
  final path = Path()..moveTo(pts.first.dx, base + 400);
  for (final p in pts) {
    path.lineTo(p.dx, p.dy);
  }
  path
    ..lineTo(pts.last.dx, base + 400)
    ..close();
  c.drawPath(path.shift(const Offset(3, 4)), _drop);
  c.drawPath(path, Paint()..color = body);
  // Doruk karı: tepeden iki yamaca, alt kenarı dişli.
  final capPaint = Paint()..color = cap;
  final crack = Paint()
    ..color = body.withValues(alpha: 0.7)
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  for (final (vl, pk, vr, k) in peaks) {
    final d = capDepth * (0.7 + 0.5 * _hash(k, seed + 6));
    final l = Offset.lerp(pk, vl, d)!;
    final r = Offset.lerp(pk, vr, d * 0.8)!;
    final cp = Path()
      ..moveTo(pk.dx, pk.dy)
      ..lineTo(l.dx, l.dy);
    const teeth = 5;
    for (var t = 1; t < teeth; t++) {
      final p = Offset.lerp(l, r, t / teeth)!;
      final down = t.isOdd
          ? (pk.dy - l.dy).abs() * (0.25 + 0.3 * _hash(k * 7 + t, seed))
          : -(pk.dy - l.dy).abs() * 0.12;
      cp.lineTo(p.dx, p.dy + down);
    }
    cp
      ..lineTo(r.dx, r.dy)
      ..close();
    c.drawPath(cp, capPaint);
    // Oyma yarık: doruktan aşağı tek ince çizgi.
    final y0 = pk.dy + (l.dy - pk.dy) * 0.25;
    c.drawLine(
      Offset(pk.dx + 1, y0),
      Offset(pk.dx + (r.dx - pk.dx) * 0.25, y0 + (l.dy - pk.dy) * 0.45),
      crack,
    );
    // Ay soldan: sol yamacın üst yarısında dar kenar ışığı.
    c.drawLine(
      pk,
      Offset.lerp(pk, vl, 0.55)!,
      Paint()
        ..color = _moonRim.withValues(alpha: rim)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    if (lights && _hash(k, seed + 9) < 0.18) {
      // Uzak bir ağılın penceresi: oyulmuş, ardından ılık ışık sızar.
      final at = Offset.lerp(vl, vr, 0.5)! + Offset(0, -2);
      c.drawRect(
        Rect.fromCenter(center: at, width: 2.6, height: 2.2),
        Paint()..color = const Color(0xCCFFC27A),
      );
    }
  }
}

/// Volkan koni (Ağrı) ya da sivri doruk (Palandöken): kâğıt katman, geniş
/// buzul şapkası, buzuldan vadilere inen dilleri, oyma yarıklar.
void _cone(
  Canvas c,
  Offset foot,
  double hgt,
  double half, {
  required int seed,
  bool sharp = false,
}) {
  final top = foot.dy - hgt;
  final sw = sharp ? half * 0.03 : half * 0.06; // doruğun yarı genişliği
  final body = Path()
    ..moveTo(foot.dx - half * 1.2, foot.dy + 200)
    ..lineTo(foot.dx - half * 1.2, foot.dy)
    ..quadraticBezierTo(
      foot.dx - half * 0.45,
      foot.dy - hgt * 0.35,
      foot.dx - sw,
      top,
    )
    ..quadraticBezierTo(
      foot.dx,
      top - hgt * 0.02,
      foot.dx + sw,
      top + hgt * 0.01,
    )
    ..quadraticBezierTo(
      foot.dx + half * 0.45,
      foot.dy - hgt * 0.32,
      foot.dx + half * 1.2,
      foot.dy,
    )
    ..lineTo(foot.dx + half * 1.2, foot.dy + 200)
    ..close();
  c.drawPath(body.shift(const Offset(4, 5)), _drop);
  c.drawPath(body, Paint()..color = const Color(0xFF151D2E));
  // Gölgeli yamaç: ay soldan vurur, sağ yarı bir ton koyu.
  c.save();
  c.clipPath(body);
  c.drawRect(
    Rect.fromLTRB(foot.dx + sw * 0.3, top - 10, foot.dx + half * 1.3, foot.dy),
    Paint()..color = const Color(0x33000814),
  );
  // Buzul: doruktan aşağı, alt kenarı uzun ve kısa diller.
  final capY = top + hgt * 0.24;
  final cap = Path()..moveTo(foot.dx - half * 1.3, top - 20);
  const n = 11;
  for (var k = 0; k <= n; k++) {
    final t = k / n;
    final x = foot.dx - half * 0.62 + half * 1.24 * t;
    final edge = (t - 0.5).abs() * 2; // yamaçlarda buzul daha yukarıda biter
    final tongue = k.isOdd
        ? hgt * (0.04 + 0.1 * _hash(k, seed))
        : -hgt * 0.03 * _hash(k, seed + 1);
    cap.lineTo(x, capY - hgt * 0.12 * edge * edge + tongue);
  }
  cap
    ..lineTo(foot.dx + half * 1.3, top - 20)
    ..close();
  c.drawPath(cap, Paint()..color = const Color(0xFF7E8EAA));
  // Buzulun gölgede kalan sağ yarısı.
  c.save();
  c.clipPath(cap);
  c.drawRect(
    Rect.fromLTRB(
      foot.dx + sw * 0.3,
      top - 10,
      foot.dx + half * 1.3,
      capY + hgt * 0.3,
    ),
    Paint()..color = const Color(0xFF5A6A86),
  );
  c.restore();
  // Oyma yarıklar: buzulda doruktan aşağı ince kesikler.
  final carve = Paint()
    ..color = const Color(0xFF34435E)
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 5; k++) {
    final fx = -0.5 + k * 0.25 + (_hash(k, seed + 3) - 0.5) * 0.1;
    final x0 = foot.dx + fx * sw * 2;
    final x1 = foot.dx + fx * half * 0.6;
    c.drawLine(
      Offset(x0, top + hgt * 0.04),
      Offset(x1, top + hgt * (0.14 + 0.06 * _hash(k, seed + 4))),
      carve,
    );
  }
  c.restore();
  // Ay ışığı sol yamaçta ve doruğun üstünde: dağın kendi kenarı, yalnız
  // üst yarıda.
  c.save();
  c.clipRect(
    Rect.fromLTRB(
      foot.dx - half * 1.3,
      top - 10,
      foot.dx + sw * 0.4,
      foot.dy - hgt * 0.72,
    ),
  );
  c.drawPath(
    body,
    Paint()
      ..color = _moonRim.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke,
  );
  c.restore();
}

/// Oyma çam sırası: kat kat dallar, her katın sol üstünde kar.
void _pines(
  Canvas c,
  double w, {
  required double offset,
  required double base,
  required int seed,
}) {
  const step = 30.0;
  final ink = Paint()..color = const Color(0xFF0A111C);
  final snow = Paint()..color = const Color(0xFF66768F);
  final ground = Path()..moveTo(-10, base + 300);
  var i = (offset / step).floor() - 2;
  final trees = <(double, double)>[];
  while (true) {
    final x = i * step - offset + (_hash(i, seed) - 0.5) * step * 0.8;
    if (x > w + step * 2) break;
    if (_hash(i, seed + 1) > 0.3) {
      trees.add((x, 0.6 + 0.6 * _hash(i, seed + 2)));
    }
    ground.lineTo(x, base - 3 * _hash(i, seed + 3));
    i++;
  }
  ground
    ..lineTo(w + 10, base + 300)
    ..close();
  final all = Path()..addPath(ground, Offset.zero);
  final caps = Path();
  for (final (x, s) in trees) {
    final th = 66 * s;
    const tiers = 4;
    for (var k = 0; k < tiers; k++) {
      final y0 = base - th * k / tiers * 0.8;
      final y1 = y0 - th * 0.42;
      final hw = 17 * s * (1 - k / tiers * 0.6);
      all.addPath(
        Path()
          ..moveTo(x - hw, y0)
          ..lineTo(x, y1)
          ..lineTo(x + hw, y0)
          ..lineTo(x + hw * 0.3, y0 - 2 * s)
          ..lineTo(x - hw * 0.4, y0 - 1.5 * s)
          ..close(),
        Offset.zero,
      );
      // Katın üstüne konmuş kar: iki yamaçta, alt kenarı dişli.
      final hy = (y0 - y1) * 0.42;
      caps.addPath(
        Path()
          ..moveTo(x, y1 + 0.5)
          ..lineTo(x - hw * 0.55, y1 + hy * 1.1)
          ..lineTo(x - hw * 0.3, y1 + hy * 0.75)
          ..lineTo(x - hw * 0.1, y1 + hy * 1.05)
          ..lineTo(x + hw * 0.15, y1 + hy * 0.7)
          ..lineTo(x + hw * 0.4, y1 + hy * 0.85)
          ..close(),
        Offset.zero,
      );
    }
  }
  c.drawPath(all.shift(const Offset(2, 3)), _drop);
  c.drawPath(all, ink);
  c.drawPath(caps, snow);
}

/// Yakın kar kuşağı: tümsek tümsek, kâğıt kenarında ay ışığı.
void _drift(
  Canvas c,
  double w,
  double h, {
  required double offset,
  required double base,
  required int seed,
}) {
  const step = 60.0;
  final path = Path()..moveTo(-20, h + 40);
  var i = (offset / step).floor() - 2;
  var x = i * step - offset;
  path.lineTo(x, base);
  final rimPath = Path()..moveTo(x, base);
  while (x < w + step) {
    final nx = x + step;
    final top = base - 10 - 18 * _hash(i, seed);
    path.quadraticBezierTo(x + step / 2, top, nx, base);
    rimPath.quadraticBezierTo(x + step / 2, top, nx, base);
    x = nx;
    i++;
  }
  path
    ..lineTo(x, h + 40)
    ..close();
  c.drawPath(path.shift(const Offset(0, -3)), _drop);
  c.drawPath(path, Paint()..color = const Color(0xFF7A889F));
  c.drawPath(
    rimPath,
    Paint()
      ..color = _moonRim.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke,
  );
}

// ------------------------------------------------------------- zemin

/// Kar bölümünün zemin karosu, olağan çizimin üstüne (CARTOON, kayaksız):
/// kayaya oyulmuş eğik katmanlar; üstü açıksa kalın, alt kenarı tırtıllı
/// kar örtüsü, ay ışığı alan üst kenar ve kenarlardan sarkan kar saçağı.
/// Desenler dünyada kesintisiz sürer (karo izi kalmaz).
void paintKarTile(Canvas c, Level lv, int col, int row, double x, double y) {
  const t = kTile;
  var depth = 0;
  while (depth < 3 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  if (depth < 3) {
    // Oyma kaya katmanları: dünyada süren dalgalı yatay çizgiler, yer yer
    // kopuk (oyulmuş taş); derine indikçe söner.
    final strata = Paint()
      ..color = const Color(0xFF283449).withValues(alpha: 0.6 * (1 - depth / 3))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    c.save();
    c.clipRect(Rect.fromLTWH(x, y, t, t));
    const gap = 12.0;
    for (var n = ((y - 6) / gap).floor(); n * gap < y + t + 6; n++) {
      double ly(double wx) => n * gap + math.sin(wx * 0.035 + n * 1.7) * 3;
      for (var dx = 0.0; dx < t; dx += 4) {
        final wx = x + dx;
        if (math.sin(wx * 0.09 + n * 3.1) < -0.25) continue;
        c.drawLine(Offset(wx, ly(wx)), Offset(wx + 4, ly(wx + 4)), strata);
      }
    }
    c.restore();
  }
  final top = row > 0 && !lv.solid(col, row - 1);
  final left = !lv.solid(col - 1, row);
  final right = !lv.solid(col + 1, row);
  if (left) {
    c.drawLine(
      Offset(x + 0.6, y + (top ? 6 : 0)),
      Offset(x + 0.6, y + t),
      Paint()
        ..color = _moonRim.withValues(alpha: 0.18)
        ..strokeWidth = 1,
    );
  }
  if (!top) return;
  // Kar örtüsü: alt kenarı dünyada kesintisiz tırtıllı.
  double lower(double wx) =>
      y + 5 + math.sin(wx * 0.31) * 1.4 + math.sin(wx * 0.13 + 1) * 1.2;
  double upper(double wx) => y - 2 - math.max(0, math.sin(wx * 0.05)) * 2.5;
  final x0 = left ? x - 2.5 : x - 0.5;
  final x1 = right ? x + t + 2.5 : x + t + 0.5;
  final blanket = Path()..moveTo(x0, upper(x0));
  for (var wx = x0; wx <= x1; wx += 2) {
    blanket.lineTo(wx, upper(wx));
  }
  blanket.lineTo(x1, upper(x1));
  if (right) {
    // Sağ kenarda saçak: kar kenardan taşıp sarkar.
    blanket.quadraticBezierTo(x1 + 1.5, y + 3, x1 - 1, y + 9);
  }
  for (var wx = x1 - 1; wx >= x0; wx -= 2) {
    blanket.lineTo(wx, lower(wx));
  }
  if (left) blanket.quadraticBezierTo(x0 - 1.5, y + 3, x0, upper(x0));
  blanket.close();
  c.drawPath(blanket, Paint()..color = const Color(0xFF7C8BA3));
  // Ay ışığı alan üst kenar.
  final rim = Path()..moveTo(x0, upper(x0));
  for (var wx = x0; wx <= x1; wx += 2) {
    rim.lineTo(wx, upper(wx));
  }
  c.drawPath(
    rim,
    Paint()
      ..color = _moonRim.withValues(alpha: 0.55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke,
  );
}
