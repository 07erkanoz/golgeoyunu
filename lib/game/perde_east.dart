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
  final float = level < 112;
  final ay = math.min(level, 112.0);
  final bob = float ? math.sin(time * 1.6) * 4 : 0.0;
  canvas.save();
  canvas.translate(330, ay - 8 + bob);
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

void _camel(Paint ink, Paint hole, double time, {bool load = true}) {
  final c = _P._c;
  final step = math.sin(time * 3);
  c.drawOval(const Rect.fromLTWH(-40, -70, 80, 34), ink);
  c.drawOval(const Rect.fromLTWH(-20, -92, 36, 34), ink);
  c.drawPath(
    Path()
      ..moveTo(34, -60)
      ..quadraticBezierTo(50, -70, 52, -96)
      ..lineTo(66, -100)
      ..lineTo(68, -92)
      ..lineTo(58, -90)
      ..quadraticBezierTo(54, -60, 38, -46)
      ..close(),
    ink,
  );
  for (final (x, ph) in [
    (-30.0, 0.0),
    (-20.0, 2.0),
    (22.0, 1.0),
    (32.0, 3.0),
  ]) {
    final sw = math.sin(time * 3 + ph) * 6;
    c.drawLine(Offset(x, -40), Offset(x + sw, 0), ink..strokeWidth = 5);
  }
  if (load) {
    // Palan ve yük.
    c.drawRect(const Rect.fromLTWH(-30, -110, 50, 22), ink);
    c.drawCircle(const Offset(-5, -100), 3, hole);
  }
  c.drawCircle(Offset(56, -94 + step), 1.6, hole);
}

void _caravanScene(
  Canvas canvas,
  double time,
  double u, {
  bool avalanche = false,
}) {
  _P._c = canvas;
  // İki doruk: Büyük Ejder ve Küçük Ejder. Doruklarda uyuyan ejderler.
  canvas.drawPath(
    Path()
      ..moveTo(0, 300)
      ..lineTo(180, 90)
      ..lineTo(260, 150)
      ..lineTo(420, 60)
      ..lineTo(560, 200)
      ..lineTo(780, 260)
      ..lineTo(780, 400)
      ..lineTo(0, 400)
      ..close(),
    _ink(0.45),
  );
  final eye = avalanche ? _span(u, 0.6, 1.0) : _span(u, 2.6, 3.2) * 0.4;
  for (final (x, y, s) in [(420.0, 60.0, 1.0), (180.0, 90.0, 0.7)]) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(s);
    // Ejder doruğa sarılmış: pullu gövde, sırtında dikenler, boynuzlu baş.
    final spine = <Offset>[
      for (var i = 0; i <= 16; i++)
        Offset(-64 + i * 8.0, 30 - math.sin(i / 16 * math.pi) * 44),
    ];
    final body = Path()..moveTo(spine.first.dx, spine.first.dy);
    for (final q in spine.skip(1)) {
      body.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      body,
      _ink(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 1; i < spine.length - 1; i += 2) {
      final q = spine[i];
      canvas.drawPath(
        Path()
          ..moveTo(q.dx - 4, q.dy - 4)
          ..lineTo(q.dx + 1, q.dy - 15)
          ..lineTo(q.dx + 5, q.dy - 4)
          ..close(),
        _ink(0.75),
      );
    }
    // Kuyruk ucu ve baş.
    canvas.drawPath(
      Path()
        ..moveTo(64, 30)
        ..lineTo(80, 40)
        ..lineTo(70, 24)
        ..close(),
      _ink(0.75),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-60, 22)
        ..lineTo(-96, 24)
        ..lineTo(-100, 32)
        ..lineTo(-78, 34)
        ..lineTo(-60, 38)
        ..close(),
      _ink(0.75),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-66, 22)
        ..lineTo(-58, 4)
        ..lineTo(-60, 22)
        ..close(),
      _ink(0.75),
    );
    if (eye > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(-78, 27),
          width: 6,
          height: 4 * eye,
        ),
        _hole(eye),
      );
    }
    canvas.restore();
  }
  // Yamaç.
  canvas.drawPath(
    Path()
      ..moveTo(0, 230)
      ..lineTo(780, 360)
      ..lineTo(780, 400)
      ..lineTo(0, 400)
      ..close(),
    _ink(1),
  );
  _fallLines(canvas, time, 1, snow: true);

  // Kervan yokuştan iner: develer, Kandilciler, zincirli usta.
  final walk = (u * 40 + time * 6) % 900;
  double slopeY(double x) => 230 + x * (130 / 780);
  final members = <(double, int)>[
    (0, 0),
    (-90, 1),
    (-170, 2),
    (-250, 0),
    (-340, 1),
  ];
  for (final (dx, kind) in members) {
    final x = 120 + walk * 0.4 + dx;
    if (x < -80 || x > 860) continue;
    final y = slopeY(x);
    canvas.save();
    canvas.translate(x, y + 2);
    canvas.rotate(0.16);
    final ink = _ink(1);
    final hole = _hole(0.9);
    _P._c = canvas;
    switch (kind) {
      case 0:
        canvas.scale(0.55);
        // İlk devenin palanı yokuşta kayıp düşer.
        final slip = dx == 0 ? _span(u, 1.1, 1.6) : 0.0;
        _camel(ink, hole, time, load: slip == 0);
        if (slip > 0 && slip < 1) {
          canvas.drawRect(
            Rect.fromLTWH(-30 - slip * 120, -110 + slip * slip * 160, 50, 22),
            ink,
          );
        }
      case 1:
        canvas.scale(0.4);
        _P._lamplighter(ink, hole);
      default:
        canvas.scale(0.42);
        _P._master(ink, hole);
        // Zincir: önündeki Kandilci'ye.
        canvas.drawLine(
          const Offset(30, -60),
          const Offset(150, -110),
          ink..strokeWidth = 2,
        );
        // Göğsündeki kandil, mum kadar kalmış.
        canvas.drawCircle(
          const Offset(18, -96),
          3 + math.sin(time * 6),
          _hole(0.9),
        );
    }
    canvas.restore();
  }

  // Çığ: doruktan beyaz bir dalga iner.
  if (avalanche) {
    final roll = _span(u, 1.0, 2.4);
    if (roll > 0) {
      final x = 420 + roll * 420;
      final y = 60 + roll * 280;
      canvas.drawPath(
        Path()
          ..moveTo(x - 260, y - 150)
          ..quadraticBezierTo(x - 40, y - 120, x, y)
          ..quadraticBezierTo(x - 100, y + 60, x - 300, y + 40)
          ..close(),
        _hole(0.85),
      );
    }
  }
  // Sâye karın üstünde, kervanı izler.
  final sa = _span(u, 0.4, 0.9);
  _P._puppet(canvas, Offset(60, slopeY(60)), time, 1.4, sa, (ink, hole) {
    _P._saye(ink, hole, time);
  }, scale: 0.6);
}

