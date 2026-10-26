part of 'perde.dart';

// Yolun son durakları: Göğün katları (16), Ülgen'in kapısı (18), Konya'da
// Şeb-i Arûs (13), Yeşil Kubbe (19), köprüleri ve son perdenin yakın
// tasvirleri. Her satır kendi tasviriyle: konuşan perdede görünür, satırda
// anılmayan kimse yoktur. Sanal sahne 780×400, zemin y=350.

const _sg = PerdePainter._ground;

/// Satır [k]'nın tasviri: girer, önüne ışık iner, satır biterken çıkar.
/// [cover] 2 iken ardındaki manzara neredeyse büsbütün silinir (yakın
/// tasvirlerde arkada başka bir kubbe, başka bir usta kalmasın).
void _satir(
  Canvas c,
  double u,
  double k,
  void Function(double a) draw, {
  double veil = 1,
  int cover = 1,
}) {
  final a = _heroA(u, k);
  if (a <= 0) return;
  for (var i = 0; i < cover; i++) {
    _veil(c, a * veil);
  }
  _P._c = c;
  draw(a);
}

// ---------------------------------------------------------- yardımcılar

/// Dört (ya da [points]) köşeli yıldız.
void _starShape(
  Canvas c,
  Offset at,
  double r,
  Paint p, {
  int points = 4,
  double spin = 0,
}) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final rr = i.isEven ? r : r * 0.38;
    final ang = i * math.pi / points - math.pi / 2 + spin;
    final q = at + Offset(math.cos(ang), math.sin(ang)) * rr;
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  c.drawPath(path..close(), p);
}

/// Kandil ışığı: sıcak hale ve aydınlık öz. [flick] titreşim (0: durgun).
void _lampGlow(Canvas c, Offset at, double r, double a, {double flick = 0}) {
  if (a <= 0) return;
  final rr = r * (1 + flick);
  c.drawCircle(
    at,
    rr * 3,
    Paint()
      ..shader = ui.Gradient.radial(at, rr * 3, [
        const Color(0xFFFFE0A0).withValues(alpha: 0.65 * a),
        const Color(0x00FFE0A0),
      ]),
  );
  c.drawCircle(at, rr, _hole(a));
}

/// Ülgen'in ışığı: biçimsiz bir aydınlık, dönen ışınlar.
void _ulgenGlow(Canvas c, Offset at, double r, double time, double a) {
  if (a <= 0) return;
  c.drawCircle(
    at,
    r * 2.2,
    Paint()
      ..shader = ui.Gradient.radial(at, r * 2.2, [
        const Color(0xFFFFFBEA).withValues(alpha: 0.85 * a),
        const Color(0x00FFE8B0),
      ]),
  );
  final ray = _stroke(_hole(0.55 * a), 2.4);
  for (var i = 0; i < 16; i++) {
    final ang = i / 16 * math.pi * 2 + time * 0.15;
    final len = r * (1.1 + 0.35 * math.sin(time * 1.3 + i * 1.7));
    c.drawLine(
      at + Offset(math.cos(ang), math.sin(ang)) * r * 0.45,
      at + Offset(math.cos(ang), math.sin(ang)) * len,
      ray,
    );
  }
  c.drawCircle(at, r * 0.28 + 2 * math.sin(time * 2), _hole(a));
}

/// Şimşek: kırık çizgi, kandilin ışığından; [a] çakışın gücü.
void _bolt(Canvas c, Offset from, Offset to, double seed, double a) {
  if (a <= 0.02) return;
  final path = Path()..moveTo(from.dx, from.dy);
  const n = 7;
  final d = to - from;
  final nrm = Offset(-d.dy, d.dx) / d.distance;
  for (var i = 1; i < n; i++) {
    final j = math.sin(seed * 12.9898 + i * 78.233) * 43758.5453;
    final off = (j - j.floorToDouble() - 0.5) * 46;
    final q = from + d * (i / n) + nrm * off;
    path.lineTo(q.dx, q.dy);
  }
  path.lineTo(to.dx, to.dy);
  c.drawPath(path, _stroke(_hole(a), 5)..strokeJoin = StrokeJoin.round);
  c.drawPath(
    path,
    _stroke(Paint()..color = const Color(0xFFFFFBEA).withValues(alpha: a), 2)
      ..strokeJoin = StrokeJoin.round,
  );
}

/// Çakış: kısa bir parlama, sonra karanlık ([seed] her şimşeğe ayrı an).
double _flash(double time, double seed, {double rate = 0.8}) {
  final f = (time * rate + seed) % 1;
  return f < 0.16 ? 1 - f / 0.16 : 0;
}

/// Bulut katı: dalgalı ince şerit.
void _cloudBand(
  Canvas c,
  double y,
  double time,
  Paint p, {
  double x0 = 0,
  double x1 = 780,
  double depth = 16,
}) {
  final path = Path()..moveTo(x0, y + depth);
  for (var x = x0; x <= x1 + 0.1; x += 20) {
    path.lineTo(x, y + math.sin(x / 38 + time * 0.4) * 5);
  }
  path
    ..lineTo(x1, y + depth)
    ..close();
  c.drawPath(path, p);
}

/// Bulut tabanı: üstünde durulan kabarık bulutlar (zemin y=350).
void _cloudFloor(Canvas c, double a) {
  for (var i = 0; i < 8; i++) {
    _P._cloud(c, 20 + i * 110.0, _sg + 6, 0.8 + (i % 3) * 0.12, a);
  }
  c.drawRect(Rect.fromLTWH(0, _sg, 780, 60), _ink(a));
}

/// Hilal: soğuk, yumuşak ay.
void _crescent(Canvas c, Offset at, double r, Paint p) {
  c.drawPath(
    Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: at, radius: r)),
      Path()..addOval(
        Rect.fromCircle(
          center: at + Offset(r * 0.42, -r * 0.22),
          radius: r * 0.86,
        ),
      ),
    ),
    p,
  );
}

// ------------------------------------------------------------ kişiler

/// Kam: tüylü başlık, saçaklı cübbe; bir elinde resimli davul, ötekinde
/// tokmak. Vurdukça davuldan ses halkaları açılır. [h] gövde boyu (tüyler
/// bunun %16 üstüne çıkar).
void _kamFig(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = false,
  double rate = 1.1,
  double force = 1,
}) {
  if (a <= 0) return;
  final s = h / 100;
  final beat = (time * rate) % 1;
  final hit = math.pow(1 - beat, 4).toDouble();
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(flip ? -s : s, s);
  final ink = _ink(a);
  c.drawPath(MythFigures.kamSilhouette, ink);
  // Etek saçakları ve cübbedeki çıngıraklar: ışık kesikleri.
  final cut = _stroke(_hole(0.55 * a), 0.9);
  for (var i = 0; i < 9; i++) {
    final x = -18 + i * 4.5;
    final sw = math.sin(time * 3 + i * 0.7) * 1.2 + hit * 1.5;
    c.drawLine(Offset(x, -36), Offset(x + sw, -31), cut);
  }
  for (var i = 0; i < 5; i++) {
    c.drawCircle(
      Offset(-8 + i * 4.0, -62 + (i.isOdd ? 3 : 0)),
      1.1,
      _hole((0.45 + 0.45 * hit) * a),
    );
  }
  // Davul: kasnak, gergin deri, üstünde Gün, Ay ve hayat ağacı.
  const drum = Offset(-31, -56);
  c.drawOval(Rect.fromCenter(center: drum, width: 22, height: 32), ink);
  c.drawOval(
    Rect.fromCenter(center: drum, width: 16, height: 25),
    _hole((0.18 + 0.45 * hit) * a),
  );
  final pic = _stroke(_ink(a), 1.1);
  c.drawLine(drum + const Offset(0, 9), drum + const Offset(0, -6), pic);
  for (final sd in [-1.0, 1.0]) {
    c.drawLine(drum + const Offset(0, -1), drum + Offset(sd * 4, -5), pic);
    c.drawLine(drum + const Offset(0, 4), drum + Offset(sd * 4.5, 1), pic);
  }
  c.drawCircle(drum + const Offset(-3.5, -8.5), 1.6, _ink(a));
  // Tokmak: vuruşta davula savrulur.
  const hand = Offset(-14, -50);
  final ang = math.pi + 0.9 - hit * 0.9;
  final tip = hand + Offset(math.cos(ang), math.sin(ang)) * 15;
  c.drawLine(hand, tip, _stroke(_ink(a), 2.4));
  c.drawCircle(tip, 2.6, ink);
  // Ses halkaları: davulun ardından açılır.
  for (var i = 0; i < 3; i++) {
    final k = (beat + i / 3) % 1;
    c.drawArc(
      Rect.fromCircle(center: drum, radius: 16 + k * 34),
      1.9,
      2.5,
      false,
      _stroke(_hole(0.55 * force * (1 - k) * a), 1.6),
    );
  }
  c.restore();
}

const _yelAnaLook = _Look(hat: _Hat.hair, garb: _Garb.dress, belt: false);

