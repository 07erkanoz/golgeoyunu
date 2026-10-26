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

/// Nuh'un gemisi, direğiyle: [at] teknenin ortası, [s] ölçek. Direğin
/// tepesi: at + (-5, -150) × s.
void _agArk(Canvas c, Offset at, double s, double a, {double light = 0}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(s);
  final ink = _ink(a);
  c.drawLine(
    const Offset(-5, -76),
    const Offset(-5, -150),
    Paint()
      ..color = ink.color
      ..strokeWidth = 4,
  );
  // Direğin tepesinde flama.
  c.drawPath(
    Path()
      ..moveTo(-3, -150)
      ..lineTo(22, -144)
      ..lineTo(-3, -138)
      ..close(),
    ink,
  );
  _arkShape(ink, _hole(0.8 * a), light * a);
  c.restore();
}

/// Ak Ana: ak saçlı, ak giysili; bedeni ışıktan, her yanından ışık
/// süzülür. Ayakları [feet]'te, boyu [h].
void _agAkAna(Canvas c, Offset feet, double h, double time, double a) {
  if (a <= 0.01) return;
  final s = h / 100;
  final mid = feet.translate(0, -h * 0.6);
  c.drawCircle(
    mid,
    h * 0.9,
    Paint()
      ..shader = ui.Gradient.radial(mid, h * 0.9, [
        const Color(0xFFFFFBEA).withValues(alpha: 0.75 * a),
        const Color(0x00FFFBEA),
      ]),
  );
  // Işık hüzmeleri.
  final ray = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFF8E0).withValues(alpha: 0.5 * a);
  for (var i = 0; i < 10; i++) {
    final ang =
        -math.pi / 2 + (i - 4.5) * 0.3 + math.sin(time * 0.8 + i) * 0.04;
    c.drawLine(
      mid + Offset(math.cos(ang), math.sin(ang)) * h * 0.45,
      mid + Offset(math.cos(ang), math.sin(ang)) * h * 0.8,
      ray,
    );
  }
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.2) * 1.5);
  c.scale(s);
  final body = MythFigures.akAnaSilhouette;
  c.drawPath(
    body,
    Paint()..color = const Color(0xFFFFFCF2).withValues(alpha: a),
  );
  c.drawPath(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 / s
      ..color = PerdePainter._ink.withValues(alpha: 0.75 * a),
  );
  c.restore();
}

/// Tasvir hayvanı ve gölgesi: [shadow] eşinden kopmuş soluk gölge.
void _agBeast(
  Canvas c,
  Path shape,
  Offset feet,
  double h,
  double a, {
  bool flip = false,
  bool shadow = false,
}) {
  if (a <= 0.01) return;
  final s = h / 100;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(flip ? -s : s, s);
  c.drawPath(shape, shadow ? _ink(0.38 * a) : _ink(a));
  if (shadow) {
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / s
        ..color = PerdePainter._hole.withValues(alpha: 0.6 * a),
    );
  }
  c.restore();
}

/// Gemi ambarının içi: kaburgalar, tavan kirişi, döşeme.
void _agHold(Canvas c, double a) {
  for (var i = 0; i < 7; i++) {
    c.drawArc(
      Rect.fromLTWH(-40 + i * 130.0, -80, 160, 520),
      math.pi * 0.5,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = PerdePainter._ink.withValues(alpha: 0.35 * a),
    );
  }
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 46), _ink(a));
  c.drawRect(const Rect.fromLTWH(0, PerdePainter._ground, 780, 60), _ink(a));
  _punchRow(c, const Offset(20, 32), const Offset(760, 32), 24, 1.6, a);
}

/// Perde 5: buzun altındaki gemi; güvercinin anlattığı tufan; ambarlar;
/// Ak Ana.
void _floodScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  final c = canvas;
  final a0 = _agWin(u, 0, 1);
  if (a0 > 0) _agFloodIceShip(c, time, u, a0);
  final a1 = _agWin(u, 1, 2);
  if (a1 > 0) _agFloodRain(c, time, u, a1);
  final a2 = _agWin(u, 2, 3);
  if (a2 > 0) _agFloodNoah(c, time, u, a2);
  final a3 = _agWin(u, 3, 4);
  if (a3 > 0) _agFloodThieves(c, time, u, a3);
  final a4 = _agWin(u, 4, 5);
  if (a4 > 0) _agFloodHolds(c, time, u, a4);
  final a5 = _agWin(u, 5, 99);
  if (a5 > 0) _agFloodAkAna(c, time, u, a5);
}

/// Güvercin zeytin dallı: [dry] kurumuş dal.
void _agDoveBranch(
  Canvas c,
  Offset at,
  double s,
  double time,
  double a, {
  bool flip = false,
  bool branch = true,
}) {
  if (a <= 0.01) return;
  _dove(c, at, s, time, a, flip: flip);
  if (!branch) return;
  final d = flip ? -1.0 : 1.0;
  final beak = at + Offset(d * 28 * s, -5 * s);
  c.drawLine(
    beak,
    beak + Offset(d * 18 * s, 6 * s),
    _ink(a)..strokeWidth = 1.6 * s,
  );
  for (var i = 0; i < 3; i++) {
    c.drawOval(
      Rect.fromCenter(
        center:
            beak +
            Offset(
              d * (6 + i * 5.0) * s,
              (3 + i * 2.0 + (i.isEven ? -3 : 3)) * s,
            ),
        width: 6 * s,
        height: 3 * s,
      ),
      _ink(a),
    );
  }
}

/// 0: buz mağarasında kapkara gemi; Sâye tahtasına dokunur; zeytin dallı
/// güvercin direğe konar.
void _agFloodIceShip(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  // Buzun soğuk ışığı.
  c.drawRect(
    const Rect.fromLTWH(0, 0, 780, 400),
    Paint()..color = const Color(0xFFFFF4E0).withValues(alpha: 0.28 * a),
  );
  const at = Offset(470, g - 22);
  _agArk(c, at, 1.6, a);
  // Gövdede buz kabuğu: soluk lekeler.
  final frost = _hole(0.35 * a);
  for (var i = 0; i < 9; i++) {
    c.drawOval(
      Rect.fromCenter(
        center: at + Offset(-150 + i * 38.0, -10 + (i % 3) * 6.0),
        width: 22,
        height: 5,
      ),
      frost,
    );
  }
  // Mağaranın kayası ve sarkıtları.
  c.drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(-10, -10, 800, 420))
      ..moveTo(10, g)
      ..lineTo(20, 90)
      ..quadraticBezierTo(120, 18, 400, 20)
      ..quadraticBezierTo(700, 18, 770, 90)
      ..lineTo(775, g)
      ..close(),
    _ink(a),
  );
  for (var i = 0; i < 15; i++) {
    final x = 40 + i * 50.0;
    if ((x - 465).abs() < 40) continue;
    final l = 18 + (i * 37 % 5) * 7.0;
    final top = 22 + ((x - 400).abs() / 400) * 50;
    c.drawPath(
      Path()
        ..moveTo(x - 8, top - 4)
        ..lineTo(x, top + l)
        ..lineTo(x + 8, top - 4)
        ..close(),
      _ink(a),
    );
  }
  c.drawRect(const Rect.fromLTWH(0, g, 780, 60), _ink(a));
  // Sâye tahtaya dokunur.
  final touch = _span(u, 0.25, 0.45);
  _agSaye(c, const Offset(250, g + 6), 1.8, time, a, raise: 0.42 * touch);
  // Güvercin direğe konar.
  final land = _span(u, 0.55, 0.85);
  final mast = at + const Offset(-5, -150) * 1.6;
  final dp = Offset.lerp(
    const Offset(800, 40),
    mast + const Offset(4, -12),
    land,
  )!;
  _agDoveBranch(c, dp, 1.3, time, a * _span(u, 0.5, 0.58), flip: true);
}

/// 1: kırk gün kırk gece yağmur; gemi karanlık sularda tek başına.
void _agFloodRain(Canvas c, double time, double u, double a) {
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.35 * a));
  final at = Offset(400, 268 + math.sin(time * 1.6) * 7);
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(math.sin(time * 1.2) * 0.06);
  _agArk(c, Offset.zero, 1.25, a, light: 1);
  // Güvercin direkte: anlatan o.
  _agDoveBranch(
    c,
    const Offset(-5, -150) * 1.25 + const Offset(4, -12),
    1.2,
    time,
    a,
    flip: true,
    branch: false,
  );
  c.restore();
  final wave = Path()..moveTo(0, 400);
  for (var x = 0.0; x <= 780; x += 15) {
    wave.lineTo(
      x,
      282 + math.sin(x / 38 + time * 2.2) * 10 + math.sin(x / 13 - time) * 3,
    );
  }
  wave
    ..lineTo(780, 400)
    ..close();
  c.drawPath(wave, _ink(a));
  final crest = _hole(0.4 * a);
  for (var i = 0; i < 12; i++) {
    final x = (i * 67.0 + time * 30) % 780;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, 286 + math.sin(x / 38 + time * 2.2) * 10),
        width: 16,
        height: 3,
      ),
      crest,
    );
  }
  _fallLines(c, time, a, count: 110);
}

/// 2: Nuh önce kuzgunu salar (dönmez), sonra güvercini; güvercin zeytin
/// dalıyla döner, dünya yeşerir.
void _agFloodNoah(Canvas c, double time, double u, double a) {
  // Dağ başı; sular çekilir.
  c.drawPath(
    Path()
      ..moveTo(60, 400)
      ..lineTo(330, 238)
      ..lineTo(380, 244)
      ..lineTo(640, 400)
      ..close(),
    _ink(a),
  );
  c.drawPath(
    Path()
      ..moveTo(520, 400)
      ..lineTo(700, 280)
      ..lineTo(800, 330)
      ..lineTo(800, 400)
      ..close(),
    _ink(0.5 * a),
  );
  final level = 300 + 40 * _span(u, 2.0, 2.9);
  final wave = Path()..moveTo(0, 400);
  for (var x = 0.0; x <= 780; x += 15) {
    wave.lineTo(x, level + math.sin(x / 30 + time * 2) * 4);
  }
  wave
    ..lineTo(780, 400)
    ..close();
  c.drawPath(wave, _ink(0.55 * a));
  // Yeşeren dünya: yamaçlarda filizler.
  final green = _span(u, 2.78, 2.95);
  if (green > 0) {
    for (var i = 0; i < 9; i++) {
      final x = 110 + i * 26.0;
      final y = 400 - (x - 60) * 162 / 270 - 4;
      if (y > level - 6) continue;
      final h = 14 + (i % 3) * 6.0;
      c.drawLine(
        Offset(x, y),
        Offset(x, y - h * green),
        _ink(a)..strokeWidth = 2,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + 4, y - h * green),
          width: 9 * green,
          height: 5 * green,
        ),
        _ink(a),
      );
    }
  }
  const at = Offset(355, 222);
  _agArk(c, at, 1.3, a, light: 1);
  // Nuh pruvada: kolunu kaldırıp kuşları salar.
  final release = math.max(
    _shown(u, 2.04, 2.22, 0.05),
    _shown(u, 2.4, 2.56, 0.05),
  );
  final take = _span(u, 2.82, 2.9);
  _person(
    c,
    at + const Offset(92, -26),
    128,
    a,
    _nuh,
    time: time,
    arm: -1.9 * math.max(release, take),
  );
  final hand = at + const Offset(120, -96);
  // Kuzgun: gider, dönmez (perdenin içinde silinir).
  final rv = _span(u, 2.06, 2.42);
  if (rv > 0 && rv < 1) {
    final rp = Offset.lerp(hand, const Offset(700, 60), rv)!;
    _cut(
      c,
      MythShapes.birdFlap,
      rp.translate(0, 18),
      40,
      a * (1 - _span(u, 2.32, 2.42)),
      deco: false,
    );
  }
  // Güvercin: gider ve zeytin dalıyla döner.
  final dv = _span(u, 2.42, 2.84);
  if (dv > 0) {
    final out = dv < 0.5;
    final k = out ? dv * 2 : (1 - dv) * 2;
    final dp = Offset.lerp(hand, const Offset(660, 90), k)!;
    _agDoveBranch(c, dp, 1.1, time, a, flip: !out, branch: !out);
  }
}

