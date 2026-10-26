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
      _bSkyLayers(c, time, u, nn);
    case 17:
      _bOtuken(c, time, u, nn);
    case 18:
      _bUlgen(c, time, u, nn);
    case 19:
      _bKubbe(c, time, u, nn);
    case 20:
      _bSea(c, time, u, nn);
  }
}

// ------------------------------------------------------------- Yerebatan

const _suIyesi = _Look(hat: _Hat.hair, garb: _Garb.dress, belt: false);

/// Medusa'nın taş başı: profilden bir kadın yüzü (alın, burun, dudak,
/// çene, kesik boyun), saçı kıvrılan yılanlar; gözü kapalı, taşta çatlaklar.
/// [rot] 0'da yüz sağa bakar, boyun aşağıdadır.
void _medusaHead(
  Canvas c,
  Offset at,
  double r,
  double rot,
  double time,
  double a,
) {
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  final ink = _ink(a);
  // Yılan saçlar: kafatasının ardından ve tepesinden kıvrılarak çıkar.
  for (var i = 0; i < 7; i++) {
    final ang = math.pi * 0.95 + i * 0.27;
    final dir = Offset(math.cos(ang), math.sin(ang));
    final side = Offset(-dir.dy, dir.dx);
    final root = dir * r * 0.75;
    final len = r * (1.0 + (i % 3) * 0.18);
    final wig = math.sin(time * 2.2 + i * 1.3) * 0.25;
    final snake = Path()..moveTo(root.dx, root.dy);
    var tip = root;
    for (var k = 1; k <= 8; k++) {
      final t = k / 8;
      tip =
          root +
          dir * len * t +
          side * math.sin(t * math.pi * 2 + i + wig * 4) * r * 0.16;
      snake.lineTo(tip.dx, tip.dy);
    }
    c.drawPath(snake, _stroke(_ink(a), r * 0.13));
    // Yılanın başı ve çatal dili.
    c.drawOval(
      Rect.fromCenter(center: tip, width: r * 0.26, height: r * 0.18),
      ink,
    );
    c.drawLine(tip, tip + dir * r * 0.22, _stroke(_ink(a), 1.2));
  }
  // Baş: kafatası, alın, burun, dudak, çene; boyun taştan kesik.
  final head = Path()
    ..moveTo(-r * 0.35, r * 1.25)
    ..lineTo(-r * 0.4, r * 0.7)
    ..quadraticBezierTo(-r * 1.05, r * 0.25, -r * 0.9, -r * 0.35)
    ..quadraticBezierTo(-r * 0.6, -r * 1.05, r * 0.15, -r * 1.0)
    ..quadraticBezierTo(r * 0.75, -r * 0.9, r * 0.8, -r * 0.35)
    ..lineTo(r * 1.12, r * 0.05)
    ..lineTo(r * 0.86, r * 0.14)
    ..lineTo(r * 0.92, r * 0.3)
    ..lineTo(r * 0.82, r * 0.38)
    ..lineTo(r * 0.86, r * 0.48)
    ..quadraticBezierTo(r * 0.82, r * 0.72, r * 0.45, r * 0.78)
    ..lineTo(r * 0.4, r * 1.25)
    ..close();
  c.drawPath(head, ink);
  c.drawPath(head, _rim(a));
  // Kapalı göz (aşağı kıvrık kesik), kaş, taş çatlakları.
  final cut = _stroke(_hole(0.7 * a), 1.6);
  c.drawArc(
    Rect.fromCenter(
      center: Offset(r * 0.48, -r * 0.3),
      width: r * 0.34,
      height: r * 0.16,
    ),
    0.2,
    2.6,
    false,
    cut,
  );
  c.drawLine(Offset(r * 0.3, -r * 0.48), Offset(r * 0.66, -r * 0.5), cut);
  final crack = _stroke(_hole(0.35 * a), 1.1);
  c.drawPath(
    Path()
      ..moveTo(-r * 0.2, -r * 0.95)
      ..lineTo(-r * 0.05, -r * 0.55)
      ..lineTo(-r * 0.25, -r * 0.2)
      ..lineTo(-r * 0.1, r * 0.3),
    crack,
  );
  c.drawLine(
    Offset(-r * 0.4, r * 1.1),
    Offset(r * 0.4, r * 1.1),
    _stroke(_hole(0.5 * a), 1.4),
  );
  c.restore();
}

/// Karabasan'ın izi: karanlıkta bir an kıpırdayan kara bir buğu, iki soluk
/// göz.
void _karabasanHint(Canvas c, Offset at, double r, double time, double a) {
  if (a <= 0) return;
  final blob = Path();
  for (var i = 0; i <= 18; i++) {
    final t = i / 18 * math.pi * 2;
    final rr = r * (1 + 0.16 * math.sin(time * 3 + i * 1.9));
    final p = at + Offset(math.cos(t) * rr * 1.1, math.sin(t) * rr * 0.8);
    i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
  }
  c.drawPath(blob..close(), _ink(0.8 * a));
  for (final dx in [-0.3, 0.25]) {
    c.drawOval(
      Rect.fromCenter(
        center: at + Offset(dx * r, -r * 0.2),
        width: r * 0.22,
        height: r * 0.1,
      ),
      _hole(0.5 * a),
    );
  }
}

/// Sâye, isteğe bağlı olarak sola dönük (geriye bakar).
void _sayeFacing(
  Canvas c,
  Offset feet,
  double time, {
  double s = 1.5,
  double a = 1,
  bool left = false,
  double rot = 0,
}) {
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  if (left) c.scale(-1, 1);
  _tasvirSaye(c, Offset.zero, s, time, a);
  c.restore();
}

void _bCistern(Canvas c, double time, double u, double n) {
  final water = _gb - 14.0;
  // Sarnıç karanlık: sütunlar ve kemerler soluk; kanallarda daha da kararır.
  final dark = 0.42 + 0.25 * _span(u, 2.0, 2.3);
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(dark));
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
  // Sâye'nin yolu: 0'da suya bakar, 1'de başların arasından geçer, 2'de
  // döner, sala atlar, kanaldan kaçar.
  final hop = _span(u, 2.35, 2.47);
  // Sal 520'de bekler; Sâye atlayınca sağa, merdivene akar.
  final ride = _span(u, 2.47, 2.95);
  final x =
      150 +
      50 * _span(u, 0.05, 0.4) +
      70 * _span(u, 0.9, 1.15) +
      200 * _span(u, 1.15, 1.9) +
      50 * hop +
      130 * ride;
  // 0: su kıpırdar, su iyesi sudan yükselir, paslı vanayı gösterir.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    final rise = _span(u, 0.05, 0.5);
    for (var k = 0; k < 3; k++) {
      final rr = 16 + ((time * 0.7 + k / 3) % 1) * 70;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(360, water + 4),
          width: rr * 2,
          height: rr * 0.3,
        ),
        _stroke(_hole(0.45 * a0 * (1 - rr / 90)), 1.4),
      );
    }
    // Vana: sütundaki boruda paslı bir çark.
    const valve = Offset(490, 190);
    c.drawRect(Rect.fromLTWH(482, 190, 16, water - 190), _ink(a0 * 0.9));
    c.save();
    c.translate(valve.dx, valve.dy);
    c.rotate(0.3);
    c.drawCircle(Offset.zero, 18, _stroke(_ink(a0), 4));
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset.zero,
        Offset(math.cos(i * math.pi / 2) * 18, math.sin(i * math.pi / 2) * 18),
        _stroke(_ink(a0), 3),
      );
    }
    c.restore();
    c.drawCircle(valve, 26, _hole(0.22 * a0 * _span(u, 0.5, 0.8)));
    _suIyesiRise(
      c,
      Offset(360, water + 120 - 112 * rise),
      190,
      time,
      a0,
      water,
    );
  }
  // 1: sütunların dibinde iki taş Medusa başı (biri baş aşağı, biri yan);
  // su iyesi kenarda fısıldar; Sâye gözlerini yumup aralarından geçer.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    // Baş aşağı baş: boynu yukarıda, sütun boynuna oturur. Yan yatan
    // baş: yüzü yukarı bakar, sütun yanağına oturur.
    const r = 40.0;
    c.drawRect(Rect.fromLTWH(109, 0, 26, water - r * 2.95), _ink(a1 * 0.9));
    _medusaHead(c, Offset(122, water - r * 1.7), r, math.pi, time, a1);
    c.drawRect(Rect.fromLTWH(560, 0, 26, water - r * 1.95), _ink(a1 * 0.9));
    _medusaHead(c, Offset(582, water - r * 0.9), r, -math.pi / 2, time, a1);
    _suIyesiRise(c, Offset(700, water + 60), 150, time, a1 * 0.7, water);
  }
  // 2: ardında bir şey nefes alır (Karabasan'ın izi); Sâye döner, kimse
  // yok. Bir sala atlar, karanlık kanaldan kaçar; ilerde yukarıya, yanan
  // şehre çıkan merdiven.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    // Kanalın tonozu: iki yanda kalın kemer ayakları.
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(780, 0)
        ..lineTo(780, 40)
        ..quadraticBezierTo(390, -30, 0, 40)
        ..close(),
      _ink(a2 * 0.8),
    );
    _karabasanHint(
      c,
      Offset(330, water - 70),
      46,
      time,
      a2 * _span(u, 2.02, 2.1) * (1 - _span(u, 2.16, 2.32)),
    );
    // Merdiven ve yukarıdaki ağız: yanan şehrin ışığı.
    final open = Rect.fromLTRB(690, 34, 772, 124);
    c.drawRect(open, _cloth(a2 * (0.75 + 0.15 * math.sin(time * 5))));
    for (var i = 0; i < 5; i++) {
      final ey = 120 - ((time * 30 + i * 22) % 86);
      c.drawCircle(
        Offset(700 + i * 16.0 + math.sin(time + i) * 4, ey),
        1.8,
        _hole(0.8 * a2),
      );
    }
    final steps = Path()..moveTo(640, water + 2);
    for (var i = 0; i < 9; i++) {
      steps
        ..lineTo(640 + i * 14.0, water - i * 24.0 - 24)
        ..lineTo(654 + i * 14.0, water - i * 24.0 - 24);
    }
    steps
      ..lineTo(780, water - 216)
      ..lineTo(780, water + 2)
      ..close();
    c.drawPath(steps, _ink(a2));
    // Sal: tahtalar suyun üstünde; ardında dalga izi.
    final rx = 520 + 130 * ride;
    c.drawRect(Rect.fromLTWH(rx - 44, water - 4, 88, 10), _ink(a2));
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(rx - 38 + i * 19.0, water - 4),
        Offset(rx - 38 + i * 19.0, water + 6),
        _stroke(_hole(0.45 * a2), 1),
      );
    }
    if (ride > 0) {
      for (var k = 0; k < 3; k++) {
        c.drawLine(
          Offset(rx - 60 - k * 26.0, water + 6 + k * 5),
          Offset(rx - 48 - k * 18.0, water + 3 + k * 5),
          _stroke(_hole(0.5 * a2 * ride), 1.4),
        );
      }
    }
  }
  final turned = u > 2.08 && u < 2.33;
  final y = water - 4 * _span(u, 2.4, 2.47) - math.sin(hop * math.pi) * 30;
  _sayeFacing(c, Offset(x, y), time, left: turned);
}