/// Yel Ana: rüzgârların anası; yatay uçar, ardında esintinin telleri.
/// [at] ayakları (gövde yana yatıktır), [h] boyu.
void _yelAna(
  Canvas c,
  Offset at,
  double h,
  double time,
  double a, {
  bool flip = false,
}) {
  if (a <= 0) return;
  final dir = flip ? -1.0 : 1.0;
  // Esinti telleri: bedenin ardından dalga dalga uzar.
  for (var i = 0; i < 6; i++) {
    final y0 = at.dy - h * (0.05 + i * 0.07) + math.sin(time * 2 + i) * 4;
    final x0 = at.dx + dir * h * (0.25 + i * 0.1);
    final w = math.sin(time * 3 + i * 1.3) * 10;
    c.drawPath(
      Path()
        ..moveTo(x0, y0)
        ..cubicTo(
          x0 - dir * h * 0.4,
          y0 - 18 + w,
          x0 - dir * h * 0.7,
          y0 + 16 - w,
          x0 - dir * h * (1.0 + i * 0.06),
          y0 + w,
        ),
      _stroke(_hole(0.6 * a), i.isEven ? 2.6 : 1.6),
    );
  }
  // Rüzgârın burgaçları.
  for (var i = 0; i < 2; i++) {
    final cx = at.dx - dir * h * (0.55 + i * 0.35);
    final cy = at.dy - h * (0.15 + i * 0.18);
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: 12 + i * 4),
      time * 2 + i,
      4.4,
      false,
      _stroke(_ink(0.8 * a), 2.2),
    );
  }
  _person(c, at, h, a, _yelAnaLook, flip: flip, rot: dir * 1.2, arm: -2.6);
}

/// Hüma kuşu: geniş kanatlı, süzülen; gövdesi ortada ([at] karnının altı).
void _humaFig(Canvas c, Offset at, double s, double time, double a) {
  if (a <= 0) return;
  c.save();
  c.translate(at.dx, at.dy + math.sin(time * 1.4) * 4);
  c.scale(s, s * (1 + math.sin(time * 1.2) * 0.05));
  c.drawPath(MythShapes.birdGlide, _ink(a));
  c.drawCircle(const Offset(30, -24), 1.4, _hole(a));
  _punchRow(c, const Offset(-34, -22), const Offset(34, -22), 9, 0.9, a);
  c.restore();
}

/// Tulpar: kanatlı ak at. [bow] başını eğişi (ön ayakları çevresinde).
void _tulparFig(
  Canvas c,
  Offset feet,
  double h,
  double time,
  double a, {
  bool flip = false,
  double spread = 0.4,
  double bow = 0,
  bool flap = true,
}) {
  if (a <= 0) return;
  final k = h / 170;
  final dir = flip ? -1.0 : 1.0;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(dir * bow);
  _cut(
    c,
    MythShapes.horse,
    Offset.zero,
    h,
    a,
    flip: flip,
    eye: const Offset(48, -82),
    deco: false,
  );
  // Ak at: gövdesinde zımba yıldızlar.
  for (var i = 0; i < 6; i++) {
    c.drawCircle(
      Offset(dir * (-28 + i * 9.0) * k, (-70 + (i % 2) * 8.0) * k),
      1.6 * k + 0.6,
      _hole(0.7 * a),
    );
  }
  _wings(
    c,
    Offset(dir * 6 * k, -128 * k),
    100 * k,
    spread + (flap ? math.sin(time * 3) * 0.18 : 0),
    a,
  );
  c.restore();
}

/// Kandilci: fenerli, kukuletalı (yönü çevrilebilir). [lit] false iken
/// feneri kapalıdır, içinden ışık geçmez.
void _kandilciFig(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  bool lit = true,
  double lift = 0,
  double seed = 0,
}) {
  if (a <= 0) return;
  if (lit) {
    final lantern = feet + Offset((flip ? -88.0 : 88.0) * s, (-188 - lift) * s);
    c.drawCircle(
      lantern,
      48 * s,
      Paint()
        ..shader = ui.Gradient.radial(lantern, 48 * s, [
          const Color(0xFFFFE0A0).withValues(alpha: 0.7 * a),
          const Color(0x00FFE0A0),
        ]),
    );
  }
  _P._c = c;
  _P._puppet(
    c,
    feet,
    time,
    1.7 + seed,
    a,
    (ink, hole) => _P._lamplighter(ink, lit ? hole : ink, lanternLift: lift),
    scale: s,
    flip: flip,
    rod: false,
  );
}

/// Kandilci Başı: Kandilcilerin en yaşlısı; daha uzun, sivri kukuletası
/// geriye düşmüş, uzun sakallı. Feneri kapalı. [laugh] gülerken sarsılır.
void _kandilciBasi(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  bool lit = false,
  double laugh = 0,
}) {
  if (a <= 0) return;
  final dir = flip ? -1.0 : 1.0;
  c.save();
  c.translate(feet.dx, feet.dy - (math.sin(time * 21) * 2.5 * laugh).abs());
  c.rotate(-dir * laugh * 0.07);
  c.save();
  c.scale(dir * s, s);
  final ink = _ink(a);
  // Uzun, geriye kıvrılan kukulete ucu.
  c.drawPath(
    Path()
      ..moveTo(-9, -166)
      ..quadraticBezierTo(-16, -196, -30, -214)
      ..quadraticBezierTo(-4, -200, 5, -160)
      ..close(),
    ink,
  );
  // Uzun sakal: kukuletanın altından göğsüne iner.
  c.drawPath(
    Path()
      ..moveTo(6, -146)
      ..quadraticBezierTo(22, -140, 19, -116)
      ..quadraticBezierTo(15, -96, 7, -80)
      ..quadraticBezierTo(5, -110, 0, -138)
      ..close(),
    ink,
  );
  final strand = _stroke(_hole(0.45 * a), 0.9);
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(8 + i * 3.0, -132),
      Offset(9 + i * 2.0, -100 + i * 4.0),
      strand,
    );
  }
  // Cübbenin eteğinde eski bir hayalînin zımba süsü.
  _punchRow(c, const Offset(-26, -14), const Offset(26, -14), 8, 1.6, a);
  c.restore();
  _kandilciFig(c, Offset.zero, s, time, a, flip: flip, lit: lit, seed: 0.6);
  c.restore();
}

/// Hayalî Usta. [bend] öne eğilişi (ayakları çevresinde), [lamp] elinde
/// kandil tutar (kolu öne uzanır), [snow] omuzlarına ve kavuğuna yağan kar.
void _masterFig(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
  double bend = 0,
  bool lamp = false,
  double snow = 0,
}) {
  if (a <= 0) return;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate((flip ? -1 : 1) * bend);
  _P._c = c;
  _P._puppet(
    c,
    Offset.zero,
    time,
    0.9,
    a,
    (ink, hole) {
      _P._master(ink, hole);
      final cc = _P._c;
      if (lamp) {
        // Kandili tutan kol: omuzdan öne.
        cc.drawPath(
          Path()
            ..moveTo(4, -120)
            ..quadraticBezierTo(30, -106, 44, -90)
            ..lineTo(40, -82)
            ..quadraticBezierTo(24, -96, 2, -106)
            ..close(),
          ink,
        );
        cc.drawCircle(const Offset(42, -86), 4, ink);
      }
      if (snow > 0) {
        final w = _hole(snow * a);
        cc.drawOval(
          Rect.fromCenter(
            center: const Offset(-22, -121),
            width: 24,
            height: 7,
          ),
          w,
        );
        cc.drawOval(
          Rect.fromCenter(center: const Offset(22, -119), width: 18, height: 6),
          w,
        );
        cc.drawOval(
          Rect.fromCenter(center: const Offset(4, -227), width: 14, height: 5),
          w,
        );
      }
    },
    scale: s,
    flip: flip,
    rod: false,
  );
  c.restore();
}

/// [_masterFig]'in kandil tuttuğu elin perdedeki yeri.
Offset _masterHand(
  Offset feet,
  double s, {
  bool flip = false,
  double bend = 0,
}) {
  final d = flip ? -1.0 : 1.0;
  final l = Offset(d * 46 * s, -88 * s);
  final r = d * bend;
  return feet +
      Offset(
        l.dx * math.cos(r) - l.dy * math.sin(r),
        l.dx * math.sin(r) + l.dy * math.cos(r),
      );
}

/// Sâye dizlerinin üstünde: bacakları karın ardında kalır.
void _sayeKneel(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  double kneel = 1,
  double floor = _sg + 12,
}) {
  c.save();
  c.clipRect(Rect.fromLTWH(0, 0, 780, floor + 2));
  _tasvirSaye(c, feet + Offset(0, 24 * s * kneel), s, time, a);
  c.restore();
}

/// Sâye'nin kavanozunu tutan eli (avuçları) — [_tasvirSaye] ölçeğinde.
Offset _sayeHand(Offset feet, double s) => feet + Offset(26 * s, -27 * s);

// ------------------------------------------------------------- mekânlar

