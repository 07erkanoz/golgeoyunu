part of 'perde.dart';

// Büyük, renkli tasvirler: Karagöz perdesindeki gibi arkadan ışık alan, yarı
// saydam boyalı deri; mürekkep kontur, deriye zımbalanmış ışık delikleri,
// eklem çivileri. Bölümün efsane kahramanı kendi satırında perdeyi doldurur;
// her perdenin sonunda ana iplik: Sâye ile Hüdhüd önde, Kandilci ustanın
// ışığını perdeden dışarı taşır.

/// Tasvir derisi: perdenin gölge dili (tek renk mürekkep). [c] yalnız
/// parçanın adını taşır; renk kullanılmaz.
Paint _hide(Color c, double a) => _ink(a);

/// Parçaların arası: deriye kesilmiş ince ışık çizgisi (Karagöz'deki
/// gibi ayrıntı ışıkla seçilir).
Paint _rim(double a) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.6
  ..strokeJoin = StrokeJoin.round
  ..color = PerdePainter._hole.withValues(alpha: 0.55 * a);

/// Deriye zımbalanmış süs: bir sıra ışık deliği.
void _punchRow(Canvas c, Offset a, Offset b, int n, double r, double alpha) {
  final p = _hole(0.75 * alpha);
  for (var i = 0; i < n; i++) {
    c.drawCircle(Offset.lerp(a, b, (i + 0.5) / n)!, r, p);
  }
}

/// Gül biçimli zımba süsü.
void _rosette(Canvas c, Offset at, double r, double alpha) {
  final p = _hole(0.8 * alpha);
  c.drawCircle(at, r * 0.35, p);
  for (var i = 0; i < 6; i++) {
    final ang = i * math.pi / 3;
    c.drawCircle(
      at + Offset(math.cos(ang), math.sin(ang)) * r * 0.75,
      r * 0.22,
      p,
    );
  }
}

/// Eklem çivisi.
void _rivet(Canvas c, Offset at, double alpha) {
  c.drawCircle(at, 3, _ink(alpha));
  c.drawCircle(at, 1.2, _hole(0.6 * alpha));
}

void _fillRim(Canvas c, Path p, Color col, double a) {
  c.drawPath(p, _hide(col, a));
  c.drawPath(p, _rim(a));
}

/// Kahraman sahnesinde manzara geri çekilir: perdenin bezi önüne ışık iner.
void _veil(Canvas canvas, double a) {
  if (a <= 0) return;
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, PerdePainter._vw, PerdePainter._vh),
    Paint()..color = const Color(0xFFE6A15A).withValues(alpha: 0.62 * a),
  );
}

/// Tasvir giriş/çıkışı: satırda yandan kayarak girer, satır biterken çıkar.
double _enter(double u, double k) => _span(u, k + 0.02, k + 0.3);
double _leave(double u, double k) => _span(u, k + 0.82, k + 1.0);

// ------------------------------------------------------------- Demirci

/// Demirci: keçe külahlı, sakallı, deri önlüklü; sağ eli çekici kaldırıp
/// örse indirir, örsün üstünde akkor demir, vuruşta kıvılcım. Ayaklar
/// [feet]'te, sağa bakar; boyu ~250 birim × [s].
void _tasvirDemirci(Canvas c, Offset feet, double s, double time, double a) {
  if (a <= 0) return;
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.6) * 1.5);
  c.scale(s);
  const indigo = Color(0xFF2E3E7A);
  const madder = Color(0xFF9A2E1E);
  const leather = Color(0xFF5A3A22);
  const skin = Color(0xFFE0B080);
  const green = Color(0xFF3A6A3A);
  // Örs ve akkor demir (önde, sağda).
  final strike = math.pow((time * 0.9) % 1, 4).toDouble();
  _fillRim(
    c,
    Path()
      ..moveTo(70, -62)
      ..lineTo(150, -62)
      ..lineTo(140, -48)
      ..lineTo(122, -44)
      ..lineTo(124, 0)
      ..lineTo(96, 0)
      ..lineTo(98, -44)
      ..lineTo(80, -48)
      ..close(),
    const Color(0xFF2A2630),
    a,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(96, -72, 40, 9),
      const Radius.circular(4),
    ),
    _hole(a),
  );
  if (strike > 0.92) {
    final sp = _hole(a);
    for (var i = 0; i < 9; i++) {
      final ang = -math.pi / 2 + (i - 4) * 0.33;
      c.drawCircle(
        const Offset(116, -74) + Offset(math.cos(ang), math.sin(ang)) * 22,
        2.2,
        sp,
      );
    }
  }
  // Bacaklar: bol şalvar (çivit) ve sivri kızıl çarık.
  _fillRim(
    c,
    Path()
      ..moveTo(-34, -112)
      ..cubicTo(-46, -70, -40, -30, -30, -10)
      ..lineTo(-6, -10)
      ..lineTo(-2, -60)
      ..lineTo(4, -10)
      ..lineTo(28, -10)
      ..cubicTo(38, -40, 42, -80, 34, -112)
      ..close(),
    indigo,
    a,
  );
  for (final x in [-18.0, 16.0]) {
    _fillRim(
      c,
      Path()
        ..moveTo(x - 14, -10)
        ..lineTo(x + 12, -10)
        ..quadraticBezierTo(x + 26, -6, x + 24, 0)
        ..lineTo(x - 14, 0)
        ..close(),
      madder,
      a,
    );
  }
  // Gövde: kızıl kaftan, yeşil kuşak, deri önlük.
  final torso = Path()
    ..moveTo(-30, -196)
    ..cubicTo(-46, -180, -44, -140, -40, -108)
    ..lineTo(40, -108)
    ..cubicTo(44, -140, 46, -180, 30, -196)
    ..close();
  _fillRim(c, torso, madder, a);
  _fillRim(
    c,
    Path()..addRect(const Rect.fromLTRB(-41, -126, 41, -112)),
    green,
    a,
  );
  _fillRim(
    c,
    Path()
      ..moveTo(-6, -170)
      ..lineTo(26, -170)
      ..lineTo(36, -48)
      ..lineTo(-4, -48)
      ..close(),
    leather,
    a,
  );
  _punchRow(c, const Offset(-38, -112), const Offset(38, -112), 9, 1.8, a);
  _rosette(c, const Offset(-20, -160), 9, a);
  _punchRow(c, const Offset(2, -60), const Offset(32, -60), 5, 1.6, a);
  // Sol kol: maşayla demiri tutar.
  _fillRim(
    c,
    Path()
      ..moveTo(-28, -188)
      ..quadraticBezierTo(-50, -150, -10, -128)
      ..lineTo(40, -98)
      ..lineTo(44, -106)
      ..lineTo(-2, -138)
      ..quadraticBezierTo(-30, -156, -16, -184)
      ..close(),
    madder,
    a,
  );
  c.drawLine(
    const Offset(42, -102),
    const Offset(104, -70),
    _ink(a)..strokeWidth = 4,
  );
  // Baş: keçe külah, gür sakal, ışık deliği göz.
  _fillRim(
    c,
    Path()..addOval(
      Rect.fromCenter(center: const Offset(4, -222), width: 40, height: 46),
    ),
    skin,
    a,
  );
  _fillRim(
    c,
    Path()
      ..moveTo(-20, -214)
      ..quadraticBezierTo(-22, -176, 4, -168)
      ..quadraticBezierTo(30, -176, 28, -212)
      ..quadraticBezierTo(14, -200, 4, -202)
      ..quadraticBezierTo(-8, -200, -20, -214)
      ..close(),
    const Color(0xFF2A1A12),
    a,
  );
  _fillRim(
    c,
    Path()
      ..moveTo(-20, -232)
      ..quadraticBezierTo(-16, -276, 10, -280)
      ..quadraticBezierTo(30, -270, 26, -232)
      ..close(),
    madder,
    a,
  );
  _punchRow(c, const Offset(-18, -236), const Offset(24, -236), 6, 1.6, a);
  c.drawCircle(const Offset(14, -224), 2.6, _hole(a));
  _fillRim(
    c,
    Path()
      ..moveTo(22, -220)
      ..lineTo(32, -212)
      ..lineTo(22, -208)
      ..close(),
    skin,
    a,
  );
  // Sağ kol: omuz çivisinden çekici kaldırıp indirir.
  const sh = Offset(20, -186);
  final ang = -2.6 + strike * 1.9;
  c.save();
  c.translate(sh.dx, sh.dy);
  c.rotate(ang + math.pi / 2);
  _fillRim(
    c,
    Path()
      ..moveTo(-9, 0)
      ..lineTo(9, 0)
      ..lineTo(7, 62)
      ..lineTo(-7, 62)
      ..close(),
    madder,
    a,
  );
  c.drawLine(
    const Offset(0, 60),
    const Offset(0, 104),
    _ink(a)..strokeWidth = 5,
  );
  _fillRim(
    c,
    Path()
      ..addRect(Rect.fromCenter(center: Offset(0, 106), width: 30, height: 18)),
    const Color(0xFF2A2630),
    a,
  );
  c.restore();
  _rivet(c, sh, a);
  _rivet(c, const Offset(-22, -186), a);
  c.restore();
}

