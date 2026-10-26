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
  _peaks(c, [(0, 300), (250, 60), (420, 230), (560, 150), (780, 290)], _far(1));
  c.drawPath(
    Path()
      ..moveTo(212, 100)
      ..lineTo(250, 60)
      ..lineTo(290, 104)
      ..lineTo(268, 96)
      ..lineTo(250, 110)
      ..lineTo(232, 94)
      ..close(),
    _hole(0.35),
  );
  _floor(c, 0.9);
  final x = _walkX(u, n, 80, 640);
  // 0: iplere tutunarak; terk edilmiş ağıl.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    for (var i = 0; i < 6; i++) {
      c.drawLine(
        Offset(60 + i * 64.0, _gb),
        Offset(60 + i * 64.0, _gb - 70),
        _stroke(_ink(a0), 3),
      );
    }
    final rope = Path()..moveTo(60, _gb - 64);
    for (var i = 0; i < 5; i++) {
      rope.quadraticBezierTo(92 + i * 64.0, _gb - 50, 124 + i * 64.0, _gb - 64);
    }
    c.drawPath(rope, _stroke(_ink(a0), 2));
    c.drawRect(Rect.fromLTWH(470, _gb - 50, 110, 50), _ink(a0));
    c.drawPath(
      Path()
        ..moveTo(460, _gb - 48)
        ..lineTo(525, _gb - 84)
        ..lineTo(590, _gb - 48)
        ..close(),
      _ink(a0),
    );
    c.drawRect(Rect.fromLTWH(512, _gb - 30, 22, 30), _hole(0.4 * a0));
  }
  // 1: Akori'nin bağı, manastır, Ayaz Ata'nın ak gölgesi.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (var i = 0; i < 4; i++) {
      final vx = 70 + i * 44.0;
      c.drawPath(
        Path()
          ..moveTo(vx, _gb)
          ..quadraticBezierTo(vx - 8, _gb - 24, vx + 4, _gb - 44)
          ..quadraticBezierTo(vx + 14, _gb - 52, vx + 6, _gb - 60),
        _stroke(_ink(a1), 3),
      );
      c.drawCircle(Offset(vx + 10, _gb - 50), 5, _ink(a1));
    }
    c.drawRect(Rect.fromLTWH(430, _gb - 90, 90, 90), _ink(a1));
    c.drawRect(Rect.fromLTWH(458, _gb - 130, 34, 40), _ink(a1));
    c.drawPath(
      Path()
        ..moveTo(452, _gb - 128)
        ..lineTo(475, _gb - 170)
        ..lineTo(498, _gb - 128)
        ..close(),
      _ink(a1),
    );
    c.drawLine(
      Offset(475, _gb - 170),
      Offset(475, _gb - 186),
      _stroke(_ink(a1), 2),
    );
    c.drawLine(
      Offset(468, _gb - 180),
      Offset(482, _gb - 180),
      _stroke(_ink(a1), 2),
    );
    c.drawArc(
      Rect.fromLTWH(462, _gb - 50, 26, 40),
      math.pi,
      math.pi,
      true,
      _hole(0.5 * a1),
    );
    final ax = 680 - _span(u, 1.05, 1.9) * 60;
    c.save();
    c.translate(ax, _gb + 12);
    c.scale(-2.2, 2.2);
    c.drawPath(MythFigures.ayazAtaSilhouette, _hole(0.5 * a1));
    c.restore();
  }
  // 2: buz mağarası; tufanın eşiği.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawPath(
      Path()
        ..moveTo(520, _gb)
        ..lineTo(560, 160)
        ..lineTo(700, 130)
        ..lineTo(780, 180)
        ..lineTo(780, _gb)
        ..close(),
      _ink(a2),
    );
    final mouth = Path()
      ..moveTo(600, _gb)
      ..quadraticBezierTo(650, 190, 720, _gb)
      ..close();
    c.drawPath(mouth, _hole(0.5 * a2 * _span(u, 2.2, 2.7)));
    for (var i = 0; i < 6; i++) {
      c.drawPath(
        Path()
          ..moveTo(600 + i * 20.0, 228 + (i % 2) * 8)
          ..lineTo(606 + i * 20.0, 252 + (i % 3) * 8)
          ..lineTo(612 + i * 20.0, 228 + (i % 2) * 8)
          ..close(),
        _ink(a2),
      );
    }
  }
  _snowfall(c, time, 1, wind: 120);
  _sayeAt(c, Offset(x, _gb + 12), time);
}