/// Uçsuz bucaksız kar ovası: ufuk çizgisi, ovada kar parıltısı, önde
/// basılan zemin.
void _snowPlain(Canvas c, double time, double a, {double horizon = 296}) {
  if (a <= 0) return;
  c.drawRect(Rect.fromLTWH(0, horizon, 780, 400 - horizon), _ink(0.16 * a));
  c.drawLine(
    Offset(0, horizon),
    Offset(780, horizon),
    _stroke(_ink(0.55 * a), 2),
  );
  final glint = _hole(0.7 * a);
  for (var i = 0; i < 26; i++) {
    final x = (i * 97.0) % 780;
    final y = horizon + 8 + (i * 37.0) % (_sg - horizon - 6);
    c.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.5, glint);
  }
  final ground = Path()..moveTo(0, 400);
  for (var x = 0.0; x <= 780; x += 30) {
    ground.lineTo(x, _sg + math.sin(x / 70) * 3);
  }
  ground
    ..lineTo(780, 400)
    ..close();
  c.drawPath(ground, _ink(0.9 * a));
  _snowfall(c, time, a);
}

/// Uzaktaki Konya: ufukta küçük kubbeler, minareler ve Yeşil Kubbe;
/// pencerelerinden ışık sızar.
void _farCity(
  Canvas c,
  double x,
  double base,
  double s,
  double a, {
  double glow = 0.7,
}) {
  if (a <= 0) return;
  final ink = _ink(0.75 * a);
  c.drawRect(Rect.fromLTWH(x - 60 * s, base - 8 * s, 150 * s, 8 * s), ink);
  for (final (dx, r) in [(-40.0, 12.0), (-6.0, 17.0), (52.0, 11.0)]) {
    c.drawArc(
      Rect.fromCircle(center: Offset(x + dx * s, base - 6 * s), radius: r * s),
      math.pi,
      math.pi,
      true,
      ink,
    );
  }
  for (final dx in [-58.0, 26.0, 80.0]) {
    c.drawRect(Rect.fromLTWH(x + dx * s, base - 44 * s, 3.5 * s, 40 * s), ink);
    c.drawPath(
      Path()
        ..moveTo(x + dx * s - 0.5 * s, base - 44 * s)
        ..lineTo(x + dx * s + 1.75 * s, base - 54 * s)
        ..lineTo(x + dx * s + 4 * s, base - 44 * s)
        ..close(),
      ink,
    );
  }
  // Yeşil Kubbe: dilimli külah.
  c.drawRect(Rect.fromLTWH(x + 34 * s, base - 22 * s, 14 * s, 16 * s), ink);
  c.drawPath(
    Path()
      ..moveTo(x + 34 * s, base - 22 * s)
      ..lineTo(x + 41 * s, base - 46 * s)
      ..lineTo(x + 48 * s, base - 22 * s)
      ..close(),
    ink,
  );
  final win = _hole(glow * a);
  for (final dx in [-44.0, -10.0, -2.0, 6.0, 48.0, 41.0]) {
    c.drawCircle(Offset(x + dx * s, base - 10 * s), 1.4 * s, win);
  }
}

/// Kubbenin tepesi yakından: karlı düz dam, iki yana inen dilimli kubbe,
/// ortada alem. [base] damın ortası (ayaklar burada), [w] damın yarı eni,
/// [finial] alemin boyu.
void _domeTip(
  Canvas c,
  Offset base,
  double a, {
  double w = 70,
  double finial = 150,
  bool snowTop = true,
}) {
  if (a <= 0) return;
  final ink = _ink(a);
  final y0 = base.dy;
  final spread = (400 - y0) * 1.1;
  // Alem: direk, top ve hilal (kubbenin ardında, ayaklar önünde).
  if (finial > 0) {
    c.drawLine(base, base - Offset(0, finial), _stroke(_ink(a), 5));
    c.drawCircle(base - Offset(0, finial * 0.45), 8, ink);
    c.drawCircle(base - Offset(0, finial * 0.7), 6, ink);
    final moon = base - Offset(0, finial + 6);
    c.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 14)),
        Path()..addOval(
          Rect.fromCircle(center: moon - const Offset(0, 6), radius: 12),
        ),
      ),
      ink,
    );
  }
  c.drawPath(
    Path()
      ..moveTo(base.dx - w, y0)
      ..lineTo(base.dx + w, y0)
      ..lineTo(base.dx + w + spread, 400)
      ..lineTo(base.dx - w - spread, 400)
      ..close(),
    ink,
  );
  // Yeşil dilimler: damdan aşağı açılan kaburgalar.
  final rib = _stroke(_hole(0.35 * a), 1.6);
  for (var i = -6; i <= 6; i++) {
    c.drawLine(
      Offset(base.dx + i * w / 6, y0 + 6),
      Offset(base.dx + i * (w + spread) / 6, 400),
      rib,
    );
  }
  // Damın kenarı: halka ve üstünde kar.
  c.drawRect(Rect.fromLTWH(base.dx - w - 6, y0, 2 * w + 12, 7), ink);
  if (snowTop) {
    c.drawLine(
      Offset(base.dx - w - 4, y0 + 1),
      Offset(base.dx + w + 4, y0 + 1),
      _stroke(_hole(0.75 * a), 2.2),
    );
  }
}

/// Ayna: ayaklı çerçeve, yüzü ışık tutar.
void _mirrorStand(
  Canvas c,
  Offset foot,
  double h,
  double tilt,
  double a, {
  double shine = 0.5,
}) {
  if (a <= 0) return;
  final ink = _ink(a);
  c.drawLine(foot, foot - Offset(0, h), _stroke(_ink(a), 4));
  c.drawLine(
    foot - const Offset(14, 0),
    foot + const Offset(14, 0),
    _stroke(_ink(a), 4),
  );
  c.save();
  c.translate(foot.dx, foot.dy - h - 16);
  c.rotate(tilt);
  final r = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-14, -22, 28, 44),
    const Radius.circular(12),
  );
  c.drawRRect(r, ink);
  c.drawRRect(r.deflate(4), _hole((0.25 + 0.7 * shine) * a));
  c.restore();
}

// -------------------------------------------------- perde 16: göğün katları

const _ridge = [
  (0.0, 300.0),
  (110.0, 286.0),
  (230.0, 266.0),
  (330.0, 256.0),
  (450.0, 240.0),
  (560.0, 250.0),
  (680.0, 282.0),
  (780.0, 298.0),
];

double _ridgeY(double x) {
  for (var i = 1; i < _ridge.length; i++) {
    final (x0, y0) = _ridge[i - 1];
    final (x1, y1) = _ridge[i];
    if (x <= x1) return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
  }
  return _ridge.last.$2;
}