// ---------------------------------------------------------------- periler

void _fairy(Canvas canvas, Offset p, double time, double a, double seed) {
  final ink = _ink(a);
  final f = math.sin(time * 10 + seed) * 6;
  canvas.drawCircle(p.translate(0, -12), 4, ink);
  canvas.drawPath(
    Path()
      ..moveTo(p.dx - 4, p.dy - 8)
      ..lineTo(p.dx + 4, p.dy - 8)
      ..lineTo(p.dx + 6, p.dy + 6)
      ..lineTo(p.dx - 6, p.dy + 6)
      ..close(),
    ink,
  );
  for (final s in [-1.0, 1.0]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: p.translate(s * 9, -10 - f * 0.4),
        width: 14,
        height: 8 + f.abs(),
      ),
      _ink(a * 0.6),
    );
  }
  // Elinde kar: ışık deliği.
  canvas.drawCircle(p.translate(7, -2), 2, _hole(a));
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
  // Erciyes: ağzından ateş akan dağ.
  canvas.drawPath(
    Path()
      ..moveTo(0, 352)
      ..lineTo(150, 120)
      ..lineTo(190, 120)
      ..lineTo(360, 352)
      ..close(),
    _ink(0.85),
  );
  final fire = 1 - _span(u, 1.6, 2.2);
  if (fire > 0) {
    for (var i = 0; i < 5; i++) {
      final x = 150 + i * 10.0;
      final f = math.sin(time * 8 + i) * 6;
      canvas.drawPath(
        Path()
          ..moveTo(x - 8, 122)
          ..quadraticBezierTo(x + f, 80, x + 4, 50 - i * 6.0)
          ..quadraticBezierTo(x + 10, 90, x + 10, 122)
          ..close(),
        _ink(fire),
      );
    }
  }
  // Devler: başları dağlara değer; peri karıyla yere batarlar.
  final sink = _span(u, 1.8, 2.6);
  canvas.save();
  canvas.clipRect(const Rect.fromLTWH(0, 0, 780, 352));
  for (final (x, s) in [(300.0, 1.0), (420.0, 0.85)]) {
    canvas.save();
    canvas.translate(x, 352 + sink * 300);
    canvas.scale(s * 1.4);
    _P._master(_ink(0.9), _hole(0.0));
    canvas.restore();
  }
  canvas.restore();
  // Periler sağdan gelir.
  final fly = _span(u, 0.8, 1.8);
  final fa = _shown(u, 0.8, 3.0);
  for (var i = 0; i < 12; i++) {
    final x = 820 - fly * (380 + (i % 4) * 40) + math.sin(time + i) * 10;
    final y = 80 + (i * 37) % 160 + math.cos(time * 1.3 + i) * 8;
    _fairy(canvas, Offset(x, y), time, fa, i * 1.1);
  }
  // Zemin ve küllerden yükselen bacalar.
  canvas.drawRect(const Rect.fromLTWH(0, 350, 780, 50), _ink(1));
  final grow = _span(u, 2.4, 3.2);
  for (final (x, h) in [
    (470.0, 150.0),
    (540.0, 200.0),
    (610.0, 130.0),
    (690.0, 180.0),
  ]) {
    final top = 350 - h * grow;
    canvas.drawPath(
      Path()
        ..moveTo(x - 22, 352)
        ..quadraticBezierTo(x - 14, top + 30, x - 8, top + 14)
        ..lineTo(x + 8, top + 14)
        ..quadraticBezierTo(x + 14, top + 30, x + 22, 352)
        ..close(),
      _ink(1),
    );
    // Bazalt şapka.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, top + 12), width: 34, height: 14),
      _ink(1),
    );
    if (grow > 0.8) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, top + 60), width: 6, height: 10),
          const Radius.circular(3),
        ),
        _hole(grow),
      );
    }
  }
  // Sâye bir bacanın tepesinde.
  final sa = _span(u, 3.2, 3.6);
  _P._puppet(canvas, Offset(540, 350 - 200 * grow + 8), time, 0.8, sa, (
    ink,
    hole,
  ) {
    _P._saye(ink, hole, time);
  }, scale: 0.5);
}

