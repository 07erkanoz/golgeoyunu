part of 'perde.dart';

// Doğu yolculuğunun perde sahneleri: tufan, taş tanrılar, kervan, periler,
// semâ ve son. Hepsi 780×400'lük sanal sahnede, zemin y=350.

typedef _P = PerdePainter;

Paint _ink(double a) => _P._inkPaint(a);
Paint _hole(double a) => _P._holePaint(a);
double _span(double u, double a, double b) => _P._span(u, a, b);
double _shown(double u, double a, double b, [double fade = 0.25]) =>
    _P._shown(u, a, b, fade);

/// Yağan kar ya da yağmur çizgileri.
void _fallLines(
  Canvas canvas,
  double time,
  double a, {
  bool snow = false,
  int count = 70,
}) {
  if (a <= 0) return;
  final p = _ink(a * 0.5)..strokeWidth = snow ? 2.6 : 1.2;
  for (var i = 0; i < count; i++) {
    final x0 = (i * 97.0) % 800;
    final speed = snow ? 30.0 + (i % 5) * 6 : 260.0;
    final y = (i * 53.0 + time * speed) % 420 - 10;
    final x = x0 + (snow ? math.sin(time + i) * 8 : -y * 0.15);
    if (snow) {
      _P._c.drawCircle(Offset(x, y), 1.6, p);
    } else {
      _P._c.drawLine(Offset(x, y), Offset(x - 3, y + 14), p);
    }
  }
}

// ----------------------------------------------------------------- tufan

void _arkShape(Paint ink, Paint hole, double light) {
  final c = _P._c;
  c.drawPath(
    Path()
      ..moveTo(-120, -20)
      ..quadraticBezierTo(-110, 10, -70, 14)
      ..lineTo(70, 14)
      ..quadraticBezierTo(112, 10, 124, -26)
      ..lineTo(100, -18)
      ..lineTo(-100, -18)
      ..close(),
    ink,
  );
  // Üstündeki ev.
  c.drawRect(const Rect.fromLTWH(-70, -52, 130, 36), ink);
  c.drawPath(
    Path()
      ..moveTo(-80, -52)
      ..lineTo(-5, -78)
      ..lineTo(70, -52)
      ..close(),
    ink,
  );
  // Tahta dikiş delikleri.
  for (var x = -90.0; x <= 90; x += 22) {
    c.drawCircle(Offset(x, -2), 2, hole);
  }
  // Hiç sönmeyen ışık: pencerede.
  if (light > 0) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -44, 18, 18),
        const Radius.circular(9),
      ),
      _hole(light),
    );
  }
}

void _floodScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  // Ağrı'nın iki doruğu.
  canvas.drawPath(
    Path()
      ..moveTo(0, 400)
      ..lineTo(110, 270)
      ..lineTo(190, 300)
      ..lineTo(330, 124)
      ..lineTo(392, 160)
      ..lineTo(520, 320)
      ..lineTo(600, 250)
      ..lineTo(690, 330)
      ..lineTo(780, 372)
      ..lineTo(780, 400)
      ..close(),
    _ink(1),
  );
  // Sular önce dağı örter, sonra çekilir.
  final recede = _span(u, 1.0, 2.0);
  final level = 96 + recede * 250;
  final waves = Path()
    ..moveTo(0, 400)
    ..lineTo(0, level);
  for (var x = 0.0; x <= 780; x += 20) {
    waves.lineTo(x, level + math.sin(x / 30 + time * 2) * 5);
  }
  waves
    ..lineTo(780, 400)
    ..close();
  canvas.drawPath(waves, _ink(0.5));
  _fallLines(canvas, time, _shown(u, 0.3, 1.5));

  // Gemi: dalgada sallanır, sonra doruğa oturur.
  // Sular doruğun altına inince tekne doruğa (y=124) oturur: dibi
  // doruğa hafifçe gömülür (havada asılı kalmasın).
  final float = level < 122;
  final ay = math.min(level, 122.0);
  final bob = float ? math.sin(time * 1.6) * 4 : 0.0;
  canvas.save();
  canvas.translate(330, ay - 6 + bob);
  canvas.rotate(float ? math.sin(time * 1.2) * 0.05 : 0.04);
  canvas.scale(0.75);
  _arkShape(_ink(1), _hole(0.8), _span(u, 2.9, 3.3));
  canvas.restore();

  // Kuzgun gider, dönmez; güvercin zeytin dalıyla döner.
  final raven = _span(u, 2.0, 2.5);
  if (raven > 0 && raven < 1) {
    _P._bird(canvas, Offset(340 + raven * 480, 70 - raven * 40), time, 1, 0.4);
  }
  final dove = _span(u, 2.4, 3.1);
  if (dove > 0 && dove < 1) {
    final k = math.sin(dove * math.pi);
    final p = Offset(340 + k * 300, 70 - k * 30);
    _P._bird(canvas, p, time, 1, 2.2);
    if (dove > 0.5) {
      // Zeytin dalı.
      canvas.drawLine(
        p.translate(-12, 4),
        p.translate(-24, 10),
        _ink(1)..strokeWidth = 1.6,
      );
      for (final d in [-16.0, -20.0]) {
        canvas.drawOval(
          Rect.fromCenter(center: p.translate(d, 9), width: 6, height: 3),
          _ink(1),
        );
      }
    }
  }

  // Kandilciler gemiye tırmanır.
  final la = _span(u, 3.0, 3.4);
  for (var i = 0; i < 3; i++) {
    final k = _span(u, 3.0 + i * 0.1, 3.9);
    final x = 60 + k * 190 + i * 22.0;
    final y = 330 - k * 150 - i * 4.0;
    _P._puppet(canvas, Offset(x, y), time, i * 1.7, la, (ink, hole) {
      _P._lamplighter(ink, hole);
    }, scale: 0.32);
  }
  // Sâye uzaktan bakar.
  final sa = _span(u, 3.2, 3.6);
  _P._puppet(
    canvas,
    const Offset(640, 300),
    time,
    2.4,
    sa,
    (ink, hole) {
      _P._saye(ink, hole, time);
    },
    scale: 0.6,
    flip: true,
  );
}

// ------------------------------------------------------- Nemrut tanrıları

void _seatedGod(Canvas canvas, double x, int i, double head, double t) {
  final ink = _ink(1);
  const g = PerdePainter._ground;
  // Taht ve gövde.
  canvas.drawRect(Rect.fromLTWH(x - 34, g - 60, 68, 60), ink);
  canvas.drawRect(Rect.fromLTWH(x - 22, g - 128, 44, 70), ink);
  canvas.drawRect(Rect.fromLTWH(x - 26, g - 76, 56, 18), ink);
  // Oymalar.
  canvas.drawCircle(Offset(x, g - 100), 3, _hole(0.8));
  canvas.drawLine(
    Offset(x - 26, g - 30),
    Offset(x + 26, g - 30),
    _hole(0.5)..strokeWidth = 2,
  );
  // Baş ve külah biçimli taç: yerinde ya da yere düşmüş.
  void drawHead() {
    canvas.drawOval(
      const Rect.fromLTWH(-16, -34, 32, 36),
      Paint()..color = ink.color,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-15, -28)
        ..lineTo(-6, -64)
        ..lineTo(8, -66)
        ..lineTo(16, -28)
        ..close(),
      ink,
    );
    canvas.drawCircle(const Offset(6, -18), 2.4, _hole(0.6 + 0.4 * t));
  }

  canvas.save();
  if (head < 1) {
    canvas.translate(x, g - 128 + head * 4);
  } else {
    // Düşmüş baş: tahtın önünde, yan yatmış.
    canvas.translate(x + 40 + i * 4.0, g - 2);
    canvas.rotate(-1.2 + i * 0.2);
  }
  drawHead();
  canvas.restore();
}

void _godsScene(Canvas canvas, double time, double u, {bool dawn = false}) {
  _P._c = canvas;
  // Güneş doğu teraslarına doğar.
  final rise = dawn ? _span(u, 0.3, 2.6) : 0.0;
  if (dawn) {
    final sc = Offset(560, 340 - rise * 200);
    canvas.drawCircle(
      sc,
      70,
      Paint()
        ..shader = ui.Gradient.radial(sc, 70, [
          const Color(0xFFFFF4D8).withValues(alpha: 0.95),
          const Color(0xFFFFC870).withValues(alpha: 0),
        ]),
    );
    // Kırık güneş: çatlaklar.
    canvas.drawLine(
      sc.translate(-14, -30),
      sc.translate(6, 4),
      _ink(0.7)..strokeWidth = 2,
    );
    canvas.drawLine(
      sc.translate(6, 4),
      sc.translate(-4, 28),
      _ink(0.7)..strokeWidth = 2,
    );
  }
  // Tümülüs: taşlardan yığılmış koni.
  canvas.drawPath(
    Path()
      ..moveTo(150, 352)
      ..lineTo(390, 110)
      ..lineTo(630, 352)
      ..close(),
    _ink(0.4),
  );
  canvas.drawRect(const Rect.fromLTWH(0, 350, 780, 50), _ink(1));
  // Kartal ve aslan.
  final ink = _ink(1);
  canvas.drawPath(
    Path()
      ..moveTo(40, 350)
      ..lineTo(44, 300)
      ..quadraticBezierTo(60, 270, 76, 300)
      ..lineTo(84, 350)
      ..close(),
    ink,
  );
  canvas.drawPath(
    Path()
      ..moveTo(60, 284)
      ..lineTo(74, 270)
      ..lineTo(84, 280)
      ..lineTo(72, 286)
      ..close(),
    ink,
  );
  canvas.drawPath(
    Path()
      ..moveTo(690, 350)
      ..lineTo(696, 312)
      ..lineTo(740, 304)
      ..quadraticBezierTo(760, 290, 756, 320)
      ..lineTo(752, 350)
      ..close(),
    ink,
  );
  // Beş taht: kral ve tanrılar. Deprem başları yere indirir.
  final quake = dawn ? 1.0 : _span(u, 2.9, 3.4);
  if (!dawn && u > 2.8 && u < 3.5) {
    canvas.translate(math.sin(time * 40) * 2, 0);
  }
  for (var i = 0; i < 5; i++) {
    final fallen = quake >= 1 || (quake > i * 0.2 + 0.1);
    _seatedGod(canvas, 170 + i * 110.0, i, fallen ? 1 : 0, rise);
  }
  // Kandilciler ışığı doğuya taşır.
  final carry = dawn ? _span(u, 3.0, 3.9) : _span(u, 4.0, 4.9);
  final ca = dawn ? _shown(u, 2.9, 4.1) : _shown(u, 3.9, 5.1);
  for (var i = 0; i < 2; i++) {
    _P._puppet(
      canvas,
      Offset(100 + carry * 520 + i * 60.0, 350),
      time,
      i * 1.9,
      ca,
      (ink, hole) => _P._lamplighter(ink, hole, lanternLift: i * 20.0),
      scale: 0.45,
    );
  }
  if (dawn) {
    final sa = _span(u, 2.6, 3.0);
    _P._puppet(canvas, const Offset(110, 350), time, 0.7, sa, (ink, hole) {
      _P._saye(ink, hole, time);
    }, scale: 0.7);
  }
}

// ---------------------------------------------------------------- kervan

// Kar ve periler perdeleri (Kar Yolu, Palandöken, Çığ, Peri Bacaları,
// Derinkuyu): her satır kendi tasviriyle. Satırlar birbirine yumuşakça
// geçer ([_krL]); aynı kişi satırlar boyunca perdede kalır.

/// Işıktan olanlar (kar, çığ, peri, ay): bezin sıcak renginden ayrılsın
/// diye ak.
Paint _krLight(double a) =>
    Paint()
      ..color = const Color(0xFFFFF6E4)
          .withValues(alpha: 0.95 * a.clamp(0.0, 1.0));

/// [k]. satırdan başlayıp [n] satır süren görünürlük; satır sınırında bir
/// öncekiyle kesişerek geçer.
double _krL(double u, double k, [double n = 1]) =>
    _shown(u, k - 0.1, k + n + 0.1, 0.2);

Paint _krLine(Paint p, double w) => p
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Yumuşak ışık halesi (kandil, peri, görüntü).
void _krGlow(Canvas c, Offset at, double r, double a, {double core = 0.8}) {
  if (a <= 0) return;
  c.drawCircle(
    at,
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        at,
        r,
        [
          const Color(0xFFFFF4DA).withValues(alpha: core * a),
          const Color(0xFFFFE2B0).withValues(alpha: 0.35 * a),
          const Color(0x00FFE2B0),
        ],
        const [0, 0.45, 1],
      ),
  );
}

/// Yağan kar: ak zerreler; [wind] yana sürükler.
void _krSnow(
  Canvas c,
  double time,
  double a, {
  double wind = 18,
  int n = 70,
  double size = 1,
  Rect area = const Rect.fromLTWH(0, 0, 780, 400),
}) {
  if (a <= 0) return;
  final p = _krLight(0.8 * a);
  for (var i = 0; i < n; i++) {
    final sp = 20.0 + (i % 7) * 5;
    final y = (i * 61.0 + time * sp) % (area.height + 20) - 10;
    final x =
        (i * 97.0 + time * wind + y * wind / sp * 0.6) % (area.width + 20) -
        10 +
        math.sin(time * 0.9 + i) * 6;
    c.drawCircle(
      Offset(area.left + x, area.top + y),
      (1.2 + (i % 3) * 0.7) * size,
      p,
    );
  }
}

/// Karlı zemin (dalgalı üst kenar, kar kesiği).
void _krGround(Canvas c, double a, {double y = 350}) {
  if (a <= 0) return;
  final p = Path()..moveTo(0, 400);
  for (var x = 0.0; x <= 780; x += 26) {
    p.lineTo(x, y + 2.5 * math.sin(x / 41) + 1.5 * math.sin(x / 13));
  }
  p
    ..lineTo(780, 400)
    ..close();
  c.drawPath(p, _ink(a));
  final cut = _krLine(_hole(0.35 * a), 1.2);
  for (var x = 14.0; x < 780; x += 52) {
    c.drawLine(Offset(x, y + 9), Offset(x + 22, y + 10), cut);
  }
}

/// Karlı bir doruk: mürekkep gövde, ak kar örtüsü (eteği dişli). [ridge]
/// sırtında ejder dikenleri.
void _krPeak(
  Canvas c,
  double x,
  double top,
  double half,
  double a, {
  double base = 352,
  double ink = 0.42,
  double snow = 1,
  double ridge = 0,
}) {
  if (a <= 0) return;
  final h = base - top;
  c.drawPath(
    Path()
      ..moveTo(x - half, base)
      ..quadraticBezierTo(x - half * 0.45, top + h * 0.35, x - 8, top + 4)
      ..quadraticBezierTo(x, top - 3, x + 8, top + 4)
      ..quadraticBezierTo(x + half * 0.5, top + h * 0.4, x + half, base)
      ..close(),
    _ink(ink * a),
  );
  if (snow > 0) {
    // Kar örtüsü: doruktan aşağı, dişli etek.
    final d = h * 0.32 * snow;
    final cap = Path()..moveTo(x - 8, top + 4);
    cap.quadraticBezierTo(x, top - 3, x + 8, top + 4);
    final l = x - 8 - d * 0.62, r = x + 8 + d * 0.66;
    cap.lineTo(r, top + d);
    const teeth = 6;
    for (var i = 1; i <= teeth; i++) {
      final t = i / teeth;
      cap.lineTo(
        r + (l - r) * t,
        top + d + (i.isOdd ? -d * 0.28 : d * 0.06) * (1 - 0.4 * t),
      );
    }
    cap.close();
    c.drawPath(cap, _krLight(0.55 * a * snow));
  }
  if (ridge > 0) {
    for (var i = 0; i < 7; i++) {
      final t = 0.12 + i * 0.1;
      final px = x + half * 0.5 * t * 1.6;
      final py = top + h * 0.4 * t * 1.25;
      c.drawPath(
        Path()
          ..moveTo(px - 5, py + 2)
          ..lineTo(px + 2, py - 12 * (1 - t * 0.5))
          ..lineTo(px + 6, py + 4)
          ..close(),
        _ink(ink * a * ridge),
      );
    }
  }
}

