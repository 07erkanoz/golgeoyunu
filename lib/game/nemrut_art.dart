part of 'nemrut.dart';

// ====================================================== Nemrut heykelleri

/// Nemrut'un dev başları (Doğu ve Batı Terası, MÖ 1. yy). Hepsi önden,
/// dimdik durur; yüzün üstünde uzun bir başlık, alında desenli şerit,
/// şakaklardan yanaklara inen başlık kanatları.
enum NemrutHead {
  /// Kral Antiochos: uzun, ucu yuvarlak Armen tiarası; pürüzsüz yüz.
  antiochos,

  /// Zeus-Oromasdes: tiara, kıvırcık sakal ve bıyık.
  zeus,

  /// Apollon-Mithras: ucu öne kıvrılan Frig başlığı; pürüzsüz yüz.
  apollo,

  /// Herakles-Artagnes: alçak başlık, gür sakal.
  herakles,

  /// Kommagene (Tyche): meyve ve başaklardan taç.
  tyche,
}

/// Taş renkleri: gece, karlı dağ.
const _nStoneLit = Color(0xFF524A5E);
const _nStoneDark = Color(0xFF1E1925);
const _nCut = Color(0xFF110D15);
const _nRim = Color(0xFFB8B0D0);
const _nSnow = Color(0xFFB8C2D4);