// ------------------------------------------------------------- Bozkurt

/// Bozkurt: gerçek bir kurt silueti (yürüyüş), yelesi ve sırtı zımba
/// süslü, gözü ışık deliği; yolu gösterir.
void _tasvirBozkurt(
  Canvas c,
  Offset feet,
  double height,
  double time,
  double a,
) {
  if (a <= 0) return;
  c.save();
  c.translate(feet.dx, feet.dy + math.sin(time * 1.4) * 1.2);
  c.scale(height / 100);
  c.drawPath(MythShapes.wolfWalk, _ink(a));
  // Sırt ve yele boyunca ince kesik süs, gövdede gül, gözde ışık.
  _punchRow(c, const Offset(-24, -74), const Offset(22, -78), 8, 0.9, a);
  _rosette(c, const Offset(-8, -58), 5, a);
  c.drawCircle(const Offset(50.5, -80), 1.8, _hole(a));
  c.restore();
}

// ------------------------------------------------------- Ana iplik

/// Büyük Sâye: o bir gölgedir, kara kalır; elindeki kavanoz ışır.
void _tasvirSaye(Canvas canvas, Offset feet, double s, double time, double a) {
  if (a <= 0) return;
  _P._c = canvas;
  _P._puppet(
    canvas,
    feet,
    time,
    0.3,
    a,
    (ink, hole) {
      _P._saye(ink, hole, time);
    },
    scale: s,
    rod: false,
  );
}

/// Renkli Hüdhüd: safran tepelik, pembe-kızıl gövde, alaca kanat.
void _tasvirHudhud(Canvas c, Offset at, double s, double time, double a) {
  if (a <= 0) return;
  c.save();
  c.translate(at.dx, at.dy + math.sin(time * 2.2) * 3);
  c.scale(s);
  const body = Color(0xFFC8784A);
  const crest = Color(0xFFE0A030);
  // Kanatlar: geniş, yuvarlak uçlu, kara-ak alaca (Hüdhüd'ün kanadı).
  // Uzaktaki kanat gövdenin ardında, yakındaki önünde; ikisi birlikte
  // çırpar (uzaktaki biraz gecikmeli).
  final flap = math.sin(time * 9);
  // Uzun, yuvarlak uçlu kanat: omuzdan geriye ve yukarı.
  Path wingPath() => Path()
    ..moveTo(2, -4)
    ..cubicTo(-14, -22, -38, -40, -60, -40)
    ..cubicTo(-68, -40, -68, -32, -60, -28)
    ..cubicTo(-40, -18, -20, -4, -2, 4)
    ..close();
  void wing(double angle, double tone) {
    c.save();
    c.rotate(angle);
    final path = wingPath();
    _fillRim(
      c,
      path,
      Color.lerp(const Color(0xFF2A2420), const Color(0xFF14100E), tone)!,
      a,
    );
    // Ak bantlar: kanadı enine kesen ince alaca çizgiler.
    c.save();
    c.clipPath(path);
    final band = _hole(0.6 * a)..strokeWidth = 1.8;
    for (var i = 0; i < 4; i++) {
      final x = -22.0 - i * 10;
      c.drawLine(Offset(x + 10, -46), Offset(x - 2, 0), band);
    }
    c.restore();
    c.restore();
  }

  // Uzaktaki kanat: gövdenin ardında, biraz gecikmeli.
  wing(0.15 + math.sin(time * 9 - 0.7) * 0.4, 1);
  _fillRim(
    c,
    Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 40, height: 22)),
    body,
    a,
  );
  // Kuyruk.
  _fillRim(
    c,
    Path()
      ..moveTo(-18, -2)
      ..lineTo(-40, 4)
      ..lineTo(-38, 10)
      ..lineTo(-16, 4)
      ..close(),
    const Color(0xFF2A2420),
    a,
  );
  // Yakındaki kanat: gövdenin önünde, yukarı çırpar.
  wing(0.05 + flap * 0.45, 0);
  // Baş, uzun ince gaga, yelpaze tepelik.
  _fillRim(
    c,
    Path()..addOval(
      Rect.fromCenter(center: const Offset(20, -8), width: 16, height: 14),
    ),
    body,
    a,
  );
  c.drawLine(
    const Offset(27, -8),
    const Offset(48, -2),
    _ink(a)..strokeWidth = 2,
  );
  // Yelpaze tepelik: safran tüyler, uçları kara.
  final fan = Path()..moveTo(17, -13);
  for (var i = 0; i <= 6; i++) {
    final ang = -2.5 + i * 0.32;
    fan.lineTo(17 + math.cos(ang) * 20, -13 + math.sin(ang) * 20);
  }
  fan.close();
  _fillRim(c, fan, crest, a);
  for (var i = 0; i <= 6; i++) {
    final ang = -2.5 + i * 0.32;
    c.drawCircle(
      Offset(17 + math.cos(ang) * 19, -13 + math.sin(ang) * 19),
      2.6,
      _ink(a),
    );
  }
  c.drawCircle(const Offset(23, -10), 1.6, _hole(a));
  c.restore();
}

