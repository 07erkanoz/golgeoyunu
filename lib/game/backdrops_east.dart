part of 'atmosphere.dart';

/// Kaf'tan Konya'ya yeni mekânların gökyüzü ve uzak siluetleri.
extension _EastBackdrops on Backdrop {
  // ------------------------------------------------------------- ortak

  void _stars(Canvas canvas, double w, double h, int count, double camX) {
    final p = Paint();
    for (var i = 0; i < count; i++) {
      final rnd = math.Random(i * 7349 + 11);
      final x = ((rnd.nextDouble() * w * 1.5 - camX * 0.02) % w + w) % w;
      final y = rnd.nextDouble() * h * 0.6;
      final tw = 0.5 + 0.5 * math.sin(_t * (0.8 + rnd.nextDouble()) + i);
      p.color = const Color(0xFFEFF4FF)
          .withValues(alpha: 0.15 + 0.5 * tw * rnd.nextDouble());
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble(), p);
    }
  }

  void _moon(Canvas canvas, Offset c, double r, Color tint) {
    _lightLeak(canvas, c, r * 5, 0.22, tint);
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF4F1E6));
    canvas.drawCircle(
      c.translate(r * 0.25, -r * 0.1),
      r * 0.9,
      Paint()..color = const Color(0xFFE4DFCF).withValues(alpha: 0.35),
    );
  }

  /// Tekrarlanan bir siluet katmanı: [draw] her örneği x konumunda çizer.
  void _repeat(
    double w,
    double offset,
    double spacing,
    void Function(double x, math.Random rnd) draw, {
    int salt = 0,
  }) {
    final first = ((offset - spacing) / spacing).floor();
    for (var i = first; i * spacing - offset < w + spacing; i++) {
      draw(i * spacing - offset, math.Random(i * 92821 + salt));
    }
  }

  void _pines(
    Canvas canvas,
    double w, {
    required double offset,
    required double base,
    required double size,
    required Color color,
    Color? snow,
    int salt = 0,
  }) {
    final paint = Paint()..color = color;
    final cap = snow == null ? null : (Paint()..color = snow);
    _repeat(w, offset, 46 * size, (x, rnd) {
      if (rnd.nextDouble() < 0.25) return;
      final hgt = (70 + rnd.nextDouble() * 60) * size;
      final bx = x + rnd.nextDouble() * 20 * size;
      final path = Path()..moveTo(bx, base - hgt);
      const tiers = 4;
      for (var t = 1; t <= tiers; t++) {
        final y = base - hgt + hgt * t / tiers;
        final half = hgt * 0.16 * t / tiers + 6 * size;
        path
          ..lineTo(bx + half, y)
          ..lineTo(bx + half * 0.45, y);
      }
      path.lineTo(bx + 3 * size, base + 4);
      path.lineTo(bx - 3 * size, base + 4);
      for (var t = tiers; t >= 1; t--) {
        final y = base - hgt + hgt * t / tiers;
        final half = hgt * 0.16 * t / tiers + 6 * size;
        path
          ..lineTo(bx - half * 0.45, y)
          ..lineTo(bx - half, y);
      }
      path.close();
      canvas.drawPath(path, paint);
      if (cap != null) {
        for (var t = 1; t <= tiers; t++) {
          final y = base - hgt + hgt * t / tiers;
          final half = hgt * 0.16 * t / tiers + 6 * size;
          canvas.drawPath(
            Path()
              ..moveTo(bx - half * 0.8, y - 1)
              ..quadraticBezierTo(
                bx,
                y - hgt / tiers * 0.45,
                bx + half * 0.8,
                y - 1,
              )
              ..close(),
            cap,
          );
        }
      }
    }, salt: salt);
  }

  // --------------------------------------------------------------- Kaf

  /// Kaf Dağı: zümrüt kayalar, dev ay, düşen Simurg tüyleri.
  void _kaf(Canvas canvas, double w, double h, Vector2 cam, double height) {
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [
      lerpColor(0xFF05121A, 0xFF071A26, height),
      lerpColor(0xFF0E3A3A, 0xFF16504A, height),
      lerpColor(0xFF2E6F5E, 0xFF5FA88A, height),
    ]);
    _stars(canvas, w, h, 70, cam.x);
    _moon(canvas, Offset(w * 0.78, h * 0.2), h * 0.07, const Color(0xFFBFF5DC));
    final rise = -cam.y * 0.04;
    // Kuzey ışığı gibi yeşil bir perde.
    for (var k = 0; k < 3; k++) {
      final path = Path()..moveTo(-20, h * 0.1);
      for (var x = -20.0; x <= w + 20; x += 20) {
        path.lineTo(
          x,
          h * (0.12 + k * 0.05) +
              math.sin(x * 0.004 + _t * 0.15 + k * 2) * h * 0.05 -
              cam.x * 0,
        );
      }
      path
        ..lineTo(w + 20, h * 0.45)
        ..lineTo(-20, h * 0.45)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, h * 0.1),
            Offset(0, h * 0.45),
            [
              const Color(0xFF7FFFC8).withValues(alpha: 0.07 - k * 0.015),
              const Color(0x007FFFC8),
            ],
          ),
      );
    }
    // Uzak zümrüt sıradağlar.
    _rockyRange(
      canvas,
      w,
      h,
      offset: cam.x * 0.03,
      base: h * 0.62 + rise,
      height: h * 0.2,
      seed: 41,
      body: const Color(0xFF1E5248),
      snow: const Color(0xFF8AD8B8),
      snowline: 0.35,
    );
    // Kaf'ın dev doruğu: dünyanın kıyısında; belinde bulut kuşağı, tepesinde
    // Simurg'un yuvasından sızan altın ışık.
    final kx = w * 0.5 - cam.x * 0.02;
    final kb = h * 0.75 + rise;
    final glow = 0.6 + 0.4 * math.sin(_t * 0.8);
    _lightLeak(
      canvas,
      Offset(kx, kb - h * 0.72),
      h * 0.35,
      0.25 * glow,
      const Color(0xFFFFE6A0),
    );
    _volcano(
      canvas,
      kx,
      kb,
      h * 0.72,
      w * 0.32,
      7,
      h,
      body: const [Color(0xFF2A6A5A), Color(0xFF184A40), Color(0xFF0A2420)],
      snowCols: const [Color(0xFFD8FFF0), Color(0xFF9AE0C4), Color(0xFF4A9A80)],
    );
    // Bulut kuşağı.
    final belt = Paint();
    for (var i = 0; i < 9; i++) {
      final u = i / 8 * 2 - 1;
      final x = kx + u * w * 0.34 + math.sin(_t * 0.2 + i) * 14;
      final y = kb - h * 0.36 + math.sin(i * 1.7) * 8;
      belt
        ..color = const Color(0xFFCFF0E4).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: w * 0.16,
          height: h * 0.05,
        ),
        belt,
      );
    }
    // Yakın sıradağlar ve sis.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62 + rise, w, h * 0.2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.62 + rise),
          Offset(0, h * 0.82 + rise),
          const [Color(0x007FD8B8), Color(0x337FD8B8), Color(0x007FD8B8)],
          const [0, 0.5, 1],
        ),
    );
    _rockyRange(
      canvas,
      w,
      h,
      offset: cam.x * 0.18,
      base: h * 0.86 + rise * 1.5,
      height: h * 0.22,
      seed: 43,
      body: const Color(0xFF0C2A26),
      snow: const Color(0xFF3E8A72),
      snowline: 0.25,
    );
    // Süzülen tüyler.
    final feather = Paint()
      ..color = const Color(0xFFE8D58A).withValues(alpha: 0.55);
    for (var i = 0; i < 7; i++) {
      final k = ((_t * (0.02 + i * 0.004) + i * 0.37) % 1.0);
      final x =
          ((i * 211.0 + math.sin(_t * 0.5 + i) * 60 - cam.x * 0.3) % w + w) % w;
      canvas.save();
      canvas.translate(x, h * k);
      canvas.rotate(math.sin(_t + i) * 0.8);
      canvas.drawOval(const Rect.fromLTWH(-2.5, -10, 5, 20), feather);
      canvas.restore();
    }
  }

  // --------------------------------------------------------------- kar

  /// Karlı dağlar: 0 Ağrı'nın iki tepesi, 1 Palandöken'in çamlı yamaçları,
  /// 2 çığ: tipiyle kapanan gök. Ay soldan vurur: dağların sol yamaçları
  /// aydınlık, sağları gölgede; kar yarıklardan aşağı iner.
  void _snowPeaks(
    Canvas canvas,
    double w,
    double h,
    Vector2 cam,
    double height,
    int variant,
  ) {
    final storm = variant == 2;
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [
      storm ? const Color(0xFF1A2230) : const Color(0xFF050A18),
      lerpColor(0xFF16223C, 0xFF243652, height),
      storm ? const Color(0xFF8A98A8) : const Color(0xFF4A5E7E),
    ]);
    if (!storm) {
      _stars(canvas, w, h, 120, cam.x);
      // Samanyolu.
      canvas.save();
      canvas.translate(w * 0.6 - cam.x * 0.004, h * 0.25);
      canvas.rotate(-0.45);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * 1.3, height: h * 0.16),
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, w * 0.65, const [
            Color(0x22CFD8FF),
            Color(0x00CFD8FF),
          ]),
      );
      canvas.restore();
    }
    _moon(
      canvas,
      Offset(w * 0.18, h * 0.15),
      h * 0.05,
      const Color(0xFFDCE6FF),
    );
    final rise = (game.level.pixelHeight - cam.y) * 0.05;
    // Uzak sıradağlar (pusa karışan).
    _rockyRange(
      canvas,
      w,
      h,
      offset: cam.x * 0.03,
      base: h * 0.7 + rise * 0.4,
      height: h * 0.2,
      seed: 3,
      body: const Color(0xFF2E3E5A),
      snow: const Color(0xFF9AAAC4),
      snowline: 0.45,
    );
    if (variant == 0) {
      // Büyük ve Küçük Ağrı: kayalık volkan koniler, zirvede buzul.
      final dx = -cam.x * 0.035;
      _volcano(
        canvas,
        w * 0.58 + dx,
        h * 0.78 + rise * 0.5,
        h * 0.62,
        w * 0.38,
        11,
        h,
      );
      _volcano(
        canvas,
        w * 0.95 + dx,
        h * 0.78 + rise * 0.5,
        h * 0.36,
        w * 0.17,
        23,
        h,
      );
    } else if (!storm) {
      // Büyük ve Küçük Ejder: Palandöken'in iki doruğu.
      final dx = -cam.x * 0.035;
      _volcano(
        canvas,
        w * 0.42 + dx,
        h * 0.8 + rise * 0.5,
        h * 0.42,
        w * 0.3,
        5,
        h,
      );
      _volcano(
        canvas,
        w * 0.78 + dx,
        h * 0.8 + rise * 0.5,
        h * 0.34,
        w * 0.26,
        17,
        h,
      );
    }
    // Pus: dağların eteğinde yatay sis bandı.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62 + rise * 0.6, w, h * 0.2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.62 + rise * 0.6),
          Offset(0, h * 0.82 + rise * 0.6),
          const [Color(0x00AAB8D0), Color(0x40AAB8D0), Color(0x00AAB8D0)],
          const [0, 0.5, 1],
        ),
    );
    _rockyRange(
      canvas,
      w,
      h,
      offset: cam.x * 0.12,
      base: h * 0.8 + rise,
      height: h * 0.14,
      seed: 21,
      body: const Color(0xFF1C2638),
      snow: const Color(0xFF6E7E98),
      snowline: 0.3,
    );
    _pines(
      canvas,
      w,
      offset: cam.x * 0.25,
      base: h * 0.86 + rise * 1.3,
      size: 0.7,
      color: const Color(0xFF101824),
      snow: const Color(0xFF7A8AA4),
      salt: 3,
    );
    if (variant == 1) {
      // Uzakta Erzurum: kalenin ve medrese minarelerinin ışıkları.
      final city = Paint()
        ..color = const Color(0xFFFFC27A).withValues(alpha: 0.6);
      for (var i = 0; i < 26; i++) {
        final rnd = math.Random(i * 31 + 5);
        final x = ((rnd.nextDouble() * w * 1.4 - cam.x * 0.06) % w + w) % w;
        canvas.drawCircle(
          Offset(x, h * 0.86 + rnd.nextDouble() * 8),
          1.1,
          city,
        );
      }
    }
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.4,
      base: h * 0.92 + rise * 1.6,
      amp: 26,
      freq: 0.012,
      seed: 22,
      color: const Color(0xFFB8C6D8),
    );
    if (storm) {
      // Tipi: gökyüzü beyaza boğulur.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFDDE6F0)
              .withValues(alpha: 0.12 + 0.06 * math.sin(_t * 0.7)),
      );
    }
  }

  /// Kayalık sıradağ: sivri, kırıklı tepeler; ay soldan vurduğu için her
  /// tepenin sol yamacı açık, sağı koyu; zirvelerde kar, yarıklardan iner.
  void _rockyRange(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
    required double base,
    required double height,
    required int seed,
    required Color body,
    required Color snow,
    required double snowline,
  }) {
    // Tepe noktaları: düzensiz aralık ve yükseklik.
    const span = 140.0;
    final first = ((offset - span) / span).floor();
    final peaks = <Offset>[];
    // Her tepenin dünyadaki sırası: rastgele ayrıntılar (boyun, kar) buna
    // bağlıdır, kamera kaydıkça değişmez (eskiden ekran konumuna bağlıydı,
    // tepeler her harekette kıpırdıyordu).
    final ids = <int>[];
    for (var i = first; i * span - offset < w + span * 2; i++) {
      final r = math.Random(i * 7919 + seed);
      ids.add(i);
      peaks.add(
        Offset(
          i * span - offset + r.nextDouble() * 60,
          base - height * (0.45 + r.nextDouble() * 0.55),
        ),
      );
    }
    final outline = <Offset>[Offset(-20, base)];
    for (var k = 0; k < peaks.length; k++) {
      final p = peaks[k];
      outline.add(p);
      if (k + 1 < peaks.length) {
        final q = peaks[k + 1];
        final r = math.Random(ids[k] * 31 + seed);
        // İki tepe arasında kırıklı bir boyun.
        final mid = Offset.lerp(p, q, 0.45 + r.nextDouble() * 0.1)!;
        outline.add(
          Offset(
            Offset.lerp(p, mid, 0.5)!.dx,
            Offset.lerp(p, mid, 0.5)!.dy + height * 0.1 * r.nextDouble(),
          ),
        );
        outline.add(
          Offset(
            mid.dx,
            math.max(p.dy, q.dy) + height * (0.25 + 0.2 * r.nextDouble()),
          ),
        );
      }
    }
    outline.add(Offset(w + 20, base));
    final path = Path()..moveTo(outline.first.dx, outline.first.dy);
    for (final p in outline.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(w + 20, h)
      ..lineTo(-20, h)
      ..close();
    canvas.drawPath(path, Paint()..color = body);
    canvas.save();
    canvas.clipPath(path);
    // Gölgeli yamaçlar: her tepeden sağa aşağı inen koyu üçgen.
    final dark = Paint()
      ..color = Color.lerp(body, const Color(0xFF000000), 0.35)!;
    final lit = Paint()..color = Color.lerp(body, snow, 0.18)!;
    for (var pi = 0; pi < peaks.length; pi++) {
      final p = peaks[pi];
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx + height * 1.1, base + 4)
          ..lineTo(p.dx + height * 0.15, base + 4)
          ..close(),
        dark,
      );
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx - height * 0.2, base)
          ..lineTo(p.dx - height * 0.6, base)
          ..close(),
        lit,
      );
      // Kar: zirveden yarıklara dalga dalga iner.
      final sl = p.dy + (base - p.dy) * snowline;
      final r = math.Random(ids[pi] * 131 + seed);
      final half = (sl - p.dy) * 1.3;
      final cpts = <Offset>[Offset(p.dx, p.dy - 2)];
      for (var k = 0; k <= 8; k++) {
        final u = k / 8;
        final x = p.dx + half * (u * 2 - 1) * 0.9;
        final down =
            (k.isEven ? 1.0 : 0.55) *
            (sl - p.dy) *
            (0.7 + r.nextDouble() * 0.6);
        cpts.add(Offset(x, p.dy + down * (1 - (u * 2 - 1).abs() * 0.5)));
      }
      final cap = smoothClosed(cpts);
      canvas.drawPath(cap, Paint()..color = snow);
      // Gölgedeki kar daha koyu.
      canvas.save();
      canvas.clipPath(cap);
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - 4)
          ..lineTo(p.dx + half * 1.2, p.dy + (sl - p.dy) * 1.4)
          ..lineTo(p.dx + half * 0.05, p.dy + (sl - p.dy) * 1.6)
          ..close(),
        Paint()..color = Color.lerp(snow, body, 0.45)!,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  /// Kayalık volkan koni (Ağrı): pürüzlü dış hat, sol yamaç ay ışığında,
  /// zirvede buzul ve aşağı inen kar dilleri, eteğinde kaya şeritleri.
  void _volcano(
    Canvas canvas,
    double cx,
    double base,
    double tall,
    double half,
    int seed,
    double h, {
    List<Color> body = const [
      Color(0xFF34445E),
      Color(0xFF222E46),
      Color(0xFF101828),
    ],
    List<Color> snowCols = const [
      Color(0xFFF2F6FF),
      Color(0xFFD0DAEA),
      Color(0xFF7E8EAC),
    ],
  }) {
    final top = base - tall;
    final r = math.Random(seed);
    final outline = <Offset>[];
    const n = 28;
    for (var k = 0; k <= n; k++) {
      final u = k / n * 2 - 1; // -1 sol etek, 1 sağ etek
      // Konkav koni: zirveye doğru dikleşir, tepesi hafif kesik.
      final y = top + tall * math.pow(u.abs(), 0.62) + (u.abs() < 0.08 ? 4 : 0);
      final jag = (r.nextDouble() - 0.5) * tall * 0.035 * (0.3 + u.abs());
      outline.add(Offset(cx + u * half, y + jag));
    }
    final path = Path()..moveTo(outline.first.dx, outline.first.dy);
    for (final p in outline.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(cx + half, h)
      ..lineTo(cx - half, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - half, 0),
          Offset(cx + half, 0),
          body,
          const [0, 0.48, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(path);
    // Kar örtüsü: zirvede kalın buzul, yamaçlarda düzensiz, yumuşak
    // diller (yarıklarda uzun, sırtlarda kısa).
    final pts = <Offset>[Offset(cx - half * 1.1, top - 20)];
    const tongues = 30;
    for (var k = 0; k <= tongues; k++) {
      final u = k / tongues * 2 - 1;
      final rr = math.Random(seed * 97 + k);
      final along = 0.24 + 0.12 * rr.nextDouble() + (k % 3 == 0 ? 0.08 : 0);
      final y =
          top + tall * along * (1 - u.abs() * 0.55) + tall * 0.06 * u.abs();
      pts.add(Offset(cx + u * half * 0.9, y));
    }
    pts.add(Offset(cx + half * 1.1, top - 20));
    final snow = smoothClosed(pts);
    canvas.drawPath(
      snow,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - half * 0.5, 0),
          Offset(cx + half * 0.5, 0),
          snowCols,
          const [0, 0.5, 1],
        ),
    );
    // Yarıklar: zirveden aşağı kıvrılan ince gölgeler (karın ve kayanın
    // üstünde).
    final crev = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0E1420).withValues(alpha: 0.35);
    for (var k = 0; k < 7; k++) {
      final rr = math.Random(seed * 13 + k);
      final u = (rr.nextDouble() * 2 - 1) * 0.8;
      final x0 = cx + u * half * 0.25;
      final y0 = top + tall * (0.08 + rr.nextDouble() * 0.1);
      final len = tall * (0.25 + rr.nextDouble() * 0.35);
      canvas.drawPath(
        Path()
          ..moveTo(x0, y0)
          ..quadraticBezierTo(
            x0 + u * half * 0.3 + (rr.nextDouble() - 0.5) * 20,
            y0 + len * 0.5,
            x0 + u * half * 0.55,
            y0 + len,
          ),
        crev,
      );
    }
    canvas.restore();
  }

  // --------------------------------------------------------- Nuh'un Gemisi

  /// Taşlaşmış geminin içi: dev kaburgalar, asılı kandiller ve duvarda
  /// ikişer ikişer yürüyen hayvan gölgeleri.
  /// Kameranın baktığı yerde ambarın tavanı ve tabanı (ekran koordinatı).
  /// Her sütunda yukarıdan ilk boşluk tavan, ondan aşağı ilk kaya taban
  /// sayılır; ambarın içindeki bloklar (sandık rafı vb.) etkilemez. Ekranın
  /// ortasındaki geniş bir pencerenin ortancası alınır: kamera kaydıkça
  /// kirişler, kandiller ve hayvan gölgeleri zıplamaz.
  (double, double) _holdBand(double h) {
    final lv = game.level;
    if (!identical(_holdFor, lv)) {
      _holdFor = lv;
      _holdTop = null;
      _holdBottom = null;
      _hold = [
        for (var c = 0; c < lv.width; c++)
          () {
            var r = 0;
            while (r < lv.height && lv.solid(c, r)) {
              r++;
            }
            if (r >= lv.height) return null;
            var b = r;
            while (b < lv.height && !lv.solid(c, b)) {
              b++;
            }
            return (r, b);
          }(),
      ];
    }
    final view = game.camera.visibleWorldRect;
    final c0 = (view.center.dx / 32.0).floor();
    final tops = <int>[];
    final bottoms = <int>[];
    for (var c = c0 - 14; c <= c0 + 14; c++) {
      if (c < 0 || c >= lv.width) continue;
      final band = _hold![c];
      if (band == null) continue;
      tops.add(band.$1);
      bottoms.add(band.$2);
    }
    if (tops.isEmpty) return (h * 0.25, h * 0.8);
    tops.sort();
    bottoms.sort();
    const tile = 32.0; // kTile
    double toScreen(double wy) => (wy - view.top) / view.height * h;
    final wantTop = tops[tops.length ~/ 2] * tile;
    final wantBottom = bottoms[bottoms.length ~/ 2] * tile;
    final dt = (_t - _holdT).clamp(0.0, 0.1);
    _holdT = _t;
    final k = math.min(1.0, dt * 1.5);
    final top = _holdTop == null
        ? wantTop
        : _holdTop! + (wantTop - _holdTop!) * k;
    final bottom = _holdBottom == null
        ? wantBottom
        : _holdBottom! + (wantBottom - _holdBottom!) * k;
    _holdTop = top;
    _holdBottom = bottom;
    return (toScreen(top), toScreen(bottom));
  }

  /// Nuh'un Gemisi'nin ambarı: bindirme kalaslı iç gövde, eğri postalar,
  /// güverteyi taşıyan kirişler, aralıklarından sızan gün ışığı; fenerlerin
  /// önünden geçen hayvanların gölgeleri gövdeye perde gibi düşer.
  void _arkHull(Canvas canvas, double w, double h, Vector2 cam) {
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), const [
      Color(0xFF0C0705),
      Color(0xFF24150C),
      Color(0xFF3A2414),
    ]);
    final (top, bottom) = _holdBand(h);
    final hold = (bottom - top).clamp(120.0, h);

    // İç gövde: yatay bindirme kalaslar. Her kalas kendi tonunda; altında
    // bindirmenin gölgesi, üstünde ince ışık; lifler ve ağaç çiviler.
    const plank = 22.0;
    final wallX = cam.x * 0.25;
    final y0 = top - ((top / plank).ceil() + 1) * plank;
    final tones = [
      for (var k = 0; k < 4; k++)
        Paint()
          ..color = Color.lerp(
            const Color(0xFF3A2212),
            const Color(0xFF4E2F18),
            k / 3,
          )!,
    ];
    final lap = Paint()
      ..color = const Color(0xFF0E0704).withValues(alpha: 0.85);
    final edge = Paint()
      ..color = const Color(0xFF8A5A34).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final grain = Paint()
      ..color = const Color(0xFF1A0E07).withValues(alpha: 0.55)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    final peg = Paint()..color = const Color(0xFF1A0E07);
    for (var y = y0, i = 0; y < h; y += plank, i++) {
      final row = ((y + wallX * 0) / plank).round();
      // Kalaslar farklı boyda; ek yerleri sıradan sıraya kayar.
      const span = 720.0;
      final rowShift = (row * 263) % span;
      final start = -((wallX + rowShift) % span) - span;
      var x = start;
      var k = 0;
      while (x < w) {
        final len = 150.0 + ((row * 31 + k * 57) % 5) * 30;
        final tone = tones[((row * 7 + k * 3) % 4).abs()];
        canvas.drawRect(Rect.fromLTWH(x, y, len, plank), tone);
        for (var g = 0; g < 2; g++) {
          final gy = y + 6 + g * 8;
          final path = Path()..moveTo(x, gy);
          for (var gx = x; gx <= x + len; gx += 18) {
            path.lineTo(gx, gy + math.sin((gx - x) * 0.05 + row + g) * 1.3);
          }
          canvas.drawPath(path, grain);
        }
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + plank),
          lap..strokeWidth = 1.4,
        );
        canvas.drawCircle(Offset(x + 6, y + plank * 0.35), 1.3, peg);
        canvas.drawCircle(Offset(x + 6, y + plank * 0.7), 1.3, peg);
        x += len;
        k++;
        if (k > 40) break;
      }
      // Bindirme: üstteki kalasın alt kenarı gölge düşürür, kalasın üstü ışık.
      canvas.drawRect(Rect.fromLTWH(0, y + plank - 3, w, 3), lap);
      canvas.drawLine(Offset(0, y + 0.5), Offset(w, y + 0.5), edge);
    }

    // Fenerlerin gövdeye vurduğu sıcak ışık halkaları.
    const lampGap = 380.0;
    final lampX = cam.x * 0.5;
    _repeat(w, lampX, lampGap, (x, rnd) {
      _lightLeak(
        canvas,
        Offset(x, top + hold * 0.45),
        hold * 0.95,
        0.26,
        const Color(0xFFFFB46A),
      );
    }, salt: 4);

    // Geminin yalpası: kandiller ve lumbuzdaki ufuk aynı ritimle eğilir.
    final roll = math.sin(_t * 2 * math.pi / 7) * 0.07;
    _gunports(canvas, w, h, wallX, top, hold, roll);

    // Hayvan gölgeleri: ikişer ikişer geminin içinde yürüyen hayvanların
    // fener ışığıyla duvara düşen gölgeleri. Fenerden uzaklaştıkça gölge
    // uzar ve yana yatar, kandil titredikçe kıpırdar; kenarları yumuşak.
    final walk = _t * 16;
    final scale = (hold / 220).clamp(0.6, 1.5);
    _repeat(w, wallX - walk, 560, (x, rnd) {
      final kind = ArkAnimal.kinds[rnd.nextInt(ArkAnimal.kinds.length)];
      for (final (dx, ph) in [(0.0, 0.0), (86.0, 1.7)]) {
        final gx = x + dx * scale;
        // En yakın fener: gölge ondan uzağa düşer.
        final lamp = ((gx + lampX) / lampGap).round() * lampGap - lampX;
        final off = ((gx - lamp) / lampGap).clamp(-0.6, 0.6);
        final flick =
            0.94 +
            0.04 * math.sin(_t * 5.3 + gx) +
            0.02 * math.sin(_t * 13 + gx);
        final alpha = (0.72 - off.abs() * 0.3) * flick;
        canvas.save();
        canvas.translate(gx, bottom - 2);
        canvas.scale(
          scale * (1.15 + off.abs() * 0.5) * flick,
          scale * 1.15 * flick,
        );
        // Yürüyüş: başla birlikte inip kalkar.
        canvas.translate(0, -math.sin(_t * 3 + ph).abs() * 2.2);
        canvas.transform(
          Float64List.fromList([
            1, 0, 0, 0, //
            -off * 0.6, 1, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1,
          ]),
        );
        drawAnimalShadow(
          canvas,
          kind,
          const Color(0xFF080402).withValues(alpha: alpha),
          blur: 3.5 + off.abs() * 6,
        );
        canvas.restore();
      }
    }, salt: 9);

    // Postalar: tabandan yükselen, tavana doğru içe kıvrılan kalın kaburgalar;
    // tepede güverte kirişine bir dizle bağlanır.
    final frameX = cam.x * 0.5;
    const frameGap = 260.0;
    final frame = Paint()..color = const Color(0xFF1A0F08);
    final frameEdge = Paint()
      ..color = const Color(0xFF6A4226).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    _repeat(w, frameX, frameGap, (x, rnd) {
      final path = Path()
        ..moveTo(x - 11, bottom + 30)
        ..quadraticBezierTo(x - 20, top + hold * 0.5, x - 6, top + 14)
        ..lineTo(x - 40, top)
        ..lineTo(x + 46, top)
        ..lineTo(x + 12, top + 18)
        ..quadraticBezierTo(x + 2, top + hold * 0.5, x + 11, bottom + 30)
        ..close();
      canvas.drawPath(path, frame);
      // Fenere bakan kenar ışığı yakalar.
      canvas.drawPath(
        Path()
          ..moveTo(x + 11, bottom)
          ..quadraticBezierTo(x + 2, top + hold * 0.5, x + 12, top + 18),
        frameEdge..style = PaintingStyle.stroke,
      );
    }, salt: 2);

    // Güverte kirişi (iç kemer) ve güverte kalaslarının aralığından sızan ışık.
    canvas.drawRect(
      Rect.fromLTRB(0, top - 2, w, top + 9),
      Paint()..color = const Color(0xFF120A06),
    );
    final slit = Paint();
    _repeat(w, cam.x * 0.5, 97, (x, rnd) {
      final a = 0.25 + 0.25 * math.sin(_t * 0.7 + x * 0.05);
      slit.color = const Color(0xFFE8D6B0).withValues(alpha: a);
      canvas.drawRect(
        Rect.fromLTWH(x, top - 1, 30 + rnd.nextDouble() * 40, 1.2),
        slit,
      );
    }, salt: 6);

    // Kirişlerden sarkan kandiller.
    _repeat(w, lampX, lampGap, (x, rnd) {
      final y = top + hold * (0.28 + rnd.nextDouble() * 0.1);
      // Gemi yalpaladıkça kandil ters yöne sarkar.
      final sway = -roll * (y - top) * 1.4 + math.sin(_t * 1.7 + x) * 0.6;
      canvas.drawLine(
        Offset(x, top + 8),
        Offset(x + sway, y),
        Paint()
          ..color = const Color(0xFF170D07)
          ..strokeWidth = 1.5,
      );
      _lightLeak(
        canvas,
        Offset(x + sway, y + 6),
        90,
        0.45,
        const Color(0xFFFFC27A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + sway, y + 6),
            width: 7,
            height: 10,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFE2A8),
      );
    }, salt: 4);

    // Zemindeki yük: fıçılar, halat yumakları, saman balyaları.
    _cargo(canvas, w, cam.x * 0.62, bottom, (hold / 230).clamp(0.6, 1.3));
  }

  /// Gövdedeki lumbuzlar: içinde tufanın gece denizi, yağmur, arada şimşek;
  /// ufuk geminin yalpasıyla eğilir. Lumbuzdan ambara soğuk ışık düşer.
  void _gunports(
    Canvas canvas,
    double w,
    double h,
    double wallX,
    double top,
    double hold,
    double roll,
  ) {
    final size = (hold * 0.2).clamp(30.0, 58.0);
    final cy = top + hold * 0.36;
    // Şimşek: seyrek ve kısa.
    final flash =
        math.max(
          0.0,
          math.sin(_t * 0.37) * math.sin(_t * 1.31) * math.sin(_t * 0.23) -
              0.55,
        ) *
        4;
    _repeat(w, wallX, 430, (x, rnd) {
      final c = Offset(x, cy);
      final port = Rect.fromCenter(center: c, width: size, height: size * 0.82);
      // İçeri düşen soğuk ışık.
      canvas.drawPath(
        Path()
          ..moveTo(port.left + 4, port.bottom)
          ..lineTo(port.right - 4, port.bottom)
          ..lineTo(port.right + size * 1.6, top + hold)
          ..lineTo(port.left + size * 0.4, top + hold)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(
            port.bottomCenter,
            Offset(c.dx, top + hold),
            [
              const Color(0xFFAFC6E8).withValues(alpha: 0.10 + 0.25 * flash),
              const Color(0xFFAFC6E8).withValues(alpha: 0),
            ],
          ),
      );
      // Çerçeve.
      canvas.drawRRect(
        RRect.fromRectAndRadius(port.inflate(5), const Radius.circular(3)),
        Paint()..color = const Color(0xFF140B06),
      );
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(port, const Radius.circular(2)));
      // Gece göğü.
      canvas.drawRect(
        port,
        Paint()
          ..shader = ui.Gradient.linear(port.topCenter, port.bottomCenter, [
            Color.lerp(
              const Color(0xFF0B1424),
              const Color(0xFFDDE8FF),
              flash,
            )!,
            Color.lerp(
              const Color(0xFF1E2C44),
              const Color(0xFFB8C8E8),
              flash,
            )!,
          ]),
      );
      // Tufanın denizi: yalpayla eğilen ufuk, iki katman kabaran dalga,
      // tepelerinde köpük. Şimşekte dalgalar bir an aydınlanır.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(roll * 1.6);
      for (final (depth, amp, col, foam) in [
        (0.0, 3.0, const Color(0xFF22324A), 0.25),
        (size * 0.18, 5.0, const Color(0xFF16223A), 0.55),
      ]) {
        final sea = Path()..moveTo(-size, size);
        final pts = <Offset>[];
        for (var k = -size; k <= size; k += 2) {
          final y =
              depth +
              math.sin(k * 0.18 + _t * 1.6 + x * 0.01 + depth) * amp +
              math.sin(k * 0.07 - _t * 0.9) * amp * 0.8;
          pts.add(Offset(k, y));
          sea.lineTo(k, y);
        }
        sea
          ..lineTo(size, size)
          ..close();
        canvas.drawPath(
          sea,
          Paint()
            ..color = Color.lerp(col, const Color(0xFF8AA0C0), flash * 0.6)!,
        );
        final crest = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts) {
          crest.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          crest,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFDDE8F4).withValues(alpha: foam),
        );
      }
      canvas.restore();
      // Şimşek: göğü yaran kırık bir çizgi.
      if (flash > 0.3) {
        final bolt = Path()..moveTo(port.left + size * 0.6, port.top);
        var bx = port.left + size * 0.6;
        for (var by = port.top; by < c.dy; by += 6) {
          bx += ((by * 7 + x).round() % 7 - 3).toDouble();
          bolt.lineTo(bx, by);
        }
        canvas.drawPath(
          bolt,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFF4F8FF)
                .withValues(alpha: flash.clamp(0.0, 1.0)),
        );
      }
      // Yağmur.
      final rain = Paint()
        ..color = const Color(0xFFCAD8F0).withValues(alpha: 0.45)
        ..strokeWidth = 0.8;
      for (var k = 0; k < 14; k++) {
        final rx = port.left + ((k * 9.3 + _t * 40) % size);
        final ry = port.top + ((k * 13.7 + _t * 160) % (size * 0.82));
        canvas.drawLine(Offset(rx, ry), Offset(rx - 2, ry + 6), rain);
      }
      canvas.restore();
      // Çerçevenin aydınlık alt kenarı ve perçinler.
      canvas.drawLine(
        Offset(port.left - 5, port.bottom + 5),
        Offset(port.right + 5, port.bottom + 5),
        Paint()
          ..color = const Color(0xFF6A4226).withValues(alpha: 0.6)
          ..strokeWidth = 1.4,
      );
    }, salt: 11);
  }

  /// Ambarın zeminindeki yük siluetleri.
  void _cargo(Canvas canvas, double w, double offset, double floor, double k) {
    final ink = Paint()..color = const Color(0xFF140B06);
    final edge = Paint()
      ..color = const Color(0xFF7A4C2A).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _repeat(w, offset, 330, (x, rnd) {
      final kind = rnd.nextInt(3);
      canvas.save();
      canvas.translate(x, floor);
      canvas.scale(k);
      switch (kind) {
        case 0: // iki fıçı
          for (final (bx, bh) in [(0.0, 34.0), (26.0, 28.0)]) {
            final r = RRect.fromRectAndRadius(
              Rect.fromLTWH(bx, -bh, 24, bh),
              const Radius.circular(7),
            );
            canvas.drawRRect(r, ink);
            canvas.drawRRect(r, edge);
            for (final hy in [0.25, 0.75]) {
              canvas.drawLine(
                Offset(bx + 1, -bh * hy),
                Offset(bx + 23, -bh * hy),
                edge,
              );
            }
          }
        case 1: // halat yumağı
          for (var i = 0; i < 4; i++) {
            final rr = Rect.fromCenter(
              center: Offset(14, -4 - i * 5.0),
              width: 34 - i * 5.0,
              height: 9,
            );
            canvas.drawOval(rr, ink);
            canvas.drawOval(rr, edge);
          }
        default: // saman balyası
          final b = Rect.fromLTWH(0, -24, 46, 24);
          canvas.drawRect(b, ink);
          canvas.drawRect(b, edge);
          for (final sx in [12.0, 34.0]) {
            canvas.drawLine(Offset(sx, -24), Offset(sx, 0), edge);
          }
      }
      canvas.restore();
    }, salt: 13);
  }

  // ------------------------------------------------------------ Nemrut

  /// Nemrut: kışın taş tanrılar; başları ayaklarının dibine düşmüş.
  /// variant 1: gün doğumu, güneş tümülüsün ardından yükselir.
  void _nemrut(Canvas canvas, double w, double h, Vector2 cam, int variant) {
    final dawn = variant == 1
        ? (0.4 + 0.6 * (cam.x / game.level.pixelWidth)).clamp(0.0, 1.0)
        : 0.25;
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [
      Color.lerp(const Color(0xFF0D0C1C), const Color(0xFF3A2A4A), dawn)!,
      Color.lerp(const Color(0xFF3A2A40), const Color(0xFFC0604A), dawn)!,
      Color.lerp(const Color(0xFF7A5060), const Color(0xFFF4B070), dawn)!,
    ]);
    if (dawn < 0.5) _stars(canvas, w, h, 60, cam.x);
    // Tümülüs: dağın tepesinde çakıl taşından yapma koni.
    final tx = w * 0.5 - cam.x * 0.02;
    if (variant == 1) {
      final sunY = h * (0.62 - 0.35 * dawn);
      _lightLeak(
        canvas,
        Offset(tx, sunY),
        h * 0.8,
        0.35 * dawn,
        const Color(0xFFFFC080),
      );
      canvas.drawCircle(
        Offset(tx, sunY),
        h * 0.06,
        Paint()..color = const Color(0xFFFFE6B8),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(tx - w * 0.5, h * 0.7)
        ..quadraticBezierTo(tx - w * 0.1, h * 0.36, tx, h * 0.34)
        ..quadraticBezierTo(tx + w * 0.1, h * 0.36, tx + w * 0.5, h * 0.7)
        ..close(),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF2A2234),
          const Color(0xFF6A4040),
          dawn,
        )!,
    );
    // Karla örtülü teras.
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.08,
      base: h * 0.74,
      amp: 14,
      freq: 0.008,
      seed: 31,
      color: Color.lerp(
        const Color(0xFF8A90A8),
        const Color(0xFFE8D0C0),
        dawn,
      )!,
    );
    // Oturan dev tanrılar ve önlerine düşmüş başları.
    final stone = Color.lerp(
      const Color(0xFF1A1622),
      const Color(0xFF3A2A2A),
      dawn,
    )!;
    _repeat(w, cam.x * 0.18, 1400, (x, rnd) {
      final base = h * 0.76;
      final s = h / 720;
      var gx = x;
      _statueBird(canvas, gx, base, s, stone, eagle: true);
      gx += 120 * s;
      for (var i = 0; i < 5; i++) {
        // Bir kısmının başı yerinde, ötekilerin başı ayaklarının dibinde.
        final headOn = i.isOdd || (i == 2 && variant == 1);
        _seatedGod(canvas, gx, base, s, stone, headOn: headOn, tiara: i != 3);
        if (!headOn) {
          _fallenHead(
            canvas,
            gx + 30 * s,
            base + 10 * s,
            s * 0.95,
            stone,
            tiara: i.isEven,
            tilt: (i - 2) * 0.12,
          );
        }
        gx += 170 * s;
      }
      _statueBird(canvas, gx, base, s, stone, eagle: false);
    }, salt: 7);
  }

  void _seatedGod(
    Canvas canvas,
    double x,
    double base,
    double s,
    Color color, {
    required bool headOn,
    required bool tiara,
  }) {
    final p = Paint()..color = color;
    final seam = Paint()
      ..color = Color.lerp(color, const Color(0xFF000000), 0.45)!
      ..strokeWidth = 1.2 * s;
    // Taht.
    canvas.drawRect(
      Rect.fromLTWH(x - 60 * s, base - 120 * s, 120 * s, 120 * s),
      p,
    );
    // Gövde (taş sıralarından), omuzlar.
    canvas.drawPath(
      Path()
        ..moveTo(x - 34 * s, base - 120 * s)
        ..quadraticBezierTo(
          x - 30 * s,
          base - 180 * s,
          x - 44 * s,
          base - 236 * s,
        )
        ..quadraticBezierTo(
          x - 44 * s,
          base - 252 * s,
          x - 26 * s,
          base - 254 * s,
        )
        ..lineTo(x + 26 * s, base - 254 * s)
        ..quadraticBezierTo(
          x + 44 * s,
          base - 252 * s,
          x + 44 * s,
          base - 236 * s,
        )
        ..quadraticBezierTo(
          x + 30 * s,
          base - 180 * s,
          x + 34 * s,
          base - 120 * s,
        )
        ..close(),
      p,
    );
    // Kollar yanlarda, eller dizlerde; dizler tahtın önüne taşar.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x + side * 40 * s - (side < 0 ? 16 * s : 0),
            base - 244 * s,
            x + side * 40 * s + (side > 0 ? 16 * s : 0),
            base - 136 * s,
          ),
          Radius.circular(6 * s),
        ),
        p,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          x + side * 6 * s - (side < 0 ? 46 * s : 0),
          base - 140 * s,
          x + side * 6 * s + (side > 0 ? 46 * s : 0),
          base - 112 * s,
        ),
        p,
      );
    }
    // Taş sıralarının derzleri.
    for (var y = base - 26 * s; y > base - 250 * s; y -= 26 * s) {
      final half = y < base - 120 * s ? 40 * s : 60 * s;
      canvas.drawLine(Offset(x - half, y), Offset(x + half, y), seam);
    }
    canvas.drawLine(Offset(x, base - 112 * s), Offset(x, base - 140 * s), seam);
    // Karla örtülü omuzlar ve dizler.
    final snow = Paint()
      ..color = const Color(0xFFDCE2EE).withValues(alpha: 0.85);
    canvas.drawRect(
      Rect.fromLTWH(x - 52 * s, base - 142 * s, 104 * s, 4 * s),
      snow,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 30 * s, base - 256 * s, 60 * s, 4 * s),
      snow,
    );
    if (headOn) {
      canvas.save();
      canvas.translate(x, base - 254 * s);
      NemrutArt.head(
        canvas,
        tiara ? NemrutHead.antiochos : NemrutHead.zeus,
        150 * s,
        flat: color,
      );
      canvas.restore();
    }
  }

  void _fallenHead(
    Canvas canvas,
    double x,
    double base,
    double s,
    Color color, {
    required bool tiara,
    double tilt = 0,
  }) {
    canvas.save();
    canvas.translate(x, base);
    canvas.rotate(tilt);
    // Sıradaki yerine göre (eğimden) sabit bir tanrı.
    final i = (tilt / 0.12).round() + 2;
    const kinds = [
      NemrutHead.zeus,
      NemrutHead.herakles,
      NemrutHead.antiochos,
      NemrutHead.tyche,
      NemrutHead.apollo,
    ];
    final kind = kinds[i.clamp(0, kinds.length - 1)];
    NemrutArt.head(canvas, kind, 150 * s, flat: color);
    canvas.restore();
  }

  void _statueBird(
    Canvas canvas,
    double x,
    double base,
    double s,
    Color color, {
    required bool eagle,
  }) {
    final p = Paint()..color = color;
    canvas.drawRect(
      Rect.fromLTWH(x - 34 * s, base - 70 * s, 68 * s, 70 * s),
      p,
    );
    if (eagle) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 22 * s, base - 70 * s)
          ..quadraticBezierTo(x - 30 * s, base - 150 * s, x, base - 170 * s)
          ..lineTo(x + 18 * s, base - 160 * s)
          ..lineTo(x + 6 * s, base - 150 * s)
          ..quadraticBezierTo(
            x + 26 * s,
            base - 110 * s,
            x + 22 * s,
            base - 70 * s,
          )
          ..close(),
        p,
      );
    } else {
      // Aslan: oturan, yeleli.
      canvas.drawPath(
        Path()
          ..moveTo(x - 30 * s, base - 70 * s)
          ..lineTo(x - 26 * s, base - 140 * s)
          ..quadraticBezierTo(
            x + 10 * s,
            base - 175 * s,
            x + 30 * s,
            base - 140 * s,
          )
          ..lineTo(x + 30 * s, base - 70 * s)
          ..close(),
        p,
      );
    }
  }

  // ------------------------------------------------------- Peri Bacaları

  /// Kapadokya: alacakaranlıkta peri bacaları, kaya oyma pencerelerde ışık.
  void _fairyChimneys(Canvas canvas, double w, double h, Vector2 cam) {
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), const [
      Color(0xFF241830),
      Color(0xFFB86A5A),
      Color(0xFFF0C090),
    ]);
    _stars(canvas, w, h, 30, cam.x);
    _lightLeak(
      canvas,
      Offset(w * 0.3, h * 0.7),
      h,
      0.25,
      const Color(0xFFFFC890),
    );
    // Üç kat, gün batımında göğe karşı siluet: uzakta puslu kahve, ortada
    // toprak, yakında koyu kahve; şapka taşları daha koyu. Her katın
    // altında alçak tüf sırtları; pencerelerde kandil.
    for (final (depth, tones, scale, base) in [
      (
        0.08,
        const ChimneyTones(
          Color(0xFFB07E6A),
          Color(0xFF94685A),
          Color(0xFF6E4E46),
        ),
        0.6,
        0.62,
      ),
      (
        0.2,
        const ChimneyTones(
          Color(0xFF7E5440),
          Color(0xFF5E3C2E),
          Color(0xFF3A2620),
        ),
        0.85,
        0.7,
      ),
      (
        0.38,
        const ChimneyTones(
          Color(0xFF4E3024),
          Color(0xFF3A2219),
          Color(0xFF221410),
        ),
        1.15,
        0.79,
      ),
    ]) {
      // Tüf tepeleri: tabanları birbirine bağlayan alçak, yuvarlak sırt.
      final hill = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w + 20; x += 20) {
        final u = x + cam.x * depth;
        hill.lineTo(
          x,
          h * base -
              (10 + 8 * math.sin(u * 0.013) + 6 * math.sin(u * 0.031 + 1)) *
                  scale,
        );
      }
      hill
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(hill, Paint()..color = tones.body);
      final lit = const Color(0xFFFFC27A).withValues(alpha: 0.85);
      _repeat(w, cam.x * depth, 320 * scale, (x, rnd) {
        if (rnd.nextDouble() < 0.3 + (0.38 - depth) * 0.6) return;
        drawFairyCluster(
          canvas,
          Offset(x + rnd.nextDouble() * 60 * scale, h * base + 8 * scale),
          (170 + rnd.nextDouble() * 130) * scale,
          tones,
          rnd,
          peaks: 1 + rnd.nextInt(3),
          openings: depth > 0.1 ? 0.3 : 0,
          lit: lit,
        );
      }, salt: (depth * 1000).round());
    }
  }

  // -------------------------------------------------------------- Konya

  /// Konya, 17 Aralık gecesi: karda Yeşil Kubbe, yanında camiler, mumlar.
  void _konya(Canvas canvas, double w, double h, Vector2 cam) {
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), const [
      Color(0xFF04060D),
      Color(0xFF0E1830),
      Color(0xFF2A3552),
    ]);
    _stars(canvas, w, h, 120, cam.x);
    _moon(
      canvas,
      Offset(w * 0.82, h * 0.14),
      h * 0.04,
      const Color(0xFFDCE6FF),
    );
    final dark = Paint()..color = const Color(0xFF0C1020);
    // Ufuk: oynanan zeminin biraz üstü (şehir zeminin arkasında kalmasın).
    final base =
        h * 0.58 +
        (game.level.pixelHeight - game.camera.viewfinder.position.y) * 0.02;
    // Ufkun üstünde şehrin ışığıyla açılan gök: siluet ona karşı seçilir.
    canvas.drawRect(
      Rect.fromLTWH(0, base - h * 0.32, w, h * 0.32 + 4),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, base - h * 0.32),
          Offset(0, base),
          const [Color(0x003A4A70), Color(0xCC3A4A70), Color(0xFF52587A)],
          const [0, 0.7, 1],
        ),
    );
    final moonRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF8A9CC0).withValues(alpha: 0.55);
    final window = Paint()
      ..color = const Color(0xFFFFC27A).withValues(alpha: 0.7);
    // Uzakta şehir: kubbeli camiler, şerefeli minareler, düz damlı evler;
    // kubbelerin üstü ay ışığını yakalar, pencerelerde kandil.
    _repeat(w, cam.x * 0.06, 140, (x, rnd) {
      final hh = 18 + rnd.nextDouble() * 22;
      final ww = 50 + rnd.nextDouble() * 50;
      canvas.drawRect(Rect.fromLTWH(x, base - hh, ww, hh + 20), dark);
      for (var k = 0; k < 3; k++) {
        if (rnd.nextDouble() < 0.5) {
          canvas.drawRect(
            Rect.fromLTWH(x + 6 + k * ww / 3, base - hh + 6, 3, 4),
            window,
          );
        }
      }
    }, salt: 7);
    _repeat(w, cam.x * 0.1, 360, (x, rnd) {
      final r = 40 + rnd.nextDouble() * 30;
      canvas.drawRect(
        Rect.fromLTWH(x - r, base - r * 0.8, r * 2, r * 0.8 + 10),
        dark,
      );
      final dome = Rect.fromCircle(
        center: Offset(x, base - r * 0.8),
        radius: r,
      );
      canvas.drawArc(dome, math.pi, math.pi, true, dark);
      canvas.drawArc(dome, math.pi * 1.1, math.pi * 0.45, false, moonRim);
      // Kubbe alemi.
      canvas.drawLine(
        Offset(x, base - r * 1.8),
        Offset(x, base - r * 1.8 - 12),
        Paint()
          ..color = const Color(0xFFB8A060)
          ..strokeWidth = 1.6,
      );
      // Yan kubbecikler ve pencere sırası.
      for (final side in [-1.0, 1.0]) {
        final sc = Offset(x + side * r * 0.75, base - r * 0.8);
        canvas.drawArc(
          Rect.fromCircle(center: sc, radius: r * 0.32),
          math.pi,
          math.pi,
          true,
          dark,
        );
      }
      for (var k = -2; k <= 2; k++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + k * r * 0.32 - 2.5, base - r * 0.55, 5, 9),
            const Radius.circular(2.5),
          ),
          window,
        );
      }
      for (final side in [-1.0, 1.0]) {
        final mx = x + side * (r + 24);
        final mh = r * 3.2;
        canvas.drawRect(Rect.fromLTWH(mx - 5, base - mh, 10, mh), dark);
        // Şerefe.
        canvas.drawRect(Rect.fromLTWH(mx - 8, base - mh * 0.72, 16, 3), dark);
        canvas.drawPath(
          Path()
            ..moveTo(mx - 6, base - mh)
            ..lineTo(mx, base - mh - r * 0.7)
            ..lineTo(mx + 6, base - mh)
            ..close(),
          dark,
        );
        canvas.drawLine(
          Offset(mx - 5, base - mh),
          Offset(mx - 5, base - mh * 0.3),
          moonRim,
        );
        canvas.drawCircle(Offset(mx, base - mh * 0.72 - 3), 1.6, window);
      }
    }, salt: 2);
    // Şehrin üstünde ince bir ışık pusu.
    canvas.drawRect(
      Rect.fromLTWH(0, base - 60, w, 80),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, base - 60),
          Offset(0, base + 20),
          const [Color(0x00FFC27A), Color(0x22FFC27A)],
        ),
    );
    // Yeşil Kubbe: dilimli, sivri, külah biçimli kubbe ve gövdesi. Uzakta
    // belirir, bölümün sonuna doğru yaklaşır ve büyür.
    final goal = game.level.pixelWidth - 960;
    final gx = w * 0.5 + (goal - cam.x) * 0.15;
    if (gx < -200 || gx > w + 200) {
      _konyaSnow(canvas, w, h, cam);
      return;
    }
    canvas.save();
    final near = (1 - (goal - cam.x).abs() / 6000).clamp(0.0, 1.0);
    final k = 1 + 0.45 * near;
    canvas.translate(gx, base);
    canvas.scale(k);
    canvas.translate(-gx, -base);
    final green = Paint()..color = const Color(0xFF1E5A50);
    final rib = Paint()
      ..color = const Color(0xFF3E8C7A).withValues(alpha: 0.7)
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(gx - 46, base - 150, 92, 150), dark);
    final dome = Path()
      ..moveTo(gx - 42, base - 150)
      ..lineTo(gx - 38, base - 230)
      ..lineTo(gx, base - 330)
      ..lineTo(gx + 38, base - 230)
      ..lineTo(gx + 42, base - 150)
      ..close();
    canvas.drawPath(dome, green);
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(gx + i * 12, base - 150),
        Offset(gx + i * 2, base - 320),
        rib,
      );
    }
    canvas.drawLine(
      Offset(gx, base - 330),
      Offset(gx, base - 352),
      Paint()
        ..color = const Color(0xFFD8B860)
        ..strokeWidth = 2,
    );
    // Kar örtüsü ve pencerelerde mum ışığı.
    final candle = Paint()
      ..color = const Color(0xFFFFD08A).withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      final cx = gx - 24 + i * 24;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 4, base - 110, 8, 16),
          const Radius.circular(4),
        ),
        candle,
      );
    }
    canvas.restore();
    _konyaSnow(canvas, w, h, cam);
  }

  /// Ovanın karlı sırtı.
  void _konyaSnow(Canvas canvas, double w, double h, Vector2 cam) {
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.3,
      base: h * 0.9,
      amp: 12,
      freq: 0.01,
      seed: 41,
      color: const Color(0xFFB8C4D8),
    );
  }

  // ----------------------------------------------------------- Ergenekon

  /// Ergenekon: dört yanı aşılmaz dağlarla çevrili, çayırlı, ırmaklı, meyve
  /// ağaçlı vadi; ortada pas renkli, kızıl damarlı demir dağ. Bölümde
  /// ilerledikçe şafak söker: çıkışta Nevruz güneşi doğar.
  /// Ötüken Ormanı: kutlu ormanlı dağ. Yaprak örtüsünün arasından altın
  /// yeşil ışık süzülür; uzakta ormanla kaplı yuvarlak dağlar (Ötüken yış),
  /// ortada ak gövdeli kayınlar ve koyu ağaçlar, tepede yaprak tavanı.
  void _forest(Canvas canvas, double w, double h, Vector2 cam) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final dy = -cam.y * 0.04;
    _gradient(canvas, rect, const [
      Color(0xFF1E3A2E),
      Color(0xFF6E9466),
      Color(0xFFD2DCA0),
    ]);
    // Yaprakların ardındaki güneş.
    final sun = Offset(w * 0.68 - (cam.x * 0.01) % (w * 0.2), h * 0.22);
    _lightLeak(canvas, sun, h * 0.9, 0.5, const Color(0xFFFFF0B8));
    // Uzakta Ötüken'in ormanlı, yuvarlak dağları.
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.04,
      base: h * 0.5 + dy,
      amp: 60,
      freq: 0.004,
      seed: 31,
      color: const Color(0xFF7FA088),
    );
    _pines(
      canvas,
      w,
      offset: cam.x * 0.06,
      base: h * 0.58 + dy,
      size: 0.45,
      color: const Color(0xFF5E8470),
      salt: 3,
    );
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.1,
      base: h * 0.62 + dy,
      amp: 36,
      freq: 0.007,
      seed: 7,
      color: const Color(0xFF4E7458),
    );
    // Gövdeler: koyu ağaçlar ve aralarında ak kayınlar (Umay'ın ağacı).
    _trunks(
      canvas,
      w,
      h,
      cam.x * 0.22,
      dy,
      scale: 0.75,
      dark: const Color(0xFF2E4A34),
      salt: 4,
    );
    // Işık huzmeleri: yaprak aralarından eğik iner, toz içinde parlar.
    for (var i = 0; i < 6; i++) {
      final span = w + 700;
      final x = ((i * 290 + 120 - cam.x * 0.15) % span + span) % span - 250;
      final pulse = 0.65 + 0.35 * math.sin(_t * 0.5 + i * 1.7);
      final top = 0.0;
      final beam = Path()
        ..moveTo(x, top)
        ..lineTo(x + 34 + i % 3 * 14, top)
        ..lineTo(x + 230, h)
        ..lineTo(x + 120, h)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x + 160, h), [
            const Color(0xFFFFF2B0).withValues(alpha: 0.2 * pulse),
            const Color(0xFFFFF2B0).withValues(alpha: 0),
          ]),
      );
    }
    _trunks(
      canvas,
      w,
      h,
      cam.x * 0.42,
      dy,
      scale: 1.15,
      dark: const Color(0xFF1A3020),
      salt: 9,
    );
    // Yaprak tavanı: tepeden sarkan, dalgalı koyu yeşil örtü.
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.5,
      base: h * 0.1,
      amp: 70,
      freq: 0.012,
      seed: 17,
      color: const Color(0xFF143022),
      fromTop: true,
    );
    final leaf = Paint()..color = const Color(0xFF1C3A28);
    _repeat(w, cam.x * 0.5, 70, (x, rnd) {
      for (var k = 0; k < 3; k++) {
        canvas.drawCircle(
          Offset(
            x + rnd.nextDouble() * 50,
            h * (0.08 + rnd.nextDouble() * 0.1),
          ),
          18 + rnd.nextDouble() * 22,
          leaf,
        );
      }
    }, salt: 21);
  }

  /// Ağaç gövdeleri: koyu ağaçlar ve ak kayınlar (kara benekli ak gövde,
  /// dallarında ak ve al çaputlar).
  void _trunks(
    Canvas canvas,
    double w,
    double h,
    double offset,
    double dy, {
    required double scale,
    required Color dark,
    required int salt,
  }) {
    final darkP = Paint()..color = dark;
    final birch = Paint()
      ..color = Color.lerp(const Color(0xFFE8E6D8), dark, 0.35 - scale * 0.15)!;
    final mark = Paint()
      ..color = Color.lerp(dark, const Color(0xFF000000), 0.3)!;
    _repeat(w, offset, 120 * scale, (x, rnd) {
      if (rnd.nextDouble() < 0.25) return;
      final isBirch = rnd.nextDouble() < 0.4;
      final tw = (isBirch ? 10 : 16 + rnd.nextDouble() * 12) * scale;
      final bx = x + rnd.nextDouble() * 40 * scale;
      final base = h * 0.92 + dy;
      // Gövde hafif eğik, tepeye doğru incelir.
      final lean = (rnd.nextDouble() - 0.5) * 20 * scale;
      final trunk = Path()
        ..moveTo(bx - tw, base)
        ..lineTo(bx - tw * 0.6 + lean, 0)
        ..lineTo(bx + tw * 0.6 + lean, 0)
        ..lineTo(bx + tw, base)
        ..close();
      canvas.drawPath(trunk, isBirch ? birch : darkP);
      if (isBirch) {
        // Kayının kara benekleri.
        for (var k = 0; k < 9; k++) {
          final yy = base - (k + rnd.nextDouble()) * h * 0.1;
          final xx =
              bx + lean * (1 - yy / base) + (rnd.nextDouble() - 0.5) * tw;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(xx, yy),
              width: tw * 0.9,
              height: 2.5 * scale,
            ),
            mark,
          );
        }
        // Dalına bağlı çaputlar.
        final cy = h * (0.28 + rnd.nextDouble() * 0.25);
        final cx = bx + lean * (1 - cy / base);
        for (final (dx, col) in const [
          (-1.0, Color(0xFFF2EEE0)),
          (1.0, Color(0xFFC0302A)),
        ]) {
          final sway = math.sin(_t * 1.6 + x * 0.01 + dx) * 3;
          canvas.drawPath(
            Path()
              ..moveTo(cx + dx * tw * 0.4, cy)
              ..lineTo(cx + dx * tw * 0.4 + 3 * scale + sway, cy + 14 * scale)
              ..lineTo(cx + dx * tw * 0.4 - 2 * scale + sway, cy + 13 * scale)
              ..close(),
            Paint()..color = col.withValues(alpha: 0.85),
          );
        }
      }
    }, salt: salt);
  }

  void _ergenekon(Canvas canvas, double w, double h, Vector2 cam) {
    final lv = game.level;
    final dawn = (cam.x / lv.pixelWidth).clamp(0.0, 1.0);
    final sun = ((dawn - 0.7) / 0.3).clamp(0.0, 1.0);
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [
      Color.lerp(const Color(0xFF3A4A6E), const Color(0xFF5A6A98), dawn)!,
      Color.lerp(const Color(0xFF6A7A88), const Color(0xFFD89A6A), sun)!,
      Color.lerp(const Color(0xFF9AA894), const Color(0xFFF2D49A), sun)!,
    ]);
    if (dawn < 0.4) {
      _stars(canvas, w, h, (30 * (1 - dawn * 2.5)).round(), cam.x);
    }
    if (sun > 0) {
      final c = Offset(w * 0.72, h * (0.62 - 0.22 * sun));
      _lightLeak(canvas, c, h * 1.1, 0.45 * sun, const Color(0xFFFFC890));
      canvas.drawCircle(
        c,
        h * 0.06,
        Paint()..color = const Color(0xFFFFF0D0).withValues(alpha: sun),
      );
    }
    final dy = -cam.y * 0.04;
    // Aşılmaz dağlar: dört yanı çeviren dik, kayalık, karlı sıradağlar.
    _rockyRange(
      canvas,
      w,
      h,
      offset: cam.x * 0.05,
      base: h * 0.66 + dy,
      height: h * 0.42,
      seed: 61,
      body: Color.lerp(const Color(0xFF34405A), const Color(0xFF5A4A52), sun)!,
      snow: Color.lerp(const Color(0xFFB8C4D8), const Color(0xFFF2D8C0), sun)!,
      snowline: 0.3,
    );
    // Demir dağ: pürüzlü, pas renkli kütle; tepesi çıplak demir, içinden
    // kızıl damarlar yanar (eritilecek dağ).
    final ironX = w * 0.55 - cam.x * 0.12 % (w * 2.2);
    final ironBase = h * 0.8 + dy;
    _volcano(
      canvas,
      ironX,
      ironBase,
      h * 0.5,
      w * 0.34,
      19,
      h,
      body: const [Color(0xFF7A4A36), Color(0xFF4A2A20), Color(0xFF1E100C)],
      snowCols: const [Color(0xFF8A8890), Color(0xFF55545C), Color(0xFF2A282E)],
    );
    final pulse = 0.35 + 0.2 * math.sin(_t * 0.7);
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = const Color(0xFFE0603A).withValues(alpha: pulse);
    final veinGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = const Color(0xFFFF8A40).withValues(alpha: pulse * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < 6; i++) {
      final x0 = ironX - w * 0.2 + i * w * 0.08;
      final top = ironBase - h * (0.18 + (i % 3) * 0.06);
      final path = Path()
        ..moveTo(x0, ironBase - 6)
        ..quadraticBezierTo(
          x0 + 16 - i * 4,
          (ironBase + top) / 2,
          (x0 + ironX) / 2 + (i - 2.5) * 6,
          top,
        );
      canvas.drawPath(path, veinGlow);
      canvas.drawPath(path, vein);
    }
    // Vadi: çayırlar, ırmak, meyve ağaçları, otlayan atlar.
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.25,
      base: h * 0.74 + dy,
      amp: 26,
      freq: 0.006,
      seed: 22,
      color: const Color(0xFF34583A),
    );
    final river = Paint()
      ..color = Color.lerp(
        const Color(0xFF6A8AA0),
        const Color(0xFFF2D49A),
        sun,
      )!.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.8 + dy, w, 5), river);
    final tree = Paint()..color = const Color(0xFF243E28);
    _repeat(w, cam.x * 0.32, 150, (x, rnd) {
      if (rnd.nextDouble() < 0.4) return;
      final base = h * 0.79 + dy;
      final th = 24 + rnd.nextDouble() * 18;
      canvas.drawRect(Rect.fromLTWH(x - 2, base - th, 4, th), tree);
      for (var k = 0; k < 4; k++) {
        canvas.drawCircle(
          Offset(
            x + (k - 1.5) * 7 + rnd.nextDouble() * 4,
            base - th - 6 + (k.isEven ? 0 : -8),
          ),
          10 + rnd.nextDouble() * 5,
          tree,
        );
      }
      // Meyveler: birkaç sıcak nokta.
      if (rnd.nextDouble() < 0.6) {
        for (var k = 0; k < 4; k++) {
          canvas.drawCircle(
            Offset(
              x - 10 + rnd.nextDouble() * 20,
              base - th - rnd.nextDouble() * 18,
            ),
            1.6,
            Paint()..color = const Color(0xFFC8784A).withValues(alpha: 0.7),
          );
        }
      }
    }, salt: 5);
    final herd = Paint()..color = const Color(0xFF162418);
    _repeat(w, cam.x * 0.36, 420, (x, rnd) {
      if (rnd.nextDouble() < 0.5) return;
      for (var k = 0; k < 3; k++) {
        canvas.save();
        canvas.translate(x + k * 26, h * 0.82 + dy + (k % 2) * 3);
        canvas.scale((rnd.nextBool() ? 1 : -1) * 0.16, 0.16);
        canvas.drawPath(MythShapes.horse, herd);
        canvas.restore();
      }
    }, salt: 9);
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.45,
      base: h * 0.9 + dy,
      amp: 20,
      freq: 0.01,
      seed: 23,
      color: const Color(0xFF16261A),
    );
  }

  /// Yumuşak bulut kümesi: tepesi ışık alan, altı gölgeli yuvarlak öbekler.
  void _cloudBank(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
    required double base,
    required double size,
    required Color body,
    required Color lit,
    required int seed,
  }) {
    final blur = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(Rect.fromLTRB(0, base, w, h), Paint()..color = body);
    // Önce aydınlık tepeler, sonra aşağı kaydırılmış gövde: ışık yalnız
    // üstte ince bir kenar olarak kalır. Öbekler düzensiz boyda ve aralıkta.
    final puffs = <(Offset, double)>[];
    _repeat(w, offset, size * 0.9, (x, rnd) {
      if (rnd.nextDouble() < 0.25) return;
      final r = size * (0.35 + rnd.nextDouble() * 0.85);
      puffs.add((
        Offset(
          x + (rnd.nextDouble() - 0.5) * size,
          base - r * (0.2 + rnd.nextDouble() * 0.3),
        ),
        r,
      ));
    }, salt: seed);
    for (final (c, r) in puffs) {
      canvas.drawCircle(c, r, blur..color = lit);
    }
    for (final (c, r) in puffs) {
      canvas.drawCircle(
        c.translate(r * 0.1, r * 0.22),
        r * 0.98,
        blur..color = body,
      );
    }
  }

  // ------------------------------------------------------ Göğün katları

  /// Göğün katları: önce ay katı (soğuk, yumuşak, büyük ay: Ay Ata), sonra
  /// gün katı (sıcak, yakıcı: Gün Ana), Ülgen'in kapısında kırık güneşin
  /// parçası; en sonda Erlik'in fırtınası.
  /// Göğün katlarının renkleri (LevelDef.skies türleri sırasıyla): üst,
  /// orta, alt, bulut gövdesi, bulut ışığı.
  static const _skyTones = [
    [0xFF101A3A, 0xFF2A3A6A, 0xFF4A5A8A, 0xFF2A3460, 0xFFB8C8F0],
    [0xFF04071A, 0xFF0E1534, 0xFF1C264C, 0xFF141C38, 0xFF5A6A9A],
    [0xFF3A5A8A, 0xFF9AB4D0, 0xFFD0DCE8, 0xFFB8C8D8, 0xFFF0F4FA],
    [0xFF6AA0E0, 0xFFE8C890, 0xFFF0D8A8, 0xFFE8D8C8, 0xFFFFF8EC],
    [0xFF6AA0E0, 0xFFE8C890, 0xFFF0D8A8, 0xFFE8D8C8, 0xFFFFF8EC],
    [0xFF1A1028, 0xFF3A2440, 0xFF4A3048, 0xFF2A1C34, 0xFF6A4A80],
  ];

  /// Kameranın sütununa göre katların ağırlıkları (iki komşu kat arasında
  /// on kare boyunca geçiş).
  List<double> _skyWeights(List<(int, int)> skies, double col) {
    final out = List.filled(_skyTones.length, 0.0);
    var i = 0;
    while (i + 1 < skies.length && col >= skies[i + 1].$1) {
      i++;
    }
    final (c0, k0) = skies[i];
    if (i + 1 < skies.length) {
      final (c1, k1) = skies[i + 1];
      final k = ((col - (c1 - 10)) / 10).clamp(0.0, 1.0);
      out[k0] += 1 - k;
      out[k1] += k;
    } else {
      out[k0] = 1;
    }
    if (col < c0) out[k0] = 1;
    return out;
  }

  void _layeredHeavens(
    Canvas canvas,
    double w,
    double h,
    Vector2 cam,
    List<(int, int)> skies,
  ) {
    // Kameranın sol kenarı + yarım ekran (yaklaşık 18 kare).
    final wt = _skyWeights(skies, cam.x / 32 + 18);
    Color mix(int idx) {
      var r = 0.0, g = 0.0, b = 0.0;
      for (var k = 0; k < wt.length; k++) {
        final c = Color(_skyTones[k][idx]);
        r += c.r * wt[k];
        g += c.g * wt[k];
        b += c.b * wt[k];
      }
      return Color.from(alpha: 1, red: r, green: g, blue: b);
    }

    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [mix(0), mix(1), mix(2)]);
    final night = wt[0] + wt[1];
    if (night > 0) {
      _stars(canvas, w, h, (70 * wt[0] + 180 * wt[1]).round(), cam.x);
    }
    if (wt[1] > 0) {
      // Kuş Yolu: göğü çaprazlama kesen soluk ışık kuşağı.
      final band = Path()
        ..moveTo(-w * 0.1, h * 0.75)
        ..quadraticBezierTo(w * 0.45, h * 0.2, w * 1.1, -h * 0.05)
        ..lineTo(w * 1.1, h * 0.12)
        ..quadraticBezierTo(w * 0.5, h * 0.42, -w * 0.1, h * 0.95)
        ..close();
      canvas.drawPath(
        band,
        Paint()
          ..color = const Color(0xFFC8D4FF).withValues(alpha: 0.08 * wt[1])
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
    if (wt[0] > 0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Color.fromRGBO(0, 0, 0, wt[0]),
      );
      _moon(
        canvas,
        Offset(w * 0.3, h * 0.26),
        h * 0.12,
        const Color(0xFFCFE0FF),
      );
      canvas.restore();
    }
    final day = wt[3] + wt[4];
    if (day > 0) {
      final c = Offset(w * 0.68, h * 0.24);
      _lightLeak(canvas, c, h * 1.2, 0.5 * day, const Color(0xFFFFE8B0));
      if (wt[4] > wt[3]) {
        _brokenSun(canvas, c, h * 0.11);
      } else {
        canvas.drawCircle(
          c,
          h * 0.1,
          Paint()..color = const Color(0xFFFFF6DA).withValues(alpha: day),
        );
      }
    }
    final windy = wt[2];
    for (var k = 0; k < 3; k++) {
      _cloudBank(
        canvas,
        w,
        h,
        offset: cam.x * (0.08 + k * 0.1) + _t * (3 + k * 3) * (1 + 6 * windy),
        base: h * (0.58 + k * 0.14),
        size: 70.0 - k * 10,
        body: mix(3).withValues(alpha: 0.75 + k * 0.08),
        lit: mix(4).withValues(alpha: 0.8),
        seed: 31 + k,
      );
    }
    // Yel katında göğü çizen uzun rüzgâr çizgileri.
    if (windy > 0) {
      final streak = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.18 * windy)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 24; i++) {
        final y = h * (0.1 + (i * 0.037) % 0.7);
        final len = 60.0 + (i % 5) * 30;
        final x = w - ((_t * (300 + i * 17) + i * 97) % (w + len * 2)) + len;
        canvas.drawLine(Offset(x, y), Offset(x + len, y), streak);
      }
    }
    final storm = wt[5];
    if (storm > 0 && (_t * 0.7) % 1 < 0.04) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFE8E0FF).withValues(alpha: 0.25 * storm),
      );
    }
  }

  void _heavens(Canvas canvas, double w, double h, Vector2 cam) {
    final lv = game.level;
    if (lv.def.skies.isNotEmpty) {
      _layeredHeavens(canvas, w, h, cam, lv.def.skies);
      return;
    }
    final u = (cam.x / lv.pixelWidth).clamp(0.0, 1.0);
    final day = ((u - 0.3) / 0.15).clamp(0.0, 1.0);
    final storm = ((u - 0.74) / 0.08).clamp(0.0, 1.0);
    final top = Color.lerp(
      Color.lerp(const Color(0xFF101A3A), const Color(0xFF6AA0E0), day)!,
      const Color(0xFF1A1028),
      storm,
    )!;
    final mid = Color.lerp(
      Color.lerp(const Color(0xFF2A3A6A), const Color(0xFFE8C890), day)!,
      const Color(0xFF3A2440),
      storm,
    )!;
    final low = Color.lerp(
      Color.lerp(const Color(0xFF4A5A8A), const Color(0xFFF0D8A8), day)!,
      const Color(0xFF4A3048),
      storm,
    )!;
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [top, mid, low]);
    if (day < 1) {
      _stars(canvas, w, h, (70 * (1 - day)).round(), cam.x);
      _moon(
        canvas,
        Offset(w * 0.3, h * 0.26),
        h * 0.12,
        const Color(0xFFCFE0FF),
      );
    }
    if (day > 0 && storm < 1) {
      final a = day * (1 - storm);
      final c = Offset(w * 0.68, h * 0.24);
      _lightLeak(canvas, c, h * 1.2, 0.5 * a, const Color(0xFFFFE8B0));
      if (u > 0.58 && u < 0.76) {
        _brokenSun(canvas, c, h * 0.11);
      } else {
        canvas.drawCircle(
          c,
          h * 0.1,
          Paint()..color = const Color(0xFFFFF6DA).withValues(alpha: a),
        );
      }
    }
    // Bulut katları: üst üste, ağır ağır kayan, tepeleri ışığı yakalayan
    // yumuşak kümeler.
    for (var k = 0; k < 3; k++) {
      final body = Color.lerp(
        Color.lerp(const Color(0xFF2A3460), const Color(0xFFE8D8C8), day)!,
        const Color(0xFF2A1C34),
        storm,
      )!;
      final lit = Color.lerp(
        Color.lerp(const Color(0xFFB8C8F0), const Color(0xFFFFF8EC), day)!,
        const Color(0xFF6A4A80),
        storm,
      )!;
      _cloudBank(
        canvas,
        w,
        h,
        offset: cam.x * (0.08 + k * 0.1) + _t * (3 + k * 3),
        base: h * (0.58 + k * 0.14),
        size: 70.0 - k * 10,
        body: body.withValues(alpha: 0.75 + k * 0.08),
        lit: lit.withValues(alpha: 0.8),
        seed: 31 + k,
      );
    }
    // Fırtınada şimşek.
    if (storm > 0 && (_t * 0.7) % 1 < 0.04) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFE8E0FF).withValues(alpha: 0.25 * storm),
      );
    }
  }
}