/// Perde 16'nın satırları: dağ başında kam, katların anlatısı, ay ve
/// Demir Kazık, Yel Ana ve Hüma, son davul vuruşu.
void _gokLines(Canvas c, double time, double u) {
  // 0: dağların tepesinde yaşlı kam davul çalar; Sâye dinler.
  _satir(c, u, 0, (a) {
    _peaks(
      c,
      const [
        (0, 250),
        (90, 200),
        (180, 236),
        (300, 170),
        (420, 214),
        (560, 160),
        (680, 220),
        (780, 190),
      ],
      _ink(0.3 * a),
      base: 320,
    );
    final ridge = Path()..moveTo(0, 400);
    for (final (x, y) in _ridge) {
      ridge.lineTo(x, y);
    }
    ridge
      ..lineTo(780, 400)
      ..close();
    c.drawPath(ridge, _ink(a));
    const kx = 480.0;
    final ky = _ridgeY(kx) + 4;
    _kamFig(c, Offset(kx, ky), 170, time, a, flip: true);
    // Canlar göğe yükselir: davuldan süzülen ışık zerreleri.
    final drum = Offset(kx + 31 * 1.7, ky - 56 * 1.7);
    for (var i = 0; i < 7; i++) {
      final k = (time * 0.22 + i / 7) % 1;
      c.drawCircle(
        drum + Offset(math.sin(i * 2.3 + time) * 18, -k * 150),
        2.6,
        _hole(0.8 * a * (1 - k)),
      );
    }
    _tasvirSaye(c, Offset(250, _ridgeY(250) + 4), 1.25, time, a);
  });
  // 1: "En yüksek katta Ülgen, yerin dibinde Erlik."
  _satir(c, u, 1, (a) {
    _floor(c, a);
    // Yerin dibi: Erlik'in karanlığı, içinde iki kor göz.
    final pit = Path()..moveTo(330, 400);
    for (var x = 330.0; x <= 760; x += 22) {
      pit.lineTo(x, 300 + ((x / 22).round().isEven ? -10 : 8));
    }
    pit
      ..lineTo(760, 400)
      ..close();
    c.drawPath(pit, _ink(a));
    final eye = 0.5 + 0.4 * math.sin(time * 1.3);
    c.drawCircle(const Offset(530, 330), 3, _hole(eye * a));
    c.drawCircle(const Offset(556, 330), 3, _hole(eye * a));
    // Aradaki katlar.
    for (var k = 0; k < 3; k++) {
      _cloudBand(
        c,
        250 - k * 50,
        time + k,
        _ink((0.35 + k * 0.08) * a),
        x0: 330,
        x1: 760,
        depth: 10,
      );
    }
    // Göğün tepesinde Ülgen'in ışığı.
    _ulgenGlow(c, const Offset(545, 76), 48, time, a);
    _kamFig(c, const Offset(170, _sg + 12), 190, time, a);
  });
  // 2: Sâye yükselir; ay katı ve Demir Kazık'ın çevresinde dönen yıldızlar.
  _satir(c, u, 2, (a) {
    _cloudBand(c, 286, time, _ink(0.5 * a));
    _crescent(c, const Offset(170, 226), 34, _hole(0.65 * a));
    _cloudBand(c, 140, time + 1, _ink(0.42 * a));
    const pole = Offset(600, 82);
    c.drawLine(
      pole + const Offset(0, 20),
      const Offset(600, 142),
      _stroke(_ink(a), 5),
    );
    c.drawCircle(pole, 42, _stroke(_hole(0.25 * a), 1.4));
    c.drawCircle(pole, 66, _stroke(_hole(0.2 * a), 1.4));
    _starShape(c, pole, 22, _hole(a));
    for (var i = 0; i < 9; i++) {
      final ang = time * 0.45 + i * math.pi * 2 / 9;
      final r = i.isEven ? 66.0 : 42.0;
      _starShape(
        c,
        pole + Offset(math.cos(ang), math.sin(ang)) * r,
        8,
        _hole(0.9 * a),
        spin: ang,
      );
    }
    final rise = _span(u, 2.1, 2.85);
    final y = _sg + 12 - rise * 190;
    // Yükselişin izi.
    for (var i = 1; i < 5; i++) {
      c.drawCircle(
        Offset(390, y + i * 18),
        3.0 - i * 0.5,
        _hole(0.6 * a * rise),
      );
    }
    _tasvirSaye(c, Offset(390, y), 1.3, time, a);
  });
  // 3: Yel Ana katların arasında eser; Hüma süzülür, gölgesi bulutlara
  // düşer; kam anlatır.
  _satir(c, u, 3, (a) {
    _cloudFloor(c, a);
    const clouds = [330.0, 500.0, 670.0];
    for (final x in clouds) {
      _P._cloud(c, x, 262, 0.8, 0.5 * a);
    }
    final k = _span(u, 3.05, 3.95);
    final hx = 150 + k * 470;
    _humaFig(c, Offset(hx, 118), 2.3, time, a);
    // Gölgesi altındaki buluta düşer.
    var near = 1.0;
    var cx = clouds.first;
    for (final x in clouds) {
      final d = (hx - x).abs() / 90;
      if (d < near) {
        near = d;
        cx = x;
      }
    }
    c.drawOval(
      Rect.fromCenter(
        center: Offset(hx.clamp(cx - 50, cx + 50), 226),
        width: 110,
        height: 14,
      ),
      _ink(0.55 * a * (1 - near).clamp(0.0, 1.0)),
    );
    _yelAna(c, const Offset(60, 236), 130, time, a);
    _kamFig(c, const Offset(670, _sg + 6), 150, time, a, flip: true);
    _tasvirSaye(c, const Offset(560, _sg + 6), 1.1, time, a);
  });
  // 4: "Kandilciler kırık güneşin parçasını en yüksek kata taşıdı." Son
  // vuruş; Sâye bulutların üstüne fırlar.
  _satir(c, u, 4, (a) {
    _floor(c, a);
    for (final x in [300.0, 470.0, 640.0]) {
      _P._cloud(c, x, 236, 0.9, 0.6 * a);
    }
    // En yüksek kat: kırık güneşin parçası ve onu taşıyan Kandilci.
    _cloudBand(c, 112, time, _ink(0.45 * a), x0: 470, x1: 780, depth: 12);
    const shard = Offset(672, 62);
    c.drawCircle(
      shard,
      52,
      Paint()
        ..shader = ui.Gradient.radial(shard, 52, [
          const Color(0xFFFFF0C8).withValues(alpha: 0.8 * a),
          const Color(0x00FFE0A0),
        ]),
    );
    c.drawPath(
      Path()
        ..moveTo(shard.dx - 18, shard.dy - 16)
        ..lineTo(shard.dx + 20, shard.dy - 22)
        ..lineTo(shard.dx + 8, shard.dy - 2)
        ..lineTo(shard.dx + 16, shard.dy + 18)
        ..lineTo(shard.dx - 14, shard.dy + 10)
        ..close(),
      _hole(a),
    );
    _kandilciFig(c, const Offset(560, 116), 0.4, time, a, lit: false);
    // Kam son kez vurur.
    _kamFig(
      c,
      const Offset(130, _sg + 12),
      180,
      time,
      a,
      rate: 1.5,
      force: 1.6,
    );
    final k = _span(u, 4.15, 4.7);
    final p =
        Offset.lerp(const Offset(320, _sg + 12), const Offset(450, 202), k)! -
        Offset(0, math.sin(k * math.pi) * 50);
    for (var i = 1; i < 6; i++) {
      final q = Offset.lerp(const Offset(320, _sg), p, 1 - i * 0.15)!;
      c.drawCircle(
        q - const Offset(0, 30),
        2.6,
        _hole(0.5 * a * k * (1 - i / 6)),
      );
    }
    _tasvirSaye(c, p, 1.2, time, a);
  });
}

// ------------------------------------------------- perde 18: Ülgen'in kapısı

const _sugeToyon = _Look(
  hat: _Hat.helmet,
  garb: _Garb.kaftan,
  beard: _Beard.long,
  cape: true,
  broad: 1.2,
);

/// Ülgen'in kapısı: uzakta, içi aydınlık kemer; çevresine ışınlar.
void _ulgenGate(Canvas c, Offset base, double s, double time, double a) {
  if (a <= 0) return;
  final top = base - Offset(0, 220 * s);
  c.drawCircle(
    top + Offset(0, 80 * s),
    150 * s,
    Paint()
      ..shader = ui.Gradient.radial(top + Offset(0, 80 * s), 150 * s, [
        const Color(0xFFFFF6DC).withValues(alpha: 0.75 * a),
        const Color(0x00FFE0A0),
      ]),
  );
  final arch = Path()
    ..moveTo(base.dx - 60 * s, base.dy)
    ..lineTo(base.dx - 60 * s, top.dy + 60 * s)
    ..quadraticBezierTo(base.dx - 60 * s, top.dy, base.dx, top.dy - 10 * s)
    ..quadraticBezierTo(
      base.dx + 60 * s,
      top.dy,
      base.dx + 60 * s,
      top.dy + 60 * s,
    )
    ..lineTo(base.dx + 60 * s, base.dy);
  c.drawPath(arch, _stroke(_ink(a), 14 * s));
  c.drawPath(arch, _stroke(_hole(0.5 * a), 2));
  for (var i = 0; i < 7; i++) {
    c.drawCircle(
      Offset(
        base.dx + (i - 3) * 16 * s,
        top.dy - 30 * s - (3 - (i - 3).abs()) * 6 * s,
      ),
      3 * s,
      _hole(0.8 * a),
    );
  }
}

/// Kırık güneşin parçası: küçük bir güneş gibi yanar.
void _sunShard(Canvas c, Offset at, double r, double time, double a) {
  if (a <= 0) return;
  c.drawCircle(
    at,
    r * 3,
    Paint()
      ..shader = ui.Gradient.radial(at, r * 3, [
        const Color(0xFFFFF0C8).withValues(alpha: 0.85 * a),
        const Color(0x00FFD08A),
      ]),
  );
  final ray = _stroke(_hole(0.6 * a), 2.4);
  for (var i = 0; i < 10; i++) {
    final ang = i / 10 * math.pi * 2 + time * 0.4;
    c.drawLine(
      at + Offset(math.cos(ang), math.sin(ang)) * r * 1.3,
      at +
          Offset(math.cos(ang), math.sin(ang)) *
              r *
              (1.9 + 0.3 * math.sin(time * 3 + i)),
      ray,
    );
  }
  c.drawPath(
    Path()
      ..moveTo(at.dx - r, at.dy - r * 0.6)
      ..lineTo(at.dx + r * 0.9, at.dy - r)
      ..lineTo(at.dx + r * 0.3, at.dy - r * 0.1)
      ..lineTo(at.dx + r * 0.8, at.dy + r * 0.9)
      ..lineTo(at.dx - r * 0.7, at.dy + r * 0.5)
      ..close(),
    _hole(a),
  );
}

void _ulgenScene(Canvas c, double time, double u) {
  _P._c = c;
  // Göğün en üst katı: köşede Ülgen'in aydınlığı, aşağıda bulut tabanı.
  c.drawCircle(
    const Offset(690, 40),
    220,
    Paint()
      ..shader = ui.Gradient.radial(const Offset(690, 40), 220, [
        const Color(0xFFFFF4D8).withValues(alpha: 0.35),
        const Color(0x00FFE0A0),
      ]),
  );
  _cloudBand(c, 230, time, _ink(0.2));
  _cloudFloor(c, 0.9);
}

