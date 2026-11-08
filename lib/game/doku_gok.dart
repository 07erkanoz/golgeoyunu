// Gökyolu'nun renk ve doku katmanları (CARTOON açıkken): Kule'deki gibi
// siluet dili. Bölümün karanlığı ve paleti değişmez; ayrıntı kenar ışığı,
// oyma çizgi ve ışık sızdıran deliklerle verilir.
import 'dart:math' as math;
import 'dart:ui';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

/// Kırık güneşin ardından vuran kenar ışığı.
const _rimWarm = Color(0xFFFFC890);

/// Gökyolu'nun arka planı, kırık güneşten sonra (ekran uzayında):
/// uzak bulut adacıkları, Kandilci fener balonları, aşağıdaki damlardan
/// yükselen uçurtmalar ve kâğıttan oyulmuş bulut kuşakları.
void paintGokBackdrop(Canvas canvas, double w, double h, Offset cam, double t) {
  _cloudIslands(canvas, w, h, cam.dx * 0.12 + t * 2);
  _balloons(canvas, w, h, cam.dx * 0.16, t);
  _band(
    canvas,
    w,
    h,
    offset: cam.dx * 0.1 + t * 4,
    base: h * 0.72,
    r: 34,
    seed: 7,
    fill: const Color(0xFFB5603A),
    rim: 0.55,
    holes: const Color(0xFFE39B62),
  );
  _kites(canvas, w, h, cam.dx * 0.2, t);
  _band(
    canvas,
    w,
    h,
    offset: cam.dx * 0.25 + t * 8,
    base: h * 0.83,
    r: 46,
    seed: 8,
    fill: const Color(0xFF8A3C24),
    rim: 0.4,
    holes: const Color(0xFFB5603A),
  );
  _band(
    canvas,
    w,
    h,
    offset: cam.dx * 0.45 + t * 12,
    base: h * 0.94,
    r: 58,
    seed: 9,
    fill: const Color(0xFF5E281A),
    rim: 0.28,
    holes: const Color(0xFF8A3C24),
  );
}

/// Göğün Katları: Gökyolu'nun kâğıt oyma bulut kuşakları, bulanıklık
/// olmadan, katın renkleriyle ([body] gövde, [lit] kenar ışığı). Uzaktaki
/// kuşak açık, yakındaki koyu; [drift] rüzgârın hızı. Üç kuşak aynı hızla
/// kayar (ayrı hızlarda birbirinin içinden geçip karışıyordu); derinliği
/// yalnız kameranın kayması verir.
void paintHeavenBands(
  Canvas canvas,
  double w,
  double h,
  double camX,
  double t, {
  required Color body,
  required Color lit,
  double drift = 1,
}) {
  final far = Color.lerp(body, lit, 0.22)!;
  final near = Color.lerp(body, const Color(0xFF000000), 0.28)!;
  _band(
    canvas,
    w,
    h,
    offset: camX * 0.08 + t * 3 * drift,
    base: h * 0.62,
    r: 34,
    seed: 31,
    fill: far,
    rim: 0.6,
    holes: lit,
    rimColor: lit,
  );
  _band(
    canvas,
    w,
    h,
    offset: camX * 0.18 + t * 3 * drift,
    base: h * 0.76,
    r: 46,
    seed: 32,
    fill: body,
    rim: 0.5,
    holes: far,
    rimColor: lit,
  );
  _band(
    canvas,
    w,
    h,
    offset: camX * 0.28 + t * 3 * drift,
    base: h * 0.9,
    r: 58,
    seed: 33,
    fill: near,
    rim: 0.38,
    holes: body,
    rimColor: lit,
  );
}

/// Bir kuşağın tepecik dizilimi (kuşak boyunca tekrar eden bir dönem):
/// her tepeciğin dönem içindeki merkezi, yarıçapı, tabana göre yüksekliği
/// ve kimliği (oyma, ışık deliği seçimi için).
typedef _BandRow = ({
  double period,
  List<(double, double, double, int)> bumps,
});