/// Kandilci: kara cübbeli, kukuletalı; fenerinde ustanın kandilinin ışığı
/// (çevresine sıcak bir hale düşer).
void _tasvirKandilci(
  Canvas canvas,
  Offset feet,
  double s,
  double time,
  double a,
) {
  if (a <= 0) return;
  _P._c = canvas;
  final lantern = feet + Offset(88 * s, -196 * s);
  canvas.drawCircle(
    lantern,
    60 * s,
    Paint()
      ..shader = ui.Gradient.radial(lantern, 60 * s, [
        const Color(0xFFFFE0A0).withValues(alpha: 0.75 * a),
        const Color(0x00FFE0A0),
      ]),
  );
  _P._puppet(
    canvas,
    feet,
    time,
    1.7,
    a,
    (ink, hole) {
      _P._lamplighter(ink, hole);
    },
    scale: s,
    rod: false,
  );
}

/// Her perdenin son satırı: ana iplik. Sâye önde, omzunun üstünde Hüdhüd;
/// ileride bir Kandilci ustanın kandiliyle perdeden çıkar; Sâye ardından
/// yürür. [k] satır numarası.
void _chaseBeat(Canvas canvas, double time, double u, double k) {
  final a = _enter(u, k) * (1 - _leave(u, k));
  if (a <= 0) return;
  _veil(canvas, a);
  const g = PerdePainter._ground;
  final go = _span(u, k + 0.3, k + 0.95);
  // Kandilci sağdan çıkar.
  _tasvirKandilci(canvas, Offset(500 + go * 340, g + 12), 1.3, time, a);
  // Sâye ve Hüdhüd ardından.
  _tasvirSaye(canvas, Offset(170 + go * 130, g + 12), 2.4, time, a);
  _tasvirHudhud(canvas, Offset(250 + go * 140, g - 285), 1.7, time, a);
}

/// Ana iplikte yalnız Sâye ve Hüdhüd (Kandilci yok): yola bakar, yürür.
void _sayeBeat(Canvas canvas, double time, double u, double k) {
  final a = _enter(u, k) * (1 - _leave(u, k));
  if (a <= 0) return;
  _veil(canvas, a);
  const g = PerdePainter._ground;
  final go = _span(u, k + 0.3, k + 0.95);
  _tasvirSaye(canvas, Offset(260 + go * 140, g + 12), 2.4, time, a);
  _tasvirHudhud(canvas, Offset(355 + go * 150, g - 285), 1.7, time, a);
}

// ------------------------------------------------------------ yardımcılar

/// Kahraman satırının görünürlüğü.
double _heroA(double u, double k) => _enter(u, k) * (1 - _leave(u, k));

/// Gerçek bir siluetten tasvir: mürekkep deri, isteğe bağlı göz deliği ve
/// göğüste zımba süsü. [h] piksel boy, ayaklar [feet]'te.
void _cut(
  Canvas c,
  Path shape,
  Offset feet,
  double h,
  double a, {
  bool flip = false,
  double rot = 0,
  Offset? eye,
  bool deco = true,
}) {
  if (a <= 0) return;
  final s = h / 100;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.rotate(rot);
  c.scale(flip ? -s : s, s);
  c.drawPath(shape, _ink(a));
  if (eye != null) c.drawCircle(eye, 2.6 / s, _hole(a));
  if (deco) {
    _rosette(c, const Offset(1, -58), 6 / s, a);
    _punchRow(c, const Offset(-8, -46), const Offset(9, -46), 5, 1.4 / s, a);
  }
  c.restore();
}

/// Kanat çifti (Hezarfen, peri, melek): omuz noktasından açılır.
void _wings(Canvas c, Offset at, double size, double spread, double a) {
  for (final side in [-1.0, 1.0]) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(side * size / 60, size / 60);
    c.rotate(-0.2 - spread);
    c.drawPath(MythFigures.wingSilhouette, _ink(a));
    c.restore();
  }
}

/// Ejder: dağ gibi kıvrılan, sırtı dikenli, boynuzlu gövde; uyurken gözü
/// kapalı çizgi, uyanınca ışık deliği ve ağzından kar soluğu.
void _ejder(
  Canvas c,
  Offset head,
  double s,
  double time,
  double a, {
  bool awake = false,
  int dir = 1,
}) {
  if (a <= 0) return;
  c.save();
  c.translate(head.dx, head.dy);
  c.scale(dir * s, s);
  final ink = _ink(a);
  // Gövde: başın ardından dalga dalga geriye kıvrılır.
  final body = <Offset>[];
  for (var i = 0; i <= 24; i++) {
    final t = i / 24;
    body.add(
      Offset(
        -30 - t * 260,
        10 + math.sin(t * math.pi * 2.4 + time * 0.8) * 24 + t * 30,
      ),
    );
  }
  for (var i = 0; i < body.length; i++) {
    final r = 22 - i * 0.7;
    c.drawCircle(body[i], math.max(5, r), ink);
    if (i.isEven && i > 1) {
      // Sırt dikeni.
      c.drawPath(
        Path()
          ..moveTo(body[i].dx - 6, body[i].dy - r + 2)
          ..lineTo(body[i].dx, body[i].dy - r - 14)
          ..lineTo(body[i].dx + 6, body[i].dy - r + 2)
          ..close(),
        ink,
      );
    }
  }
  // Baş: uzun çene, boynuzlar.
  final jaw = awake ? 0.35 + 0.1 * math.sin(time * 4) : 0.05;
  c.drawPath(
    Path()
      ..moveTo(-34, -14)
      ..quadraticBezierTo(0, -30, 46, -10)
      ..lineTo(40, 0)
      ..lineTo(-30, 8)
      ..close(),
    ink,
  );
  c.save();
  c.translate(-20, 4);
  c.rotate(jaw);
  c.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(60, 2)
      ..lineTo(54, 12)
      ..lineTo(0, 14)
      ..close(),
    ink,
  );
  c.restore();
  for (final (bx, tx, ty) in [(-22.0, -50.0, -54.0), (-12.0, -30.0, -58.0)]) {
    c.drawPath(
      Path()
        ..moveTo(bx - 5, -18)
        ..quadraticBezierTo(bx - 4, -40, tx, ty)
        ..quadraticBezierTo(bx + 4, -34, bx + 6, -18)
        ..close(),
      ink,
    );
  }
  if (awake) {
    c.drawCircle(const Offset(10, -14), 4, _hole(a));
    // Soluk: karla dolu ışık zerreleri.
    final p = _hole(0.7 * a);
    for (var i = 0; i < 14; i++) {
      final k = ((time * 0.8 + i / 14) % 1);
      c.drawCircle(
        Offset(60 + k * 160, 6 + math.sin(i * 2.1) * k * 40),
        2 + k * 3,
        p,
      );
    }
  } else {
    c.drawLine(
      const Offset(4, -14),
      const Offset(16, -12),
      _hole(0.7 * a)..strokeWidth = 2,
    );
  }
  c.restore();
}