/// 3: gemide her canlıdan bir çift ve sönmeyen ışık; Kandilciler
/// hayvanların gölgelerini eşlerinden koparıp ambara kilitler.
void _agFloodThieves(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  _agHold(c, a);
  // Sönmeyen ışık: tavandan sarkan kandil.
  const lamp = Offset(330, 120);
  c.drawLine(
    const Offset(330, 46),
    lamp.translate(0, -10),
    _ink(a)..strokeWidth = 2,
  );
  c.drawCircle(
    lamp,
    60,
    Paint()
      ..shader = ui.Gradient.radial(lamp, 60, [
        const Color(0xFFFFF4D0).withValues(alpha: 0.8 * a),
        const Color(0x00FFF4D0),
      ]),
  );
  c.drawPath(
    Path()
      ..moveTo(lamp.dx - 16, lamp.dy - 6)
      ..quadraticBezierTo(lamp.dx, lamp.dy + 12, lamp.dx + 16, lamp.dy - 6)
      ..close(),
    _ink(a),
  );
  c.drawCircle(lamp.translate(0, -14), 6 + math.sin(time * 9), _hole(a));
  // Ambar: parmaklıklı bölme, içinde koparılmış gölgeler.
  const cell = Rect.fromLTWH(600, 120, 170, 230);
  c.drawRect(cell, _ink(0.25 * a));
  _agBeast(c, MythShapes.deer, const Offset(650, g), 92, a, shadow: true);
  // Aslan çifti: biri yerinde, ötekinin gölgesi sürüklenir.
  _agBeast(c, MythShapes.lion, const Offset(110, g), 84, a);
  _agBeast(c, MythShapes.lion, const Offset(260, g), 80, a, flip: true);
  final drag = _span(u, 3.25, 3.9);
  final shadowAt = Offset(_agLerp(268, 440, drag), g);
  _agBeast(
    c,
    MythShapes.lion,
    shadowAt,
    80,
    a * _span(u, 3.15, 3.3),
    flip: true,
    shadow: true,
  );
  // Kandilci zincirle çeker.
  final kx = _agLerp(430, 620, drag);
  _agKandilci(
    c,
    Offset(kx, g + 4),
    0.85,
    time,
    a * _span(u, 3.05, 3.2),
    seed: 1,
  );
  if (drag > 0) {
    c.drawLine(
      Offset(kx - 20, g - 100),
      shadowAt + const Offset(-50, -58),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = PerdePainter._ink.withValues(alpha: 0.9 * a),
    );
  }
  for (var i = 0; i < 8; i++) {
    c.drawRect(
      Rect.fromLTWH(cell.left + 6 + i * 21.0, cell.top, 6, cell.height),
      _ink(a),
    );
  }
  // Güvercin kirişte: anlatan o.
  _agDoveBranch(c, const Offset(110, 66), 1.3, time, a, branch: false);
}

/// 4: ambarların karanlığında ayrı düşen gölgeler birbirini arar; Sâye.
void _agFloodHolds(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  _agHold(c, a);
  // Üç bölme: her birinde bir gölge, komşusuna döner.
  final beasts = [
    (MythShapes.lion, 70.0, false),
    (MythShapes.deer, 86.0, true),
    (MythShapes.horse, 82.0, true),
  ];
  for (var i = 0; i < 3; i++) {
    final cell = Rect.fromLTWH(30 + i * 250.0, 62, 220, 150);
    c.drawRect(cell, _hole(0.18 * a));
    final (shape, h, flip) = beasts[i];
    final pace = math.sin(time * 0.9 + i * 2) * 30;
    _agBeast(
      c,
      shape,
      Offset(cell.center.dx + pace, cell.bottom - 4),
      h,
      a,
      flip: (i == 0) ? false : flip,
      shadow: true,
    );
    for (var b = 0; b < 9; b++) {
      c.drawRect(
        Rect.fromLTWH(cell.left + 4 + b * 25.0, cell.top, 5, cell.height),
        _ink(a),
      );
    }
    c.drawRect(
      Rect.fromLTWH(cell.left - 6, cell.bottom, cell.width + 12, 10),
      _ink(a),
    );
  }
  // Karanlık: Sâye'nin kavanozu dışında her yer gölgede.
  const sp = Offset(390, g + 6);
  c.drawRect(
    const Rect.fromLTWH(0, 0, 780, 400),
    Paint()
      ..shader = ui.Gradient.radial(
        sp.translate(40, -60),
        380,
        [const Color(0x001A0B05), PerdePainter._ink.withValues(alpha: 0.6 * a)],
        const [0.25, 1],
      ),
  );
  _agSaye(c, sp, 1.5, time, a, jar: 0.75, seed: 4, rot: 0.06);
}

/// 5: dipteki su kıpırdar; ak saçlı, ak giysili Ak Ana sudan yükselir.
void _agFloodAkAna(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  _agHold(c, a);
  const water = 300.0;
  final rise = _span(u, 5.08, 5.55);
  c.save();
  c.clipRect(const Rect.fromLTWH(0, 0, 780, water + 4));
  _agAkAna(
    c,
    Offset(480, water + 232 - 200 * rise),
    240,
    time,
    a * _span(u, 5.04, 5.2),
  );
  c.restore();
  // Su: dibi dolduran dalgalı su, kıpırdayan halkalar.
  final pool = Path()..moveTo(250, g);
  for (var x = 250.0; x <= 780; x += 12) {
    pool.lineTo(x, water + math.sin(x / 24 + time * 2) * 3);
  }
  pool
    ..lineTo(780, g)
    ..close();
  c.drawPath(pool, _ink(0.6 * a));
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..color = PerdePainter._hole.withValues(alpha: 0.7 * a);
  for (var i = 0; i < 3; i++) {
    final k = (time * 0.6 + i / 3) % 1;
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(480, water + 4),
        width: 40 + k * 300,
        height: 6 + k * 14,
      ),
      ring..color = PerdePainter._hole.withValues(alpha: 0.7 * a * (1 - k)),
    );
  }
  _agSaye(c, const Offset(150, g + 6), 1.8, time, a, seed: 5);
}

// ------------------------------------------------------- Nemrut tanrıları

/// Nemrut'un taş başı: profilden, kırık boyunlu; [kind] 0 Antiochos'un
/// sivri ucu öne kıvrık külahı, 1 Apollon'un yuvarlak başlığı, 2 Zeus'un
/// basamaklı tacı. Boynun kırığı [at]'ta (yere yatınca yere değer), boyu
/// [size]. [eyes] 0 kapalı, 1 açık; [tear] gözden süzülen damla (0..1).
void _agStoneHead(
  Canvas c,
  Offset at,
  double size,
  double a, {
  double rot = 0,
  bool flip = false,
  int kind = 0,
  double eyes = 0,
  double tear = 0,
  double light = 0,
  double alpha = 1,
}) {
  if (a <= 0.01) return;
  final s = size / 100;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  c.scale(flip ? -s : s, s);
  final ink = _ink(a * alpha);
  // Yüz: ense, alın, burun, dudaklar, çene; kırık boyun.
  final face = Path()
    ..moveTo(-28, 0)
    ..lineTo(-24, -6)
    ..lineTo(-30, -12)
    ..quadraticBezierTo(-38, -34, -32, -54)
    ..lineTo(27, -54)
    ..quadraticBezierTo(29, -46, 29, -40)
    ..lineTo(40, -26)
    ..lineTo(31, -23)
    ..lineTo(33, -19)
    ..lineTo(29, -16)
    ..lineTo(32, -12)
    ..quadraticBezierTo(30, -4, 22, -2)
    ..lineTo(14, 0)
    ..lineTo(6, -4)
    ..lineTo(-4, 1)
    ..lineTo(-14, -4)
    ..close();
  c.drawPath(face, ink);
  // Başlık.
  final hat = Path();
  switch (kind) {
    case 0:
      hat
        ..moveTo(-36, -50)
        ..lineTo(30, -50)
        ..lineTo(26, -60)
        ..quadraticBezierTo(22, -92, 4, -100)
        ..quadraticBezierTo(18, -102, 26, -94)
        ..quadraticBezierTo(12, -110, -10, -100)
        ..quadraticBezierTo(-30, -88, -36, -50)
        ..close();
    case 1:
      hat
        ..moveTo(-38, -50)
        ..lineTo(30, -50)
        ..quadraticBezierTo(28, -92, -4, -90)
        ..quadraticBezierTo(-36, -88, -38, -50)
        ..close();
    default:
      hat
        ..moveTo(-36, -50)
        ..lineTo(30, -50)
        ..lineTo(26, -70)
        ..lineTo(18, -70)
        ..lineTo(16, -86)
        ..lineTo(-18, -86)
        ..lineTo(-22, -70)
        ..lineTo(-32, -70)
        ..close();
  }
  c.drawPath(hat, ink);
  final cut = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4 / s
    ..strokeCap = StrokeCap.round
    ..color = PerdePainter._hole.withValues(alpha: 0.55 * a * alpha);
  // Başlığın bandı, zımba süsü; yüzde taş çatlakları; kulak.
  c.drawLine(const Offset(-34, -53), const Offset(28, -53), cut);
  _punchRow(
    c,
    const Offset(-28, -62),
    const Offset(18, -62),
    6,
    1.6,
    a * alpha,
  );
  c.drawLine(const Offset(-8, -28), const Offset(-2, -14), cut);
  c.drawArc(
    Rect.fromCenter(center: const Offset(-10, -32), width: 10, height: 14),
    -1.4,
    3.0,
    false,
    cut,
  );
  c.drawLine(const Offset(18, -12), const Offset(26, -13), cut);
  // Göz: kapalıyken çizgi, açıkken ışık.
  if (eyes < 0.5) {
    c.drawLine(const Offset(18, -35), const Offset(26, -34), cut);
  } else {
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(22, -35),
        width: 10,
        height: 3 + 4 * eyes,
      ),
      Paint()..color = const Color(0xFFFFF4D6).withValues(alpha: a * alpha),
    );
    c.drawCircle(const Offset(24, -35), 1.6, ink);
  }
  if (tear > 0) {
    final ty = -31 + 26 * tear;
    final tp = Offset(26 + 4 * tear, ty);
    c.drawPath(
      Path()
        ..moveTo(tp.dx, tp.dy - 5)
        ..quadraticBezierTo(tp.dx + 3.5, tp.dy, tp.dx, tp.dy + 3)
        ..quadraticBezierTo(tp.dx - 3.5, tp.dy, tp.dx, tp.dy - 5)
        ..close(),
      Paint()..color = const Color(0xFFFFF8E8).withValues(alpha: a * alpha),
    );
    c.drawLine(const Offset(25, -31), tp, cut);
  }
  if (light > 0) {
    // Güneşin ilk ışığı yüzüne vurur: alnı, burnu, çenesi aydınlanır.
    final lit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 / s
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFF4D0).withValues(alpha: a * light);
    c.drawPath(
      Path()
        ..moveTo(27, -54)
        ..quadraticBezierTo(29, -46, 29, -40)
        ..lineTo(40, -26)
        ..lineTo(31, -23)
        ..lineTo(33, -19)
        ..lineTo(29, -16)
        ..lineTo(32, -12)
        ..quadraticBezierTo(30, -4, 22, -2),
      lit,
    );
  }
  c.restore();
}