// ------------------------------------------------------------- Gemi

void _bArk(Canvas c, double time, double u, double n) {
  // Ambarın kaburgaları.
  for (var i = 0; i < 7; i++) {
    c.drawArc(
      Rect.fromLTWH(-40 + i * 130.0, -80, 160, 520),
      math.pi * 0.5,
      math.pi,
      false,
      _stroke(_far(1), 9),
    );
  }
  c.drawRect(const Rect.fromLTWH(0, 30, 780, 10), _far(1));
  _floor(c, 0.9);
  final x = _walkX(u, n, 80, 640);
  // 0: eşlerinden ayrılmış gölgeler, kilitler açılır.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    final pairs = [
      (MythShapes.horse, 90.0),
      (MythShapes.wolfStand, 70.0),
      (MythShapes.birdGlide, 46.0),
    ];
    for (var i = 0; i < 3; i++) {
      final cx = 180 + i * 210.0;
      final open = _span(u, 0.3 + i * 0.18, 0.55 + i * 0.18);
      final (shape, h) = pairs[i];
      final y = i == 2 ? _gb - 90 : _gb + 6;
      _cut(c, shape, Offset(cx - 66 + 34 * open, y), h, a0, deco: false);
      _cut(
        c,
        shape,
        Offset(cx + 66 - 34 * open, y),
        h,
        a0,
        flip: true,
        deco: false,
      );
      for (var b = 0; b < 3; b++) {
        c.drawLine(
          Offset(cx - 8 + b * 8.0, _gb - 140 - open * 150),
          Offset(cx - 8 + b * 8.0, _gb - open * 150),
          _stroke(_ink(a0), 3),
        );
      }
    }
  }
  // 1: kuyunun dibinde Ak Ana.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    final water = _gb - 20 - 40 * _span(u, 1.4, 1.9);
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, 780, water));
    _person(
      c,
      Offset(460, water + 70 - 60 * _span(u, 1.05, 1.5)),
      210,
      a1,
      _akAna,
      time: time,
    );
    c.restore();
    c.drawRect(
      Rect.fromLTWH(300, water, 320, _gb - water + 10),
      _hole(0.4 * a1),
    );
    for (var i = 0; i < 5; i++) {
      final wx = 310 + (i * 63 + time * 20) % 300;
      c.drawLine(
        Offset(wx, water + 6),
        Offset(wx + 20, water + 6),
        _stroke(_ink(0.5 * a1), 1.4),
      );
    }
  }
  // 2: güverte: ışığın yeri boş.
  final a2 = _heroA(u, 2);
  if (a2 > 0) {
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 210), _cloth(a2));
    c.drawRect(Rect.fromLTWH(0, 210, 780, 12), _ink(a2));
    final niche = Path()
      ..moveTo(560, _gb)
      ..lineTo(560, 260)
      ..quadraticBezierTo(600, 210, 640, 260)
      ..lineTo(640, _gb)
      ..close();
    c.drawPath(niche, _ink(a2));
    c.drawCircle(const Offset(600, 300), 14, _stroke(_hole(0.5 * a2), 1.5));
  }
  _sayeAt(c, Offset(x, _gb + 12), time);
}

// ------------------------------------------------------------- Nemrut