/// Su iyesi: sudan yapılmış kız; yosun gibi dalgalanan ışık saçları, üstünden
/// damlalar süzülür. Suyun altı görünmez.
void _suIyesiRise(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a,
  double water,
) {
  if (a <= 0) return;
  c.save();
  c.clipRect(Rect.fromLTWH(0, 0, 780, water + 2));
  _person(c, feet, h, a * 0.75, _suIyesi, arm: -2.1, time: time);
  final s = h / 100;
  final head = feet + Offset(-1 * s, -96 * s);
  for (var i = 0; i < 5; i++) {
    final hair = Path()..moveTo(head.dx - 4 * s, head.dy + i * 3 * s);
    for (var k = 1; k <= 6; k++) {
      final t = k / 6;
      hair.lineTo(
        head.dx - 4 * s - t * 16 * s + math.sin(time * 2 + t * 5 + i) * 3 * s,
        head.dy + i * 3 * s + t * (30 + i * 8) * s,
      );
    }
    c.drawPath(hair, _stroke(_hole(0.5 * a), 1.3));
  }
  for (var i = 0; i < 4; i++) {
    final dy = (time * 40 + i * 37) % (90 * s);
    c.drawCircle(
      feet + Offset((i - 1.5) * 9 * s, -80 * s + dy),
      1.6,
      _hole(0.6 * a),
    );
  }
  c.restore();
}

/// Konmuş Hüdhüd: başında taç gibi yelpaze tepelik, alaca (ak bantlı)
/// kanadı katlı, uzun ince gaga, ince bacaklar. Ayakları [feet]'te, sağa
/// bakar; boyu ~46 × [s]. [crest] tepeliğin kabarıklığı, [tear] gözündeki
/// yaş.
void _hudhudPerch(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double crest = 1,
  double tear = 0,
}) {
  if (a <= 0) return;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(flip ? -s : s, s);
  final ink = _ink(a);
  final leg = _stroke(_ink(a), 1.6);
  c.drawLine(const Offset(-2, -10), const Offset(-4, 0), leg);
  c.drawLine(const Offset(3, -10), const Offset(4, 0), leg);
  // Kuyruk ve gövde.
  _fillRim(
    c,
    Path()
      ..moveTo(-12, -16)
      ..lineTo(-32, -6)
      ..lineTo(-30, -1)
      ..lineTo(-10, -11)
      ..close(),
    const Color(0xFF2A2420),
    a,
  );
  _fillRim(
    c,
    Path()..addOval(
      Rect.fromCenter(center: const Offset(0, -19), width: 30, height: 19),
    ),
    const Color(0xFFC8784A),
    a,
  );
  // Katlı kanat: kara-ak alaca bantlar.
  final wing = Path()
    ..moveTo(8, -24)
    ..quadraticBezierTo(-6, -30, -26, -14)
    ..quadraticBezierTo(-6, -10, 8, -16)
    ..close();
  _fillRim(c, wing, const Color(0xFF14100E), a);
  c.save();
  c.clipPath(wing);
  for (var i = 0; i < 4; i++) {
    final x = 2.0 - i * 7;
    c.drawLine(
      Offset(x + 3, -30),
      Offset(x - 3, -8),
      _hole(0.65 * a)..strokeWidth = 2,
    );
  }
  c.restore();
  // Baş, gaga, göz.
  _fillRim(
    c,
    Path()..addOval(
      Rect.fromCenter(center: const Offset(14, -30), width: 13, height: 12),
    ),
    const Color(0xFFC8784A),
    a,
  );
  c.drawPath(
    Path()
      ..moveTo(19, -32)
      ..quadraticBezierTo(30, -30, 38, -23)
      ..quadraticBezierTo(29, -27, 19, -28)
      ..close(),
    ink,
  );
  c.drawCircle(const Offset(16.5, -31), 1.5, _hole(a));
  if (tear > 0) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(16.5, -27 + tear * 5),
        width: 2.6,
        height: 3.6,
      ),
      _hole(tear * a),
    );
  }
  // Yelpaze tepelik: uçları kara, altlarında ışık zımbası.
  final fan = Path()..moveTo(9, -34);
  for (var i = 0; i <= 6; i++) {
    final ang = -2.65 + i * 0.3;
    final r = (11 + (i.isEven ? 2 : 0)) * (0.55 + 0.45 * crest);
    fan.lineTo(10 + math.cos(ang) * r, -34 + math.sin(ang) * r);
  }
  fan.close();
  _fillRim(c, fan, const Color(0xFFE0A030), a);
  for (var i = 0; i <= 6; i++) {
    final ang = -2.65 + i * 0.3;
    final r = 8 * (0.55 + 0.45 * crest);
    c.drawCircle(
      Offset(10 + math.cos(ang) * r, -34 + math.sin(ang) * r),
      1,
      _hole(0.8 * a),
    );
  }
  c.restore();
}

/// Kanatlı Sâye: kanatlar sırtında, [spread] açıklığında; [flap] kanatları
/// çırptırır (ya da titretir); [size] kanadın boyu (katlıyken küçük).
void _wingedSaye(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  double spread = 0.4,
  double flap = 0.15,
  double rot = 0,
  double size = 1,
}) {
  if (a <= 0) return;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  _wings(
    c,
    Offset(-3 * s, -46 * s),
    56 * s * size,
    spread + math.sin(time * 4) * flap,
    a,
  );
  _tasvirSaye(c, Offset.zero, s, time, a);
  c.restore();
}

/// Bembeyaz kanatlı at (Tulpar): ışık rengi deri, mürekkep kontur; kanatlar
/// da ak. Ayakları [feet]'te; [h] boy; [flip] sola bakar.
void _whiteHorse(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = false,
  double flap = 0,
}) {
  if (a <= 0) return;
  final s = h / 100;
  final white = Paint()
    ..color = const Color(0xFFFFF4DC).withValues(alpha: 0.95 * a);
  final line = _stroke(_ink(a), 2.4 / s)..strokeJoin = StrokeJoin.round;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(flip ? -s : s, s);
  // Kanat: sırttan yukarı ve geriye.
  for (final (dx, ang, k) in [(-4.0, 0.75, 0.9), (4.0, 0.45, 1.0)]) {
    c.save();
    c.translate(dx, -70);
    c.rotate(ang + flap);
    c.scale(k * 0.95, k * 0.95);
    c.drawPath(MythFigures.wingSilhouette, white);
    c.drawPath(MythFigures.wingSilhouette, line);
    c.restore();
  }
  c.drawPath(MythShapes.horse, white);
  c.drawPath(MythShapes.horse, line);
  c.drawCircle(const Offset(48, -82), 2.4, _ink(a));
  c.restore();
}