/// Kar: yerin üstünde soluk öbekler; [front] öndeki yığınlar başların
/// dibini örter.
void _agSnowDrifts(Canvas c, double a, List<double> xs, {double y = 352}) {
  final snow = Paint()
    ..color = const Color(0xFFFFF4E2).withValues(alpha: 0.85 * a);
  for (final x in xs) {
    c.drawPath(
      Path()
        ..moveTo(x - 70, y + 4)
        ..quadraticBezierTo(x - 30, y - 22, x + 10, y - 10)
        ..quadraticBezierTo(x + 50, y - 20, x + 80, y + 4)
        ..close(),
      snow,
    );
  }
}

/// Nemrut'un doruğu: taş yığını tümülüs, karlı zemin.
void _agNemrutSummit(Canvas c, double a, {double snow = 1}) {
  c.drawPath(
    Path()
      ..moveTo(120, 352)
      ..lineTo(390, 96)
      ..lineTo(660, 352)
      ..close(),
    _ink(0.32 * a),
  );
  final st = _hole(0.18 * a);
  for (var r = 0; r < 9; r++) {
    final y = 130.0 + r * 26;
    final half = (y - 96) * 270 / 256;
    for (var x = 390 - half + 12; x < 390 + half - 8; x += 22) {
      c.drawCircle(Offset(x + (r.isEven ? 0 : 11), y), 2, st);
    }
  }
  c.drawRect(const Rect.fromLTWH(0, 350, 780, 60), _ink(a));
  if (snow > 0) {
    c.drawRect(
      const Rect.fromLTWH(0, 346, 780, 8),
      Paint()
        ..color = const Color(0xFFFFF4E2).withValues(alpha: 0.75 * a * snow),
    );
  }
}

/// Oturan taş tanrı: taht ve gövde; başı boynunda ya da [fall] ile
/// yuvarlanıp yere düşer ([headless] ise başı yok).
void _agStatue(
  Canvas c,
  double x,
  double size,
  double a, {
  int kind = 1,
  double fall = 0,
  bool headless = false,
  double alpha = 1,
  double y = PerdePainter._ground,
}) {
  final k = size / 100;
  final ink = _ink(a * alpha);
  c.drawRect(Rect.fromLTWH(x - 34 * k, y - 50 * k, 68 * k, 50 * k), ink);
  c.drawRect(Rect.fromLTWH(x - 20 * k, y - 104 * k, 40 * k, 56 * k), ink);
  c.drawRect(Rect.fromLTWH(x - 24 * k, y - 62 * k, 52 * k, 14 * k), ink);
  c.drawLine(
    Offset(x - 26 * k, y - 26 * k),
    Offset(x + 26 * k, y - 26 * k),
    _hole(0.45 * a * alpha)..strokeWidth = 2,
  );
  c.drawCircle(Offset(x, y - 84 * k), 2.4, _hole(0.6 * a * alpha));
  if (headless) {
    // Kırık boyun.
    c.drawPath(
      Path()
        ..moveTo(x - 9 * k, y - 104 * k)
        ..lineTo(x - 4 * k, y - 112 * k)
        ..lineTo(x + 2 * k, y - 107 * k)
        ..lineTo(x + 8 * k, y - 113 * k)
        ..lineTo(x + 10 * k, y - 104 * k)
        ..close(),
      ink,
    );
    return;
  }
  final neck = Offset(x, y - 102 * k);
  final ground = Offset(x + 64 * k, y);
  final f = fall.clamp(0.0, 1.0);
  final p = Offset(
    _agLerp(neck.dx, ground.dx, f),
    _agLerp(neck.dy, ground.dy, f * f) - math.sin(f * math.pi) * 18 * k,
  );
  _agStoneHead(c, p, 52 * k, a, rot: f * 1.75, kind: kind, alpha: alpha);
}

/// Perde 6: karda yatan taş başlar; Antiochos konuşur.
void _godsScene(Canvas canvas, double time, double u, {bool dawn = false}) {
  _P._c = canvas;
  if (dawn) {
    _dawnTale(canvas, time, u);
    return;
  }
  final c = canvas;
  final aHeads = math.max(_agWin(u, 0, 2), _agWin(u, 3, 99));
  if (aHeads > 0) _agGodsHeads(c, time, u, aHeads);
  final aTomb = _agWin(u, 2, 3);
  if (aTomb > 0) _agGodsTomb(c, time, u, aTomb);
}

void _agGodsHeads(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final night = _span(u, 3.8, 4.1);
  _agNemrutSummit(c, a);
  _snowfall(c, time, 0.8 * a, wind: 15);
  // Satır 1: el sıkışma kabartması (anı) sağda bir taş levhada.
  final stele = _shown(u, 1.08, 2.0, 0.15);
  if (stele > 0) {
    const r = Rect.fromLTWH(575, 52, 190, 292);
    c.drawRect(r, _ink(stele * a));
    c.drawRect(
      r.deflate(10),
      Paint()..color = const Color(0xFFE8B070).withValues(alpha: stele * a),
    );
    _person(c, const Offset(625, 334), 200, stele * a, _antiochos, arm: -0.9);
    _person(
      c,
      const Offset(715, 334),
      178,
      stele * a,
      _herakles,
      flip: true,
      arm: -0.9,
    );
    _punchRow(
      c,
      r.topLeft + const Offset(16, 5),
      r.topRight + const Offset(-16, 5),
      12,
      1.6,
      stele * a,
    );
  }
  // Satır 3: doğu terası, sönük ateş sunağı; ufukta şafak.
  final terrace = _span(u, 3.1, 3.4) * (1 - _span(u, 3.85, 4.05));
  if (terrace > 0) {
    final ta = terrace * a;
    final hz = const Offset(700, 300);
    c.drawCircle(
      hz,
      120,
      Paint()
        ..shader = ui.Gradient.radial(hz, 120, [
          const Color(0xFFFFE6B0).withValues(alpha: 0.7 * ta),
          const Color(0x00FFE6B0),
        ]),
    );
    c.drawRect(const Rect.fromLTWH(600, 300, 180, 50), _ink(0.6 * ta));
    c.drawRect(const Rect.fromLTWH(630, 270, 120, 30), _ink(0.6 * ta));
    c.drawPath(
      Path()
        ..moveTo(670, 270)
        ..lineTo(660, 236)
        ..lineTo(720, 236)
        ..lineTo(710, 270)
        ..close(),
      _ink(0.75 * ta),
    );
  }
  // Satır 4: gece; başların arasında fenerler (başların ardında).
  if (night > 0) {
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.28 * a * night));
    final walk = _span(u, 4.1, 4.95);
    _agKandilci(
      c,
      Offset(_agLerp(560, 600, walk), g + 4),
      0.82,
      time,
      a * night,
      seed: 0.5,
    );
    _agKandilci(
      c,
      Offset(_agLerp(640, 700, walk), g + 4),
      0.78,
      time,
      a * night,
      seed: 2.2,
      lift: 20,
    );
    _agKandilci(
      c,
      Offset(_agLerp(30, 70, walk), g + 4),
      0.74,
      time,
      a * night,
      seed: 3.1,
    );
  }
  // Başlar karda yatar; Antiochos'un başı Sâye'ye döner.
  final close = _span(u, 2.9, 3.15) * (1 - _span(u, 3.85, 4.05));
  final mainSize = _agLerp(175, 225, close);
  final mainX = _agLerp(470, 440, close);
  final eyes = _span(u, 0.72, 0.85);
  final tear = u > 3.2 ? ((u - 3.2) / 0.45) % 1 : 0.0;
  _agStoneHead(c, const Offset(150, g + 2), 115, a, rot: 0.12, kind: 1);
  if (stele <= 0 && close < 0.5) {
    _agStoneHead(
      c,
      const Offset(690, g + 2),
      120,
      a,
      rot: -0.3,
      flip: true,
      kind: 2,
    );
  }
  _agStoneHead(
    c,
    Offset(mainX, g + 2),
    mainSize,
    a,
    rot: -0.08,
    flip: true,
    kind: 0,
    eyes: eyes,
    tear: u > 3.2 && u < 3.95 ? tear : 0,
  );
  _agSnowDrifts(c, a, [150, mainX, if (stele <= 0) 690]);
  // Konuşan taş baş: ağzından söz yayları.
  if (u > 1.0 && u < 5.0) {
    final talk = 1 - _span(u, 1.85, 1.95) + _span(u, 2.95, 3.1);
    final mouth = Offset(mainX - 0.31 * mainSize, g - 0.17 * mainSize);
    _agWhisper(
      c,
      mouth,
      const Offset(-1, 0.1),
      time,
      a * talk.clamp(0.0, 1.0) * 0.8,
    );
  }
  // Sâye: Fırat'ın ötesinden süzülüp doruğa konar.
  final land = _span(u, 0.0, 0.4);
  final sp = Offset(
    _agLerp(40, 290, land),
    _agLerp(120, g + 6, land) - math.sin(land * math.pi) * 40,
  );
  final alarm = _span(u, 4.3, 4.45);
  _agSaye(
    c,
    sp.translate(-24 * alarm, 0),
    1.8,
    time,
    a,
    rot: (1 - land) * 0.4 - 0.1 * alarm,
    jar: 1 - 0.6 * alarm,
    seed: 9,
  );
  if (land < 1) {
    // Fırat: altında akan ışık şerit.
    final river = a * (1 - _span(u, 0.3, 0.45));
    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFFFFF0D0).withValues(alpha: 0.6 * river);
    c.drawPath(
      Path()
        ..moveTo(0, 372)
        ..quadraticBezierTo(120, 360, 200, 380)
        ..quadraticBezierTo(300, 398, 420, 386),
      rp,
    );
  }
}

/// Satır 2: tepeye taş üstüne taş; kral altına yatar. Deprem: başı
/// omzundan yuvarlanır.
void _agGodsTomb(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final quake = _shown(u, 2.55, 2.9, 0.04);
  c.save();
  c.translate(
    math.sin(time * 40) * 3 * quake,
    math.cos(time * 33) * 1.5 * quake,
  );
  // Taş yığını tümülüs, içinde mezar odası.
  c.drawPath(
    Path()
      ..moveTo(10, g + 2)
      ..lineTo(250, 70)
      ..lineTo(490, g + 2)
      ..close(),
    _ink(0.88 * a),
  );
  final st = _hole(0.28 * a);
  for (var r = 0; r < 10; r++) {
    final y = 100.0 + r * 24;
    final half = (y - 70) * 240 / 282;
    for (var x = 250 - half + 10; x < 250 + half - 6; x += 20) {
      if (y > 250 && (x - 250).abs() < 100) continue;
      c.drawCircle(Offset(x + (r.isEven ? 0 : 10), y), 2.2, st);
    }
  }
  const room = Rect.fromLTWH(150, 262, 200, 76);
  c.drawRRect(
    RRect.fromRectAndRadius(room, const Radius.circular(6)),
    Paint()..color = const Color(0xFFE9AE6C).withValues(alpha: a),
  );
  // Lahit ve üstünde yatan kral.
  c.drawRect(const Rect.fromLTWH(172, 318, 156, 16), _ink(a));
  _person(c, const Offset(322, 318), 140, a, _antiochos, rot: -math.pi / 2);
  c.drawRect(Rect.fromLTWH(0, g, 780, 60), _ink(a));
  // Terasta oturan taş tanrılar; Antiochos'un başı yuvarlanır.
  final fall = _span(u, 2.6, 2.95);
  _agStatue(c, 716, 130, a, kind: 2, alpha: 0.55);
  _agStatue(c, 560, 150, a, kind: 0, fall: fall);
  c.restore();
}