abstract final class NemrutArt {
  /// Dev baş: çene orijinde, başlığın tepesi -[height]'te.
  /// [flat] verilirse ayrıntısız, tek renk siluet çizilir (uzaktaki
  /// arka plan heykelleri).
  static void head(Canvas c, NemrutHead kind, double height, {Color? flat}) {
    c.save();
    c.scale(height / 100);
    final stone = Paint()
      ..shader = Gradient.linear(const Offset(-26, 0), const Offset(26, 0), [
        _nStoneLit,
        _nStoneDark,
      ]);
    final cut = Paint()
      ..color = _nCut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final rim = Paint()
      ..color = _nRim.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final bearded = kind == NemrutHead.zeus || kind == NemrutHead.herakles;

    // Başlık.
    final hat = switch (kind) {
      NemrutHead.antiochos || NemrutHead.zeus =>
        Path()
          ..moveTo(-23, -50)
          ..cubicTo(-25, -70, -15, -92, -2, -100)
          ..quadraticBezierTo(4, -102, 6, -97)
          ..cubicTo(14, -86, 24, -68, 23, -50)
          ..close(),
      NemrutHead.apollo =>
        Path()
          ..moveTo(-23, -50)
          ..cubicTo(-26, -72, -10, -94, 10, -96)
          ..quadraticBezierTo(18, -95, 16, -88)
          ..quadraticBezierTo(8, -86, 10, -80)
          ..cubicTo(20, -72, 24, -62, 23, -50)
          ..close(),
      NemrutHead.herakles =>
        Path()
          ..moveTo(-23, -50)
          ..cubicTo(-25, -66, -12, -80, 0, -81)
          ..cubicTo(12, -80, 25, -66, 23, -50)
          ..close(),
      NemrutHead.tyche => () {
        final p = Path()
          ..moveTo(-22, -50)
          ..lineTo(-24, -74)
          ..lineTo(24, -74)
          ..lineTo(22, -50)
          ..close();
        for (var i = 0; i < 5; i++) {
          p.addOval(
            Rect.fromCircle(
              center: Offset(-18 + i * 9.0, -77 - (i.isEven ? 0 : 2)),
              radius: 6,
            ),
          );
        }
        return p;
      }(),
    };
    // Başlık kanatları: şakaktan yanağa iner.
    final flaps = Path()
      ..moveTo(-21, -52)
      ..lineTo(-28, -50)
      ..lineTo(-27, -14)
      ..lineTo(-19, -11)
      ..close()
      ..moveTo(21, -52)
      ..lineTo(28, -50)
      ..lineTo(27, -14)
      ..lineTo(19, -11)
      ..close();
    // Yüz: geniş elmacık, yuvarlanan çene.
    final face = Path()
      ..moveTo(-21, -50)
      ..cubicTo(-23, -34, -22, -16, -14, -6)
      ..quadraticBezierTo(-6, 1, 0, 1)
      ..quadraticBezierTo(6, 1, 14, -6)
      ..cubicTo(22, -16, 23, -34, 21, -50)
      ..close();
    if (flat != null) {
      final p = Paint()..color = flat;
      c.drawPath(hat, p);
      if (kind != NemrutHead.tyche) c.drawPath(flaps, p);
      c.drawPath(face, p);
      c.drawRect(const Rect.fromLTRB(-24, -57, 24, -49), p);
      if (bearded) {
        c.drawPath(
          Path()
            ..moveTo(-21, -28)
            ..cubicTo(-24, -8, -13, 8, 0, 11)
            ..cubicTo(13, 8, 24, -8, 21, -28)
            ..close(),
          p,
        );
      }
      c.restore();
      return;
    }
    // Gölge: alt sağa düşer (taşın kütlesi).
    final all = Path()
      ..addPath(hat, Offset.zero)
      ..addPath(flaps, Offset.zero)
      ..addPath(face, Offset.zero);
    c.drawPath(
      all.shift(const Offset(3, 2)),
      Paint()..color = const Color(0xFF07050A).withValues(alpha: 0.55),
    );
    c.drawPath(hat, stone);
    if (kind != NemrutHead.tyche) c.drawPath(flaps, stone);
    c.drawPath(face, stone);
    // Alında desenli şerit (diadem).
    final band = Rect.fromLTRB(-24, -57, 24, -49);
    c.drawRect(band, stone);
    c.drawRect(band, rim);
    final zig = Path()..moveTo(-22, -51);
    for (var x = -22.0; x < 22; x += 4) {
      zig
        ..lineTo(x + 2, -55)
        ..lineTo(x + 4, -51);
    }
    c.drawPath(zig, cut..strokeWidth = 1.0);
    cut.strokeWidth = 1.6;
    // Başlığın dikiş çizgisi ve ışığa bakan kenarı.
    if (kind == NemrutHead.antiochos || kind == NemrutHead.zeus) {
      c.drawPath(
        Path()
          ..moveTo(-1, -57)
          ..quadraticBezierTo(-2, -80, 1, -98),
        cut..strokeWidth = 0.9,
      );
      cut.strokeWidth = 1.6;
    }
    // Ay ışığı: siluetin sol yarısının kenarı parlar (gökyüzünden ayrılsın).
    c.save();
    c.clipRect(const Rect.fromLTRB(-40, -110, 4, 20));
    c.drawPath(
      Path()
        ..addPath(hat, Offset.zero)
        ..addPath(face, Offset.zero),
      Paint()
        ..color = _nRim.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    c.restore();
    // Kaşlar, badem gözler, burun.
    for (final s in const [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(s * 15, -39)
          ..quadraticBezierTo(s * 10, -43, s * 4, -40),
        cut,
      );
      c.drawPath(
        Path()
          ..moveTo(s * 15, -34)
          ..quadraticBezierTo(s * 10, -38, s * 5, -34)
          ..quadraticBezierTo(s * 10, -31, s * 15, -34),
        cut..strokeWidth = 1.3,
      );
      cut.strokeWidth = 1.6;
    }
    c.drawPath(
      Path()
        ..moveTo(-1, -38)
        ..lineTo(-3, -22)
        ..quadraticBezierTo(0, -19, 4, -22),
      cut,
    );
    // Burnun ışık alan yüzü.
    c.drawPath(
      Path()
        ..moveTo(-1, -37)
        ..lineTo(-3, -23)
        ..lineTo(-0.5, -23)
        ..close(),
      Paint()..color = _nRim.withValues(alpha: 0.3),
    );
    if (bearded) {
      // Gür, kıvırcık sakal ve bıyık; alında şeridin altında bukleler.
      final beard = Path()
        ..moveTo(-21, -28)
        ..cubicTo(-24, -8, -13, 8, 0, 11)
        ..cubicTo(13, 8, 24, -8, 21, -28)
        ..lineTo(15, -21)
        ..quadraticBezierTo(0, -12, -15, -21)
        ..close();
      c.drawPath(beard, stone);
      final curl = Paint()
        ..color = _nCut
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      for (var row = 0; row < 4; row++) {
        final y = -18.0 + row * 7;
        final half = 17.0 - row * 3.5;
        for (var x = -half; x <= half + 0.1; x += 5.5) {
          c.drawArc(
            Rect.fromCircle(center: Offset(x, y), radius: 2.4),
            0.4,
            math.pi * 1.4,
            false,
            curl,
          );
        }
      }
      c.drawPath(
        Path()
          ..moveTo(-11, -18)
          ..quadraticBezierTo(-5, -22, 0, -19)
          ..quadraticBezierTo(5, -22, 11, -18),
        cut,
      );
      for (var x = -18.0; x <= 18; x += 6) {
        c.drawArc(
          Rect.fromCircle(center: Offset(x, -47), radius: 2.6),
          0,
          math.pi,
          false,
          curl,
        );
      }
    } else {
      // Dudaklar ve çene.
      c.drawPath(
        Path()
          ..moveTo(-6, -14)
          ..quadraticBezierTo(0, -12, 6, -14),
        cut,
      );
      c.drawLine(const Offset(-3.5, -10.5), const Offset(3.5, -10.5), cut);
    }
    // Çatlaklar: yüzyılların kırığı.
    c.drawPath(
      Path()
        ..moveTo(-24, -66)
        ..lineTo(-12, -63)
        ..lineTo(-6, -66)
        ..lineTo(8, -62),
      cut..strokeWidth = 1.0,
    );
    c.drawPath(
      Path()
        ..moveTo(18, -44)
        ..lineTo(13, -36)
        ..lineTo(16, -28),
      cut,
    );
    // Başlığın tepesinde kar.
    c.drawOval(
      Rect.fromCenter(
        center: switch (kind) {
          NemrutHead.tyche => const Offset(0, -82),
          NemrutHead.herakles => const Offset(0, -80),
          NemrutHead.apollo => const Offset(10, -95),
          _ => const Offset(1, -99),
        },
        width: kind == NemrutHead.tyche ? 40 : 12,
        height: 3.5,
      ),
      Paint()..color = _nSnow,
    );
    c.restore();
  }

  /// Bloklardan bir yüzey: dolgu, ışık kenarı, taş sıraları (yatay derz)
  /// ve kaydırılmış dikey derzler.
  static void _masonry(Canvas c, Rect r, {double course = 0.9 * kTile}) {
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(r.topLeft, r.bottomRight, [
          const Color(0xFF4A4256),
          const Color(0xFF262030),
        ]),
    );
    final seam = Paint()
      ..color = _nCut
      ..strokeWidth = 1.2;
    var i = 0;
    for (var y = r.top + course; y < r.bottom - 2; y += course, i++) {
      c.drawLine(Offset(r.left, y), Offset(r.right, y), seam);
    }
    i = 0;
    for (var y = r.top; y < r.bottom - 2; y += course, i++) {
      final off = i.isEven ? 0.0 : kTile * 0.7;
      for (
        var x = r.left + off + kTile * 1.4;
        x < r.right - 4;
        x += kTile * 1.4
      ) {
        c.drawLine(
          Offset(x, y),
          Offset(x, math.min(r.bottom, y + course)),
          seam,
        );
      }
    }
    c.drawLine(
      r.topLeft,
      r.topRight,
      Paint()
        ..color = _nRim.withValues(alpha: 0.5)
        ..strokeWidth = 1.4,
    );
    c.drawLine(
      r.topLeft,
      r.bottomLeft,
      Paint()
        ..color = _nRim.withValues(alpha: 0.3)
        ..strokeWidth = 1.2,
    );
  }