/// Zümrüt Kaf Dağı: mürekkep sırtlar, yüzeylerinde yeşil ışıklı kristal
/// kesikleri. [base] dağın orta-alt noktası, [s] ölçek (1: ~300 boy).
void _qafMountain(Canvas c, Offset base, double s, double a) {
  if (a <= 0) return;
  c.save();
  c.translate(base.dx, base.dy);
  c.scale(s);
  final peaks = [
    (-260.0, 0.0),
    (-190.0, -150.0),
    (-150.0, -120.0),
    (-70.0, -260.0),
    (-20.0, -230.0),
    (40.0, -300.0),
    (110.0, -200.0),
    (170.0, -240.0),
    (260.0, 0.0),
  ];
  final m = Path()..moveTo(peaks.first.$1, peaks.first.$2);
  for (final (x, y) in peaks.skip(1)) {
    m.lineTo(x, y);
  }
  m.close();
  c.drawPath(m, _ink(a));
  final green = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 / s
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF9FE6B4).withValues(alpha: 0.6 * a);
  // Kristal yüzeyler: her doruktan aşağı kısa, kırık bir sırt çizgisi.
  for (var i = 1; i < peaks.length - 1; i++) {
    final (x, y) = peaks[i];
    final side = i.isEven ? 1.0 : -1.0;
    final mid = Offset(x + side * 16, y * 0.55);
    c.drawLine(Offset(x, y), mid, green);
    c.drawLine(mid, Offset(x - side * 6, y * 0.2), green);
  }
  final gem = Paint()
    ..color = const Color(0xFFB8F2C8).withValues(alpha: 0.75 * a);
  for (final (x, y) in [(-120.0, -80.0), (30.0, -150.0), (120.0, -90.0)]) {
    c.drawPath(
      Path()
        ..moveTo(x, y - 9)
        ..lineTo(x + 6, y)
        ..lineTo(x, y + 9)
        ..lineTo(x - 6, y)
        ..close(),
      gem,
    );
  }
  c.restore();
}

// ------------------------------------------------------------- Kule

void _bTower(Canvas c, double time, double u, double n) {
  // 0: kulenin zindanından yukarı: kat kat döşemeler, her katta bir bekçi;
  // soğuk fenerler duvarı tarar, Sâye gölgeden gölgeye kaçar.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    c.drawRect(const Rect.fromLTWH(170, 0, 440, 400), _far(a0));
    const floors = [_gb, 250.0, 150.0, 58.0];
    for (final y in floors) {
      c.drawRect(Rect.fromLTWH(170, y, 440, 8), _ink(0.8 * a0));
    }
    // Saklanılacak gölgeler: duvar oyukları.
    for (final (x, y) in [(330.0, _gb), (250.0, 250.0), (470.0, 150.0)]) {
      c.drawRect(Rect.fromLTWH(x - 26, y - 92, 52, 92), _ink(0.45 * a0));
    }
    // Katlar arası merdiven.
    for (final (x0, y0) in [(390.0, _gb), (300.0, 250.0)]) {
      for (var i = 0; i < 5; i++) {
        c.drawRect(
          Rect.fromLTWH(x0 + i * 12.0, y0 - (i + 1) * 20.0, 14, 5),
          _ink(0.8 * a0),
        );
      }
    }
    // Bekçiler ve tarayan fenerleri.
    for (final (bx, by, ph) in [(530.0, _gb, 0.0), (520.0, 250.0, 1.9)]) {
      final sweep = math.sin(time * 1.1 + ph) * 0.45;
      final lamp = Offset(bx + 42, by - 94);
      c.drawPath(
        Path()
          ..moveTo(lamp.dx, lamp.dy)
          ..lineTo(
            lamp.dx - 230 * math.cos(sweep),
            by + 4 - 60 * math.sin(sweep),
          )
          ..lineTo(
            lamp.dx - 230 * math.cos(sweep),
            by - 70 - 60 * math.sin(sweep),
          )
          ..close(),
        _hole(0.22 * a0),
      );
      _P._puppet(
        c,
        Offset(bx, by),
        time,
        ph,
        a0,
        (ink, hole) => _P._lamplighter(ink, hole),
        scale: 0.48,
        rod: false,
      );
    }
    // Sâye'nin yolu: oyuktan oyuğa, merdivenden yukarı.
    const keys = [
      (0.0, Offset(220, _gb)),
      (0.22, Offset(330, _gb)),
      (0.38, Offset(330, _gb)),
      (0.52, Offset(460, 250)),
      (0.64, Offset(250, 250)),
      (0.74, Offset(250, 250)),
      (0.88, Offset(370, 150)),
      (1.0, Offset(470, 150)),
    ];
    final t = (u - 0.05).clamp(0.0, 0.95) / 0.95;
    var p = keys.last.$2;
    for (var i = 0; i < keys.length - 1; i++) {
      final (t0, p0) = keys[i];
      final (t1, p1) = keys[i + 1];
      if (t <= t1) {
        p = Offset.lerp(p0, p1, _P._ease((t - t0) / (t1 - t0)))!;
        break;
      }
    }
    _sayeAt(c, p, time, s: 1.0, a: a0);
  }

  // 1: en üst kat: tozlu bir sandık; kapağı açılır, içinde kartal tüyünden
  // iki kanat.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    // Çatı kirişleri ve tozlu ışık.
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(780, 0)
        ..lineTo(780, 120)
        ..lineTo(390, 20)
        ..lineTo(0, 120)
        ..close(),
      _ink(0.85 * a1),
    );
    for (final x in [140.0, 390.0, 640.0]) {
      c.drawRect(Rect.fromLTWH(x - 7, 40, 14, _gb - 40), _far(a1));
    }
    _floor(c, a1);
    for (var i = 0; i < 14; i++) {
      final dx = (i * 53.0 + time * 6) % 300;
      final dy = (i * 37.0 + time * 9) % 200;
      c.drawCircle(Offset(380 + dx, 110 + dy), 1.3, _hole(0.5 * a1));
    }
    const chest = Rect.fromLTRB(420, _gb - 64, 580, _gb);
    final open = _span(u, 1.42, 1.68);
    final rise = _span(u, 1.55, 1.95);
    // İçinden sızan ışık ve yükselen kanatlar.
    if (open > 0) {
      final glowC = Offset(chest.center.dx, chest.top);
      c.drawCircle(
        glowC,
        110,
        Paint()
          ..shader = ui.Gradient.radial(glowC, 110, [
            const Color(0xFFFFE6B0).withValues(alpha: 0.65 * open * a1),
            const Color(0x00FFE6B0),
          ]),
      );
      _wings(
        c,
        Offset(chest.center.dx, chest.top + 10 - 34 * rise),
        58 + 12 * rise,
        0.05 + 0.25 * rise,
        a1 * open,
      );
    }
    c.drawRect(chest, _ink(a1));
    _punchRow(
      c,
      Offset(chest.left + 12, chest.top + 18),
      Offset(chest.right - 12, chest.top + 18),
      9,
      2,
      a1,
    );
    _rosette(c, chest.center + const Offset(0, 8), 10, a1);
    // Kapak: arka üst kenarından menteşeyle kalkar.
    c.save();
    c.translate(chest.left, chest.top);
    c.rotate(-1.9 * open);
    c.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(0, -18, 160, 18),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      _ink(a1),
    );
    c.restore();
    final sx = 180 + 160 * _span(u, 1.05, 1.4);
    _sayeAt(c, Offset(sx, _gb + 10), time, s: 1.6, a: a1);
  }

  // 2: kanatlar sırtında, külahın ucunda; aşağıda Haliç bir ayna gibi
  // parlar. "Yine de uç." Ve rüzgâra bırakır kendini.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    // Haliç ve karşı kıyı.
    c.drawRect(
      const Rect.fromLTWH(0, 318, 780, 82),
      Paint()..color = const Color(0xFFFFE8C0).withValues(alpha: 0.75 * a2),
    );
    for (var i = 0; i < 12; i++) {
      final x = (i * 67.0 + time * 10) % 780;
      c.drawLine(
        Offset(x, 330 + (i % 4) * 14),
        Offset(x + 30, 330 + (i % 4) * 14),
        _stroke(_ink(0.25 * a2), 1.2),
      );
    }
    final shore = Path()..moveTo(0, 318);
    for (final (x, y) in [
      (60.0, 300.0),
      (90.0, 300.0),
      (110.0, 286.0),
      (130.0, 300.0),
      (420.0, 300.0),
      (450.0, 282.0),
      (480.0, 300.0),
      (560.0, 304.0),
      (600.0, 290.0),
      (640.0, 304.0),
      (780.0, 306.0),
    ]) {
      shore.lineTo(x, y);
    }
    shore
      ..lineTo(780, 318)
      ..close();
    c.drawPath(shore, _ink(0.55 * a2));
    for (final mx in [70.0, 140.0, 470.0, 620.0]) {
      c.drawRect(Rect.fromLTWH(mx - 2, 262, 4, 40), _ink(0.55 * a2));
    }
    // Külah: Sâye'nin ayağının altında.
    c.drawPath(
      Path()
        ..moveTo(120, 400)
        ..lineTo(290, 178)
        ..lineTo(300, 178)
        ..lineTo(470, 400)
        ..close(),
      _ink(a2),
    );
    c.drawRect(const Rect.fromLTWH(292, 160, 6, 20), _ink(a2));
    final fly = _span(u, 2.55, 2.95);
    final feet = Offset.lerp(
      const Offset(295, 160),
      const Offset(560, 215),
      fly,
    )!;
    final y = feet.dy + math.sin(fly * math.pi) * -30;
    final at = Offset(feet.dx, y);
    final spread = 0.0 + 0.55 * fly + (fly > 0 ? math.sin(time * 4) * 0.12 : 0);
    _wings(c, at + const Offset(-4, -62), 74, spread, a2);
    _sayeAt(c, at, time, s: 1.3, a: a2, rot: 0.35 * fly);
  }
}