/// Palandöken'in iki ejder doruğu: Küçük Ejder solda, Büyük Ejder sağda.
void _krTwinPeaks(Canvas c, double a, {double ridge = 0}) {
  _krPeak(c, 240, 130, 230, a, ridge: ridge);
  _krPeak(c, 540, 66, 290, a, ridge: ridge);
}

/// Zincir: [p0]'dan [p1]'e sarkan halkalar.
void _krChain(Canvas c, Offset p0, Offset p1, double sag, double a) {
  if (a <= 0) return;
  final cp = Offset.lerp(p0, p1, 0.5)! + Offset(0, sag * 2);
  final len = (p1 - p0).distance + sag;
  final n = math.max(3, (len / 7).round());
  final p = _krLine(_ink(a), 1.7);
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final q = p0 * ((1 - t) * (1 - t)) + cp * (2 * (1 - t) * t) + p1 * (t * t);
    final d = (cp - p0) * (2 * (1 - t)) + (p1 - cp) * (2 * t);
    c.save();
    c.translate(q.dx, q.dy);
    c.rotate(math.atan2(d.dy, d.dx));
    c.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 8,
        height: i.isEven ? 4.6 : 1.8,
      ),
      p,
    );
    c.restore();
  }
}

/// Sâye: [flip] sola bakar, [rot] eğilir, [shake] elleri titrer.
void _krSaye(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double rot = 0,
  double jar = 1,
  double shake = 0,
}) {
  if (a <= 0) return;
  _P._c = c;
  c.save();
  c.translate(
    feet.dx + shake * math.sin(time * 53) * 1.4,
    feet.dy + shake * math.sin(time * 41) * 0.8,
  );
  c.rotate(rot);
  _P._puppet(
    c,
    Offset.zero,
    time,
    0.3,
    a,
    (ink, hole) => _P._saye(
      ink,
      hole,
      time,
      jar: jar * (shake > 0 ? 0.7 + 0.3 * math.sin(time * 31) : 1),
    ),
    scale: s,
    flip: flip,
    rod: false,
  );
  c.restore();
}

/// Koşan Sâye: sekerek öne eğilir.
void _krSayeRun(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
}) {
  final hop = math.sin(time * 9).abs();
  _krSaye(
    c,
    feet + Offset(0, -hop * 5 * s),
    s,
    time,
    a,
    flip: flip,
    rot: (flip ? -1 : 1) * (0.14 + 0.04 * hop),
  );
}

/// Bağırış: ağzın önünde üç kısa çizgi.
void _krShout(Canvas c, Offset at, double a, {bool flip = false}) {
  if (a <= 0) return;
  final p = _krLine(_ink(a), 2.4);
  final d = flip ? -1.0 : 1.0;
  for (final ang in [-0.5, 0.0, 0.5]) {
    final v = Offset(math.cos(ang) * d, math.sin(ang));
    c.drawLine(at + v * 6, at + v * 20, p);
  }
}

/// Kandilci: [lift] feneri kaldırır, [lit] fener yanık mı.
void _krKandilci(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double lift = 0,
  double lit = 1,
}) {
  if (a <= 0) return;
  _P._c = c;
  final lantern = feet + Offset((flip ? -88 : 88) * s, (-188 - lift) * s);
  _krGlow(c, lantern, 62 * s, a * lit, core: 0.75);
  _P._puppet(
    c,
    feet,
    time,
    1.7 + feet.dx * 0.013,
    a,
    (ink, hole) => _P._lamplighter(
      ink,
      lit >= 0.99 ? hole : _hole(a * lit),
      lanternLift: lift,
    ),
    scale: s,
    flip: flip,
    rod: false,
  );
}

/// Kandilcinin fener noktası (çizimle aynı hesap).
Offset _krLantern(
  Offset feet,
  double s, {
  bool flip = false,
  double lift = 0,
}) => feet + Offset((flip ? -88 : 88) * s, (-188 - lift) * s);

/// Hayalî Usta: elleri arkada zincirli; boynundan sarkan kandili göğsünde,
/// içinde [lamp] kadar alev.
void _krMaster(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double lamp = 1,
}) {
  if (a <= 0) return;
  _P._c = c;
  _P._puppet(
    c,
    feet,
    time,
    0.9,
    a,
    (ink, hole) {
      final cc = _P._c;
      _P._master(ink, hole);
      // Bileklerdeki kelepçe zinciri.
      _krChain(cc, const Offset(-38, -58), const Offset(-28, -60), 7, a);
      // Kandil boynundan bir iple sarkar, göğsüne bastırılmış.
      cc.drawLine(
        const Offset(8, -134),
        const Offset(30, -100),
        _krLine(_ink(a), 1.4),
      );
      cc.drawPath(
        Path()
          ..moveTo(20, -100)
          ..quadraticBezierTo(30, -84, 42, -97)
          ..lineTo(50, -101)
          ..lineTo(40, -102)
          ..close(),
        _ink(a),
      );
      if (lamp > 0) {
        final f = 1 + 0.15 * math.sin(time * 9);
        _krGlow(cc, const Offset(45, -108), 26 * lamp, a, core: 0.9);
        cc.drawPath(
          Path()
            ..moveTo(42, -103)
            ..quadraticBezierTo(
              44,
              -111 - 6 * lamp * f,
              46,
              -114 - 6 * lamp * f,
            )
            ..quadraticBezierTo(49, -108, 48, -103)
            ..close(),
          _krLight(a * (0.4 + 0.6 * lamp)),
        );
      }
    },
    scale: s,
    flip: flip,
    rod: false,
  );
}

/// Ustanın bileklerinin (zincirin) yeri.
Offset _krWrists(Offset feet, double s, {bool flip = false}) =>
    feet + Offset((flip ? 33 : -33) * s, -58 * s);

/// Deve: hörgüçlü, uzun boyunlu; [load] sırtındaki palan ve yük.
void _krCamel(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double load = 1,
  double rot = 0,
  double walk = 1,
}) {
  if (a <= 0) return;
  final ink = _ink(a);
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  c.scale(flip ? -s : s, s);
  // Bacaklar: dört uzun bacak, diz yumrusu; yürürken sallanır.
  final leg = _krLine(_ink(a), 5.5);
  for (final (hx, ph) in [
    (-26.0, 0.0),
    (-16.0, math.pi),
    (20.0, 0.6),
    (30.0, math.pi + 0.6),
  ]) {
    final sw = math.sin(time * 3.2 + ph) * 0.3 * walk;
    final knee = Offset(hx + math.sin(sw) * 22, -24);
    final foot = knee + Offset(math.sin(sw * 0.4) * 22, 22);
    c.drawPath(
      Path()
        ..moveTo(hx, -48)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy),
      leg,
    );
    c.drawCircle(knee, 3.6, ink);
    c.drawOval(
      Rect.fromCenter(center: foot + const Offset(3, 0), width: 11, height: 4),
      ink,
    );
  }
  // Gövde, hörgüç, boyun ve baş.
  c.drawPath(
    Path()
      ..moveTo(-40, -60)
      ..quadraticBezierTo(-38, -76, -22, -80)
      ..quadraticBezierTo(-6, -106, 12, -82)
      ..quadraticBezierTo(24, -72, 32, -66)
      ..quadraticBezierTo(42, -60, 47, -72)
      ..quadraticBezierTo(51, -88, 57, -93)
      ..lineTo(67, -95)
      ..quadraticBezierTo(77, -93, 78, -86)
      ..lineTo(71, -82)
      ..lineTo(61, -82)
      ..quadraticBezierTo(55, -70, 51, -58)
      ..quadraticBezierTo(45, -44, 30, -44)
      ..lineTo(-28, -44)
      ..quadraticBezierTo(-41, -46, -40, -60)
      ..close(),
    ink,
  );
  c.drawPath(
    Path()
      ..moveTo(60, -93)
      ..lineTo(58, -101)
      ..lineTo(64, -94)
      ..close(),
    ink,
  );
  c.drawLine(
    const Offset(-40, -62),
    const Offset(-45, -38),
    _krLine(_ink(a), 2),
  );
  c.drawCircle(const Offset(68, -89), 1.6, _hole(a));
  // Yular ve süs: boyunda zımba sırası.
  _punchRow(c, const Offset(48, -66), const Offset(56, -88), 4, 1.1, a);
  if (load > 0) _krLoad(c, const Offset(-6, -96), 0, 1, a * load);
  c.restore();
}

/// Palan ve yükü: iki denk, üstte kilim; [at] palanın ortası.
void _krLoad(Canvas c, Offset at, double rot, double s, double a) {
  if (a <= 0) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  c.scale(s);
  final ink = _ink(a);
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-30, -8, 60, 16),
      const Radius.circular(7),
    ),
    ink,
  );
  for (final x in [-22.0, 4.0]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, -30, 20, 24),
        const Radius.circular(4),
      ),
      ink,
    );
    c.drawLine(
      Offset(x + 3, -18),
      Offset(x + 17, -18),
      _krLine(_hole(0.6 * a), 1.2),
    );
  }
  _punchRow(c, const Offset(-26, 2), const Offset(26, 2), 7, 1.2, a);
  c.restore();
}

/// Gökbörü: [shape] duruşu; [run] koşarken sıçrar; [flip] sola bakar.
void _krWolf(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = false,
  Path? shape,
  double run = 0,
}) {
  if (a <= 0) return;
  final stride = math.sin(time * 9);
  c.save();
  c.translate(
    feet.dx,
    feet.dy - stride.abs() * 7 * run * h / 100 + math.sin(time * 1.4) * 1.2,
  );
  c.rotate((flip ? 1 : -1) * stride * 0.06 * run);
  c.scale((flip ? -1 : 1) * h / 100, h / 100);
  final walk = shape == null;
  c.drawPath(shape ?? MythShapes.wolfWalk, _ink(a));
  if (walk) {
    // Gök yele: boyunda ince ışık kesikleri; sırtta zımba, gözde ışık.
    final mane = _krLine(_hole(0.7 * a), 0.9);
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(24 + i * 4.0, -84 + i * 2.0),
        Offset(18 + i * 4.0, -70 + i * 2.0),
        mane,
      );
    }
    _punchRow(c, const Offset(-24, -74), const Offset(14, -78), 7, 0.9, a);
    _rosette(c, const Offset(-8, -58), 5, a);
    c.drawCircle(const Offset(50.5, -80), 1.8, _hole(a));
  }
  c.restore();
}

/// Yaşlı kervancı: börklü, uzun sakallı, beli bükük.
const _krKervanciEl = _Look(
  hat: _Hat.bork,
  garb: _Garb.kaftan,
  beard: _Beard.long,
  bent: 0.3,
);

/// İkinci kol: [_person]'un tek kolunun aynısı, arkadaki omuzdan.
void _krArm(
  Canvas c,
  Offset feet,
  double h,
  double angle,
  double a, {
  bool flip = false,
  double bent = 0,
}) {
  if (a <= 0) return;
  final s = h / 100;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(flip ? -s : s, s);
  c.translate(0, -4);
  c.rotate(bent * 0.6);
  c.translate(0, 4);
  c.translate(-1, -76);
  c.rotate(angle);
  final arm = Path()
    ..moveTo(-4, 0)
    ..lineTo(4, 0)
    ..lineTo(3, 26)
    ..lineTo(-3, 26)
    ..close();
  c.drawPath(arm, _ink(a));
  c.drawPath(arm, _krLine(_hole(0.45 * a), 0.9));
  c.drawCircle(const Offset(0, 27), 2.8, _ink(a));
  c.restore();
}

// ------------------------------------------------------ Kar Yolu (perde 8)

void _krCaravan(Canvas c, double time, double u) {
  const g = PerdePainter._ground;
  const f = g + 12;
  // Uzak doruklar ve kar: dik dağ satırı (4) dışında hep.
  final far = 1 - _krL(u, 4);
  _krTwinPeaks(c, far);

  // 0: Işığa dokunur; ustanın görüntüsü belirir; "Usta!" diye bağırır.
  final a0 = _krL(u, 0);
  if (a0 > 0) {
    _krGround(c, a0);
    final vis = _span(u, 0.18, 0.42);
    _krGlow(c, const Offset(545, 215), 220, a0 * vis, core: 0.9);
    final walk = _span(u, 0.2, 1.05);
    _krSnow(
      c,
      time,
      a0 * vis,
      n: 24,
      area: const Rect.fromLTWH(400, 40, 300, 300),
    );
    _krMaster(
      c,
      Offset(500 + walk * 70, f),
      1.0,
      time,
      a0 * vis * 0.95,
      lamp: 0.55,
    );
    // Dokunulan ışık: elinin önünde; dokununca halka yayılır.
    const orb = Offset(262, 302);
    final ring = _span(u, 0.1, 0.55);
    _krGlow(c, orb, 46 + 6 * math.sin(time * 3), a0 * (1 - 0.6 * vis));
    if (ring > 0 && ring < 1) {
      c.drawCircle(
        orb,
        20 + ring * 260,
        _krLine(_krLight(0.7 * (1 - ring) * a0), 4 * (1 - ring) + 1),
      );
    }
    final cry = _span(u, 0.45, 0.55) * (1 - _span(u, 0.82, 0.95));
    _krSaye(c, const Offset(200, f), 2.1, time, a0, rot: 0.07 * cry);
    _krShout(c, const Offset(232, 222), cry * a0);
  }

  // 1: Usta karda, zincirli, kervanın ortasında; kandilinde mum kadar ışık.
  final a1 = _krL(u, 1);
  if (a1 > 0) {
    _krGround(c, a1);
    final d = _span(u, 0.9, 2.1) * 40;
    _krCamel(c, Offset(640 + d, f - 4), 1.15, time, a1);
    _krKandilci(c, Offset(470 + d, f), 0.95, time, a1);
    final mf = Offset(320 + d, f);
    final wf = Offset(120 + d, f);
    _krChain(
      c,
      _krWrists(mf, 1.1),
      _krLantern(wf, 0.9) + Offset(-14, 66 * 0.9),
      16,
      a1,
    );
    _krMaster(c, mf, 1.1, time, a1, lamp: 0.45);
    _krKandilci(c, wf, 0.9, time, a1);
    _krSnow(c, time, a1, wind: 40);
  }

  // 2: Kandilciler onun kandilinden alev çalar; usta her alevde söner.
  // Görüntü dağılır; Sâye'nin elleri titrer.
  final a2 = _krL(u, 2);
  if (a2 > 0) {
    _krGround(c, a2);
    final vis = 1 - _span(u, 2.6, 2.78);
    final lit1 = _span(u, 2.24, 2.3), lit2 = _span(u, 2.44, 2.5);
    final fade = 1 - 0.3 * lit1 - 0.3 * lit2;
    _krGlow(c, const Offset(450, 215), 240, a2 * vis * 0.8, core: 0.7);
    const mf = Offset(300, f);
    _krMaster(c, mf, 1.05, time, a2 * vis * fade, lamp: 0.55 * fade);
    const k1 = Offset(500, f), k2 = Offset(650, f);
    _krKandilci(c, k1, 0.95, time, a2 * vis, flip: true, lit: lit1, lift: 20);
    _krKandilci(c, k2, 0.9, time, a2 * vis, flip: true, lit: lit2, lift: 30);
    // Alev ustanın kandilinden fenerlere uçar.
    final lampAt = mf + const Offset(45, -112) * 1.05;
    for (final (t0, k, s, lift) in [
      (2.1, k1, 0.95, 20.0),
      (2.3, k2, 0.9, 30.0),
    ]) {
      final fly = _span(u, t0, t0 + 0.16);
      if (fly > 0 && fly < 1) {
        final to = _krLantern(k, s, flip: true, lift: lift);
        final p =
            Offset.lerp(lampAt, to, fly)! +
            Offset(0, -math.sin(fly * math.pi) * 40);
        _krGlow(c, p, 22, a2 * vis);
        c.drawCircle(p, 4, _krLight(a2 * vis));
      }
    }
    // Görüntü kırılır: ışık kırıkları dağılır.
    final br = _span(u, 2.58, 2.9);
    if (br > 0 && br < 1) {
      final p = _krLight(a2 * (1 - br));
      for (var i = 0; i < 14; i++) {
        final ang = i * 2.4;
        final at =
            const Offset(450, 215) +
            Offset(math.cos(ang), math.sin(ang)) * (60 + i * 9 + br * 160);
        c.save();
        c.translate(at.dx, at.dy);
        c.rotate(ang + br * 3);
        c.drawPath(
          Path()
            ..moveTo(-7, 0)
            ..lineTo(0, -4)
            ..lineTo(8, 1)
            ..close(),
          p,
        );
        c.restore();
      }
    }
    final sa = _span(u, 2.55, 2.75);
    _krSaye(c, const Offset(170, f), 2.1, time, a2 * sa, shake: sa);
  }

  // 3: Kervan kuzeye, Erzurum'a; Sâye ardından koşar.
  final a3 = _krL(u, 3);
  if (a3 > 0) {
    _krGround(c, a3);
    _krErzurum(c, a3);
    final go = _span(u, 2.95, 4.05);
    final cx = 330 + go * 120;
    const s = 0.42;
    _krCamel(c, Offset(cx + 150, f - 2), s * 1.1, time, a3);
    _krKandilci(c, Offset(cx + 95, f), s, time, a3);
    _krChain(
      c,
      _krWrists(Offset(cx + 30, f), s),
      Offset(cx - 25, f - 60 * s * 1.5),
      6,
      a3,
    );
    _krMaster(c, Offset(cx + 30, f), s, time, a3, lamp: 0.4);
    _krKandilci(c, Offset(cx - 40, f), s, time, a3);
    final run = _span(u, 3.15, 4.05);
    _krSayeRun(c, Offset(70 + run * 170, f), 1.5, time, a3);
    _krSnow(c, time, a3, wind: 110, n: 90);
  }

  // 4: Palandöken: dik yamaçta palan kayar, yük uçuruma dökülür.
  final a4 = _krL(u, 4);
  if (a4 > 0) _krPalandoken(c, time, u, a4);

  // 5: Kervanın ardında Gökbörü: zincirli ustayı yalnız bırakmaz.
  final a5 = _krL(u, 5);
  if (a5 > 0) {
    _krGround(c, a5);
    final d = _span(u, 4.9, 6.1) * 40;
    final kf = Offset(610 + d, f);
    final mf = Offset(440 + d, f);
    // Zincir ustanın ardından dolanıp öndeki Kandilci'ye gider.
    _krChain(c, _krWrists(mf, 1.0), kf + const Offset(-26, -100), 22, a5);
    _krKandilci(c, kf, 0.88, time, a5);
    _krMaster(c, mf, 1.0, time, a5, lamp: 0.4);
    _krWolf(c, Offset(225 + d, f - 2), 165, time, a5);
    _krSnow(c, time, a5, wind: 30);
  }

  // 6: Başlık: uzakta kervan, ardında kurt; levha üstte.
  final a6 = _krL(u, 6, 3);
  if (a6 > 0) {
    _krGround(c, a6);
    final d = (u - 6).clamp(0.0, 3.0) * 30;
    const s = 0.36;
    _krCamel(c, Offset(520 + d, f - 2), s * 1.1, time, a6);
    _krKandilci(c, Offset(460 + d, f), s, time, a6);
    _krMaster(c, Offset(400 + d, f), s, time, a6, lamp: 0.4);
    _krKandilci(c, Offset(340 + d, f), s, time, a6);
    _krWolf(c, Offset(255 + d, f - 2), 60, time, a6);
    _krSnow(c, time, a6, n: 50);
  }
  if (far > 0 && u < 3) _krSnow(c, time, far * 0.5, n: 30);
}

