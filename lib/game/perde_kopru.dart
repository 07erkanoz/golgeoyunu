part of 'perde.dart';

// Köprüler: Hikâye tiyatrosunda bölüm perdesinden sonra, Sâye'nin o
// bölümde yürüdüğü yol. Her bölümün kendi zemini; satır satır o bölümün
// karşılaşmaları; Sâye perdeyi soldan sağa geçer.

const _gb = PerdePainter._ground;

Paint _far(double a) => _ink(0.38 * a);

Paint _stroke(Paint p, double w) => p
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

/// Bezin kendi rengi: koyu bir zeminde oyulmuş aydınlık yer (tünel, oda).
Paint _cloth(double a) =>
    Paint()..color = const Color(0xFFF2B46A).withValues(alpha: a);

/// Sâye'nin soldan sağa yürüyüşü ([n] satır boyunca).
double _walkX(double u, double n, double x0, double x1) =>
    x0 + (x1 - x0) * _span(u, 0.08, n - 0.15);

void _sayeAt(
  Canvas c,
  Offset feet,
  double time, {
  double s = 1.5,
  double a = 1,
  double rot = 0,
}) {
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  _tasvirSaye(c, Offset.zero, s, time, a);
  c.restore();
}

void _snowfall(Canvas c, double time, double a, {double wind = 30}) {
  final p = _hole(0.45 * a);
  for (var i = 0; i < 46; i++) {
    final x = (i * 83.0 + time * wind) % 800 - 10;
    final y = (i * 47.0 + time * (40 + i % 5 * 8)) % 360;
    c.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.6, p);
  }
}

void _peaks(
  Canvas c,
  List<(double, double)> pts,
  Paint p, {
  double base = _gb,
}) {
  final path = Path()..moveTo(pts.first.$1, base);
  for (final (x, y) in pts) {
    path.lineTo(x, y);
  }
  path
    ..lineTo(pts.last.$1, base)
    ..close();
  c.drawPath(path, p);
}

void _floor(Canvas c, double a) =>
    c.drawRect(Rect.fromLTWH(0, _gb, 780, 60), _ink(a));

void _bridgeStage(Canvas c, int level, double time, double u, int n) {
  _P._c = c;
  final nn = n.toDouble();
  switch (level) {
    case 0:
      _bCistern(c, time, u, nn);
    case 1:
      _bTower(c, time, u, nn);
    case 2:
      _bSkyRoad(c, time, u, nn);
    case 3:
      _bQaf(c, time, u, nn);
    case 4:
      _bAgri(c, time, u, nn);
    case 5:
      _bArk(c, time, u, nn);
    case 6:
      _bNemrut(c, time, u, nn);
    case 7:
      _bSunrise(c, time, u, nn);
    case 8:
      _bSnowRoad(c, time, u, nn);
    case 9:
      _bSki(c, time, u, nn);
    case 10:
      _bAvalanche(c, time, u, nn);
    case 11:
      _bFairy(c, time, u, nn);
    case 12:
      _bDerinkuyu(c, time, u, nn);
    case 13:
      _bKonya(c, time, u, nn);
    case 14:
      _bErlik(c, time, u, nn);
    case 15:
      _bErgenekon(c, time, u, nn);
    case 16:
      _bSky(c, time, u, nn);
    case 17:
      _bOtuken(c, time, u, nn);
    case 18:
      _bSky(c, time, u, nn);
    case 20:
      _bSea(c, time, u, nn);
  }
}

// ------------------------------------------------------------- Yerebatan

const _suIyesi = _Look(hat: _Hat.hair, garb: _Garb.dress, belt: false);

void _medusaHead(Canvas c, Offset at, double r, double rot, double a) {
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  final ink = _ink(a);
  for (var i = 0; i < 9; i++) {
    final ang = -math.pi + i * math.pi / 8;
    final p0 = Offset(math.cos(ang) * r * 0.8, math.sin(ang) * r * 0.8);
    final p1 = Offset(math.cos(ang) * r * 1.5, math.sin(ang) * r * 1.5);
    final mid = Offset.lerp(p0, p1, 0.5)! + Offset(-p1.dy, p1.dx) * 0.12;
    c.drawPath(
      Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p1.dx, p1.dy),
      _stroke(_ink(a), 4),
    );
    c.drawCircle(p1, 3, ink);
  }
  c.drawOval(
    Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r * 2.1),
    ink,
  );
  // Taş yüz: kapalı göz kesikleri, ağız.
  final cut = _stroke(_hole(0.55 * a), 1.6);
  c.drawLine(Offset(-r * 0.45, -r * 0.15), Offset(-r * 0.15, -r * 0.12), cut);
  c.drawLine(Offset(r * 0.15, -r * 0.12), Offset(r * 0.45, -r * 0.15), cut);
  c.drawLine(Offset(-r * 0.2, r * 0.5), Offset(r * 0.2, r * 0.5), cut);
  c.restore();
}

void _bCistern(Canvas c, double time, double u, double n) {
  final water = _gb - 14.0;
  final far = _far(1);
  for (var i = 0; i < 9; i++) {
    final x = 30 + i * 92.0;
    c.drawRect(Rect.fromLTWH(x - 9, 46, 18, water - 46), far);
    c.drawRect(Rect.fromLTWH(x - 15, 40, 30, 10), far);
    if (i < 8) {
      c.drawArc(
        Rect.fromLTWH(x, 4, 92, 74),
        math.pi,
        math.pi,
        false,
        _stroke(_far(1), 7),
      );
    }
  }
  c.drawRect(Rect.fromLTWH(0, water, 780, 70), _ink(0.6));
  final rip = _stroke(_hole(0.22), 1.2);
  for (var i = 0; i < 12; i++) {
    final x = (i * 71.0 + time * 12) % 800 - 10;
    c.drawLine(
      Offset(x, water + 8 + i % 3 * 9),
      Offset(x + 26, water + 8 + i % 3 * 9),
      rip,
    );
  }
  final x = _walkX(u, n, 120, 640);
  // 0: su iyesi sudan yükselir, vanayı gösterir.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    final rise = _span(u, 0.05, 0.5);
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, 780, water));
    _person(
      c,
      Offset(330, water + 120 - 110 * rise),
      190,
      a0,
      _suIyesi,
      arm: -2.1,
      time: time,
    );
    c.restore();
    final valve = const Offset(490, 170);
    c.save();
    c.translate(valve.dx, valve.dy);
    c.rotate(time * 0.6 * _span(u, 0.5, 0.9));
    c.drawCircle(Offset.zero, 18, _stroke(_ink(a0), 4));
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset.zero,
        Offset(math.cos(i * math.pi / 2) * 18, math.sin(i * math.pi / 2) * 18),
        _stroke(_ink(a0), 3),
      );
    }
    c.restore();
    c.drawCircle(valve, 26, _hole(0.25 * a0 * _span(u, 0.5, 0.9)));
  }
  // 1: Medusa'nın başları: biri baş aşağı, biri yan.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    _medusaHead(c, Offset(214, water - 30), 30, math.pi, a1);
    _medusaHead(c, Offset(582, water - 30), 30, math.pi / 2, a1);
  }
  // 2: sal ve yukarıya merdiven.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    final steps = Path()..moveTo(680, water);
    for (var i = 0; i < 8; i++) {
      steps
        ..lineTo(680 + i * 13.0, water - i * 22.0 - 22)
        ..lineTo(693 + i * 13.0, water - i * 22.0 - 22);
    }
    steps
      ..lineTo(780, water - 180)
      ..lineTo(780, water)
      ..close();
    c.drawPath(steps, _ink(a2));
    c.drawCircle(const Offset(770, 120), 50, _hole(0.35 * a2));
  }
  final onRaft = _span(u, 2.0, 2.2);
  if (onRaft > 0) {
    c.drawRect(Rect.fromLTWH(x - 46, water - 6, 92, 10), _ink(onRaft));
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(x - 40 + i * 20.0, water - 6),
        Offset(x - 40 + i * 20.0, water + 4),
        _stroke(_hole(0.4 * onRaft), 1),
      );
    }
  }
  _sayeAt(c, Offset(x, water - (onRaft > 0 ? 4 : 0)), time);
}

// ------------------------------------------------------------- Kule

