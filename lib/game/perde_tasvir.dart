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
  // Kanat: kara-ak çizgili.
  final flap = math.sin(time * 9) * 0.35;
  c.save();
  c.rotate(-0.4 + flap);
  final wing = Path()
    ..moveTo(-4, -2)
    ..quadraticBezierTo(-30, -26, -52, -12)
    ..quadraticBezierTo(-30, 2, -4, 4)
    ..close();
  _fillRim(c, wing, const Color(0xFF2A2420), a);
  for (var i = 0; i < 4; i++) {
    final x = -14.0 - i * 9;
    c.drawLine(
      Offset(x, -12 + i * 2.0),
      Offset(x - 4, 0),
      _hole(0.8 * a)..strokeWidth = 2.4,
    );
  }
  c.restore();
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
  _tasvirHudhud(canvas, Offset(215 + go * 140, g - 218), 1.7, time, a);
}

/// Ana iplikte yalnız Sâye ve Hüdhüd (Kandilci yok): yola bakar, yürür.
void _sayeBeat(Canvas canvas, double time, double u, double k) {
  final a = _enter(u, k) * (1 - _leave(u, k));
  if (a <= 0) return;
  _veil(canvas, a);
  const g = PerdePainter._ground;
  final go = _span(u, k + 0.3, k + 0.95);
  _tasvirSaye(canvas, Offset(260 + go * 140, g + 12), 2.4, time, a);
  _tasvirHudhud(canvas, Offset(320 + go * 150, g - 220), 1.7, time, a);
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
void _dervish(Canvas c, Offset feet, double h, double a, {bool flip = false}) {
  _cut(c, MythFigures.manSilhouette, feet, h, a, flip: flip);
  final s = h / 100;
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(feet.dx + (flip ? -1 : 1) * 1 * s, feet.dy - 104 * s),
        width: 12 * s,
        height: 22 * s,
      ),
      Radius.circular(5 * s),
    ),
    _ink(a),
  );
}

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
    case PerdeScene.galata:
      // Hezarfen: kanatlarıyla kulede; sonra Boğaz'ın üstünden süzülür.
      stage(1, (a) {
        _wings(c, const Offset(372, g - 175), 150, 0.1, a);
        _cut(c, MythFigures.manSilhouette, const Offset(370, g + 12), 230, a);
      });
      stage(3, (a) {
        final k = _span(u, 3.1, 3.95);
        final at = Offset(640 - k * 470, 150 + k * 60);
        _wings(c, at, 170, 0.55 + math.sin(time * 1.5) * 0.05, a);
        _cut(
          c,
          MythFigures.manSilhouette,
          at + const Offset(0, 60),
          120,
          a,
          rot: -1.45,
          deco: false,
        );
      });
      _sayeBeat(canvas, time, u, 5);
    case PerdeScene.skyroad:
      // Lagari Hasan Çelebi yedi kollu fişekle göğe.
      stage(1, (a) {
        final k = _span(u, 1.1, 1.95);
        c.save();
        c.translate(240 + k * 320, g - 40 - k * 220);
        c.rotate(-0.5);
        final fire = _hole(0.85 * a);
        for (var i = 0; i < 7; i++) {
          final x = -36 + i * 12.0;
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, -10, 9, 120),
              const Radius.circular(4),
            ),
            _ink(a),
          );
          final f = 20 + 10 * math.sin(time * 18 + i);
          c.drawPath(
            Path()
              ..moveTo(x, 110)
              ..lineTo(x + 4.5, 110 + f)
              ..lineTo(x + 9, 110)
              ..close(),
            fire,
          );
        }
        c.restore();
        _cut(
          c,
          MythFigures.manSilhouette,
          Offset(232 + k * 320, g - 90 - k * 220),
          120,
          a,
          rot: -0.5,
          deco: false,
        );
      });
      _chaseBeat(canvas, time, u, 4);
      // Tulpar: kanatlı at, bulutların ardında dörtnala.
      stage(5, (a) {
        final k = _span(u, 5.05, 5.95);
        final x = 640 - k * 420;
        final y = g + 10 - 40 - math.sin(time * 3) * 8;
        _cut(
          c,
          MythShapes.horse,
          Offset(x, y),
          200,
          a,
          flip: true,
          eye: const Offset(48, -82),
        );
        _wings(
          c,
          Offset(x + 6, y - 150),
          120,
          0.4 + math.sin(time * 3) * 0.25,
          a,
        );
      });
    case PerdeScene.kaf:
      // Hüdhüd kuşlara yol gösterir.
      stage(2, (a) {
        _tasvirHudhud(canvas, const Offset(470, 170), 3.4, time, a);
        for (var i = 0; i < 9; i++) {
          final bx = 130 + (i % 5) * 52.0 + (i ~/ 5) * 26;
          final by = 210 + (i ~/ 5) * 48.0 + math.sin(time * 3 + i) * 6;
          _cut(c, MythShapes.birdFlap, Offset(bx, by), 40, a, deco: false);
        }
      });
      // Simurg: tepedeki dev kuş.
      stage(4, (a) {
        final k = math.sin(time * 1.2) * 0.04;
        c.save();
        c.translate(390, 210);
        c.scale(3.6, 3.6 * (1 + k));
        c.drawPath(MythShapes.birdGlide, _ink(a));
        c.restore();
        // Uzun kuyruk tüyleri.
        for (var i = 0; i < 4; i++) {
          final y0 = 210 - 30 + i * 12.0;
          c.drawPath(
            Path()
              ..moveTo(330, y0)
              ..quadraticBezierTo(
                220,
                y0 + 40 + i * 10 + math.sin(time + i) * 8,
                110,
                y0 + 10 + i * 18,
              )
              ..quadraticBezierTo(220, y0 + 30 + i * 10, 330, y0 + 8)
              ..close(),
            _ink(a),
          );
          c.drawCircle(Offset(118, y0 + 12 + i * 18), 5, _hole(0.8 * a));
        }
        _rosette(c, const Offset(400, 196), 8, a);
      });
    case PerdeScene.mirror:
      // Aynada bir çocuk değil, bir gölge.
      stage(1, (a) {
        _tasvirSaye(canvas, const Offset(250, g + 12), 2.4, time, a);
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(520, 200),
            width: 190,
            height: 260,
          ),
          _ink(a),
        );
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(520, 200),
            width: 160,
            height: 230,
          ),
          _hole(0.9 * a),
        );
        _rosette(c, const Offset(520, 64), 10, a);
        _tasvirSaye(canvas, const Offset(520, 318), 1.7, time, a);
      });
      _chaseBeat(canvas, time, u, 2);
      // Aziz Hakob: meleğin getirdiği tahta.
      stage(4, (a) {
        _cut(
          c,
          MythFigures.ayazAtaSilhouette,
          const Offset(300, g + 12),
          220,
          a,
          flip: true,
        );
        final k = _span(u, 4.1, 4.7);
        final angel = Offset(520, 60 + k * 90);
        _wings(c, angel, 110, 0.2 + math.sin(time * 2) * 0.1, a);
        _cut(
          c,
          MythFigures.manSilhouette,
          angel + const Offset(0, 110),
          110,
          a,
          flip: true,
          deco: false,
        );
        c.drawRect(
          Rect.fromLTWH(angel.dx - 70, angel.dy + 40, 60, 12),
          _ink(a),
        );
      });
      stage(5, (a) {
        _cut(
          c,
          MythFigures.ayazAtaSilhouette,
          const Offset(400, g + 12),
          270,
          a,
          flip: true,
        );
        final p = _hole(0.6 * a);
        for (var i = 0; i < 40; i++) {
          final x = (i * 97.0 + time * 40) % 780;
          final y = (i * 53.0 + time * 70) % 360;
          c.drawCircle(Offset(x, y), 2, p);
        }
      });
    case PerdeScene.flood:
      // Nuh ve zeytin dallı güvercin.
      stage(2, (a) {
        _cut(
          c,
          MythFigures.ayazAtaSilhouette,
          const Offset(300, g + 12),
          240,
          a,
        );
        final k = _span(u, 2.1, 2.8);
        final dove = Offset(700 - k * 330, 90 + k * 70);
        _cut(c, MythShapes.birdFlap, dove, 70, a, flip: true, deco: false);
        // Zeytin dalı.
        c.drawLine(
          dove + const Offset(-26, -40),
          dove + const Offset(-52, -30),
          _ink(a)..strokeWidth = 2.5,
        );
        for (var i = 0; i < 3; i++) {
          c.drawOval(
            Rect.fromCenter(
              center: dove + Offset(-34 - i * 7.0, -38 + i * 3.0),
              width: 9,
              height: 4,
            ),
            _ink(a),
          );
        }
      });
      _chaseBeat(canvas, time, u, 3);
      // Ak Ana sudan yükselir.
      stage(5, (a) {
        final rise = _span(u, 5.05, 5.6);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        _cut(
          c,
          MythFigures.akAnaSilhouette,
          Offset(390, g + 160 - 160 * rise),
          280,
          a,
        );
        c.restore();
        c.drawCircle(
          Offset(390, g + 160 - 160 * rise - 250),
          30,
          _hole(0.45 * a * rise),
        );
      });
    case PerdeScene.gods:
      // Antiochos ve Herakles el sıkışır (Nemrut'un dexiosis kabartması).
      stage(1, (a) {
        _cut(c, MythFigures.manSilhouette, const Offset(320, g + 12), 240, a);
        // Sivri, beş dişli Ermeni taçı.
        c.drawPath(
          Path()
            ..moveTo(304, g - 220)
            ..lineTo(308, g - 262)
            ..lineTo(316, g - 236)
            ..lineTo(322, g - 270)
            ..lineTo(328, g - 236)
            ..lineTo(336, g - 262)
            ..lineTo(340, g - 220)
            ..close(),
          _ink(a),
        );
        _cut(
          c,
          MythFigures.manSilhouette,
          const Offset(470, g + 12),
          250,
          a,
          flip: true,
        );
        // Herakles'in topuzu.
        c.drawLine(
          const Offset(500, g - 120),
          const Offset(540, g - 40),
          _ink(a)..strokeWidth = 10,
        );
      });
      _chaseBeat(canvas, time, u, 4);
    case PerdeScene.dawn:
      // Nemrud'un kartallı sandığı göğe yükselir.
      stage(1, (a) {
        final k = _span(u, 1.05, 1.95);
        final box = Offset(390, 260 - k * 120);
        for (var i = 0; i < 4; i++) {
          final ex = box.dx + (i < 2 ? -110.0 : 110.0) + (i.isEven ? -20 : 20);
          _cut(
            c,
            MythShapes.birdFlap,
            Offset(ex, box.dy - 40 - (i.isEven ? 0 : 20)),
            70 + math.sin(time * 8 + i) * 4,
            a,
            flip: i < 2,
            deco: false,
          );
        }
        c.drawRect(
          Rect.fromCenter(center: box, width: 130, height: 70),
          _ink(a),
        );
        _punchRow(
          c,
          box + const Offset(-55, 0),
          box + const Offset(55, 0),
          9,
          2.4,
          a,
        );
        _cut(
          c,
          MythFigures.manSilhouette,
          box + const Offset(0, -34),
          110,
          a,
          deco: false,
        );
        // Göğe atılan ok.
        c.drawLine(
          box + const Offset(20, -120),
          box + const Offset(60, -220),
          _ink(a)..strokeWidth = 3,
        );
      });
      // Sivrisinek: kral başını tutar.
      stage(3, (a) {
        _cut(c, MythFigures.manSilhouette, const Offset(390, g + 12), 270, a);
        final k = _span(u, 3.1, 3.8);
        c.drawCircle(Offset(640 - k * 230, 120 + k * 20), 3.5, _ink(a));
        c.drawCircle(Offset(640 - k * 230, 118 + k * 20), 1.6, _hole(a));
      });
      _chaseBeat(canvas, time, u, 4);
      // Tepegöz ve Basat.
      stage(5, (a) {
        _cut(
          c,
          MythFigures.manSilhouette,
          const Offset(540, g + 12),
          320,
          a,
          flip: true,
          eye: const Offset(2, -94),
        );
        final step = _span(u, 5.1, 5.7);
        final bx = 180 + step * 140;
        _cut(c, MythFigures.manSilhouette, Offset(bx, g + 12), 150, a);
        c.drawLine(
          Offset(bx + 30, g - 80),
          Offset(bx + 90, g - 140),
          _hole(a)..strokeWidth = 5,
        );
      });
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
        _cut(c, MythFigures.akAnaSilhouette, const Offset(390, g + 12), 250, a);
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
        _cut(
          c,
          MythFigures.manSilhouette,
          const Offset(520, g + 80),
          330,
          a,
          flip: true,
          eye: const Offset(2, -94),
        );
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
        _cut(c, MythFigures.akAnaSilhouette, const Offset(230, g + 12), 220, a);
        c.drawPath(
          Path()
            ..moveTo(212, g - 212)
            ..lineTo(218, g - 240)
            ..lineTo(226, g - 222)
            ..lineTo(232, g - 246)
            ..lineTo(238, g - 222)
            ..lineTo(246, g - 240)
            ..lineTo(250, g - 212)
            ..close(),
          _ink(a),
        );
      });
      // Erlik: yerin dibinden boynuzlu bir gölge.
      stage(4, (a) {
        final rise = _span(u, 4.05, 4.6);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        final f = Offset(390, g + 220 - 210 * rise);
        _cut(
          c,
          MythFigures.manSilhouette,
          f,
          300,
          a,
          eye: const Offset(2, -94),
        );
        for (final sx in [-1.0, 1.0]) {
          c.drawPath(
            Path()
              ..moveTo(f.dx + sx * 14, f.dy - 290)
              ..quadraticBezierTo(
                f.dx + sx * 50,
                f.dy - 330,
                f.dx + sx * 30,
                f.dy - 360,
              )
              ..quadraticBezierTo(
                f.dx + sx * 40,
                f.dy - 320,
                f.dx + sx * 4,
                f.dy - 292,
              )
              ..close(),
            _ink(a),
          );
        }
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
        _cut(c, MythFigures.manSilhouette, const Offset(390, g - 20), 230, a);
      });
      // Ak Ana sudan yükselir: "Yarat."
      stage(2, (a) {
        final rise = _span(u, 2.05, 2.6);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        _cut(
          c,
          MythFigures.akAnaSilhouette,
          Offset(390, g + 170 - 170 * rise),
          290,
          a,
        );
        c.restore();
      });
      // Erlik yerin altına sürülür.
      stage(3, (a) {
        final fall = _span(u, 3.2, 3.9);
        c.save();
        c.clipRect(const Rect.fromLTWH(0, 0, 780, g + 12));
        _cut(
          c,
          MythFigures.manSilhouette,
          Offset(470, g + 12 + fall * 260),
          240,
          a,
          flip: true,
          eye: const Offset(2, -94),
        );
        c.restore();
        _cut(c, MythFigures.manSilhouette, const Offset(250, g + 12), 250, a);
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
        _cut(
          c,
          MythFigures.manSilhouette,
          Offset(x - 8, g - 120),
          130,
          a,
          deco: false,
        );
      });
      // Körmösler: Erlik'in gölgeleri, ışık delikli gözler.
      stage(6, (a) {
        for (var i = 0; i < 3; i++) {
          _cut(
            c,
            MythFigures.manSilhouette,
            Offset(220 + i * 170.0, g + 12 + math.sin(time * 2 + i) * 4),
            200 + i * 20.0,
            a,
            flip: i.isOdd,
            eye: const Offset(2, -94),
            deco: false,
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
    case PerdeScene.prologue || PerdeScene.ergenekon || PerdeScene.epilogue:
      // Önsöz ve son kendi tasvirleriyle; Ergenekon sahnenin içinde.
      break;
  }
}