/// Erzurum uzakta: kale, Çifte Minareli'nin iki minaresi, külahlı
/// kümbetler; kapısı kışa açılır.
void _krErzurum(Canvas c, double a) {
  final p = _ink(0.6 * a);
  const g = 352.0;
  c.drawRect(const Rect.fromLTWH(560, g - 70, 210, 70), p);
  for (var x = 560.0; x < 770; x += 18) {
    c.drawRect(Rect.fromLTWH(x, g - 80, 10, 12), p);
  }
  // Kapı: kemer, içi ışık.
  c.drawPath(
    Path()
      ..moveTo(640, g)
      ..lineTo(640, g - 34)
      ..quadraticBezierTo(656, g - 56, 672, g - 34)
      ..lineTo(672, g)
      ..close(),
    _hole(0.7 * a),
  );
  // Çifte Minare.
  for (final x in [700.0, 736.0]) {
    c.drawRect(Rect.fromLTWH(x - 6, g - 170, 12, 100), p);
    c.drawRect(Rect.fromLTWH(x - 9, g - 140, 18, 5), p);
    c.drawPath(
      Path()
        ..moveTo(x - 7, g - 170)
        ..lineTo(x, g - 196)
        ..lineTo(x + 7, g - 170)
        ..close(),
      p,
    );
  }
  c.drawRect(const Rect.fromLTWH(694, g - 100, 48, 30), p);
  // Kümbetler: külahlı türbeler.
  for (final (x, h) in [(590.0, 40.0), (616.0, 30.0)]) {
    c.drawRect(Rect.fromLTWH(x - 9, g - 70 - h, 18, h), p);
    c.drawPath(
      Path()
        ..moveTo(x - 11, g - 70 - h)
        ..lineTo(x, g - 96 - h)
        ..lineTo(x + 11, g - 70 - h)
        ..close(),
      p,
    );
  }
}

/// Palandöken: dik yamaçta deve tırmanır; palan kayar, yük uçurumdan
/// dökülür.
void _krPalandoken(Canvas c, double time, double u, double a) {
  // Dik yamaç: soldaki uçurum kenarından sağ yukarıya.
  const edge = Offset(170, 318);
  const top = Offset(700, 40);
  const ang = -0.488; // yamacın eğimi
  final slope = (top.dy - edge.dy) / (top.dx - edge.dx);
  double sy(double x) => edge.dy + (x - edge.dx) * slope;
  // Uzak dağ: dorukta kar.
  _krPeak(c, 640, 30, 300, a, ink: 0.3);
  c.drawPath(
    Path()
      ..moveTo(edge.dx, 400)
      ..lineTo(edge.dx - 6, edge.dy + 30)
      ..lineTo(edge.dx, edge.dy)
      ..lineTo(top.dx, top.dy)
      ..lineTo(780, top.dy + 20)
      ..lineTo(780, 400)
      ..close(),
    _ink(a),
  );
  // Yamaçta kar kesikleri.
  for (var x = 200.0; x < 680; x += 46) {
    c.drawLine(
      Offset(x, sy(x) + 10),
      Offset(x + 24, sy(x + 24) + 10),
      _krLine(_hole(0.35 * a), 1.2),
    );
  }
  // Uçurumun dibi: karanlık.
  c.drawRect(
    Rect.fromLTWH(0, 330, edge.dx - 6, 70),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 330),
        const Offset(0, 400),
        [
          const Color(0x001A0B05),
          const Color(0xFF1A0B05).withValues(alpha: 0.85 * a),
        ],
      ),
  );
  // Deve tırmanır (önde Kandilci).
  final climb = _span(u, 3.95, 5.05) * 30;
  final camelX = 390 + climb;
  _krKandilci(
    c,
    Offset(530 + climb, sy(530 + climb) + 8),
    0.5,
    time,
    a,
    lift: -20,
  );
  final slip = _span(u, 4.2, 4.5);
  final slip2 = _span(u, 4.42, 4.68);
  _krCamel(
    c,
    Offset(camelX, sy(camelX) + 8),
    1.05,
    time,
    a,
    rot: ang,
    load: 0,
    walk: 1 - 0.7 * slip * (1 - slip2),
  );
  // İki denk: palanla birlikte sırttan yamaca düşer, yamaç boyunca kayar,
  // kenardan uçuruma dökülür.
  for (final (t0, dz) in [(4.2, 0.0), (4.42, 1.0)]) {
    final drop = _span(u, t0, t0 + 0.08);
    final k = _span(u, t0 + 0.08, t0 + 0.3);
    final fall = _span(u, t0 + 0.3, t0 + 0.55);
    final onBack =
        Offset(camelX, sy(camelX) + 8) +
        _krRot(Offset(-6 + dz * 2, -96 - dz * 22) * 1.05, ang);
    if (drop <= 0) {
      _krLoad(c, onBack, ang, 1.05, a);
      continue;
    }
    // Yamacın üstü: yükün altı yere değer.
    Offset surf(double x) => Offset(x, sy(x) - 9);
    final land = surf(onBack.dx - 40);
    final along = surf(edge.dx + 6);
    var p = Offset.lerp(onBack, land, drop)!;
    var r = ang - drop * 0.15;
    if (k > 0) {
      p = Offset.lerp(land, along, k * k)!;
      r = ang - 0.15 - k * 0.2;
    }
    if (fall > 0) {
      p = along + Offset(-fall * 70, fall * fall * 130);
      r = ang - 0.35 - fall * 2.6;
    }
    _krLoad(
      c,
      p,
      r,
      1.05 * (1 - 0.25 * fall),
      a * (1 - _span(u, t0 + 0.45, t0 + 0.56)),
    );
  }
  _krSnow(c, time, a, wind: 60, n: 60);
}

Offset _krRot(Offset v, double ang) => Offset(
  v.dx * math.cos(ang) - v.dy * math.sin(ang),
  v.dx * math.sin(ang) + v.dy * math.cos(ang),
);

// ------------------------------------------------- Palandöken (perde 9)

/// Kişinin elinin yeri ([_person]'un tek kolu, [armA] gerçek açı).
Offset _krHand(
  Offset feet,
  double h,
  double armA, {
  double bent = 0,
  bool flip = false,
}) {
  final b = bent * 0.6;
  final v = const Offset(3, -76) + _krRot(const Offset(0, 28), armA);
  final q = _krRot(v - const Offset(0, -4), b) + const Offset(0, -4);
  return feet + Offset((flip ? -q.dx : q.dx) * h / 100, q.dy * h / 100);
}

/// Hanın penceresi: kemerli, geniş; dışarısı (doruklar, masal) burada.
Path _krWindow() => Path()
  ..moveTo(292, 300)
  ..lineTo(292, 118)
  ..quadraticBezierTo(300, 46, 520, 42)
  ..quadraticBezierTo(740, 46, 748, 118)
  ..lineTo(748, 300)
  ..close();

/// Hanın içi: duvar gölgesi, kiriş, kemerli pencere, sönmeye yüz tutmuş
/// ocak ve küller.
void _krInn(Canvas c, double time, double a) {
  if (a <= 0) return;
  final win = _krWindow();
  c.drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(0, 0, 780, 400))
      ..addPath(win, Offset.zero),
    _ink(0.24 * a),
  );
  c.drawPath(win, _krLine(_ink(a), 12));
  c.drawRect(const Rect.fromLTWH(280, 296, 480, 14), _ink(a));
  c.drawRect(const Rect.fromLTWH(0, 18, 780, 14), _ink(a));
  for (final x in [60.0, 180.0, 600.0, 720.0]) {
    c.drawCircle(Offset(x, 25), 2, _hole(0.5 * a));
  }
  // Ocak: davlumbaz, baca, taş ağız; içinde kor.
  final ink = _ink(a);
  c.drawRect(const Rect.fromLTWH(52, 32, 46, 130), ink);
  c.drawPath(
    Path()
      ..moveTo(18, 220)
      ..lineTo(132, 220)
      ..lineTo(104, 160)
      ..lineTo(46, 160)
      ..close(),
    ink,
  );
  c.drawRect(const Rect.fromLTWH(24, 236, 102, 116), ink);
  final ember = 0.35 + 0.12 * math.sin(time * 4.3) + 0.08 * math.sin(time * 11);
  _krGlow(c, const Offset(75, 335), 70, a * ember, core: 0.7);
  c.drawPath(
    Path()
      ..moveTo(44, 352)
      ..lineTo(44, 290)
      ..quadraticBezierTo(75, 258, 106, 290)
      ..lineTo(106, 352)
      ..close(),
    _hole(0.5 * a * ember),
  );
  // Küller ve son korlar.
  c.drawOval(const Rect.fromLTRB(48, 336, 102, 352), _ink(0.7 * a));
  for (var i = 0; i < 6; i++) {
    final f = 0.5 + 0.5 * math.sin(time * (3 + i) + i * 2);
    c.drawCircle(Offset(56 + i * 8.0, 340 + (i % 2) * 4), 1.6, _hole(a * f));
  }
  _krGround(c, a);
}

/// Pencereden görünen iki doruk (masalın sonunda ejderler bunlara döner).
/// [grow] yükseklik, [ridge] ejder sırtı.
void _krInnPeaks(Canvas c, double a, {double grow = 1, double ridge = 0}) {
  for (final (x, top, half) in [(420.0, 150.0, 150.0), (610.0, 96.0, 180.0)]) {
    _krPeak(
      c,
      x,
      300 - (300 - top) * grow,
      half * (0.5 + 0.5 * grow),
      a,
      base: 300,
      ink: 0.5,
      snow: grow,
      ridge: ridge,
    );
  }
}

/// Ejder, [rot] kadar eğik (iner, süzülür).
void _krDragon(
  Canvas c,
  Offset head,
  double s,
  double rot,
  double time,
  double a, {
  int dir = 1,
  bool awake = false,
}) {
  if (a <= 0) return;
  c.save();
  c.translate(head.dx, head.dy);
  c.rotate(rot);
  _ejder(c, Offset.zero, s, time, a, dir: dir, awake: awake);
  c.restore();
}

/// Koyun: küçük yünlü gövde, kara baş.
void _krSheep(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double run = 0,
}) {
  if (a <= 0) return;
  final hop = run * math.sin(time * 12 + feet.dx).abs() * 4;
  c.save();
  c.translate(feet.dx, feet.dy - hop);
  c.scale(flip ? -s : s, s);
  final ink = _ink(a);
  c.drawOval(const Rect.fromLTWH(-12, -16, 24, 12), ink);
  c.drawOval(const Rect.fromLTWH(9, -19, 9, 7), ink);
  for (final x in [-8.0, -3.0, 4.0, 8.0]) {
    c.drawLine(Offset(x, -6), Offset(x, 0), _krLine(_ink(a), 1.6));
  }
  c.restore();
}