void _bTower(Canvas c, double time, double u, double n) {
  // Kulenin içi: kat kat döşemeler, taş duvar.
  c.drawRect(const Rect.fromLTWH(170, 0, 440, 400), _far(1));
  final floors = [_gb, 250.0, 150.0, 58.0];
  for (final y in floors) {
    c.drawRect(Rect.fromLTWH(170, y, 440, 8), _ink(0.8));
  }
  for (var i = 0; i < 3; i++) {
    c.drawArc(
      Rect.fromLTWH(360, floors[i + 1] + 20, 60, 70),
      math.pi,
      math.pi,
      true,
      _hole(0.25),
    );
    c.drawRect(Rect.fromLTWH(360, floors[i + 1] + 55, 60, 35), _hole(0.25));
  }
  // Sâye kat kat çıkar: her satırda bir kat.
  final lift = _span(u, 0.1, 2.3);
  final level = lift * 2.6;
  final fl = level.floor().clamp(0, 2);
  final fy = floors[fl] + (floors[fl + 1] - floors[fl]) * _P._ease(level - fl);
  var sx = 240 + 300 * ((level * 0.5) % 1);
  var sy = fy + 12;
  // 0: gözcü soğuk feneriyle tarar.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    final sweep = math.sin(time * 1.1) * 0.5;
    final lamp = const Offset(560, 196);
    c.drawPath(
      Path()
        ..moveTo(lamp.dx, lamp.dy)
        ..lineTo(
          lamp.dx - 260 * math.cos(sweep),
          lamp.dy + 160 + 80 * math.sin(sweep),
        )
        ..lineTo(
          lamp.dx - 200 * math.cos(sweep),
          lamp.dy + 200 + 60 * math.sin(sweep),
        )
        ..close(),
      _hole(0.2 * a0),
    );
    _tasvirKandilci(c, Offset(470, _gb + 12), 0.78, time, a0);
  }
  // 1: Hezarfen'in sandığı, içinde kartal kanatları.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    const chest = Offset(520, 238);
    final open = _span(u, 1.2, 1.6);
    _wings(
      c,
      chest + Offset(0, -10 - 30 * open),
      50 + 20 * open,
      0.1 + 0.3 * open,
      a1 * open,
    );
    c.drawRect(Rect.fromCenter(center: chest, width: 70, height: 26), _ink(a1));
    c.save();
    c.translate(chest.dx - 35, chest.dy - 13);
    c.rotate(-1.4 * open);
    c.drawRect(const Rect.fromLTWH(0, -6, 70, 6), _ink(a1));
    c.restore();
    _punchRow(
      c,
      chest + const Offset(-28, 4),
      chest + const Offset(28, 4),
      6,
      1.4,
      a1,
    );
  }
  // 2: külahın tepesinden boşluğa: Haliç aşağıda parlar.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawRect(Rect.fromLTWH(0, 0, 780, 58), _cloth(a2));
    c.drawPath(
      Path()
        ..moveTo(330, 58)
        ..lineTo(390, -10)
        ..lineTo(450, 58)
        ..close(),
      _ink(a2),
    );
    c.drawRect(
      Rect.fromLTWH(610, 300, 170, 14),
      _hole(0.4 * a2 * (0.8 + 0.2 * math.sin(time * 2))),
    );
    final fly = _span(u, 2.35, 2.9);
    if (fly > 0) {
      sx = 450 + fly * 260;
      sy = 60 + fly * 160;
      _wings(c, Offset(sx, sy - 70), 110, 0.5 + math.sin(time * 4) * 0.15, 1);
    }
  }
  _sayeAt(c, Offset(sx, sy), time, s: 1.3);
}

// ------------------------------------------------------------- Gökyolu

void _bSkyRoad(Canvas c, double time, double u, double n) {
  for (var i = 0; i < 7; i++) {
    final x = (i * 140.0 - time * 14) % 900 - 60;
    _P._cloud(c, x, 300 + (i % 3) * 22.0, 0.9 + (i % 2) * 0.3, 0.7);
  }
  final x = _walkX(u, n, 90, 640);
  final y = 190 + math.sin(time * 1.4) * 14;
  // 0: kargaların adaları, bulut kampı.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (final (ix, iy) in [(520.0, 110.0), (660.0, 170.0)]) {
      c.drawPath(
        Path()
          ..moveTo(ix - 50, iy)
          ..lineTo(ix + 50, iy)
          ..lineTo(ix + 10, iy + 50)
          ..lineTo(ix - 14, iy + 34)
          ..close(),
        _far(a0 * 2),
      );
    }
    for (var i = 0; i < 6; i++) {
      _P._bird(
        c,
        Offset(560 - (time * 50 + i * 60) % 500, 80 + i * 17.0),
        time,
        a0,
        i * 1.3,
      );
    }
    c.drawPath(
      Path()
        ..moveTo(160, 300)
        ..lineTo(200, 240)
        ..lineTo(240, 300)
        ..close(),
      _ink(a0),
    );
    c.drawCircle(const Offset(200, 236), 7, _hole(0.8 * a0));
  }
  // 1: şimşek ve gölgeden köprü.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final flash = math.pow(math.max(0, math.sin(time * 2.2)), 18).toDouble();
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _hole(0.35 * flash * a1));
    final bolt = Path()..moveTo(600, 0);
    for (var i = 1; i < 7; i++) {
      bolt.lineTo(600 + (i.isEven ? -20 : 18), i * 28.0);
    }
    c.drawPath(bolt, _stroke(_hole(a1 * (0.3 + 0.7 * flash)), 3));
    for (var i = 0; i < 16; i++) {
      final t = i / 15;
      final bx = 120 + t * 540;
      final by = 260 - math.sin(t * math.pi) * 60;
      c.drawRect(
        Rect.fromCenter(center: Offset(bx, by), width: 26, height: 8),
        _ink(a1 * 0.8),
      );
    }
  }
  // 2: Tulpar'ın yelesi, güneşin kapısı.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    const gate = Offset(660, 170);
    c.drawCircle(gate, 120, _hole(0.25 * a2));
    c.drawCircle(gate, 90, _stroke(_ink(a2), 12));
    for (var i = 0; i < 4; i++) {
      final ang = i * 1.6 + 0.4;
      c.drawLine(
        gate + Offset(math.cos(ang) * 80, math.sin(ang) * 80),
        gate + Offset(math.cos(ang + 0.2) * 98, math.sin(ang + 0.2) * 98),
        _stroke(_hole(a2), 2),
      );
    }
    final tx = 180 + _span(u, 2.05, 2.9) * 220;
    _cut(
      c,
      MythShapes.horse,
      Offset(tx, 150),
      100,
      a2 * 0.5,
      flip: true,
      deco: false,
    );
    _wings(c, Offset(tx + 4, 75), 60, 0.4 + math.sin(time * 3) * 0.2, a2 * 0.5);
  }
  _wings(c, Offset(x, y - 82), 92, 0.45 + math.sin(time * 3.2) * 0.18, 1);
  _sayeAt(c, Offset(x, y), time, s: 1.4);
}

// ------------------------------------------------------------- Kaf

void _feather(Canvas c, Offset at, double s, double a, double glow) {
  if (glow > 0) c.drawCircle(at, 34 * s, _hole(0.4 * glow * a));
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(-0.4);
  c.scale(s);
  c.drawPath(
    Path()
      ..moveTo(0, 30)
      ..quadraticBezierTo(-12, 0, 0, -32)
      ..quadraticBezierTo(12, 0, 0, 30)
      ..close(),
    _ink(a),
  );
  c.drawLine(
    const Offset(0, 36),
    const Offset(0, -28),
    _stroke(_hole(0.6 * a), 1.2),
  );
  c.drawCircle(const Offset(0, -12), 3.5, _hole(a));
  c.restore();
}

void _bQaf(Canvas c, double time, double u, double n) {
  _peaks(c, [
    (0, 230),
    (120, 120),
    (230, 190),
    (390, 40),
    (520, 170),
    (640, 90),
    (780, 200),
  ], _far(1));
  _floor(c, 0.9);
  final x = _walkX(u, n, 90, 620);
  // 0: zümrüt köprü ve gök karakolu.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    c.drawRect(Rect.fromLTWH(150, _gb - 6, 330, 8), _ink(a0));
    for (var i = 0; i < 12; i++) {
      c.drawLine(
        Offset(160 + i * 28.0, _gb - 6),
        Offset(160 + i * 28.0, _gb - 40),
        _stroke(_ink(a0), 2),
      );
    }
    c.drawLine(
      Offset(150, _gb - 40),
      Offset(480, _gb - 40),
      _stroke(_ink(a0), 2),
    );
    c.drawRect(Rect.fromLTWH(600, 170, 46, _gb - 170), _ink(a0));
    c.drawPath(
      Path()
        ..moveTo(590, 172)
        ..lineTo(623, 130)
        ..lineTo(656, 172)
        ..close(),
      _ink(a0),
    );
    c.drawCircle(const Offset(623, 196), 9, _hole(0.8 * a0));
  }
  // 1: üç tüy; Sâye yaklaştıkça yanar.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (var i = 0; i < 3; i++) {
      _feather(
        c,
        Offset(250 + i * 150.0, 220 - (i % 2) * 40),
        1.1,
        a1,
        _span(u, 1.15 + i * 0.22, 1.3 + i * 0.22),
      );
    }
  }
  // 2: ayna salonunun kapısı açılır.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    final open = _span(u, 2.15, 2.7);
    final door = Path()
      ..moveTo(620, _gb)
      ..lineTo(620, 170)
      ..quadraticBezierTo(680, 100, 740, 170)
      ..lineTo(740, _gb)
      ..close();
    c.drawPath(door, _ink(a2));
    c.save();
    c.clipPath(door);
    c.drawRect(
      Rect.fromLTWH(680 - 60 * open, 100, 120 * open, 260),
      _hole(0.9 * a2),
    );
    c.restore();
  }
  _sayeAt(c, Offset(x, _gb + 12), time);
}

// ------------------------------------------------------------- Ağrı

void _bAgri(Canvas c, double time, double u, double n) {
  final a0 = _agWin(u, 0, 1, n);
  if (a0 > 0) _bAgriRopes(c, time, u, a0);
  final a1 = _agWin(u, 1, 2, n);
  if (a1 > 0) _bAgriGate(c, time, u, a1);
  final a2 = _agWin(u, 2, 3, n);
  if (a2 > 0) _bAgriIceCave(c, time, u, a2);
}