/// Perde 18'in satırları.
void _ulgenLines(Canvas c, double time, double u) {
  // 0: Yel Ana Sâye'yi eşiğe bırakıp gider; Sâye yalnız.
  _satir(c, u, 0, (a) {
    _cloudFloor(c, a);
    c.drawLine(
      const Offset(430, _sg + 1),
      const Offset(780, _sg + 1),
      _stroke(_hole(0.6 * a), 3),
    );
    final k = _span(u, 0.1, 0.95);
    _yelAna(
      c,
      Offset(420 - k * 300, 250 - k * 120),
      130 * (1 - 0.35 * k),
      time,
      a * (1 - 0.75 * k),
      flip: true,
    );
    _tasvirSaye(c, const Offset(540, _sg + 8), 1.4, time, a);
  });
  // 1: Ötede Ülgen'in kapısı; önünde kırık güneşin parçası.
  _satir(c, u, 1, (a) {
    _cloudFloor(c, a);
    _ulgenGate(c, const Offset(650, _sg + 2), 0.8, time, a);
    _sunShard(c, const Offset(520, 290), 18, time, a);
    _tasvirSaye(c, const Offset(200, _sg + 8), 1.5, time, a);
  });
  // 2: Kara bulutlar, Erlik'in fırtınası; şimşek çakar, Sâye'nin ışığı
  // titrer.
  _satir(c, u, 2, (a) {
    _cloudFloor(c, a);
    _ulgenGate(c, const Offset(650, _sg + 2), 0.8, time, 0.25 * a);
    for (final (x, y, s) in [
      (330.0, 150.0, 1.3),
      (520.0, 120.0, 1.5),
      (700.0, 170.0, 1.2),
      (430.0, 236.0, 1.4),
      (640.0, 262.0, 1.3),
    ]) {
      _P._cloud(c, x, y, s, a);
    }
    _bolt(
      c,
      const Offset(450, 210),
      const Offset(380, _sg),
      1,
      a * _flash(time, 0),
    );
    _bolt(
      c,
      const Offset(620, 130),
      const Offset(700, _sg),
      2,
      a * _flash(time, 0.45),
    );
    _bolt(
      c,
      const Offset(330, 140),
      const Offset(270, 300),
      3,
      a * _flash(time, 0.7),
    );
    final sx = 170.0, s = 1.6;
    _tasvirSaye(c, const Offset(170, _sg + 8), s, time, a);
    final jar = _sayeHand(Offset(sx, _sg + 8), s);
    final tremble = 0.5 + 0.5 * math.sin(time * 23) * math.sin(time * 9.7);
    _lampGlow(c, jar, 6, a * (0.4 + 0.6 * tremble), flick: 0.4 * tremble);
  });
  // 3: Hüma bulutların arasında süzülür; gölgesi buluttan buluta düşer.
  _satir(c, u, 3, (a) {
    _cloudFloor(c, a);
    const clouds = [
      (150.0, 262.0),
      (330.0, 238.0),
      (510.0, 262.0),
      (690.0, 238.0),
    ];
    for (final (x, y) in clouds) {
      _P._cloud(c, x, y, 0.9, 0.75 * a);
    }
    final k = _span(u, 3.05, 3.95);
    final hx = 110 + k * 560;
    _humaFig(c, Offset(hx, 110), 2.2, time, a);
    for (final (x, y) in clouds) {
      final near = (1 - (hx - x).abs() / 80).clamp(0.0, 1.0);
      if (near <= 0) continue;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + (hx - x) * 0.4, y - 40),
          width: 100,
          height: 12,
        ),
        _ink(0.6 * a * near),
      );
    }
    _tasvirSaye(c, const Offset(400, _sg + 8), 1.1, time, a);
  });
  // 4: Süge Toyon kötü ruhlara şimşek yağdırır; gök gürler.
  _satir(c, u, 4, (a) {
    _cloudFloor(c, a);
    final thunder = _flash(time, 0.2, rate: 1.1);
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _hole(0.25 * a * thunder));
    _P._cloud(c, 610, 200, 1.8, a);
    _person(
      c,
      const Offset(600, 188),
      150,
      a,
      _sugeToyon,
      flip: true,
      arm: -2.6,
      time: time,
    );
    const hand = Offset(566, 42);
    // Elindeki yıldırım: hep yanar.
    _bolt(c, hand + const Offset(14, 30), hand + const Offset(-10, -34), 9, a);
    for (final (to, seed) in [
      (const Offset(170, 300), 0.0),
      (const Offset(290, 310), 0.33),
      (const Offset(380, 290), 0.66),
    ]) {
      _bolt(c, hand, to, seed * 7 + 1, a * _flash(time, seed, rate: 1.1));
    }
    // Kötü ruhlar kaçışır.
    final flee = _span(u, 4.1, 4.9);
    for (var i = 0; i < 3; i++) {
      _person(
        c,
        Offset(
          330 - i * 105.0 - flee * 60,
          _sg + 8 + math.sin(time * 6 + i) * 3,
        ),
        96 - i * 6.0,
        a,
        _kormos,
        flip: true,
      );
    }
  });
}

// ----------------------------------------------------- perde 13: Şeb-i Arûs

/// Perde 13'ün satırları (2 ve 3 sahnenin şehriyle).
void _semaLines(Canvas c, double time, double u) {
  const g = _sg;
  // 0: Tulpar Sâye'yi sırtında bulutlardan indirir; ay ve kar ovası.
  _satir(c, u, 0, (a) {
    _snowPlain(c, time, a);
    c.drawCircle(const Offset(110, 66), 26, _hole(0.85 * a));
    _farCity(c, 690, 296, 0.55, a, glow: 0.5);
    final k = _span(u, 0.05, 0.85);
    final at = Offset(150 + k * 320, 205 + k * 157);
    _tulparFig(c, at, 120, time, a, spread: 0.45);
    _tasvirSaye(c, at + const Offset(-4, -66), 0.72, time, a);
  });
  // 1: Batıda Konya'nın kubbeleri; "Ustan orada," dedi Tulpar.
  _satir(c, u, 1, (a) {
    _snowPlain(c, time, a);
    c.drawCircle(const Offset(110, 66), 26, _hole(0.85 * a));
    final glow = 0.6 + 0.35 * math.sin(time * 2.2);
    c.drawCircle(
      const Offset(650, 280),
      120,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(650, 280), 120, [
          const Color(0xFFFFE6B0).withValues(alpha: 0.45 * a),
          const Color(0x00FFE0A0),
        ]),
    );
    _farCity(c, 640, 296, 1.1, a, glow: glow);
    const feet = Offset(290, g + 12);
    _tulparFig(c, feet, 150, time, a, spread: 0.15, flap: false);
    final saye = feet + const Offset(-4, -84);
    _tasvirSaye(c, saye, 0.8, time, a);
    // Kalbi küt küt atar.
    final beat = math.pow(math.max(0, math.sin(time * 7)), 6).toDouble();
    c.drawCircle(
      saye + const Offset(2, -40),
      2 + beat * 3,
      _hole(a * (0.4 + 0.6 * beat)),
    );
  });
  // 2: Şeb-i Arûs: semâhanede semâzenler döner.
  _satir(c, u, 2, (a) {
    _semazenPuppet(c, const Offset(390, g + 12), time * 3, a);
    c.save();
    c.translate(390, g + 12);
    c.scale(2.3);
    c.translate(-390, -(g + 12));
    _semazenPuppet(c, const Offset(390, g + 12), time * 3, a);
    c.restore();
  });
  // 3: Mevlânâ: "Bu benim düğün gecemdir."
  _satir(c, u, 3, (a) {
    _dervish(c, const Offset(390, g + 12), 260, a);
    c.drawCircle(const Offset(390, 70), 40, _hole(0.3 * a));
  });
  // 4: Kandilciler ustanın kandilini bu gece yakmaya hazırlanır; ustanın
  // kendisi sönmektedir.
  _satir(c, u, 4, (a) {
    _floor(c, a);
    _snowfall(c, time, a);
    final fade = _span(u, 4.2, 4.85);
    final ms = 0.88;
    _masterFig(
      c,
      const Offset(390, g + 12),
      ms,
      time,
      a * (1 - 0.3 * fade),
      lamp: true,
      snow: 0.6,
    );
    final hand = _masterHand(const Offset(390, g + 12), ms);
    // Kandil sönük; yalnız fitilde küçük bir kor.
    c.drawCircle(hand, 7, _ink(a));
    c.drawCircle(hand - const Offset(0, 6), 2.2, _hole(0.8 * a));
    _kandilciFig(c, const Offset(170, g + 12), 1.05, time, a, lift: -20);
    _kandilciFig(
      c,
      const Offset(620, g + 12),
      1.05,
      time,
      a,
      flip: true,
      lift: -20,
      seed: 1,
    );
    // Fenerlerinden ustanın kandiline uzanan ince ışık.
    final reach = _span(u, 4.15, 4.6);
    for (final from in [
      Offset(170 + 88 * 1.05, g + 12 - 168 * 1.05),
      Offset(620 - 88 * 1.05, g + 12 - 168 * 1.05),
    ]) {
      c.drawLine(
        from,
        Offset.lerp(from, hand, reach)!,
        _stroke(_hole(0.45 * a), 2),
      );
    }
  }, cover: 2);
  // 5: Ovada bir tepenin üstünde gök yeleli kurt; Sâye'yi görünce ulur.
  _satir(c, u, 5, (a) {
    _snowPlain(c, time, a);
    _farCity(c, 700, 296, 0.75, a, glow: 0.6);
    c.drawPath(
      Path()
        ..moveTo(270, g + 4)
        ..quadraticBezierTo(330, 250, 450, 236)
        ..quadraticBezierTo(560, 246, 640, g + 4)
        ..close(),
      _ink(a),
    );
    _cut(
      c,
      MythShapes.wolfHowl,
      const Offset(450, 240),
      150,
      a,
      eye: const Offset(36, -84),
    );
    // Uluma: ağzından açılan halkalar.
    final howl = _span(u, 5.15, 5.3) * (1 - _span(u, 5.85, 5.97));
    for (var i = 0; i < 3; i++) {
      c.drawArc(
        Rect.fromCircle(center: const Offset(520, 98), radius: 14 + i * 13.0),
        -1.6,
        1.4,
        false,
        _stroke(_hole(0.6 * a * howl), 2),
      );
    }
    _tasvirSaye(c, const Offset(130, g + 10), 1.3, time, a);
  });
}

