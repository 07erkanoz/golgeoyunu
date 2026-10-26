part of 'perde.dart';

// Ötüken, Ak Ana'nın Denizi, Erlik'in Katı ve Ergenekon perdelerinin
// tasvirleri: oturan kişi, davullu kam, Karabasan, kara kaz, ak kanatlı
// Umay, başını kaldıran at, kafes, yeraltının soğuk bezi, ihtiyar demirci.

/// Sâye: kavanozunun ışığı [jar] ile kısılır (saklanırken söner); [flip]
/// sola bakar, [rot] gövdeyi ayak noktasından döndürür.
void _sayeJ(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  double jar = 1,
  bool flip = false,
  double rot = 0,
}) {
  if (a <= 0) return;
  _P._c = c;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  _P._puppet(
    c,
    Offset.zero,
    time,
    0.3,
    a,
    (ink, hole) => _P._saye(ink, hole, time, jar: jar),
    scale: s,
    flip: flip,
    rod: false,
  );
  c.restore();
}

/// Sâye'nin gözyaşı: yanağından süzülen iki ışık damlası.
void _tears(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a, {
  bool flip = false,
}) {
  if (a <= 0) return;
  final d = flip ? -1.0 : 1.0;
  for (var i = 0; i < 2; i++) {
    final k = (time * 0.6 + i * 0.5) % 1;
    final at = feet + Offset(d * 7 * s, (-62 + k * 22) * s);
    c.drawOval(
      Rect.fromCenter(center: at, width: 2.4 * s, height: 3.6 * s),
      _hole(a * (1 - k) * 0.95),
    );
  }
}

/// Oturan kişi: kalçası [seat]'te. Üst beden [_person]'dan (bel çizgisinin
/// üstü); bağdaş kurmuş dizler öne uzanır ya da [hang] ile etek daldan
/// sarkar.
void _seated(
  Canvas c,
  Offset seat,
  double h,
  double a,
  _Look l, {
  bool flip = false,
  double time = 0,
  double arm = 0,
  bool hang = false,
}) {
  if (a <= 0) return;
  final hh = h * (1 + math.max(0.0, l.broad - 1.1) * 0.6);
  c.save();
  c.clipRect(
    Rect.fromLTRB(seat.dx - hh, seat.dy - hh * 1.6, seat.dx + hh, seat.dy),
  );
  _person(
    c,
    Offset(seat.dx, seat.dy + hh * 0.46),
    h,
    a,
    l,
    flip: flip,
    time: time,
    arm: arm,
  );
  c.restore();
  final d = flip ? -1.0 : 1.0;
  final ink = _ink(a);
  if (hang) {
    c.drawPath(
      Path()
        ..moveTo(seat.dx - d * 0.1 * hh, seat.dy - 0.03 * hh)
        ..lineTo(seat.dx + d * 0.12 * hh, seat.dy - 0.03 * hh)
        ..quadraticBezierTo(
          seat.dx + d * 0.2 * hh,
          seat.dy + 0.16 * hh,
          seat.dx + d * 0.16 * hh,
          seat.dy + 0.32 * hh,
        )
        ..lineTo(seat.dx - d * 0.06 * hh, seat.dy + 0.32 * hh)
        ..close(),
      ink,
    );
    _punchRow(
      c,
      Offset(seat.dx - d * 0.04 * hh, seat.dy + 0.29 * hh),
      Offset(seat.dx + d * 0.14 * hh, seat.dy + 0.29 * hh),
      4,
      0.9,
      a,
    );
  } else {
    final x0 = seat.dx - d * 0.1 * hh;
    final x1 = seat.dx + d * 0.3 * hh;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          math.min(x0, x1),
          seat.dy - 0.12 * hh,
          math.max(x0, x1),
          seat.dy,
        ),
        Radius.circular(0.06 * hh),
      ),
      ink,
    );
    _punchRow(
      c,
      Offset(seat.dx, seat.dy - 0.03 * hh),
      Offset(seat.dx + d * 0.24 * hh, seat.dy - 0.03 * hh),
      4,
      0.9,
      a,
    );
  }
}

/// Kam: tüylü başlık, cübbe; bir elinde çerçeve davul, ötekinde tokmak.
/// [beat] 0-1 tokmağın davula inişi (1'de vurur); [seated] bağdaş kurar.
/// Boyu (ayakta) [h] piksel.
void _kamOrman(
  Canvas c,
  Offset feet,
  double h,
  double a,
  double time, {
  bool flip = false,
  bool seated = false,
  double beat = 0,
  double speak = 0,
}) {
  if (a <= 0) return;
  final s = h / 116;
  final ink = _ink(a);
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.3 + feet.dx) * 0.8);
  c.scale(flip ? -s : s, s);
  if (seated) c.translate(0, 40);
  c.save();
  if (seated) c.clipRect(const Rect.fromLTRB(-80, -200, 80, -40));
  c.drawPath(MythFigures.kamSilhouette, ink);
  c.restore();
  // Cübbe süsü: göğüste zımba gülü, etekte delik sırası.
  _rosette(c, const Offset(-1, -66), 6, a);
  _punchRow(c, const Offset(-12, -46), const Offset(12, -46), 6, 1.1, a);
  if (seated) {
    c.drawRRect(
      RRect.fromLTRBR(-34, -54, 36, -40, const Radius.circular(7)),
      ink,
    );
    _punchRow(c, const Offset(-26, -44), const Offset(28, -44), 7, 1.0, a);
  }
  // Konuşurken başı hafifçe sallanır: ağzın önünde ince ses çizgileri.
  if (speak > 0) {
    final p = _stroke(_hole(0.7 * a * speak), 1.4);
    for (var i = 0; i < 3; i++) {
      final r = 8.0 + i * 6 + (time * 14) % 6;
      c.drawArc(
        Rect.fromCircle(center: const Offset(8, -98), radius: r),
        -0.5,
        1.0,
        false,
        p,
      );
    }
  }
  // Çerçeve davul: sol elde, gövdenin önünde; derisinde ışık deliği
  // çemberi.
  final drum = Rect.fromCenter(
    center: const Offset(26, -64),
    width: 26,
    height: 34,
  );
  c.drawOval(drum, ink);
  c.drawOval(drum.deflate(4), _stroke(_hole(0.55 * a), 1.2));
  _rosette(c, drum.center, 6, a);
  if (beat > 0.85) {
    c.drawOval(drum.inflate(5), _stroke(_hole(a * (beat - 0.85) * 5), 1.6));
  }
  // Tokmak: sağ elden davula iner.
  final hand = const Offset(-22, -56);
  final ang = -1.9 + beat * 1.6;
  c.drawLine(
    hand,
    hand + Offset(math.cos(ang), math.sin(ang)) * 34,
    _stroke(_ink(a), 3),
  );
  c.restore();
}

/// Karabasan: uyuyanın göğsüne çöken kara ağırlık. Dalgalanan bir kütle,
/// [dir] yönüne uzanan kolları, açılıp kapanan ışık gözleri. [scatter]
/// 0-1 ışıkta parçalanıp dağılır.
void _karabasan(
  Canvas c,
  Offset center,
  double r,
  double a,
  double time, {
  double dir = 1,
  double reach = 1,
  double scatter = 0,
}) {
  if (a <= 0) return;
  final k = r / 62;
  if (scatter > 0) {
    final n = 16;
    for (var i = 0; i < n; i++) {
      final ang = i / n * math.pi * 2 + i * 0.3;
      final d = (20 + scatter * 170) * k;
      c.drawCircle(
        center + Offset(math.cos(ang) * d, math.sin(ang) * d * 0.6),
        (18 - 12 * scatter) * k,
        _ink(a * (1 - scatter)),
      );
    }
    if (scatter >= 1) return;
  }
  final body = a * (1 - scatter);
  final blob = Path();
  for (var i = 0; i <= 20; i++) {
    final t = i / 20 * math.pi * 2;
    final rr = (62 + 12 * math.sin(time * 3 + i * 1.7)) * k * (1 - scatter);
    final p = center + Offset(math.cos(t) * rr * 1.2, math.sin(t) * rr * 0.75);
    i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
  }
  c.drawPath(blob..close(), _ink(body));
  final arm = _stroke(_ink(body), 7 * k);
  for (var i = 0; i < 4; i++) {
    arm.strokeWidth = (7.0 - i) * k;
    final rch = (70 + 20 * math.sin(time * 2.4 + i)) * k * reach;
    final o = center + Offset(dir * 50 * k, (-30 + i * 18) * k);
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(
          o.dx + dir * rch * 0.5,
          o.dy - 20 * k + i * 2 * k,
          o.dx + dir * rch,
          o.dy + (10 - i * 4) * k,
        ),
      arm,
    );
  }
  final blink = (time % 4) < 0.15 ? 0.2 : 1.0;
  for (final dx in [-14.0, 14.0]) {
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset((dx + 20 * dir) * k, -16 * k),
        width: 14 * k,
        height: 6 * blink * k,
      ),
      _hole(body),
    );
  }
}