/// Kavuklu, uzun cüppeli bir insan tasviri (derviş, Mevlânâ): siluetin
/// üstüne uzun sikke.
void _dervish(Canvas c, Offset feet, double h, double a, {bool flip = false}) =>
    _person(c, feet, h, a, _dervishLook, flip: flip);

// ---------------------------------------------------------- kahramanlar

/// Bölüm perdelerinin kahraman satırları ve ana iplik.
void _heroOverlay(Canvas canvas, PerdeScene scene, double time, double u) {
  _P._c = canvas;
  const g = PerdePainter._ground;
  final c = canvas;
  void stage(double k, void Function(double a) draw) {
    final a = _heroA(u, k);
    if (a <= 0) return;
    _veil(canvas, a);
    draw(a);
  }

  switch (scene) {
    // Erlik perdesi Ak Ana sahnesinin devamıdır: kahramanları da öyle.
    case PerdeScene.erlik:
      _heroOverlay(canvas, PerdeScene.akAna, time, u + 3);
    case PerdeScene.galata || PerdeScene.skyroad || PerdeScene.kaf:
      // Satır tasvirleri sahnenin kendisinde (PerdePainter._galata, _kaf).
      break;
    case PerdeScene.mirror:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.flood:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.gods:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.dawn:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.caravan:
      // Usta zincirli; kandili bir mum kadar.
      stage(1, (a) {
        _P._puppet(
          canvas,
          const Offset(380, g + 12),
          time,
          0.9,
          a,
          (ink, hole) {
            _P._master(ink, hole);
          },
          scale: 2.0,
          rod: false,
        );
        final chain = _ink(a)..strokeWidth = 3;
        for (var i = 0; i < 8; i++) {
          final t = i / 8;
          c.drawOval(
            Rect.fromCenter(
              center: Offset(350 - t * 120, g - 80 + t * 90),
              width: 14,
              height: 8,
            ),
            chain..style = PaintingStyle.stroke,
          );
        }
        c.drawCircle(const Offset(410, g - 150), 5, _hole(0.6 * a));
      });
      _chaseBeat(canvas, time, u, 2);
      stage(5, (a) {
        _tasvirBozkurt(
          c,
          Offset(330 + 140 * _span(u, 5.0, 6.0), g + 10),
          230,
          time,
          a,
        );
      });
    case PerdeScene.dragons:
      // İki ejder kardeş doruklarda uyur.
      stage(1, (a) {
        _ejder(c, const Offset(560, 170), 1.0, time, a, dir: -1);
        _ejder(c, const Offset(260, 230), 0.8, time + 2, a);
      });
      // Derviş zirvede dua eder; kar yağar.
      stage(2, (a) {
        _dervish(c, const Offset(390, g + 12), 240, a);
        final p = _hole(0.6 * a);
        for (var i = 0; i < 50; i++) {
          c.drawCircle(
            Offset((i * 83.0) % 780, (i * 47.0 + time * 60) % 360),
            2,
            p,
          );
        }
      });
      _chaseBeat(canvas, time, u, 4);
    case PerdeScene.avalanche:
      _chaseBeat(canvas, time, u, 0);
      // Ejder uyanır, soluğu kar olur.
      stage(1, (a) {
        _ejder(
          c,
          Offset(560 - 20 * _span(u, 1.0, 2.0), 190),
          1.25,
          time,
          a,
          dir: -1,
          awake: true,
        );
      });
      // Çığın önünde Gökbörü.
      stage(4, (a) {
        _tasvirBozkurt(
          c,
          Offset(160 + 380 * _span(u, 4.0, 5.0), g + 10),
          210,
          time,
          a,
        );
      });
    case PerdeScene.fairies:
      // Peri: kanatlı, ışıklı.
      stage(2, (a) {
        c.drawCircle(const Offset(390, 140), 70, _hole(0.35 * a));
        _wings(
          c,
          const Offset(390, g - 180),
          130,
          0.15 + math.sin(time * 2.5) * 0.12,
          a,
        );
        _person(c, const Offset(390, g + 12), 250, a, _periBare);
      });
      _sayeBeat(canvas, time, u, 3);
      stage(4, (a) {
        _cut(
          c,
          MythFigures.albastiSilhouette,
          const Offset(420, g + 12),
          270,
          a,
          eye: const Offset(6, -88),
        );
      });
    case PerdeScene.underground:
      _chaseBeat(canvas, time, u, 0);
      // Peri Padişahı ateşli devi yerin altına sürer.
      stage(2, (a) {
        _person(c, const Offset(520, g + 80), 260, a, _giant, flip: true);
        final p = _hole(0.7 * a);
        for (var i = 0; i < 10; i++) {
          c.drawCircle(
            Offset(
              470 + (i % 4) * 30.0,
              g - 60 - (i ~/ 4) * 60 + math.sin(time * 5 + i) * 6,
            ),
            4,
            p,
          );
        }
        _person(c, const Offset(230, g + 12), 220, a, _periQueen);
      });
      // Erlik: yerin dibinden boynuzlu bir gölge.
      stage(4, (a) {
        final rise = _span(u, 4.05, 4.6);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        final f = Offset(390, g + 220 - 210 * rise);
        _person(c, f, 260, a, _erlik);
        c.restore();
      });
    case PerdeScene.sema:
      // Mevlânâ: "Bu benim düğünümdür."
      stage(3, (a) {
        _dervish(c, const Offset(390, g + 12), 260, a);
        c.drawCircle(const Offset(390, 70), 40, _hole(0.3 * a));
      });
      _chaseBeat(canvas, time, u, 4);
      stage(5, (a) {
        _cut(c, MythShapes.wolfHowl, const Offset(430, g + 10), 220, a);
      });
    case PerdeScene.akAna:
      // Kayra Han suyun üstünde yalnız.
      stage(1, (a) {
        final p = _hole(0.4 * a);
        for (var i = 0; i < 12; i++) {
          final ang = i / 12 * math.pi * 2 + time * 0.2;
          c.drawLine(
            const Offset(390, 120) + Offset(math.cos(ang), math.sin(ang)) * 70,
            const Offset(390, 120) + Offset(math.cos(ang), math.sin(ang)) * 110,
            p..strokeWidth = 3,
          );
        }
        _person(c, const Offset(390, g - 20), 230, a, _kayra);
      });
      // Ak Ana sudan yükselir: "Yarat."
      stage(2, (a) {
        final rise = _span(u, 2.05, 2.6);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        _person(c, Offset(390, g + 170 - 170 * rise), 290, a, _akAna);
        c.restore();
      });
      // Erlik yerin altına sürülür.
      stage(3, (a) {
        final fall = _span(u, 3.2, 3.9);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        _person(
          c,
          Offset(470, g + 12 + fall * 260),
          220,
          a,
          _erlik,
          flip: true,
        );
        c.restore();
        _person(c, const Offset(250, g + 12), 250, a, _kayra);
      });
      _chaseBeat(canvas, time, u, 4);
      // Er Töştük, konuşan atı Çalkuyruk'la.
      stage(5, (a) {
        final x = 260 + 220 * _span(u, 5.0, 6.0);
        _cut(
          c,
          MythShapes.horse,
          Offset(x, g + 10),
          200,
          a,
          eye: const Offset(48, -82),
        );
        _person(c, Offset(x - 8, g - 120), 130, a, _erTostuk);
      });
      // Körmösler: Erlik'in gölgeleri, ışık delikli gözler.
      stage(6, (a) {
        for (var i = 0; i < 3; i++) {
          _person(
            c,
            Offset(220 + i * 170.0, g + 12 + math.sin(time * 2 + i) * 4),
            200 + i * 20.0,
            a,
            _kormos,
            flip: i.isOdd,
          );
        }
      });
    case PerdeScene.gok:
      // Kam davulunu çalar.
      stage(0, (a) {
        _cut(c, MythFigures.kamSilhouette, const Offset(390, g + 12), 270, a);
      });
      // Ülgen'in ışığı en yüksek katta.
      stage(1, (a) {
        c.save();
        c.translate(390, 300);
        c.scale(2.2);
        MythFigures.ulgenLight(c, time);
        c.restore();
      });
      // Hüma'nın gölgesi kimin başına düşerse.
      stage(3, (a) {
        c.save();
        c.translate(390, 150 + math.sin(time * 1.4) * 8);
        c.scale(4.2);
        c.drawPath(MythShapes.birdGlide, _ink(a));
        c.restore();
        _tasvirSaye(canvas, const Offset(390, g + 12), 2.0, time, a);
      });
      _chaseBeat(canvas, time, u, 4);
    case PerdeScene.prologue ||
        PerdeScene.ergenekon ||
        PerdeScene.otuken ||
        PerdeScene.epilogue:
      // Önsöz ve son kendi tasvirleriyle; Ergenekon ve Ötüken sahnenin
      // içinde.
      break;
  }
}