/// 0: tipide iplere tutunup yamacı tırmanır; terk edilmiş ağıla sığınır.
void _bAgriRopes(Canvas c, double time, double u, double a) {
  double slope(double x) => x < 560 ? 382 - x * 182 / 560 : 200;
  _peaks(c, [(0, 200), (220, 40), (420, 180)], _far(0.7 * a));
  c.drawPath(
    Path()
      ..moveTo(0, 400)
      ..lineTo(0, slope(0))
      ..lineTo(560, 200)
      ..lineTo(780, 200)
      ..lineTo(780, 400)
      ..close(),
    _ink(a),
  );
  // Kazıklar ve ip: yamaç boyunca.
  final rope = Path();
  for (var i = 0; i <= 7; i++) {
    final x = 30 + i * 76.0;
    final y = slope(x);
    c.drawLine(Offset(x, y), Offset(x - 3, y - 46), _stroke(_ink(a), 4));
    if (i == 0) {
      rope.moveTo(x - 3, y - 44);
    } else {
      final px = x - 76;
      rope.quadraticBezierTo(px + 36, (slope(px) + y) / 2 - 26, x - 3, y - 44);
    }
  }
  c.drawPath(rope, _stroke(_ink(a), 2.4));
  // Ağıl: taş duvar ve sundurma.
  c.drawRect(const Rect.fromLTWH(600, 166, 170, 34), _ink(a));
  for (var i = 0; i < 9; i++) {
    c.drawCircle(Offset(612 + i * 19.0, 176 + (i % 2) * 10), 2, _hole(0.5 * a));
  }
  c.drawPath(
    Path()
      ..moveTo(650, 166)
      ..lineTo(650, 120)
      ..lineTo(700, 100)
      ..lineTo(760, 120)
      ..lineTo(760, 166)
      ..close(),
    _ink(a),
  );
  final inside = _span(u, 0.72, 0.85);
  c.drawRect(
    const Rect.fromLTWH(676, 128, 34, 38),
    _hole((0.15 + 0.55 * inside) * a),
  );
  // Sâye: ipe tutunarak tırmanır, ağılın kapısında ateşböceklerini
  // göğsüne bastırır.
  final x = _agLerp(40, 620, _span(u, 0.04, 0.72));
  final hug = _span(u, 0.74, 0.85);
  _agSaye(
    c,
    Offset(x, slope(x) + 4),
    1.25,
    time,
    a,
    rot: x < 560 ? -0.12 : 0,
    jar: 1 - hug,
    seed: 1,
  );
  if (hug > 0) {
    final chest = Offset(x + 6, slope(x) + 4 - 44 * 1.25);
    c.drawCircle(
      chest,
      26,
      Paint()
        ..shader = ui.Gradient.radial(chest, 26, [
          const Color(0xFFFFF0C0).withValues(alpha: 0.75 * a * hug),
          const Color(0x00FFF0C0),
        ]),
    );
    c.drawCircle(chest, 5, _hole(a * hug));
  }
  // Tipi.
  final wind = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFF8EC).withValues(alpha: 0.65 * a);
  for (var i = 0; i < 60; i++) {
    final wx = (i * 71.0 + time * 360) % 860 - 40;
    final wy = (i * 37.0 + time * 50) % 380;
    c.drawLine(Offset(wx, wy), Offset(wx - 20, wy - 4), wind);
  }
}

/// 1: Akori'nin asmaları; manastırın kapısında Ayaz Ata sorar, sonra kenara
/// çekilir.
void _bAgriGate(Canvas c, double time, double u, double a) {
  _peaks(c, [(0, 260), (180, 90), (380, 250)], _far(0.6 * a));
  _floor(c, a);
  // Asmalar: çardak ve salkımlar.
  final vine = _stroke(_ink(a), 3);
  c.drawLine(const Offset(30, _gb - 92), const Offset(250, _gb - 92), vine);
  for (var i = 0; i < 4; i++) {
    final vx = 40 + i * 64.0;
    c.drawPath(
      Path()
        ..moveTo(vx, _gb)
        ..quadraticBezierTo(vx - 10, _gb - 40, vx + 6, _gb - 92),
      vine,
    );
    for (var j = 0; j < 6; j++) {
      c.drawCircle(
        Offset(
          vx + 22 + (j % 3) * 5.0 - (j ~/ 3) * 2,
          _gb - 80 + (j ~/ 3) * 7.0 + (j % 3) * 2,
        ),
        3.6,
        _ink(a),
      );
    }
  }
  // Yapraklar çardak boyunca.
  for (var i = 0; i < 12; i++) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(36 + i * 19.0, _gb - 96 - (i % 2) * 6),
        width: 22,
        height: 11,
      ),
      _ink(a),
    );
  }
  // Manastır: taş gövde, kubbe kasnağı, sivri külah, haç; kemerli kapı.
  // Uzakta (soluk): kapıdaki Ayaz Ata önünde seçik kalır.
  final ink = _ink(0.55 * a);
  c.drawRect(const Rect.fromLTWH(440, _gb - 130, 200, 130), ink);
  c.drawRect(const Rect.fromLTWH(505, _gb - 180, 70, 50), ink);
  c.drawPath(
    Path()
      ..moveTo(498, _gb - 180)
      ..lineTo(540, _gb - 232)
      ..lineTo(582, _gb - 180)
      ..close(),
    ink,
  );
  c.drawLine(
    const Offset(540, _gb - 232),
    const Offset(540, _gb - 256),
    _stroke(_ink(0.55 * a), 3),
  );
  c.drawLine(
    const Offset(530, _gb - 247),
    const Offset(550, _gb - 247),
    _stroke(_ink(0.55 * a), 3),
  );
  for (var i = 0; i < 3; i++) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(516 + i * 18.0, _gb - 172, 8, 22),
        const Radius.circular(4),
      ),
      _hole(0.6 * a),
    );
  }
  final open = _span(u, 1.72, 1.95);
  final door = Path()
    ..moveTo(515, _gb)
    ..lineTo(515, _gb - 62)
    ..quadraticBezierTo(540, _gb - 96, 565, _gb - 62)
    ..lineTo(565, _gb)
    ..close();
  c.drawPath(door, _hole((0.55 + 0.4 * open) * a));
  _snowfall(c, time, a, wind: 30);
  // Ayaz Ata kapıda; konuşup kenara çekilir.
  final ax = _agLerp(540, 690, _span(u, 1.72, 1.95));
  _agAyazAta(
    c,
    Offset(ax, _gb + 6),
    190,
    time,
    a,
    flip: true,
    hand: _shown(u, 1.25, 1.55, 0.06),
  );
  // Sâye cevap verir, sonra kapıya yürür.
  final sx = _agLerp(300, 420, _span(u, 1.85, 1.98));
  _agSaye(
    c,
    Offset(sx, _gb + 6),
    1.6,
    time,
    a,
    raise: 0.4 * _shown(u, 1.55, 1.72, 0.05),
    seed: 2,
  );
}

/// 2: buz mağarasının dibinde, buzun ardında kapkara, kocaman bir gemi.
void _bAgriIceCave(Canvas c, double time, double u, double a) {
  final ice = Path()
    ..moveTo(300, _gb)
    ..lineTo(290, 150)
    ..quadraticBezierTo(320, 70, 470, 66)
    ..quadraticBezierTo(700, 70, 740, 160)
    ..lineTo(750, _gb)
    ..close();
  c.drawPath(
    ice,
    Paint()..color = const Color(0xFFFFF4E0).withValues(alpha: 0.55 * a),
  );
  // Buzun ardında gemi.
  final reveal = _span(u, 2.15, 2.6);
  c.save();
  c.clipPath(ice);
  c.translate(520, 250);
  c.scale(1.65);
  _arkShape(_ink(0.85 * a * (0.45 + 0.55 * reveal)), _hole(0), 0);
  c.restore();
  // Buzun çatlakları.
  final crack = _stroke(_hole(0.7 * a), 1.4);
  c.drawLine(const Offset(330, 120), const Offset(380, 200), crack);
  c.drawLine(const Offset(380, 200), const Offset(360, 260), crack);
  c.drawLine(const Offset(690, 110), const Offset(650, 190), crack);
  // Mağaranın kayası: çerçeve ve sarkıtlar.
  c.drawPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(-10, -10, 800, 420))
      ..moveTo(40, _gb)
      ..lineTo(60, 120)
      ..quadraticBezierTo(140, 30, 400, 34)
      ..quadraticBezierTo(700, 30, 760, 110)
      ..lineTo(770, _gb)
      ..close(),
    _ink(a),
  );
  for (var i = 0; i < 14; i++) {
    final x = 90 + i * 48.0;
    final l = 26 + (i * 37 % 5) * 9.0;
    final top = 40 + ((x - 400).abs() / 400) * 40;
    c.drawPath(
      Path()
        ..moveTo(x - 9, top - 4)
        ..lineTo(x, top + l)
        ..lineTo(x + 9, top - 4)
        ..close(),
      _ink(a),
    );
  }
  _floor(c, a);
  _agSaye(c, const Offset(180, _gb + 6), 1.7, time, a, seed: 3);
}

// ------------------------------------------------------------- Gemi

void _bArk(Canvas c, double time, double u, double n) {
  final a0 = _agWin(u, 0, 1, n);
  if (a0 > 0) _bArkLocks(c, time, u, a0);
  final a1 = _agWin(u, 1, 2, n);
  if (a1 > 0) _bArkWell(c, time, u, a1);
  final a2 = _agWin(u, 2, 3, n);
  if (a2 > 0) _bArkDeck(c, time, u, a2);
}

/// Sevinç: kavuşan eşlerin çevresinde ışık kıvılcımları.
void _bJoy(Canvas c, Offset at, double time, double a) {
  if (a <= 0.01) return;
  final p = _hole(0.9 * a);
  for (var i = 0; i < 9; i++) {
    final k = (time * 0.8 + i / 9) % 1;
    final ang = i * 0.7;
    c.drawCircle(
      at + Offset(math.cos(ang) * (20 + k * 50), -k * 70 + math.sin(ang) * 10),
      2.4 * (1 - k) + 0.6,
      p,
    );
  }
}