/// Taştan dev: Nemrud gibi sivri taçlı, iri; gövdesi taş bloklardan.
const _agStoneGiantLook = _Look(
  hat: _Hat.crownSpikes,
  garb: _Garb.tunic,
  beard: _Beard.pointed,
  broad: 1.6,
  belt: false,
);

/// Taş dev tasviri: [h] (_person boyu), taş derzleri ışık kesiği.
void _agStoneGiant(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = true,
  double arm = 0,
  double alpha = 1,
  double rot = 0,
}) {
  if (a <= 0.01) return;
  _person(
    c,
    feet,
    h,
    a * alpha,
    _agStoneGiantLook,
    flip: flip,
    arm: arm,
    rot: rot,
  );
  final s = h / 100 * 1.3;
  final seam = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..color = PerdePainter._hole.withValues(alpha: 0.4 * a * alpha);
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  for (var i = 0; i < 4; i++) {
    final y = -(30 + i * 13.0) * s;
    c.drawLine(Offset(-12 * s, y), Offset(12 * s, y + 2), seam);
  }
  c.drawLine(Offset(-2 * s, -78 * s), Offset(-4 * s, -40 * s), seam);
  c.restore();
}

/// Sivrisinek: ince gövde, iki kanat, uzun hortum; [s] ölçek.
void _agMosquito(
  Canvas c,
  Offset at,
  double s,
  double time,
  double a, {
  bool flip = false,
}) {
  if (a <= 0.01) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(flip ? -s : s, s);
  final ink = _ink(a);
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: 14, height: 4), ink);
  c.drawCircle(const Offset(8, -1), 2.4, ink);
  c.drawLine(const Offset(10, -1), const Offset(17, 2), ink..strokeWidth = 0.9);
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(-2 + i * 3.0, 1),
      Offset(-5 + i * 4.0, 7),
      ink..strokeWidth = 0.7,
    );
  }
  final f = math.sin(time * 60) * 0.6;
  for (final d in [0.0, 0.5]) {
    c.save();
    c.translate(1, -1);
    c.rotate(-1.2 + f + d);
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 4, height: 12),
      _ink(0.6 * a),
    );
    c.restore();
  }
  c.restore();
}

/// Perde 7'nin önü: taşların ardına sinmiş Sâye ve fısıldayan taş baş.
void _agDawnFront(
  Canvas c,
  double time,
  double u,
  double a, {
  double stand = 0,
  double run = 0,
  double smile = 0,
}) {
  const g = PerdePainter._ground;
  final sx = _agLerp(92, 400, run);
  final tremble = _shown(u, 5.0, 5.45, 0.05) * math.sin(time * 30) * 1.6;
  // Sinmişken taşın ardında yalnız başı, omzu ve kavanozu görünür.
  _agSaye(
    c,
    Offset(sx + tremble, g + 6 + 26 * (1 - stand) * (1 - run)),
    1.6,
    time,
    a,
    smile: smile,
    rot: run > 0 && run < 1 ? 0.12 : 0,
    seed: 11,
  );
  _agStoneHead(
    c,
    const Offset(250, g + 2),
    150,
    a,
    rot: -0.06,
    flip: true,
    kind: 0,
    eyes: 1,
  );
  // Taşlar.
  final ink = _ink(a);
  c.drawPath(
    Path()
      ..moveTo(20, g + 2)
      ..lineTo(30, g - 40)
      ..lineTo(70, g - 56)
      ..lineTo(118, g - 44)
      ..lineTo(132, g + 2)
      ..close(),
    ink,
  );
  c.drawRect(const Rect.fromLTWH(0, g, 780, 60), ink);
  c.drawRect(
    const Rect.fromLTWH(0, g - 4, 780, 7),
    Paint()..color = const Color(0xFFFFF4E2).withValues(alpha: 0.6 * a),
  );
}

/// Perde 7: Antiochos'un anlattıkları (Nemrud, İbrahim, sivrisinek), taş
/// dev ve Tepegöz ile Basat. Önde hep taşların ardındaki Sâye ve taş baş.
void _dawnTale(Canvas c, double time, double u) {
  const g = PerdePainter._ground;
  // Şafak yaklaşır: doğuda (sağda) ışık büyür.
  final dawn = _span(u, 0, 4.5);
  final hz = const Offset(700, 340);
  c.drawCircle(
    hz,
    160 + 120 * dawn,
    Paint()
      ..shader = ui.Gradient.radial(hz, 160 + 120 * dawn, [
        const Color(0xFFFFF0C8).withValues(alpha: 0.35 + 0.45 * dawn),
        const Color(0x00FFF0C8),
      ]),
  );
  final quake = _shown(u, 4.02, 4.6, 0.05);
  c.save();
  c.translate(
    math.sin(time * 41) * 3.5 * quake,
    math.cos(time * 37) * 2 * quake,
  );
  final t0 = _agWin(u, 0, 1);
  if (t0 > 0) _agDawnTerrace(c, time, t0, lights: true);
  final t1 = _agWin(u, 1, 2);
  if (t1 > 0) _agNemrudEagles(c, time, u, t1);
  final t2 = _agWin(u, 2, 3);
  if (t2 > 0) _agIbrahimFire(c, time, u, t2);
  final t3 = _agWin(u, 3, 4);
  if (t3 > 0) _agNemrudMosquito(c, time, u, t3);
  final t4 = _agWin(u, 4, 99);
  if (t4 > 0) {
    // Taş dev doğu terasında doğrulur; satır 5'in başında Tepegöz'ün
    // masalı onun yerini alır, sonra dev geri gelir.
    final tale = _shown(u, 5.0, 5.5, 0.08);
    final giant = 1 - _shown(u, 4.92, 5.5, 0.08);
    final rise = _span(u, 4.1, 4.75);
    c.save();
    // Terasın ardından doğrulur: terasın gövdesi onu örter.
    c.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(const Rect.fromLTWH(0, 0, 780, 352)),
        _agTerracePath(),
      ),
    );
    _agStoneGiant(
      c,
      Offset(610, g + 6 + 300 * (1 - rise)),
      230,
      time,
      t4 * giant,
      arm: -0.4,
    );
    c.restore();
    _agDawnTerrace(c, time, t4 * giant);
    if (tale > 0) _agBasatTale(c, time, u, t4 * tale);
  }
  c.restore();
  // Ön: Sâye ve taş baş.
  final stand = math.max(_span(u, 4.15, 4.35), _shown(u, 3.55, 4.0, 0.1));
  final run = _span(u, 5.6, 5.95);
  _agDawnFront(
    c,
    time,
    u,
    1,
    stand: stand,
    run: run,
    smile: _span(u, 3.62, 3.78),
  );
  // Fısıltı: taş başın ağzından Sâye'ye (anlattığı satırlarda).
  final talk = _span(u, 0.1, 0.25) * (1 - _span(u, 3.55, 3.65));
  _agWhisper(
    c,
    const Offset(250 - 0.31 * 150, g - 0.17 * 150),
    const Offset(-1, -0.2),
    time,
    talk,
  );
}

Path _agTerracePath() => Path()
  ..moveTo(440, 352)
  ..lineTo(470, 300)
  ..lineTo(560, 300)
  ..lineTo(575, 270)
  ..lineTo(780, 270)
  ..lineTo(780, 352)
  ..close();

/// Doğu terası: basamaklı taş set; [lights] Kandilcilerin uzaktaki
/// fenerleri.
void _agDawnTerrace(Canvas c, double time, double a, {bool lights = false}) {
  c.drawPath(_agTerracePath(), _ink(a));
  if (lights) {
    for (var i = 0; i < 3; i++) {
      final p = Offset(
        610 + i * 50.0,
        250 - (i % 2) * 8 + math.sin(time * 2 + i) * 2,
      );
      c.drawLine(p, p.translate(2, 22), _ink(0.8 * a)..strokeWidth = 2);
      c.drawCircle(p, 4.5, _hole(a));
    }
  }
}

/// Satır 1: Nemrud'un dört kartallı sandığı bulutların üstüne yükselir;
/// göğe ok atar.
void _agNemrudEagles(Canvas c, double time, double u, double a) {
  final k = _span(u, 1.05, 1.75);
  final box = Offset(560, 326 - k * 120);
  // Bulutlar: sandık yükseldikçe altında kalır.
  final clouds = _span(u, 1.35, 1.7);
  for (final (x, y, s) in [
    (400.0, 330.0, 0.9),
    (560.0, 322.0, 1.1),
    (720.0, 334.0, 0.8),
  ]) {
    _P._cloud(c, x, y, s, 0.55 * a * clouds);
  }
  // Et asılı sırıklar ve dört kartal.
  final ink = _ink(a);
  for (final side in [-1.0, 1.0]) {
    final pole = box + Offset(side * 50, -28);
    final tip = box + Offset(side * 128, -150);
    c.drawLine(pole, tip, _stroke(_ink(a), 3));
    c.drawLine(tip, tip.translate(0, 16), _stroke(_ink(a), 1.5));
    c.drawOval(
      Rect.fromCenter(center: tip.translate(0, 24), width: 14, height: 18),
      ink,
    );
    for (var j = 0; j < 2; j++) {
      final e = box + Offset(side * (92 + j * 50.0), -64 - j * 26.0);
      c.drawLine(
        box + Offset(side * 54, -10),
        e.translate(0, -6),
        _stroke(_ink(0.8 * a), 1.2),
      );
      // Kartal: kanat açmış, ete uzanır.
      c.save();
      c.translate(e.dx, e.dy + 14);
      c.scale(0.62, 0.62 + math.sin(time * 8 + j + side) * 0.05);
      c.drawPath(MythShapes.birdGlide, ink);
      c.restore();
    }
  }
  c.drawRect(Rect.fromCenter(center: box, width: 108, height: 52), ink);
  _punchRow(
    c,
    box + const Offset(-44, 0),
    box + const Offset(44, 0),
    8,
    2.2,
    a,
  );
  _person(
    c,
    box + const Offset(0, -26),
    104,
    a,
    _nemrud,
    arm: -0.6 - 0.8 * _span(u, 1.75, 1.82),
  );
  // Göğe atılan ok.
  final shot = _span(u, 1.8, 1.97);
  if (shot > 0) {
    final from = box + const Offset(30, -100);
    final to = Offset.lerp(from, from + const Offset(70, -110), shot)!;
    c.drawLine(
      to,
      to + const Offset(-14, 22),
      _stroke(_ink(a * (1 - shot * 0.5)), 2.6),
    );
  }
}