final _bandRows = <(double, int), _BandRow>{};

_BandRow _bandRow(double r, int seed) => _bandRows.putIfAbsent((r, seed), () {
  const n = 64;
  final bumps = <(double, double, double, int)>[];
  var x = 0.0;
  for (var i = 0; i < n; i++) {
    final u = _hash(i, seed);
    final rr = r * (0.5 + 1.1 * u * u);
    final dy = -r * 0.3 * _hash(i, seed + 1) + rr * 0.15;
    bumps.add((x + rr, rr, dy, i));
    x += rr * (1.1 + 0.6 * _hash(i, seed + 2));
  }
  return (period: x, bumps: bumps);
});

/// Kâğıt oyma bulut kuşağı: üstü yarım daire tepecikler, her tepecikte
/// oyulmuş kıvrım (çin bulutu), üst kenarda ılık ışık, altında bir sıra
/// ışık deliği (ardındaki kuşağın rengi sızar).
void _band(
  Canvas canvas,
  double w,
  double h, {
  required double offset,
  required double base,
  required double r,
  required int seed,
  required Color fill,
  required double rim,
  required Color holes,
  Color rimColor = _rimWarm,
}) {
  // Tepecikler: iri ve küçük karışık, aralarında düzensiz boşluk. Dizilim
  // kuşağa sabittir (bir kez kurulur, tekrar eder); kamera kayınca
  // tepecikler yerinden oynamaz, yalnız kayar.
  final row = _bandRow(r, seed);
  final period = row.period;
  final bumps = <(Offset, double, int)>[];
  final from = offset - r * 4;
  var rep = (from / period).floor();
  while (rep * period - offset < w + r * 4) {
    for (final (bx, rr, dy, id) in row.bumps) {
      final x = rep * period + bx - offset;
      if (x + rr < -r * 2 || x - rr > w + r * 2) continue;
      bumps.add((Offset(x, base + dy), rr, id));
    }
    rep++;
  }
  final body = Path()..addRect(Rect.fromLTRB(-r * 2, base, w + r * 2, h));
  for (final (c, rr, _) in bumps) {
    body.addOval(Rect.fromCircle(center: c, radius: rr));
  }
  canvas.drawPath(body, Paint()..color = fill);
  // Üst kenar ışığı: yalnız tepeciklerin üst yarısı (başka tepeciğin
  // içinde kalan yayı çizme).
  final rimPaint = Paint()
    ..color = rimColor.withValues(alpha: rim)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final carve = Paint()
    ..color = Color.lerp(fill, const Color(0xFF1A0C08), 0.45)!
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.8;
  final hole = Paint()..color = holes.withValues(alpha: 0.75);
  for (var k = 0; k < bumps.length; k++) {
    final (c, rr, id) = bumps[k];
    canvas.save();
    // Komşuların örttüğü yerde kenar ışığı yanmasın.
    var clip = Path()
      ..addRect(
        Rect.fromLTRB(c.dx - rr - 2, c.dy - rr - 2, c.dx + rr + 2, base),
      );
    for (final j in [k - 1, k + 1]) {
      if (j < 0 || j >= bumps.length) continue;
      final (o, orr, _) = bumps[j];
      clip = Path.combine(
        PathOperation.difference,
        clip,
        Path()..addOval(Rect.fromCircle(center: o, radius: orr - 0.8)),
      );
    }
    canvas.clipPath(clip);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rr - 0.8),
      math.pi,
      math.pi,
      false,
      rimPaint,
    );
    canvas.restore();
    // Oyma kıvrım yalnız iri tepeciklerde, arada bir.
    if (rr > r * 0.9 && _hash(id, seed + 3) < 0.45) {
      final s = Path();
      for (var a = 0; a <= 26; a++) {
        final th = math.pi * 1.05 + a * 0.22;
        final rad = rr * 0.55 * (1 - a / 34);
        final p = c + Offset(math.cos(th) * rad, math.sin(th) * rad * 0.8);
        a == 0 ? s.moveTo(p.dx, p.dy) : s.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(s, carve);
    }
    // Işık delikleri: bazı tepeciklerin altında küçük bir üçlü.
    if (_hash(id, seed + 4) < 0.3) {
      final hy = math.max(c.dy + rr * 0.35, base + r * 0.3);
      for (final d in const [-6.0, 0.0, 6.0]) {
        canvas.drawCircle(
          Offset(c.dx + d, hy + d.abs() * 0.4),
          d == 0 ? 2.2 : 1.4,
          hole,
        );
      }
    }
  }
}