/// 0: Sâye ambar kilitlerini açar; aslanın gölgesi aslanına, kuşun gölgesi
/// kuşuna koşar.
void _bArkLocks(Canvas c, double time, double u, double a) {
  _agHold(c, a);
  // Sol ambar: aslanın gölgesi; sağ ambar: kuşun gölgesi.
  const left = Rect.fromLTWH(30, 150, 180, 200);
  const right = Rect.fromLTWH(600, 150, 170, 200);
  final open1 = _span(u, 0.18, 0.3);
  final open2 = _span(u, 0.62, 0.72);
  for (final r in [left, right]) {
    c.drawRect(r, _ink(0.22 * a));
  }
  // Aslan bekler; gölgesi koşup ona kavuşur.
  const lion = Offset(410, _gb);
  _agBeast(c, MythShapes.lion, lion, 90, a, flip: true);
  final run1 = _span(u, 0.3, 0.5);
  if (run1 < 1) {
    _agBeast(
      c,
      MythShapes.lion,
      Offset(_agLerp(120, lion.dx, run1), _gb),
      90,
      a * (1 - _span(u, 0.45, 0.52)),
      flip: true,
      shadow: true,
    );
  }
  _bJoy(c, lion.translate(-20, -70), time, a * _shown(u, 0.48, 0.95, 0.08));
  // Kuş tünekte bekler; gölgesi uçup ona kavuşur.
  c.drawLine(
    const Offset(470, _gb),
    const Offset(470, 250),
    _stroke(_ink(a), 5),
  );
  c.drawLine(
    const Offset(440, 250),
    const Offset(500, 250),
    _stroke(_ink(a), 5),
  );
  const bird = Offset(470, 250);
  _cut(c, MythShapes.birdFlap, bird, 46, a, deco: false);
  final run2 = _span(u, 0.72, 0.9);
  if (run2 < 1) {
    final bp = Offset.lerp(
      const Offset(690, 300),
      bird,
      run2,
    )!.translate(0, -math.sin(run2 * math.pi) * 60);
    c.save();
    c.translate(bp.dx, bp.dy);
    c.scale(0.46);
    c.drawPath(
      MythShapes.birdFlap,
      _ink(0.38 * a * (1 - _span(u, 0.86, 0.92))),
    );
    c.restore();
  }
  _bJoy(c, bird.translate(0, -30), time, a * _span(u, 0.88, 0.95));
  // Ambar kapıları: parmaklıklar kalkar; asma kilit düşer.
  for (final (r, open) in [(left, open1), (right, open2)]) {
    for (var b = 0; b < 7; b++) {
      c.drawRect(
        Rect.fromLTWH(
          r.left + 6 + b * r.width / 7,
          r.top - open * 120,
          6,
          r.height,
        ),
        _ink(a),
      );
    }
    c.drawRect(
      Rect.fromLTWH(r.left - 6, r.top - 12, r.width + 12, 12),
      _ink(a),
    );
    final lockAt = Offset(r.center.dx, r.center.dy + open * 140);
    if (open < 1) {
      c.drawRect(
        Rect.fromCenter(center: lockAt, width: 22, height: 18),
        _ink(a),
      );
      c.drawArc(
        Rect.fromCenter(
          center: lockAt.translate(0, -12 - open * 6),
          width: 14,
          height: 14,
        ),
        math.pi,
        math.pi,
        false,
        _stroke(_ink(a), 3),
      );
      c.drawCircle(lockAt, 2.4, _hole(a));
    }
  }
  // Sâye: önce sol kapıyı, sonra sağ kapıyı açar.
  final walk = _span(u, 0.5, 0.62);
  final sx = _agLerp(232, 562, walk);
  _agSaye(
    c,
    Offset(sx, _gb + 6),
    1.5,
    time,
    a,
    flip: walk < 0.02,
    raise:
        0.4 * math.max(_shown(u, 0.1, 0.3, 0.05), _shown(u, 0.6, 0.74, 0.05)),
    seed: 6,
  );
}

/// 1: kuyunun dibinde Ak Ana gülümser; su yükselir, Sâye'yi güverteye taşır.
void _bArkWell(Canvas c, double time, double u, double a) {
  _agHold(c, a);
  final level = _agLerp(330, 150, _span(u, 1.2, 1.85));
  // Ak Ana suyun içinde, ışıktan: başı ve omuzları suyun üstünde.
  c.save();
  c.clipRect(const Rect.fromLTWH(300, 0, 180, _gb));
  _agAkAna(c, Offset(445, level + 150), 190, time, a);
  c.restore();
  // Kuyunun suyu (yarı saydam).
  final wpath = Path()..moveTo(300, _gb);
  for (var x = 300.0; x <= 480; x += 10) {
    wpath.lineTo(x, level + math.sin(x / 18 + time * 2.4) * 3);
  }
  wpath
    ..lineTo(480, _gb)
    ..close();
  c.drawPath(wpath, _ink(0.18 * a));
  c.drawPath(wpath, _stroke(_hole(0.8 * a), 2));
  // Taş kuyu duvarları.
  for (final x in [250.0, 480.0]) {
    c.drawRect(Rect.fromLTWH(x, 120, 50, _gb - 120), _ink(a));
    for (var i = 0; i < 9; i++) {
      c.drawLine(
        Offset(x, 140 + i * 24.0),
        Offset(x + 50, 140 + i * 24.0),
        _stroke(_hole(0.35 * a), 1.2),
      );
      c.drawLine(
        Offset(x + (i.isEven ? 20 : 34), 140 + i * 24.0),
        Offset(x + (i.isEven ? 20 : 34), 164 + i * 24.0),
        _stroke(_hole(0.35 * a), 1.2),
      );
    }
  }
  // Güverte ağzı.
  c.drawRect(const Rect.fromLTWH(0, 108, 300, 14), _ink(a));
  c.drawRect(const Rect.fromLTWH(480, 108, 300, 14), _ink(a));
  // Sâye suyun üstünde yükselir.
  _agSaye(c, Offset(372, level + 2), 1.25, time, a, seed: 7);
}

/// 2: güverte boş; sönmeyen ışığın yeri boş. Sâye yumruklarını sıkar.
void _bArkDeck(Canvas c, double time, double u, double a) {
  // Mağaranın loşluğu, uzakta giden fenerler.
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.2 * a));
  final away = _span(u, 2.0, 2.9);
  for (var i = 0; i < 3; i++) {
    final p = Offset(640 + away * 110 + i * 22, 150 + i * 6.0);
    c.drawCircle(p, 3, _hole(a * (1 - away)));
  }
  // Güverte tahtaları.
  c.drawRect(Rect.fromLTWH(0, _gb, 780, 60), _ink(a));
  for (var i = 0; i < 14; i++) {
    c.drawLine(
      Offset(i * 60.0, _gb + 4),
      Offset(i * 60.0, _gb + 50),
      _stroke(_hole(0.25 * a), 1.2),
    );
  }
  c.drawLine(
    const Offset(0, _gb),
    const Offset(780, _gb),
    _stroke(_hole(0.4 * a), 1.4),
  );
  // Işığın kaidesi: ayaklı, boş kandillik; kopuk zinciri sallanır.
  c.drawRect(const Rect.fromLTWH(562, 196, 12, _gb - 196), _ink(a));
  c.drawPath(
    Path()
      ..moveTo(540, _gb)
      ..lineTo(568, _gb - 30)
      ..lineTo(596, _gb)
      ..close(),
    _ink(a),
  );
  c.drawPath(
    Path()
      ..moveTo(530, 180)
      ..quadraticBezierTo(568, 220, 606, 180)
      ..lineTo(596, 176)
      ..quadraticBezierTo(568, 204, 540, 176)
      ..close(),
    _ink(a),
  );
  final sw = math.sin(time * 1.8) * 0.25;
  c.save();
  c.translate(600, 182);
  c.rotate(sw);
  for (var i = 0; i < 4; i++) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, 8 + i * 10.0),
        width: i.isEven ? 7 : 11,
        height: i.isEven ? 11 : 7,
      ),
      _stroke(_ink(a), 2.4),
    );
  }
  c.drawArc(
    Rect.fromCenter(center: const Offset(3, 50), width: 12, height: 12),
    -0.3,
    3.6,
    false,
    _stroke(_ink(a), 2.4),
  );
  c.restore();
  // Işığın bıraktığı soluk iz.
  c.drawCircle(const Offset(568, 160), 22, _stroke(_hole(0.35 * a), 1.4));
  final fist = _span(u, 2.5, 2.65);
  _agSaye(
    c,
    const Offset(330, _gb + 6),
    2.1,
    time,
    a,
    fist: fist,
    jar: 0.8,
    seed: 8,
  );
}

// ------------------------------------------------------------- Nemrut

void _bNemrut(Canvas c, double time, double u, double n) {
  _peaks(c, [(420, 330), (600, 120), (780, 330)], _far(1));
  // Başsız beş tanrı (perdedeki gibi beş): terasta, uzakta; başları
  // dibinde karda.
  for (var i = 0; i < 5; i++) {
    final x = 90 + i * 150.0;
    _agStatue(c, x, 120, 1, headless: true, alpha: 0.5, y: _gb - 4);
    _agStoneHead(
      c,
      Offset(x + 52, _gb - 2),
      50,
      1,
      rot: -0.5 + i * 0.25,
      flip: i.isOdd,
      kind: i % 3,
      alpha: 0.5,
    );
  }
  _floor(c, 0.9);
  final a0 = _agWin(u, 0, 1, n);
  if (a0 > 0) _bNemrutCracks(c, time, u, a0);
  final a1 = _agWin(u, 1, 2, n);
  if (a1 > 0) _bNemrutEagle(c, time, u, a1);
}

/// 0: başsız tanrıların arasından geçer; ayağının altında yer yarılır,
/// sonra kapanır (Sâye yarıkların üstünden sıçrar).
void _bNemrutCracks(Canvas c, double time, double u, double a) {
  final x = _agLerp(50, 730, _span(u, 0.04, 0.95));
  var lift = 0.0;
  for (final (rx, ph) in [(250.0, 0.0), (480.0, 1.9)]) {
    final w = 4 + 12 * math.max(0, math.sin(time * 2.6 + ph));
    final crack = Path()..moveTo(rx - w, _gb);
    for (var i = 1; i < 5; i++) {
      crack.lineTo(rx + (i.isEven ? -w : w) * 0.6, _gb + i * 12.0);
    }
    crack
      ..lineTo(rx + w, _gb)
      ..close();
    c.drawPath(crack, _hole(0.8 * a));
    final d = x - rx;
    if (d.abs() < 50) {
      lift = math.max(lift, math.cos(d / 50 * math.pi / 2) * 46);
    }
  }
  _agSaye(
    c,
    Offset(x, _gb + 6 - lift),
    1.5,
    time,
    a,
    rot: lift > 4 ? 0.15 : 0,
    seed: 10,
  );
}