void _krDragons(Canvas c, double time, double u) {
  const g = PerdePainter._ground;
  const f = g + 12;
  final win = _krWindow();
  // 0-3: handa; pencereden doruklar, sonra masalın kendisi.
  final inn = _krL(u, 0, 4);
  if (inn > 0) {
    _krInn(c, time, inn);
    c.save();
    c.clipPath(win);
    // 0: iki ak doruk; sırtlarında uyuyan ejderlerin dikenleri belli belirsiz.
    final w0 = _krL(u, 0);
    if (w0 > 0) {
      _krInnPeaks(c, w0, ridge: 0.6 * _span(u, 0.45, 0.8));
      _krSnow(c, time, w0, n: 30, area: const Rect.fromLTWH(292, 40, 456, 260));
    }
    // 1: iki ejder kardeş ovaya iner; sürüler kaçışır.
    final w1 = _krL(u, 1);
    if (w1 > 0) {
      _krInnPeaks(c, w1 * 0.6, grow: 0.85);
      c.drawRect(const Rect.fromLTWH(292, 282, 456, 20), _ink(0.6 * w1));
      final dive = _span(u, 1.0, 1.75);
      for (var i = 0; i < 7; i++) {
        final away = i.isEven ? 1.0 : -1.0;
        _krSheep(
          c,
          Offset(520 + i * 16.0 + away * dive * (30 + i * 6), 284),
          1.0,
          time,
          w1,
          flip: away < 0,
          run: dive,
        );
      }
      _krCamel(c, Offset(640 + dive * 50, 284), 0.36, time, w1);
      _krDragon(
        c,
        Offset.lerp(const Offset(640, 110), const Offset(575, 236), dive)!,
        0.4,
        -0.45 + dive * 0.3,
        time,
        w1,
        dir: -1,
        awake: true,
      );
      _krDragon(
        c,
        Offset.lerp(const Offset(450, 150), const Offset(485, 240), dive)!,
        0.36,
        0.3 - dive * 0.2,
        time + 1.3,
        w1,
        awake: true,
      );
    }
    // 2: derviş tepeye çıkar, ellerini açıp dua eder; yedi gün kar yağar.
    final w2 = _krL(u, 2);
    if (w2 > 0) {
      final snow = _span(u, 2.4, 2.95);
      _krPeak(c, 520, 160, 230, w2, base: 300, ink: 0.55, snow: 0.35 + snow);
      final up = _span(u, 2.0, 2.35);
      // Tepenin sol yamacı boyunca (yamacın eğrisi).
      final t = 0.5 + 0.5 * up;
      final feet = Offset(
        (1 - t) * (1 - t) * 290 + 2 * (1 - t) * t * 393.5 + t * t * 512,
        (1 - t) * (1 - t) * 300 + 2 * (1 - t) * t * 209 + t * t * 164 + 4,
      );
      final pray = _span(u, 2.32, 2.45);
      _person(
        c,
        feet,
        96,
        w2,
        _dervishLook,
        arm: -0.2 - 1.75 * pray,
        time: time,
      );
      _krArm(c, feet, 96, -0.1 - 2.75 * pray, w2);
      _krSnow(
        c,
        time,
        w2 * snow,
        n: (20 + 90 * snow).round(),
        size: 1.2,
        area: const Rect.fromLTWH(292, 40, 456, 260),
      );
    }
    // 3: ejderler karın altında uyur, iki dağa döner; fırtına nefesleri,
    // sis uykuları.
    final w3 = _krL(u, 3);
    if (w3 > 0) {
      final cover = _span(u, 3.12, 3.6);
      c.drawRect(const Rect.fromLTWH(292, 282, 456, 20), _ink(0.6 * w3));
      final da = w3 * (1 - _span(u, 3.35, 3.62));
      _ejder(c, const Offset(600, 262), 0.4, time * 0.3, da, dir: -1);
      _ejder(c, const Offset(455, 268), 0.36, time * 0.3 + 2, da);
      if (cover > 0) {
        _krInnPeaks(c, w3, grow: cover, ridge: _span(u, 3.5, 3.7));
      }
      _krSnow(
        c,
        time,
        w3 * (1 - cover * 0.5),
        n: 60,
        area: const Rect.fromLTWH(292, 40, 456, 260),
      );
      final breath = _span(u, 3.6, 3.75);
      if (breath > 0) {
        // Fırtına: Büyük Ejder'in doruğundan savrulan kar.
        for (var i = 0; i < 9; i++) {
          final k = (time * 0.35 + i / 9) % 1;
          c.drawCircle(
            Offset(612 + k * 130, 96 + math.sin(k * 6 + i) * 10 + k * 20),
            4 + k * 12,
            _krLight(0.45 * breath * w3 * (1 - k)),
          );
        }
        // Sis: eteklerde uzanan uyku.
        for (var i = 0; i < 6; i++) {
          final x = 300 + ((time * 8 + i * 80) % 480);
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x, 270 + (i % 2) * 8),
              width: 130,
              height: 22,
            ),
            _krLight(0.3 * breath * w3),
          );
        }
      }
    }
    c.restore();

    // Kervancı ve Sâye ocağın başında.
    final talk = _krL(u, 1, 3);
    final first = _krL(u, 0);
    // 0: külleri karıştırır; Sâye'yi görünce döner, dorukları gösterir.
    final turn = _span(u, 0.38, 0.46);
    if (first > 0) {
      const mf = Offset(205, f);
      final stir = -0.75 + 0.18 * math.sin(time * 2.6);
      final aStir = first * (1 - turn);
      if (aStir > 0) {
        _person(
          c,
          mf,
          168,
          aStir,
          _krKervanciEl,
          flip: true,
          arm: stir - 0.15,
          time: time,
        );
        final hand = _krHand(mf, 168, stir, bent: 0.3, flip: true);
        c.drawLine(hand, const Offset(84, 338), _krLine(_ink(aStir), 3));
      }
      final aPoint = first * turn * (1 - _span(u, 0.82, 1.0) * talk);
      _person(
        c,
        mf + Offset(-25 * _span(u, 0.8, 1.0), 0),
        168,
        aPoint,
        _krKervanciEl,
        arm: -2.25,
        time: time,
      );
      c.drawLine(
        const Offset(120, 352),
        const Offset(140, 280),
        _krLine(_ink(first * turn), 3),
      );
      final come = _span(u, 0.0, 0.32);
      _krSaye(c, Offset(430 - come * 80, f), 1.35, time, first, flip: true);
    }
    if (talk > 0) {
      final tell = first > 0 ? _span(u, 0.82, 1.0) : 1.0;
      final arm = -1.5 + 0.35 * math.sin(time * 1.3);
      _person(
        c,
        const Offset(180, f),
        168,
        talk * tell,
        _krKervanciEl,
        arm: arm,
        time: time,
      );
      c.drawLine(
        const Offset(120, 352),
        const Offset(140, 280),
        _krLine(_ink(talk), 3),
      );
      // Sâye pencereye dönmüş, dinler.
      final sit = first > 0 ? _span(u, 0.85, 1.05) : 1.0;
      _krSaye(c, Offset(350 - sit * 70, f), 1.3, time, talk * sit);
    }
  }

  // 4: Sâye dışarıda, ejderin sırtında; Kandilcilerin kervanı karşı
  // yamaçtan iner.
  final a4 = _krL(u, 4, 3);
  if (a4 > 0) {
    _krTwinPeaks(c, a4 * 0.7);
    // Karşı yamaç (uzak).
    c.drawPath(
      Path()
        ..moveTo(380, 400)
        ..lineTo(380, 330)
        ..quadraticBezierTo(560, 300, 690, 140)
        ..lineTo(780, 120)
        ..lineTo(780, 400)
        ..close(),
      _ink(0.5 * a4),
    );
    // Kervan: küçük fenerler yamaçtan aşağı süzülür.
    final go = (u - 4).clamp(0.0, 3.0);
    for (var i = 0; i < 5; i++) {
      final t = (0.18 + go * 0.22 - i * 0.07).clamp(0.0, 1.0);
      final p = Offset(700 - t * 260, 150 + t * 170 - math.sin(t * 2.6) * 20);
      final s = 0.17;
      if (i == 2) {
        _krMaster(c, p, s, time, a4, lamp: 0.5);
      } else if (i == 4) {
        _krCamel(c, p, s * 1.2, time, a4);
      } else {
        _krKandilci(c, p, s, time, a4);
      }
    }
    // Ejderin sırtı: Sâye'nin durduğu sırt, dikenli; aşağı iner.
    final ridge = Path()
      ..moveTo(0, 400)
      ..lineTo(0, 196);
    ridge
      ..quadraticBezierTo(150, 186, 280, 214)
      ..quadraticBezierTo(420, 260, 560, 400)
      ..close();
    c.drawPath(ridge, _ink(a4));
    for (var i = 1; i < 10; i++) {
      final t = i / 10;
      final x = 2 * (1 - t) * t * 150 + t * t * 280;
      final y = (1 - t) * (1 - t) * 196 + 2 * (1 - t) * t * 186 + t * t * 214;
      if ((x - 165).abs() < 26) continue;
      c.drawPath(
        Path()
          ..moveTo(x - 7, y + 4)
          ..lineTo(x + 2, y - 12)
          ..lineTo(x + 8, y + 5)
          ..close(),
        _ink(a4),
      );
    }
    final look = _span(u, 4.1, 4.4);
    _krSaye(c, Offset(150 + look * 20, 199), 1.5, time, a4, rot: 0.05 * look);
    _krSnow(c, time, a4, wind: 30, n: 60);
  }
}

// ------------------------------------------------------ Çığ (perde 10)

/// Küçük Ejder dağı: yamaçta ejder burnu gibi bir kaya, üstünde kapalı göz.
/// [breath] dağ nefes alır (şişer), [eye] göz açılır.
void _krDragonMountain(
  Canvas c,
  double a, {
  double breath = 0,
  double eye = 0,
}) {
  if (a <= 0) return;
  c.save();
  c.translate(520, 352);
  c.scale(1 + 0.045 * breath, 1 + 0.07 * breath);
  c.translate(-520, -352);
  final m = Path()
    ..moveTo(150, 352)
    ..quadraticBezierTo(300, 260, 396, 150)
    // Burun: yamaçtan öne uzanan kaya.
    ..lineTo(370, 146)
    ..lineTo(366, 134)
    ..lineTo(404, 116)
    ..quadraticBezierTo(470, 40, 520, 46)
    ..quadraticBezierTo(600, 60, 780, 250)
    ..lineTo(780, 352)
    ..close();
  c.drawPath(m, _ink(0.45 * a));
  // Kar örtüsü.
  c.drawPath(
    Path()
      ..moveTo(470, 72)
      ..quadraticBezierTo(500, 44, 520, 46)
      ..quadraticBezierTo(560, 52, 600, 92)
      ..lineTo(584, 104)
      ..lineTo(570, 90)
      ..lineTo(552, 106)
      ..lineTo(532, 88)
      ..lineTo(512, 104)
      ..lineTo(494, 86)
      ..close(),
    _krLight(0.5 * a),
  );
  // Burun deliği ve göz.
  c.drawCircle(const Offset(374, 138), 3, _ink(0.9 * a));
  c.drawOval(
    Rect.fromCenter(
      center: const Offset(420, 112),
      width: 16,
      height: 1.6 + 9 * eye,
    ),
    _krLight(a * (0.45 + 0.55 * eye)),
  );
  if (eye > 0) c.drawCircle(const Offset(422, 112), 2.4 * eye, _ink(a));
  c.restore();
}

/// Çığ: yoldaki ([route]) ak kütle; [front] ucun ilerleyişi (birim).
void _krAvalancheMass(
  Canvas c,
  List<Offset> route,
  double front,
  double time,
  double a, {
  double grow = 0.14,
  double maxR = 80,
}) {
  if (a <= 0 || front <= 0) return;
  final pts = <Offset>[];
  final ds = <double>[];
  var dist = 0.0;
  for (var i = 0; i < route.length - 1; i++) {
    final seg = route[i + 1] - route[i];
    final len = seg.distance;
    for (var t = 0.0; t < len; t += 10) {
      if (dist + t > front) break;
      pts.add(route[i] + seg * (t / len));
      ds.add(dist + t);
    }
    dist += len;
    if (dist > front) break;
  }
  final light = _krLight(a);
  for (var i = 0; i < pts.length; i++) {
    final behind = front - ds[i];
    final r =
        math.min(maxR, 10 + ds[i] * grow) *
        (0.55 + 0.45 * _span(behind, 0, 90)) *
        (1 + 0.1 * math.sin(time * 6 + i * 1.7));
    c.drawCircle(pts[i] + Offset(0, -r * 0.55), r, light);
  }
  // Kütlenin içinde yuvarlanan kaya ve buz parçaları; ucunda serpinti.
  final chunk = _ink(0.75 * a);
  for (var i = 0; i < pts.length; i += 3) {
    final r = math.min(maxR, 10 + ds[i] * grow) * 0.6;
    final ang = time * 5 + i;
    c.drawCircle(
      pts[i] +
          Offset(math.cos(ang) * r * 0.6, -r * 0.5 + math.sin(ang) * r * 0.4),
      2 + (i % 3),
      chunk,
    );
  }
  if (pts.isNotEmpty) {
    final tip = pts.last;
    for (var i = 0; i < 12; i++) {
      final k = (time * 1.4 + i / 12) % 1;
      c.drawCircle(
        tip + Offset(-20 + math.sin(i * 2.3) * 40 - k * 30, -20 - k * 60),
        1.5 + (i % 3),
        _krLight(a * (1 - k)),
      );
    }
  }
}

/// Kalp çarpıntısı: iki vuruş, sonra durak.
double _krBeat(double time) {
  final t = (time * 1.6) % 1;
  return math.max(
    math.exp(-math.pow((t - 0.1) / 0.05, 2)),
    0.7 * math.exp(-math.pow((t - 0.3) / 0.05, 2)),
  );
}

void _krAvalanche(Canvas c, double time, double u) {
  const g = PerdePainter._ground;
  const f = g + 12;
  final breath = _span(u, 2.08, 2.8) * (1 - _span(u, 3.0, 3.25));
  final eye = _span(u, 2.72, 2.95);
  _krDragonMountain(c, 1, breath: breath, eye: eye);
  _krGround(c, 1);
  // Yağan kar: nefeste durur.
  final still = _span(u, 2.0, 2.25) * (1 - _span(u, 2.95, 3.1));
  _krSnow(c, time, 1 - still, wind: 14, n: 50);

  // Kandilciler yamaçta: fenerlerini dağın burnuna kaldırırlar.
  final kA = _krL(u, 0, 4) * (1 - _span(u, 3.42, 3.58));
  final lift = 70 * _span(u, 0.15, 0.7);
  final kS = 0.7 - 0.18 * _span(u, 0.85, 1.15);
  for (final (i, x0) in [(0, 175.0), (1, 255.0), (2, 330.0)]) {
    final x =
        x0 +
        (x0 - 175) * 0.1 * _span(u, 0.85, 1.15) +
        60 * _span(u, 0.85, 1.15);
    _krKandilci(c, Offset(x, f), kS, time + i, kA, lift: lift - i * 8);
  }
  // 2: nefes: kar zerreleri burun deliğine akar.
  if (still > 0) {
    const nose = Offset(374, 138);
    for (var i = 0; i < 46; i++) {
      final k = (time * 0.22 + i / 46) % 1;
      final ang = i * 2.399;
      final r0 = 150 + (i % 5) * 45.0;
      Offset at(double k) {
        final rr = r0 * (1 - k) * (1 - k);
        final sw = ang + k * 1.8;
        return nose + Offset(math.cos(sw) * rr, math.sin(sw) * rr * 0.75);
      }

      final p0 = at(k), p1 = at(math.max(0, k - 0.06));
      final al = 0.85 * still * math.min(1, k * 4);
      c.drawLine(p1, p0, _krLine(_krLight(al * 0.6), 2));
      c.drawCircle(p0, 2.2, _krLight(al));
    }
  }
  // 3: ve kar aktı.
  const route = [
    Offset(500, 70),
    Offset(300, 250),
    Offset(170, 352),
    Offset(-80, 352),
  ];
  final q = _span(u, 3.02, 3.85);
  final aMass = _krL(u, 3, 2.2);
  _krAvalancheMass(c, route, q * 760 + 40 * _span(u, 3.85, 5.0), time, aMass);

  // Sâye: önde; yüreği ağzında.
  final sA = _krL(u, 1, 2.5) * (1 - _span(u, 3.3, 3.42));
  if (sA > 0) {
    final big = 1 - _span(u, 1.85, 2.15);
    final s = 1.5 + 0.8 * big;
    // 3: çığ inince kaçar.
    final flee = _span(u, 3.0, 3.32);
    final at = Offset(90 + 20 * big + flee * 230, f);
    if (flee > 0) {
      _krSayeRun(c, at, s, time, sA);
    } else {
      _krSaye(c, at, s, time, sA, shake: 0.4 * big);
    }
    // Yürek: göğsünde çarpan ışık.
    final b = _krBeat(time) * big;
    final heart = at + Offset(4 * s, -40 * s);
    c.drawCircle(heart, 3 + 3 * b, _krLight(sA * big * (0.5 + 0.5 * b)));
    if (b > 0.2) {
      c.drawCircle(heart, 8 + 18 * b, _krLine(_krLight(0.5 * sA * b), 1.5));
    }
  }

  // 4: beyazlığın önünde gök yeleli kurt koşar; dönüp Sâye'ye bakar.
  final a4 = _krL(u, 4, 2);
  if (a4 > 0) {
    // Çığ ardında, perdenin sol yanını doldurur.
    final edge = 70 + 70 * _span(u, 3.9, 5.0);
    for (var i = 0; i < 9; i++) {
      final y = 360 - i * 36.0;
      final r = 70 - i * 3.0 + 6 * math.sin(time * 5 + i);
      c.drawCircle(Offset(edge - 60 - i * 14, y), r, _krLight(a4));
    }
    final look = _span(u, 4.32, 4.4) * (1 - _span(u, 4.66, 4.74));
    final wx = 360 + 200 * _span(u, 3.95, 4.33) + 60 * _span(u, 4.7, 5.0);
    _krWolf(c, Offset(wx, f - 2), 135, time, a4 * (1 - look), run: 1);
    _krWolf(
      c,
      Offset(wx, f - 2),
      135,
      time,
      a4 * look,
      flip: true,
      shape: MythShapes.wolfStand,
    );
    if (look > 0.5) {
      _krShout(c, Offset(wx - 52, f - 128), (look - 0.5) * 2 * a4, flip: true);
    }
    final sx = 200 + 160 * _span(u, 4.0, 4.95);
    _krSayeRun(c, Offset(sx, f), 1.6, time, a4);
  }
}

