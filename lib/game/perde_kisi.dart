part of 'perde.dart';

// Karagöz tasvirleri gibi profilden kişiler: her kişiyi başlığı, sakalı,
// giysisi, yapısı ve elindeki eşya tanıtır. Mürekkep deri; ayrıntılar ışık
// kesikleri, göz bir ışık deliği. Ayaklar orijinde, sağa bakar; boy 100
// birim (çağıran ölçekler).

enum _Hat {
  none,
  hair,
  kavuk, // padişahın iri kavuğu, sorguçlu
  sarik, // sarık
  sikke, // Mevlevi'nin uzun keçe külahı
  bork, // Türk börkü (kürk kenarlı)
  tiara, // Ermeni-Pers sivri tacı (Kommagene)
  byzCrown, // Bizans taçı, sarkan inci telleri
  rayCrown, // ışın taçlı gök tanrısı
  horns, // Erlik
  hood, // keşiş kukuletası
  helmet, // sivri tolga
  hotoz, // kadın: yüksek başlık ve tül
  veil, // kadın: başörtüsü
  wreath, // Herakles: aslan postu başlık
  crownSpikes, // Nemrud: sivri taç
}

enum _Garb { robe, kaftan, tunic, dress, rags, bare }

enum _Beard { none, short, long, pointed }

enum _Prop {
  none,
  staff,
  bow,
  sword,
  club,
  purse,
  scroll,
  lamp,
  scepter,
  wingFrame,
  hammer,
  plank,
}

class _Look {
  const _Look({
    this.hat = _Hat.none,
    this.garb = _Garb.robe,
    this.beard = _Beard.none,
    this.prop = _Prop.none,
    this.broad = 1,
    this.bent = 0,
    this.cape = false,
    this.belt = true,
    this.oneEye = false,
    this.wings = false,
  });
  final _Hat hat;
  final _Garb garb;
  final _Beard beard;
  final _Prop prop;

  /// Omuz genişliği çarpanı (dev, savaşçı > 1; ince < 1).
  final double broad;

  /// Öne eğilme (yaşlı, keşiş): radyan.
  final double bent;
  final bool cape;
  final bool belt;
  final bool oneEye;

  /// Perinin sırtında tül kanatlar.
  final bool wings;
}