/// 1: taş kartalın gözünden süzülür; taşların arasındaki gizli yoldan doğu
/// terasına çıkar.
void _bNemrutEagle(Canvas c, double time, double u, double a) {
  final ink = _ink(a);
  // Kaide ve kartalın gövdesi (kanatları kapalı).
  c.drawRect(const Rect.fromLTWH(330, _gb - 60, 150, 60), ink);
  _punchRow(
    c,
    const Offset(340, _gb - 30),
    const Offset(470, _gb - 30),
    8,
    2,
    a,
  );
  c.drawPath(
    Path()
      ..moveTo(300, _gb - 60)
      ..quadraticBezierTo(320, _gb - 190, 420, _gb - 200)
      ..quadraticBezierTo(470, _gb - 196, 476, _gb - 150)
      ..lineTo(470, _gb - 60)
      ..close(),
    ink,
  );
  for (var i = 0; i < 4; i++) {
    c.drawArc(
      Rect.fromLTWH(330 + i * 26.0, _gb - 170 + i * 20.0, 70, 50),
      0.4,
      2.0,
      false,
      _stroke(_hole(0.35 * a), 1.5),
    );
  }
  // Baş: kıvrık gaga, iri göz (içinden geçilecek delik).
  const head = Offset(470, _gb - 230);
  c.drawCircle(head, 46, ink);
  c.drawPath(
    Path()
      ..moveTo(500, _gb - 256)
      ..quadraticBezierTo(552, _gb - 252, 548, _gb - 208)
      ..quadraticBezierTo(536, _gb - 222, 506, _gb - 214)
      ..close(),
    ink,
  );
  const eye = Offset(478, _gb - 240);
  c.drawCircle(eye, 16, _hole(0.95 * a));
  // Gizli yol: taşların arasında basamaklar, doğu terasına.
  for (var i = 0; i < 6; i++) {
    c.drawRect(
      Rect.fromLTWH(520 + i * 42.0, _gb - 20 - i * 24.0, 46, 20 + i * 24.0),
      _ink(0.85 * a),
    );
  }
  final top = const Offset(760, 200);
  c.drawCircle(
    top,
    60,
    Paint()
      ..shader = ui.Gradient.radial(top, 60, [
        const Color(0xFFFFF0C8).withValues(alpha: 0.7 * a),
        const Color(0x00FFF0C8),
      ]),
  );
  // Sâye: kartala tırmanır, küçülüp gözünden geçer, ardında basamaklara
  // iner ve terasa çıkar.
  final toEye = _span(u, 1.05, 1.4);
  final through = _span(u, 1.4, 1.55);
  final climb = _span(u, 1.6, 1.95);
  Offset p;
  double s;
  double sa = a;
  if (through <= 0) {
    p = Offset.lerp(
      const Offset(230, _gb + 6),
      eye + const Offset(-6, 12),
      toEye,
    )!;
    s = _agLerp(1.5, 0.28, toEye);
  } else if (climb <= 0) {
    p = Offset.lerp(
      eye + const Offset(-6, 12),
      eye + const Offset(64, -26),
      through,
    )!;
    s = 0.28 + 0.4 * through;
    sa = a * (through < 0.3 ? 0.4 : 1);
  } else {
    final i = climb * 5;
    final step = i.floor().clamp(0, 5);
    p = Offset(
      _agLerp(560, 740, climb),
      _gb - 20 - step * 24.0 - math.sin((i - step) * math.pi) * 6 + 6,
    );
    s = _agLerp(0.68, 1.0, climb);
  }
  _agSaye(c, p, s, time, sa, seed: 14);
}

// ------------------------------------------------------------- Gün doğumu

void _bSunrise(Canvas c, double time, double u, double n) {
  final a0 = _agWin(u, 0, 1, n);
  if (a0 > 0) _agGiantWalk(c, time, u, a0);
  final a1 = _agWin(u, 1, 2, n);
  if (a1 > 0) _agFirstLight(c, time, u, a1);
}

// ------------------------------------------------------------- Kar Yolu

void _pine(Canvas c, double x, double h, Paint p) {
  for (var i = 0; i < 3; i++) {
    final y = _gb - h * (0.25 + i * 0.28);
    final w = h * (0.34 - i * 0.08);
    c.drawPath(
      Path()
        ..moveTo(x - w, y + h * 0.2)
        ..lineTo(x, y - h * 0.22)
        ..lineTo(x + w, y + h * 0.2)
        ..close(),
      p,
    );
  }
  c.drawRect(Rect.fromLTWH(x - 3, _gb - h * 0.12, 6, h * 0.12), p);
}

void _bSnowRoad(Canvas c, double time, double u, double n) {
  for (var i = 0; i < 9; i++) {
    _pine(c, 30 + i * 92.0, 150 + (i % 3) * 30, _far(1));
  }
  _floor(c, 0.9);
  final x = _walkX(u, n, 60, 560);
  final wx = x + 150;
  // 0: Gökbörü önde; ayak izleri.
  final a0 = _heroA(u, 0);
  for (var i = 0; i < 14; i++) {
    final px = wx - 30 - i * 26.0;
    if (px < 0) break;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(px, _gb + 3 + (i % 2) * 4),
        width: 7,
        height: 4,
      ),
      _ink(0.5),
    );
  }
  if (a0 > 0) {
    for (var i = 0; i < 4; i++) {
      _pine(c, 90 + i * 210.0, 230, _ink(a0));
    }
  }
  // 1: donmuş göl, sönmüş han, ejderin eteği.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    _ejder(c, const Offset(600, 120), 0.8, time, 0.5 * a1, dir: -1);
    c.drawOval(
      Rect.fromCenter(center: Offset(260, _gb + 4), width: 300, height: 16),
      _hole(0.4 * a1),
    );
    c.drawRect(Rect.fromLTWH(470, _gb - 80, 120, 80), _ink(a1));
    c.drawPath(
      Path()
        ..moveTo(460, _gb - 78)
        ..lineTo(530, _gb - 120)
        ..lineTo(600, _gb - 78)
        ..close(),
      _ink(a1),
    );
    c.drawArc(
      Rect.fromLTWH(512, _gb - 46, 36, 70),
      math.pi,
      math.pi,
      true,
      _ink(a1),
    );
    c.drawRect(Rect.fromLTWH(560, _gb - 140, 12, 30), _ink(a1));
  }
  _tasvirBozkurt(c, Offset(wx, _gb + 8), 80, time, 1);
  _snowfall(c, time, 1);
  _sayeAt(c, Offset(x, _gb + 12), time);
}

// ------------------------------------------------------------- Palandöken

void _bSki(Canvas c, double time, double u, double n) {
  double slope(double x) => 150 + x * 0.25 + 18 * math.sin(x / 90);
  _peaks(
    c,
    [(0, 140), (160, 60), (300, 120), (420, 40), (600, 150), (780, 130)],
    _far(1),
    base: 360,
  );
  final hill = Path()..moveTo(0, slope(0));
  for (var x = 0.0; x <= 780; x += 20) {
    hill.lineTo(x, slope(x));
  }
  hill
    ..lineTo(780, 400)
    ..lineTo(0, 400)
    ..close();
  c.drawPath(hill, _ink(0.9));
  final p = _span(u, 0.08, n - 0.1);
  var x = 60 + p * 640;
  var y = slope(x);
  // 0: çoban kulübesi, kandil balonları.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    c.drawRect(Rect.fromLTWH(30, slope(50) - 40, 50, 42), _ink(a0));
    c.drawPath(
      Path()
        ..moveTo(24, slope(50) - 38)
        ..lineTo(55, slope(50) - 66)
        ..lineTo(86, slope(50) - 38)
        ..close(),
      _ink(a0),
    );
    for (var i = 0; i < 4; i++) {
      final b = Offset(
        240 + i * 120.0,
        60 + (i % 2) * 30 + math.sin(time + i) * 8,
      );
      c.drawCircle(b, 16, _ink(a0));
      c.drawCircle(b, 8, _hole(0.7 * a0));
      c.drawLine(
        b + const Offset(-8, 14),
        b + const Offset(-5, 32),
        _stroke(_ink(a0), 1),
      );
      c.drawLine(
        b + const Offset(8, 14),
        b + const Offset(5, 32),
        _stroke(_ink(a0), 1),
      );
      c.drawRect(
        Rect.fromCenter(center: b + const Offset(0, 36), width: 12, height: 8),
        _ink(a0),
      );
    }
  }
  // 1: ejderin sıçrayışı, uzakta Erzurum.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (var i = 0; i < 6; i++) {
      final bx = 620 + i * 26.0;
      c.drawRect(Rect.fromLTWH(bx, 330 - (i % 3) * 8, 20, 40), _far(a1 * 2));
      c.drawCircle(Offset(bx + 10, 330 - (i % 3) * 8), 10, _far(a1 * 2));
    }
    c.drawRect(const Rect.fromLTWH(700, 270, 6, 60), _far(a1 * 2));
    final air = _span(u, 1.35, 1.75) * (1 - _span(u, 1.75, 1.85));
    y -= math.sin(air * math.pi) * 70;
  }
  final ang = math.atan(0.25 + 0.2 * math.cos(x / 90));
  c.save();
  c.translate(x, y);
  c.rotate(ang);
  c.drawRect(const Rect.fromLTWH(-34, -4, 68, 6), _ink(1));
  c.restore();
  x += 0;
  _sayeAt(c, Offset(x, y - 2), time, s: 1.3, rot: ang);
}

// ------------------------------------------------------------- Çığ