/// Kara kaz: yandan, uzun boyunlu; kanatları çırpar. Gövde ortası [at],
/// [s] ölçek (1'de kanat açıklığı ~110 birim).
void _goose(
  Canvas c,
  Offset at,
  double s,
  double a,
  double time, {
  bool flip = false,
}) {
  if (a <= 0) return;
  final ink = _ink(a);
  c.save();
  c.translate(at.dx, at.dy + math.sin(time * 2) * 3);
  c.scale(flip ? -s : s, s);
  final f = math.sin(time * 4.2);
  Path wing(double lift) => Path()
    ..moveTo(12, -4)
    ..quadraticBezierTo(0, -34 * lift, -26, -54 * lift)
    ..lineTo(-36, -50 * lift)
    ..quadraticBezierTo(-22, -26 * lift, -16, -2)
    ..close();
  // Uzaktaki kanat, gövde, yakındaki kanat.
  c.drawPath(wing(0.9 * f + 0.1), _ink(a * 0.8));
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: 64, height: 22), ink);
  c.drawPath(
    Path()
      ..moveTo(-28, -4)
      ..lineTo(-44, -8)
      ..lineTo(-40, 2)
      ..lineTo(-28, 4)
      ..close(),
    ink,
  );
  c.drawPath(
    Path()
      ..moveTo(22, -8)
      ..quadraticBezierTo(40, -12, 52, -14)
      ..lineTo(54, -8)
      ..quadraticBezierTo(40, -4, 24, 4)
      ..close(),
    ink,
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(56, -12), width: 14, height: 10),
    ink,
  );
  c.drawPath(
    Path()
      ..moveTo(61, -15)
      ..lineTo(72, -11)
      ..lineTo(61, -9)
      ..close(),
    ink,
  );
  c.drawCircle(const Offset(57, -13), 1.6, _hole(a));
  final near = wing(-0.9 * f + 0.1);
  c.drawPath(near, ink);
  c.drawPath(near, _rim(a));
  _punchRow(c, const Offset(-14, 2), const Offset(18, 2), 5, 1.2, a);
  c.restore();
}

/// Umay: daldaki ak kanatlı ana. Kanatları perdeye kesilmiş ışık (ak),
/// tüyleri mürekkep çizgi; kendisi dalda oturur, eteği sarkar.
void _umay(
  Canvas c,
  Offset seat,
  double h,
  double a,
  double time, {
  bool flip = false,
  double spread = 1,
}) {
  if (a <= 0) return;
  final d = flip ? -1.0 : 1.0;
  final sh = seat + Offset(-d * 0.04 * h, -0.3 * h);
  final flap = math.sin(time * 1.3) * 0.06;
  for (final side in [1.0, -1.0]) {
    c.save();
    c.translate(sh.dx, sh.dy);
    c.scale(side * h * 1.25 / 100, h * 1.25 / 100);
    c.rotate(0.15 - 0.3 * spread + flap);
    final w = Path()
      ..moveTo(0, 0)
      ..cubicTo(20, -30, 60, -60, 100, -62)
      ..cubicTo(92, -50, 96, -40, 86, -34)
      ..cubicTo(80, -24, 82, -16, 70, -10)
      ..cubicTo(60, -2, 56, 6, 40, 8)
      ..cubicTo(26, 12, 12, 10, 0, 8)
      ..close();
    c.drawPath(w, _hole(0.9 * a));
    c.drawPath(w, _stroke(_ink(a), 2.6));
    final feather = _stroke(_ink(0.8 * a), 1.6);
    for (var i = 0; i < 5; i++) {
      final t = (i + 1) / 6;
      c.drawLine(
        Offset(10 + 20 * t, -6 - 10 * t),
        Offset(30 + 64 * t, -54 + 52 * t),
        feather,
      );
    }
    c.restore();
  }
  _seated(
    c,
    seat,
    h,
    a,
    const _Look(hat: _Hat.hotoz, garb: _Garb.dress, belt: true),
    flip: flip,
    time: time,
    hang: true,
    arm: -0.6,
  );
}

/// At: başı boyun çivisinden iner ya da kalkar ([lift] 0 başı yerde, 1
/// başı dik); uzun yelesi dalgalanır. [h] piksel boy, ayaklar [feet]'te.
void _horseLift(
  Canvas c,
  Offset feet,
  double h,
  double a,
  double lift,
  double time, {
  bool flip = false,
  double speak = 0,
}) {
  if (a <= 0) return;
  final s = h / 100;
  final ink = _ink(a);
  const pivot = Offset(14, -60);
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(flip ? -s : s, s);
  // Gövde: baş ve boyun dışında.
  c.save();
  c.clipRect(
    const Rect.fromLTRB(14, -130, 90, -50),
    clipOp: ui.ClipOp.difference,
  );
  c.drawPath(MythShapes.horse, ink);
  c.restore();
  _punchRow(c, const Offset(-34, -62), const Offset(8, -66), 7, 1.4, a);
  _rosette(c, const Offset(-12, -52), 6, a);
  // Baş ve boyun: çividen döner.
  c.save();
  c.translate(pivot.dx, pivot.dy);
  c.rotate((1 - lift) * 0.95 + math.sin(time * 1.1) * 0.03);
  c.translate(-pivot.dx, -pivot.dy);
  c.save();
  c.clipRect(const Rect.fromLTRB(14, -130, 90, -50));
  c.drawPath(MythShapes.horse, ink);
  c.restore();
  // Uzun yele: boynun sırtından dalgalanarak dökülür.
  const crest = [
    Offset(16, -74),
    Offset(24, -84),
    Offset(33, -92),
    Offset(42, -98),
  ];
  final strand = _stroke(_ink(a), 2.2);
  for (var i = 0; i < 12; i++) {
    final t = i / 11;
    final f = (t * 3).floor().clamp(0, 2);
    final p = Offset.lerp(crest[f], crest[f + 1], t * 3 - f)!;
    final w = math.sin(time * 2.6 + i * 0.7);
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..cubicTo(
          p.dx - 8,
          p.dy + 2 + w * 2,
          p.dx - 14,
          p.dy + 10 - w * 2,
          p.dx - 22 - t * 6,
          p.dy + 18 + w * 3,
        ),
      strand,
    );
  }
  c.drawCircle(const Offset(47, -86), 2.4, _hole(a));
  if (speak > 0) {
    final p = _stroke(_hole(0.7 * a * speak), 1.4);
    for (var i = 0; i < 3; i++) {
      final r = 6.0 + i * 5 + (time * 12) % 5;
      c.drawArc(
        Rect.fromCircle(center: const Offset(60, -76), radius: r),
        -0.6,
        1.2,
        false,
        p,
      );
    }
  }
  c.restore();
  // Boyun çivisi: Karagöz tasvirindeki gibi eklem.
  c.drawCircle(pivot, 6, ink);
  c.drawCircle(pivot, 2, _hole(0.7 * a));
  c.restore();
}

/// Tavandan zincirle sarkan kafes; içinde çırpınan bir can ışığı.
/// [open] 0-1 kapısı açılır, ışık kuş olup çıkar.
void _hangCage(
  Canvas c,
  Offset top,
  double w,
  double a,
  double time, {
  double light = 1,
}) {
  if (a <= 0) return;
  final ink = _stroke(_ink(a), 2.4);
  final h = w * 1.3;
  c.drawLine(Offset(top.dx, 0), top, _stroke(_ink(a), 1.6));
  final body = top + Offset(0, w * 0.35);
  c.drawArc(
    Rect.fromCenter(center: body, width: w, height: w * 0.7),
    math.pi,
    math.pi,
    false,
    ink,
  );
  for (var i = 0; i <= 4; i++) {
    final x = body.dx - w / 2 + i * w / 4;
    c.drawLine(Offset(x, body.dy), Offset(x, body.dy + h - w * 0.35), ink);
  }
  c.drawLine(
    Offset(body.dx - w / 2 - 3, top.dy + h),
    Offset(body.dx + w / 2 + 3, top.dy + h),
    _stroke(_ink(a), 4),
  );
  if (light > 0) {
    final at = Offset(
      body.dx + math.sin(time * 1.7 + top.dx) * w * 0.12,
      body.dy + h * 0.45 + math.cos(time * 2.3 + top.dx) * 4,
    );
    c.drawCircle(
      at,
      w * 0.4,
      Paint()
        ..shader = ui.Gradient.radial(at, w * 0.4, [
          const Color(0xFFFFE6B0).withValues(alpha: 0.7 * a * light),
          const Color(0x00FFE6B0),
        ]),
    );
    c.drawCircle(at, w * 0.1, _hole(a * light));
  }
}