// Kadro: her kahramanın kendi görünüşü.
const _hezarfen = _Look(
  hat: _Hat.sarik,
  garb: _Garb.kaftan,
  beard: _Beard.short,
  prop: _Prop.wingFrame,
);
const _hezarfenFly = _Look(
  hat: _Hat.sarik,
  garb: _Garb.kaftan,
  beard: _Beard.short,
);
const _kandilci = _Look(hat: _Hat.hood, garb: _Garb.robe, prop: _Prop.lamp);
const _sultanLook = _Look(
  hat: _Hat.kavuk,
  garb: _Garb.robe,
  beard: _Beard.short,
  broad: 1.2,
  cape: true,
  prop: _Prop.purse,
);
const _lagari = _Look(
  hat: _Hat.sarik,
  garb: _Garb.kaftan,
  beard: _Beard.pointed,
);
const _justinian = _Look(
  hat: _Hat.byzCrown,
  garb: _Garb.robe,
  beard: _Beard.short,
  cape: true,
  prop: _Prop.scepter,
);
const _worker = _Look(hat: _Hat.hair, garb: _Garb.tunic, belt: true);
const _slave = _Look(hat: _Hat.hair, garb: _Garb.rags, belt: false, bent: 0.35);
const _monk = _Look(
  hat: _Hat.hood,
  garb: _Garb.robe,
  beard: _Beard.long,
  bent: 0.2,
  belt: true,
  prop: _Prop.staff,
);
const _shepherd = _Look(
  hat: _Hat.bork,
  garb: _Garb.kaftan,
  beard: _Beard.short,
  prop: _Prop.staff,
);
const _nuh = _Look(
  hat: _Hat.sarik,
  garb: _Garb.robe,
  beard: _Beard.long,
  bent: 0.12,
  prop: _Prop.staff,
);
const _antiochos = _Look(
  hat: _Hat.tiara,
  garb: _Garb.tunic,
  beard: _Beard.none,
  cape: true,
  prop: _Prop.scepter,
);
const _herakles = _Look(
  hat: _Hat.wreath,
  garb: _Garb.bare,
  beard: _Beard.short,
  broad: 1.35,
  prop: _Prop.club,
  belt: false,
);
const _nemrud = _Look(
  hat: _Hat.crownSpikes,
  garb: _Garb.robe,
  beard: _Beard.pointed,
  cape: true,
  broad: 1.15,
  prop: _Prop.bow,
);
const _ibrahim = _Look(hat: _Hat.sarik, garb: _Garb.robe, beard: _Beard.long);
const _tepegoz = _Look(
  hat: _Hat.hair,
  garb: _Garb.rags,
  broad: 1.6,
  oneEye: true,
  prop: _Prop.club,
  belt: false,
);
const _basat = _Look(hat: _Hat.helmet, garb: _Garb.kaftan, beard: _Beard.short);
const _dervishLook = _Look(
  hat: _Hat.sikke,
  garb: _Garb.robe,
  beard: _Beard.short,
);
const _mevlana = _Look(
  hat: _Hat.sikke,
  garb: _Garb.robe,
  beard: _Beard.long,
  cape: true,
  prop: _Prop.scroll,
);
const _kayra = _Look(
  hat: _Hat.rayCrown,
  garb: _Garb.robe,
  beard: _Beard.long,
  broad: 1.15,
  cape: true,
);
const _erlik = _Look(
  hat: _Hat.horns,
  garb: _Garb.robe,
  beard: _Beard.long,
  broad: 1.4,
  cape: true,
  oneEye: false,
);
const _erTostuk = _Look(
  hat: _Hat.helmet,
  garb: _Garb.kaftan,
  beard: _Beard.short,
  prop: _Prop.bow,
);
const _kiyan = _Look(
  hat: _Hat.bork,
  garb: _Garb.kaftan,
  beard: _Beard.short,
  prop: _Prop.bow,
);
const _nukuz = _Look(
  hat: _Hat.bork,
  garb: _Garb.kaftan,
  beard: _Beard.pointed,
  prop: _Prop.sword,
);
const _woman = _Look(hat: _Hat.hotoz, garb: _Garb.dress, belt: true);
const _woman2 = _Look(hat: _Hat.veil, garb: _Garb.dress, belt: true);
const _peri = _Look(hat: _Hat.hair, garb: _Garb.dress, belt: true, wings: true);
const _periBare = _Look(hat: _Hat.hair, garb: _Garb.dress);
const _periQueen = _Look(
  wings: true,
  hat: _Hat.byzCrown,
  garb: _Garb.dress,
  belt: true,
  cape: true,
);
const _akAna = _Look(
  hat: _Hat.veil,
  garb: _Garb.dress,
  belt: false,
  cape: true,
);
const _giant = _Look(
  hat: _Hat.hair,
  garb: _Garb.rags,
  broad: 1.7,
  belt: false,
  prop: _Prop.club,
);
const _angel = _Look(hat: _Hat.hair, garb: _Garb.robe, belt: true);
const _kormos = _Look(
  hat: _Hat.hood,
  garb: _Garb.rags,
  bent: 0.25,
  belt: false,
  oneEye: true,
);