void _bAvalanche(Canvas c, double time, double u, double n) {
  _peaks(c, [(0, 120), (200, 40), (380, 140), (560, 70), (780, 160)], _far(1));
  final a0 = _heroA(u, 0) + _heroA(u, 1);
  _ejder(
    c,
    const Offset(170, 120),
    0.9,
    time,
    a0.clamp(0, 1) * 0.8,
    awake: true,
  );
  _floor(c, 0.9);
  final x = _walkX(u, n, 160, 600);
  final front = x - 140 + math.sin(time * 3) * 8;
  final shelter = _span(u, 1.5, 1.8);
  // 1: kırık sırt ve sığınak.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    c.drawPath(
      Path()
        ..moveTo(560, _gb)
        ..lineTo(560, 250)
        ..quadraticBezierTo(650, 190, 740, 250)
        ..lineTo(740, _gb)
        ..close(),
      _ink(a1),
    );
    c.drawArc(
      Rect.fromLTWH(600, _gb - 70, 80, 140),
      math.pi,
      math.pi,
      true,
      _hole(0.35 * a1),
    );
  }
  // Çığın beyaz nefesi: Sâye'nin ardından akar; sığınağın üstünden geçer.
  final wave = Path()..moveTo(-20, 400);
  final reach = shelter > 0 ? front + shelter * 400 : front;
  for (var i = 0; i <= 12; i++) {
    final t = i / 12;
    final wy = _gb + 20 - 260 * t;
    wave.lineTo(reach - t * 120 + math.sin(time * 4 + i) * 14, wy);
  }
  wave
    ..lineTo(-20, 60)
    ..close();
  c.save();
  if (shelter > 0) {
    c.clipRect(
      Rect.fromLTWH(0, 0, 780, 250 - 40 * shelter + 140 * (1 - shelter)),
    );
  }
  c.drawPath(wave, _hole(0.55));
  c.restore();
  final wx = x + 120;
  if (shelter < 1) {
    _tasvirBozkurt(c, Offset(wx, _gb + 8), 80, time, 1 - shelter);
  }
  _sayeAt(c, Offset(x, _gb + 12), time, a: 1 - 0.5 * shelter);
}

// ------------------------------------------------------------- Peri bacaları

void _chimney(
  Canvas c,
  double x,
  double h,
  double w,
  Paint p, {
  double hole = 0,
}) {
  c.drawPath(
    Path()
      ..moveTo(x - w, _gb)
      ..quadraticBezierTo(x - w * 0.4, _gb - h * 0.6, x - w * 0.3, _gb - h)
      ..lineTo(x + w * 0.3, _gb - h)
      ..quadraticBezierTo(x + w * 0.4, _gb - h * 0.6, x + w, _gb)
      ..close(),
    p,
  );
  c.drawOval(
    Rect.fromCenter(center: Offset(x, _gb - h - 6), width: w * 1.1, height: 20),
    p,
  );
  if (hole > 0) {
    for (var i = 0; i < 3; i++) {
      c.drawRect(
        Rect.fromLTWH(x - 5 + (i - 1) * 12.0, _gb - h * 0.5 + i * 14, 7, 10),
        _hole(hole),
      );
    }
  }
}

void _bFairy(Canvas c, double time, double u, double n) {
  for (var i = 0; i < 7; i++) {
    _chimney(c, 40 + i * 120.0, 160 + (i % 3) * 40, 40, _far(1));
  }
  _floor(c, 0.9);
  var x = _walkX(u, n, 60, 600);
  var y = _gb + 12;
  // 0: güvercinlikler, kaya kiliseleri, perilerin dansı.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (var i = 0; i < 3; i++) {
      final cx = 200 + i * 200.0;
      _chimney(c, cx, 200 + i * 20.0, 50, _ink(a0), hole: 0.5 * a0);
      final top = Offset(cx, _gb - 230 - i * 20.0);
      for (var f = 0; f < 2; f++) {
        _fairy(
          c,
          top +
              Offset(
                math.cos(time * 1.6 + f * math.pi) * 34,
                -16 + math.sin(time * 1.6 + f * math.pi) * 8,
              ),
          time,
          a0,
          i * 2.0 + f,
        );
      }
    }
  }
  // 1: Albastı; Sâye demirin ardında.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final back = _span(u, 1.45, 1.8);
    c.save();
    c.translate(560 + back * 120, _gb + 12);
    c.scale(-2.3, 2.3);
    c.drawPath(MythFigures.albastiSilhouette, _ink(a1));
    c.restore();
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(430 + i * 14.0, _gb),
        Offset(430 + i * 14.0, _gb - 120),
        _stroke(_ink(a1), 4),
      );
    }
    c.drawLine(
      Offset(424, _gb - 116),
      Offset(492, _gb - 116),
      _stroke(_ink(a1), 5),
    );
    c.drawLine(
      Offset(424, _gb - 60),
      Offset(492, _gb - 60),
      _stroke(_ink(a1), 5),
    );
    if (u > 1 && u < 2) x = math.min(x, 400);
  }
  // 2: Uçhisar'ın tepesi; ay doğar.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawCircle(
      Offset(640, 140 - 40 * _span(u, 2.05, 2.8)),
      26,
      _hole(0.8 * a2),
    );
    c.drawPath(
      Path()
        ..moveTo(360, _gb)
        ..lineTo(400, 230)
        ..lineTo(450, 200)
        ..lineTo(520, 214)
        ..lineTo(560, _gb)
        ..close(),
      _ink(a2),
    );
    for (var i = 0; i < 6; i++) {
      c.drawRect(
        Rect.fromLTWH(410 + (i % 3) * 36.0, 250 + (i ~/ 3) * 40.0, 10, 14),
        _hole(0.4 * a2),
      );
    }
    final climb = _span(u, 2.1, 2.7);
    if (climb > 0) {
      x = 420 + climb * 50;
      y = _gb + 12 - climb * 150;
    }
  }
  _sayeAt(c, Offset(x, y), time);
}

// ------------------------------------------------------------- Derinkuyu

void _bDerinkuyu(Canvas c, double time, double u, double n) {
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.82));
  final carve = _cloth(0.75);
  // Kat kat odalar, dikey baca, alt dehliz.
  c.drawRect(const Rect.fromLTWH(60, 30, 300, 70), carve);
  c.drawRect(const Rect.fromLTWH(330, 30, 50, 200), carve);
  c.drawRect(const Rect.fromLTWH(380, 115, 300, 60), carve);
  c.drawRect(const Rect.fromLTWH(60, 200, 680, 150), carve);
  for (final (dx, dy) in [(300.0, 68.0), (450.0, 146.0)]) {
    final roll = _span(u, 0.2, 0.6) * 40;
    c.drawCircle(Offset(dx + roll, dy), 28, _ink(1));
    c.drawCircle(Offset(dx + roll, dy), 7, _cloth(0.75));
  }
  // Sâye: önce yukarı odadan bacaya, sonra alt dehlize.
  final d = _span(u, 0.08, 0.95);
  var p = Offset(120 + d * 230, 108);
  if (d >= 1) p = Offset(355, 108 + _span(u, 0.95, 1.1) * 254);
  if (u > 1.1) p = Offset(355 + _span(u, 1.1, 2.6) * 300, 362);
  // 1: dev uyanır ve peşine düşer; karanlıkta kurt gözleri.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    c.save();
    c.clipRect(const Rect.fromLTWH(60, 200, 680, 150));
    _person(c, Offset(p.dx - 170, 362), 100, a1, _giant, arm: -1.3, time: time);
    c.restore();
    c.drawCircle(Offset(p.dx + 140, 300), 3, _hole(a1));
    c.drawCircle(Offset(p.dx + 150, 300), 3, _hole(a1));
  }
  // 2: en dipten uğultu.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    for (var i = 0; i < 4; i++) {
      final r = 30 + ((time * 30 + i * 30) % 120);
      c.drawArc(
        Rect.fromCenter(center: Offset(p.dx, 420), width: r * 3, height: r),
        math.pi,
        math.pi,
        false,
        _stroke(_hole(0.4 * a2 * (1 - r / 150)), 2),
      );
    }
  }
  _sayeAt(c, p, time, s: 0.95);
}

// ------------------------------------------------------------- Konya

void _bKonya(Canvas c, double time, double u, double n) {
  final pan = -_span(u, 0.08, n - 0.4) * 900;
  c.save();
  c.translate(pan, 0);
  final ink = _ink(0.9);
  // Höyük, İkonion kapısı, Alâeddin tepesi.
  c.drawOval(const Rect.fromLTWH(60, 280, 260, 140), _far(1.6));
  c.drawRect(const Rect.fromLTWH(380, 220, 40, 130), ink);
  c.drawRect(const Rect.fromLTWH(480, 220, 40, 130), ink);
  c.drawArc(
    const Rect.fromLTWH(410, 250, 80, 90),
    math.pi,
    math.pi,
    false,
    _stroke(_ink(0.9), 10),
  );
  c.drawRect(const Rect.fromLTWH(410, 238, 80, 14), ink);
  // Karatay: yıldızlı kubbe.
  c.drawRect(const Rect.fromLTWH(740, 250, 140, 100), ink);
  c.drawArc(
    const Rect.fromLTWH(750, 190, 120, 120),
    math.pi,
    math.pi,
    true,
    ink,
  );
  for (var i = 0; i < 7; i++) {
    c.drawCircle(Offset(770 + i * 14.0, 236 + (i % 2) * 10), 2.4, _hole(0.6));
  }
  // İnce Minare.
  c.drawRect(const Rect.fromLTWH(960, 120, 16, 230), ink);
  c.drawRect(const Rect.fromLTWH(954, 170, 28, 8), ink);
  c.drawPath(
    Path()
      ..moveTo(958, 122)
      ..lineTo(968, 96)
      ..lineTo(978, 122)
      ..close(),
    ink,
  );
  c.drawRect(const Rect.fromLTWH(920, 290, 120, 60), ink);
  // Şems'in kuyusu.
  c.drawRect(const Rect.fromLTWH(1090, 320, 50, 30), ink);
  c.drawArc(
    const Rect.fromLTWH(1090, 300, 50, 40),
    math.pi,
    math.pi,
    false,
    _stroke(_ink(0.9), 3),
  );
  // Semâhane ve Yeşil Kubbe.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (var i = 0; i < 3; i++) {
      _semazenPuppet(c, Offset(1190 + i * 60.0, _gb + 12), time * 3 + i, a1);
    }
  }
  _greenDome(c, 1560, 1, scale: 1.4);
  c.restore();
  _floor(c, 0.9);
  var x = 160 + _span(u, 0.08, n - 0.4) * 140;
  var y = _gb + 12;
  final climb = _span(u, 2.55, 2.95);
  if (climb > 0) {
    x += climb * 300;
    y -= _span(u, 2.78, 2.98) * 110;
  }
  _snowfall(c, time, 1, wind: 20);
  _sayeAt(c, Offset(x, y), time);
}