/// Yeraltının bezi: kandil ışığı soğur, perde koyu ve soğuk olur (Erlik'in
/// ülkesi); ortada soluk bir ay ışığı kalır.
void _coldCloth(Canvas c, double a) {
  if (a <= 0) return;
  c.drawRect(
    const Rect.fromLTWH(0, 0, 780, 400),
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(400, 220),
        480,
        [
          const Color(0xFF7C8898).withValues(alpha: 0.72 * a),
          const Color(0xFF3A4252).withValues(alpha: 0.85 * a),
          const Color(0xFF0E1018).withValues(alpha: 0.95 * a),
        ],
        const [0, 0.55, 1],
      ),
  );
}

/// İhtiyar demirci: börklü, uzun sakallı, sırtı eğik; sönmüş ocağının
/// başında oturur. [arm] kolunu kaldırır (çekiç tutar gibi).
const _ihtiyar = _Look(
  hat: _Hat.bork,
  garb: _Garb.kaftan,
  beard: _Beard.long,
  bent: 0.22,
);

/// Sönmüş ocak: taş ocak, içinde kara kömür, yanında örs ve yere serili
/// körük. [fire] 0-1 ateş (0 soğuk).
void _coldForge(Canvas c, double x, double a, double time, {double fire = 0}) {
  if (a <= 0) return;
  const g = PerdePainter._ground;
  final ink = _ink(a);
  // Taş ocak.
  c.drawPath(
    Path()
      ..moveTo(x - 46, g + 10)
      ..lineTo(x - 40, g - 40)
      ..lineTo(x + 40, g - 40)
      ..lineTo(x + 46, g + 10)
      ..close(),
    ink,
  );
  for (var i = 0; i < 4; i++) {
    c.drawLine(
      Offset(x - 40 + i * 2.0, g - 26 + i * 12.0),
      Offset(x + 40 - i * 2.0, g - 26 + i * 12.0),
      _stroke(_hole(0.35 * a), 1.2),
    );
  }
  // Kömür: söndüyse kara topaklar, yanarsa kor.
  for (var i = 0; i < 6; i++) {
    final at = Offset(x - 28 + i * 11.0, g - 44 - (i % 2) * 4.0);
    c.drawCircle(at, 7, ink);
    if (fire > 0) c.drawCircle(at, 3.5, _hole(a * fire));
  }
  if (fire > 0) {
    for (var i = 0; i < 3; i++) {
      final f = math.sin(time * 9 + i * 2) * 4;
      c.drawPath(
        Path()
          ..moveTo(x - 24 + i * 22.0, g - 46)
          ..quadraticBezierTo(
            x - 22 + i * 22.0 + f,
            g - 70 * fire,
            x - 14 + i * 22.0,
            g - 90 * fire,
          )
          ..quadraticBezierTo(
            x - 8 + i * 22.0,
            g - 64 * fire,
            x - 4 + i * 22.0,
            g - 46,
          )
          ..close(),
        _hole(a * fire * 0.9),
      );
    }
  } else {
    // Soğuk ocaktan ince, sönük bir duman teli.
    final p = _stroke(_ink(0.35 * a), 2);
    c.drawPath(
      Path()
        ..moveTo(x, g - 50)
        ..quadraticBezierTo(x + 10 + math.sin(time) * 6, g - 80, x - 4, g - 110)
        ..quadraticBezierTo(
          x - 14,
          g - 130,
          x + 4 + math.sin(time * 0.8) * 6,
          g - 150,
        ),
      p,
    );
  }
}

/// Yere serili deri körük: [pump] 0 sönük (yassı), 1 şişkin.
void _bellows(Canvas c, Offset at, double w, double a, double pump) {
  if (a <= 0) return;
  final ink = _ink(a);
  final top = 4 + 16 * pump;
  c.drawPath(
    Path()
      ..moveTo(at.dx - w / 2, at.dy)
      ..lineTo(at.dx + w / 2, at.dy)
      ..lineTo(at.dx + w / 2 + 14, at.dy - 3)
      ..lineTo(at.dx + w / 2, at.dy - 6)
      ..quadraticBezierTo(at.dx, at.dy - top * 2, at.dx - w / 2, at.dy - top)
      ..close(),
    ink,
  );
  c.drawLine(
    Offset(at.dx - w / 2, at.dy - top),
    Offset(at.dx - w / 2 - 12, at.dy - top - 8),
    _stroke(_ink(a), 3),
  );
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(at.dx - w / 2 + 8 + i * w / 4, at.dy - 2),
      Offset(at.dx - w / 2 + 8 + i * w / 4, at.dy - top * 0.6 - 2),
      _stroke(_hole(0.35 * a), 1),
    );
  }
}

// ---------------------------------------------------------------- Ötüken