void _caravanScene(
  Canvas canvas,
  double time,
  double u, {
  bool avalanche = false,
}) {
  _P._c = canvas;
  // Kar perdeleri satır satır kendi tasvirleriyle (_kr...): Kar Yolu ve
  // Palandöken aynı sahneyi paylaşır, hangisi olduğunu son sahne söyler.
  if (avalanche) {
    _krAvalanche(canvas, time, u);
  } else if (_P._lastScene == PerdeScene.dragons) {
    _krDragons(canvas, time, u);
  } else {
    _krCaravan(canvas, time, u);
  }
}

// ---------------------------------------------------------------- periler

/// Çizilen her şeyi tek renge boyar (ışıktan dev, peri).
void _krRecolor(Canvas c, Color col, void Function() draw) {
  c.saveLayer(
    null,
    Paint()..colorFilter = ColorFilter.mode(col, BlendMode.srcIn),
  );
  draw();
  c.restore();
}

/// Peri bacası: külden oyulmuş konik gövde, üstünde kara bazalt başlık.
/// [face] başlığın altında iki göz (başlıklı dev gibi), [holes] güvercinlik.
void _krChimney(
  Canvas c,
  double x,
  double h,
  double w,
  Paint p, {
  double base = 352,
  double face = 0,
  double holes = 0,
  double tilt = 0,
}) {
  final top = base - h;
  c.drawPath(
    Path()
      ..moveTo(x - w, base)
      ..quadraticBezierTo(x - w * 0.55, base - h * 0.45, x - w * 0.3, top + 6)
      ..lineTo(x + w * 0.3, top + 6)
      ..quadraticBezierTo(x + w * 0.55, base - h * 0.45, x + w, base)
      ..close(),
    p,
  );
  c.save();
  c.translate(x, top + 4);
  c.rotate(tilt);
  c.drawPath(
    Path()
      ..moveTo(-w * 0.62, 4)
      ..quadraticBezierTo(-w * 0.7, -w * 0.38, -w * 0.1, -w * 0.48)
      ..quadraticBezierTo(w * 0.62, -w * 0.5, w * 0.66, 2)
      ..quadraticBezierTo(0, 10, -w * 0.62, 4)
      ..close(),
    p,
  );
  c.restore();
  if (face > 0) {
    for (final dx in [-w * 0.13, w * 0.13]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x + dx, top + 22), width: 4, height: 6),
        _hole(0.8 * face),
      );
    }
  }
  if (holes > 0) {
    for (var i = 0; i < 6; i++) {
      c.drawRect(
        Rect.fromLTWH(
          x - w * 0.3 + (i % 3) * w * 0.24,
          top + 40 + (i ~/ 3) * 16,
          4,
          6,
        ),
        _hole(0.75 * holes),
      );
    }
  }
}

/// Kapadokya: üç sıra peri bacası (uzak, orta, yakın).
void _krChimneyRows(Canvas c, double a, {double near = 0, double grow = 1}) {
  if (a <= 0) return;
  final g = 0.45 + 0.55 * grow;
  for (var i = 0; i < 11; i++) {
    _krChimney(
      c,
      20 + i * 76.0,
      (90 + (i * 37) % 60) * g,
      24,
      _ink(0.3 * a),
      base: 330,
    );
  }
  for (final (x, h) in [
    (90.0, 150.0),
    (250.0, 190.0),
    (430.0, 140.0),
    (600.0, 200.0),
    (730.0, 160.0),
  ]) {
    _krChimney(c, x, h * g, 34, _ink(0.55 * a), holes: grow > 0.9 ? 0.6 : 0);
  }
  if (near > 0) {
    for (final (x, h, t) in [
      (62.0, 220.0, -0.08),
      (520.0, 250.0, 0.06),
      (690.0, 215.0, -0.04),
    ]) {
      _krChimney(c, x, h * g, 46, _ink(a * near), face: near * grow, tilt: t);
    }
  }
}

/// Ay: ak teker, üstünde soluk lekeler.
void _krMoon(Canvas c, Offset at, double r, double a) {
  if (a <= 0) return;
  _krGlow(c, at, r * 2.6, 0.5 * a, core: 0.6);
  c.drawCircle(at, r, _krLight(0.95 * a));
  c.drawCircle(at + Offset(-r * 0.3, -r * 0.2), r * 0.22, _ink(0.12 * a));
  c.drawCircle(at + Offset(r * 0.25, r * 0.3), r * 0.15, _ink(0.1 * a));
}

/// Işıktan peri: ak deri, ince mürekkep kenar, arkasında hale. [wings]
/// kanatların açılışı, [body] gövdenin görünürlüğü. Ayakları (eteği)
/// [feet]'te, sağa bakar; boyu [h].
void _krFairy(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = false,
  double wings = 1,
  double body = 1,
}) {
  if (a <= 0) return;
  final k = h / 100;
  _krGlow(c, feet + Offset(0, -55 * k), 85 * k, a, core: 0.85);
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 2.3) * 3 * k);
  c.scale(flip ? -k : k, k);
  final edge = _krLine(_ink(0.75 * a), 1.6 / math.max(k, 0.4));
  final flap = math.sin(time * 8);
  if (wings > 0) {
    for (final (ang, len) in [(-2.0, 66.0), (-2.55, 50.0)]) {
      c.save();
      c.translate(-4, -62);
      c.rotate(ang + flap * 0.16);
      c.scale(wings);
      final w = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.4, -len * 0.36, len, -3)
        ..quadraticBezierTo(len * 0.55, len * 0.2, 0, 0)
        ..close();
      c.drawPath(w, _krLight(0.8 * a));
      c.drawPath(w, edge);
      c.drawLine(
        const Offset(4, -1),
        Offset(len * 0.8, -4),
        _krLine(_ink(0.35 * a), 1),
      );
      c.restore();
    }
  }
  if (body > 0) {
    final b = Path()
      ..addOval(Rect.fromCircle(center: const Offset(3, -76), radius: 8.5))
      // Saç: arkaya dökülür.
      ..moveTo(-3, -84)
      ..quadraticBezierTo(-20, -78, -16 + math.sin(time * 2) * 2, -42)
      ..quadraticBezierTo(-8, -60, -2, -70)
      ..close()
      // Elbise: çan etek.
      ..moveTo(-5, -67)
      ..lineTo(8, -67)
      ..quadraticBezierTo(14, -36, 20, 0)
      ..quadraticBezierTo(0, 6, -20, 0)
      ..quadraticBezierTo(-12, -36, -5, -67)
      ..close()
      // Öne uzanan kol.
      ..moveTo(5, -62)
      ..lineTo(26, -50)
      ..lineTo(24, -46)
      ..lineTo(3, -56)
      ..close();
    c.drawPath(b, _krLight(a * body));
    c.drawPath(b, _krLine(_ink(0.75 * a * body), 1.6 / math.max(k, 0.4)));
    c.drawCircle(const Offset(7, -78), 1.3, _ink(a * body));
    c.drawCircle(const Offset(28, -48), 3, _krLight(a * body));
  }
  c.restore();
}

/// Demir kapı: parmaklıklar, sivri uçlar, perçinler.
void _krIronGate(Canvas c, double x0, double x1, double top, double a) {
  if (a <= 0) return;
  final bar = _krLine(_ink(a), 4);
  for (var x = x0; x <= x1 + 0.1; x += (x1 - x0) / 5) {
    c.drawLine(Offset(x, 352), Offset(x, top), bar);
    c.drawPath(
      Path()
        ..moveTo(x - 5, top + 2)
        ..lineTo(x, top - 12)
        ..lineTo(x + 5, top + 2)
        ..close(),
      _ink(a),
    );
  }
  for (final y in [top + 14, top + (352 - top) * 0.55]) {
    c.drawLine(Offset(x0 - 6, y), Offset(x1 + 6, y), _krLine(_ink(a), 5));
    for (var x = x0; x <= x1 + 0.1; x += (x1 - x0) / 5) {
      c.drawCircle(Offset(x, y), 1.3, _hole(0.6 * a));
    }
  }
}

/// Albastı: uzun saçlı, ışığa aç; [step] yürüyüş evresi.
void _krAlbasti(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = true,
}) {
  if (a <= 0) return;
  final bob = math.sin(time * 4).abs() * 4;
  c.save();
  c.translate(feet.dx, feet.dy - bob);
  c.rotate((flip ? -1 : 1) * 0.04 * math.sin(time * 4));
  _cut(
    c,
    MythFigures.albastiSilhouette,
    Offset.zero,
    h,
    a,
    flip: flip,
    eye: const Offset(6, -88),
    deco: false,
  );
  c.restore();
}

/// Muşkara köyü: düz damlı evler, minare; pencerelerde ışık.
void _krVillage(Canvas c, double a) {
  if (a <= 0) return;
  final p = _ink(0.7 * a);
  for (final (x, w, h) in [
    (470.0, 44.0, 36.0),
    (520.0, 52.0, 48.0),
    (582.0, 40.0, 30.0),
    (628.0, 56.0, 42.0),
    (690.0, 46.0, 34.0),
  ]) {
    c.drawRect(Rect.fromLTWH(x, 352 - h, w, h), p);
    c.drawRect(Rect.fromLTWH(x + w * 0.4, 352 - h * 0.7, 6, 8), _hole(0.7 * a));
  }
  c.drawRect(const Rect.fromLTWH(610, 238, 10, 80), p);
  c.drawPath(
    Path()
      ..moveTo(608, 240)
      ..lineTo(615, 212)
      ..lineTo(622, 240)
      ..close(),
    p,
  );
  c.drawRect(const Rect.fromLTWH(605, 262, 20, 4), p);
}

void _fairiesScene(
  Canvas canvas,
  double time,
  double u, {
  bool underground = false,
}) {
  _P._c = canvas;
  if (underground) {
    _undergroundScene(canvas, time, u);
    return;
  }
  final c = canvas;
  const f = 362.0;
  // 0: karlar geride kalır; ılık bir diyar; Muşkara'nın üstünde ay doğar.
  final a0 = _krL(u, 0);
  if (a0 > 0) {
    _krMoon(c, Offset(600, 250 - 120 * _span(u, 0.0, 1.0)), 30, a0);
    _krPeak(c, 120, 120, 200, a0, ink: 0.35);
    _krPeak(c, 300, 170, 150, a0, ink: 0.3, snow: 0.7);
    _krVillage(c, a0);
    c.drawPath(
      Path()
        ..moveTo(0, 400)
        ..lineTo(0, 300)
        ..quadraticBezierTo(200, 310, 380, 352)
        ..lineTo(780, 352)
        ..lineTo(780, 400)
        ..close(),
      _ink(a0),
    );
    final w = _span(u, 0.05, 1.0);
    final x = 70 + w * 280;
    final y = x < 380 ? 300 + (x / 380) * (x / 380) * 52 * 0.98 + 10 : f;
    _krSaye(c, Offset(x, y), 1.4, time, a0, rot: 0.06);
    // Kar geride: arkasında son kar taneleri.
    _krSnow(
      c,
      time,
      a0 * (1 - w),
      n: 30,
      area: const Rect.fromLTWH(0, 0, 360, 360),
    );
  }
  // 1-5: Kapadokya; bacalar sıra sıra.
  final rows = _krL(u, 1, 6);
  if (rows > 0) {
    final grow = u < 1.5 ? _span(u, 1.0, 1.6) : 1.0;
    final moon = _krL(u, 1, 6) * _span(u, 1.5, 2.2);
    _krMoon(c, const Offset(640, 70), 24, moon);
    // Erciyes uzakta, ağzında ince duman.
    _krPeak(c, 90, 150, 150, rows, ink: 0.25, snow: 0.6);
    final near = _krL(u, 1, 2);
    _krChimneyRows(c, rows, near: near, grow: grow);
    c.drawRect(const Rect.fromLTWH(0, 350, 780, 50), _ink(rows));
    // Yağmur ve rüzgâr külü oyar.
    final carve = _krL(u, 1) * (1 - _span(u, 1.5, 1.7));
    if (carve > 0) {
      final p = _krLine(_krLight(0.5 * carve), 1.3);
      for (var i = 0; i < 40; i++) {
        final x = (i * 53.0 + time * 300) % 860 - 40;
        final y = (i * 37.0 + time * 380) % 360;
        c.drawLine(Offset(x, y), Offset(x - 10, y + 22), p);
      }
    }
  }
  // 1: güzel atlar ülkesi: atlar dörtnala geçer.
  final a1 = _krL(u, 1);
  if (a1 > 0) {
    final run = _span(u, 1.25, 1.95);
    for (var i = 0; i < 3; i++) {
      final x = 60 + i * 80.0 + run * 300;
      _cut(
        c,
        MythShapes.horse,
        Offset(x, f - 4 - math.sin(time * 9 + i).abs() * 8),
        78 - i * 6.0,
        a1,
        eye: const Offset(48, -82),
        deco: false,
      );
    }
  }
  // Sâye: 2-4 boyunca bacaların önünde.
  final sA = _krL(u, 2, 3);
  final hide = _span(u, 4.5, 4.85);
  final sx = 200 - hide * 70;
  _krSaye(c, Offset(sx, f), 1.6, time, sA, shake: 0.5 * _span(u, 4.2, 4.4));
  // 2: bir bacanın tepesinde ışık yanar, kanatlanır, Sâye'nin önüne süzülür.
  final pa = _krL(u, 2, 3);
  if (pa > 0) {
    final spark = _span(u, 2.05, 2.2);
    final wing = _span(u, 2.2, 2.36);
    final glide = _span(u, 2.36, 2.72);
    const top = Offset(520, 104);
    const hover = Offset(330, 300);
    final start = top + const Offset(0, -2);
    var at =
        Offset.lerp(start, hover, glide)! +
        Offset(0, -math.sin(glide * math.pi) * 60);
    var h = 16 + 90 * glide;
    // 3: konuşur; sonra Sâye'ye uzun uzun bakar, biraz yaklaşır.
    final close = _span(u, 3.55, 3.85);
    at += Offset(-45 * close, 6 * close);
    // 4: Sâye'yi demirin ardına çağırır.
    final warn = _span(u, 4.05, 4.4);
    at += Offset(-60 * warn, -30 * warn);
    if (u > 2.0) {
      final flicker = u > 4.02 ? 0.65 + 0.35 * math.sin(time * 23).abs() : 1.0;
      if (spark < 1 && wing <= 0) {
        _krGlow(c, top, 10 + 18 * spark, pa * spark);
        c.drawCircle(top, 2 + 2.5 * spark, _krLight(pa * spark));
      } else {
        _krFairy(
          c,
          at,
          h,
          time,
          pa * flicker,
          flip: true,
          wings: wing,
          body: _span(u, 2.3, 2.55),
        );
      }
    }
    // Işıkları buluşur.
    if (close > 0) {
      _krGlow(c, Offset(sx + 50, f - 60), 50, 0.6 * pa * close * (1 - warn));
    }
  }
  // 3: devlerle savaşın anısı: gökte soluk devler yere batar, periler üstünde.
  final mem = _krL(u, 3) * _span(u, 3.05, 3.2) * (1 - _span(u, 3.55, 3.7));
  if (mem > 0) {
    _krGlow(c, const Offset(590, 130), 170, 0.7 * mem, core: 0.6);
    final sink = _span(u, 3.15, 3.55);
    c.save();
    c.clipRect(const Rect.fromLTWH(440, 20, 300, 200));
    for (final (x, s) in [(540.0, 1.0), (650.0, 0.85)]) {
      _person(c, Offset(x, 200 + sink * 120), 150 * s, 0.4 * mem, _giant);
    }
    c.restore();
    c.drawLine(
      const Offset(450, 200),
      const Offset(730, 200),
      _krLine(_ink(0.4 * mem), 2),
    );
    for (var i = 0; i < 4; i++) {
      _person(
        c,
        Offset(
          480 + i * 70.0 + math.sin(time * 2 + i) * 6,
          90 + (i % 2) * 20.0,
        ),
        30,
        0.4 * mem,
        _periBare,
        time: time,
      );
    }
  }
  // 4: Albastı bacaların dibinde dolaşır; Sâye demirin ardına saklanır.
  final a4 = _krL(u, 4, 3);
  if (a4 > 0) {
    final walk = _span(u, 4.1, 5.0) + 0.4 * _span(u, 5.0, 7.0);
    final ax = 720 - walk * 200;
    _krAlbasti(c, Offset(ax, f), 170, time, a4 * _krL(u, 4));
    _krIronGate(c, 102, 162, 230, a4 * _span(u, 4.0, 4.25) * _krL(u, 4));
  }
  // 5: başlık: bacaların tepesinde peri ışıkları dans eder.
  final a5 = _krL(u, 5, 3);
  if (a5 > 0) {
    for (final (x, y) in [(250.0, 150.0), (600.0, 140.0), (430.0, 200.0)]) {
      for (var i = 0; i < 2; i++) {
        final ang = time * 1.6 + i * math.pi + x;
        _krFairy(
          c,
          Offset(x + math.cos(ang) * 30, y - 10 + math.sin(ang) * 8),
          22,
          time + i,
          a5,
          flip: math.sin(ang) > 0,
        );
      }
    }
  }
}