// ------------------------------------------------------------- Erlik

void _bErlik(Canvas c, double time, double u, double n) {
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.5));
  _floor(c, 1);
  var x = _walkX(u, n, 70, 600);
  var y = _gb + 12;
  var hide = 1.0;
  // 0: kara kapı, mürekkep köprüler, Körmösler ışığı koklar.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    c.drawRect(Rect.fromLTWH(40, 120, 30, _gb - 120), _ink(a0));
    c.drawRect(Rect.fromLTWH(140, 120, 30, _gb - 120), _ink(a0));
    c.drawRect(Rect.fromLTWH(30, 100, 150, 24), _ink(a0));
    for (var i = 0; i < 2; i++) {
      c.drawArc(
        Rect.fromLTWH(220 + i * 200.0, _gb - 60, 200, 120),
        math.pi,
        math.pi,
        false,
        _stroke(_ink(a0), 8),
      );
    }
    for (var i = 0; i < 2; i++) {
      final kx = 380 + i * 170.0 + math.sin(time * 0.8 + i) * 20;
      _person(
        c,
        Offset(kx, _gb + 12),
        170,
        a0,
        _kormos,
        flip: i.isEven,
        time: time + i,
      );
      if ((x - kx).abs() < 120) {
        hide = math.min(hide, 0.35 + (x - kx).abs() / 200);
      }
    }
  }
  // 1: kut zindanı: kafesler açılır, canlar kuş olup uçar.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final open = _span(u, 1.3, 1.7);
    for (var i = 0; i < 3; i++) {
      final cx = 280 + i * 140.0;
      c.drawRect(Rect.fromLTWH(cx - 30, 140, 60, 8), _ink(a1));
      for (var b = 0; b < 5; b++) {
        c.drawLine(
          Offset(cx - 26 + b * 13.0, 148),
          Offset(cx - 26 + b * 13.0, 230 - 70 * open),
          _stroke(_ink(a1), 2.5),
        );
      }
      _P._bird(
        c,
        Offset(cx + 30 * open * math.sin(time + i), 200 - open * 160),
        time,
        a1,
        i * 1.1,
      );
      c.drawCircle(Offset(cx, 200 - open * 160), 9, _hole(0.4 * a1));
    }
  }
  // 2: Çalkuyruk'un kuyusu: atın başı, yukarı yol.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawRect(Rect.fromLTWH(560, 0, 140, _gb), _cloth(0.6 * a2));
    _cut(
      c,
      MythShapes.horse,
      Offset(650, _gb + 40),
      170,
      a2,
      flip: true,
      eye: const Offset(48, -82),
      deco: false,
    );
    c.drawLine(const Offset(600, 0), Offset(600, _gb), _stroke(_ink(a2), 2));
    final up = _span(u, 2.3, 2.9);
    if (up > 0) {
      x = 600;
      y = _gb + 12 - up * 260;
    }
  }
  _sayeAt(c, Offset(x, y), time, a: hide);
}

// ------------------------------------------------------------- Ergenekon

void _bErgenekon(Canvas c, double time, double u, double n) {
  _peaks(c, [
    (0, 60),
    (140, 140),
    (260, 70),
    (400, 150),
    (540, 60),
    (660, 130),
    (780, 50),
  ], _far(1));
  _floor(c, 0.95);
  var x = _walkX(u, n, 60, 620);
  var y = _gb + 12;
  // 0: kömür sandıkları ocağa, körükler ritimle.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    final fire = _span(u, 0.5, 0.9);
    c.drawCircle(
      Offset(520, _gb - 40),
      60 + 30 * fire,
      _hole((0.2 + 0.5 * fire) * a0),
    );
    c.drawRect(Rect.fromLTWH(470, _gb - 60, 100, 60), _ink(a0));
    c.drawRect(
      Rect.fromLTWH(495, _gb - 40, 50, 28),
      _hole((0.3 + 0.7 * fire) * a0),
    );
    final crate = 300 + _span(u, 0.1, 0.45) * 140;
    c.drawRect(Rect.fromLTWH(crate - 26, _gb - 40, 52, 40), _ink(a0));
    c.drawLine(
      Offset(crate - 26, _gb - 40),
      Offset(crate + 26, _gb),
      _stroke(_hole(0.4 * a0), 1.5),
    );
    c.drawLine(
      Offset(crate + 26, _gb - 40),
      Offset(crate - 26, _gb),
      _stroke(_hole(0.4 * a0), 1.5),
    );
    for (var i = 0; i < 2; i++) {
      final beat = math
          .pow(math.max(0, math.sin(time * 4 + i * math.pi)), 3)
          .toDouble();
      final bx = 620 + i * 70.0;
      c.drawPath(
        Path()
          ..moveTo(bx - 26, _gb - 10)
          ..lineTo(bx + 26, _gb - 10 - 20 * (1 - beat) - 6)
          ..lineTo(bx + 26, _gb - 10)
          ..close(),
        _ink(a0),
      );
      c.drawRect(Rect.fromLTWH(bx - 26, _gb - 10, 52, 10), _ink(a0));
    }
    if (u < 0.5) x = crate - 50;
  }
  // 1: akan demir, sisli çayırın adacıkları, Asena'nın mağarası.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final wave = Path()..moveTo(0, _gb + 2);
    for (var i = 0; i <= 26; i++) {
      final wx = i * 30.0;
      wave.lineTo(wx, _gb - 8 - 8 * math.sin(time * 3 + i * 0.7));
    }
    wave
      ..lineTo(780, 400)
      ..lineTo(0, 400)
      ..close();
    c.drawPath(wave, _hole(0.6 * a1));
    for (var i = 0; i < 4; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(150 + i * 130.0, _gb - 6),
          width: 70,
          height: 22,
        ),
        _ink(a1),
      );
    }
    c.drawArc(
      Rect.fromLTWH(600, _gb - 110, 150, 220),
      math.pi,
      math.pi,
      true,
      _ink(a1),
    );
    c.drawCircle(Offset(668, _gb - 50), 3, _hole(a1));
    c.drawCircle(Offset(682, _gb - 50), 3, _hole(a1));
    y -= math.max(0, math.sin((x - 150) / 130 * math.pi)) * 30;
  }
  // 2: demir dağın içi: Nevruz örsü, kapı açılır.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.6 * a2));
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(i * 170.0, 0),
        Offset(i * 170.0 + 90, 400),
        _stroke(_hole(0.15 * a2), 6),
      );
    }
    final anvil = Path()
      ..moveTo(350, _gb - 40)
      ..lineTo(450, _gb - 40)
      ..lineTo(430, _gb - 24)
      ..lineTo(416, _gb - 24)
      ..lineTo(424, _gb)
      ..lineTo(376, _gb)
      ..lineTo(384, _gb - 24)
      ..lineTo(360, _gb - 24)
      ..close();
    c.drawPath(anvil, _ink(a2));
    c.drawRect(Rect.fromLTWH(380, _gb - 48, 40, 8), _hole(0.9 * a2));
    for (var s = 0; s < 3; s++) {
      final hit = _shown(u, 2.2 + s * 0.15, 2.3 + s * 0.15, 0.04);
      for (var i = 0; i < 6; i++) {
        final ang = -math.pi / 2 + (i - 2.5) * 0.4;
        c.drawLine(
          Offset(400, _gb - 50),
          Offset(400 + math.cos(ang) * 40, _gb - 50 + math.sin(ang) * 40),
          _stroke(_hole(hit * a2), 2),
        );
      }
    }
    final open = _span(u, 2.65, 2.9);
    c.drawRect(Rect.fromLTWH(640, 150, 100, _gb - 150), _hole(0.9 * a2 * open));
    c.drawRect(Rect.fromLTWH(640 - 50 * open, 150, 50, _gb - 150), _ink(a2));
    c.drawRect(Rect.fromLTWH(690 + 50 * open, 150, 50, _gb - 150), _ink(a2));
    if (u > 2 && u < 2.6) x = math.min(x, 340);
  }
  _sayeAt(c, Offset(x, y), time);
}

// ------------------------------------------------------------- Göğün katları

void _bSky(Canvas c, double time, double u, double n) {
  final rise = _span(u, 0.55, 1.3);
  // Katlar: bulut, ay, gün; yükseldikçe aşağı kayar.
  c.save();
  c.translate(0, rise * 300);
  for (var i = 0; i < 6; i++) {
    _P._cloud(c, 60 + i * 130.0, 330, 1.1, 0.8);
  }
  c.drawCircle(const Offset(600, 40), 30, _hole(0.7));
  c.drawCircle(const Offset(612, 34), 26, _cloth(1));
  c.drawCircle(const Offset(240, -220), 60, _hole(0.8));
  c.restore();
  final x = _walkX(u, n, 300, 560);
  final y = 330 - rise * 120 + math.sin(time * 1.2) * 6;
  // 0: kamın davulu.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    _cut(
      c,
      MythShapes.kam,
      Offset(110, _gb + 12 + rise * 300),
      190,
      a0,
      deco: false,
    );
    final beat = math.pow(math.max(0, math.sin(time * 5)), 8).toDouble();
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
        Offset(150, _gb - 110 + rise * 300),
        30 + i * 18 + beat * 10,
        _stroke(_hole(0.3 * a0 * (1 - i / 3)), 2),
      );
    }
  }
  // 1: Hüma'nın gölgesi, Ülgen'in kapısı, Tulpar bekler.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final hx = 100 + _span(u, 1.05, 1.8) * 600;
    _cut(c, MythShapes.birdGlide, Offset(hx, 110), 120, a1, deco: false);
    c.drawOval(
      Rect.fromCenter(center: Offset(hx, y - 140), width: 120, height: 14),
      _ink(0.3 * a1),
    );
    c.drawCircle(const Offset(690, 150), 120, _hole(0.3 * a1));
    final gate = Path()
      ..moveTo(640, 360)
      ..lineTo(640, 150)
      ..quadraticBezierTo(690, 90, 740, 150)
      ..lineTo(740, 360);
    c.drawPath(gate, _stroke(_ink(a1), 10));
    _cut(
      c,
      MythShapes.horse,
      Offset(600, 330),
      120,
      a1,
      flip: true,
      deco: false,
    );
    _wings(c, const Offset(596, 240), 70, 0.3 + math.sin(time * 2) * 0.1, a1);
  }
  _sayeAt(c, Offset(x, y), time);
}