/// Ötüken: kök Sâye'yi sarıp ışığa çeker; şafakta orman; Kül Tigin'in
/// taşı ve dibinde oturan kam; Hayat Ağacı'nın dalında ak kanatlı Umay;
/// Karabasan sağdan sürünür, çöker; yapraklardan süzülen ışıkta geri
/// çekilir.
void _otukenScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  final c = canvas;
  const g = PerdePainter._ground;
  // 0: yerin altı. Tavandan kökler sarkar; biri kıpırdar, Sâye'yi sarar ve
  // yukarı, ışığa çeker.
  final under = 1 - _span(u, 0.85, 1.1);
  final forest = _span(u, 0.9, 1.4);
  if (under > 0) {
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 70), _ink(under));
    final root = _stroke(_ink(under), 5);
    for (var i = 0; i < 9; i++) {
      if (i == 4) continue;
      final x = 50.0 + i * 85;
      root.strokeWidth = 7 - (i % 3) * 1.5;
      final path = Path()..moveTo(x, 60);
      for (var y = 60.0; y < 300 - (i % 4) * 40; y += 20) {
        path.lineTo(x + math.sin(y / 30 + i) * 10, y);
      }
      c.drawPath(path, root);
    }
    final wiggle = 1 - _span(u, 0.05, 0.3);
    final wrap = _span(u, 0.1, 0.38);
    final climb = _span(u, 0.38, 0.92);
    const s = 1.7;
    final feet = Offset(390 + math.sin(time * 2) * 2, 340 - climb * 130);
    // Yukarıdan sızan ışık.
    c.drawCircle(
      const Offset(390, 40),
      30 + 26 * climb,
      _hole((0.25 + 0.4 * climb) * under),
    );
    // Ana kök: tavandan iner, kıvrılarak Sâye'nin beline dolanır.
    final waist = feet + const Offset(0, -38 * s);
    final main = Path()..moveTo(390, 60);
    for (var y = 60.0; y <= waist.dy; y += 8) {
      final k = (y - 60) / math.max(1, waist.dy - 60);
      main.lineTo(
        390 +
            math.sin(y / 26 + time * 3) * (3 + 10 * wiggle) * (1 - k) +
            14 * k,
        y,
      );
    }
    final rootP = _stroke(_ink(under), 10);
    c.drawPath(main, rootP);
    final coil = Rect.fromCenter(center: waist, width: 46, height: 16);
    final coil2 = Rect.fromCenter(
      center: feet + const Offset(0, -16 * s),
      width: 40,
      height: 14,
    );
    // Arkadaki halka (Sâye'nin ardında), sonra Sâye, sonra öndeki halka.
    rootP.strokeWidth = 7;
    c.drawArc(coil, math.pi, math.pi * wrap, false, rootP);
    c.drawArc(coil2, math.pi, math.pi * wrap, false, rootP);
    _sayeJ(c, feet, s, time, under);
    // Öndeki halkalar gövdenin önünde seçilsin: ışık kesikli kenar.
    final edge = _stroke(_hole(0.7 * under), 10);
    for (final r in [coil, coil2]) {
      c.drawArc(r, 0.1, (math.pi - 0.2) * wrap, false, edge);
      c.drawArc(r, 0, math.pi * wrap, false, rootP);
    }
  }
  if (forest <= 0) return;
  // Uzak orman: kayınlar ve çamlar, arada kuşlar (öndekiler seçilsin diye
  // soluk).
  for (var i = 0; i < 12; i++) {
    final x = 20.0 + i * 68 + (i % 3) * 9;
    final h = 150.0 + (i * 37 % 60);
    final a = forest * (0.3 + (i % 2) * 0.12);
    if (i.isEven) {
      for (var k = 0; k < 4; k++) {
        final y = g - h + k * h / 5;
        c.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x - 18 - k * 6, y + h / 4)
            ..lineTo(x + 18 + k * 6, y + h / 4)
            ..close(),
          _ink(a),
        );
      }
    } else {
      c.drawRect(Rect.fromLTWH(x - 4, g - h, 8, h), _ink(a));
      c.drawOval(
        Rect.fromCenter(center: Offset(x, g - h), width: 70, height: 60),
        _ink(a * 0.8),
      );
    }
  }
  for (var i = 0; i < 4; i++) {
    final k = (time * 0.06 + i / 4) % 1;
    _shape(
      c,
      i.isEven ? MythShapes.birdGlide : MythShapes.birdFlap,
      Offset(k * 820 - 20, 80 + i * 22 + math.sin(time + i) * 6),
      12,
      _ink(forest * 0.6),
    );
  }
  // 1: şafak. Ufukta ağaran gün.
  final dawn = _span(u, 1.0, 1.6) * (1 - _span(u, 2.6, 3.2));
  if (dawn > 0) {
    c.drawCircle(const Offset(640, g), 70, _hole(0.35 * dawn));
    c.drawCircle(const Offset(640, g), 110, _hole(0.12 * dawn));
  }
  // 3-7: Hayat Ağacı sağ ortada yükselir.
  final tree = _span(u, 3.0, 3.5);
  const tx = 610.0;
  if (tree > 0) {
    final ink = _ink(tree);
    c.drawPath(
      Path()
        ..moveTo(tx - 34, g)
        ..quadraticBezierTo(tx - 16, g - 120 * tree, tx - 10, g - 240 * tree)
        ..lineTo(tx + 10, g - 240 * tree)
        ..quadraticBezierTo(tx + 16, g - 120 * tree, tx + 34, g)
        ..close(),
      ink,
    );
    final branch = _stroke(_ink(tree), 8);
    for (var i = 0; i < 6; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final y = g - 120 - i * 22.0;
      final len = (120 - i * 12) * tree;
      branch.strokeWidth = 9.0 - i;
      final end = Offset(tx + side * len, y - 36 - i * 4);
      c.drawPath(
        Path()
          ..moveTo(tx, y)
          ..quadraticBezierTo(tx + side * len * 0.5, y - 4, end.dx, end.dy),
        branch,
      );
      // Dallarda can kuşları: ışık delikleri.
      c.drawOval(
        Rect.fromCenter(
          center: end + const Offset(0, -6),
          width: 11,
          height: 7,
        ),
        _hole(tree * (0.5 + 0.3 * math.sin(time * 2 + i))),
      );
    }
    c.drawOval(
      Rect.fromCenter(
        center: Offset(tx, g - 268 * tree),
        width: 280 * tree,
        height: 84 * tree,
      ),
      _ink(tree * 0.9),
    );
    for (var i = 0; i < 7; i++) {
      c.drawCircle(
        Offset(tx - 100 + i * 33.0, g - 268 * tree + math.sin(i * 1.9) * 18),
        3,
        _hole(0.6 * tree),
      );
    }
    // Umay: sol dalda oturur, ak kanatları açık.
    final umay = _span(u, 3.25, 3.6);
    _umay(
      c,
      Offset(tx - 96, g - 178),
      100,
      umay,
      time,
      spread: 0.7 + 0.3 * umay,
    );
  }
  // 6-7: yapraklardan süzülen gün ışığı.
  final beams = _span(u, 6.0, 6.4);
  if (beams > 0) {
    for (final (x0, x1, w) in [
      (290.0, 350.0, 90.0),
      (110.0, 150.0, 30.0),
      (450.0, 500.0, 34.0),
      (630.0, 680.0, 36.0),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(x0 - w * 0.3, 0)
          ..lineTo(x0 + w * 0.3, 0)
          ..lineTo(x1 + w * 0.5, g)
          ..lineTo(x1 - w * 0.5, g)
          ..close(),
        _hole(beams * 0.32),
      );
    }
  }
  c.drawRect(Rect.fromLTWH(0, g, 780, 50), _ink(forest));
  // 2-7: Kül Tigin'in taşı, oyma harfler; dibinde yaşlı kam oturur.
  final stone = _span(u, 2.0, 2.35);
  if (stone > 0) {
    final rr = RRect.fromRectAndCorners(
      const Rect.fromLTWH(30, g - 230, 104, 230),
      topLeft: const Radius.circular(34),
      topRight: const Radius.circular(34),
    );
    c.drawRRect(rr, _ink(stone));
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 4; col++) {
        final h = (row * 7 + col * 13) % 5;
        final at = Offset(44.0 + col * 21, g - 190 + row * 20.0);
        c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..lineTo(at.dx + 4 + h, at.dy + 6)
            ..lineTo(at.dx + (h.isEven ? 0 : 8), at.dy + 11),
          _stroke(_hole(stone * 0.85), 2),
        );
      }
    }
    // Kam: söylediği satırlarda (2, 4, 6) ağzından ses çizgileri.
    final speak = math.max(
      _line(u, 2),
      math.max(_span(u, 4.55, 4.75) * (1 - _span(u, 4.85, 5.0)), _line(u, 6)),
    );
    _kamOrman(
      c,
      const Offset(196, g + 8),
      250,
      stone,
      time,
      seated: true,
      speak: speak,
    );
  }
  // 4-7: Karabasan Sâye'nin çıktığı yerden, topraktan sızar; 5'te
  // kabarıp üstüne eğilir; 6'da ışıktan geri çekilir, toprağa çöker; 7'de
  // kaybolur.
  final dark = _span(u, 4.0, 4.3) * (1 - _span(u, 6.6, 7.1));
  if (dark > 0) {
    final ooze = _span(u, 4.05, 4.8);
    final loom = _span(u, 5.05, 5.6) * (1 - _span(u, 6.1, 6.5));
    final back = _span(u, 6.1, 6.9);
    final r = 30 + 32 * ooze + 30 * loom - 40 * back;
    c.save();
    c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 4));
    _karabasan(
      c,
      Offset(
        470 - 30 * loom + 20 * back,
        g + 30 - 76 * ooze - 60 * loom + 60 * back,
      ),
      r,
      dark,
      time,
      dir: -1,
      reach: (0.4 + 0.6 * ooze) * (1 - 0.8 * back),
    );
    c.restore();
  }
  // Sâye: 1'de topraktan çıkar; 2'de kama döner; 3'te Umay'a bakar; 5'te
  // geri çekilir; 6-7'de ışık huzmesinde yürür.
  final sa = _span(u, 1.0, 1.15);
  if (sa > 0) {
    final rise = _span(u, 1.02, 1.3);
    final shrink = _span(u, 5.05, 5.5) * (1 - _span(u, 6.0, 6.3));
    final walk = _span(u, 6.3, 7.9);
    final x = 345 - 30 * shrink + 25 * walk;
    final flip = u >= 2.1 && u < 3.0;
    c.save();
    c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
    _sayeJ(c, Offset(x, g + 12 + (1 - rise) * 160), 1.7, time, sa, flip: flip);
    c.restore();
  }
}

// ---------------------------------------------------- Ak Ana'nın Denizi

/// Kişi: Kayra Han'ın ilk yarattığı; yalın başlı, kısa sakallı, kısa
/// giysili (Erlik olmadan önce).
const _kisi = _Look(hat: _Hat.hair, garb: _Garb.tunic, beard: _Beard.short);