// ------------------------------------------------------------- Gökyolu

void _bSkyRoad(Canvas c, double time, double u, double n) {
  for (var i = 0; i < 7; i++) {
    final x = (i * 140.0 - time * 14) % 900 - 60;
    _P._cloud(c, x, 330 + (i % 3) * 22.0, 0.9 + (i % 2) * 0.3, 0.7);
  }
  // Rüzgâr yolu: akan ışık çizgileri.
  for (var i = 0; i < 9; i++) {
    final x = (i * 97.0 + time * 90) % 860 - 40;
    final y = 70.0 + (i * 53) % 220;
    c.drawLine(Offset(x, y), Offset(x + 46, y - 4), _stroke(_hole(0.35), 1.6));
  }
  // 0: Hüdhüd önde, Sâye ardında; kargaların adaları, "Gak! Gak!"; sonra
  // Kandilcilerin bulut kampı.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (final (ix, iy) in [(400.0, 120.0), (520.0, 190.0)]) {
      c.drawPath(
        Path()
          ..moveTo(ix - 54, iy)
          ..quadraticBezierTo(ix, iy - 14, ix + 54, iy)
          ..lineTo(ix + 12, iy + 52)
          ..lineTo(ix - 16, iy + 36)
          ..close(),
        _ink(0.7 * a0),
      );
    }
    final gak = _span(u, 0.25, 0.4) * (1 - _span(u, 0.6, 0.75));
    for (var i = 0; i < 6; i++) {
      final ang = time * 1.6 + i * 1.05;
      final cx = i.isEven ? 400.0 : 520.0;
      final cy = i.isEven ? 84.0 : 154.0;
      final p = Offset(cx + math.cos(ang) * 60, cy + math.sin(ang) * 18);
      _P._bird(c, p, time, a0, i * 1.3);
      if (gak > 0 && i < 3) {
        for (var k = 0; k < 2; k++) {
          c.drawArc(
            Rect.fromCenter(
              center: p + const Offset(-8, -6),
              width: 10.0 + k * 8,
              height: 10.0 + k * 8,
            ),
            2.4,
            1.2,
            false,
            _stroke(_hole(0.8 * gak * a0), 1.4),
          );
        }
      }
    }
    // Bulut kampı: çadırlar, fenerli Kandilciler.
    final camp = a0 * _span(u, 0.5, 0.7);
    if (camp > 0) {
      _P._cloud(c, 625, 318, 1.5, camp);
      for (final x in [560.0, 650.0]) {
        c.drawPath(
          Path()
            ..moveTo(x - 32, 300)
            ..lineTo(x, 252)
            ..lineTo(x + 32, 300)
            ..close(),
          _ink(camp),
        );
        c.drawRect(Rect.fromLTWH(x - 5, 284, 10, 16), _hole(0.6 * camp));
      }
      for (final (x, flip) in [(610.0, false), (700.0, true)]) {
        final lamp = Offset(x + (flip ? -1 : 1) * 42, 300 - 92);
        c.drawCircle(
          lamp,
          22,
          Paint()
            ..shader = ui.Gradient.radial(lamp, 22, [
              const Color(0xFFFFE0A0).withValues(alpha: 0.7 * camp),
              const Color(0x00FFE0A0),
            ]),
        );
        _P._puppet(
          c,
          Offset(x, 300),
          time,
          x,
          camp,
          (ink, hole) => _P._lamplighter(ink, hole),
          scale: 0.48,
          flip: flip,
          rod: false,
        );
      }
    }
    final k = _span(u, 0.05, 0.8);
    final sp = Offset(110 + 160 * k, 220 - 20 * k + math.sin(time * 1.4) * 8);
    _wingedSaye(c, sp, 1.2, time, a0, spread: 0.5, flap: 0.18);
    _tasvirHudhud(c, sp + const Offset(130, -70), 1.0, time, a0);
  }
  // 1: fırtına adalarında şimşek: her yer bir an ışığa boğulur; Sâye
  // gölgeden örülmüş köprünün üstünden uçup kaçar.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (final (ix, iy) in [(180.0, 110.0), (640.0, 90.0)]) {
      c.drawPath(
        Path()
          ..moveTo(ix - 60, iy)
          ..lineTo(ix + 60, iy)
          ..lineTo(ix + 14, iy + 56)
          ..lineTo(ix - 18, iy + 40)
          ..close(),
        _ink(0.75 * a1),
      );
    }
    final bridge = Path()
      ..moveTo(70, 310)
      ..quadraticBezierTo(390, 170, 710, 310)
      ..lineTo(710, 322)
      ..quadraticBezierTo(390, 186, 70, 322)
      ..close();
    c.drawPath(bridge, _ink(a1));
    for (var i = 0; i < 24; i++) {
      final t = i / 24;
      final x = 70 + t * 640;
      final y = 316 - math.sin(t * math.pi) * 70;
      c.drawLine(
        Offset(x - 6, y - 6),
        Offset(x + 6, y + 6),
        _stroke(_hole(0.35 * a1), 1),
      );
    }
    final flash =
        _span(u, 1.05, 1.1) * (1 - _span(u, 1.28, 1.55)) +
        0.5 * _span(u, 1.62, 1.65) * (1 - _span(u, 1.66, 1.75));
    if (flash > 0) {
      c.drawRect(
        const Rect.fromLTWH(0, 0, 780, 400),
        Paint()
          ..color = const Color(0xFFFFF4DC).withValues(alpha: 0.8 * flash * a1),
      );
      final bolt = Path()..moveTo(600, 0);
      for (var i = 1; i < 7; i++) {
        bolt.lineTo(600 + (i.isEven ? -22 : 18), i * 26.0);
      }
      c.drawPath(bolt, _stroke(_ink(a1 * flash), 3));
    }
    final k = _span(u, 1.2, 1.95);
    final t = 0.1 + 0.75 * k;
    final sp = Offset(70 + t * 640, 300 - math.sin(t * math.pi) * 70);
    _wingedSaye(c, sp, 1.15, time, a1, spread: 0.5, flap: 0.2, rot: 0.1);
    _tasvirHudhud(c, sp + const Offset(110, -60), 0.9, time, a1);
  }
  // 2: bulutların arasında Tulpar'ın yelesi bir an parlar, sonra kaybolur.
  // İleride zümrüt dağ: "Kaf," dedi Hüdhüd.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    _qafMountain(c, Offset(620, 352 - 30 * _span(u, 2.2, 2.7)), 0.8, a2);
    final mane = a2 * _span(u, 2.05, 2.15) * (1 - _span(u, 2.4, 2.55));
    if (mane > 0) {
      _whiteHorse(c, const Offset(262, 196), 90, time, mane, flip: true);
      for (var i = 0; i < 6; i++) {
        c.drawLine(
          Offset(294 + i * 5.0, 120 + i * 3.0),
          Offset(312 + i * 7.0, 110 + i * 5.0 + math.sin(time * 6 + i) * 3),
          _stroke(_hole(mane), 1.6),
        );
      }
    }
    // Tulpar bulutun ardında: bulut ondan önce koyulaşır.
    _P._cloud(c, 250, 206, 1.5, math.min(1.0, a2 * 1.6));
    final sp = Offset(180 + 80 * _span(u, 2.1, 2.9), 300);
    _wingedSaye(c, sp, 1.2, time, a2, spread: 0.5, flap: 0.18);
    _tasvirHudhud(c, sp + const Offset(140, -50), 1.0, time, a2);
  }
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
  // 0: zümrüt köprü; Kandilcilerin gök karakolu. Sâye köprüyü aşar,
  // gölgesini rüzgâra bırakıp karakolun dibinden süzülür.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    // Köprü: uçurumun üstünde, zümrüt ışıklı korkuluk.
    c.drawRect(Rect.fromLTWH(0, 300, 360, 10), _ink(a0));
    final green = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF9FE6B4).withValues(alpha: 0.7 * a0);
    for (var i = 0; i < 13; i++) {
      c.drawLine(Offset(10 + i * 28.0, 300), Offset(10 + i * 28.0, 270), green);
    }
    c.drawLine(const Offset(0, 270), const Offset(360, 270), green);
    for (var i = 0; i < 6; i++) {
      _P._cloud(c, 60 + i * 150.0, 400, 1.0, a0 * 0.8);
    }
    // Karakol: bulutun üstünde bir kule, platformda iki fenerli bekçi.
    _P._cloud(c, 640, 214, 1.0, a0);
    c.drawRect(Rect.fromLTWH(560, 172, 160, 10), _ink(a0));
    c.drawRect(Rect.fromLTWH(628, 182, 24, 40), _ink(a0));
    for (final (x, flip, ph) in [(600.0, false, 0.0), (690.0, true, 2.0)]) {
      final sweep = math.sin(time * 1.3 + ph) * 0.35;
      final lamp = Offset(x + (flip ? -1 : 1) * 40, 172 - 88);
      c.drawPath(
        Path()
          ..moveTo(lamp.dx, lamp.dy)
          ..lineTo(lamp.dx - 70 + 160 * sweep, 400)
          ..lineTo(lamp.dx + 10 + 160 * sweep, 400)
          ..close(),
        _hole(0.18 * a0),
      );
      _P._puppet(
        c,
        Offset(x, 172),
        time,
        ph,
        a0,
        (ink, hole) => _P._lamplighter(ink, hole),
        scale: 0.46,
        flip: flip,
        rod: false,
      );
    }
    final walk = _span(u, 0.05, 0.42);
    final glide = _span(u, 0.42, 0.95);
    final feet = glide > 0
        ? Offset(300 + 330 * glide, 300 - 40 * math.sin(glide * math.pi) + 10)
        : Offset(60 + 240 * walk, 300);
    _wingedSaye(
      c,
      feet,
      1.2,
      time,
      a0,
      spread: glide > 0 ? 0.5 : 0.95,
      flap: glide > 0 ? 0.06 : 0.02,
      size: glide > 0 ? 1 : 0.72,
      rot: 0.2 * glide,
    );
  }
  // 1: Simurg'un tüyleri birer birer; her tüye dokununca dağın bir yerinde
  // bir kuş öter.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    _floor(c, 0.9 * a1);
    const feathers = [Offset(250, 240), Offset(420, 200), Offset(590, 240)];
    const singers = [Offset(120, 116), Offset(390, 36), Offset(640, 86)];
    for (var i = 0; i < 3; i++) {
      final found = _span(u, 1.2 + i * 0.25, 1.3 + i * 0.25);
      _feather(c, feathers[i], 1.1, a1, found);
      final song = found * (1 - _span(u, 1.45 + i * 0.25, 1.62 + i * 0.25));
      _P._bird(c, singers[i] + const Offset(0, -6), time, a1, i * 2.0);
      for (var k = 0; k < 3; k++) {
        c.drawArc(
          Rect.fromCenter(
            center: singers[i] + const Offset(0, -10),
            width: 16.0 + k * 12,
            height: 12.0 + k * 9,
          ),
          -2.6,
          2.0,
          false,
          _stroke(_hole(0.85 * song * a1), 1.6),
        );
      }
    }
    final sx = 170 + 420 * _span(u, 1.08, 1.92);
    _sayeAt(c, Offset(sx, _gb + 12), time, a: a1);
  }
  // 2: üçüncü tüyle ayna salonunun kapısı gıcırdayarak açılır; içerisi
  // karanlık; karanlığın içinde bir ayna bekler.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    _floor(c, 0.9 * a2);
    final open = _span(u, 2.15, 2.6);
    final arch = Path()
      ..moveTo(600, _gb)
      ..lineTo(600, 170)
      ..quadraticBezierTo(670, 92, 740, 170)
      ..lineTo(740, _gb)
      ..close();
    // Taş çerçeve.
    c.drawPath(arch, _stroke(_ink(a2), 18)..strokeCap = StrokeCap.butt);
    c.drawPath(arch, _ink(a2));
    // İçerideki ayna: karanlıkta ancak kenarı seçilir.
    final mirror = a2 * _span(u, 2.35, 2.7);
    c.drawOval(
      Rect.fromCenter(center: const Offset(670, 220), width: 60, height: 92),
      _stroke(_hole(0.75 * mirror), 2.5),
    );
    c.drawLine(
      const Offset(652, 196),
      const Offset(664, 182),
      _stroke(_hole(0.6 * mirror), 2),
    );
    // Kanatlar: iki yana açılır (daralarak), kenarları ışıkla seçilir.
    for (final side in [-1.0, 1.0]) {
      final hinge = side < 0 ? 600.0 : 740.0;
      final w = 70 * (1 - 0.82 * open);
      final r = side < 0
          ? Rect.fromLTWH(hinge, 130, w, _gb - 130)
          : Rect.fromLTWH(hinge - w, 130, w, _gb - 130);
      c.save();
      c.clipPath(arch);
      c.drawRect(
        r,
        Paint()..color = const Color(0xFF3A2010).withValues(alpha: a2),
      );
      c.drawRect(r, _stroke(_hole(0.5 * a2), 1.5));
      c.restore();
    }
    final sx = 470 + 60 * _span(u, 2.5, 2.9);
    _sayeAt(c, Offset(sx, _gb + 12), time, a: a2);
    // Elindeki üçüncü tüy.
    _feather(c, Offset(sx + 40, 288), 0.7, a2, 1 - open);
  }
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
  // Yapılar soluk: önlerinden geçen Sâye seçik kalsın.
  final ink = _ink(0.55);
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
  _greenDome(c, 1560, 0.95, scale: 1.15);
  c.restore();
  _floor(c, 0.9);
  // Kar: iri taneler, yoğun.
  _snowfall(c, time, 1.9, wind: 20);
  _snowfall(c, time * 0.7 + 3, 1.2, wind: 35);
  var x = 160 + _span(u, 0.08, n - 0.4) * 140;
  var y = _gb + 12;
  var rot = 0.0;
  // Kubbeye yürür, duvarına, sonra yeşil kaburgalarına tutunup tırmanır.
  final walk = _span(u, 2.5, 2.68);
  if (walk > 0) x += walk * 305;
  final climb = _span(u, 2.68, 2.97);
  if (climb > 0) {
    // Kubbe ekranda 1560-900 = 660'ta; duvar dibi, duvar başı, külah.
    const path = [Offset(605, _gb + 12), Offset(610, 216), Offset(636, 148)];
    final f = climb * 2;
    final i = math.min(f.floor(), 1);
    final p = Offset.lerp(path[i], path[i + 1], f - i)!;
    x = p.dx;
    y = p.dy;
    rot = 0.28 * _span(u, 2.8, 2.9);
  }
  _sayeAt(
    c,
    Offset(x, y),
    time,
    rot: rot,
    s: walk > 0 ? 1.5 - 0.5 * walk : 1.5,
  );
}