void _undergroundScene(Canvas canvas, double time, double u) {
  // Kesit: yukarıda ova, aşağıda katlar, en dipte uyuyan dev.
  canvas.drawRect(const Rect.fromLTWH(0, 120, 780, 280), _ink(0.95));
  // Kuyu ağzı ve oyulmuş katlar.
  final carve = _hole(0.35);
  canvas.drawRect(const Rect.fromLTWH(372, 120, 36, 220), carve);
  for (final (y, x0, x1) in [
    (160.0, 200.0, 560.0),
    (220.0, 120.0, 640.0),
    (280.0, 240.0, 700.0),
  ]) {
    canvas.drawRect(Rect.fromLTWH(x0, y, x1 - x0, 26), carve);
  }
  // Yuvarlak taş kapı.
  final roll = _span(u, 1.8, 2.4);
  canvas.drawCircle(Offset(560 - roll * 30, 173), 14, _ink(1));
  canvas.drawCircle(Offset(560 - roll * 30, 173), 4, _hole(0.6));
  // Kandilcilerin fenerleri birer birer iner.
  for (var i = 0; i < 4; i++) {
    final k = _span(u, 0.4 + i * 0.25, 1.6 + i * 0.25);
    if (k <= 0) continue;
    canvas.drawCircle(Offset(390, 120 + k * 210), 4, _hole(0.9));
  }
  // Dev uyur: nefesiyle ışık söner.
  final breath = 0.5 + 0.5 * math.sin(time * 0.8);
  canvas.save();
  canvas.translate(390, 396);
  canvas.rotate(-math.pi / 2);
  canvas.scale(0.9);
  _P._master(_ink(0.6 + 0.2 * breath), _hole(0));
  canvas.restore();
  // Sâye kuyunun ağzında.
  final sa = _span(u, 2.6, 3.0);
  _P._puppet(canvas, const Offset(350, 120), time, 1.2, sa, (ink, hole) {
    _P._saye(ink, hole, time);
  }, scale: 0.55);
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