/// Dünyanın ilk suyu: [top]'tan aşağı mürekkep su, derine indikçe koyu;
/// yüzeyde dalga, içinde yatay ışık kırışıkları (kum tepesi gibi değil, su
/// gibi okunsun).
void _firstWater(Canvas c, double time, double top, double a) {
  if (a <= 0) return;
  final surface = Path()..moveTo(0, 400);
  for (var x = 0.0; x <= 780; x += 10) {
    surface.lineTo(
      x,
      top + math.sin(time * 1.6 + x / 30) * 3 + math.sin(time + x / 13) * 1.2,
    );
  }
  surface
    ..lineTo(780, 400)
    ..close();
  c.drawPath(surface, _ink(0.5 * a));
  c.drawRect(Rect.fromLTWH(0, top + 60, 780, 400 - top), _ink(0.2 * a));
  c.drawRect(Rect.fromLTWH(0, top + 110, 780, 400 - top), _ink(0.2 * a));
  // Işık kırışıkları: kısa, kesik yatay çizgiler; derine indikçe seyrek.
  for (var row = 0; row < 6; row++) {
    final y = top + 10 + row * 20.0 + row * row * 2;
    final p = _stroke(_hole(a * (0.45 - row * 0.06)), 2 - row * 0.2);
    for (var i = 0; i < 9; i++) {
      final x = (i * 97.0 + row * 41 + time * (14 + row * 3)) % 860 - 40;
      final w = 26.0 - row * 3;
      c.drawLine(
        Offset(x, y + math.sin(time * 2 + i + row) * 2),
        Offset(x + w, y + math.sin(time * 2 + i + row + 0.6) * 2),
        p,
      );
    }
  }
}

/// Ak Ana suyun içinden yükselir: [rise] 0 suyun dibinde, 1 belinden
/// yukarısı suyun üstünde (ya da [full] ile bütün boyu). Başının ardında
/// ışık hâlesi.
void _akAnaRise(
  Canvas c,
  double x,
  double top,
  double h,
  double a,
  double rise,
  double time, {
  bool full = false,
  bool flip = true,
  double arm = 0,
}) {
  if (a <= 0 || rise <= 0) return;
  final out = full ? 1.0 : 0.62;
  final feet = Offset(x, top + h * (1.05 - out * rise));
  final head = feet + Offset(0, -h * 0.94);
  c.drawCircle(head, h * 0.12, _hole(0.4 * a * rise));
  c.save();
  c.clipRect(Rect.fromLTWH(0, 0, 780, top + 4));
  _person(c, feet, h, a, _akAna, flip: flip, time: time, arm: arm);
  c.restore();
  // Suyun altındaki etek: soluk.
  c.save();
  c.clipRect(Rect.fromLTWH(0, top + 4, 780, 400));
  _person(c, feet, h, a * 0.35, _akAna, flip: flip, time: time, arm: arm);
  c.restore();
}

void _akAnaScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  final c = canvas;
  const g = PerdePainter._ground;
  const top = 262.0;
  // 0: Hayat Ağacı'nın kökleri yerin dibine iner; Sâye köklerin arasından
  // aşağı süzülür, kulağını bir taşa dayar; taşın ardında su sesi, sonra
  // suyun içinde ışıktan bir ana: "Hoş geldin, kızım."
  final under = 1 - _span(u, 0.86, 1.08);
  if (under > 0) {
    c.drawRect(const Rect.fromLTWH(0, 0, 780, 400), _ink(0.42 * under));
    // Taşın ardındaki su oyuğu: perdenin ışığı.
    final cave = Path()
      ..moveTo(560, g)
      ..quadraticBezierTo(560, 120, 680, 110)
      ..quadraticBezierTo(790, 110, 790, g)
      ..close();
    c.drawPath(
      cave,
      Paint()..color = const Color(0xFFF2B46A).withValues(alpha: 0.75 * under),
    );
    final listen = _span(u, 0.4, 0.55);
    for (var i = 0; i < 4; i++) {
      final k = (time * 0.5 + i / 4) % 1;
      c.drawArc(
        Rect.fromCenter(
          center: const Offset(600, 250),
          width: 40 + k * 260,
          height: 20 + k * 120,
        ),
        -1.3,
        2.6,
        false,
        _stroke(_hole(under * (1 - k) * (0.3 + 0.6 * listen)), 2),
      );
    }
    c.drawRect(Rect.fromLTWH(560, g - 40, 230, 60), _ink(0.6 * under));
    // Sudan bir ses: ışıktan bir kadın beliriyor.
    final voice = _span(u, 0.62, 0.85);
    if (voice > 0) {
      _shape(
        c,
        MythShapes.akAna,
        const Offset(690, g - 30),
        160,
        _hole(0.75 * voice * under),
      );
    }
    // Kökler: tavandan iner, dallanır.
    final root = _stroke(_ink(under), 8);
    for (var i = 0; i < 7; i++) {
      final x = 40.0 + i * 78;
      root.strokeWidth = 11 - (i % 3) * 2.5;
      final p = Path()..moveTo(x, 0);
      for (var y = 0.0; y <= g; y += 18) {
        p.lineTo(x + math.sin(y / 40 + i * 1.3) * 16 + y * 0.08, y);
      }
      c.drawPath(p, root);
    }
    // Taş: kulağını dayadığı kaya.
    c.drawPath(
      Path()
        ..moveTo(430, g + 10)
        ..quadraticBezierTo(420, 190, 480, 168)
        ..quadraticBezierTo(560, 150, 590, 200)
        ..quadraticBezierTo(610, 270, 600, g + 10)
        ..close(),
      _ink(under),
    );
    c.drawPath(
      Path()
        ..moveTo(470, 200)
        ..lineTo(500, 240)
        ..lineTo(490, 290),
      _stroke(_hole(0.4 * under), 1.6),
    );
    c.drawRect(const Rect.fromLTWH(0, g, 780, 60), _ink(under));
    // Sâye kökler arasından süzülür, sonra taşa eğilir.
    final slide = _span(u, 0.04, 0.4);
    final lean = _span(u, 0.42, 0.55);
    final feet = Offset(
      150 + 232 * slide,
      60 + (g + 12 - 60) * math.sin(slide * math.pi / 2),
    );
    _sayeJ(
      c,
      feet,
      1.8,
      time,
      under,
      rot: 0.5 * (1 - slide) * (slide > 0 ? 1 : 0) + 0.22 * lean,
    );
  }
  if (u < 0.86) return;
  final sea = _span(u, 0.86, 1.08);
  // 1-4: uçsuz bucaksız ilk su.
  _firstWater(c, time, top, sea);
  // Kayra Han: suyun üstünde uçan kara kaz (1-3); 1'de yanında Kişi.
  final goose = _span(u, 1.05, 1.35) * (1 - _span(u, 3.85, 4.1));
  if (goose > 0) {
    final fly = _span(u, 1.05, 1.95);
    final gx = u < 2 ? 90 + 300 * fly : 390 - 140 * _span(u, 2.0, 2.4);
    final gy = 120 + math.sin(time * 0.7) * 8 - 30 * _span(u, 2.0, 2.4);
    _goose(c, Offset(gx, gy), 1.5, goose, time);
  }
  // Kişi: 1'de kazın yanında uçar; 3'te kazdan yükseğe çıkmak ister, suya
  // düşer, dibe dalar, toprakla çıkar, bir avucunu ağzına saklar.
  final kisi =
      _span(u, 1.15, 1.45) * (1 - _span(u, 1.82, 1.97)) +
      _span(u, 3.0, 3.2) * (1 - _span(u, 3.9, 4.05));
  if (kisi > 0) {
    if (u < 3) {
      final fly = _span(u, 1.05, 1.95);
      _person(
        c,
        Offset(30 + 300 * fly, 196 + math.sin(time * 0.9) * 6),
        120,
        kisi,
        _kisi,
        rot: 1.45,
        arm: -1.4,
        time: time,
      );
    } else {
      final climb = _span(u, 3.05, 3.3);
      final fall = _span(u, 3.3, 3.48);
      final dive = _span(u, 3.48, 3.65);
      final surface = _span(u, 3.65, 3.8);
      final hide = _span(u, 3.8, 3.95);
      double x, y, rot;
      if (u < 3.3) {
        x = 400 + 40 * climb;
        y = 150 - 110 * climb;
        rot = 1.45 - 1.2 * climb;
      } else if (u < 3.48) {
        x = 440 + 20 * fall;
        y = 40 + (top + 30 - 40) * fall * fall;
        rot = 0.25 + 2.6 * fall;
      } else if (u < 3.65) {
        x = 460;
        y = top + 30 + 90 * dive;
        rot = 2.85 + 0.29 * dive;
      } else {
        x = 460 + 20 * surface;
        y = top + 140 - 76 * surface;
        rot = math.pi * (1 - surface);
      }
      // Suya düştüğü yerde halkalar.
      final splash = _span(u, 3.44, 3.5) * (1 - _span(u, 3.6, 3.75));
      for (var i = 0; i < 3; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(460, top),
            width: 40 + i * 50 + 60 * fall,
            height: 8 + i * 6,
          ),
          _stroke(_hole(0.8 * splash), 2),
        );
      }
      // Suyun altında soluk, üstünde koyu.
      final wet = u >= 3.48;
      for (final above in [true, false]) {
        c.save();
        if (wet) {
          c.clipRect(
            above
                ? const Rect.fromLTWH(0, 0, 780, top + 3)
                : const Rect.fromLTWH(0, top + 3, 780, 400),
          );
        } else if (!above) {
          c.restore();
          continue;
        }
        _person(
          c,
          Offset(x, y),
          140,
          kisi * (above ? 1 : 0.45),
          _kisi,
          rot: rot,
          arm: -2.3 * surface * (1 - hide) - 2.8 * hide,
          time: time,
        );
        c.restore();
      }
      // Avuç toprak: önce elinde, sonra ağzına saklanır.
      if (surface > 0) {
        final hand = Offset(x + 30, y - 128 + 26 * hide);
        final earth = Offset.lerp(hand, Offset(x + 10, y - 120), hide)!;
        c.drawCircle(earth, 9 - 4 * hide, _ink(kisi));
        for (var i = 0; i < 3; i++) {
          c.drawCircle(
            earth + Offset(-3.0 + i * 3, -2.0 + (i % 2) * 3),
            1.1,
            _hole(0.6 * kisi * (1 - hide)),
          );
        }
        if (hide > 0.9) {
          c.drawCircle(Offset(x + 9, y - 121), 2, _hole(kisi));
        }
      }
    }
  }
  // Ak Ana: 1'de yarıya dek sudan çıkmış konuşur; 2'de bütün boyuyla
  // yükselir, "Yarat" der, suya döner; 4'te yeniden konuşur.
  final speak1 = _span(u, 1.0, 1.25) * (1 - _span(u, 1.85, 2.0));
  _akAnaRise(c, 650, top, 230, speak1, speak1, time);
  final rise2 = _span(u, 2.05, 2.35) * (1 - _span(u, 2.7, 2.95));
  if (rise2 > 0) {
    final point = _span(u, 2.3, 2.42) * (1 - _span(u, 2.6, 2.72));
    _akAnaRise(c, 560, top, 250, 1, rise2, time, full: true, arm: -1.6 * point);
    final word = _span(u, 2.35, 2.45) * (1 - _span(u, 2.6, 2.75));
    if (word > 0) {
      final from = Offset(548, top + 250 * (1.05 - rise2) - 225);
      for (var i = 0; i < 7; i++) {
        final ang = math.pi + 0.15 + i * 0.09;
        c.drawLine(
          from + Offset(math.cos(ang), math.sin(ang)) * 30,
          from + Offset(math.cos(ang), math.sin(ang)) * (60 + 60 * word),
          _stroke(_hole(0.8 * word), 3),
        );
      }
    }
  }
  final speak4 = _span(u, 4.0, 4.2) * (1 - _span(u, 4.6, 4.85));
  _akAnaRise(c, 650, top, 230, speak4, speak4, time);
  // 4: çalınan ışıklar suyun dibine, Erlik'in ülkesine akar; Sâye derin bir
  // nefes alır, kendini suya bırakır.
  final a4 = _span(u, 4.0, 4.25);
  if (a4 > 0) {
    final rift = Path()
      ..moveTo(300, 400)
      ..lineTo(340, 378)
      ..lineTo(370, 384)
      ..lineTo(410, 366)
      ..lineTo(450, 380)
      ..lineTo(500, 372)
      ..lineTo(560, 400)
      ..close();
    c.drawPath(rift, _ink(a4));
    for (var i = 0; i < 12; i++) {
      final k = (time * 0.25 + i / 12) % 1;
      final start = Offset(120 + (i * 53) % 260.0, -10);
      final end = const Offset(430, 380);
      final p = Offset.lerp(start, end, k)!;
      c.drawCircle(p, 4, _hole(a4 * (k < 0.15 ? k / 0.15 : 1) * (1 - k * 0.6)));
      c.drawCircle(p, 10, _hole(0.15 * a4));
    }
    // Kıyıdaki kök: Sâye'nin durduğu yer.
    c.drawPath(
      Path()
        ..moveTo(0, top - 10)
        ..lineTo(150, top - 14)
        ..quadraticBezierTo(190, top - 8, 200, top + 30)
        ..lineTo(0, top + 40)
        ..close(),
      _ink(a4),
    );
    final breath = _span(u, 4.3, 4.55);
    final dive = _span(u, 4.58, 4.95);
    final x = 140 + 180 * dive;
    final y = top - 10 - 70 * math.sin(dive * math.pi) + dive * dive * 80;
    if (dive > 0.75) {
      final ring = (dive - 0.75) / 0.25;
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(300, top),
          width: 40 + 80 * ring,
          height: 10 + 8 * ring,
        ),
        _stroke(_hole(0.8 * (1 - ring * 0.5)), 2),
      );
    }
    c.save();
    if (dive > 0.7) c.clipRect(const Rect.fromLTWH(0, 0, 780, top + 2));
    _sayeJ(
      c,
      Offset(x, y - 6 * breath * (1 - dive)),
      1.5 + 0.06 * breath * (1 - dive),
      time,
      a4,
      rot: 2.6 * dive,
    );
    c.restore();
  }
}