/// Satır 2: ok kanlı düşer, Nemrud böbürlenir; İbrahim'i ateşe attırır, ateş
/// gül bahçesine döner.
void _agIbrahimFire(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final boast = _shown(u, 2.08, 2.5, 0.06);
  _person(
    c,
    const Offset(380, g + 6),
    186,
    a,
    _nemrud,
    time: time,
    arm: -0.6 - 1.6 * boast,
  );
  // Kanlı ok: gökten düşer, ucunda damla.
  final fall = _span(u, 2.02, 2.2);
  final ap = Offset(440, _agLerp(20, 240, fall));
  final aa = a * (1 - _span(u, 2.4, 2.5));
  c.drawLine(ap, ap.translate(6, -64), _stroke(_ink(aa), 3));
  c.drawPath(
    Path()
      ..moveTo(ap.dx - 6, ap.dy - 4)
      ..lineTo(ap.dx, ap.dy + 10)
      ..lineTo(ap.dx + 6, ap.dy - 3)
      ..close(),
    _ink(aa),
  );
  for (final d in [-1.0, 1.0]) {
    c.drawLine(
      ap.translate(5, -58),
      ap.translate(5 + d * 8, -70),
      _stroke(_ink(aa), 2),
    );
  }
  // Kan damlası.
  c.drawCircle(ap.translate(0, 18 + 6 * fall), 4, _ink(aa * fall));
  // İbrahim ateşin ortasında; ateş gül bahçesine döner.
  final bloom = _span(u, 2.62, 2.85);
  _person(
    c,
    const Offset(640, g + 6),
    168,
    a * _span(u, 2.3, 2.4),
    _ibrahim,
    flip: true,
    time: time,
  );
  if (bloom < 1) {
    _agFire(
      c,
      const Offset(640, g + 4),
      230,
      150 * (1 - bloom * 0.8),
      time,
      a * _span(u, 2.3, 2.4) * (1 - bloom),
    );
  }
  if (bloom > 0) {
    final ink = _ink(a * bloom);
    for (var i = 0; i < 10; i++) {
      final x = 548 + i * 20.0 + (i.isEven ? 0 : 4);
      if ((x - 640).abs() < 16) continue;
      final top = g - 30 - (i * 37 % 4) * 14.0 * bloom;
      c.drawLine(Offset(x, g + 4), Offset(x, top), _stroke(_ink(a * bloom), 2));
      c.drawOval(
        Rect.fromCenter(center: Offset(x + 6, top + 18), width: 10, height: 5),
        ink,
      );
      c.drawCircle(Offset(x, top), 7 * bloom, ink);
      c.drawCircle(Offset(x, top), 2.4 * bloom, _hole(a * bloom));
      c.drawArc(
        Rect.fromCircle(center: Offset(x, top), radius: 4.6 * bloom),
        0,
        4.4,
        false,
        _stroke(_hole(0.8 * a * bloom), 1),
      );
    }
  }
}

/// Satır 3: sivrisinek koca kralın burnundan girer; kral başını tutar.
void _agNemrudMosquito(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final hit = _span(u, 3.38, 3.45);
  final sway = _span(u, 3.45, 3.75);
  _person(
    c,
    const Offset(520, g + 6),
    224,
    a,
    _nemrud,
    time: time,
    arm: -2.7 * hit,
    rot: -0.18 * sway + math.sin(time * 5) * 0.03 * sway,
  );
  final fly = _span(u, 3.05, 3.4);
  if (fly < 1) {
    final p = Offset(
      _agLerp(760, 556, fly),
      _agLerp(80, 140, fly) + math.sin(time * 9) * 10 * (1 - fly),
    );
    final trail = _ink(0.5 * a);
    for (var i = 1; i < 6; i++) {
      c.drawCircle(
        p + Offset(i * 12.0, math.sin(time * 9 - i) * 6),
        1.4,
        trail,
      );
    }
    _agMosquito(c, p, 2.6, time, a, flip: true);
  }
}

/// Satır 5'in başı: aslanlar arasında büyümüş küçük Basat, tek gözlü
/// Tepegöz'ü gözünden vurur.
void _agBasatTale(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  _person(
    c,
    const Offset(660, g + 6),
    196,
    a,
    _tepegoz,
    flip: true,
    time: time,
    arm: -0.4,
  );
  _agBeast(c, MythShapes.lion, const Offset(450, g + 4), 70, a);
  final lunge = _span(u, 5.15, 5.3);
  final bx = _agLerp(470, 510, lunge);
  _person(c, Offset(bx, g + 6), 118, a, _basat, time: time, arm: -1.9 * lunge);
  if (lunge > 0) {
    // Kızgın şiş: Basat'ın elinden Tepegöz'ün gözüne.
    c.drawLine(
      Offset(bx + 14, g - 112),
      Offset.lerp(Offset(bx + 14, g - 112), const Offset(642, g - 196), lunge)!,
      _stroke(_hole(a), 4),
    );
  }
}

/// Köprü 7, satır 0: taştan dev yürür, her adımda dağ sarsılır; Sâye bir
/// sivrisinek gibi gölgelerinin arasından vızıldar.
void _agGiantWalk(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final step = (time * 1.1) % 1;
  final shake = math.pow(1 - step, 6).toDouble() * 6;
  c.save();
  c.translate(0, shake);
  final hz = const Offset(700, 345);
  c.drawCircle(
    hz,
    200,
    Paint()
      ..shader = ui.Gradient.radial(hz, 200, [
        const Color(0xFFFFF0C8).withValues(alpha: 0.8 * a),
        const Color(0x00FFF0C8),
      ]),
  );
  c.drawRect(Rect.fromLTWH(-10, g, 800, 70), _ink(a));
  final gx = _agLerp(560, 420, _span(u, 0.0, 0.95));
  final bob = math.sin(step * math.pi) * 6;
  // Devin gölgeleri: fenerlerin vurduğu iki soluk kopya.
  for (final d in [-120.0, 130.0]) {
    _agStoneGiant(
      c,
      Offset(gx + d, g + 6 - bob),
      210,
      time,
      a,
      alpha: 0.28,
      arm: -0.3,
    );
  }
  _agStoneGiant(
    c,
    Offset(gx, g + 6 - bob),
    210,
    time,
    a,
    arm: -0.3 - 0.3 * math.sin(time * 2),
  );
  // Adım tozu.
  final dust = _ink(0.5 * a * (1 - step));
  for (var i = 0; i < 6; i++) {
    c.drawCircle(
      Offset(gx - 30 + i * 12.0, g - step * 20 - (i % 2) * 6),
      3 + step * 4,
      dust,
    );
  }
  c.restore();
  // Sâye: gölgelerin arasında zikzak.
  final t = _span(u, 0.05, 0.95);
  final x = _agLerp(80, 720, t);
  final hop = (math.sin(t * math.pi * 6)).abs() * 70;
  final prev = <Offset>[];
  for (var i = 1; i < 8; i++) {
    final tt = (t - i * 0.012).clamp(0.0, 1.0);
    prev.add(
      Offset(
        _agLerp(80, 720, tt) + 8,
        g - 40 - (math.sin(tt * math.pi * 6)).abs() * 70,
      ),
    );
  }
  final trail = _ink(0.4 * a);
  for (final p in prev) {
    c.drawCircle(p, 1.6, trail);
  }
  _agSaye(c, Offset(x, g + 6 - hop), 1.0, time, a, rot: 0.25, seed: 12);
}

/// Köprü 7, satır 1: güneşin ilk ışığı taş yüzlere vurur; Sâye
/// Kandilcilerin yakmak üzere olduğu ışığa uzanır.
void _agFirstLight(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final rise = _span(u, 1.0, 1.6);
  final sun = Offset(400, g + 20 - 60 * rise);
  c.drawCircle(
    sun,
    230,
    Paint()
      ..shader = ui.Gradient.radial(sun, 230, [
        const Color(0xFFFFF6DA).withValues(alpha: 0.9 * a),
        const Color(0x00FFF6DA),
      ]),
  );
  c.drawCircle(
    sun,
    46,
    Paint()..color = const Color(0xFFFFF8E4).withValues(alpha: a),
  );
  final rays = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFF4D6).withValues(alpha: 0.6 * a * rise);
  for (var i = 0; i < 7; i++) {
    final ang = math.pi + 0.25 + i * 0.4;
    c.drawLine(
      sun + Offset(math.cos(ang), math.sin(ang)) * 60,
      sun + Offset(math.cos(ang), math.sin(ang)) * (120 + 30 * rise),
      rays,
    );
  }
  c.drawRect(Rect.fromLTWH(0, g, 780, 60), _ink(a));
  // Taş yüzler ilk ışığı alır.
  final lit = _span(u, 1.2, 1.5);
  for (final (x, sz, kind) in [
    (70.0, 104.0, 1),
    (190.0, 118.0, 0),
    (300.0, 96.0, 2),
  ]) {
    _agStoneHead(c, Offset(x, g + 2), sz, a, kind: kind, light: lit);
  }
  // Sunak ve çalınan ışık.
  c.drawRect(const Rect.fromLTWH(570, 290, 70, 60), _ink(a));
  c.drawRect(const Rect.fromLTWH(560, 280, 90, 12), _ink(a));
  final orb = const Offset(605, 250);
  c.drawCircle(
    orb,
    52,
    Paint()
      ..shader = ui.Gradient.radial(orb, 52, [
        const Color(0xFFFFF4D0).withValues(alpha: 0.9 * a),
        const Color(0x00FFF4D0),
      ]),
  );
  c.drawCircle(orb, 16 + math.sin(time * 6) * 1.5, _hole(a));
  _agKandilci(c, const Offset(735, g + 4), 0.8, time, a, flip: true, seed: 4);
  // Sâye uzanıp dokunur.
  final reach = _span(u, 1.35, 1.7);
  final sx = _agLerp(470, 545, _span(u, 1.05, 1.35));
  _agSaye(c, Offset(sx, g + 6), 1.8, time, a, raise: 0.5 * reach, seed: 13);
  if (reach > 0.9) {
    c.drawCircle(orb, 24 + 10 * math.sin(time * 9).abs(), _stroke(_hole(a), 2));
  }
}

// ===================================================== Kaf → Ağrı → Nemrut
// İkinci perde (Ağrı, Tufan, Nemrut, gün doğumu) ve köprüleri: her satır
// kendi resmiyle. Aynı yerde geçen satırlar bir zemini paylaşır; yer
// değişince resimler satır sınırında birbirine geçer.

/// Satır penceresi: [a] satırının başında belirir, [b] satırının başında
/// söner; sınırda komşu resimle çapraz geçer. İlk satır baştan görünür;
/// [b] ≥ [last] ise sönmez.
double _agWin(double u, double a, double b, [double last = 99]) {
  const f = 0.12;
  final i = a <= 0 ? 1.0 : _span(u, a - f, a + f);
  final o = b >= last ? 0.0 : _span(u, b - f, b + f);
  return math.min(i, 1 - o);
}

double _agLerp(double a, double b, double t) => a + (b - a) * t;

/// Sâye tasviri: ayakları [feet]'te, [flip] ise sola bakar. [raise] boştaki
/// kolu yukarı kaldırır, [fist] öne yumruk yapar; [smile] yüzüne gülümseme
/// keser; [jar] kavanozun ışığı.
void _agSaye(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double jar = 1,
  double raise = 0,
  double fist = 0,
  double smile = 0,
  double rot = 0,
  double seed = 0,
}) {
  if (a <= 0.01) return;
  _P._c = c;
  final ink = _ink(a);
  final hole = _hole(a);
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.7 + seed) * 1.2);
  c.rotate(rot + math.sin(time * 1.1 + seed * 2) * 0.02);
  c.scale(flip ? -s : s, s);
  if (raise > 0 || fist > 0) {
    // Arkadaki kol: omuzdan kalkar (açık el) ya da öne yumruk olur.
    c.save();
    c.translate(-1, -50);
    c.rotate(-0.25 - 2.2 * raise - 1.35 * fist);
    final arm = Path()
      ..moveTo(-3, 0)
      ..lineTo(3, 0)
      ..lineTo(2, 22)
      ..lineTo(-2, 22)
      ..close();
    c.drawPath(arm, ink);
    c.drawCircle(const Offset(0, 24), fist > 0 ? 4.2 : 3.4, ink);
    if (raise > 0.5) {
      // Açık el: parmaklar.
      for (var i = 0; i < 4; i++) {
        c.drawLine(
          Offset(-2.4 + i * 1.6, 25),
          Offset(-3.6 + i * 2.4, 30),
          ink..strokeWidth = 1.3,
        );
      }
    }
    c.restore();
  }
  _P._saye(ink, hole, time, jar: jar);
  if (smile > 0) {
    final cut = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = PerdePainter._hole.withValues(alpha: 0.95 * a * smile);
    // Gülen ağız ve kısılmış göz.
    c.drawArc(
      Rect.fromCenter(center: const Offset(5, -63), width: 9, height: 7),
      0.35,
      2.2,
      false,
      cut,
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(5, -69.5), width: 6, height: 5),
      math.pi + 0.4,
      math.pi - 0.8,
      false,
      cut,
    );
  }
  c.restore();
}