// ------------------------------------------------------------- Yerebatan

/// Önsözün sarnıç satırları (6-10): sütun ormanı ve kemerler, su ve
/// yansıması; Sâye gözünü açar, Justinianus sütunları diktirir, Ağlayan
/// Sütun, evlerin tabanından sarkan kovalar ve balıkçı, suyun üstünde
/// yürüyen gölge.
void _cistern(Canvas c, double time, double u) {
  const water = 300.0;
  final a = _span(u, 5.6, 6.1);
  // Sütunlar: arka sıra soluk ve kısa, ön sıra koyu; Justinianus satırında
  // sudan yükselir.
  final rise = u < 7 ? 1.0 : (u < 8 ? 0.15 + 0.85 * _span(u, 7.15, 7.9) : 1.0);
  for (var row = 0; row < 2; row++) {
    final back = row == 0;
    final spacing = back ? 70.0 : 130.0;
    final colW = back ? 14.0 : 26.0;
    final top = back ? 70.0 : 10.0;
    final ink = _ink(a * (back ? 0.45 : 0.95));
    for (var x = back ? 30.0 : 0.0; x < 800; x += spacing) {
      final h = (water - top) * rise;
      final y0 = water - h;
      // Gövde ve başlık.
      c.drawRect(Rect.fromLTWH(x - colW / 2, y0, colW, h), ink);
      c.drawRect(
        Rect.fromLTWH(x - colW * 0.9, y0, colW * 1.8, back ? 6 : 12),
        ink,
      );
      // Kemer: komşu sütuna.
      if (rise >= 0.99) {
        c.drawPath(
          Path()
            ..moveTo(x + colW * 0.9, top)
            ..quadraticBezierTo(
              x + spacing / 2,
              top + (back ? 26 : 46),
              x + spacing - colW * 0.9,
              top,
            )
            ..lineTo(x + spacing - colW * 0.9, top - 10)
            ..lineTo(x + colW * 0.9, top - 10)
            ..close(),
          ink,
        );
      }
      // Sudaki yansıma: kırık kırık titrer.
      if (!back) {
        for (var k = 0; k < 6; k++) {
          final yy = water + 6 + k * 8.0;
          final off = math.sin(time * 2 + k + x * 0.05) * 3;
          c.drawRect(
            Rect.fromLTWH(x - colW / 2 + off, yy, colW, 4),
            _ink(a * 0.35 * (1 - k / 6)),
          );
        }
      }
    }
  }
  // Tavan.
  c.drawRect(const Rect.fromLTWH(0, 0, 780, 10), _ink(a));
  // Su yüzü: ince ışık çizgileri.
  final glint = _hole(0.35 * a);
  for (var i = 0; i < 18; i++) {
    final x = (i * 53.0 + time * 12) % 800 - 10;
    c.drawLine(
      Offset(x, water + 2 + (i % 3) * 6),
      Offset(x + 20, water + 2 + (i % 3) * 6),
      glint..strokeWidth = 1.5,
    );
  }

  // 6: Sâye gözünü suyun ortasında açar; çevresinde halkalar.
  final wake = _heroA(u, 6);
  if (wake > 0) {
    for (var k = 0; k < 3; k++) {
      final r = 20 + ((time * 0.6 + k / 3) % 1) * 80;
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(390, water + 4),
          width: r * 2,
          height: r * 0.35,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = PerdePainter._hole.withValues(
            alpha: 0.5 * wake * (1 - r / 100),
          ),
      );
    }
    _tasvirSaye(c, const Offset(390, water + 4), 1.8, time, wake);
  }

  // 7: Justinianus (taçlı, başının ardında hale) sütunları diktirir; taş
  // taşıyan işçiler.
  final emp = _heroA(u, 7);
  if (emp > 0) {
    _veil(c, emp * 0.6);
    c.drawCircle(const Offset(200, 108), 34, _hole(0.55 * emp));
    _person(c, const Offset(200, water + 4), 240, emp, _justinian);
    c.drawPath(
      Path()
        ..moveTo(184, 116)
        ..lineTo(186, 96)
        ..lineTo(194, 108)
        ..lineTo(200, 92)
        ..lineTo(206, 108)
        ..lineTo(214, 96)
        ..lineTo(216, 116)
        ..close(),
      _ink(emp),
    );
    for (var i = 0; i < 3; i++) {
      final wx = 430 + i * 90.0 + _span(u, 7.0, 8.0) * 40;
      _person(c, Offset(wx, water + 4), 110, emp, _worker, flip: true);
      c.drawRect(
        Rect.fromCenter(
          center: Offset(wx - 6, water - 112),
          width: 36,
          height: 22,
        ),
        _ink(emp),
      );
    }
  }

  // 8: Ağlayan Sütun: gövdesinden damlalar iner; dibinde zincirli köleler.
  final weep = _heroA(u, 8);
  if (weep > 0) {
    _veil(c, weep * 0.55);
    c.drawRect(const Rect.fromLTWH(372, 10, 36, water - 10), _ink(weep));
    c.drawRect(const Rect.fromLTWH(360, 10, 60, 16), _ink(weep));
    // Gövdedeki gözyaşı damarları ve inen damlalar.
    for (var k = 0; k < 5; k++) {
      final x = 378 + k * 6.0;
      c.drawLine(
        Offset(x, 40),
        Offset(x + 1, water - 10),
        _hole(0.25 * weep)..strokeWidth = 1.2,
      );
      final y = 40 + ((time * 0.5 + k * 0.23) % 1) * (water - 50);
      c.drawCircle(Offset(x, y), 2.4, _hole(0.8 * weep));
    }
    for (var i = 0; i < 4; i++) {
      final sx = 240 + i * 60.0 + (i >= 2 ? 160 : 0);
      _person(
        c,
        Offset(sx, water + 4),
        120,
        weep,
        _slave,
        rot: (i.isEven ? 0.25 : -0.25),
        flip: i >= 2,
      );
    }
    final chain = _ink(weep)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var i = 0; i < 14; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(250 + i * 21.0, water - 40),
          width: 12,
          height: 7,
        ),
        chain,
      );
    }
  }

  // 9: Unutulan sarnıç: tavanın üstünde evler, tabanlarından sarkan
  // kovalar; oltaya takılan bir balık.
  final forgot = _heroA(u, 9);
  if (forgot > 0) {
    _veil(c, forgot * 0.4);
    // Tavanda evlerin tabanına açılmış kova delikleri: yukarıdan ışık.
    for (var i = 0; i < 3; i++) {
      final hx = 150 + i * 240.0;
      c.drawRect(Rect.fromLTWH(hx - 12, 0, 24, 10), _hole(0.9 * forgot));
      c.drawPath(
        Path()
          ..moveTo(hx - 12, 10)
          ..lineTo(hx + 12, 10)
          ..lineTo(hx + 40, water)
          ..lineTo(hx - 40, water)
          ..close(),
        _hole(0.12 * forgot),
      );
    }
    // Kovalar: halatla iner çıkar.
    for (var i = 0; i < 3; i++) {
      final bx = 150 + i * 240.0;
      final by =
          80 + (math.sin(time * 0.9 + i * 2) * 0.5 + 0.5) * (water - 110);
      c.drawLine(Offset(bx, 10), Offset(bx, by), _ink(forgot)..strokeWidth = 2);
      c.drawPath(
        Path()
          ..moveTo(bx - 14, by)
          ..lineTo(bx + 14, by)
          ..lineTo(bx + 10, by + 22)
          ..lineTo(bx - 10, by + 22)
          ..close(),
        _ink(forgot),
      );
    }
    // Olta ve sıçrayan balık.
    c.drawLine(
      const Offset(520, 10),
      const Offset(560, water - 10),
      _ink(forgot)..strokeWidth = 1.5,
    );
    final jump = (time * 0.7) % 1;
    final fy = water - math.sin(jump * math.pi) * 60;
    final fish = Path()
      ..moveTo(560, fy)
      ..quadraticBezierTo(580, fy - 12, 600, fy)
      ..quadraticBezierTo(580, fy + 12, 560, fy)
      ..moveTo(598, fy)
      ..lineTo(612, fy - 9)
      ..lineTo(612, fy + 9)
      ..close();
    c.drawPath(fish, _ink(forgot));
    c.drawCircle(Offset(566, fy - 2), 1.8, _hole(forgot));
  }

  // 10: Şimdi o sularda bir gölge yürür; suda yansıması.
  final walk = _heroA(u, 10);
  if (walk > 0) {
    final x = 160 + _span(u, 10.05, 10.95) * 460;
    _tasvirSaye(c, Offset(x, water + 4), 2.0, time, walk);
    c.save();
    c.translate(x, water + 8);
    c.scale(1, -0.5);
    c.translate(-x, -(water + 8));
    _tasvirSaye(c, Offset(x, water + 8), 2.0, time, walk * 0.3);
    c.restore();
  }
}