/// Profilden kişi tasviri. [h] piksel boy, ayaklar [feet]'te.
void _person(
  Canvas c,
  Offset feet,
  double h,
  double a,
  _Look l, {
  bool flip = false,
  double time = 0,
  double arm = 0,
  double rot = 0,
}) {
  if (a <= 0) return;
  final ink = _ink(a);
  final cut = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round
    ..color = PerdePainter._hole.withValues(alpha: 0.6 * a);
  final s = h / 100 * (1 + math.max(0.0, l.broad - 1.1) * 0.6);
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.7 + feet.dx) * 0.8);
  c.rotate(rot);
  c.scale(flip ? -s : s, s);
  final w = l.broad;
  final female = l.garb == _Garb.dress;
  if (l.wings) {
    final flap = math.sin(time * 3) * 0.12;
    for (final (len, ang) in [(44.0, -2.2), (34.0, -2.75)]) {
      c.save();
      c.translate(-4, -74);
      c.rotate(ang + flap);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(len * 0.5, -11, len, 0)
          ..quadraticBezierTo(len * 0.5, 7, 0, 0)
          ..close(),
        ink,
      );
      c.drawLine(Offset(3, 0), Offset(len * 0.9, 0), cut);
      c.restore();
    }
  }
  // Pelerin: arkadan dökülür.
  if (l.cape) {
    c.drawPath(
      Path()
        ..moveTo(-6 * w, -78)
        ..quadraticBezierTo(-22 * w, -50, -20 * w, -2)
        ..lineTo(-6, -2)
        ..lineTo(-2, -76)
        ..close(),
      ink,
    );
  }

  // Bacaklar ve ayakkabı (giysiye göre).
  final longRobe = l.garb == _Garb.robe || l.garb == _Garb.dress;
  if (!longRobe) {
    final legW = l.garb == _Garb.kaftan ? 5.5 : 3.6; // şalvar bol
    for (final (x0, x1) in [(-4.0, -7.0), (3.0, 5.0)]) {
      c.drawPath(
        Path()
          ..moveTo(x0 - legW * w, -48)
          ..lineTo(x0 + legW * w, -48)
          ..quadraticBezierTo(x1 + legW, -20, x1 + 2.6, -4)
          ..lineTo(x1 - 2.6, -4)
          ..quadraticBezierTo(x1 - legW - 1, -20, x0 - legW * w, -48)
          ..close(),
        ink,
      );
    }
  }
  // Sivri burunlu pabuçlar.
  for (final x in [-6.0, 5.0]) {
    c.drawPath(
      Path()
        ..moveTo(x - 4, -5)
        ..lineTo(x + 4, -5)
        ..quadraticBezierTo(x + 10, -3, x + 9, 0)
        ..lineTo(x - 4, 0)
        ..close(),
      ink,
    );
  }

  // Gövdeyi öne eğ (yaşlılar, köleler): uzun giyside etekten, kısada
  // kalçadan.
  final longPivot = longRobe ? -4.0 : -48.0;
  c.translate(0, longPivot);
  c.rotate(l.bent * 0.6);
  c.translate(0, -longPivot);

  // Gövde ve giysi.
  final hemY = switch (l.garb) {
    _Garb.robe || _Garb.dress => -3.0,
    _Garb.kaftan => -26.0,
    _Garb.tunic => -38.0,
    _Garb.rags => -34.0,
    _Garb.bare => -46.0,
  };
  final hemW = switch (l.garb) {
    _Garb.dress => 17.0,
    _Garb.robe => 13.0,
    _Garb.kaftan => 12.0,
    _Garb.rags => 11.0,
    _ => 10.0,
  };
  final waistW = female ? 6.0 : 8.0;
  final body = Path()
    ..moveTo((female ? -8 : -11) * w, -79)
    ..quadraticBezierTo((female ? -9 : -12) * w, -64, -waistW * w, -52)
    ..quadraticBezierTo(-hemW * w * 0.85, (hemY - 52) / 2 - 6, -hemW * w, hemY)
    ..lineTo(hemW * w * 0.95, hemY)
    ..quadraticBezierTo(hemW * w * 0.8, (hemY - 52) / 2 - 6, waistW * w, -52);
  if (female) {
    body.quadraticBezierTo(11, -62, 8, -72);
  } else {
    body.quadraticBezierTo(12 * w, -66, 10 * w, -78);
  }
  body
    ..lineTo(4, -81)
    ..lineTo(-4, -81)
    ..close();
  if (l.garb == _Garb.rags) {
    // Yırtık etek ucu.
    for (var i = 0; i < 6; i++) {
      final x = -hemW * w + i * hemW * w * 0.38;
      body.addPolygon([
        Offset(x, hemY),
        Offset(x + 2.5, hemY + 6),
        Offset(x + 5, hemY),
      ], true);
    }
  }
  c.drawPath(body, ink);
  if (l.garb == _Garb.bare) {
    // Çıplak gövde: kaslar ışık kesiğiyle.
    c.drawArc(
      Rect.fromCenter(center: Offset(2, -68), width: 14 * w, height: 10),
      0.2,
      2.6,
      false,
      cut,
    );
    c.drawLine(Offset(0, -62), Offset(0, -52), cut);
  }
  // Kuşak, yaka ve etek kenarı: ışık kesikleri.
  if (l.belt) {
    c.drawLine(
      Offset(-waistW * w, -52),
      Offset(waistW * w, -52),
      cut..strokeWidth = 1.6,
    );
    cut.strokeWidth = 0.9;
  }
  if (l.garb == _Garb.robe || l.garb == _Garb.kaftan) {
    c.drawLine(const Offset(3, -80), Offset(1, hemY + 2), cut);
  }
  if (l.garb != _Garb.bare) {
    _punchRow(
      c,
      Offset(-hemW * w + 2, hemY - 3),
      Offset(hemW * w - 2, hemY - 3),
      6,
      0.8,
      a,
    );
  }
  if (female) {
    // Elbisenin göğüs ve kol kesikleri.
    c.drawArc(
      Rect.fromCenter(center: const Offset(1, -76), width: 10, height: 8),
      0.3,
      2.5,
      false,
      cut,
    );
  }

  // Baş: profil (alın, burun, çene).
  final head = Path()
    ..moveTo(-6, -84)
    ..quadraticBezierTo(-9, -94, -2, -99)
    ..quadraticBezierTo(5, -100, 7, -94);
  if (female) {
    head
      ..lineTo(8.5, -90)
      ..lineTo(7, -88.5)
      ..quadraticBezierTo(7.5, -85.5, 5.5, -83.5);
  } else {
    head
      ..lineTo(10.5, -89)
      ..lineTo(7.5, -87.5)
      ..lineTo(8, -85)
      ..quadraticBezierTo(7, -82, 4, -81.5);
  }
  head
    ..lineTo(-3, -81)
    ..close();
  c.drawPath(head, ink);
  // Göz: ışık deliği (Tepegöz'de alında tek büyük göz).
  if (l.oneEye) {
    c.drawCircle(const Offset(3, -94), 2.2, _hole(a));
  } else {
    c.drawOval(
      Rect.fromCenter(center: const Offset(4.2, -92), width: 2.6, height: 1.4),
      _hole(a),
    );
  }
  // Kaş kesiği.
  c.drawLine(const Offset(2.5, -94), const Offset(6, -94.5), cut);

  // Sakal.
  switch (l.beard) {
    case _Beard.short:
      c.drawPath(
        Path()
          ..moveTo(-3, -84)
          ..quadraticBezierTo(2, -78, 8, -83)
          ..lineTo(7.5, -86)
          ..lineTo(-1, -86)
          ..close(),
        ink,
      );
    case _Beard.long:
      c.drawPath(
        Path()
          ..moveTo(-3, -85)
          ..quadraticBezierTo(-2, -66, 3, -64)
          ..quadraticBezierTo(9, -72, 8, -84)
          ..lineTo(0, -86)
          ..close(),
        ink,
      );
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(0.5 + i * 2, -80), Offset(1.5 + i * 2, -69), cut);
      }
    case _Beard.pointed:
      c.drawPath(
        Path()
          ..moveTo(-1, -84)
          ..lineTo(9, -72)
          ..lineTo(8, -85)
          ..close(),
        ink,
      );
    case _Beard.none:
      break;
  }

  // Başlık.
  switch (l.hat) {
    case _Hat.none:
      break;
    case _Hat.hair:
      c.drawPath(
        Path()
          ..moveTo(-8, -86)
          ..quadraticBezierTo(-11, -98, -1, -101)
          ..quadraticBezierTo(6, -101, 6, -96)
          ..lineTo(-4, -95)
          ..lineTo(-4, -86)
          ..close(),
        ink,
      );
      if (female) {
        // Uzun saç örgüsü.
        c.drawPath(
          Path()
            ..moveTo(-7, -90)
            ..quadraticBezierTo(-12, -70, -9, -56)
            ..lineTo(-6, -58)
            ..quadraticBezierTo(-8, -72, -4, -88)
            ..close(),
          ink,
        );
      }
    case _Hat.kavuk:
      c.drawOval(
        Rect.fromCenter(center: const Offset(-1, -103), width: 24, height: 17),
        ink,
      );
      c.drawPath(
        Path()
          ..moveTo(-6, -100)
          ..lineTo(4, -100)
          ..lineTo(2, -116)
          ..lineTo(-4, -116)
          ..close(),
        ink,
      );
      for (var i = 0; i < 3; i++) {
        c.drawArc(
          Rect.fromCenter(
            center: Offset(-1, -103 + i * 2.5),
            width: 20 - i * 2,
            height: 8,
          ),
          0.2,
          2.7,
          false,
          cut,
        );
      }
      // Sorguç.
      c.drawPath(
        Path()
          ..moveTo(4, -108)
          ..quadraticBezierTo(14, -122, 9, -130)
          ..quadraticBezierTo(8, -118, 2, -110)
          ..close(),
        ink,
      );
      c.drawCircle(const Offset(4, -106), 1.6, _hole(a));
    case _Hat.sarik:
      c.drawOval(
        Rect.fromCenter(center: const Offset(-1, -100), width: 17, height: 11),
        ink,
      );
      c.drawArc(
        Rect.fromCenter(center: const Offset(-1, -100), width: 14, height: 6),
        0.2,
        2.6,
        false,
        cut,
      );
    case _Hat.sikke:
      c.drawPath(
        Path()
          ..moveTo(-7, -97)
          ..lineTo(5, -97)
          ..lineTo(3.5, -120)
          ..quadraticBezierTo(-1, -123, -5.5, -120)
          ..close(),
        ink,
      );
      c.drawLine(const Offset(-6, -99), const Offset(5, -99), cut);
    case _Hat.bork:
      c.drawPath(
        Path()
          ..moveTo(-9, -96)
          ..quadraticBezierTo(-6, -112, 1, -113)
          ..quadraticBezierTo(8, -110, 7, -96)
          ..close(),
        ink,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -98, 18, 5),
          const Radius.circular(2),
        ),
        ink,
      );
      _punchRow(c, const Offset(-8, -95.5), const Offset(6, -95.5), 5, 0.6, a);
    case _Hat.tiara:
      c.drawPath(
        Path()
          ..moveTo(-8, -97)
          ..lineTo(7, -97)
          ..lineTo(6, -104)
          ..lineTo(5, -112)
          ..lineTo(2.5, -106)
          ..lineTo(0, -116)
          ..lineTo(-2.5, -106)
          ..lineTo(-5, -112)
          ..lineTo(-6, -104)
          ..close(),
        ink,
      );
      // Kulaklık ve ense örtüsü.
      c.drawPath(
        Path()
          ..moveTo(-8, -97)
          ..lineTo(-10, -82)
          ..lineTo(-5, -84)
          ..lineTo(-4, -96)
          ..close(),
        ink,
      );
      c.drawCircle(const Offset(0, -103), 1.4, _hole(a));
    case _Hat.byzCrown:
      c.drawRect(const Rect.fromLTWH(-7, -104, 14, 7), ink);
      for (final x in [-6.0, 0.0, 6.0]) {
        c.drawCircle(Offset(x, -106), 2.2, ink);
      }
      _punchRow(
        c,
        const Offset(-6, -100.5),
        const Offset(6, -100.5),
        4,
        0.8,
        a,
      );
      // Sarkan inci telleri.
      for (final x in [-7.0, 6.0]) {
        c.drawLine(Offset(x, -98), Offset(x, -88), ink..strokeWidth = 1.2);
        c.drawCircle(Offset(x, -88), 1.4, ink);
      }
    case _Hat.rayCrown:
      for (var i = 0; i < 7; i++) {
        final ang = -math.pi / 2 + (i - 3) * 0.3;
        final base = const Offset(-1, -99);
        c.drawPath(
          Path()
            ..moveTo(
              base.dx + math.cos(ang - 0.08) * 6,
              base.dy + math.sin(ang - 0.08) * 6,
            )
            ..lineTo(base.dx + math.cos(ang) * 20, base.dy + math.sin(ang) * 20)
            ..lineTo(
              base.dx + math.cos(ang + 0.08) * 6,
              base.dy + math.sin(ang + 0.08) * 6,
            )
            ..close(),
          ink,
        );
      }
      c.drawCircle(const Offset(-1, -99), 7, ink);
    case _Hat.horns:
      for (final sx in [-1.0, 1.0]) {
        c.drawPath(
          Path()
            ..moveTo(sx * 3 - 1, -97)
            ..quadraticBezierTo(sx * 14 - 1, -104, sx * 12 - 1, -118)
            ..quadraticBezierTo(sx * 9 - 1, -106, sx * 1 - 1, -100)
            ..close(),
          ink,
        );
      }
    case _Hat.hood:
      c.drawPath(
        Path()
          ..moveTo(-10, -78)
          ..quadraticBezierTo(-13, -100, -2, -104)
          ..quadraticBezierTo(8, -103, 9, -94)
          ..lineTo(5, -94)
          ..quadraticBezierTo(2, -99, -4, -96)
          ..lineTo(-6, -80)
          ..close(),
        ink,
      );
    case _Hat.helmet:
      c.drawPath(
        Path()
          ..moveTo(-8, -95)
          ..quadraticBezierTo(-6, -108, 0, -118)
          ..quadraticBezierTo(6, -108, 7, -95)
          ..close(),
        ink,
      );
      // Zincir ense örtüsü.
      c.drawPath(
        Path()
          ..moveTo(-8, -95)
          ..lineTo(-10, -82)
          ..lineTo(-3, -82)
          ..lineTo(-3, -95)
          ..close(),
        ink,
      );
      _punchRow(c, const Offset(-9, -88), const Offset(-4, -88), 3, 0.6, a);
    case _Hat.hotoz:
      c.drawPath(
        Path()
          ..moveTo(-6, -97)
          ..lineTo(4, -97)
          ..lineTo(1, -122)
          ..lineTo(-3, -122)
          ..close(),
        ink,
      );
      c.drawCircle(const Offset(-1, -123), 3, ink);
      // Arkaya dökülen tül.
      c.drawPath(
        Path()
          ..moveTo(-3, -118)
          ..quadraticBezierTo(-16, -96, -14, -70)
          ..lineTo(-10, -70)
          ..quadraticBezierTo(-10, -94, -4, -100)
          ..close(),
        ink,
      );
      _punchRow(c, const Offset(-1, -118), const Offset(-1, -100), 4, 0.7, a);
    case _Hat.veil:
      c.drawPath(
        Path()
          ..moveTo(-9, -72)
          ..quadraticBezierTo(-12, -100, -1, -101)
          ..quadraticBezierTo(7, -101, 7.5, -95)
          ..lineTo(5, -95)
          ..quadraticBezierTo(0, -97, -3, -92)
          ..lineTo(-4, -74)
          ..close(),
        ink,
      );
    case _Hat.wreath:
      // Aslan postu: başın üstünde aslan başı, omuzdan sarkan pençeler.
      c.drawPath(
        Path()
          ..moveTo(-9, -88)
          ..quadraticBezierTo(-10, -104, 0, -106)
          ..quadraticBezierTo(10, -104, 11, -96)
          ..lineTo(13, -94)
          ..lineTo(8, -93)
          ..quadraticBezierTo(2, -98, -4, -94)
          ..lineTo(-6, -80)
          ..close(),
        ink,
      );
      c.drawCircle(const Offset(6, -100), 1.2, _hole(a));
    case _Hat.crownSpikes:
      c.drawPath(
        Path()
          ..moveTo(-7, -97)
          ..lineTo(7, -97)
          ..lineTo(8, -112)
          ..lineTo(4, -104)
          ..lineTo(0, -114)
          ..lineTo(-4, -104)
          ..lineTo(-8, -112)
          ..close(),
        ink,
      );
  }

  // Ön kol: omuzdan, giysiye göre kol yeni; elde eşya.
  final sleeve = longRobe || l.garb == _Garb.kaftan ? 4.2 : 3.0;
  final armA =
      arm +
      switch (l.prop) {
        _Prop.staff || _Prop.scepter || _Prop.club || _Prop.hammer => -0.5,
        _Prop.bow || _Prop.sword => -1.0,
        _Prop.purse || _Prop.scroll || _Prop.lamp || _Prop.plank => -0.9,
        _ => 0.15,
      };
  c.save();
  c.translate(3 * w, -76);
  c.rotate(armA);
  c.drawPath(
    Path()
      ..moveTo(-sleeve, 0)
      ..lineTo(sleeve, 0)
      ..lineTo(3, 26)
      ..lineTo(-3, 26)
      ..close(),
    ink,
  );
  c.drawCircle(const Offset(0, 27), 2.8, ink);
  final hand = const Offset(0, 28);
  switch (l.prop) {
    case _Prop.staff:
      break;
    case _Prop.scepter:
      c.drawLine(
        hand + const Offset(0, -26),
        hand + const Offset(0, 14),
        ink..strokeWidth = 2,
      );
      c.drawCircle(hand + const Offset(0, -28), 3.5, ink);
      c.drawCircle(hand + const Offset(0, -28), 1.4, _hole(a));
    case _Prop.club:
      c.drawPath(
        Path()
          ..moveTo(-2, 22)
          ..lineTo(2, 22)
          ..lineTo(6, 58)
          ..quadraticBezierTo(0, 64, -6, 58)
          ..close(),
        ink,
      );
    case _Prop.hammer:
      c.drawLine(hand, hand + const Offset(0, 22), ink..strokeWidth = 2);
      c.drawRect(
        Rect.fromCenter(
          center: hand + const Offset(0, 24),
          width: 12,
          height: 7,
        ),
        ink,
      );
    case _Prop.bow:
      c.drawArc(
        Rect.fromCenter(
          center: hand + const Offset(4, 0),
          width: 14,
          height: 44,
        ),
        -1.4,
        2.8,
        false,
        ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      ink.style = PaintingStyle.fill;
      c.drawLine(hand + const Offset(2, -21), hand + const Offset(2, 21), cut);
    case _Prop.sword:
      c.drawPath(
        Path()
          ..moveTo(-1.5, 28)
          ..lineTo(1.5, 28)
          ..quadraticBezierTo(4, 46, 0, 64)
          ..quadraticBezierTo(-2, 46, -1.5, 28)
          ..close(),
        ink,
      );
      c.drawLine(
        const Offset(-5, 28),
        const Offset(5, 28),
        ink..strokeWidth = 2,
      );
    case _Prop.purse:
      c.drawOval(
        Rect.fromCenter(
          center: hand + const Offset(0, 6),
          width: 9,
          height: 11,
        ),
        ink,
      );
      c.drawLine(hand + const Offset(-3, 1), hand + const Offset(3, 1), cut);
    case _Prop.scroll:
      c.drawRect(
        Rect.fromCenter(
          center: hand + const Offset(0, 4),
          width: 4,
          height: 14,
        ),
        ink,
      );
    case _Prop.lamp:
      c.drawLine(hand, hand + const Offset(0, 10), ink..strokeWidth = 1.2);
      c.drawCircle(hand + const Offset(0, 13), 4, _hole(a));
    case _Prop.plank:
      c.drawRect(
        Rect.fromCenter(
          center: hand + const Offset(0, 4),
          width: 30,
          height: 6,
        ),
        ink,
      );
    case _Prop.wingFrame:
      break;
    case _Prop.none:
      break;
  }
  c.restore();
  if (l.prop == _Prop.staff) {
    // Asa yere dik iner: elin yerinden, başın üstünden yere.
    final hx = 3 * w - 28 * math.sin(armA);
    c.drawLine(Offset(hx, -112), Offset(hx, 0), ink..strokeWidth = 2.2);
    c.drawCircle(Offset(hx, -76 + 28 * math.cos(armA)), 3, ink);
  }
  // Omuz çivisi.
  c.drawCircle(Offset(3 * w, -76), 1.3, _hole(0.6 * a));
  // Hezarfen'in sırtında kanat iskeleti (kartal tüyü dizili çubuklar).
  if (l.prop == _Prop.wingFrame) {
    for (var i = 0; i < 5; i++) {
      final ang = -2.4 + i * 0.18;
      c.drawLine(
        const Offset(-6, -74),
        Offset(-6 + math.cos(ang) * 36, -74 + math.sin(ang) * 36),
        ink..strokeWidth = 1.6,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-6 + math.cos(ang) * 30, -74 + math.sin(ang) * 30),
          width: 5,
          height: 10,
        ),
        ink,
      );
    }
  }
  c.restore();
}

