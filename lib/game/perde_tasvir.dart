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