/// Toprak ve içine oyulmuş odalar: oyuklardan bezin ışığı görünür.
void _krEarth(
  Canvas c,
  Rect earth,
  List<Rect> rooms,
  double a, {
  double ink = 0.88,
}) {
  if (a <= 0) return;
  final holes = Path();
  for (final r in rooms) {
    holes.addRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)));
  }
  c.drawPath(
    Path.combine(PathOperation.difference, Path()..addRect(earth), holes),
    _ink(ink * a),
  );
}

/// Değirmen taşı gibi yuvarlak kapı: ortası delik, kenarı zımbalı.
void _krMillDoor(Canvas c, Offset at, double r, double rot, double a) {
  if (a <= 0) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  c.drawCircle(Offset.zero, r, _ink(a));
  c.drawCircle(Offset.zero, r * 0.16, _hole(0.8 * a));
  for (var i = 0; i < 10; i++) {
    final ang = i * math.pi / 5;
    c.drawCircle(
      Offset(math.cos(ang), math.sin(ang)) * r * 0.78,
      1.8,
      _hole(0.6 * a),
    );
  }
  c.drawLine(
    Offset(-r * 0.5, 0),
    Offset(-r * 0.2, 0),
    _krLine(_hole(0.5 * a), 1.5),
  );
  c.restore();
}

/// Ateşli dev: ışıktan; uykuda nefesiyle parlar.
void _krFireGiant(
  Canvas c,
  Offset feet,
  double h,
  double rot,
  double time,
  double a, {
  double glow = 1,
}) {
  if (a <= 0) return;
  final mid = feet + _krRot(Offset(0, -h * 0.5), rot);
  _krGlow(c, mid, h * 0.75, a * glow * 0.8, core: 0.7);
  _krRecolor(c, const Color(0xFFFFC870).withValues(alpha: a), () {
    _person(c, feet, h, 1, _giant, rot: rot, time: time);
  });
  // Kor çatlakları.
  for (var i = 0; i < 7; i++) {
    final q =
        feet +
        _krRot(
          Offset(math.sin(i * 2.1) * h * 0.08, -h * (0.12 + i * 0.11)),
          rot,
        );
    c.drawCircle(q, 2 + (i % 2), _ink(0.5 * a));
  }
}

/// Derinkuyu'nun kesiti: yüzey [top]'ta; katlar, baca, yuvarlak kapı.
List<Rect> _krCityRooms(double top) => [
  Rect.fromLTWH(90, top + 26, 170, 46), // mutfak
  Rect.fromLTWH(300, top + 26, 170, 46), // ahır
  Rect.fromLTWH(120, top + 104, 380, 44), // odalar
  Rect.fromLTWH(220, top + 178, 440, 40), // ambar
  Rect.fromLTWH(522, top - 2, 22, 222), // hava bacası
  Rect.fromLTWH(600, top - 2, 26, 110), // giriş kuyusu
  Rect.fromLTWH(470, top + 104, 156, 30), // geçit
  Rect.fromLTWH(240, top + 64, 26, 50), // merdiven
  Rect.fromLTWH(430, top + 140, 26, 46), // merdiven
];

void _krCityLife(Canvas c, double top, double time, double a) {
  if (a <= 0) return;
  // Mutfak: tandır ateşi ve dumanı.
  final fire = 0.6 + 0.3 * math.sin(time * 6);
  _krGlow(c, Offset(160, top + 66), 34, a * fire, core: 0.7);
  c.drawOval(Rect.fromLTWH(140, top + 58, 40, 14), _ink(a));
  for (var i = 0; i < 3; i++) {
    final k = (time * 0.4 + i / 3) % 1;
    c.drawCircle(
      Offset(160 + k * 10, top + 52 - k * 20),
      4 + k * 6,
      _ink(0.25 * a * (1 - k)),
    );
  }
  // Ahır: eşek ve yemlik.
  _cut(c, MythShapes.horse, Offset(380, top + 72), 38, a, deco: false);
  c.drawRect(Rect.fromLTWH(430, top + 60, 26, 12), _ink(a));
  // Hava bacasında soluyan hava.
  for (var i = 0; i < 4; i++) {
    final k = (time * 0.5 + i / 4) % 1;
    c.drawLine(
      Offset(533, top + 210 - k * 200),
      Offset(533, top + 196 - k * 200),
      _krLine(_hole(0.5 * a * math.sin(k * math.pi)), 2),
    );
  }
}

void _undergroundScene(Canvas canvas, double time, double u) {
  final c = canvas;
  const f = 362.0;
  // 0: Uçhisar'dan ovaya bakar; fenerler birer birer kuyuda kaybolur; peri
  // yanına süzülür.
  final a0 = _krL(u, 0);
  if (a0 > 0) {
    _krMoon(c, const Offset(660, 64), 22, a0);
    _krChimneyRows(c, a0 * 0.6, grow: 0.6);
    c.drawRect(const Rect.fromLTWH(0, 336, 780, 64), _ink(0.8 * a0));
    // Kuyu ağzı.
    c.drawRect(const Rect.fromLTWH(560, 324, 54, 14), _ink(a0));
    c.drawOval(const Rect.fromLTWH(566, 332, 42, 8), _ink(a0));
    for (var i = 0; i < 4; i++) {
      final walk = _span(u, 0.05 + i * 0.16, 0.2 + i * 0.16);
      final down = _span(u, 0.2 + i * 0.16, 0.3 + i * 0.16);
      if (down >= 1) continue;
      final x = 720 - walk * 133;
      c.save();
      c.clipRect(const Rect.fromLTWH(0, 0, 780, 336));
      _krKandilci(
        c,
        Offset(x, 338 + down * 40),
        0.15,
        time + i,
        a0 * (1 - down * 0.6),
      );
      c.restore();
    }
    // Uçhisar: Sâye tepede.
    final rock = Path()
      ..moveTo(0, 400)
      ..lineTo(0, 200)
      ..quadraticBezierTo(60, 186, 120, 188)
      ..quadraticBezierTo(200, 186, 236, 214)
      ..quadraticBezierTo(270, 280, 300, 400)
      ..close();
    c.drawPath(rock, _ink(a0));
    for (var i = 0; i < 8; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(30 + (i % 4) * 50.0, 240 + (i ~/ 4) * 50.0, 10, 16),
          const Radius.circular(5),
        ),
        _hole(0.5 * a0),
      );
    }
    _krSaye(c, const Offset(140, 192), 1.4, time, a0);
    final come = _span(u, 0.45, 0.78);
    _krFairy(
      c,
      Offset.lerp(const Offset(560, 90), const Offset(250, 150), come)! +
          Offset(0, -math.sin(come * math.pi) * 30),
      58,
      time,
      a0 * _span(u, 0.4, 0.5),
      flip: true,
    );
  }
  // 1-2: yer altı şehrinin kesiti; Sâye ile peri yüzeyde.
  const top = 110.0;
  final cut = _krL(u, 1, 2);
  if (cut > 0) {
    _krMoon(c, const Offset(690, 50), 18, cut);
    // Şehir 2'de bir an silinir (devler sürülürken), sonra yeniden oyulur.
    final city = 1 - _span(u, 2.0, 2.15) * (1 - _span(u, 2.55, 2.85));
    _krEarth(c, Rect.fromLTWH(0, top, 780, 400 - top), [], cut * (1 - city));
    _krEarth(
      c,
      Rect.fromLTWH(0, top, 780, 400 - top),
      _krCityRooms(top),
      cut * city,
    );
    _krCityLife(c, top, time, cut * city);
    // 1: insanlar iner; düşman yüzeyden geçer.
    final a1 = _krL(u, 1);
    if (a1 > 0) {
      for (var i = 0; i < 4; i++) {
        final k = _span(u, 1.1 + i * 0.08, 1.4 + i * 0.08);
        final p = k < 0.5
            ? Offset(700 - k * 2 * 87, top + 2)
            : Offset(613, top + 2 + (k - 0.5) * 2 * 100);
        if (k <= 0) continue;
        c.save();
        c.clipRect(Rect.fromLTWH(0, 0, 780, k < 0.5 ? 400 : top + 100));
        _person(c, p, 26, a1 * (1 - _span(k, 0.9, 1.0)), _woman2, time: time);
        c.restore();
      }
      // Saklananlar: aşağı odada.
      for (var i = 0; i < 3; i++) {
        _person(
          c,
          Offset(160 + i * 40.0, top + 146),
          28,
          a1 * _span(u, 1.45, 1.6),
          _worker,
          flip: i == 1,
        );
      }
      final ride = _span(u, 1.55, 1.98);
      for (var i = 0; i < 2; i++) {
        final x = 800 - ride * 560 + i * 60;
        _cut(
          c,
          MythShapes.horse,
          Offset(x, top + 2),
          44,
          a1 * _span(u, 1.5, 1.6),
          flip: true,
          deco: false,
        );
        _person(
          c,
          Offset(x + 2, top - 26),
          26,
          a1 * _span(u, 1.5, 1.6),
          _nukuz,
          flip: true,
        );
      }
    }
    // 2: Peri Padişahı ateşli devi yerin altına sürer; dev şehrin altında
    // uyur; insanlar bilmeden üstüne kazar.
    final a2 = _krL(u, 2);
    if (a2 > 0) {
      final drive = _span(u, 2.08, 2.5);
      _person(
        c,
        Offset(380, top + 2),
        64,
        a2 * (1 - _span(u, 2.5, 2.65)),
        _periQueen,
        flip: true,
        arm: -0.6,
        time: time,
      );
      // Dev batar ve yatar.
      final lie = _span(u, 2.3, 2.55);
      final from = const Offset(520, top + 66);
      const rest = Offset(560, 368);
      final feet = Offset.lerp(from, rest, drive)!;
      final breath = 0.75 + 0.25 * math.sin(time * 1.2);
      c.save();
      c.clipRect(const Rect.fromLTWH(0, top, 780, 400 - top));
      _krFireGiant(
        c,
        feet,
        110,
        -math.pi / 2 * lie,
        time,
        a2,
        glow: drive < 1 ? 1 : breath,
      );
      c.restore();
      if (drive > 0 && drive < 1) {
        // Yer yarılır.
        c.drawLine(
          const Offset(470, top),
          const Offset(570, top),
          _krLine(_krLight(0.6 * a2 * (1 - drive)), 3),
        );
      }
    }
    // Sâye ve peri yüzeyde, solda.
    _krSaye(c, const Offset(60, top + 2), 0.95, time, cut);
    _krFairy(c, const Offset(118, top - 16), 44, time, cut, flip: true);
  }
  // 3: yuvarlak taş kapı içeriden açılır; "Aşağı in, Sâye."
  final a3 = _krL(u, 3);
  if (a3 > 0) {
    // Bölme duvarda yuvarlak kapı ağzı; solunda taşın yuvası.
    const mouth = Offset(436, 262);
    _krEarth(c, const Rect.fromLTWH(0, 0, 780, 400), const [
      Rect.fromLTWH(520, 150, 300, 202),
      Rect.fromLTWH(244, 172, 194, 180),
      Rect.fromLTWH(352, 178, 168, 168),
    ], a3);
    c.drawRect(const Rect.fromLTWH(-10, 352, 800, 60), _ink(a3));
    final roll = _span(u, 3.15, 3.55);
    // Ağzın ardında aşağı inen basamaklar.
    c.save();
    c.clipRect(const Rect.fromLTWH(352, 178, 168, 174));
    for (var i = 0; i < 6; i++) {
      c.drawRect(
        Rect.fromLTWH(360 + i * 22.0, 200 + i * 26.0, 160, 7),
        _ink(0.55 * a3 * roll),
      );
    }
    c.restore();
    _krMillDoor(c, mouth - Offset(roll * 100, 0), 86, -roll * 2.2, a3);
    final go = _span(u, 3.6, 3.95);
    _krSaye(c, Offset(610 - go * 150, f - 10), 1.4, time, a3, flip: true);
    _krFairy(c, Offset(680 - go * 60, 270), 70, time, a3, flip: true);
  }
  // 4: kuyuya iner; dipten uğultu; ensesinde o nefes; çok derinde Erlik.
  final a4 = _krL(u, 4, 3);
  if (a4 > 0) {
    _krEarth(c, const Rect.fromLTWH(0, 0, 780, 400), const [
      Rect.fromLTWH(330, -20, 110, 300),
      Rect.fromLTWH(140, 300, 520, 120),
    ], a4);
    // İp.
    c.drawLine(
      const Offset(392, 0),
      const Offset(392, 280),
      _krLine(_ink(a4), 1.6),
    );
    // Uğultu: dipten yükselen halkalar.
    for (var i = 0; i < 4; i++) {
      final k = (time * 0.35 + i / 4) % 1;
      c.drawArc(
        Rect.fromCenter(
          center: const Offset(400, 400),
          width: 120 + k * 300,
          height: 40 + k * 140,
        ),
        math.pi,
        math.pi,
        false,
        _krLine(_krLight(0.4 * a4 * (1 - k)), 2),
      );
    }
    // Erlik: çok aşağıda, küçük ve soluk; kıpırdar.
    final stir = _span(u, 4.6, 4.95);
    c.save();
    c.translate(530, 398);
    c.rotate(-0.06 * stir * math.sin(time * 2));
    _person(
      c,
      Offset.zero,
      70,
      a4 * 0.5 * _span(u, 4.45, 4.7),
      _erlik,
      time: time,
    );
    c.restore();
    final down = _span(u, 4.05, 4.5);
    final sp = Offset(385, 110 + down * 140);
    final chill = _span(u, 4.42, 4.55) * (1 - _span(u, 4.85, 5.0));
    _krSaye(c, sp, 1.25, time, a4, shake: chill);
    // Ensesinde kara bir nefes kıvrılır.
    if (chill > 0) {
      final neck = sp + const Offset(-14, -68);
      final w = Path()..moveTo(neck.dx - 40, neck.dy + 10);
      for (var i = 1; i <= 8; i++) {
        final t = i / 8;
        w.lineTo(
          neck.dx - 40 + t * 40,
          neck.dy + 10 - t * 10 + math.sin(t * 9 + time * 4) * 6,
        );
      }
      c.drawPath(w, _krLine(_ink(0.7 * chill * a4), 4));
    }
  }
}

// ------------------------------------------------------------------ semâ

void _semazenPuppet(Canvas canvas, Offset feet, double spin, double a) {
  final ink = _ink(a);
  final hole = _hole(a * 0.8);
  canvas.save();
  canvas.translate(feet.dx, feet.dy);
  final flare = 38 + 4 * math.sin(spin * 2);
  canvas.drawPath(
    Path()
      ..moveTo(-9, -56)
      ..lineTo(9, -56)
      ..quadraticBezierTo(24, -26, flare, -2)
      ..quadraticBezierTo(0, 6, -flare, -2)
      ..quadraticBezierTo(-24, -26, -9, -56)
      ..close(),
    ink,
  );
  // Tennurenin dönen oyma delikleri.
  for (var i = 0; i < 5; i++) {
    final k = math.sin(spin + i * 1.256);
    canvas.drawCircle(Offset(k * flare * 0.7, -12), 2.2, hole);
  }
  canvas.drawRect(const Rect.fromLTWH(-8, -84, 16, 30), ink);
  canvas.drawCircle(const Offset(3, -90), 7, ink);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-2, -120, 12, 26),
      const Radius.circular(3),
    ),
    ink,
  );
  final arm = _ink(a)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(6, -80), const Offset(30, -100), arm);
  canvas.drawLine(const Offset(-6, -80), const Offset(-30, -72), arm);
  canvas.restore();
}