// ---------------------------------------------------------------- Ötüken

void _bOtuken(Canvas c, double time, double u, double n) {
  // Orman: arkada kayınlar ve çamlar, önde yosunlu zemin.
  for (var i = 0; i < 11; i++) {
    final x = 30.0 + i * 74;
    final h = 170.0 + (i * 41 % 70);
    if (i.isEven) {
      c.drawRect(Rect.fromLTWH(x - 4, _gb - h, 8, h), _far(1));
      c.drawOval(
        Rect.fromCenter(center: Offset(x, _gb - h), width: 80, height: 64),
        _far(1),
      );
    } else {
      for (var k = 0; k < 4; k++) {
        final y = _gb - h + k * h / 5;
        c.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x - 18 - k * 7, y + h / 4)
            ..lineTo(x + 18 + k * 7, y + h / 4)
            ..close(),
          _far(1),
        );
      }
    }
  }
  _floor(c, 1);
  final x = _walkX(u, n, 90, 560);
  // 0: yapraklardan ışık; gölgede gözler.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (var i = 0; i < 4; i++) {
      final bx = 120.0 + i * 160;
      c.drawPath(
        Path()
          ..moveTo(bx - 12, 0)
          ..lineTo(bx + 14, 0)
          ..lineTo(bx + 46, _gb)
          ..lineTo(bx + 4, _gb)
          ..close(),
        _hole(0.35 * a0),
      );
      final blink = ((time * 0.4 + i * 0.3) % 1) < 0.5 ? 1.0 : 0.15;
      for (final dx in [-6.0, 6.0]) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(bx + 90 + dx, _gb - 70),
            width: 7,
            height: 3 * blink,
          ),
          _hole(0.8 * a0),
        );
      }
    }
  }
  // 1: davul kökleri ve sarmaşık; ışığa yürüyen Ak Geyik.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final beat = ((time * 0.7).floor()) % 2;
    for (var i = 0; i < 4; i++) {
      final up = (i % 2) == beat;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(200 + i * 70.0, _gb - (up ? 14 : 0), 54, 12),
          const Radius.circular(6),
        ),
        _ink(a1 * (up ? 1 : 0.4)),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(470, 30)
        ..quadraticBezierTo(470 + math.sin(time) * 30, 150, 480, 240),
      _stroke(_ink(a1), 3),
    );
    final dk = _span(u, 1.1, 1.9);
    c.save();
    c.translate(560 + dk * 120, _gb);
    c.scale(0.9);
    c.drawPath(DeerRig.frame(time * 0.8, alert: 0.5).shape, _ink(a1));
    c.restore();
    c.drawCircle(Offset(640 + dk * 120, _gb - 90), 10, _hole(0.8 * a1));
  }
  // 2: Kara Bataklık ve Hayat Ağacı; ışık köklere akar, Karabasan dağılır.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawPath(
      Path()
        ..moveTo(600, _gb)
        ..quadraticBezierTo(610, 160, 620, 0)
        ..lineTo(680, 0)
        ..quadraticBezierTo(690, 160, 700, _gb)
        ..close(),
      _ink(a2),
    );
    final flow = _span(u, 2.3, 2.9);
    c.drawRect(Rect.fromLTWH(632, 0, 36, _gb * flow), _hole(0.75 * a2));
    final scatter = _span(u, 2.5, 2.95);
    for (var i = 0; i < 14; i++) {
      final ang = i / 14 * math.pi * 2;
      final d = 30 + scatter * 160;
      c.drawCircle(
        Offset(560 + math.cos(ang) * d, _gb - 60 + math.sin(ang) * d * 0.6),
        16 * (1 - scatter * 0.8),
        _ink(a2 * (1 - scatter)),
      );
    }
  }
  _sayeAt(c, Offset(x, _gb + 12), time);
}

// ------------------------------------------------------------- Ak Ana'nın Denizi

void _bSea(Canvas c, double time, double u, double n) {
  // İlk su: perdenin üst kenarı yüzey; altı mürekkebe doğru koyulaşır.
  const top = 70.0;
  c.drawRect(const Rect.fromLTWH(0, top, 780, 330), _ink(0.35));
  c.drawRect(const Rect.fromLTWH(0, 230, 780, 170), _ink(0.25));
  final wave = Path()..moveTo(0, top);
  for (var x = 0.0; x <= 780; x += 12) {
    wave.lineTo(x, top + math.sin(time * 1.3 + x / 40) * 3);
  }
  c.drawPath(wave, _stroke(_ink(0.9), 3));
  // Sâye soldan sağa yüzer: gövdesi yatık, hafif dalgalanarak.
  final x = _walkX(u, n, 60, 640);
  var y = 200 + math.sin(time * 1.6) * 8;
  var rot = math.pi / 2 - 0.15;
  // 0: Kandilci sandalları yüzeyde; fenerlerin ışığı suya iner, yosunlar.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (var i = 0; i < 2; i++) {
      final bx = 220 + i * 300.0 + math.sin(time * 0.4 + i) * 30;
      c.drawPath(
        Path()
          ..moveTo(bx - 50, top - 12)
          ..lineTo(bx + 50, top - 12)
          ..quadraticBezierTo(bx + 40, top + 8, bx, top + 8)
          ..quadraticBezierTo(bx - 40, top + 8, bx - 50, top - 12)
          ..close(),
        _ink(a0),
      );
      c.drawCircle(Offset(bx - 10, top - 40), 9, _ink(a0));
      c.drawRect(Rect.fromLTWH(bx - 18, top - 32, 16, 22), _ink(a0));
      final cone = Path()
        ..moveTo(bx + 34, top - 8)
        ..lineTo(bx - 10, 260)
        ..lineTo(bx + 90, 260)
        ..close();
      c.drawPath(cone, _hole(0.18 * a0));
    }
    for (var k = 0; k < 9; k++) {
      final kx = 40.0 + k * 85;
      final sway = math.sin(time * 0.9 + k) * 12;
      c.drawPath(
        Path()
          ..moveTo(kx, _gb + 50)
          ..quadraticBezierTo(kx + sway, _gb - 60, kx + sway * 1.6, _gb - 140),
        _stroke(_ink(a0), 5),
      );
    }
    y = 300 + math.sin(time * 1.6) * 6;
  }
  // 1: denizanalarının ışığı; kaplumbağa Sâye'yi sırtında taşır.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (var i = 0; i < 4; i++) {
      final jx = 140 + i * 160.0;
      final jy = 150 + math.sin(time * 1.4 + i * 1.7) * 30;
      c.drawCircle(Offset(jx, jy), 26, _hole(0.25 * a1));
      c.drawPath(
        Path()
          ..moveTo(jx - 18, jy + 4)
          ..quadraticBezierTo(jx, jy - 26, jx + 18, jy + 4)
          ..close(),
        _hole(0.6 * a1),
      );
      for (var t = 0; t < 4; t++) {
        c.drawLine(
          Offset(jx - 12 + t * 8.0, jy + 4),
          Offset(jx - 12 + t * 8.0 + math.sin(time * 2 + t) * 4, jy + 34),
          _stroke(_hole(0.4 * a1), 1.5),
        );
      }
    }
    final ride = _span(u, 1.3, 1.9);
    if (ride > 0) {
      final tx = x + 10;
      final ty = 250.0;
      c.drawOval(Rect.fromCenter(center: Offset(tx, ty), width: 120, height: 50), _ink(a1));
      c.drawOval(Rect.fromCenter(center: Offset(tx + 70, ty + 4), width: 34, height: 22), _ink(a1));
      for (final s in const [-1.0, 1.0]) {
        c.save();
        c.translate(tx + 30 * s, ty + 18);
        c.rotate(0.7 * math.sin(time * 6) * s + 0.4);
        c.drawOval(const Rect.fromLTWH(-8, 0, 16, 40), _ink(a1));
        c.restore();
      }
      y = ty - 30;
      rot = math.pi / 2;
    }
  }
  // 2: dipte yarık; Körmösler dağılır, Ak Ana ışıkla yükselir.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawRect(Rect.fromLTWH(0, _gb - 10, 780, 70), _ink(a2));
    c.drawRect(Rect.fromLTWH(520, _gb - 10, 50, 70), _hole(0.5 * a2));
    final rise = _span(u, 2.25, 2.8);
    for (var i = 0; i < 3; i++) {
      final kx = 300 + i * 90.0 - rise * (60 + i * 30);
      _person(
        c,
        Offset(kx, _gb - 10 + rise * 120),
        150,
        a2 * (1 - rise),
        _kormos,
        flip: i.isOdd,
        time: time + i,
      );
    }
    if (rise > 0) {
      c.drawCircle(Offset(545, _gb - 150 * rise), 60 * rise, _hole(0.45 * a2));
      _person(c, Offset(545, _gb + 60 - 170 * rise), 210, a2 * rise, _akAna);
    }
    y = 220 + _span(u, 2.6, 2.95) * 160;
  }
  _sayeAt(c, Offset(x, y), time, s: 1.3, rot: rot);
}