// ------------------------------------------------------ perde 19: Yeşil Kubbe

void _kubbeScene(Canvas c, double time, double u) {
  _P._c = c;
  _fallLines(c, time, 0.6, snow: true, count: 40);
  c.drawCircle(const Offset(110, 60), 20, _hole(0.6));
  c.drawRect(const Rect.fromLTWH(0, _sg, 780, 50), _ink(0.9));
}

/// Perde 19'un satırları.
void _kubbeLines(Canvas c, double time, double u) {
  const g = _sg;
  // 0: Semâhanenin damından Yeşil Kubbe'ye bakar; ışık kubbeye sığmaz.
  _satir(c, u, 0, (a) {
    _snowfall(c, time, a);
    const dx = 560.0;
    const ds = 1.04;
    c.drawCircle(
      const Offset(dx, 190),
      190,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(dx, 190), 190, [
          const Color(0xFFFFF0C8).withValues(alpha: 0.75 * a),
          const Color(0x00FFE0A0),
        ]),
    );
    // Taşan ışık: kubbeden dışarı ışınlar.
    for (var i = 0; i < 14; i++) {
      final ang = -math.pi + i / 13 * math.pi;
      final len = 120 + 30 * math.sin(time * 2 + i * 1.7);
      c.drawLine(
        Offset(dx, 210) + Offset(math.cos(ang), math.sin(ang)) * 70,
        Offset(dx, 210) + Offset(math.cos(ang), math.sin(ang)) * len,
        _stroke(_hole(0.5 * a), 3),
      );
    }
    c.drawRect(Rect.fromLTWH(360, g, 420, 50), _ink(a));
    _greenDome(c, dx, a, scale: ds);
    // Dilimlerin arasından sızan ışık, aşağı damlar.
    for (var i = -2; i <= 2; i++) {
      c.drawLine(
        Offset(dx + i * 12.0 * ds, g - 124 * ds),
        Offset(dx + i * 2.0 * ds, g - 246 * ds),
        _stroke(_hole(0.85 * a), 2.2),
      );
    }
    for (var i = 0; i < 6; i++) {
      final k = (time * 0.4 + i / 6) % 1;
      c.drawCircle(
        Offset(dx + (i - 2.5) * 16, g - 120 * ds + k * 110),
        2.4,
        _hole(0.8 * a * (1 - k)),
      );
    }
    // Semâhanenin damı: küçük kubbeler, korkuluk.
    final roof = _ink(a);
    c.drawRect(const Rect.fromLTWH(0, 300, 360, 100), roof);
    c.drawArc(
      const Rect.fromLTWH(50, 262, 90, 76),
      math.pi,
      math.pi,
      true,
      roof,
    );
    c.drawArc(
      const Rect.fromLTWH(170, 276, 60, 48),
      math.pi,
      math.pi,
      true,
      roof,
    );
    for (var i = 0; i < 9; i++) {
      c.drawRect(Rect.fromLTWH(10 + i * 40.0, 312, 14, 22), _hole(0.25 * a));
    }
    c.drawLine(
      const Offset(0, 301),
      const Offset(360, 301),
      _stroke(_hole(0.6 * a), 2),
    );
    _tasvirSaye(c, const Offset(320, 304), 1.3, time, a);
  });
  // 1: Kandilciler ustayı kubbenin en tepesine çıkarmış; yanında
  // Kandilci Başı.
  _satir(c, u, 1, (a) {
    _snowfall(c, time, a);
    _domeTip(c, const Offset(400, 282), a, w: 160, finial: 176);
    _kandilciFig(c, const Offset(150, 352), 0.62, time, a * 0.85);
    _kandilciFig(
      c,
      const Offset(650, 352),
      0.62,
      time,
      a * 0.85,
      flip: true,
      seed: 1,
    );
    const mf = Offset(400, 286);
    _masterFig(c, mf, 0.76, time, a, lamp: true, snow: 0.7);
    _lampGlow(c, _masterHand(mf, 0.76), 5, a, flick: 0.15 * math.sin(time * 9));
    _kandilciBasi(c, const Offset(548, 286), 1.0, time, a, flip: true);
  }, cover: 3);
  // 2: Kandilci Başı güler: "Ben de bir zamanlar hayalîydim..." Kapalı
  // feneri, karda gölgesi yok; Sâye'nin gölgesi var.
  _satir(c, u, 2, (a) {
    c.drawRect(const Rect.fromLTWH(0, g + 12, 780, 50), _ink(0.28 * a));
    c.drawLine(
      const Offset(0, g + 12),
      const Offset(780, g + 12),
      _stroke(_ink(a), 2),
    );
    c.drawRect(const Rect.fromLTWH(0, 388, 780, 12), _ink(a));
    _snowfall(c, time, a);
    // Sâye'nin gölgesi: ay ışığında karın üstüne yatar.
    const sf = Offset(180, g + 12);
    c.save();
    c.translate(sf.dx, sf.dy);
    c.scale(1, -0.26);
    c.skew(1.2, 0);
    c.scale(1.5);
    _P._c = c;
    _P._saye(_ink(0.55 * a), _ink(0.55 * a), time, jar: 0);
    c.restore();
    _tasvirSaye(c, sf, 1.5, time, a);
    final laugh = 0.6 + 0.4 * math.sin(time * 1.3);
    _kandilciBasi(
      c,
      const Offset(500, g + 12),
      1.32,
      time,
      a,
      flip: true,
      laugh: laugh,
    );
  }, cover: 3);
  // 3: Ustanın kandili titrer, gece yarısı yakın; kavanozdaki ateşböcekleri
  // de titrer.
  _satir(c, u, 3, (a) {
    _snowfall(c, time, a);
    c.drawCircle(const Offset(400, 36), 16, _hole(0.8 * a));
    _domeTip(c, const Offset(560, 236), a, w: 100, finial: 120);
    const mf = Offset(530, 240);
    _masterFig(c, mf, 0.66, time, a, lamp: true, snow: 0.7);
    final f = (0.5 + 0.5 * math.sin(time * 13) * math.sin(time * 7.3)).clamp(
      0.0,
      1.0,
    );
    _lampGlow(
      c,
      _masterHand(mf, 0.66),
      6,
      a * (0.25 + 0.75 * f),
      flick: 0.5 * f,
    );
    _floor(c, a);
    const sf = Offset(190, g + 12);
    _tasvirSaye(c, sf, 1.9, time, a);
    // Kavanoz yakından: koyu cam, içinde titreyen ateşböcekleri.
    final jar = _sayeHand(sf, 1.9) + const Offset(10, 0);
    final glass = RRect.fromRectAndRadius(
      Rect.fromCenter(center: jar, width: 34, height: 40),
      const Radius.circular(12),
    );
    c.drawRRect(glass, _ink(0.75 * a));
    c.drawRRect(glass, _stroke(_hole(0.7 * a), 1.5));
    c.drawRect(
      Rect.fromCenter(center: jar - const Offset(0, 22), width: 22, height: 6),
      _ink(a),
    );
    for (var i = 0; i < 7; i++) {
      final p =
          jar +
          Offset(
            math.cos(i * 1.05 + time * 2) * 9 + math.sin(time * 29 + i) * 2.2,
            math.sin(i * 1.3 + time * 2.5) * 10 + math.cos(time * 31 + i) * 2.2,
          );
      final tw = 0.55 + 0.45 * math.sin(time * 17 + i * 2.1);
      c.drawCircle(
        p,
        2.4,
        Paint()..color = const Color(0xFFFFF0B0).withValues(alpha: a * tw),
      );
    }
  }, cover: 3);
}

// ------------------------------------------------------------- köprüler