void _greenDome(Canvas canvas, double x, double a, {double scale = 1}) {
  canvas.save();
  canvas.translate(x, PerdePainter._ground);
  canvas.scale(scale);
  final ink = _ink(a);
  canvas.drawRect(const Rect.fromLTWH(-40, -120, 80, 120), ink);
  canvas.drawPath(
    Path()
      ..moveTo(-36, -120)
      ..lineTo(-32, -180)
      ..lineTo(0, -262)
      ..lineTo(32, -180)
      ..lineTo(36, -120)
      ..close(),
    ink,
  );
  for (var i = -2; i <= 2; i++) {
    canvas.drawLine(
      Offset(i * 12.0, -124),
      Offset(i * 2.0, -246),
      _hole(a * 0.35)..strokeWidth = 1.5,
    );
  }
  canvas.drawLine(
    const Offset(0, -262),
    const Offset(0, -282),
    ink..strokeWidth = 2,
  );
  for (final wx in [-20.0, 0.0, 20.0]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(wx - 4, -86, 8, 16),
        const Radius.circular(4),
      ),
      _hole(a * 0.8),
    );
  }
  canvas.restore();
}

void _semaScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  _fallLines(canvas, time, 0.6, snow: true, count: 40);
  _P._city(canvas, 1);
  _greenDome(canvas, 600, 1, scale: 0.9);
  // Semâzenler, düğün gecesi döner.
  final sa = _span(u, 1.6, 2.3);
  for (var i = 0; i < 5; i++) {
    final orbit = time * 0.35 + i * 2 * math.pi / 5;
    final x = 300 + math.cos(orbit) * 150;
    final depth = (math.sin(orbit) + 1) / 2;
    _semazenPuppet(
      canvas,
      Offset(x, 350 + depth * 6),
      time * 5 + i,
      sa * (0.5 + 0.5 * depth),
    );
  }
  // Neyzen: başı eğik, neyi yana tutar.
  final na = _span(u, 2.2, 2.8);
  if (na > 0) {
    final ink = _ink(na);
    canvas.drawPath(
      Path()
        ..moveTo(70, 350)
        ..lineTo(80, 290)
        ..quadraticBezierTo(96, 276, 112, 290)
        ..lineTo(122, 350)
        ..close(),
      ink,
    );
    canvas.drawCircle(const Offset(100, 278), 9, ink);
    canvas.drawRect(const Rect.fromLTWH(94, 248, 12, 24), ink);
    canvas.drawLine(
      const Offset(104, 282),
      const Offset(150, 316),
      ink..strokeWidth = 3,
    );
  }
  // Kandilciler ustayı kubbenin tepesine çıkarır.
  final ka = _span(u, 3.8, 4.4);
  if (ka > 0) {
    for (var i = 0; i < 2; i++) {
      _P._puppet(
        canvas,
        Offset(560 + i * 80.0, 350 - 262 * 0.9 + 10),
        time,
        i * 2.1,
        ka,
        (ink, hole) => _P._lamplighter(ink, hole),
        scale: 0.3,
        flip: i == 1,
        rod: false,
      );
    }
    _P._puppet(
      canvas,
      Offset(600, 350 - 262 * 0.9 + 8),
      time,
      1.3,
      ka,
      _P._master,
      scale: 0.32,
      rod: false,
    );
  }
}

// ------------------------------------------------------------------- son

/// Finalde kandilin sönüşü: perdenin ışığı (satır ilerleyişine göre).
double _endingLamp(double u) {
  if (u < 8.0) return 1;
  if (u < 8.6) return 1 - 0.88 * _P._ease((u - 8.0) / 0.6);
  if (u < 9.8) return 0.12;
  return 0.12 + 0.88 * _P._ease((u - 9.8) / 0.9);
}

void _endingScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  // Gökte kırık güneş: Sâye ışığa karışınca bir parçası yerine oturur.
  final shard = _span(u, 11.0, 12.0);
  const sun = Offset(640, 96);
  canvas.drawCircle(
    sun,
    40,
    Paint()
      ..shader = ui.Gradient.radial(sun, 40, [
        const Color(0xFFFFF4D8).withValues(alpha: 0.35 + 0.5 * shard),
        const Color(0xFFFFC870).withValues(alpha: 0),
      ]),
  );
  for (final (a, b) in [
    (const Offset(-18, -32), const Offset(4, 0)),
    (const Offset(4, 0), const Offset(-6, 34)),
    (const Offset(4, 0), const Offset(36, 10)),
  ]) {
    canvas.drawLine(
      sun + a,
      sun + b,
      _ink(0.8 - 0.5 * shard)..strokeWidth = 2.5,
    );
  }

  // Şehir, kubbe ve kar.
  _fallLines(canvas, time, 0.5, snow: true, count: 40);
  _P._city(canvas, 1);
  _greenDome(canvas, 390, 1, scale: 1.05);
  const top = Offset(390, 350 - 262 * 1.05);

  // Kandilciler halka olmuş; fenerlerinin ışığı sonunda göğe uçar.
  final freed = _span(u, 10.8, 11.8);
  final ring = _shown(u, 0.8, 12.8);
  for (var i = 0; i < 4; i++) {
    final x = 120.0 + i * 180 + (i > 1 ? 40 : 0);
    _P._puppet(
      canvas,
      Offset(x, 350),
      time,
      i * 0.9,
      ring,
      (ink, hole) {
        _P._lamplighter(
          ink,
          hole..color = _hole(ring * (1 - freed)).color,
          lanternLift: 6,
        );
      },
      scale: 0.42,
      flip: i > 1,
    );
    // Işık göğe uçar; Kandilciler yıllardır ilk kez gölge düşürür.
    if (freed > 0 && freed < 1) {
      final from = Offset(x + (i > 1 ? -38 : 38), 350 - 80);
      canvas.drawCircle(
        Offset.lerp(from, sun, freed)!,
        5 * (1 - freed) + 2,
        _hole(1 - freed * 0.5),
      );
    }
    if (freed > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + (i > 1 ? 40 : -40), 352),
          width: 70 * freed,
          height: 8,
        ),
        _ink(0.5 * freed),
      );
    }
  }

  // Usta kubbenin tepesinde, kandili elinde. Kandil Sâye'ye geçer, söner.
  final ma = _shown(u, 0.8, 8.9, 0.4);
  _P._puppet(
    canvas,
    top.translate(-26, 0),
    time,
    0.4,
    ma,
    (ink, hole) {
      _P._master(ink, hole);
    },
    scale: 0.42,
    rod: false,
  );
  final handed = _span(u, 6.0, 6.8);
  final lampAt = Offset.lerp(
    top.translate(-10, -60),
    top.translate(30, -24),
    handed,
  )!;
  final flame = u < 8.0 ? 0.6 + 0.4 * math.sin(time * 7).abs() : 0.0;
  if (u < 8.3) {
    canvas.drawCircle(
      lampAt,
      5 + flame * 2,
      _hole(0.95 * (1 - _span(u, 7.9, 8.2))),
    );
  }

  // Sâye: önce gölge, sonra ışık.
  final sa = _span(u, 1.8, 2.3);
  final glow = _span(u, 9.9, 10.8);
  canvas.save();
  canvas.translate(top.dx + 26, top.dy);
  canvas.scale(0.42);
  _P._c = canvas;
  if (glow < 1) {
    _P._saye(_ink(sa * (1 - glow)), _hole(sa * (1 - glow)), time, jar: 0);
  }
  if (glow > 0) {
    // Gölge ışığa karışmış: aynı biçim, ama ışıktan.
    _P._saye(_hole(glow), _hole(glow), time, jar: 0);
  }
  canvas.restore();
  if (glow > 0) {
    canvas.drawCircle(
      top.translate(26, -36),
      90 * glow,
      Paint()
        ..shader = ui.Gradient.radial(top.translate(26, -36), 90 * glow, [
          const Color(0xFFFFF6DC).withValues(alpha: 0.7 * glow),
          const Color(0xFFFFD08A).withValues(alpha: 0),
        ]),
    );
  }

  // Hüdhüd omzuna konar.
  final land = _span(u, 11.8, 12.6);
  if (land > 0) {
    canvas.save();
    final p = Offset.lerp(const Offset(800, 60), top.translate(36, -40), land)!;
    canvas.translate(p.dx, p.dy);
    canvas.scale(0.7);
    _P._c = canvas;
    _P._hoopoe(_ink(1), time, flying: land < 1);
    canvas.restore();
  }

  // Yol: ufka uzanan karlı bir iz.
  final road = _span(u, 12.8, 13.6);
  if (road > 0) {
    canvas.drawPath(
      Path()
        ..moveTo(390, 400)
        ..quadraticBezierTo(560, 372, 780 * road + 390 * (1 - road), 356),
      _hole(0.6 * road)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

/// Bir silueti perdede çizer: ayakların ortası [at], boyu [height] birim.
void _shape(
  Canvas canvas,
  Path shape,
  Offset at,
  double height,
  Paint p, {
  bool flip = false,
  double rotate = 0,
}) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(rotate);
  canvas.scale((flip ? -1 : 1) * height / 100, height / 100);
  canvas.drawPath(shape, p);
  canvas.restore();
}

void _akAnaScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  // İlk su: perdenin altını dolduran dalgalı su; çamurdan dünya kalkınca
  // çekilir.
  final land = _span(u, 3.0, 3.8);
  final waterTop = 250.0 + land * 40;
  final water = Path()..moveTo(0, 400);
  for (var x = 0.0; x <= 780; x += 12) {
    water.lineTo(
      x,
      waterTop +
          math.sin(time * 1.4 + x / 46) * 5 +
          math.sin(time + x / 23) * 2,
    );
  }
  water
    ..lineTo(780, 400)
    ..close();
  canvas.drawPath(water, _ink(0.75));
  // Suyun yüzünde ışık kırıntıları.
  for (var i = 0; i < 9; i++) {
    final x = 40.0 + i * 86 + math.sin(time * 0.7 + i) * 10;
    canvas.drawCircle(Offset(x, waterTop + 14), 2, _hole(0.35));
  }
  // Kayra Han: suyun üstünde yalnız, kolları açık.
  final kayra = _span(u, 0.8, 1.4) * (1 - _span(u, 4.2, 4.8));
  if (kayra > 0) {
    _shape(
      canvas,
      MythShapes.kam,
      Offset(200, 150 + math.sin(time * 0.6) * 4),
      120,
      _ink(kayra),
    );
  }
  // Ak Ana sudan yükselir; "yarat" deyip yeniden suya döner.
  final rise = _span(u, 1.8, 2.6) * (1 - _span(u, 2.9, 3.4));
  if (rise > 0) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, 780, waterTop + 6));
    _shape(
      canvas,
      MythShapes.akAna,
      Offset(470, waterTop + 150 - 150 * rise),
      150,
      _ink(1),
    );
    // Başının ardında ışıktan bir hâle (perdede delik).
    canvas.drawCircle(
      Offset(470, waterTop + 150 - 150 * rise - 138),
      22,
      _hole(0.45 * rise),
    );
    canvas.restore();
  }
  // Çamurdan dünya kalkar.
  if (land > 0) {
    final hill = Path()..moveTo(80, 400);
    for (var x = 80.0; x <= 700; x += 10) {
      final k = (x - 80) / 620;
      hill.lineTo(
        x,
        400 -
            land * 120 * math.sin(k * math.pi) * (0.8 + 0.2 * math.sin(k * 9)),
      );
    }
    hill
      ..lineTo(700, 400)
      ..close();
    canvas.drawPath(hill, _ink(1));
  }
  // Erlik kendini büyük sanır, yerin altına sürülür: perdenin dibine düşer.
  final fall = _span(u, 3.3, 4.1);
  if (fall > 0 && fall < 1) {
    _shape(
      canvas,
      MythShapes.kam,
      Offset(600, 180 + fall * 260),
      90,
      _ink(1 - fall * 0.6),
      rotate: fall * 2.4,
    );
  }
  // Çalınan ışıklar yerin altına akar; Sâye bir damla gibi ardından iner.
  final flow = _span(u, 4.0, 4.9);
  if (flow > 0) {
    for (var i = 0; i < 7; i++) {
      final k = ((flow * 1.6 + i / 7) % 1.0);
      canvas.drawCircle(
        Offset(380 + math.sin(i * 2.3) * 40, 140 + k * 240),
        3.5,
        _hole(0.8 * (1 - k)),
      );
    }
    final sa = _span(u, 4.4, 4.9);
    _P._puppet(canvas, Offset(390, 140 + sa * 120), time, 1.2, sa, (ink, hole) {
      _P._saye(ink, hole, time);
    }, scale: 0.4);
  }
}

/// Satır [k] okunurken (u: k..k+1) beliren, sonunda sönen görünürlük.
double _line(double u, double k) =>
    _span(u, k + 0.05, k + 0.35) * (1 - _span(u, k + 0.85, k + 1.0));