  /// Oturan dev tanrı (sağa bakar): taş sıralarından örülmüş gövde, taht,
  /// kucağa inen kol, diz. Tırmanılan karelerle hizalıdır: ayak taşı
  /// (-1..0, 2 kare), taht (0..6, 4 kare), diz (6..7, 3 kare), kol (5..6,
  /// -6..-5), omuzlar (1..5, -8..-7). Zemin orijindedir.
  static void seated(Canvas c, {NemrutHead? head}) {
    const t = kTile;
    final stone = Paint()
      ..shader = Gradient.linear(
        const Offset(0, -9 * t),
        const Offset(7 * t, 0),
        [_nStoneLit, _nStoneDark],
      );
    final outline = Paint()
      ..color = _nCut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rim = Paint()
      ..color = _nRim.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final seam = Paint()
      ..color = _nCut
      ..strokeWidth = 1.2;
    void part(Path p, {bool lit = true}) {
      c.drawPath(p, stone);
      c.drawPath(p, outline);
      if (lit) {
        // Ay ışığı üst-sol kenarda.
        c.save();
        c.clipRect(
          p.getBounds().translate(-2, -2).deflate(0).topLeft &
              Size(p.getBounds().width * 0.55, p.getBounds().height * 0.6),
        );
        c.drawPath(p, rim);
        c.restore();
      }
    }

    RRect rr(double l, double tp, double r, double b, double rad) =>
        RRect.fromLTRBR(l * t, tp * t, r * t, b * t, Radius.circular(rad * t));

    // Tahtın arkalığı.
    part(Path()..addRRect(rr(0, -8.8, 1.1, -3.2, 0.2)));
    // Ayak taşı (tahtın ardındaki basamak).
    part(Path()..addRRect(rr(-1, -2, 0.1, 0, 0.12)));
    // Oturak: pervazlı taş blok.
    part(Path()..addRRect(rr(0, -3.4, 5.8, 0, 0.1)), lit: false);
    part(Path()..addRRect(rr(-0.1, -3.6, 5.9, -3.2, 0.1)));
    c.drawLine(const Offset(2.9 * t, -3.2 * t), const Offset(2.9 * t, 0), seam);
    c.drawLine(
      const Offset(0, -1.6 * t),
      const Offset(5.8 * t, -1.6 * t),
      seam,
    );
    // Gövde: düz sırt, yuvarlak omuzlar, öne dolgun göğüs.
    final torso = Path()
      ..moveTo(1.0 * t, -3.6 * t)
      ..lineTo(1.1 * t, -7.3 * t)
      ..quadraticBezierTo(1.15 * t, -8.05 * t, 2.1 * t, -8.05 * t)
      ..lineTo(4.2 * t, -8.05 * t)
      ..quadraticBezierTo(5.05 * t, -8.0 * t, 5.1 * t, -7.2 * t)
      ..quadraticBezierTo(5.25 * t, -6.2 * t, 4.9 * t, -5.2 * t)
      ..quadraticBezierTo(4.8 * t, -4.3 * t, 5.2 * t, -3.9 * t)
      ..lineTo(1.0 * t, -3.6 * t)
      ..close();
    part(torso);
    // Giysinin çapraz kıvrımları ve kuşak.
    c.save();
    c.clipPath(torso);
    final fold = Paint()
      ..color = _nCut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 4; i++) {
      c.drawPath(
        Path()
          ..moveTo(1.6 * t + i * 0.5 * t, -8 * t)
          ..quadraticBezierTo(
            2.8 * t + i * 0.5 * t,
            -6.4 * t,
            4.6 * t,
            -5.4 * t + i * 0.3 * t,
          ),
        fold,
      );
    }
    c.drawRect(
      Rect.fromLTRB(1 * t, -4.75 * t, 5.3 * t, -4.45 * t),
      Paint()..color = const Color(0xFF2A2432),
    );
    // Taş sıralarının iki büyük derzi.
    c.drawLine(Offset(1 * t, -6.2 * t), Offset(5.3 * t, -6.2 * t), seam);
    c.restore();
    // Uyluk: kalçadan dize, dizi yuvarlak.
    part(
      Path()
        ..moveTo(0.9 * t, -4.3 * t)
        ..lineTo(6.3 * t, -4.25 * t)
        ..quadraticBezierTo(7.15 * t, -4.2 * t, 7.0 * t, -3.2 * t)
        ..lineTo(1.0 * t, -3.2 * t)
        ..close(),
    );
    // İncik ve ayak.
    part(Path()..addRRect(rr(6.0, -3.4, 6.95, -0.4, 0.3)), lit: false);
    part(
      Path()
        ..moveTo(5.9 * t, -0.65 * t)
        ..lineTo(7.2 * t, -0.6 * t)
        ..quadraticBezierTo(7.7 * t, -0.5 * t, 7.6 * t, 0)
        ..lineTo(5.9 * t, 0)
        ..close(),
    );
    // Kol: omuzdan inen pazı, yatay ön kol, dizine düşen yumruk.
    part(Path()..addRRect(rr(3.7, -7.9, 4.85, -5.4, 0.45)));
    part(Path()..addRRect(rr(4.0, -6.0, 6.2, -5.0, 0.4)));
    part(Path()..addRRect(rr(5.45, -5.4, 6.35, -4.15, 0.35)), lit: false);
    // Kar: üste bakan yüzlerde.
    final snow = Paint()..color = _nSnow;
    for (final r in const [
      Rect.fromLTWH(-1 * t, -2.08 * t, 1.1 * t, 0.12 * t),
      Rect.fromLTWH(1.1 * t, -4.34 * t, 5.2 * t, 0.12 * t),
      Rect.fromLTWH(4.1 * t, -6.08 * t, 2.0 * t, 0.12 * t),
      Rect.fromLTWH(1.6 * t, -8.12 * t, 3.0 * t, 0.12 * t),
      Rect.fromLTWH(0, -8.86 * t, 1.1 * t, 0.12 * t),
    ]) {
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), snow);
    }
    if (head != null) {
      c.save();
      c.translate(3.0 * t, -7.9 * t);
      NemrutArt.head(c, head, 5.2 * t);
      c.restore();
    } else {
      // Başın koptuğu boyun kırığı.
      c.drawPath(
        Path()
          ..moveTo(2.4 * t, -8 * t)
          ..lineTo(2.5 * t, -8.45 * t)
          ..lineTo(2.9 * t, -8.3 * t)
          ..lineTo(3.2 * t, -8.55 * t)
          ..lineTo(3.6 * t, -8.35 * t)
          ..lineTo(3.7 * t, -8 * t)
          ..close(),
        Paint()..color = const Color(0xFF2A2432),
      );
    }
  }

  /// Terasın kartalı: kaidesinin üstünde dimdik, başı yana dönük, kıvrık
  /// gagalı; kanatları kapalı. Ayakları orijinde, boyu [height].
  static void eagle(Canvas c, double height) {
    c.save();
    c.scale(height / 100);
    final stone = Paint()
      ..shader = Gradient.linear(const Offset(-24, 0), const Offset(24, 0), [
        _nStoneLit,
        _nStoneDark,
      ]);
    final body = Path()
      ..moveTo(-14, -8)
      ..cubicTo(-22, -40, -16, -70, 0, -78)
      ..cubicTo(8, -82, 12, -80, 14, -74)
      ..cubicTo(21, -58, 22, -32, 14, -8)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(6, -86), radius: 10))
      ..moveTo(13, -91)
      ..quadraticBezierTo(27, -90, 24, -77)
      ..quadraticBezierTo(20, -82, 13, -81)
      ..close()
      ..moveTo(-12, -10)
      ..lineTo(-26, 0)
      ..lineTo(-4, 0)
      ..close()
      ..addRect(const Rect.fromLTRB(-2, -8, 12, 0));
    c.drawPath(
      body.shift(const Offset(3, 2)),
      Paint()..color = const Color(0xFF07050A).withValues(alpha: 0.55),
    );
    c.drawPath(body, stone);
    // Kapalı kanat ve tüy sıraları.
    final wing = Path()
      ..moveTo(-10, -66)
      ..cubicTo(-24, -50, -24, -24, -16, -6)
      ..lineTo(-4, -14)
      ..cubicTo(-9, -32, -6, -50, 0, -62)
      ..close();
    c.drawPath(wing, Paint()..color = const Color(0xFF241E2C));
    final cut = Paint()
      ..color = _nCut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 6; i++) {
      final y = -56.0 + i * 8;
      c.drawPath(
        Path()
          ..moveTo(-18 + i * 0.5, y)
          ..quadraticBezierTo(-10, y + 4, -4 - i * 0.4, y - 1),
        cut,
      );
    }
    // Göğüs tüyleri.
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 2; j++) {
        c.drawArc(
          Rect.fromCircle(
            center: Offset(6 + j * 6.0 - (i.isOdd ? 3 : 0), -60 + i * 9.0),
            radius: 3,
          ),
          0,
          math.pi,
          false,
          cut,
        );
      }
    }
    c.drawCircle(const Offset(9, -88), 1.6, Paint()..color = _nCut);
    c.drawPath(
      Path()
        ..moveTo(-12, -60)
        ..cubicTo(-18, -46, -16, -26, -12, -10),
      Paint()
        ..color = _nRim.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(4, -95), width: 12, height: 3),
      Paint()..color = _nSnow,
    );
    c.restore();
  }
}