/// Köprü 16: davulun vuruşlarıyla katlar aşılır; Demir Kazık'ın atları,
/// Yedi Karakçı, yada taşı.
void _bSkyLayers(Canvas c, double time, double u, double n) {
  final a0 = _heroA(u, 0);
  final a1 = _heroA(u, 1);
  final r = _span(u, 0.1, 0.92);
  // Davul vuruşlarıyla basamak basamak.
  final beat = math.pow(math.max(0, math.sin(time * 5)), 8).toDouble();
  c.save();
  c.translate(0, r * 260);
  // Bulut kapısı: iki bulut kümesinin arası.
  _P._cloud(c, 230, 214, 1.4, 0.75);
  _P._cloud(c, 560, 214, 1.4, 0.75);
  _cloudBand(c, 222, time, _ink(0.5), x0: 0, x1: 300, depth: 10);
  _cloudBand(c, 222, time, _ink(0.5), x0: 480, x1: 780, depth: 10);
  // Ay katı.
  _crescent(c, const Offset(130, 110), 28, _hole(0.6));
  _cloudBand(c, 40, time, _ink(0.35));
  // Yıldız katı.
  for (var i = 0; i < 14; i++) {
    _starShape(
      c,
      Offset(40 + (i * 131.0) % 700, -220 + (i * 53.0) % 150),
      3 + (i % 3).toDouble(),
      _hole(0.7),
    );
  }
  c.restore();
  // Kam aşağıda kalır; davulun sesi yükselir.
  final ka = a0 * (1 - _span(u, 0.25, 0.6));
  _cloudFloor(c, 0.9 * (1 - r));
  _kamFig(c, const Offset(110, _sg + 10), 160, time, ka);
  for (var i = 0; i < 3; i++) {
    final k = ((time * 1.2 + i / 3) % 1);
    c.drawArc(
      Rect.fromCircle(center: const Offset(390, 420), radius: 60 + k * 200),
      -2.4,
      1.7,
      false,
      _stroke(_hole(0.35 * a0 * (1 - k)), 2),
    );
  }
  // Demir Kazık, bağlı iki at, Yedi Karakçı.
  if (a1 > 0) {
    const pole = Offset(420, 48);
    _starShape(c, pole, 16, _hole(a1));
    c.drawLine(
      pole + const Offset(0, 16),
      const Offset(420, 218),
      _stroke(_ink(a1), 5),
    );
    _P._cloud(c, 420, 228, 2.1, 0.7 * a1);
    for (final (x, flip) in [(330.0, true), (520.0, false)]) {
      _cut(
        c,
        MythShapes.horse,
        Offset(x, 220),
        76,
        a1,
        flip: flip,
        eye: const Offset(48, -82),
        deco: false,
      );
      c.drawLine(
        Offset(x + (flip ? -26 : 26), 160),
        const Offset(420, 170),
        _stroke(_ink(0.8 * a1), 1.6),
      );
    }
    final adv = _span(u, 1.05, 1.5) * (1 - _span(u, 1.55, 1.9));
    const dipper = [
      Offset(0, 0),
      Offset(30, 8),
      Offset(58, 4),
      Offset(84, 14),
      Offset(92, 44),
      Offset(126, 52),
      Offset(130, 22),
    ];
    final at = Offset(40 + adv * 130, 60 + adv * 40);
    for (var i = 0; i < dipper.length; i++) {
      final p = at + dipper[i];
      if (i > 0) {
        c.drawLine(at + dipper[i - 1], p, _stroke(_ink(0.4 * a1), 1.2));
      }
      _starShape(c, p, 13, _ink(a1));
      c.drawCircle(p, 2.4, _hole(a1));
    }
    // Yada taşı: rüzgâr çağırır, Yel Ana'nın esişi döner.
    final wind = _span(u, 1.55, 1.9);
    for (var i = 0; i < 4; i++) {
      final y = 120 + i * 26.0;
      c.drawPath(
        Path()
          ..moveTo(560, y)
          ..cubicTo(
            620,
            y - 20,
            680,
            y + 20,
            760,
            y - 4 + math.sin(time * 3 + i) * 8,
          ),
        _stroke(_hole(0.55 * a1 * wind), 2),
      );
    }
  }
  // Sâye: basamak basamak yükselir, sonra atın sırtına tutunur.
  final start = Offset(300 + r * 90, _sg + 10 - r * 216 - beat * 6 * a0);
  final onHorse = _span(u, 1.05, 1.35);
  final p = Offset.lerp(start, const Offset(512, 178), onHorse)!;
  _sayeAt(c, p, time, s: 1.0);
  final stone = _span(u, 1.55, 1.75) * a1;
  if (stone > 0) {
    _lampGlow(c, p + const Offset(26, -46), 4, stone);
  }
}

/// Köprü 18: Hüma'nın gölgesi Sâye'ye düşer; şimşeklerin arasından koşar,
/// kırık güneşin parçası Ülgen'e karışır; Tulpar kapıda bekler.
void _bUlgen(Canvas c, double time, double u, double n) {
  final a0 = _heroA(u, 0);
  final a1 = _heroA(u, 1);
  _ulgenGlow(c, const Offset(700, 64), 40, time, 1);
  _ulgenGate(c, const Offset(722, _sg + 2), 0.7, time, 1);
  for (var i = 0; i < 8; i++) {
    _P._cloud(c, 20 + i * 110.0, _sg + 6, 0.85, 0.95);
  }
  _floor(c, 0.95);
  // Şimşekler.
  _bolt(
    c,
    const Offset(250, 30),
    const Offset(220, 300),
    4,
    a0 * _flash(time, 0.1),
  );
  _bolt(
    c,
    const Offset(420, 20),
    const Offset(470, 290),
    5,
    a0 * _flash(time, 0.55),
  );
  // Hüma geçer, gölgesi Sâye'nin başına düşer.
  final hk = _span(u, 0.04, 0.5);
  final hx = 40 + hk * 420;
  _humaFig(c, Offset(hx, 92), 1.6, time, a0);
  final run = _span(u, 0.35, 0.78);
  final sx = 160 + run * 270 - _span(u, 1.05, 1.4) * 20;
  final head = Offset(sx, _sg + 8 - 84 * 1.4 - 8);
  final over = (1 - (hx - sx).abs() / 70).clamp(0.0, 1.0) * a0;
  c.drawOval(
    Rect.fromCenter(center: head, width: 70, height: 10),
    _ink(0.6 * over),
  );
  // Kut: gölge düştükten sonra Sâye'nin çevresinde ışık.
  final kut = _span(u, 0.25, 0.4) * (1 - _span(u, 1.2, 1.6));
  if (kut > 0) {
    c.drawCircle(
      Offset(sx, _sg - 50),
      80,
      Paint()
        ..shader = ui.Gradient.radial(Offset(sx, _sg - 50), 80, [
          const Color(0xFFFFF0C8).withValues(alpha: 0.5 * kut),
          const Color(0x00FFE0A0),
        ]),
    );
  }
  // Kırık güneşin parçası: dokununca göğe, Ülgen'in ışığına yükselir.
  final rise = _span(u, 0.8, 0.98);
  _sunShard(
    c,
    Offset.lerp(const Offset(480, 300), const Offset(700, 64), rise)!,
    16 * (1 - 0.5 * rise),
    time,
    a0 * (1 - rise * 0.9),
  );
  // Tulpar kapının önünde: kanatlarını açar, başını eğer.
  _tulparFig(
    c,
    const Offset(568, _sg + 10),
    160,
    time,
    a1,
    flip: true,
    spread: 0.1 + 0.6 * _span(u, 1.1, 1.5),
    bow: 0.13 * _span(u, 1.45, 1.75),
    flap: false,
  );
  _sayeAt(c, Offset(sx, _sg + 8), time, s: 1.4);
}