void _ergenekonScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  const g = PerdePainter._ground;
  // Ortadaki demir dağ erir: tepesi alçalır, dibinde akkor yarık açılır.
  final melt = _span(u, 4.0, 4.7);
  // Dört yanı aşılmaz dağlar: iki yanda yüksek, ortada demir dağ.
  canvas.drawPath(
    Path()
      ..moveTo(0, g)
      ..lineTo(0, 60)
      ..lineTo(90, 30)
      ..lineTo(170, 120)
      ..lineTo(230, g)
      ..close(),
    _ink(0.55),
  );
  canvas.drawPath(
    Path()
      ..moveTo(780, g)
      ..lineTo(780, 50)
      ..lineTo(700, 40)
      ..lineTo(610, 130)
      ..lineTo(560, g)
      ..close(),
    _ink(0.55),
  );
  final peak = 90 + melt * 170;
  canvas.drawPath(
    Path()
      ..moveTo(300, g)
      ..lineTo(395, peak)
      ..lineTo(490, g)
      ..close(),
    _ink(0.7),
  );
  if (melt > 0) {
    // Akkor yarık: perdede ışık sızan bir çatlak.
    canvas.drawPath(
      Path()
        ..moveTo(380, g)
        ..lineTo(395, g - 120 * melt)
        ..lineTo(410, g)
        ..close(),
      _hole(0.8 * melt),
    );
  }
  canvas.drawRect(Rect.fromLTWH(0, g, 780, 50), _ink(1));
  // Vadi yeşerir: meyve ağaçları ve atlar.
  final green = _span(u, 1.0, 1.8);
  if (green > 0) {
    for (final x in [250.0, 520.0, 545.0]) {
      _shape(
        canvas,
        MythShapes.umayTree,
        Offset(x, g + 30 * 0.7),
        70 * green,
        _ink(green),
      );
    }
    for (var i = 0; i < 3; i++) {
      _shape(
        canvas,
        MythShapes.horse,
        Offset(270 + i * 34.0, g),
        28,
        _ink(green * (1 - melt * 0.5)),
        flip: i.isOdd,
      );
    }
  }
  // Kıyan ile Nüküz, eşleriyle: keçi yolundan vadiye iner.
  final walk = _span(u, 0.1, 0.9);
  final people = _span(u, 0.05, 0.3) * (1 - _span(u, 3.0, 3.3));
  if (people > 0) {
    for (var i = 0; i < 4; i++) {
      final x = 40 + walk * 160 - i * 26.0;
      _person(
        canvas,
        Offset(x, g),
        i.isEven ? 62 : 58,
        people,
        const [_kiyan, _woman, _nukuz, _woman2][i],
        time: time,
      );
    }
  }
  // Dört yüz yıl: boy çoğalır.
  final crowd = _span(u, 2.0, 2.6) * (1 - _span(u, 5.8, 6.1));
  if (crowd > 0) {
    for (var i = 0; i < 9; i++) {
      final x = 520 + (i % 5) * 34.0 - melt * 120 - _span(u, 4.4, 5.0) * 200;
      _person(
        canvas,
        Offset(x, g),
        40 + (i % 3) * 4.0,
        crowd * 0.9,
        const [_shepherd, _woman, _kiyan, _woman2, _worker][i % 5],
        flip: true,
        time: time + i,
      );
    }
  }
  // Demirci ve yetmiş körük: dağın dibinde sıra sıra deri körükler, ateş.
  final forge = _span(u, 3.0, 3.4);
  if (forge > 0) {
    for (var i = 0; i < 9; i++) {
      final x = 292 + i * 22.0;
      final pump = 0.5 + 0.5 * math.sin(time * 6 + i);
      canvas.drawRect(
        Rect.fromLTWH(x - 8, g - 6 - 6 * pump, 16, 6 + 6 * pump),
        _ink(forge),
      );
      canvas.drawCircle(
        Offset(x, g - 3),
        2.5,
        _hole(forge * (0.4 + 0.5 * pump)),
      );
    }
  }
  // Yolu gösteren kurt: eriyen yarıktan çıkar, boy ardından.
  final wolf = _span(u, 4.3, 5.0);
  if (wolf > 0 && wolf < 1) {
    _shape(
      canvas,
      MythShapes.wolfWalk,
      Offset(395 - 40 + wolf * 340, g),
      42,
      _ink(1),
    );
  }
  // Kutsal gün: örsün üstünde kızgın demir, çekiç iner; doğan güneş.
  final anvil = _span(u, 5.0, 5.4) * (1 - _span(u, 5.85, 6.0));
  if (anvil > 0) {
    canvas.drawCircle(
      Offset(640, 110 - 20 * _span(u, 5.0, 6.0)),
      34,
      _hole(0.6 * anvil),
    );
    canvas.drawPath(
      Path()
        ..moveTo(330, g - 26)
        ..lineTo(390, g - 26)
        ..lineTo(380, g - 16)
        ..lineTo(370, g - 14)
        ..lineTo(370, g)
        ..lineTo(350, g)
        ..lineTo(350, g - 14)
        ..lineTo(340, g - 16)
        ..close(),
      _ink(anvil),
    );
    canvas.drawRect(Rect.fromLTWH(346, g - 30, 26, 4), _hole(anvil));
    final strike = math.pow((time * 1.2) % 1, 3).toDouble();
    _shape(canvas, MythShapes.kam, Offset(300, g), 80, _ink(anvil));
    final hand = const Offset(300 + 20, g - 37);
    final ang = -2.2 + strike * 1.5;
    canvas.drawLine(
      hand,
      hand + Offset(math.cos(ang), math.sin(ang)) * 30,
      _ink(anvil)..strokeWidth = 4,
    );
  }
  // Kahramanlar perdeyi doldurur: Demirci (körükler satırı), Bozkurt (dağ
  // eridi satırı); son satırda ana iplik.
  final smith = _enter(u, 3) * (1 - _leave(u, 3));
  if (smith > 0) {
    _veil(canvas, smith);
    _tasvirDemirci(
      canvas,
      Offset(250 - 60 * (1 - smith), g + 12),
      1.12,
      time,
      smith,
    );
  }
  final wolfHero = _enter(u, 4) * (1 - _leave(u, 4));
  if (wolfHero > 0) {
    _veil(canvas, wolfHero);
    _tasvirBozkurt(
      canvas,
      Offset(330 + 120 * _span(u, 4.0, 5.0), g + 10),
      240,
      time,
      wolfHero,
    );
  }
  _chaseBeat(canvas, time, u, 6);
}

void _gokScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  const g = PerdePainter._ground;
  // Üst üste bulut katları.
  for (var k = 0; k < 3; k++) {
    final y = 300.0 - k * 95;
    final band = Path()..moveTo(0, y + 30);
    for (var x = 0.0; x <= 780; x += 20) {
      band.lineTo(x, y + math.sin(x / 40 + k + time * 0.3) * 6);
    }
    band
      ..lineTo(780, y + 30)
      ..close();
    canvas.drawPath(band, _ink(0.25 + k * 0.08));
  }
  canvas.drawRect(Rect.fromLTWH(0, g, 780, 50), _ink(1));
  // Kam davulunu çalar; canlar göğe yükselir.
  final kam = _span(u, 0.05, 0.4) * (1 - _span(u, 4.6, 5.0));
  if (kam > 0) {
    _shape(canvas, MythFigures.kamSilhouette, Offset(120, g), 110, _ink(kam));
    final beat = (time * 1.4) % 1;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(84, g - 58), width: 26, height: 36),
      _ink(kam),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(84, g - 58), width: 14, height: 22),
      _hole(kam * (0.3 + 0.6 * (1 - beat))),
    );
    for (var i = 0; i < 5; i++) {
      final k = ((time * 0.25 + i / 5) % 1);
      canvas.drawCircle(
        Offset(120 + math.sin(i * 2.1 + time) * 20, g - 120 - k * 200),
        3,
        _hole(kam * (1 - k)),
      );
    }
  }
  // Ülgen'in ışığı en yüksek katta.
  final ulgen = _span(u, 1.05, 1.5);
  if (ulgen > 0) {
    const at = Offset(390, 40);
    canvas.drawCircle(at, 26 + 3 * math.sin(time * 2), _hole(0.9 * ulgen));
    final ray = _hole(0.5 * ulgen)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2 + time * 0.1;
      canvas.drawLine(
        at + Offset(math.cos(a), math.sin(a)) * 32,
        at + Offset(math.cos(a), math.sin(a)) * (52 + 8 * math.sin(time + i)),
        ray,
      );
    }
  }
  // Ay ve güneş: bir katta soğuk, bir katta yakıcı.
  final sky = _span(u, 2.05, 2.5);
  if (sky > 0) {
    canvas.drawCircle(const Offset(180, 120), 24, _hole(0.6 * sky));
    canvas.drawCircle(const Offset(192, 114), 22, _ink(sky));
    canvas.drawCircle(const Offset(600, 110), 30, _hole(0.85 * sky));
  }
  // Hüma geçer; Tulpar uçar.
  final fly = _line(u, 3);
  if (fly > 0) {
    final k = _span(u, 3, 4);
    _shape(
      canvas,
      MythShapes.birdGlide,
      Offset(100 + k * 600, 170),
      34,
      _ink(fly),
    );
    final tx = 700 - k * 560;
    _shape(
      canvas,
      MythShapes.horse,
      Offset(tx, 240),
      60,
      _ink(fly),
      flip: true,
    );
    canvas.save();
    canvas.translate(tx - 4, 240 - 42);
    canvas.rotate(math.sin(time * 3) * 0.3);
    canvas.scale(-0.6, 0.6);
    canvas.drawPath(MythFigures.wingSilhouette, _ink(fly));
    canvas.restore();
  }
  // Kırık güneşin parçası en yüksek katta; Sâye davul vuruşlarıyla yükselir.
  final rise = _span(u, 4.0, 4.9);
  if (rise > 0) {
    canvas.drawPath(
      Path()
        ..moveTo(560, 50)
        ..lineTo(600, 40)
        ..lineTo(590, 80)
        ..close(),
      _hole(rise),
    );
    for (var i = 0; i < 4; i++) {
      final on = ((time * 1.4).floor() + i) % 2 == 0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(330 + i * 40.0, g - 40 - i * 50, 44, 8),
          const Radius.circular(4),
        ),
        _hole(rise * (on ? 0.8 : 0.2)),
      );
    }
    _P._puppet(
      canvas,
      Offset(350 + rise * 120, g - 40 - rise * 150),
      time,
      2,
      rise,
      (ink, hole) {
        _P._saye(ink, hole, time);
      },
      scale: 0.45,
    );
  }
}

/// Ötüken: Sâye köklerden yukarı tırmanır, orman açılır; Kül Tigin'in taşı,
/// Hayat Ağacı ve dallarındaki can kuşları; Karabasan sürünür, yapraklardan
/// süzülen ışıktan geri çekilir.
void _otukenScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  const g = PerdePainter._ground;
  // 0: yerin altı. Tavandan kökler sarkar, Sâye birine tutunup yükselir.
  final under = 1 - _span(u, 0.85, 1.1);
  final forest = _span(u, 0.9, 1.4);
  if (under > 0) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 780, 70), _ink(under));
    final root = _ink(under)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = 50.0 + i * 85;
      root.strokeWidth = 7 - (i % 3) * 1.5;
      final path = Path()..moveTo(x, 60);
      for (var y = 60.0; y < 300 - (i % 4) * 40; y += 20) {
        path.lineTo(x + math.sin(y / 30 + i) * 10, y);
      }
      canvas.drawPath(path, root);
    }
    final climb = _span(u, 0.1, 0.9);
    _P._puppet(
      canvas,
      Offset(390 + math.sin(time * 2) * 3, 330 - climb * 220),
      time,
      1,
      under,
      (ink, hole) => _P._saye(ink, hole, time),
      scale: 0.5,
      rod: false,
    );
    // Yukarıdan sızan ilk ışık.
    canvas.drawCircle(
      const Offset(400, 40),
      30 + 10 * climb,
      _hole(0.4 * climb * under),
    );
  }
  if (forest <= 0) return;
  // Uzak orman: kayınlar ve çamlar, arada kuşlar.
  for (var i = 0; i < 12; i++) {
    final x = 20.0 + i * 68 + (i % 3) * 9;
    final h = 150.0 + (i * 37 % 60);
    final a = forest * (0.45 + (i % 2) * 0.2);
    if (i.isEven) {
      // Çam: üst üste üçgenler.
      for (var k = 0; k < 4; k++) {
        final y = g - h + k * h / 5;
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x - 18 - k * 6, y + h / 4)
            ..lineTo(x + 18 + k * 6, y + h / 4)
            ..close(),
          _ink(a),
        );
      }
    } else {
      // Kayın: ince gövde, salkım dallar; gövdede delik izler.
      canvas.drawRect(Rect.fromLTWH(x - 4, g - h, 8, h), _ink(a));
      for (var k = 0; k < 4; k++) {
        canvas.drawRect(
          Rect.fromLTWH(x - 3, g - h + 20 + k * 30, 5, 2.5),
          _hole(0.5 * a),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, g - h), width: 70, height: 60),
        _ink(a * 0.8),
      );
    }
  }
  canvas.drawRect(Rect.fromLTWH(0, g, 780, 50), _ink(forest));
  // Kuşlar uçuşur.
  for (var i = 0; i < 4; i++) {
    final k = (time * 0.06 + i / 4) % 1;
    _shape(
      canvas,
      i.isEven ? MythShapes.birdGlide : MythShapes.birdFlap,
      Offset(k * 820 - 20, 80 + i * 22 + math.sin(time + i) * 6),
      12,
      _ink(forest * 0.8),
    );
  }
  // 2: Kül Tigin'in taşı, üstünde oyma yazı.
  final stone = _line(u, 2);
  if (stone > 0) {
    final rr = RRect.fromRectAndCorners(
      Rect.fromLTWH(600, g - 150, 70, 150),
      topLeft: const Radius.circular(26),
      topRight: const Radius.circular(26),
    );
    canvas.drawRRect(rr, _ink(stone));
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 4; col++) {
        final h = (row * 7 + col * 13) % 5;
        final at = Offset(612.0 + col * 14, g - 120 + row * 16.0);
        canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..lineTo(at.dx + 4 + h, at.dy + 6)
            ..lineTo(at.dx + (h.isEven ? 0 : 8), at.dy + 11),
          _hole(stone * 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }
  // 3-7: Hayat Ağacı ortada yükselir; dallarında can kuşları.
  final tree = _span(u, 3.0, 3.6);
  if (tree > 0) {
    final trunk = Path()
      ..moveTo(360, g)
      ..quadraticBezierTo(372, g - 120 * tree, 380, g - 230 * tree)
      ..lineTo(400, g - 230 * tree)
      ..quadraticBezierTo(408, g - 120 * tree, 422, g)
      ..close();
    canvas.drawPath(trunk, _ink(tree));
    // Kökler toprağın altına iner.
    final root = _ink(tree)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    for (final dx in [-60.0, -25.0, 20.0, 55.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(390, g)
          ..quadraticBezierTo(390 + dx, g + 10, 390 + dx * 1.6, g + 40),
        root,
      );
    }
    final branch = _ink(tree)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final perch = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final y = g - 110 - i * 22.0;
      final len = (130 - i * 14) * tree;
      branch.strokeWidth = 8.0 - i;
      final end = Offset(390 + side * len, y - 40 - i * 4);
      canvas.drawPath(
        Path()
          ..moveTo(390, y)
          ..quadraticBezierTo(390 + side * len * 0.5, y - 4, end.dx, end.dy),
        branch,
      );
      perch.add(end + const Offset(0, -6));
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(390, g - 270 * tree),
        width: 300 * tree,
        height: 90 * tree,
      ),
      _ink(tree * 0.85),
    );
    // Dallarda can kuşları (delik ışık); Umay en tepede süzülür.
    final birds = _span(u, 3.3, 3.8);
    for (var i = 0; i < perch.length; i++) {
      final b = perch[i];
      canvas.drawOval(
        Rect.fromCenter(center: b, width: 12, height: 8),
        _hole(birds * (0.6 + 0.3 * math.sin(time * 2 + i))),
      );
    }
    if (birds > 0) {
      canvas.save();
      canvas.translate(390 + math.sin(time * 0.5) * 80, 45);
      canvas.scale(0.5);
      canvas.drawPath(
        MythShapes.birdGlide.shift(const Offset(-52, -20)),
        _ink(birds),
      );
      canvas.restore();
    }
  }
  // 4-6: Karabasan soldan sürünür; 6'da ışık huzmeleri onu geri iter.
  final dark = _span(u, 4.0, 4.5) * (1 - _span(u, 6.3, 6.9));
  final beams = _span(u, 6.0, 6.4);
  if (beams > 0) {
    for (var i = 0; i < 4; i++) {
      final x = 140.0 + i * 150;
      canvas.drawPath(
        Path()
          ..moveTo(x - 10, 0)
          ..lineTo(x + 18, 0)
          ..lineTo(x + 60, g)
          ..lineTo(x + 10, g)
          ..close(),
        _hole(beams * 0.35),
      );
    }
  }
  if (dark > 0) {
    final creep = _span(u, 4.0, 5.8);
    final back = _span(u, 6.1, 6.8);
    final cx = 40 + creep * 170 - back * 160;
    final c = Offset(cx, g - 50);
    final blob = Path();
    for (var i = 0; i <= 20; i++) {
      final a = i / 20 * math.pi * 2;
      final r = 62 + 12 * math.sin(time * 3 + i * 1.7);
      final p = c + Offset(math.cos(a) * r * 1.2, math.sin(a) * r * 0.75);
      i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(blob..close(), _ink(dark));
    final arm = _ink(dark)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      arm.strokeWidth = 7.0 - i;
      final reach = 70 + 20 * math.sin(time * 2.4 + i) - back * 60;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + 50, c.dy - 30 + i * 18)
          ..quadraticBezierTo(
            c.dx + 50 + reach * 0.5,
            c.dy - 50 + i * 20,
            c.dx + 50 + reach,
            c.dy - 20 + i * 14,
          ),
        arm,
      );
    }
    final blink = (time % 4) < 0.15 ? 0.2 : 1.0;
    for (final dx in [-14.0, 14.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(dx + 20, -16),
          width: 14,
          height: 6 * blink,
        ),
        _hole(dark),
      );
    }
    // Sâye ışığa doğru kaçar.
    _P._puppet(
      canvas,
      Offset(250 + creep * 120 + back * 60, g),
      time,
      3,
      dark,
      (ink, hole) => _P._saye(ink, hole, time),
      scale: 0.5,
    );
  }
  // Ak Geyik: ışıkta, ağacın yanında belirir (son satırlarda).
  final deer = _span(u, 6.4, 6.9);
  if (deer > 0) {
    canvas.save();
    canvas.translate(520, g);
    canvas.scale(-0.75, 0.75);
    canvas.drawPath(DeerRig.frame(0, still: true, alert: 1).shape, _ink(deer));
    canvas.restore();
  }
}