// ---------------------------------------------------------- Erlik'in Katı

/// Erlik'in ülkesinin zemini: soğuk, koyu bez; tavandan sarkan kara
/// sarkıtlar, uzakta mürekkep köprüler, kayalık taban.
void _erlikGround(Canvas c, double time, double a) {
  if (a <= 0) return;
  const g = PerdePainter._ground;
  _coldCloth(c, a);
  // Uzak kayalar ve köprüler.
  _peaks(c, [
    (0, 150),
    (90, 210),
    (170, 170),
    (260, 230),
    (380, 190),
    (500, 240),
    (610, 180),
    (700, 220),
    (780, 160),
  ], _ink(0.3 * a));
  for (var i = 0; i < 2; i++) {
    c.drawArc(
      Rect.fromLTWH(140 + i * 330.0, 190, 220, 110),
      math.pi,
      math.pi,
      false,
      _stroke(_ink(0.35 * a), 5),
    );
  }
  // Sarkıtlar.
  final top = Path()..moveTo(0, 0);
  for (var i = 0; i <= 20; i++) {
    final x = i * 39.0;
    top
      ..lineTo(x + 8, 14 + (i % 3) * 6)
      ..lineTo(x + 18, 40 + ((i * 7) % 5) * 14)
      ..lineTo(x + 28, 16 + (i % 2) * 8);
  }
  top
    ..lineTo(780, 0)
    ..close();
  c.drawPath(top, _ink(a));
  // Taban: kayalık.
  c.drawPath(
    Path()
      ..moveTo(0, 400)
      ..lineTo(0, g - 4)
      ..quadraticBezierTo(120, g - 14, 240, g)
      ..quadraticBezierTo(390, g + 6, 540, g - 8)
      ..quadraticBezierTo(660, g - 16, 780, g - 2)
      ..lineTo(780, 400)
      ..close(),
    _ink(a),
  );
}