void _bNemrut(Canvas c, double time, double u, double n) {
  _peaks(c, [(420, 330), (600, 120), (780, 330)], _far(1));
  _floor(c, 0.9);
  for (var i = 0; i < 3; i++) {
    c.save();
    c.translate(0, 0);
    _seatedGod(c, 120 + i * 120.0, i, 1, 0.5);
    c.restore();
  }
  final x = _walkX(u, n, 60, 660);
  // 0: deprem yarıkları açılıp kapanır.
  final a0 = _heroA(u, 0);
  var lift = 0.0;
  if (a0 > 0) {
    final w = 6 + 10 * math.max(0, math.sin(time * 2.6));
    for (final rx in [300.0, 470.0]) {
      final crack = Path()..moveTo(rx - w, _gb);
      for (var i = 1; i < 5; i++) {
        crack.lineTo(rx + (i.isEven ? -w : w) * 0.6, _gb + i * 12.0);
      }
      crack
        ..lineTo(rx + w, _gb)
        ..close();
      c.drawPath(crack, _hole(0.7 * a0));
      if ((x - rx).abs() < 40) {
        lift = math.sin((x - rx + 40) / 80 * math.pi) * 40;
      }
    }
  }
  // 1: kartal heykeli, tümülüsten doğuya geçit.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    c.drawRect(Rect.fromLTWH(380, _gb - 40, 60, 40), _ink(a1));
    _cut(c, MythShapes.birdGlide, Offset(410, _gb - 40), 110, a1, deco: false);
    c.drawArc(
      Rect.fromLTWH(620, _gb - 70, 70, 140),
      math.pi,
      math.pi,
      true,
      _hole(0.6 * a1),
    );
  }
  _sayeAt(c, Offset(x, _gb + 12 - lift), time);
}

// ------------------------------------------------------------- Gün doğumu

const _stoneGiant = _Look(
  hat: _Hat.none,
  garb: _Garb.tunic,
  broad: 1.7,
  belt: false,
);

void _bSunrise(Canvas c, double time, double u, double n) {
  final sun = _span(u, 0.2, 1.6);
  c.drawCircle(Offset(700, _gb + 30 - 90 * sun), 80, _hole(0.25 + 0.4 * sun));
  _floor(c, 0.9);
  final x = _walkX(u, n, 140, 560);
  // 0: taştan dev uyanır ve peşine düşer.
  final a0 = _heroA(u, 0);
  var shake = 0.0;
  if (a0 > 0) {
    final step = (time * 1.2) % 1;
    shake = math.pow(1 - step, 6) * 4;
    final gx = 40 + _span(u, 0.2, 0.95) * 150;
    _person(
      c,
      Offset(gx, _gb + 12 - math.sin(step * math.pi) * 8),
      230,
      a0,
      _stoneGiant,
      arm: -1.2,
      time: 0,
    );
    final seam = _stroke(_hole(0.35 * a0), 1.4);
    for (var i = 0; i < 5; i++) {
      c.drawLine(
        Offset(gx - 30 + i * 12.0, _gb - 260 + i * 40),
        Offset(gx - 10 + i * 12.0, _gb - 240 + i * 40),
        seam,
      );
    }
    for (var i = 0; i < 8; i++) {
      c.drawCircle(
        Offset(gx + 30 + i * 9.0, _gb - 4 - shake * i % 7),
        2,
        _ink(0.6 * a0),
      );
    }
  }
  // 1: güneş taş yüzlere vurur; Kandilcilerin ışığı.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    _tasvirKandilci(c, Offset(640, _gb + 12), 0.8, time, a1);
    c.drawRect(Rect.fromLTWH(560, _gb - 70, 40, 70), _ink(a1));
    final reach = _span(u, 1.4, 1.8);
    c.drawCircle(
      Offset(580, _gb - 92),
      16 + 10 * reach,
      _hole((0.6 + 0.4 * reach) * a1),
    );
    c.drawPath(
      Path()
        ..moveTo(700, 200)
        ..lineTo(560, _gb - 100)
        ..lineTo(600, _gb - 84)
        ..close(),
      _hole(0.25 * a1),
    );
  }
  _sayeAt(c, Offset(x, _gb + 12 + shake), time);
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