/// Hüdhüd: [flip] ise sola bakar.
void _agHudhud(
  Canvas c,
  Offset at,
  double s,
  double time,
  double a, {
  bool flip = false,
}) {
  if (a <= 0.01) return;
  c.save();
  c.translate(at.dx, at.dy);
  if (flip) c.scale(-1, 1);
  _tasvirHudhud(c, Offset.zero, s, time, a);
  c.restore();
}

/// Kandilci: fenerinin ışığı çevresine düşer; [flip] ise sola bakar.
void _agKandilci(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double seed = 0,
  double lift = 0,
}) {
  if (a <= 0.01) return;
  _P._c = c;
  final lantern = feet + Offset((flip ? -88 : 88) * s, (-188 - lift) * s);
  c.drawCircle(
    lantern,
    60 * s,
    Paint()
      ..shader = ui.Gradient.radial(lantern, 60 * s, [
        const Color(0xFFFFE0A0).withValues(alpha: 0.7 * a),
        const Color(0x00FFE0A0),
      ]),
  );
  _P._puppet(
    c,
    feet,
    time,
    seed,
    a,
    (ink, hole) => _P._lamplighter(ink, hole, lanternLift: lift),
    scale: s,
    flip: flip,
    rod: false,
  );
}

/// Ateş: kıvrık alev dilleri (ışık, kenarı mürekkep), odun, kıvılcım.
void _agFire(
  Canvas c,
  Offset base,
  double w,
  double h,
  double time,
  double a, {
  double seed = 0,
}) {
  if (a <= 0.01) return;
  final glowC = base.translate(0, -h * 0.45);
  c.drawCircle(
    glowC,
    h * 1.5,
    Paint()
      ..shader = ui.Gradient.radial(glowC, h * 1.5, [
        const Color(0xFFFFE6B0).withValues(alpha: 0.55 * a),
        const Color(0x00FFE6B0),
      ]),
  );
  Path tongue(double x, double tw, double th, double sway) => Path()
    ..moveTo(x - tw / 2, base.dy)
    ..cubicTo(
      x - tw * 0.7,
      base.dy - th * 0.45,
      x + sway - tw * 0.25,
      base.dy - th * 0.7,
      x + sway,
      base.dy - th,
    )
    ..cubicTo(
      x + sway + tw * 0.05,
      base.dy - th * 0.62,
      x + tw * 0.7,
      base.dy - th * 0.42,
      x + tw / 2,
      base.dy,
    )
    ..close();
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round
    ..color = PerdePainter._ink.withValues(alpha: 0.85 * a);
  const n = 5;
  for (var i = 0; i < n; i++) {
    final k = (i - (n - 1) / 2) / ((n - 1) / 2);
    final x = base.dx + k * w * 0.36;
    final th =
        h *
        (1 - 0.45 * k.abs()) *
        (0.82 + 0.18 * math.sin(time * 9 + i * 1.7 + seed));
    final sway = math.sin(time * 6 + i * 2.1 + seed) * w * 0.1;
    final p = tongue(x, w * 0.34, th, sway);
    c.drawPath(
      p,
      Paint()..color = const Color(0xFFFFB04A).withValues(alpha: a),
    );
    c.drawPath(p, rim);
    c.drawPath(
      tongue(x, w * 0.16, th * 0.62, sway * 0.6),
      Paint()..color = const Color(0xFFFFF4D6).withValues(alpha: a),
    );
  }
  // Odunlar.
  final log = _ink(a);
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.translate(base.dx, base.dy + 2);
    c.rotate(d * 0.22);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 1.1, height: 8),
        const Radius.circular(4),
      ),
      log,
    );
    c.restore();
  }
  // Kıvılcımlar.
  final sp = _hole(0.9 * a);
  for (var i = 0; i < 6; i++) {
    final k = (time * 0.7 + i / 6 + seed) % 1;
    c.drawCircle(
      Offset(
        base.dx + math.sin(i * 2.3 + time * 2) * w * 0.4,
        base.dy - h * (0.6 + k * 1.1),
      ),
      1.8 * (1 - k) + 0.4,
      sp,
    );
  }
}

/// Fısıltı: ağızdan kulağa küçük yaylar.
void _agWhisper(Canvas c, Offset from, Offset dir, double time, double a) {
  if (a <= 0.01) return;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..color = PerdePainter._ink.withValues(alpha: 0.75 * a);
  final ang = math.atan2(dir.dy, dir.dx);
  for (var i = 0; i < 3; i++) {
    final k = (time * 1.4 + i / 3) % 1;
    final r = 6 + k * 16;
    c.drawArc(
      Rect.fromCircle(center: from, radius: r),
      ang - 0.5,
      1.0,
      false,
      p..color = PerdePainter._ink.withValues(alpha: 0.75 * a * (1 - k)),
    );
  }
}

// ---------------------------------------------------- Perde 4: ayna, Ağrı

/// Kaf'ın aynası: oymalı kara çerçeve, ayaklı; [mc] camın ortası.
void _agMirrorFrame(Canvas c, Offset mc, double a) {
  final ink = _ink(a);
  // Ayak ve kaide.
  c.drawPath(
    Path()
      ..moveTo(mc.dx - 18, mc.dy + 120)
      ..lineTo(mc.dx - 30, mc.dy + 150)
      ..lineTo(mc.dx + 30, mc.dy + 150)
      ..lineTo(mc.dx + 18, mc.dy + 120)
      ..close(),
    ink,
  );
  c.drawOval(Rect.fromCenter(center: mc, width: 200, height: 262), ink);
  // Tepede taç süsü.
  c.drawPath(
    Path()
      ..moveTo(mc.dx - 30, mc.dy - 124)
      ..quadraticBezierTo(mc.dx, mc.dy - 160, mc.dx + 30, mc.dy - 124)
      ..close(),
    ink,
  );
  _rosette(c, mc.translate(0, -136), 8, a);
  // Çerçevede zımba süsü.
  final p = _hole(0.7 * a);
  for (var i = 0; i < 28; i++) {
    final t = i / 28 * math.pi * 2;
    c.drawCircle(mc + Offset(math.cos(t) * 92, math.sin(t) * 122), 1.6, p);
  }
}

/// Aynanın camı: ışık; içine çizilecekler [inside] ile camın içine kırpılır.
void _agMirrorGlass(
  Canvas c,
  Offset mc,
  double a,
  void Function() inside, {
  double dim = 0,
}) {
  final glass = Rect.fromCenter(center: mc, width: 168, height: 230);
  c.drawOval(
    glass,
    Paint()
      ..shader = ui.Gradient.radial(mc, 120, [
        Color.lerp(
          const Color(0xFFFFF6DE),
          const Color(0xFFD89A5A),
          dim,
        )!.withValues(alpha: a),
        Color.lerp(
          const Color(0xFFEFC488),
          const Color(0xFF8A4A22),
          dim,
        )!.withValues(alpha: a),
      ]),
  );
  c.save();
  c.clipPath(Path()..addOval(glass));
  inside();
  c.restore();
}

/// Aynada beliren: zincirli bir el, titreyen bir kandil.
void _agVision(Canvas c, Offset mc, double time, double a) {
  if (a <= 0.01) return;
  final ink = _ink(a);
  // Ürperen cam: halkalar.
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = PerdePainter._ink.withValues(alpha: 0.3 * a);
  for (var i = 0; i < 3; i++) {
    final k = (time * 0.5 + i / 3) % 1;
    c.drawOval(
      Rect.fromCenter(center: mc, width: 40 + k * 150, height: 50 + k * 200),
      ring..color = PerdePainter._ink.withValues(alpha: 0.3 * a * (1 - k)),
    );
  }
  // El: aşağıdan kandile uzanır; bileğinde kelepçe, zincir sarkar.
  c.save();
  c.translate(mc.dx - 26, mc.dy + 112);
  c.rotate(0.25 + math.sin(time * 1.3) * 0.04);
  c.drawRect(const Rect.fromLTWH(-9, -60, 18, 60), ink);
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-13, -88, 26, 30),
      const Radius.circular(8),
    ),
    ink,
  );
  for (var i = 0; i < 4; i++) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-12 + i * 6.4, -110 + (i - 1.5).abs() * 4, 5.2, 26),
        const Radius.circular(2.6),
      ),
      ink,
    );
  }
  c.save();
  c.translate(12, -70);
  c.rotate(-0.7);
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, -3, 18, 6),
      const Radius.circular(3),
    ),
    ink,
  );
  c.restore();
  // Kelepçe: ışıklı kenarlı kalın bant.
  c.drawRect(const Rect.fromLTWH(-12, -50, 24, 12), ink);
  c.drawRect(
    const Rect.fromLTWH(-12, -50, 24, 12),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = PerdePainter._hole.withValues(alpha: 0.8 * a),
  );
  // Zincir halkaları: bilekten aşağı, sola sarkar.
  final link = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = PerdePainter._ink.withValues(alpha: 0.92 * a);
  for (var i = 0; i < 5; i++) {
    final p = Offset(
      -16 - i * 9.0,
      -40 + i * 10.0 + math.sin(time * 2 + i) * 1.5,
    );
    c.drawOval(
      Rect.fromCenter(
        center: p,
        width: i.isEven ? 12 : 7,
        height: i.isEven ? 7 : 12,
      ),
      link,
    );
  }
  c.restore();
  // Kandil: elin ucunda, titrer.
  final shake = Offset(math.sin(time * 23) * 2.2, math.sin(time * 17) * 1.4);
  final lp = mc + const Offset(30, -30) + shake;
  c.drawCircle(
    lp.translate(14, -14),
    34,
    Paint()
      ..shader = ui.Gradient.radial(lp.translate(14, -14), 34, [
        const Color(0xFFFFF4D6).withValues(alpha: 0.8 * a),
        const Color(0x00FFF4D6),
      ]),
  );
  c.drawPath(
    Path()
      ..moveTo(lp.dx - 22, lp.dy - 4)
      ..quadraticBezierTo(lp.dx - 4, lp.dy + 16, lp.dx + 16, lp.dy - 4)
      ..lineTo(lp.dx + 26, lp.dy - 10)
      ..lineTo(lp.dx + 14, lp.dy - 8)
      ..close(),
    ink,
  );
  c.drawArc(
    Rect.fromCenter(center: lp.translate(-22, -8), width: 14, height: 14),
    0.5,
    4.5,
    false,
    link..strokeWidth = 2.4,
  );
  final f = 12 + 4 * math.sin(time * 19);
  c.drawPath(
    Path()
      ..moveTo(lp.dx + 20, lp.dy - 10)
      ..quadraticBezierTo(
        lp.dx + 14,
        lp.dy - 10 - f * 0.6,
        lp.dx + 22 + shake.dx,
        lp.dy - 10 - f,
      )
      ..quadraticBezierTo(
        lp.dx + 28,
        lp.dy - 10 - f * 0.5,
        lp.dx + 24,
        lp.dy - 10,
      )
      ..close(),
    _hole(a),
  );
}