/// Erlik'in Katı: Kişi ışıktan kovulup karanlığa düşer, boynuzlu Erlik
/// olur; Sâye onun ülkesinde. Çalınan ışıklar buraya akar; Sâye ustanın
/// sıcaklığını taşta bulur. Çalkuyruk başını kaldırıp konuşur; Körmösler
/// ve can kafesleri.
void _erlikScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  final c = canvas;
  const g = PerdePainter._ground;
  _erlikGround(c, time, 1);
  // 0: yukarıda bir ışık yarığı; Kişi oradan düşer, dibe varınca Erlik
  // olur.
  final a0 = _heroA(u, 0);
  if (a0 > 0) {
    final fall = _span(u, 0.05, 0.4);
    final become = _span(u, 0.4, 0.62);
    final slit = 1 - _span(u, 0.35, 0.5);
    c.drawPath(
      Path()
        ..moveTo(440, 0)
        ..lineTo(520, 0)
        ..lineTo(490, 60)
        ..lineTo(470, 60)
        ..close(),
      _hole(0.75 * a0 * slit),
    );
    final x = 480.0;
    if (become < 1) {
      final y = 100 + (g + 12 - 100) * fall * fall;
      _person(
        c,
        Offset(x, y),
        150,
        a0 * (1 - become),
        _kisi,
        rot: (1 - fall) * 2.6 + fall * 0.0,
        time: time,
      );
    }
    if (become > 0) {
      _person(
        c,
        Offset(x, g + 12),
        150 + 110 * become,
        a0 * become,
        _erlik,
        flip: true,
        time: time,
      );
      // Kor gözler: karanlığın efendisi.
      c.drawCircle(
        Offset(x - 3, g + 12 - (150 + 110 * become) * 0.92),
        2.5,
        _hole(a0 * become),
      );
    }
    final sa = _span(u, 0.6, 0.8);
    _sayeJ(
      c,
      Offset(140 + 60 * _span(u, 0.6, 0.95), g + 12),
      1.8,
      time,
      a0 * sa,
    );
  }
  // 1: çalınan ışıklar buraya akar; Sâye bir taşa dokunur, ustanın
  // sıcaklığı; gözleri dolar.
  final a1 = _heroA(u, 1);
  if (a1 > 0) {
    for (var i = 0; i < 14; i++) {
      final k = (time * 0.18 + i / 14) % 1;
      final p = Offset(
        40 + k * 700,
        70 + math.sin(k * math.pi) * 120 + math.sin(time + i) * 6,
      );
      c.drawCircle(p, 4, _hole(a1 * 0.9));
      c.drawCircle(p, 11, _hole(a1 * 0.15));
    }
    // Ustanın izleri: taşa doğru giden ayak izleri.
    for (var i = 0; i < 5; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(520 + i * 46.0, g - 2 + (i % 2) * 4),
          width: 16,
          height: 5,
        ),
        _hole(0.3 * a1),
      );
    }
    // Taş: ortasında ustanın elinin sıcaklığı (sıcak bir ışık).
    final warm = _span(u, 1.3, 1.55);
    c.drawPath(
      Path()
        ..moveTo(380, g + 4)
        ..quadraticBezierTo(374, g - 110, 430, g - 130)
        ..quadraticBezierTo(492, g - 136, 500, g - 60)
        ..lineTo(504, g + 4)
        ..close(),
      _ink(a1),
    );
    final glow = Offset(432, g - 78);
    c.drawCircle(
      glow,
      40,
      Paint()
        ..shader = ui.Gradient.radial(glow, 40, [
          const Color(0xFFFFB060).withValues(alpha: 0.75 * a1 * warm),
          const Color(0x00FFB060),
        ]),
    );
    // Avuç izi: beş parmak deliği.
    c.drawCircle(glow, 6, _hole(a1 * warm));
    for (var i = 0; i < 5; i++) {
      final ang = -math.pi / 2 + (i - 2) * 0.38;
      c.drawCircle(
        glow + Offset(math.cos(ang), math.sin(ang)) * 12,
        2.2,
        _hole(a1 * warm),
      );
    }
    final reach = _span(u, 1.1, 1.35);
    final feet = Offset(300 + 40 * reach, g + 12);
    _sayeJ(c, feet, 1.8, time, a1, rot: 0.1 * reach);
    _tears(c, feet + const Offset(4, 0), 1.8, time, a1 * _span(u, 1.5, 1.7));
  }
  // 2-3: Çalkuyruk. Karanlıkta kişner, başını kaldırır, konuşur.
  final horse = _span(u, 2.02, 2.25) * (1 - _leave(u, 3));
  if (horse > 0) {
    final lift = _span(u, 2.15, 2.45);
    final speak =
        _span(u, 2.4, 2.5) * (1 - _span(u, 2.85, 2.95)) +
        _span(u, 3.05, 3.15) * (1 - _span(u, 3.8, 3.9));
    // Kişneme: karanlıkta ses halkaları.
    final neigh = _span(u, 2.02, 2.1) * (1 - _span(u, 2.2, 2.3));
    for (var i = 0; i < 3; i++) {
      c.drawArc(
        Rect.fromCircle(center: const Offset(320, 220), radius: 30.0 + i * 22),
        -0.8,
        1.6,
        false,
        _stroke(_hole(0.7 * neigh), 2),
      );
    }
    _horseLift(
      c,
      const Offset(210, g + 10),
      210,
      horse,
      lift,
      time,
      speak: speak,
    );
  }
  // 3: Körmösler ışığa üşüşür; yakaladıkları canlar kafeslerde.
  final a3 = _heroA(u, 3);
  if (a3 > 0) {
    for (var i = 0; i < 4; i++) {
      _hangCage(
        c,
        Offset(470 + i * 78.0, 70 + (i % 2) * 40.0 + math.sin(time + i) * 3),
        34,
        a3,
        time,
      );
    }
    for (var i = 0; i < 3; i++) {
      final reach = _span(u, 3.2 + i * 0.1, 3.6 + i * 0.1);
      _person(
        c,
        Offset(
          580 + i * 64.0 - 20 * reach + math.sin(time * 1.3 + i) * 6,
          g + 2,
        ),
        130 + i * 10.0,
        a3 * 0.85,
        _kormos,
        flip: true,
        arm: -1.6 * reach,
        time: time + i,
      );
    }
  }
  // 2-3: Sâye ata bakar.
  final sa = _span(u, 2.05, 2.3) * (1 - _leave(u, 3));
  if (sa > 0) {
    _sayeJ(c, const Offset(450, g + 12), 1.8, time, sa, flip: true);
  }
}

// --------------------------------------------------------------- Ergenekon

/// Sâye oturur ([sit] 1) ya da ayağa kalkar ([sit] 0): oturunca gövdesi
/// aşağı iner, dizleri öne uzanır.
void _sayeSit(
  Canvas c,
  Offset feet,
  double s,
  double time,
  double a,
  double sit, {
  bool flip = false,
}) {
  if (a <= 0) return;
  final drop = 22 * s * sit;
  c.save();
  if (sit > 0) {
    c.clipRect(Rect.fromLTRB(0, 0, 780, feet.dy - 8 * s * sit + 0.5));
  }
  _sayeJ(c, feet + Offset(0, drop), s, time, a, flip: flip);
  c.restore();
  if (sit > 0) {
    final d = flip ? -1.0 : 1.0;
    final x0 = feet.dx - d * 10 * s;
    final x1 = feet.dx + d * 26 * s;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          math.min(x0, x1),
          feet.dy - 13 * s,
          math.max(x0, x1),
          feet.dy,
        ),
        Radius.circular(5 * s),
      ),
      _ink(a * sit),
    );
  }
}