/// Güvercin: yuvarlak gövde, küçük baş, yelpaze kuyruk, kalkık kanatlar.
void _dove(
  Canvas c,
  Offset at,
  double s,
  double time,
  double a, {
  bool flip = false,
}) {
  if (a <= 0) return;
  final ink = _ink(a);
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(flip ? -s : s, s);
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: 34, height: 18), ink);
  c.drawCircle(const Offset(16, -7), 7, ink);
  c.drawPath(
    Path()
      ..moveTo(22, -7)
      ..lineTo(29, -5)
      ..lineTo(22, -3)
      ..close(),
    ink,
  );
  c.drawPath(
    Path()
      ..moveTo(-14, -2)
      ..lineTo(-30, -9)
      ..lineTo(-32, 4)
      ..lineTo(-14, 4)
      ..close(),
    ink,
  );
  final flap = math.sin(time * 10) * 0.5;
  c.save();
  c.rotate(-0.3 + flap);
  c.drawPath(
    Path()
      ..moveTo(-6, -4)
      ..quadraticBezierTo(-10, -34, 8, -40)
      ..quadraticBezierTo(4, -20, 6, -4)
      ..close(),
    ink,
  );
  c.restore();
  c.drawCircle(const Offset(18, -8), 1.4, _hole(a));
  c.restore();
}

/// Kavuklu sultan: siluetin üstüne iri, yuvarlak kavuk.
void _sultan(Canvas c, Offset feet, double h, double a, {bool flip = false}) =>
    _person(c, feet, h, a, _sultanLook, flip: flip);

/// Yelkenli: sürgün gemisi.
void _ship(Canvas c, Offset at, double s, double a) {
  final ink = _ink(a);
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(s);
  c.drawPath(
    Path()
      ..moveTo(-50, 0)
      ..lineTo(50, 0)
      ..lineTo(36, 16)
      ..lineTo(-38, 16)
      ..close(),
    ink,
  );
  c.drawLine(const Offset(0, 0), const Offset(0, -70), ink..strokeWidth = 3);
  c.drawPath(
    Path()
      ..moveTo(4, -66)
      ..quadraticBezierTo(40, -40, 4, -8)
      ..close(),
    ink,
  );
  _punchRow(c, const Offset(-40, 8), const Offset(30, 8), 6, 2, a);
  c.restore();
}

