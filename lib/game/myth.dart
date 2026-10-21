import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

/// Türk mitolojisinin varlıkları (docs/MITOLOJI.md): oyunun siluet diliyle
/// çizilir. Her çizimde ayak (dip) noktası orijindedir, yüz sağa bakar; boyu
/// yaklaşık 100–200 birimdir, çağıran ölçekler. [t] saniye cinsinden zaman.
class MythPainter {
  MythPainter._();

  static const _ink = Color(0xFF120A06);

  static void _glow(Canvas c, Offset at, double r, Color color, double a) {
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = ui.Gradient.radial(at, r, [
          color.withValues(alpha: a),
          color.withValues(alpha: 0),
        ]),
    );
  }

  // ------------------------------------------------------------ Umay ağacı

  /// Umay ağacı: ak gövdeli kayın, dallarına bağlı ak ve al çaputlar.
  /// [lit] 0: dokunulmamış (çaputlar sarkık, soluk), 1: uyanmış (rüzgâr
  /// çaputları kaldırır, gövdeden ak ışık yükselir).
  static void umayTree(Canvas c, double t, {double lit = 1}) {
    if (lit > 0) {
      _glow(c, const Offset(0, -90), 120, const Color(0xFFFFF4DC), 0.35 * lit);
    }
    // Kökler.
    final root = Paint()..color = _ink;
    c.drawPath(
      Path()
        ..moveTo(-22, 0)
        ..quadraticBezierTo(-8, -6, -6, -18)
        ..lineTo(6, -18)
        ..quadraticBezierTo(8, -6, 24, 0)
        ..close(),
      root,
    );
    // Gövde: hafif kıvrık, ak kabuklu; kara kabuk izleri.
    final bark = Paint()
      ..color = Color.lerp(
        const Color(0xFF8A847A),
        const Color(0xFFEDE6D8),
        0.4 + 0.6 * lit,
      )!;
    final trunk = Path()
      ..moveTo(-6, -2)
      ..cubicTo(-9, -50, 2, -90, -3, -150)
      ..lineTo(4, -150)
      ..cubicTo(9, -92, -2, -50, 7, -2)
      ..close();
    c.drawPath(trunk, bark);
    final mark = Paint()
      ..color = _ink.withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final (y, w) in [
      (-20.0, 5.0),
      (-44.0, 4.0),
      (-70.0, 5.0),
      (-96.0, 3.0),
      (-120.0, 4.0),
    ]) {
      c.drawLine(Offset(-w / 2 - 2, y), Offset(w / 2 - 1, y - 1.5), mark);
    }
    // Dallar: yukarı ve yana kıvrılır.
    final branch = Paint()
      ..color = _ink
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tips = <Offset>[];
    void limb(Offset a, Offset ctl, Offset b) {
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(ctl.dx, ctl.dy, b.dx, b.dy),
        branch,
      );
      tips.add(b);
    }

    limb(
      const Offset(0, -110),
      const Offset(-30, -125),
      const Offset(-62, -118),
    );
    limb(const Offset(1, -120), const Offset(30, -140), const Offset(60, -132));
    limb(
      const Offset(-1, -135),
      const Offset(-22, -160),
      const Offset(-40, -168),
    );
    limb(const Offset(1, -140), const Offset(22, -168), const Offset(34, -182));
    limb(const Offset(0, -95), const Offset(28, -100), const Offset(50, -92));
    limb(const Offset(0, -150), const Offset(0, -172), const Offset(4, -194));
    // Yapraklar: dal uçlarında küçük kümeler.
    final leaf = Paint()
      ..color = Color.lerp(_ink, const Color(0xFF3A3A1C), 0.5 * lit)!;
    for (var i = 0; i < tips.length; i++) {
      final p = tips[i];
      for (var k = 0; k < 7; k++) {
        final a = k * 0.9 + i;
        final r = 6.0 + (k % 3) * 4;
        c.drawOval(
          Rect.fromCenter(
            center: p + Offset(math.cos(a) * r, math.sin(a) * r * 0.7),
            width: 7,
            height: 4.4,
          ),
          leaf,
        );
      }
    }
    // Çaputlar: dallardan sarkan bez şeritler; uyanınca rüzgârda kalkar.
    final ribbons = [
      (const Offset(-34, -122), const Color(0xFFF2ECE0)),
      (const Offset(-52, -119), const Color(0xFFB23A2E)),
      (const Offset(28, -134), const Color(0xFFB23A2E)),
      (const Offset(48, -133), const Color(0xFFF2ECE0)),
      (const Offset(-24, -160), const Color(0xFFF2ECE0)),
      (const Offset(22, -168), const Color(0xFFB23A2E)),
      (const Offset(36, -96), const Color(0xFFF2ECE0)),
    ];
    for (var i = 0; i < ribbons.length; i++) {
      final (at, color) = ribbons[i];
      final paint = Paint()..color = color.withValues(alpha: 0.55 + 0.4 * lit);
      // Sarkık hâlden rüzgâra kalkan hâle.
      final wave = math.sin(t * 3.1 + i * 1.7);
      final lift = lit * (0.6 + 0.4 * math.sin(t * 1.3 + i));
      final len = 26.0 + (i % 3) * 6;
      final end =
          at + Offset(lift * len * 0.9 + wave * 2, len * (1 - lift * 0.85));
      final mid = (at + end) / 2 + Offset(wave * 4 * (0.3 + lit), -lift * 4);
      final n =
          Offset(-(end - at).dy, (end - at).dx) / ((end - at).distance + 0.01);
      final w0 = 3.2;
      final w1 = 2.0;
      c.drawPath(
        Path()
          ..moveTo((at + n * w0).dx, (at + n * w0).dy)
          ..quadraticBezierTo(
            mid.dx + n.dx * 2.6,
            mid.dy + n.dy * 2.6,
            (end + n * w1).dx,
            (end + n * w1).dy,
          )
          ..lineTo((end - n * w1).dx, (end - n * w1).dy)
          ..quadraticBezierTo(
            mid.dx - n.dx * 2.6,
            mid.dy - n.dy * 2.6,
            (at - n * w0).dx,
            (at - n * w0).dy,
          )
          ..close(),
        paint,
      );
      // Düğüm.
      c.drawCircle(at, 2.4, Paint()..color = _ink);
    }
  }

  // -------------------------------------------------------------- Gökbörü

  /// Gökbörü: gök tüylü, gök yeleli kurt; ışıktan, kenarları titreyen bir
  /// siluet. [step] 0..1 yürüyüş evresi.
  static void gokboru(Canvas c, double t, {double step = 0}) {
    const sky = Color(0xFFBFD8EC);
    _glow(c, const Offset(10, -66), 140, const Color(0xFF9CC4E4), 0.42);
    final a = math.sin(step * 2 * math.pi);
    // Bacak: üstte kaslı, bilekte incelir, pençeyle biter.
    void leg(Offset hip, double swing, Paint p, {bool hind = false}) {
      final knee = hip + Offset(swing * 5 + (hind ? -7 : 1), 26);
      final paw = Offset(hip.dx + swing * 11 + (hind ? -2 : 2), 0);
      final path = Path()
        ..moveTo(hip.dx - 9, hip.dy)
        ..quadraticBezierTo(knee.dx - 8, knee.dy - 4, knee.dx - 4, knee.dy)
        ..lineTo(paw.dx - 4, paw.dy - 3)
        ..quadraticBezierTo(paw.dx - 2, paw.dy + 0.5, paw.dx + 8, paw.dy)
        ..lineTo(paw.dx + 3, paw.dy - 5)
        ..lineTo(knee.dx + 3, knee.dy)
        ..quadraticBezierTo(knee.dx + 8, knee.dy - 8, hip.dx + 9, hip.dy)
        ..close();
      c.drawPath(path, p);
    }

    final far = Paint()..color = sky.withValues(alpha: 0.45);
    leg(const Offset(44, -50), -a, far);
    leg(const Offset(-42, -52), a, far, hind: true);
    final fur = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -130),
        const Offset(0, -40),
        [const Color(0xFFEAF4FC), sky.withValues(alpha: 0.88)],
      );
    // Gür kuyruk: alçakta taşınır, ucu hafif kıvrık.
    final sway = math.sin(t * 1.8) * 3;
    c.drawPath(
      Path()
        ..moveTo(-58, -70)
        ..cubicTo(-86, -70, -102, -48, -104 + sway, -22)
        ..quadraticBezierTo(-100 + sway, -12, -90 + sway, -18)
        ..cubicTo(-86, -38, -74, -52, -54, -56)
        ..close(),
      fur,
    );
    // Gövde: yüksek omuz, derin göğüs, içe çekik karın; boyunda kabarık
    // yele, uzun burun, dik kulaklar.
    final body = Path()
      ..moveTo(-62, -70)
      ..cubicTo(-30, -78, 0, -80, 28, -86)
      ..cubicTo(40, -92, 50, -104, 60, -112)
      ..lineTo(63, -131)
      ..lineTo(71, -115)
      ..lineTo(75, -129)
      ..lineTo(81, -112)
      ..cubicTo(88, -108, 94, -104, 102, -101)
      ..cubicTo(108, -99, 114, -98, 119, -96)
      ..lineTo(119, -92)
      ..lineTo(106, -89)
      ..cubicTo(98, -88, 92, -86, 88, -86)
      // Boğazdaki yele: tırtıklı.
      ..lineTo(84, -80)
      ..lineTo(79, -84)
      ..lineTo(77, -74)
      ..lineTo(71, -79)
      ..lineTo(69, -67)
      ..cubicTo(68, -56, 62, -44, 52, -40)
      ..cubicTo(36, -40, 20, -46, 0, -44)
      ..cubicTo(-18, -44, -32, -48, -46, -48)
      ..cubicTo(-58, -50, -66, -58, -62, -70)
      ..close();
    c.drawPath(body, fur);
    final near = Paint()..color = sky.withValues(alpha: 0.92);
    leg(const Offset(52, -50), a, near);
    leg(const Offset(-36, -54), -a, near, hind: true);
    // Ensede kabarık yele tutamları.
    final mane = Paint()..color = const Color(0xFFF2F8FE);
    for (var i = 0; i < 6; i++) {
      final x = 30.0 + i * 5;
      final y = -88.0 - i * 4.4;
      c.drawPath(
        Path()
          ..moveTo(x, y)
          ..lineTo(x - 11, y - 7)
          ..lineTo(x + 3, y - 4)
          ..close(),
        mane,
      );
    }
    // Göz ve burun.
    c.drawOval(
      Rect.fromCenter(center: const Offset(94, -102), width: 7, height: 2.6),
      Paint()..color = const Color(0xFF1A3A5A),
    );
    _glow(c, const Offset(94, -102), 9, const Color(0xFFFFFFFF), 0.65);
    c.drawCircle(
      const Offset(118, -94),
      2.6,
      Paint()..color = const Color(0xFF2A4A6A),
    );
    // Işıktan olduğu belli olsun: titreşen ak kenar.
    c.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: 0.25 + 0.1 * math.sin(t * 7))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  /// Gökbörü'nün karanlıkta parlayan pençe izi.
  static void pawPrint(Canvas c, double alpha) {
    final p = Paint()..color = const Color(0xFFBFD8EC).withValues(alpha: alpha);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 6), p);
    for (final (x, y) in [
      (-5.0, -5.5),
      (-1.6, -7.4),
      (2.0, -7.4),
      (5.2, -5.4),
    ]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 2.8, height: 3.4),
        p,
      );
    }
  }

  // --------------------------------------------------------------- Ak Ana

  /// Ak Ana: ilk suyun içinden yükselen ak ana; saçları ve eteği suya
  /// karışır, kolları açılır.
  static void akAna(Canvas c, double t) {
    _glow(c, const Offset(0, -110), 150, const Color(0xFFF4F8FF), 0.45);
    final white = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -200), const Offset(0, 0), [
        const Color(0xFFFFFFFF),
        const Color(0xFFCADBEA).withValues(alpha: 0.6),
      ]);
    final s = math.sin(t * 1.2);
    // Etek suya karışır: dalgalı geniş bir çan.
    final robe = Path()
      ..moveTo(-12, -120)
      ..cubicTo(-22, -80, -40, -40, -64, -8)
      ..quadraticBezierTo(-48, -2 + s * 2, -32, -6)
      ..quadraticBezierTo(-16, 0 - s * 2, 0, -5)
      ..quadraticBezierTo(16, 0 + s * 2, 32, -6)
      ..quadraticBezierTo(48, -2 - s * 2, 64, -8)
      ..cubicTo(40, -40, 22, -80, 12, -120)
      ..close();
    c.drawPath(robe, white);
    // Gövde, boyun, baş.
    c.drawPath(
      Path()
        ..moveTo(-12, -122)
        ..quadraticBezierTo(-14, -140, -8, -150)
        ..lineTo(8, -150)
        ..quadraticBezierTo(14, -140, 12, -122)
        ..close(),
      white,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -164), width: 20, height: 24),
      white,
    );
    // Uzun saç: arkasından suya dek akar.
    final hair = Paint()
      ..color = const Color(0xFFE8F0F8).withValues(alpha: 0.85);
    c.drawPath(
      Path()
        ..moveTo(-6, -176)
        ..cubicTo(-30, -170, -36 + s * 4, -110, -58 + s * 6, -60)
        ..cubicTo(-50, -58, -40, -90, -20, -130)
        ..quadraticBezierTo(-12, -150, -8, -160)
        ..close(),
      hair,
    );
    // Açılan kollar: avuçlar yukarı.
    final arm = Paint()
      ..color = const Color(0xFFF6FAFF)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final open = 0.8 + 0.2 * s;
    for (final side in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(side * 9, -142)
          ..quadraticBezierTo(side * 34, -150, side * 48 * open, -176),
        arm,
      );
    }
    // Su: dalga çizgileri ve halkalar.
    final water = Paint()
      ..color = const Color(0xFFBFD4E8).withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      final r = 70.0 + k * 26 + (t * 14 % 26);
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -2),
          width: r * 2,
          height: r * 0.25,
        ),
        water,
      );
    }
  }

  // --------------------------------------------------------------- Tulpar

  /// Tulpar: kanatlı at, dörtnala; kanatları yukarı açık.
  static void tulpar(Canvas c, double t) {
    final ink = Paint()..color = _ink;
    final g = t * 6;
    final flap = math.sin(g) * 14;
    // Arkadaki kanat.
    final wingBack = Path()
      ..moveTo(0, -96)
      ..cubicTo(-20, -150 - flap, -60, -170 - flap, -96, -166 - flap)
      ..lineTo(-80, -150 - flap * 0.8)
      ..lineTo(-92, -146 - flap * 0.8)
      ..lineTo(-74, -132 - flap * 0.6)
      ..lineTo(-84, -126 - flap * 0.6)
      ..lineTo(-60, -116 - flap * 0.4)
      ..lineTo(-16, -96)
      ..close();
    c.drawPath(wingBack, Paint()..color = const Color(0xFF2A1A14));
    // Gövde, boyun, baş.
    final horse = Path()
      ..moveTo(-60, -84)
      ..cubicTo(-40, -98, 10, -100, 34, -96)
      ..cubicTo(46, -110, 54, -130, 62, -142)
      ..lineTo(66, -150)
      ..lineTo(70, -142)
      ..cubicTo(78, -138, 90, -128, 98, -118)
      ..lineTo(96, -112)
      ..cubicTo(86, -114, 76, -118, 70, -116)
      ..cubicTo(64, -104, 56, -92, 48, -76)
      ..cubicTo(36, -62, 0, -62, -30, -64)
      ..cubicTo(-46, -64, -58, -70, -60, -84)
      ..close();
    c.drawPath(horse, ink);
    // Yele ve kuyruk rüzgârda.
    c.drawPath(
      Path()
        ..moveTo(40, -102)
        ..cubicTo(36, -118, 46, -138, 60, -146)
        ..lineTo(50, -130)
        ..lineTo(44, -132)
        ..lineTo(42, -118)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(-58, -82)
        ..cubicTo(-80, -86, -96, -72, -110, -58 + math.sin(g) * 4)
        ..cubicTo(-96, -64, -82, -70, -60, -74)
        ..close(),
      ink,
    );
    // Dörtnala bacaklar: kaslı üst bacak, ince incik, toynak.
    void stride(Offset hip, double ph, {bool hind = false}) {
      final s = math.sin(g + ph);
      final knee = hip + Offset(10 * s + (hind ? -4 : 2), 24);
      final hoof = knee + Offset(14 * s - 4, 24 - 6 * s.abs());
      final d = hoof - knee;
      final n = Offset(-d.dy, d.dx) / (d.distance + 0.01);
      c.drawPath(
        Path()
          ..moveTo(hip.dx - 8, hip.dy)
          ..quadraticBezierTo(knee.dx - 7, knee.dy - 6, knee.dx - 3.5, knee.dy)
          ..lineTo((hoof + n * 2.4).dx, (hoof + n * 2.4).dy)
          ..lineTo((hoof - n * 2.4).dx, (hoof - n * 2.4).dy)
          ..lineTo(knee.dx + 3.5, knee.dy)
          ..quadraticBezierTo(knee.dx + 7, knee.dy - 8, hip.dx + 8, hip.dy)
          ..close(),
        ink,
      );
      // Toynak.
      c.save();
      c.translate(hoof.dx, hoof.dy);
      c.rotate(math.atan2(d.dy, d.dx) - math.pi / 2);
      c.drawPath(
        Path()
          ..moveTo(-3, 0)
          ..lineTo(3, 0)
          ..lineTo(4.5, 6)
          ..lineTo(-4.5, 6)
          ..close(),
        ink,
      );
      c.restore();
    }

    stride(const Offset(30, -70), 0);
    stride(const Offset(40, -72), 0.6);
    stride(const Offset(-42, -70), math.pi, hind: true);
    stride(const Offset(-32, -68), math.pi + 0.6, hind: true);
    // Öndeki kanat: tüy tüy.
    final wing = Path()
      ..moveTo(4, -94)
      ..cubicTo(-10, -150 - flap, 30, -186 - flap, 64, -196 - flap)
      ..lineTo(50, -176 - flap * 0.8)
      ..lineTo(64, -170 - flap * 0.8)
      ..lineTo(44, -154 - flap * 0.6)
      ..lineTo(56, -146 - flap * 0.6)
      ..lineTo(32, -128 - flap * 0.4)
      ..lineTo(36, -116 - flap * 0.3)
      ..lineTo(14, -100)
      ..close();
    c.drawPath(wing, ink);
    c.drawCircle(
      const Offset(86, -128),
      1.8,
      Paint()..color = const Color(0xFFE8C890),
    );
  }

  // ----------------------------------------------------------- Umay kuşu

  /// Umay kuşu (Hüma): uzun kuyruklu, geniş kanatlı kut kuşu; gölgesi
  /// koruyucudur.
  static void umayBird(Canvas c, double t) {
    final gold = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-80, -60),
        const Offset(80, -60),
        [const Color(0xFFE8C46A), const Color(0xFFF6E2A8)],
      );
    _glow(c, const Offset(0, -70), 110, const Color(0xFFF6D88A), 0.35);
    final flap = math.sin(t * 2.2) * 10;
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(0, -72)
          ..cubicTo(
            s * 30,
            -110 - flap,
            s * 80,
            -116 - flap,
            s * 110,
            -96 - flap,
          )
          ..lineTo(s * 92, -88 - flap * 0.8)
          ..lineTo(s * 102, -80 - flap * 0.7)
          ..lineTo(s * 80, -76 - flap * 0.5)
          ..lineTo(s * 86, -66 - flap * 0.4)
          ..lineTo(s * 50, -66)
          ..lineTo(s * 8, -62)
          ..close(),
        gold,
      );
    }
    // Gövde, baş, tepelik.
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -66), width: 22, height: 34),
      gold,
    );
    c.drawCircle(const Offset(0, -88), 8, gold);
    for (final x in [-4.0, 0.0, 4.0]) {
      c.drawLine(
        Offset(x * 0.6, -95),
        Offset(x * 1.6, -108),
        Paint()
          ..color = const Color(0xFFF6E2A8)
          ..strokeWidth = 1.6,
      );
    }
    // Uzun kuyruk tüyleri.
    for (var i = -2; i <= 2; i++) {
      final sway = math.sin(t * 1.5 + i) * 4;
      c.drawPath(
        Path()
          ..moveTo(i * 2.0, -50)
          ..quadraticBezierTo(i * 8.0 + sway, -20, i * 14.0 + sway * 1.6, 8)
          ..lineTo(i * 14.0 + 3 + sway * 1.6, 6)
          ..quadraticBezierTo(i * 8.0 + 2 + sway, -22, i * 2.0 + 3, -50)
          ..close(),
        gold,
      );
    }
  }

  // ------------------------------------------------------------------ Kam

  /// Kam (şaman): saçaklı kaftan, tüylü başlık, elinde büyük davul.
  static void kam(Canvas c, double t) {
    final ink = Paint()..color = _ink;
    final beat = math.max(0.0, math.sin(t * 6));
    // Kaftan: saçaklı etek.
    final coat = Path()
      ..moveTo(-14, -120)
      ..cubicTo(-30, -90, -34, -40, -40, -6)
      ..lineTo(40, -6)
      ..cubicTo(34, -40, 30, -90, 14, -120)
      ..close();
    c.drawPath(coat, ink);
    // Saçaklar: eteğin altından sarkan şeritler.
    final fringe = Paint()
      ..color = _ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = -38.0; x <= 38; x += 5) {
      final sw = math.sin(t * 4 + x) * 2;
      c.drawLine(Offset(x, -8), Offset(x + sw, 4), fringe);
    }
    // Göğüsteki çıngıraklar (ışık delikleri).
    final bell = Paint()..color = const Color(0xFFE8C890);
    for (final (x, y) in [
      (-8.0, -96.0),
      (0.0, -92.0),
      (8.0, -96.0),
      (-4.0, -80.0),
      (4.0, -80.0),
    ]) {
      c.drawCircle(Offset(x, y), 1.8, bell);
    }
    // Baş ve tüylü başlık.
    c.drawCircle(const Offset(0, -130), 11, ink);
    for (var i = -3; i <= 3; i++) {
      final a = -math.pi / 2 + i * 0.28;
      c.drawPath(
        Path()
          ..moveTo(i * 3.0, -138)
          ..lineTo(math.cos(a) * 30, -130 + math.sin(a) * 30)
          ..lineTo(math.cos(a + 0.08) * 28 + 2, -130 + math.sin(a + 0.08) * 28)
          ..close(),
        ink,
      );
    }
    // Yüzü örten saçaklar.
    for (var x = -8.0; x <= 8; x += 4) {
      c.drawLine(Offset(x, -126), Offset(x, -112), fringe);
    }
    // Davul: büyük yuvarlak çerçeve, içinde ışık; tokmak vurur.
    final drum = Offset(34, -84 - beat * 2);
    _glow(c, drum, 40 + beat * 12, const Color(0xFFFFE0A0), 0.25 + 0.3 * beat);
    c.drawOval(Rect.fromCenter(center: drum, width: 50, height: 58), ink);
    c.drawOval(
      Rect.fromCenter(center: drum, width: 40, height: 48),
      Paint()
        ..color = const Color(0xFFE8B070).withValues(alpha: 0.35 + 0.4 * beat),
    );
    // Davul yüzündeki çizim: dünya ağacı ve katlar.
    final rune = Paint()
      ..color = _ink
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    c.drawLine(drum.translate(0, 20), drum.translate(0, -20), rune);
    c.drawLine(drum.translate(-16, -2), drum.translate(16, -2), rune);
    c.drawCircle(drum.translate(-8, -12), 3, rune);
    c.drawCircle(drum.translate(8, -12), 3, rune);
    // Tokmak tutan kol.
    final stick = Paint()
      ..color = _ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(
      const Offset(-10, -104),
      Offset(-2 + beat * 10, -70 - beat * 6),
      stick,
    );
    c.drawLine(
      Offset(-2 + beat * 10, -70 - beat * 6),
      Offset(12 + beat * 12, -88),
      stick..strokeWidth = 2.6,
    );
  }

  // ------------------------------------------------------------- Ayaz Ata

  /// Ayaz Ata: ak sakallı, kürk başlıklı, asalı soğuğun ruhu; nefesi buz.
  static void ayazAta(Canvas c, double t) {
    final frost = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -180), const Offset(0, 0), [
        const Color(0xFFDDEAF6),
        const Color(0xFF7A90A8),
      ]);
    _glow(c, const Offset(0, -100), 120, const Color(0xFFC8DCF0), 0.3);
    // Uzun kürk kaftan.
    c.drawPath(
      Path()
        ..moveTo(-20, -130)
        ..cubicTo(-34, -90, -42, -40, -50, 0)
        ..lineTo(46, 0)
        ..cubicTo(38, -40, 32, -90, 18, -130)
        ..close(),
      frost,
    );
    // Kürk başlık ve yüz.
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -150), width: 30, height: 30),
      frost,
    );
    c.drawPath(
      Path()
        ..moveTo(-18, -156)
        ..quadraticBezierTo(0, -182, 18, -156)
        ..close(),
      Paint()..color = const Color(0xFFF2F8FF),
    );
    // Uzun ak sakal göğsüne iner.
    c.drawPath(
      Path()
        ..moveTo(-10, -142)
        ..quadraticBezierTo(0, -136, 10, -142)
        ..quadraticBezierTo(14, -110, 2, -82)
        ..quadraticBezierTo(-12, -108, -10, -142)
        ..close(),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    // Asa: ucunda buz kristali.
    final staff = Paint()
      ..color = const Color(0xFF5A6A80)
      ..strokeWidth = 3;
    c.drawLine(const Offset(36, 0), const Offset(30, -186), staff);
    _glow(c, const Offset(30, -190), 16, const Color(0xFFFFFFFF), 0.7);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + t * 0.4;
      c.drawLine(
        const Offset(30, -190),
        Offset(30 + math.cos(a) * 9, -190 + math.sin(a) * 9),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 1.4,
      );
    }
    // Buz nefesi.
    for (var i = 0; i < 4; i++) {
      final k = (t * 0.6 + i / 4) % 1.0;
      c.drawCircle(
        Offset(14 + k * 40, -148 - k * 6),
        2 + k * 6,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4 * (1 - k)),
      );
    }
  }

  // -------------------------------------------------------------- Albastı

  /// Albastı (Al Karısı): uzun saçları yüzünü örten, kızıl, eğik bir gölge;
  /// yalnızca su kıyısında, yansımada sezilir.
  static void albasti(Canvas c, double t) {
    final red = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -190), const Offset(0, 0), [
        const Color(0xFF8A1E18),
        const Color(0xFF3A0A08).withValues(alpha: 0.2),
      ]);
    _glow(c, const Offset(0, -110), 100, const Color(0xFFB0281E), 0.25);
    final sway = math.sin(t * 0.9) * 4;
    // Uzun, ince, eğik beden; dibi sise karışır.
    c.drawPath(
      Path()
        ..moveTo(-8, -150)
        ..cubicTo(-18, -110, -30, -50, -36 + sway, 0)
        ..lineTo(30 + sway, 0)
        ..cubicTo(22, -60, 14, -110, 10, -150)
        ..close(),
      red,
    );
    // Öne eğik baş, yüzü örten uzun saç.
    c.drawOval(
      Rect.fromCenter(center: const Offset(8, -160), width: 20, height: 24),
      red,
    );
    final hair = Paint()
      ..color = const Color(0xFF2A0606).withValues(alpha: 0.9);
    c.drawPath(
      Path()
        ..moveTo(-6, -170)
        ..cubicTo(6, -182, 24, -176, 24, -160)
        ..cubicTo(26, -130, 22 + sway, -100, 20 + sway, -70)
        ..cubicTo(14, -100, 4, -130, -6, -170)
        ..close(),
      hair,
    );
    // Uzun parmaklı el.
    final finger = Paint()
      ..color = const Color(0xFF8A1E18)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset(16 + i * 2.0, -104),
        Offset(30 + i * 3.0, -92 + i * 2),
        finger,
      );
    }
  }
}