/// Simurg: aynada otuz kuş, kanat açmış koca bir kuş olur.
void _agSimurgInMirror(Canvas c, Offset mc, double time, double a) {
  if (a <= 0.01) return;
  c.save();
  c.translate(mc.dx, mc.dy + 70);
  c.scale(1.5);
  c.drawPath(MythShapes.birdGlide, _ink(0.22 * a));
  c.restore();
  for (var i = 0; i < 30; i++) {
    final Offset p;
    if (i < 20) {
      // Kanatlar: gövdeden dışa, uca doğru yükselen yay.
      final side = i < 10 ? -1.0 : 1.0;
      final k = (i % 10) / 9;
      p = Offset(side * (12 + k * 64), -6 - math.sin(k * 2.4) * 30 + k * 6);
    } else {
      // Gövde, baş ve kuyruk: dikey dizi.
      final k = (i - 20) / 9;
      p = Offset(0, -52 + k * 120);
    }
    _P._bird(c, mc + p, time, a, i * 0.9);
  }
}

/// Perde 4: Kaf'ın aynası; Ağrı'nın eteğinde çobanlar; tipi ve Ayaz Ata.
void _mirrorTale(Canvas c, double time, double u) {
  _P._c = c;
  final aKaf = _agWin(u, 0, 3);
  if (aKaf > 0) _agKafMirror(c, time, u, aKaf);
  final aCamp = _agWin(u, 3, 5);
  if (aCamp > 0) _agShepherdCamp(c, time, u, aCamp);
  final aStorm = _agWin(u, 5, 6);
  if (aStorm > 0) _agBlizzardClimb(c, time, u, aStorm);
  final aTitle = _agWin(u, 6, 99);
  if (aTitle > 0) _agAgriTitle(c, time, aTitle);
}

void _agKafMirror(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  // Kaf'ın doruğu.
  c.drawPath(
    Path()
      ..moveTo(0, 400)
      ..lineTo(0, 360)
      ..lineTo(240, 336)
      ..lineTo(450, 318)
      ..lineTo(620, 336)
      ..lineTo(780, 360)
      ..lineTo(780, 400)
      ..close(),
    _ink(a),
  );
  const mc = Offset(470, 168);
  _agMirrorFrame(c, mc, a);
  // Otuz kuş: sağdaki yamaca konarlar.
  final land = _span(u, 0, 0.5);
  for (var i = 0; i < 30; i++) {
    final row = i ~/ 10;
    final tx = 600.0 + (i % 10) * 17 + row * 8;
    final ty = 340.0 + (tx - 600) * 0.12 + row * 9;
    final from = Offset(820 + (i % 7) * 20, 40.0 + (i % 5) * 26);
    final p = Offset.lerp(from, Offset(tx, ty), land)!;
    if (land < 1) {
      _P._bird(c, p, time, a, i * 0.7);
    } else {
      final ink = _ink(a);
      c.drawOval(
        Rect.fromCenter(center: p.translate(0, -5), width: 13, height: 8),
        ink,
      );
      c.drawCircle(p.translate(6, -10), 3.4, ink);
      c.drawLine(
        p.translate(-6, -5),
        p.translate(-11, -2),
        ink..strokeWidth = 2,
      );
    }
  }
  // Satır 0: Sâye aynaya yaklaşır. 1: el kaldırır, aynadaki gölge de.
  // 2: aynanın derininde zincirli el, titreyen kandil; Hüdhüd yolu gösterir
  // ve kendi yoluna uçar.
  final sx = _agLerp(120, 262, _span(u, 0.05, 0.75));
  final raise = _span(u, 1.2, 1.4) * (1 - _span(u, 1.8, 1.95));
  final simurg = _span(u, 0.3, 0.75) * (1 - _span(u, 0.92, 1.15));
  final mirrorSelf = _span(u, 1.0, 1.2) * (1 - _span(u, 2.0, 2.2));
  final vision = _span(u, 2.05, 2.3);
  _agMirrorGlass(c, mc, a, () {
    _agSimurgInMirror(c, mc, time, a * simurg);
    if (mirrorSelf > 0) {
      // Aynadaki: bir çocuk değil, bir gölge (kavanozunda ışık yok).
      _agSaye(
        c,
        mc + const Offset(18, 108),
        1.55,
        time,
        a * mirrorSelf,
        flip: true,
        jar: 0,
        raise: raise,
        seed: 0,
      );
    }
    _agVision(c, mc, time, a * vision);
  }, dim: 0.35 * vision);
  _agSaye(c, Offset(sx, g + 6), 1.9, time, a, raise: raise);
  // Hüdhüd: 0'da Sâye'nin kulağına fısıldar, 1'de geride bekler, 2'de
  // aynanın önüne gelip konuşur, sonra kendi yoluna uçar.
  final Offset hp;
  var hflip = false;
  if (u < 1) {
    hp = Offset(sx - 46, 150);
  } else if (u < 2) {
    hp = Offset.lerp(
      const Offset(216, 150),
      const Offset(150, 118),
      _span(u, 1.0, 1.3),
    )!;
  } else {
    final come = _span(u, 2.25, 2.5);
    final go = _span(u, 2.72, 2.98);
    hp = Offset.lerp(
      Offset.lerp(const Offset(150, 118), const Offset(300, 106), come)!,
      const Offset(90, 70),
      go,
    )!;
    hflip = come > 0.5 && go < 0.1;
  }
  final hgone = 1 - _span(u, 2.8, 2.98);
  _agHudhud(c, hp, 1.0, time, a * hgone, flip: hflip);
  if (u < 1) {
    _agWhisper(
      c,
      hp + const Offset(46, 2),
      const Offset(1, 0.3),
      time,
      a * _span(u, 0.15, 0.3),
    );
  } else if (u > 2.3 && u < 2.75) {
    _agWhisper(c, hp + const Offset(-46, 2), const Offset(-1, 0.3), time, a);
  }
}

/// Genç çoban (Masis der) ve yaşlı çoban (Agirî der): börklü, kepenekli.
const _agCobanGenc = _Look(
  hat: _Hat.hair,
  garb: _Garb.kaftan,
  beard: _Beard.short,
);
const _agCobanYasli = _Look(
  hat: _Hat.bork,
  garb: _Garb.kaftan,
  beard: _Beard.long,
  bent: 0.16,
  cape: true,
  prop: _Prop.staff,
);

/// Ayaz Ata: kışın sahibi. Uzun kürk kalpaklı, bastonlu ihtiyar; sakalı
/// ak (ışıktan kesik), gözleri buz; çevresinde kar döner. [hand] öbür elini
/// "dur" der gibi kaldırır. [flip] ise sola bakar.
void _agAyazAta(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = false,
  double hand = 0,
}) {
  if (a <= 0.01) return;
  final s = h / 112;
  final ink = _ink(a);
  // Ayaz: çevresinde soğuk bir hale.
  final halo = feet.translate(0, -h * 0.55);
  c.drawCircle(
    halo,
    h * 0.65,
    Paint()
      ..shader = ui.Gradient.radial(halo, h * 0.65, [
        const Color(0xFFF4FBFF).withValues(alpha: 0.4 * a),
        const Color(0x00F4FBFF),
      ]),
  );
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.3) * 1.0);
  c.scale(flip ? -s : s, s);
  c.drawPath(MythFigures.ayazAtaSilhouette, ink);
  // Uzun kürk kalpak.
  c.drawPath(
    Path()
      ..moveTo(-5, -94)
      ..cubicTo(-7, -110, -4, -124, 6, -127)
      ..cubicTo(15, -126, 21, -114, 20, -93)
      ..close(),
    ink,
  );
  final fur = _hole(0.85 * a);
  for (var i = 0; i < 7; i++) {
    c.drawCircle(Offset(-4 + i * 3.9, -94 + (i.isEven ? 0 : 1.2)), 1.5, fur);
  }
  // Ak sakal: göğsüne iner, uçları buz saçağı.
  final white = Paint()
    ..color = const Color(0xFFFFF8EC).withValues(alpha: 0.95 * a);
  c.drawPath(
    Path()
      ..moveTo(8, -88)
      ..cubicTo(6, -76, 8, -62, 12, -50)
      ..lineTo(14, -56)
      ..lineTo(15.5, -49)
      ..cubicTo(18, -62, 20, -76, 18.5, -87)
      ..cubicTo(15, -85, 11, -85, 8, -88)
      ..close(),
    white,
  );
  c.drawLine(
    const Offset(11, -84),
    const Offset(13, -60),
    ink..strokeWidth = 0.6,
  );
  // Buz göz.
  c.drawCircle(
    const Offset(14.5, -91.5),
    1.8,
    Paint()..color = const Color(0xFFE6F6FF).withValues(alpha: a),
  );
  // Cübbede kar çiçekleri.
  for (final p in [const Offset(-2, -64), const Offset(0, -36)]) {
    _rosette(c, p, 4.5, a);
  }
  if (hand > 0) {
    // "Dur": açık el öne kalkar.
    c.save();
    c.translate(4, -76);
    c.rotate(-0.4 - 1.5 * hand);
    c.drawPath(
      Path()
        ..moveTo(-3.5, 0)
        ..lineTo(3.5, 0)
        ..lineTo(2.5, 26)
        ..lineTo(-2.5, 26)
        ..close(),
      ink,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 30), width: 7, height: 10),
      ink,
    );
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset(-2.4 + i * 1.6, 33),
        Offset(-3.2 + i * 2.1, 38),
        ink..strokeWidth = 1.4,
      );
    }
    c.restore();
  }
  c.restore();
  // Dönen kar.
  final flake = Paint()
    ..color = const Color(0xFFF8FCFF).withValues(alpha: 0.85 * a);
  for (var i = 0; i < 16; i++) {
    final t = time * 0.9 + i * 0.39;
    final r = h * (0.28 + 0.12 * math.sin(i * 1.7));
    c.drawCircle(
      halo + Offset(math.cos(t) * r * 1.1, math.sin(t) * r * 0.9),
      1.4 + (i % 3) * 0.6,
      flake,
    );
  }
}

/// Ağrı: Büyük ve Küçük Ağrı, karlı doruklar; omzunda Nuh'un gemisi.
void _agAgriPeaks(
  Canvas c,
  double a, {
  Offset big = const Offset(250, 66),
  double ark = 0,
  double arkGlow = 0,
  double alpha = 0.42,
}) {
  final far = _ink(alpha * a);
  final bx = big.dx;
  final by = big.dy;
  c.drawPath(
    Path()
      ..moveTo(bx - 330, PerdePainter._ground)
      ..lineTo(bx, by)
      ..lineTo(bx + 75, by + 70)
      ..lineTo(bx + 105, by + 78)
      ..lineTo(bx + 310, PerdePainter._ground)
      ..close(),
    far,
  );
  c.drawPath(
    Path()
      ..moveTo(bx + 240, PerdePainter._ground)
      ..lineTo(bx + 400, by + 130)
      ..lineTo(bx + 560, PerdePainter._ground)
      ..close(),
    _ink(alpha * 0.8 * a),
  );
  // Karlı doruklar.
  final snow = _hole(0.55 * a);
  c.drawPath(
    Path()
      ..moveTo(bx, by)
      ..lineTo(bx + 34, by + 32)
      ..lineTo(bx + 16, by + 26)
      ..lineTo(bx + 4, by + 40)
      ..lineTo(bx - 12, by + 26)
      ..lineTo(bx - 32, by + 34)
      ..close(),
    snow,
  );
  c.drawPath(
    Path()
      ..moveTo(bx + 400, by + 130)
      ..lineTo(bx + 424, by + 152)
      ..lineTo(bx + 404, by + 148)
      ..lineTo(bx + 384, by + 156)
      ..close(),
    snow,
  );
  if (ark > 0) {
    // Omuzdaki düzlükte gemi: altında kara bir kaya çıkıntısı.
    c.drawPath(
      Path()
        ..moveTo(bx + 52, by + 80)
        ..lineTo(bx + 70, by + 72)
        ..lineTo(bx + 120, by + 74)
        ..lineTo(bx + 132, by + 90)
        ..close(),
      _ink(0.8 * a * ark),
    );
    c.save();
    c.translate(bx + 92, by + 72);
    c.scale(0.28);
    _arkShape(_ink(ark * a), _hole(0.8 * a * ark), arkGlow);
    c.restore();
    if (arkGlow > 0) {
      final gp = Offset(bx + 90, by + 60);
      c.drawCircle(
        gp,
        34,
        Paint()
          ..shader = ui.Gradient.radial(gp, 34, [
            const Color(0xFFFFF0C0).withValues(alpha: 0.6 * a * arkGlow),
            const Color(0x00FFF0C0),
          ]),
      );
    }
  }
}