/// Boş kalan satırlar: her satır kendi tasviriyle; son perde baştan sona.
void _heroExtra(Canvas canvas, PerdeScene scene, double time, double u) {
  _P._c = canvas;
  const g = PerdePainter._ground;
  final c = canvas;
  void stage(double k, void Function(double a) draw, {double veil = 1}) {
    final a = _heroA(u, k);
    if (a <= 0) return;
    _veil(canvas, a * veil);
    draw(a);
  }

  switch (scene) {
    case PerdeScene.mirror:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.flood:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.gods:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.dawn:
      // Satır satır resimleri sahnenin içinde (perde_east.dart).
      break;
    case PerdeScene.caravan:
      // Sâye ışığa dokunur.
      stage(0, (a) {
        c.drawCircle(const Offset(470, 190), 70, _hole(0.6 * a));
        c.drawCircle(const Offset(470, 190), 30, _hole(0.9 * a));
        _tasvirSaye(canvas, const Offset(330, g + 12), 2.4, time, a);
      });
      // Erzurum: kalesi ve çifte minaresiyle kışın kapısı.
      stage(3, (a) {
        c.drawRect(const Rect.fromLTWH(140, g - 120, 500, 132), _ink(a));
        for (var x = 140.0; x < 640; x += 30) {
          c.drawRect(Rect.fromLTWH(x, g - 140, 16, 22), _ink(a));
        }
        c.drawPath(
          Path()
            ..moveTo(350, g + 12)
            ..lineTo(350, g - 60)
            ..quadraticBezierTo(390, g - 110, 430, g - 60)
            ..lineTo(430, g + 12)
            ..close(),
          _hole(0.7 * a),
        );
        for (final x in [520.0, 580.0]) {
          c.drawRect(Rect.fromLTWH(x - 9, g - 250, 18, 130), _ink(a));
          c.drawPath(
            Path()
              ..moveTo(x - 11, g - 250)
              ..lineTo(x, g - 290)
              ..lineTo(x + 11, g - 250)
              ..close(),
            _ink(a),
          );
        }
        final p = _hole(0.6 * a);
        for (var i = 0; i < 40; i++) {
          c.drawCircle(
            Offset((i * 71.0) % 780, (i * 43.0 + time * 50) % 360),
            2,
            p,
          );
        }
      });
      // Palandöken: yokuşta palanlar kayar, yük uçuruma dökülür.
      stage(4, (a) {
        c.save();
        c.translate(390, g - 20);
        c.rotate(0.25);
        _P._c = c;
        _P._puppet(
          c,
          Offset.zero,
          time,
          0.4,
          a,
          (ink, hole) => _camel(ink, hole, time),
          scale: 2.0,
          rod: false,
        );
        c.restore();
        final fall = (time * 0.6) % 1;
        for (var i = 0; i < 3; i++) {
          c.drawRect(
            Rect.fromCenter(
              center: Offset(
                470 + fall * 140 + i * 18,
                g - 120 + fall * fall * 200 + i * 10,
              ),
              width: 30,
              height: 20,
            ),
            _ink(a),
          );
        }
      });
    case PerdeScene.dragons:
      // Fırtına nefesleri, sis uykuları.
      stage(3, (a) {
        _ejder(c, const Offset(560, 220), 1.15, time, a, dir: -1);
        final p = _hole(0.35 * a);
        for (var i = 0; i < 10; i++) {
          final k = ((time * 0.3 + i / 10) % 1);
          c.drawCircle(
            Offset(560 - 70 - k * 300, 220 - k * 80 + math.sin(i * 1.3) * 20),
            10 + k * 30,
            p,
          );
        }
      });
    case PerdeScene.fairies:
      // Katpatuka: güzel atlar ülkesi; yanardağın külünü rüzgâr oyar.
      stage(1, (a) {
        c.drawPath(
          Path()
            ..moveTo(420, g + 12)
            ..lineTo(560, 60)
            ..lineTo(600, 70)
            ..lineTo(760, g + 12)
            ..close(),
          _ink(a * 0.7),
        );
        final p = _hole(0.4 * a);
        for (var i = 0; i < 8; i++) {
          final k = ((time * 0.2 + i / 8) % 1);
          c.drawCircle(Offset(580 - k * 200, 60 - k * 40), 8 + k * 20, p);
        }
        for (var i = 0; i < 3; i++) {
          final x = 140 + i * 110.0 + _span(u, 1.0, 2.0) * 60;
          _cut(
            c,
            MythShapes.horse,
            Offset(x, g + 10 - math.sin(time * 6 + i) * 6),
            150 - i * 15.0,
            a,
            eye: const Offset(48, -82),
            deco: false,
          );
        }
      });
    case PerdeScene.underground:
      // Yuvarlak taş kapı: yalnız içeriden açılır.
      stage(3, (a) {
        c.drawRect(const Rect.fromLTWH(0, 40, 780, g - 28), _ink(a * 0.9));
        c.drawRect(
          const Rect.fromLTWH(300, 120, 200, g - 108),
          _hole(0.55 * a),
        );
        final roll = _span(u, 3.2, 3.8);
        final cx = 400 - roll * 150;
        c.save();
        c.translate(cx, g - 70);
        c.rotate(-roll * 2.5);
        c.drawCircle(Offset.zero, 82, _ink(a));
        c.drawCircle(Offset.zero, 14, _hole(0.8 * a));
        _rosette(c, const Offset(0, -46), 10, a);
        c.restore();
        _tasvirSaye(canvas, const Offset(470, g + 12), 1.6, time, a * roll);
      }, veil: 0.3);
    case PerdeScene.sema:
      // Tulpar Sâye'yi karlı ovaya indirir; gökte ay.
      stage(0, (a) {
        c.drawCircle(const Offset(640, 70), 28, _hole(0.8 * a));
        final k = _span(u, 0.05, 0.9);
        final at = Offset(180 + k * 280, 150 + k * 190);
        _cut(
          c,
          MythShapes.horse,
          at,
          170,
          a,
          eye: const Offset(48, -82),
          deco: false,
        );
        _wings(
          c,
          at + const Offset(6, -128),
          100,
          0.4 + math.sin(time * 3) * 0.25,
          a,
        );
        _tasvirSaye(canvas, at + const Offset(-6, -98), 1.0, time, a);
      });
      // Şeb-i Arûs: düğün gecesi; semâzen döner.
      stage(2, (a) {
        _semazenPuppet(c, const Offset(390, g + 12), time * 3, a);
        c.save();
        c.translate(390, g + 12);
        c.scale(2.3);
        c.translate(-390, -(g + 12));
        _semazenPuppet(c, const Offset(390, g + 12), time * 3, a);
        c.restore();
      });
    case PerdeScene.akAna:
      // Taşın altında su sesi: Sâye kulağını taşa dayar.
      stage(0, (a) {
        c.drawRect(const Rect.fromLTWH(420, 0, 360, 400), _ink(a));
        _tasvirSaye(canvas, const Offset(370, g + 12), 2.4, time, a);
        final p = _hole(0.7 * a);
        for (var i = 0; i < 6; i++) {
          final y = 40 + ((time * 0.7 + i / 6) % 1) * 300;
          c.drawCircle(Offset(470 + (i % 3) * 60.0, y), 3, p);
        }
      });
    case PerdeScene.ergenekon:
      // Kıyan ile Nüküz, eşleriyle vadiye sığınır.
      stage(0, (a) {
        final k = _span(u, 0.05, 0.95);
        for (var i = 0; i < 4; i++) {
          final x = 140 + k * 200 + i * 80.0;
          _person(
            c,
            Offset(x, g + 12),
            i.isEven ? 210 : 190,
            a,
            (i % 4 == 0
                ? _kiyan
                : i % 4 == 1
                ? _woman
                : i % 4 == 2
                ? _nukuz
                : _woman2),
          );
        }
      });
      // Nevruz: her yıl o gün demir ateşte kızdırılır, örste dövülür.
      stage(5, (a) {
        c.drawCircle(
          Offset(620, 120 - 30 * _span(u, 5.0, 6.0)),
          46,
          _hole(0.6 * a),
        );
        _tasvirDemirci(canvas, const Offset(260, g + 12), 1.0, time, a);
      });
    case PerdeScene.gok:
      // Bir katında ay soğuk, bir katında güneş yakar.
      stage(2, (a) {
        c.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addOval(
              Rect.fromCircle(center: const Offset(230, 170), radius: 80),
            ),
            Path()..addOval(
              Rect.fromCircle(center: const Offset(262, 150), radius: 70),
            ),
          ),
          _hole(0.8 * a),
        );
        c.drawCircle(const Offset(560, 170), 70, _hole(0.9 * a));
        final ray = _hole(0.6 * a)..strokeWidth = 4;
        for (var i = 0; i < 16; i++) {
          final ang = i / 16 * math.pi * 2 + time * 0.3;
          c.drawLine(
            const Offset(560, 170) + Offset(math.cos(ang), math.sin(ang)) * 84,
            const Offset(560, 170) + Offset(math.cos(ang), math.sin(ang)) * 120,
            ray,
          );
        }
        c.drawLine(
          const Offset(390, 20),
          const Offset(390, 330),
          _ink(a)..strokeWidth = 4,
        );
      });
    case PerdeScene.epilogue:
      _epilogueStage(canvas, time, u);
    default:
      break;
  }
}