/// Kadro önizlemesi: perdede bütün kişiler yan yana (önizleme aracı için).
void paintCast(Canvas canvas, Size size, double time) {
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE6A15A));
  const cast = <(_Look, String)>[
    (_hezarfen, 'Hezarfen'),
    (_sultanLook, 'Sultan'),
    (_lagari, 'Lagari'),
    (_justinian, 'Justinianus'),
    (_worker, 'işçi'),
    (_slave, 'köle'),
    (_monk, 'Hakob'),
    (_shepherd, 'çoban'),
    (_nuh, 'Nuh'),
    (_antiochos, 'Antiochos'),
    (_herakles, 'Herakles'),
    (_nemrud, 'Nemrud'),
    (_ibrahim, 'İbrahim'),
    (_tepegoz, 'Tepegöz'),
    (_basat, 'Basat'),
    (_dervishLook, 'derviş'),
    (_mevlana, 'Mevlânâ'),
    (_kayra, 'Kayra Han'),
    (_erlik, 'Erlik'),
    (_erTostuk, 'Er Töştük'),
    (_kiyan, 'Kıyan'),
    (_nukuz, 'Nüküz'),
    (_woman, 'kadın'),
    (_woman2, 'kadın'),
    (_peri, 'peri'),
    (_periQueen, 'Peri Padişahı'),
    (_akAna, 'Ak Ana'),
    (_giant, 'dev'),
    (_angel, 'melek'),
    (_kormos, 'Körmös'),
  ];
  const perRow = 10;
  final cw = size.width / perRow;
  final rows = (cast.length / perRow).ceil();
  final rh = size.height / rows;
  for (var i = 0; i < cast.length; i++) {
    final (look, _) = cast[i];
    final x = cw * (i % perRow + 0.5);
    final y = rh * (i ~/ perRow + 1) - 18;
    _person(canvas, Offset(x, y), rh * 0.62, 1, look, time: time);
  }
}