// ------------------------------------------------------------- Erlik

void _bErlik(Canvas c, double time, double u, double n) {
  _coldCloth(c, 1);
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.2));
  _floor(c, 1);
  final walk0 = _span(u, 0.05, 0.4);
  final hide = _span(u, 0.5, 0.65);
  var x = u < 1
      ? 110 + 120 * walk0 - 60 * hide
      : 170 + 160 * _span(u, 1.05, 1.9);
  var y = _gb + 12;
  var jar = 1 - hide * (1 - _span(u, 0.98, 1.2));
  var drawSaye = true;
  // 0: kara kapı, mürekkep köprüler; Körmösler ışığın kokusunu alır, Sâye
  // kavanozunu örtüp kapının gölgesine saklanır.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (var i = 0; i < 2; i++) {
      c.drawArc(
        Rect.fromLTWH(250 + i * 220.0, _gb - 70, 220, 140),
        math.pi,
        math.pi,
        false,
        _stroke(_ink(a0), 9),
      );
    }
    final sniff = _span(u, 0.35, 0.6);
    for (var i = 0; i < 2; i++) {
      final kx = 370 + i * 220.0 - 30 * sniff + math.sin(time * 0.8 + i) * 6;
      _person(
        c,
        Offset(kx, _gb - 66),
        150,
        a0,
        _kormos,
        flip: true,
        time: time + i,
        arm: -1.2 * sniff,
      );
    }
    // Kapı: Sâye'nin önünde kalan iki kara direk.
    c.drawRect(Rect.fromLTWH(30, 100, 150, 24), _ink(a0));
    c.drawRect(Rect.fromLTWH(40, 120, 30, _gb - 120), _ink(a0));
    _sayeJ(c, Offset(x, y), 1.5, time, 1, jar: jar);
    c.drawRect(Rect.fromLTWH(140, 120, 34, _gb - 120), _ink(a0));
    drawSaye = false;
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
      c.drawLine(Offset(cx, 0), Offset(cx, 140), _stroke(_ink(a1), 1.6));
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
  // 2: kuyunun dibinde Çalkuyruk bekler; "Bin sırtıma." Sâye biner, at
  // yukarı çıkan yoldan onu taşır.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    // Kuyu: yukarı kıvrılan aydınlık yol.
    final road = Path()
      ..moveTo(420, _gb)
      ..lineTo(500, _gb)
      ..lineTo(760, 150)
      ..lineTo(760, 90)
      ..close();
    c.drawPath(road, _cloth(0.55 * a2));
    c.drawLine(
      const Offset(500, _gb),
      const Offset(760, 150),
      _stroke(_ink(a2), 4),
    );
    final mount = _span(u, 2.3, 2.45);
    final ride = _span(u, 2.45, 2.92);
    const slope = -0.6;
    final hx = 520 + 190 * ride;
    final hy = _gb + 10 - 178 * ride;
    c.save();
    c.translate(hx, hy);
    c.rotate(slope * _span(u, 2.45, 2.55));
    final speak = _span(u, 2.15, 2.22) * (1 - _span(u, 2.32, 2.4));
    _horseLift(
      c,
      Offset.zero,
      150,
      a2,
      0.6 + 0.4 * _span(u, 2.1, 2.3),
      time,
      speak: speak,
    );
    if (mount > 0) {
      _sayeJ(c, const Offset(-6, -50), 1.2, time, a2 * mount);
    }
    c.restore();
    if (u < 2.45) {
      x = 330 + 30 * _span(u, 2.05, 2.25);
      y = _gb + 12;
      if (mount > 0) {
        x += (hx - 6 - x) * mount;
        y += (hy - 50 - y) * mount;
      }
      jar = 1;
      drawSaye = mount < 1;
      if (mount > 0) {
        _sayeJ(c, Offset(x, y), 1.5 - 0.3 * mount, time, a2 * (1 - mount));
        drawSaye = false;
      }
    } else {
      drawSaye = false;
    }
  }
  if (drawSaye) _sayeJ(c, Offset(x, y), 1.5, time, 1, jar: jar);
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
  // 1: erimiş demir dalga dalga akar (akkor ışık); sisli çayırın
  // adacıkları akıntının üstünde tümsek; Sâye birinden ötekine atlar;
  // Asena'nın mağarasında boz kurdun gözleri parlar.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final wave = Path()..moveTo(0, _gb + 2);
    for (var i = 0; i <= 26; i++) {
      final wx = i * 30.0;
      wave.lineTo(wx, _gb - 10 - 6 * math.sin(time * 3 - i * 0.7));
    }
    wave
      ..lineTo(780, 400)
      ..lineTo(0, 400)
      ..close();
    c.drawPath(
      wave,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, _gb - 20),
          const Offset(0, 400),
          [
            const Color(0xFFFFE8A0).withValues(alpha: 0.95 * a1),
            const Color(0xFFFF9A40).withValues(alpha: 0.9 * a1),
            const Color(0xFFB84A18).withValues(alpha: 0.85 * a1),
          ],
          const [0, 0.35, 1],
        ),
    );
    c.drawRect(
      const Rect.fromLTWH(0, _gb - 60, 780, 50),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, _gb - 60),
          const Offset(0, _gb - 10),
          [
            const Color(0x00FFB050),
            const Color(0xFFFFB050).withValues(alpha: 0.35 * a1),
          ],
        ),
    );
    // Akan demirin kabuğu: akıntıyla kayan kara pullar.
    for (var i = 0; i < 12; i++) {
      final fx = (i * 71.0 + time * 40) % 820 - 20;
      c.drawLine(
        Offset(fx, _gb + 8 + (i % 3) * 12),
        Offset(fx + 18, _gb + 8 + (i % 3) * 12),
        _stroke(_ink(0.5 * a1), 2.5),
      );
    }
    // Adacıklar: akıntının üstünde çimenli tümsekler.
    for (var i = 0; i < 4; i++) {
      final ix = 150 + i * 130.0;
      c.drawPath(
        Path()
          ..moveTo(ix - 40, _gb + 6)
          ..quadraticBezierTo(ix - 34, _gb - 30, ix, _gb - 32)
          ..quadraticBezierTo(ix + 34, _gb - 30, ix + 40, _gb + 6)
          ..close(),
        _ink(a1),
      );
      for (var t = 0; t < 4; t++) {
        final gx = ix - 18 + t * 12.0;
        c.drawLine(
          Offset(gx, _gb - 30),
          Offset(gx + math.sin(time * 2 + t) * 3, _gb - 42),
          _stroke(_ink(a1), 1.6),
        );
      }
    }
    // Sis: adacıkların üstünde ince ışık şeritleri.
    for (var i = 0; i < 6; i++) {
      final mx = (i * 140.0 + time * 12) % 900 - 60;
      c.drawLine(
        Offset(mx, _gb - 50 - (i % 2) * 14),
        Offset(mx + 90, _gb - 50 - (i % 2) * 14),
        _stroke(_hole(0.3 * a1), 5),
      );
    }
    // Asena'nın mağarası.
    c.drawArc(
      Rect.fromLTWH(610, _gb - 120, 150, 240),
      math.pi,
      math.pi,
      true,
      _ink(a1),
    );
    final blink = (time % 3) < 0.12 ? 0.2 : 1.0;
    for (final ex in [672.0, 688.0]) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(ex, _gb - 56),
          width: 7,
          height: 5 * blink,
        ),
        _hole(a1),
      );
      c.drawCircle(Offset(ex, _gb - 56), 9, _hole(0.2 * a1));
    }
    // Sâye adacıktan adacığa sekerek geçer.
    final hop = _span(u, 1.05, 1.85);
    final k = hop * 3;
    final seg = k.floor().clamp(0, 2);
    final t = k - seg;
    x = 150 + (seg + t) * 130.0;
    y = _gb - 30 + 12 - math.sin(t * math.pi) * 60;
  }
  // 2: demir dağın içi: Sâye örse üç kez vurur (tak, tak, tak); kapı
  // açılır, Sâye ışığa yürür.
  final a2 = _heroA(u, 2);
  var hammer = 0.0;
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
    var strike = 0.0;
    for (var s = 0; s < 3; s++) {
      final t0 = 2.2 + s * 0.13;
      final hit = _shown(u, t0, t0 + 0.06, 0.02);
      final lift =
          _span(u, t0 - 0.08, t0 - 0.03) * (1 - _span(u, t0 - 0.03, t0));
      strike = math.max(strike, lift);
      for (var i = 0; i < 6; i++) {
        final ang = -math.pi / 2 + (i - 2.5) * 0.4;
        c.drawLine(
          Offset(400, _gb - 50),
          Offset(400 + math.cos(ang) * 40, _gb - 50 + math.sin(ang) * 40),
          _stroke(_hole(hit * a2), 2),
        );
      }
    }
    final open = _span(u, 2.56, 2.7);
    c.drawRect(Rect.fromLTWH(640, 150, 100, _gb - 150), _hole(0.9 * a2 * open));
    c.drawRect(Rect.fromLTWH(640 - 50 * open, 150, 50, _gb - 150), _ink(a2));
    c.drawRect(Rect.fromLTWH(690 + 50 * open, 150, 50, _gb - 150), _ink(a2));
    final go = _span(u, 2.7, 2.85);
    final approach = _span(u, 2.02, 2.15);
    if (u < 2.7) {
      x = 300 + 30 * approach;
      hammer = a2 * (1 - _span(u, 2.6, 2.7));
    } else {
      x = 330 + 360 * go;
    }
    y = _gb + 12;
    if (hammer > 0) {
      // Çekiç: Sâye'nin elinde; her vuruşta kalkar, örse iner.
      final hand = Offset(x + 30, y - 46);
      final ang = -0.15 - 1.9 * strike;
      final head = hand + Offset(math.cos(ang), math.sin(ang)) * 52;
      c.drawLine(hand, head, _stroke(_ink(hammer), 4));
      c.save();
      c.translate(head.dx, head.dy);
      c.rotate(ang);
      c.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 10, height: 22),
        _ink(hammer),
      );
      c.restore();
    }
  }
  _sayeJ(c, Offset(x, y), 1.5, time, 1, jar: 1 - hammer);
}