/// Son perde: her satır kendi sahnesiyle.
void _epilogueStage(Canvas c, double time, double u) {
  const g = PerdePainter._ground;
  void stage(double k, void Function(double a) draw, {double veil = 0.8}) {
    final a = _heroA(u, k);
    if (a <= 0) return;
    _veil(c, a * veil);
    draw(a);
  }

  void master(Offset feet, double s, double a) => _P._puppet(
    c,
    feet,
    time,
    0.9,
    a,
    (ink, hole) => _P._master(ink, hole),
    scale: s,
    rod: false,
  );
  void lamp(Offset at, double r, double a) {
    c.drawCircle(
      at,
      r * 2.4,
      Paint()
        ..shader = ui.Gradient.radial(at, r * 2.4, [
          const Color(0xFFFFE0A0).withValues(alpha: 0.7 * a),
          const Color(0x00FFE0A0),
        ]),
    );
    c.drawCircle(at, r, _hole(a));
  }

  // 0: Yeşil Kubbe'nin tepesinde, karın altında bir kandil.
  stage(0, (a) {
    _greenDome(c, 390, a, scale: 2.2);
    lamp(const Offset(390, 70), 7, a);
  });
  // 1: Usta ve çevresinde halka olmuş Kandilciler.
  stage(1, (a) {
    master(const Offset(390, g + 12), 1.9, a);
    lamp(const Offset(430, g - 150), 6, a);
    for (var i = 0; i < 4; i++) {
      final x = i < 2 ? 120 + i * 90.0 : 570 + (i - 2) * 90.0;
      _tasvirKandilci(c, Offset(x, g + 12), 1.05, time, a);
    }
  });
  // 2: "Geldin," dedi usta.
  stage(2, (a) {
    master(const Offset(470, g + 12), 1.9, a);
    _tasvirSaye(c, const Offset(270, g + 12), 2.2, time, a);
  });
  // 3: Kandilciler gölgesiz; kırık güneş.
  stage(3, (a) {
    for (var i = 0; i < 5; i++) {
      final ang = i / 5 * math.pi * 2;
      c.drawPath(
        Path()
          ..moveTo(390, 120)
          ..lineTo(390 + math.cos(ang) * 70, 120 + math.sin(ang) * 70)
          ..lineTo(
            390 + math.cos(ang + 1.1) * 70,
            120 + math.sin(ang + 1.1) * 70,
          )
          ..close(),
        _hole(0.8 * a),
      );
    }
    for (var i = 0; i < 3; i++) {
      _tasvirKandilci(c, Offset(220 + i * 170.0, g + 12), 1.15, time, a);
    }
  });
  // 4: Mevlânâ'nın düğün gecesi.
  stage(4, (a) {
    master(const Offset(260, g + 12), 1.8, a);
    _semazenPuppet(c, const Offset(520, g + 12), time * 3, a);
  });
  // 5: "Bu gece ışık ölmez. Yalnızca kavuşur."
  stage(5, (a) {
    master(const Offset(450, g + 12), 1.9, a);
    _tasvirSaye(c, const Offset(300, g + 12), 2.1, time, a);
    lamp(const Offset(490, g - 150), 7, a);
  });
  // 6: Ney sesi; usta kandili Sâye'nin avuçlarına bırakır.
  stage(6, (a) {
    master(const Offset(460, g + 12), 1.9, a);
    _tasvirSaye(c, const Offset(300, g + 12), 2.1, time, a);
    final k = _span(u, 6.2, 6.8);
    lamp(
      Offset.lerp(const Offset(500, g - 150), const Offset(356, g - 60), k)!,
      7,
      a,
    );
  });
  // 7: "Sen benim gölgem değildin. Duamdın."
  stage(7, (a) {
    master(const Offset(460, g + 12), 1.9, a);
    _tasvirSaye(c, const Offset(300, g + 12), 2.1, time, a);
    lamp(const Offset(356, g - 60), 8, a);
  });
  // 10: Sâye'nin içinden bir ışık doğar.
  stage(10, (a) {
    _tasvirSaye(c, const Offset(390, g + 12), 2.4, time, a);
    final r = 40 + 80 * _span(u, 10.1, 10.9);
    c.drawCircle(const Offset(390, g - 100), r, _hole(0.55 * a));
  }, veil: 0.5);
  // 11: Işık göğe yükselir; Kandilciler gölgelerine bakıp ağlar.
  stage(11, (a) {
    final rise = _span(u, 11.05, 11.9);
    c.drawCircle(Offset(390, g - 120 - rise * 200), 40, _hole(0.8 * a));
    for (var i = 0; i < 4; i++) {
      _person(c, Offset(150 + i * 160.0, g + 12), 150, a, _kandilci, rot: 0.35);
      c.drawRect(Rect.fromLTWH(150 + i * 160.0, g + 10, 80, 6), _ink(a * 0.5));
    }
  });
  // 12: Hüdhüd: "Kırık güneşin yalnızca bir parçası buradaydı."
  stage(12, (a) {
    _tasvirHudhud(c, const Offset(420, 170), 3.4, time, a);
    _tasvirSaye(c, const Offset(240, g + 12), 2.0, time, a);
  });
  // 13: Önünde bir yol uzanır.
  stage(13, (a) {
    c.drawPath(
      Path()
        ..moveTo(330, g + 12)
        ..quadraticBezierTo(560, g - 40, 760, g - 120)
        ..lineTo(760, g - 110)
        ..quadraticBezierTo(560, g - 20, 450, g + 12)
        ..close(),
      _hole(0.6 * a),
    );
    _tasvirSaye(c, const Offset(300, g + 12), 2.2, time, a);
  }, veil: 0.5);
  // 14: "Yürü, Sâye."
  stage(14, (a) {
    final k = _span(u, 14.05, 14.95);
    _tasvirSaye(
      c,
      Offset(300 + k * 380, g + 12 - k * 80),
      2.2 - k * 1.2,
      time,
      a,
    );
    _tasvirHudhud(
      c,
      Offset(360 + k * 380, g - 190 - k * 60),
      1.6 - k * 0.8,
      time,
      a,
    );
  }, veil: 0.4);
}