/// Karlı zemin: koyu toprak, üstünde kar öbekleri.
void _agSnowGround(Canvas c, double a, {double y = PerdePainter._ground}) {
  c.drawRect(Rect.fromLTWH(0, y, 780, 400 - y + 10), _ink(a));
  final snow = _hole(0.4 * a);
  for (var i = 0; i < 16; i++) {
    final x = 20 + i * 49.0 + (i % 3) * 7;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + 2),
        width: 26 + (i % 4) * 6,
        height: 5,
      ),
      snow,
    );
  }
}

/// Satır 3-4: dağın eteğinde iki çoban ateş başında; yaşlı çoban Hakob'u
/// anlatır, anlattığı dağın yamacında görünür.
void _agShepherdCamp(Canvas c, double time, double u, double a) {
  const g = PerdePainter._ground;
  final arkGlow = _span(u, 3.6, 3.85);
  _agAgriPeaks(c, a, ark: 1, arkGlow: arkGlow * (1 - _span(u, 4.0, 4.2)));
  _agSnowGround(c, a);
  _snowfall(c, time, 0.7 * a, wind: 20);
  // Hakob'un masalı (satır 4): yamaçta.
  if (u > 3.9) _agHakobTale(c, time, u, a * _span(u, 3.95, 4.1));
  _agFire(c, const Offset(535, g + 4), 70, 66, time, a);
  // Konuşan çoban kolunu oynatır.
  final talk1 = _shown(u, 3.36, 3.6, 0.06);
  final talk2 = math.max(_shown(u, 3.58, 4.0, 0.06), _span(u, 3.95, 4.05));
  _person(
    c,
    const Offset(440, g + 6),
    186,
    a,
    _agCobanGenc,
    time: time,
    arm: -1.2 * talk1 + 0.25 * talk1 * math.sin(time * 7),
  );
  final pointUp = _shown(u, 3.72, 4.0, 0.08);
  _person(
    c,
    const Offset(640, g + 6),
    196,
    a,
    _agCobanYasli,
    flip: true,
    time: time,
    arm: -0.8 * talk2 + 0.2 * talk2 * math.sin(time * 6) - 1.4 * pointUp,
  );
  // Sâye varır, ateşin ışığında dinler.
  final sx = _agLerp(40, 300, _span(u, 3.02, 3.4));
  _agSaye(c, Offset(sx, g + 6), 1.8, time, a);
}

/// Hakob: her gece tırmanır, her sabah eteklerde uyanır; sonunda melek
/// ona gemiden bir tahta getirir.
void _agHakobTale(Canvas c, double time, double u, double a) {
  if (a <= 0.01) return;
  // Sol yamaç: (-80, 350) → (250, 66).
  double slope(double x) => 350 - (x + 80) * 0.8606;
  final night = _shown(u, 4.0, 4.45, 0.06);
  if (night > 0) {
    // Ay.
    final m = _hole(0.9 * a * night);
    c.drawCircle(const Offset(70, 60), 16, m);
    c.drawCircle(const Offset(78, 55), 14, _ink(0.0));
    c.drawCircle(
      const Offset(79, 55),
      14,
      Paint()..color = const Color(0xFFE6A15A).withValues(alpha: a * night),
    );
  }
  final climb = _span(u, 4.04, 4.4);
  final ca = _shown(u, 4.0, 4.46, 0.06);
  final cx = _agLerp(40, 160, climb);
  // Tırmandığı patika.
  c.drawLine(
    Offset(-10, slope(-10)),
    Offset(cx, slope(cx)),
    Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = PerdePainter._ink.withValues(alpha: 0.6 * a * ca),
  );
  _person(
    c,
    Offset(cx, slope(cx) + 2),
    96,
    a * ca,
    _monk,
    time: time,
    rot: 0.12,
  );
  // Sabah: eteklerde uyanır; melek tahtayı getirir.
  final morning = _span(u, 4.44, 4.56);
  if (morning > 0) {
    final wake = _span(u, 4.6, 4.72);
    if (wake < 1) {
      // Yatan keşiş.
      _person(
        c,
        const Offset(30, 346),
        92,
        a * morning * (1 - wake),
        _monk,
        flip: true,
        rot: math.pi / 2,
      );
    }
    _person(c, const Offset(62, 354), 96, a * wake, _monk, time: time);
    final down = _span(u, 4.55, 4.85);
    final angel = Offset(_agLerp(230, 150, down), _agLerp(40, 230, down));
    final aa = a * _span(u, 4.52, 4.62);
    _wings(
      c,
      angel.translate(0, -50),
      56,
      0.25 + math.sin(time * 3) * 0.12,
      aa,
    );
    _person(c, angel.translate(0, 26), 64, aa, _angel, flip: true, arm: -1.1);
    // Gemiden tahta: meleğin elinden keşişe.
    final give = _span(u, 4.85, 4.95);
    final pl = Offset.lerp(
      angel.translate(-32, -6),
      const Offset(86, 300),
      give,
    )!;
    c.save();
    c.translate(pl.dx, pl.dy);
    c.rotate(-0.4 + give * 0.4);
    c.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 40, height: 8),
      _ink(aa),
    );
    _punchRow(c, const Offset(-16, 0), const Offset(16, 0), 4, 1.2, aa);
    c.restore();
  }
}

/// Satır 5: yamaçta tipi; tipinin içinden Ayaz Ata çıkar.
void _agBlizzardClimb(Canvas c, double time, double u, double a) {
  double slope(double x) => 372 - x * 110 / 780;
  final storm = _span(u, 5.0, 5.3);
  _agAgriPeaks(
    c,
    a,
    big: const Offset(560, 40),
    alpha: 0.3 * (1 - 0.5 * storm),
  );
  c.drawPath(
    Path()
      ..moveTo(0, 400)
      ..lineTo(0, slope(0))
      ..lineTo(780, slope(780))
      ..lineTo(780, 400)
      ..close(),
    _ink(a),
  );
  // Tipi: kar perdeyi ağartır, rüzgâr çizgileri.
  c.drawRect(
    const Rect.fromLTWH(0, 0, 780, 400),
    Paint()
      ..color = const Color(0xFFFFF2DC).withValues(alpha: 0.22 * a * storm),
  );
  final wind = Paint()
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFF8EC).withValues(alpha: 0.7 * a * storm);
  for (var i = 0; i < 70; i++) {
    final x = (i * 71.0 + time * 380) % 860 - 40;
    final y = (i * 37.0 + time * 60) % 380;
    c.drawLine(Offset(x, y), Offset(x - 22, y - 5), wind);
  }
  // Sâye tırmanır; Ayaz Ata belirince durur, kavanozu titrer.
  final sx = _agLerp(90, 230, _span(u, 5.02, 5.4));
  final fear = _span(u, 5.5, 5.62);
  final jar = 1 - fear * (0.45 + 0.4 * math.sin(time * 23).abs());
  final tremble = fear * math.sin(time * 31) * 1.6;
  _agSaye(
    c,
    Offset(sx + tremble, slope(sx) + 6),
    1.8,
    time,
    a,
    jar: jar,
    rot: 0.08 * (1 - fear),
  );
  if (fear > 0) {
    // Ateşböcekleri titreşir: kavanozun çevresinde ürkek ışıklar.
    final jp = Offset(sx + 26 * 1.8, slope(sx) + 6 - 26 * 1.8);
    final f = _hole(0.8 * a * fear);
    for (var i = 0; i < 5; i++) {
      c.drawCircle(
        jp +
            Offset(
              math.sin(time * 27 + i * 2) * 6,
              math.cos(time * 23 + i) * 6,
            ),
        1.5,
        f,
      );
    }
  }
  final ay = _span(u, 5.22, 5.5);
  const ax = 540.0;
  _agAyazAta(
    c,
    Offset(ax, slope(ax) + 6),
    228,
    time,
    a * ay,
    flip: true,
    hand: _span(u, 5.55, 5.7),
  );
}

/// Başlık: İkinci Perde · Dağ. Levha sağ üstte; Ağrı solda.
void _agAgriTitle(Canvas c, double time, double a) {
  _agAgriPeaks(c, a, big: const Offset(260, 70), ark: 1, alpha: 0.6);
  _agSnowGround(c, a);
  _snowfall(c, time, a, wind: 40);
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
  // Önce ve sonra kar ovası (uzakta şehir); ortada Konya'nın içi.
  final city = _shown(u, 2.0, 3.97, 0.3);
  _snowPlain(canvas, time, 1 - city);
  _farCity(canvas, 690, 296, 0.55, 1 - city, glow: 0.5);
  if (city <= 0) return;
  _P._city(canvas, city);
  _greenDome(canvas, 540, city, scale: 0.9);
  // Semâzenler, düğün gecesi döner.
  final sa = _span(u, 1.6, 2.3) * city;
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
  final na = _span(u, 2.2, 2.8) * city;
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
  // Yakın tasvirlerde (1-7, 10, 12) kubbe ardında hayalet gibi kalmasın.
  final close = math.max(
    _shown(u, 0.9, 7.95, 0.3),
    math.max(_shown(u, 10.0, 11.0), _shown(u, 12.0, 13.0)),
  );
  _greenDome(canvas, 390, 1 - close, scale: 1.05);
  const top = Offset(390, 350 - 262 * 1.05);

  // Kandilciler halka olmuş; fenerlerinin ışığı sonunda göğe uçar.
  final freed = _span(u, 10.8, 11.8);
  // Halka, usta ve Sâye geniş manzarada kandilin sönüşünden az önce
  // görünür; öncesini yakın tasvirler anlatır.
  final ring = _shown(u, 7.85, 12.8);
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
  final ma = _shown(u, 7.85, 8.9, 0.4);
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
      _hole(0.95 * _span(u, 7.8, 8.0) * (1 - _span(u, 7.9, 8.2))),
    );
  }

  // Sâye: önce gölge, sonra ışık.
  final sa = _span(u, 7.85, 8.1);
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
  // (Konuşu 12. satırın yakın tasvirinde; burada omzunda oturur.)
  final land = _span(u, 12.8, 13.0);
  if (land > 0) {
    canvas.save();
    final p = top.translate(36, -40);
    canvas.translate(p.dx, p.dy);
    canvas.scale(0.7);
    _P._c = canvas;
    _P._hoopoe(_ink(land), time);
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

/// Satır [k] okunurken (u: k..k+1) beliren, sonunda sönen görünürlük.
double _line(double u, double k) =>
    _span(u, k + 0.05, k + 0.35) * (1 - _span(u, k + 0.85, k + 1.0));

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
  // Kam, katlar, Hüma ve Sâye'nin yükselişi satır satır tasvirde
  // (perde_son.dart).
}