// ---------------------------------------------------------------- Ötüken

void _bOtuken(Canvas c, double time, double u, double n) {
  // Orman: arkada kayınlar ve çamlar (son satırda Kara Bataklık'a döner).
  final swamp = _span(u, 1.85, 2.15);
  for (var i = 0; i < 11; i++) {
    final x = 30.0 + i * 74;
    final h = 170.0 + (i * 41 % 70);
    final p = _far(1 - 0.5 * swamp);
    if (i.isEven) {
      c.drawRect(Rect.fromLTWH(x - 4, _gb - h, 8, h), p);
      c.drawOval(
        Rect.fromCenter(center: Offset(x, _gb - h), width: 80, height: 64),
        p,
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
          p,
        );
      }
    }
  }
  var x = 100 + 200 * _span(u, 0.1, 0.9);
  var y = _gb + 12;
  var rot = 0.0;
  // 0: yapraklardan ışık; gölgede Karabasan'ın gözleri açılıp kapanır.
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
  // Zemin; 1'de ortasında dikenli bir yar açılır.
  final a1 = _heroA(u, 1);
  const r0 = 330.0, r1 = 480.0;
  if (a1 > 0) {
    c.drawRect(const Rect.fromLTWH(0, _gb, r0, 60), _ink(1));
    c.drawRect(const Rect.fromLTWH(r1, _gb, 780 - r1, 60), _ink(1));
    c.drawRect(const Rect.fromLTWH(r0, _gb, r1 - r0, 60), _ink(1 - a1));
    // Yarın duvarları ve dibi: dikenler.
    for (final (wx, dir) in [(r0, 1.0), (r1, -1.0)]) {
      for (var k = 0; k < 4; k++) {
        final ty = _gb + 4 + k * 12.0;
        c.drawPath(
          Path()
            ..moveTo(wx, ty)
            ..lineTo(wx + dir * 16, ty + 4)
            ..lineTo(wx, ty + 8)
            ..close(),
          _ink(a1),
        );
      }
    }
    for (var k = 0; k < 9; k++) {
      final tx = r0 + 10 + k * 16.0;
      c.drawPath(
        Path()
          ..moveTo(tx - 6, 400)
          ..lineTo(tx, 372 - (k % 2) * 8)
          ..lineTo(tx + 6, 400)
          ..close(),
        _ink(a1),
      );
    }
  } else {
    _floor(c, 1);
  }
  if (a1 > 0) {
    // Kam davulunu çalar; her vuruşta kökler yerden kalkar, basamak olur.
    final beat = math.pow((time * 1.6) % 1, 3).toDouble();
    _kamOrman(c, const Offset(70, _gb + 10), 210, a1, time, beat: beat);
    for (var i = 0; i < 3; i++) {
      final up = _span(u, 1.04 + i * 0.07, 1.14 + i * 0.07);
      final rx = 170 + i * 52.0;
      final top = _gb - up * (20 + i * 18);
      c.drawPath(
        Path()
          ..moveTo(rx - 22, _gb + 4)
          ..quadraticBezierTo(rx - 18, top, rx, top - 4)
          ..quadraticBezierTo(rx + 18, top, rx + 22, _gb + 4)
          ..close(),
        _ink(a1),
      );
      c.drawCircle(Offset(rx, top + 8), 2, _hole(0.5 * a1 * up));
    }
    // Yarın üstünde dal ve sarmaşık.
    const pivot = Offset(405, 40);
    c.drawPath(
      Path()
        ..moveTo(290, 30)
        ..quadraticBezierTo(400, 60, 530, 36),
      _stroke(_ink(a1), 9),
    );
    final swing = _span(u, 1.3, 1.65);
    final ang = u < 1.3
        ? 0.75 + math.sin(time * 1.5) * 0.04
        : (u < 1.65 ? 0.75 - swing * 1.5 : -0.75);
    const len = 175.0;
    final end = pivot + Offset(-math.sin(ang), math.cos(ang)) * len;
    c.drawLine(pivot, end, _stroke(_ink(a1), 3.5));
    for (var k = 1; k < 6; k++) {
      final p = Offset.lerp(pivot, end, k / 6)!;
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(5, 0), width: 10, height: 5),
        _ink(a1),
      );
    }
    // Ak geyik ateşböceklerinin ışığını izler, kök kapısını açar.
    final dk = _span(u, 1.1, 1.7);
    final gate = _span(u, 1.6, 1.85);
    c.drawRect(Rect.fromLTWH(690, 190, 44, _gb - 190), _hole(0.55 * a1 * gate));
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(712 + side * (22 + 24 * gate), _gb);
      c.scale(side, 1);
      c.drawPath(
        Path()
          ..moveTo(-10, 0)
          ..quadraticBezierTo(-8, -110, -30 * gate - 2, -170)
          ..lineTo(-30 * gate + 8, -164)
          ..quadraticBezierTo(4, -100, 8, 0)
          ..close(),
        _ink(a1),
      );
      c.restore();
    }
    final deer = DeerRig.frame(
      gate > 0.9 ? 0 : time * 0.8,
      alert: 0.5,
      still: gate > 0.9,
    ).shape;
    c.save();
    c.translate(520 + dk * 110, _gb);
    c.scale(0.95);
    c.drawPath(deer, _hole(0.9 * a1));
    c.drawPath(deer, _stroke(_ink(a1), 2.4));
    c.restore();
    for (var i = 0; i < 6; i++) {
      final fx = 600 + dk * 110 + math.sin(time * 2 + i * 1.3) * 26 + i * 6;
      final fy = _gb - 150 + math.cos(time * 1.7 + i) * 22 - i * 4;
      c.drawCircle(Offset(fx, fy), 2.4, _hole(0.9 * a1));
      c.drawCircle(Offset(fx, fy), 7, _hole(0.18 * a1));
    }
    // Sâye: kök basamaklarından çıkar, sarmaşıkla yarın üstünden sallanır,
    // karşıya iner.
    final climb = _span(u, 1.12, 1.26);
    final grab = _span(u, 1.24, 1.3);
    final land = _span(u, 1.65, 1.8);
    final hang = end + Offset(-math.sin(ang), math.cos(ang)) * 69;
    if (u < 1.3) {
      x = 140 + 150 * climb;
      var bump = 0.0;
      for (var i = 0; i < 3; i++) {
        final up = _span(u, 1.04 + i * 0.07, 1.14 + i * 0.07);
        final d = (x - (170 + i * 52.0)) / 24;
        bump = math.max(bump, up * (24 + i * 18) * (1 - d * d));
      }
      y = _gb + 12 - bump;
      x = x + (hang.dx - x) * grab;
      y = y + (hang.dy - y) * grab;
      rot = ang * grab;
    } else if (u < 1.65) {
      x = hang.dx;
      y = hang.dy;
      rot = ang;
    } else {
      x = hang.dx + 60 * land;
      y = hang.dy + (_gb + 12 - hang.dy) * land;
      rot = ang * (1 - land);
    }
  }
  // 2: Kara Bataklık: Karabasan bütün gücüyle çöker; Sâye Hayat Ağacı'na
  // tırmanır, dallardaki aynalarla gün ışığını köklere çevirir; ışık
  // köklere akınca Karabasan dağılır.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    // Bataklık sazları ve suyun parıltısı.
    for (var i = 0; i < 14; i++) {
      final rx = 20.0 + i * 56;
      c.drawLine(
        Offset(rx, _gb + 2),
        Offset(rx + math.sin(time + i) * 4, _gb - 30 - (i % 3) * 12),
        _stroke(_ink(a2), 2.5),
      );
    }
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(40 + i * 150.0, _gb + 14),
        Offset(110 + i * 150.0, _gb + 14),
        _stroke(_hole(0.25 * a2), 2),
      );
    }
    // Gün: sol üstte.
    const sun = Offset(90, 58);
    c.drawCircle(sun, 34, _hole(0.6 * a2));
    c.drawCircle(sun, 52, _hole(0.15 * a2));
    // Hayat Ağacı: perdenin içinde; gövde, dallar, tepe.
    const tx = 610.0;
    c.drawPath(
      Path()
        ..moveTo(tx - 40, _gb + 4)
        ..quadraticBezierTo(tx - 16, _gb - 150, tx - 12, 80)
        ..lineTo(tx + 12, 80)
        ..quadraticBezierTo(tx + 16, _gb - 150, tx + 40, _gb + 4)
        ..close(),
      _ink(a2),
    );
    final mirrors = <Offset>[];
    for (var i = 0; i < 4; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final by = _gb - 110 - i * 42.0;
      final end = Offset(tx + side * (110 - i * 14), by - 34);
      c.drawPath(
        Path()
          ..moveTo(tx, by)
          ..quadraticBezierTo(tx + side * 50, by - 4, end.dx, end.dy),
        _stroke(_ink(a2), 8.0 - i),
      );
      if (side < 0) mirrors.add(end);
    }
    c.drawOval(
      Rect.fromCenter(center: const Offset(tx, 78), width: 270, height: 80),
      _ink(a2),
    );
    for (final dx in [-70.0, -30.0, 30.0, 70.0]) {
      c.drawPath(
        Path()
          ..moveTo(tx, _gb)
          ..quadraticBezierTo(tx + dx, _gb + 10, tx + dx * 1.5, _gb + 40),
        _stroke(_ink(a2), 6),
      );
    }
    // Aynalar: Sâye çevirince ışığı köklere yollar.
    final turn = _span(u, 2.5, 2.62);
    final flow = _span(u, 2.58, 2.78);
    for (final m in mirrors) {
      c.drawOval(Rect.fromCenter(center: m, width: 22, height: 28), _ink(a2));
      c.drawOval(
        Rect.fromCenter(center: m, width: 14, height: 20),
        _hole((0.35 + 0.65 * turn) * a2),
      );
    }
    if (turn > 0) {
      final m = mirrors.first;
      c.drawPath(
        Path()
          ..moveTo(sun.dx + 20, sun.dy - 22)
          ..lineTo(sun.dx + 20, sun.dy + 22)
          ..lineTo(m.dx, m.dy + 10)
          ..lineTo(m.dx, m.dy - 10)
          ..close(),
        _hole(0.35 * a2 * turn),
      );
    }
    if (flow > 0) {
      final m = mirrors.first;
      c.drawPath(
        Path()
          ..moveTo(m.dx - 8, m.dy)
          ..lineTo(m.dx + 8, m.dy)
          ..lineTo(tx + 70, m.dy + (_gb - m.dy) * flow)
          ..lineTo(tx - 110, m.dy + (_gb - m.dy) * flow)
          ..close(),
        _hole(0.45 * a2),
      );
      for (var i = 0; i < 6; i++) {
        c.drawCircle(
          Offset(tx - 80 + i * 32.0, _gb + 6),
          4,
          _hole(a2 * flow * (0.5 + 0.4 * math.sin(time * 4 + i))),
        );
      }
    }
    // Karabasan: Sâye'nin üstüne çöker; ışıkta parçalanıp dağılır.
    final press = _span(u, 2.05, 2.3);
    final follow = _span(u, 2.3, 2.6);
    _karabasan(
      c,
      Offset(330 + 120 * follow, _gb - 60 - 30 * press),
      66 + 16 * press,
      a2,
      time,
      dir: 1,
      scatter: _span(u, 2.68, 2.95),
    );
    // Sâye: kaçar, ağaca tırmanır, aynanın yanında durur.
    final run = _span(u, 2.05, 2.3);
    final up = _span(u, 2.3, 2.52);
    x = 440 + 108 * run;
    y = _gb + 12 - up * 130;
  }
  _sayeAt(c, Offset(x, y), time, rot: rot);
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
    // Fenerbalığı: sağdaki karanlıktan parlak yemini sallar; Sâye
    // kanmaz, altından geçip gider.
    final fish = _span(u, 0.35, 0.6);
    if (fish > 0) {
      final fx = 700 - 90 * fish + math.sin(time * 0.8) * 8;
      const fy = 250.0;
      final body = Path()
        ..moveTo(fx - 60, fy)
        ..quadraticBezierTo(fx - 50, fy - 40, fx + 10, fy - 36)
        ..quadraticBezierTo(fx + 50, fy - 30, fx + 64, fy - 6)
        ..lineTo(fx + 84, fy - 22)
        ..lineTo(fx + 80, fy + 18)
        ..lineTo(fx + 62, fy + 6)
        ..quadraticBezierTo(fx + 40, fy + 34, fx - 10, fy + 30)
        ..quadraticBezierTo(fx - 50, fy + 26, fx - 60, fy)
        ..close();
      c.drawPath(body, _ink(a0 * fish));
      // Ağız: dişli yarık.
      for (var t = 0; t < 5; t++) {
        c.drawPath(
          Path()
            ..moveTo(fx - 58 + t * 7, fy + 2)
            ..lineTo(fx - 54 + t * 7, fy + 9)
            ..lineTo(fx - 50 + t * 7, fy + 2)
            ..close(),
          _hole(0.6 * a0 * fish),
        );
      }
      c.drawCircle(Offset(fx - 30, fy - 14), 3, _hole(a0 * fish));
      // Olta ve parlak yem.
      final lure = Offset(fx - 96, fy - 70 + math.sin(time * 2.4) * 6);
      c.drawPath(
        Path()
          ..moveTo(fx - 20, fy - 34)
          ..quadraticBezierTo(fx - 40, fy - 100, lure.dx, lure.dy),
        _stroke(_ink(a0 * fish), 2),
      );
      c.drawCircle(lure, 18, _hole(0.25 * a0 * fish));
      c.drawCircle(lure, 6, _hole(a0 * fish));
    }
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
      c.drawOval(
        Rect.fromCenter(center: Offset(tx, ty), width: 120, height: 50),
        _ink(a1),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(tx + 70, ty + 4), width: 34, height: 22),
        _ink(a1),
      );
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
  // 2: dipte yarık; Körmösler yaklaşır, Ak Ana ışıkla yükselince geri
  // çekilip karanlığa karışır; Ak Ana Sâye'ye ak bir nefes verir, Sâye
  // yarıktan aşağı süzülür.
  final a2 = _heroA(u, 2);
  var sx = x;
  if (a2 > 0) {
    c.drawRect(Rect.fromLTWH(0, _gb - 10, 780, 70), _ink(a2));
    c.drawRect(Rect.fromLTWH(440, _gb - 10, 70, 70), _hole(0.55 * a2));
    final come = _span(u, 2.05, 2.3);
    final rise = _span(u, 2.25, 2.6);
    final flee = _span(u, 2.3, 2.75);
    for (var i = 0; i < 3; i++) {
      final kx = 60 + i * 80.0 + come * 80 - flee * (140 + i * 40);
      _person(
        c,
        Offset(kx, _gb - 8),
        150,
        a2 * (1 - flee),
        _kormos,
        time: time + i,
        arm: -1.4 * come * (1 - flee),
      );
    }
    final ana = a2 * rise;
    if (ana > 0) {
      c.drawCircle(Offset(640, _gb - 150 * rise), 60 * rise, _hole(0.4 * ana));
      _person(
        c,
        Offset(640, _gb + 60 - 170 * rise),
        210,
        ana,
        _akAna,
        flip: true,
      );
    }
    // Ak nefes: Ak Ana'nın ağzından Sâye'ye ışıktan bir şerit.
    final breath = _span(u, 2.45, 2.6) * (1 - _span(u, 2.75, 2.85));
    sx = 400 + 75 * _span(u, 2.0, 2.4);
    if (breath > 0) {
      final from = Offset(632, _gb + 60 - 170 - 196);
      final to = Offset(sx + 20, 200.0);
      final p = Path()..moveTo(from.dx, from.dy);
      for (var i = 1; i <= 12; i++) {
        final t = i / 12;
        final q = Offset.lerp(from, to, t * breath)!;
        p.lineTo(q.dx, q.dy + math.sin(time * 6 + t * 8) * 6 * t);
      }
      c.drawPath(p, _stroke(_hole(0.85 * breath), 5));
    }
    final sink = _span(u, 2.62, 2.95);
    y = 200 + sink * 190;
    rot = math.pi / 2 - 0.15 + sink * (math.pi / 2 + 0.15);
  }
  // Yarığa inerken perdenin dibinden taşmasın.
  c.save();
  if (a2 > 0) c.clipRect(const Rect.fromLTWH(0, 0, 780, _gb + 50));
  _sayeAt(c, Offset(a2 > 0 ? sx : x, y), time, s: 1.3, rot: rot);
  c.restore();
}