/// Ergenekon: sönmüş ocağın başında ihtiyar demirci anlatır, Sâye dinler;
/// anlattıkları perdenin solunda bir hatıra gibi canlanır (Kıyan ile
/// Nüküz, keçi yolu ve cennet vadi, çoğalan boy, demirci ve yetmiş körük,
/// eriyen dağ ve boz kurt, Nevruz örsü). Son satırda hatıra söner: körükler
/// susar, dağ yeniden kapanır, Sâye ayağa kalkar.
void _ergenekonScene(Canvas canvas, double time, double u) {
  _P._c = canvas;
  final c = canvas;
  const g = PerdePainter._ground;
  // Ortadaki demir dağ 4'te erir (yol açılır), 6'da yeniden kapanır.
  final melt = _span(u, 4.0, 4.7) * (1 - _span(u, 6.15, 6.7));
  c.drawPath(
    Path()
      ..moveTo(0, g)
      ..lineTo(0, 60)
      ..lineTo(90, 30)
      ..lineTo(170, 120)
      ..lineTo(230, g)
      ..close(),
    _ink(0.55),
  );
  c.drawPath(
    Path()
      ..moveTo(780, g)
      ..lineTo(780, 50)
      ..lineTo(700, 40)
      ..lineTo(610, 130)
      ..lineTo(560, g)
      ..close(),
    _ink(0.55),
  );
  c.drawPath(
    Path()
      ..moveTo(300, g)
      ..lineTo(395, 90 + melt * 40)
      ..lineTo(490, g)
      ..close(),
    _ink(0.7),
  );
  if (melt > 0) {
    // Eriyen yol: dağın ortasında akkor bir geçit.
    c.drawPath(
      Path()
        ..moveTo(368, g)
        ..lineTo(386, g - 150 * melt)
        ..lineTo(404, g - 150 * melt)
        ..lineTo(422, g)
        ..close(),
      _hole(0.85 * melt),
    );
  }
  c.drawRect(const Rect.fromLTWH(0, g, 780, 50), _ink(1));

  // --- Hatıra: anlatılan, perdenin solunda (veil ile öne çıkar).
  void memory(double k, void Function(double a) draw, {double from = 0.02}) {
    final a = _span(u, k + from, k + from + 0.25) * (1 - _leave(u, k));
    if (a <= 0) return;
    _veil(c, a * 0.85);
    draw(a);
  }

  // 0: Kıyan ile Nüküz, eşleriyle vadiye sığınır.
  memory(0, (a) {
    final k = _span(u, 0.45, 0.95);
    const looks = [_nukuz, _woman2, _kiyan, _woman];
    for (var i = 0; i < 4; i++) {
      _person(
        c,
        Offset(330 + k * 60 - i * 82.0, g + 12),
        i.isEven ? 200 : 186,
        a,
        looks[i],
        arm: i.isEven ? 0.9 : 0,
        time: time + i,
      );
    }
  }, from: 0.42);
  // 1: keçi yolundan dar bir iniş; içeride çayır, ırmak, meyve ağaçları,
  // av.
  memory(1, (a) {
    final path = Path()
      ..moveTo(20, 70)
      ..lineTo(150, 110)
      ..lineTo(60, 160)
      ..lineTo(180, 210)
      ..lineTo(80, 260)
      ..lineTo(220, g - 10);
    c.drawPath(path, _stroke(_hole(0.7 * a), 4));
    final walk = _span(u, 1.05, 1.5);
    final m = path.computeMetrics().first;
    for (var i = 0; i < 4; i++) {
      final t = (walk - i * 0.08).clamp(0.0, 1.0);
      final pos = m.getTangentForOffset(m.length * t)!.position;
      _person(
        c,
        pos + const Offset(0, 2),
        38,
        a * (t > 0 ? 1 : 0),
        const [_nukuz, _woman2, _kiyan, _woman][i],
        time: time + i,
      );
    }
    final green = _span(u, 1.4, 1.75);
    // Irmak.
    final river = Path()..moveTo(230, g - 6);
    for (var x = 230.0; x <= 480; x += 10) {
      river.lineTo(x, g - 8 + math.sin(time * 2 + x / 18) * 2);
    }
    c.drawPath(river, _stroke(_hole(0.8 * a * green), 6));
    for (final (x, h) in [(260.0, 110.0), (330.0, 90.0), (450.0, 120.0)]) {
      _shape(c, MythShapes.umayTree, Offset(x, g), h * green, _ink(a));
      for (var i = 0; i < 4; i++) {
        c.drawCircle(
          Offset(x - 12 + (i % 2) * 22.0, g - h * green * 0.7 + i * 6.0),
          3,
          _hole(a * green * 0.8),
        );
      }
    }
    _shape(c, MythShapes.deer, Offset(390, g), 60 * green, _ink(a));
    _shape(c, MythShapes.rabbit, Offset(300, g), 20 * green, _ink(a));
  });
  // 2: dört yüz yıl: boy çoğalır, vadi dar gelir; dört yanda aşılmaz dağ.
  memory(2, (a) {
    final grow = _span(u, 2.1, 2.85);
    final n = 3 + (grow * 13).floor();
    for (var i = 0; i < n; i++) {
      final row = i % 2;
      _person(
        c,
        Offset(30 + (i ~/ 2) * 58.0 + row * 28, g + 4 - row * 24),
        70 - row * 10.0,
        a * (row == 1 ? 0.8 : 1),
        const [_shepherd, _woman, _kiyan, _woman2, _worker][i % 5],
        flip: i.isOdd,
        time: time + i,
      );
    }
    // Çadırlar.
    for (var i = 0; i < 3; i++) {
      final x = 80 + i * 150.0;
      c.drawPath(
        Path()
          ..moveTo(x - 30, g - 30)
          ..quadraticBezierTo(x, g - 80, x + 30, g - 30)
          ..close(),
        _ink(a * 0.8),
      );
    }
  });
  // 3: dedenin dedesinin dedesi demirci: "Şu dağ demirdir!" Yetmiş körük.
  memory(3, (a) {
    final rows = _span(u, 3.25, 3.75);
    final count = (rows * 9).ceil();
    for (var i = 0; i < count; i++) {
      final pump = 0.5 + 0.5 * math.sin(time * 6 + i * 0.9);
      _bellows(
        c,
        Offset(330 + (i % 3) * 52.0 + (i ~/ 3) * 12, g - (i ~/ 3) * 26.0),
        40,
        a,
        pump,
      );
    }
    _tasvirDemirci(c, const Offset(150, g + 12), 0.95, time, a);
  });
  // 4: demir erir; yolu boz kurt gösterir.
  memory(4, (a) {
    _tasvirBozkurt(
      c,
      Offset(170 + 110 * _span(u, 4.0, 5.0), g + 10),
      210,
      time,
      a,
    );
  });
  // 5: Nevruz: her yıl demir kızdırılıp örste dövülür; gün doğar.
  memory(5, (a) {
    c.drawCircle(
      Offset(420, 110 - 30 * _span(u, 5.0, 6.0)),
      40,
      _hole(0.6 * a),
    );
    _tasvirDemirci(c, const Offset(170, g + 12), 0.95, time, a);
  });

  // --- Anlatan: sönmüş ocağın başında ihtiyar demirci; Sâye dinler.
  // 0'da Çalkuyruk Sâye'yi vadiye getirir.
  final arrive = _span(u, 0.0, 0.32);
  final off = _span(u, 0.3, 0.42);
  final horseA = 1 - _span(u, 0.45, 0.6);
  if (horseA > 0) {
    final hx = -80 + 360 * arrive;
    final ph = arrive < 1 ? time * 1.3 : 0.0;
    c.save();
    c.translate(hx, g + 10);
    c.scale(1.7);
    c.drawPath(
      MythFigures.horseRun(ph, weight: 0.25 * (1 - arrive)),
      _ink(horseA),
    );
    c.drawCircle(const Offset(47, -86), 1.6, _hole(horseA));
    c.restore();
    if (off < 1) {
      _sayeJ(c, Offset(hx - 6, g + 10 - 100), 1.3, time, horseA * (1 - off));
    }
  }
  _coldForge(c, 728, 1, time);
  // Elleri: 5'te çekiç tutar gibi kalkar, vurur; 6'da düşer.
  final up = _span(u, 5.45, 5.65) * (1 - _span(u, 6.02, 6.2));
  final tap = math.pow(math.max(0, math.sin(time * 5.5)), 4).toDouble();
  final arm = up * (-2.5 + 0.5 * tap) + 0.35 * _span(u, 6.1, 6.25);
  const seat = Offset(652, g + 8);
  _seated(c, seat, 230, 1, _ihtiyar, flip: true, time: time, arm: arm);
  // 3: gözleri parlar.
  final shine = _span(u, 3.05, 3.2) * (1 - _span(u, 3.85, 3.95));
  if (shine > 0) {
    final eye = seat + const Offset(-16, -106);
    c.drawCircle(eye, 9, _hole(0.25 * shine));
    c.drawCircle(eye, 2.6, _hole(shine));
  }
  // Konuşurken ağzından ince ses çizgileri (anlatırken).
  final talk = _span(u, 0.35, 0.5) * (1 - _span(u, 6.85, 7.0));
  if (talk > 0) {
    for (var i = 0; i < 2; i++) {
      final r = 7.0 + i * 6 + (time * 10) % 6;
      c.drawArc(
        Rect.fromCircle(center: seat + const Offset(-26, -100), radius: r),
        math.pi - 0.5,
        1.0,
        false,
        _stroke(_hole(0.55 * talk), 1.3),
      );
    }
  }
  // Susan körükler: dağın dibinde yassı, kımıltısız.
  final silent = _span(u, 6.05, 6.35);
  for (var i = 0; i < 5; i++) {
    _bellows(c, Offset(250 + i * 50.0, g), 44, silent, 0.2);
  }
  // Sâye: atından iner, ihtiyarın karşısına oturur; 6'da ayağa kalkar.
  if (off > 0) {
    final walk = _span(u, 0.42, 0.55);
    final sit = _span(u, 0.55, 0.65) * (1 - _span(u, 6.6, 6.78));
    final stepIn = _span(u, 6.78, 6.98);
    final x = 290 + 225 * walk + 10 * stepIn;
    _sayeSit(c, Offset(x, g + 12), 1.6, time, off, sit);
  }
}