/// Köprü 19: şadırvanın ayı, aynalar, gümüş kapı; kandiller koridorunda
/// kafesler; kubbenin kaburgaları; tepede üç ayna.
void _bKubbe(Canvas c, double time, double u, double n) {
  final a = [for (var k = 0; k < 4; k++) _heroA(u, k.toDouble())];
  c.drawCircle(const Offset(80, 50), 20, _hole(0.75));
  _snowfall(c, time, 1.4);
  // 0: şadırvan, aynalar, gümüş kapı.
  if (a[0] > 0) {
    final k = a[0];
    _floor(c, k);
    final ink = _ink(k);
    // Şadırvan: havuz, direkler, kubbecik.
    c.drawPath(
      Path()
        ..moveTo(100, _sg)
        ..lineTo(112, 316)
        ..lineTo(268, 316)
        ..lineTo(280, _sg)
        ..close(),
      ink,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(190, 316), width: 156, height: 14),
      _hole(0.55 * k),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(206, 316), width: 22, height: 6),
      _hole(k),
    );
    for (final x in [118.0, 262.0]) {
      c.drawRect(Rect.fromLTWH(x - 4, 214, 8, 102), ink);
    }
    c.drawPath(
      Path()
        ..moveTo(96, 220)
        ..quadraticBezierTo(190, 130, 284, 220)
        ..close(),
      ink,
    );
    c.drawLine(
      const Offset(190, 176),
      const Offset(190, 148),
      _stroke(_ink(k), 3),
    );
    // Gümüş kapı.
    final door = _span(u, 0.75, 0.95);
    c.drawPath(
      Path()
        ..moveTo(620, _sg)
        ..lineTo(620, 230)
        ..quadraticBezierTo(670, 170, 720, 230)
        ..lineTo(720, _sg)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(634, _sg)
        ..lineTo(634, 236)
        ..quadraticBezierTo(670, 192, 706, 236)
        ..lineTo(706, _sg)
        ..close(),
      _hole((0.15 + 0.7 * door) * k),
    );
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 2; j++) {
        _starShape(
          c,
          Offset(652 + j * 36.0, 256 + i * 24.0),
          6,
          _ink(0.8 * k),
          points: 8,
        );
      }
    }
    // Aynalar ve ay ışığının yolu.
    final beam = _span(u, 0.15, 0.8);
    const pts = [
      Offset(206, 314),
      Offset(392, 236),
      Offset(520, 196),
      Offset(670, 270),
    ];
    _mirrorStand(
      c,
      const Offset(392, _sg),
      98,
      -0.5,
      k,
      shine: beam > 0.3 ? 1 : 0.2,
    );
    _mirrorStand(
      c,
      const Offset(520, _sg),
      138,
      0.6,
      k,
      shine: beam > 0.6 ? 1 : 0.2,
    );
    final total = beam * 3;
    for (var i = 0; i < 3; i++) {
      final f = (total - i).clamp(0.0, 1.0);
      if (f <= 0) break;
      c.drawLine(
        pts[i],
        Offset.lerp(pts[i], pts[i + 1], f)!,
        _stroke(_hole(0.85 * k), 3),
      );
    }
    _sayeAt(c, const Offset(350, _sg + 8), time, s: 1.3, a: k);
  }
  // 1: Kandiller koridoru: kafesler açılır, ışıklar kavanoza dolar.
  if (a[1] > 0) {
    final k = a[1];
    _floor(c, k);
    for (var i = 0; i < 6; i++) {
      final x = 40 + i * 140.0;
      c.drawRect(Rect.fromLTWH(x - 8, 120, 16, _sg - 120), _ink(k));
      if (i < 5) {
        c.drawArc(
          Rect.fromLTWH(x, 70, 140, 100),
          math.pi,
          math.pi,
          false,
          _stroke(_ink(k), 10),
        );
        final lx = x + 70;
        c.drawLine(Offset(lx, 70), Offset(lx, 112), _stroke(_ink(k), 1.5));
        c.drawRect(
          Rect.fromCenter(center: Offset(lx, 120), width: 14, height: 16),
          _ink(k),
        );
        _lampGlow(c, Offset(lx, 120), 3, 0.6 * k);
      }
    }
    final sx = 150 + _span(u, 1.05, 1.9) * 60;
    final jar = _sayeHand(Offset(sx, _sg + 8), 1.4);
    for (var i = 0; i < 3; i++) {
      final cx = 360 + i * 140.0;
      const cy = 300.0;
      final open = _span(u, 1.15 + i * 0.18, 1.32 + i * 0.18);
      final fly = _span(u, 1.3 + i * 0.18, 1.6 + i * 0.18);
      c.drawRect(Rect.fromLTWH(cx - 30, cy, 60, _sg - cy), _ink(k));
      final bars = _stroke(_ink(k), 2);
      for (var j = -2; j <= 2; j++) {
        c.drawLine(
          Offset(cx + j * 11.0, cy),
          Offset(cx + j * 7.0, cy - 50),
          bars,
        );
      }
      c.drawArc(
        Rect.fromLTWH(cx - 26, cy - 72, 52, 44),
        math.pi,
        math.pi,
        false,
        bars,
      );
      c.drawLine(Offset(cx - 26, cy - 1), Offset(cx + 26, cy - 1), bars);
      // Kapı: yana açılır.
      c.drawLine(
        Offset(cx + 24, cy),
        Offset(cx + 24 + 30 * open, cy - 44 + 10 * open),
        _stroke(_ink(k), 3),
      );
      // Işık: kime ait olduğunu hatırlar, kavanoza uçar.
      if (fly < 1) {
        final from = Offset(cx, cy - 26);
        final p =
            Offset.lerp(from, jar, fly)! -
            Offset(0, math.sin(fly * math.pi) * 80);
        _lampGlow(c, p, 5, k * (1 - fly * 0.7));
      }
    }
    _lampGlow(c, jar, 4, k * _span(u, 1.5, 1.9));
    _sayeAt(c, Offset(sx, _sg + 8), time, s: 1.4, a: k);
  }
  // 2: Kubbenin yeşil kaburgalarına tutunarak tırmanır; ışık dalga dalga
  // yükselir.
  if (a[2] > 0) {
    final k = a[2];
    const apex = Offset(400, 36);
    final cone = Path()
      ..moveTo(110, 400)
      ..quadraticBezierTo(230, 140, apex.dx, apex.dy)
      ..quadraticBezierTo(570, 140, 690, 400)
      ..close();
    c.drawPath(cone, _ink(k));
    c.save();
    c.clipPath(cone);
    for (var j = 0; j < 4; j++) {
      final y = 400 - ((time * 32 + j * 48) % 190);
      final f = 1 - (400 - y) / 190;
      c.drawLine(Offset(0, y), Offset(780, y), _stroke(_hole(0.6 * k * f), 5));
    }
    c.restore();
    for (var i = 0; i <= 10; i++) {
      c.drawLine(
        apex,
        Offset(110 + i * 58.0, 400),
        _stroke(_hole(0.35 * k), 2),
      );
    }
    const rib0 = Offset(284, 400);
    final t = 0.12 + 0.58 * _span(u, 2.05, 2.92);
    final p = Offset.lerp(rib0, apex, t)!;
    _sayeAt(c, p, time, s: 1.2, a: k, rot: 0.3);
  }
  // 3: Tepede üç ayna; Kandilci Başı yüzyıllar sonra ilk kez kendi
  // gölgesini görür.
  if (a[3] > 0) {
    final k = a[3];
    const base = Offset(390, 330);
    _domeTip(c, base, k, w: 330, finial: 0, snowTop: false);
    c.drawRect(Rect.fromLTWH(0, base.dy, 780, 20), _ink(0.3 * k));
    c.drawLine(
      Offset(0, base.dy),
      Offset(780, base.dy),
      _stroke(_hole(0.7 * k), 2),
    );
    final turn = _span(u, 3.05, 3.4);
    final lit = _span(u, 3.35, 3.6);
    const mirrors = [
      (130.0, 70.0, -0.4),
      (300.0, 92.0, 0.3),
      (640.0, 70.0, -0.3),
    ];
    const target = Offset(470, 220);
    for (final (x, h, tilt) in mirrors) {
      _mirrorStand(
        c,
        Offset(x, base.dy),
        h,
        tilt * (x == 300 ? turn : 1),
        k,
        shine: lit,
      );
      c.drawLine(
        Offset(x, base.dy - h - 16),
        Offset.lerp(Offset(x, base.dy - h - 16), target, lit)!,
        _stroke(_hole(0.7 * k), 2.5),
      );
    }
    // Gölgesi: ilk kez karın üstüne düşer.
    final shade = _span(u, 3.5, 3.9);
    if (shade > 0) {
      c.save();
      c.translate(470, base.dy + 2);
      c.scale(1, -0.24);
      c.skew(-1.3, 0);
      c.scale(0.9);
      _P._c = c;
      _P._lamplighter(_ink(0.6 * k * shade), _ink(0.6 * k * shade));
      c.restore();
    }
    _kandilciBasi(c, Offset(470, base.dy + 4), 0.9, time, k, flip: true);
    _sayeAt(c, Offset(262, base.dy + 6), time, s: 1.15, a: k);
  }
}

// ------------------------------------------------------------- son perde

/// Son perdenin yakın tasvirlerinde kubbenin tepesi.
void _endTop(Canvas c, double time, double a) {
  _snowfall(c, time, a);
  _domeTip(c, const Offset(390, _sg + 12), a, w: 300, finial: 196);
}

/// Son perdenin yolu: yeni yağmış karın üstünde ufka uzanan iz.
void _endRoad(Canvas c, double a) {
  c.drawPath(
    Path()
      ..moveTo(330, _sg + 12)
      ..quadraticBezierTo(560, _sg - 40, 760, _sg - 120)
      ..lineTo(760, _sg - 110)
      ..quadraticBezierTo(560, _sg - 20, 450, _sg + 12)
      ..close(),
    _hole(0.6 * a),
  );
}

/// Yolun ortası (t: 0 başı, 1 ufku).
Offset _endRoadAt(double t) {
  const p0 = Offset(390, _sg + 12);
  const p1 = Offset(560, _sg - 30);
  const p2 = Offset(760, _sg - 115);
  final m = 1 - t;
  return p0 * (m * m) + p1 * (2 * m * t) + p2 * (t * t);
}