/// Uzak bulut adacıkları: altı düz, üstü tepecikli kâğıt oyma bulutlar;
/// tepelerde ılık kenar ışığı, ortada oyulmuş bir kıvrım.
void _cloudIslands(Canvas canvas, double w, double h, double offset) {
  const spacing = 460.0;
  final first = (offset / spacing).floor() - 1;
  final fill = Paint()..color = const Color(0xFF6E3326);
  final rim = Paint()
    ..color = _rimWarm.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3;
  final carve = Paint()
    ..color = const Color(0xFF4A2016)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6;
  for (var i = first; i * spacing - offset < w + spacing; i++) {
    if (_hash(i, 20) < 0.25) continue;
    final x = i * spacing - offset + _hash(i, 21) * 160;
    final y = h * (0.3 + 0.24 * _hash(i, 22));
    final s = 0.7 + 0.6 * _hash(i, 23);
    final n = 3 + (_hash(i, 24) * 3).floor();
    final len = 34.0 * n * s;
    final bumps = <(Offset, double)>[];
    for (var k = 0; k < n; k++) {
      final u = (k + 0.5) / n;
      final rr =
          s * (12 + 14 * math.sin(u * math.pi) + 4 * _hash(i * 7 + k, 25));
      bumps.add((Offset(x + u * len, y - rr * 0.35), rr));
    }
    final shape = Path()
      ..addRRect(
        RRect.fromLTRBR(
          x - 6 * s,
          y - 8 * s,
          x + len + 6 * s,
          y + 5 * s,
          Radius.circular(6 * s),
        ),
      );
    for (final (c, rr) in bumps) {
      shape.addOval(Rect.fromCircle(center: c, radius: rr));
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(x - 40, y - 200, x + len + 40, y + 5 * s));
    canvas.drawPath(shape, fill);
    for (var k = 0; k < n; k++) {
      final (c, rr) = bumps[k];
      canvas.save();
      var clip = Path()
        ..addRect(
          Rect.fromLTRB(c.dx - rr - 2, c.dy - rr - 2, c.dx + rr + 2, c.dy),
        );
      for (final j in [k - 1, k + 1]) {
        if (j < 0 || j >= n) continue;
        final (o, orr) = bumps[j];
        clip = Path.combine(
          PathOperation.difference,
          clip,
          Path()..addOval(Rect.fromCircle(center: o, radius: orr - 0.6)),
        );
      }
      canvas.clipPath(clip);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: rr - 0.7),
        math.pi,
        math.pi,
        false,
        rim,
      );
      canvas.restore();
    }
    final (mc, mr) = bumps[n ~/ 2];
    final sp = Path();
    for (var a = 0; a <= 24; a++) {
      final th = math.pi * 1.1 + a * 0.24;
      final rad = mr * 0.5 * (1 - a / 30);
      final p = mc + Offset(math.cos(th) * rad, math.sin(th) * rad * 0.8);
      a == 0 ? sp.moveTo(p.dx, p.dy) : sp.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(sp, carve);
    canvas.restore();
  }
}

/// Kandilci fener balonları: uzakta salınan koyu zarflar, altlarında asılı
/// yanan bir fener (gökte de gözleri var).
void _balloons(Canvas canvas, double w, double h, double offset, double t) {
  const spacing = 640.0;
  final first = (offset / spacing).floor() - 1;
  final ink = Paint()..color = const Color(0xFF3A1A12);
  final gore = Paint()
    ..color = _rimWarm.withValues(alpha: 0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final line = Paint()
    ..color = const Color(0xFF3A1A12)
    ..strokeWidth = 1;
  for (var i = first; i * spacing - offset < w + spacing; i++) {
    if (_hash(i, 31) < 0.3) continue;
    final s = 0.85 + 0.45 * _hash(i, 32);
    final bob = math.sin(t * 0.6 + i * 1.7) * 6;
    final x = i * spacing - offset + _hash(i, 33) * 300;
    final y = h * (0.2 + 0.25 * _hash(i, 34)) + bob;
    final rw = 26 * s, rh = 32 * s;
    final env = Path()
      ..moveTo(x, y + rh * 1.15)
      ..cubicTo(x - rw * 1.4, y + rh * 0.4, x - rw * 1.1, y - rh, x, y - rh)
      ..cubicTo(
        x + rw * 1.1,
        y - rh,
        x + rw * 1.4,
        y + rh * 0.4,
        x,
        y + rh * 1.15,
      )
      ..close();
    canvas.drawPath(env, ink);
    // Dilimler: güneşe bakan yanda ince ışık.
    for (final f in [-0.55, 0.0, 0.55]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y - rh)
          ..quadraticBezierTo(x + rw * f * 1.3, y, x, y + rh * 1.15),
        gore,
      );
    }
    final lampY = y + rh * 1.15 + 16 * s;
    canvas.drawLine(Offset(x, y + rh * 1.15), Offset(x, lampY - 3 * s), line);
    final flick = 0.8 + 0.2 * math.sin(t * 5 + i * 2.3);
    canvas.drawCircle(
      Offset(x, lampY),
      30 * s,
      Paint()
        ..shader = Gradient.radial(Offset(x, lampY), 30 * s, [
          const Color(0xFFFFB060).withValues(alpha: 0.75 * flick),
          const Color(0x00FFB060),
        ]),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, lampY), width: 5 * s, height: 7 * s),
        Radius.circular(2 * s),
      ),
      Paint()..color = const Color(0xFFFFD9A0).withValues(alpha: flick),
    );
  }
}

/// Aşağıdaki damlardan yükselen uçurtmalar: ipi buluta gömülen küçük
/// baklava siluetler, kuyrukları rüzgârda.
void _kites(Canvas canvas, double w, double h, double offset, double t) {
  const spacing = 300.0;
  final first = (offset / spacing).floor() - 1;
  final ink = Paint()..color = const Color(0xFF4A2016);
  final string = Paint()
    ..color = const Color(0x664A2016)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  final tail = Paint()
    ..color = const Color(0xFF4A2016)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  for (var i = first; i * spacing - offset < w + spacing; i++) {
    if (_hash(i, 41) < 0.45) continue;
    final x =
        i * spacing - offset + _hash(i, 42) * 120 + math.sin(t * 0.9 + i) * 8;
    final y = h * (0.5 + 0.12 * _hash(i, 43)) + math.cos(t * 1.1 + i) * 5;
    final k = 9.0;
    final tilt = math.sin(t * 1.3 + i) * 0.15;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(tilt);
    final kite = Path()
      ..moveTo(0, -k * 1.3)
      ..lineTo(k, 0)
      ..lineTo(0, k * 1.6)
      ..lineTo(-k, 0)
      ..close();
    canvas.drawPath(kite, ink);
    canvas.drawLine(
      Offset(0, -k * 1.3),
      Offset(k, 0),
      Paint()
        ..color = _rimWarm.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );
    final tp = Path()..moveTo(0, k * 1.6);
    for (var s = 1; s <= 8; s++) {
      tp.lineTo(math.sin(t * 3 + s * 0.9 + i) * 4, k * 1.6 + s * 4.0);
    }
    canvas.drawPath(tp, tail);
    canvas.restore();
    // İp aşağıya, buluta iner.
    canvas.drawPath(
      Path()
        ..moveTo(x, y + k)
        ..quadraticBezierTo(
          x - 30,
          y + 50,
          x - 50 - _hash(i, 44) * 40,
          h * 0.76,
        ),
      string,
    );
  }
}
