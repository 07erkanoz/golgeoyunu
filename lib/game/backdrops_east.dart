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
    // Uzak ve yakın zümrüt sıradağlar: kırık, yontulmuş yüzler.
    for (final (depth, color, facet, base) in [
      (0.08, const Color(0xFF1C5A4C), const Color(0xFF3E9C80), 0.55),
      (0.2, const Color(0xFF0F3A33), const Color(0xFF2A7A64), 0.7),
    ]) {
      final paint = Paint()..color = color;
      final light = Paint()..color = facet.withValues(alpha: 0.5);
      _repeat(w, cam.x * depth, 260, (x, rnd) {
        final peak = h * (base - 0.25 - rnd.nextDouble() * 0.15) + rise;
        final half = 90 + rnd.nextDouble() * 70;
        final px = x + rnd.nextDouble() * 60;
        final shard = Path()
          ..moveTo(px - half, h)
          ..lineTo(px - half * 0.3, peak + 40)
          ..lineTo(px, peak)
          ..lineTo(px + half * 0.25, peak + 60)
          ..lineTo(px + half, h)
          ..close();
        canvas.drawPath(shard, paint);
        canvas.drawPath(
          Path()
            ..moveTo(px, peak)
            ..lineTo(px + half * 0.25, peak + 60)
            ..lineTo(px + half * 0.05, peak + 140)
            ..close(),
          light,
        );
      }, salt: (depth * 100).round());
    }
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
  /// 2 çığ: tipiyle kapanan gök.
  void _snowPeaks(
    Canvas canvas,
    double w,
    double h,
    Vector2 cam,
    double height,
    int variant,
  ) {
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), [
      variant == 2 ? const Color(0xFF1A2230) : const Color(0xFF070C18),
      lerpColor(0xFF1E2A44, 0xFF2C3E5C, height),
      variant == 2 ? const Color(0xFF8A98A8) : const Color(0xFF5E7290),
    ]);
    if (variant != 2) _stars(canvas, w, h, 90, cam.x);
    _moon(canvas, Offset(w * 0.2, h * 0.16), h * 0.05, const Color(0xFFDCE6FF));
    final snowPaint = Paint()..color = const Color(0xFFE6EEF8);
    if (variant == 0) {
      // Büyük ve Küçük Ağrı: uzakta iki karlı koni.
      final dx = -cam.x * 0.03;
      final base = h * 0.78;
      void cone(double cx, double top, double half, double capK) {
        final body = Path()
          ..moveTo(cx - half, base)
          ..quadraticBezierTo(
            cx - half * 0.35,
            top + (base - top) * 0.2,
            cx,
            top,
          )
          ..quadraticBezierTo(
            cx + half * 0.35,
            top + (base - top) * 0.2,
            cx + half,
            base,
          )
          ..close();
        canvas.drawPath(body, Paint()..color = const Color(0xFF2A3A55));
        canvas.save();
        canvas.clipPath(body);
        final capY = top + (base - top) * capK;
        final cap = Path()..moveTo(cx - half, capY);
        for (var x = -half; x <= half; x += half / 8) {
          cap.lineTo(
            cx + x,
            capY + math.sin(x * 0.08) * 10 + (x.abs() / half) * 18,
          );
        }
        cap
          ..lineTo(cx + half, top - 10)
          ..lineTo(cx - half, top - 10)
          ..close();
        canvas.drawPath(cap, snowPaint);
        canvas.restore();
      }

      cone(w * 0.62 + dx, h * 0.2, w * 0.42, 0.42);
      cone(w * 0.95 + dx, h * 0.45, w * 0.18, 0.35);
    }
    final rise = (game.level.pixelHeight - cam.y) * 0.06;
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.12,
      base: h * 0.72 + rise,
      amp: 50,
      freq: 0.007,
      seed: 21,
      color: const Color(0xFF3A4A66),
    );
    _pines(
      canvas,
      w,
      offset: cam.x * 0.25,
      base: h * 0.8 + rise * 1.3,
      size: 0.7,
      color: const Color(0xFF16202E),
      snow: const Color(0xFF8C9CB4),
      salt: 3,
    );
    if (variant == 1) {
      // Sisin içinde Ejder: zirvenin çevresine dolanmış, belli belirsiz.
      final dragon = Paint()
        ..color = const Color(0xFFDCE6F2).withValues(alpha: 0.06);
      final ox = w * 0.65 - cam.x * 0.03;
      for (var i = 0; i < 40; i++) {
        final k = i / 40;
        final x =
            ox +
            math.cos(k * math.pi * 2.2 + _t * 0.05) * w * 0.18 * (1 - k * 0.4);
        final y =
            h * 0.42 +
            math.sin(k * math.pi * 3 + _t * 0.07) * h * 0.08 -
            k * h * 0.12;
        canvas.drawCircle(Offset(x, y), (1 - k) * 22 + 4, dragon);
      }
    }
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
      base: h * 0.9 + rise * 1.6,
      amp: 30,
      freq: 0.012,
      seed: 22,
      color: const Color(0xFFB8C6D8),
    );
    if (variant == 2) {
      // Tipi: gökyüzü beyaza boğulur.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFDDE6F0)
              .withValues(alpha: 0.12 + 0.06 * math.sin(_t * 0.7)),
      );
    }
  }

  // --------------------------------------------------------- Nuh'un Gemisi

  /// Taşlaşmış geminin içi: dev kaburgalar, asılı kandiller ve duvarda
  /// ikişer ikişer yürüyen hayvan gölgeleri.
  void _arkHull(Canvas canvas, double w, double h, Vector2 cam) {
    _gradient(canvas, Rect.fromLTWH(0, 0, w, h), const [
      Color(0xFF0C0705),
      Color(0xFF24150C),
      Color(0xFF3A2414),
    ]);
    // Tahta aralıklarından sızan soluk gün ışığı.
    for (var i = 0; i < 5; i++) {
      final x =
          ((i * 337 + 90 - cam.x * 0.15) % (w + 300) + w + 300) % (w + 300) -
          150;
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + 8, 0)
          ..lineTo(x + 70, h)
          ..lineTo(x + 40, h)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x + 50, h), [
            const Color(0xFFE8D0A0).withValues(alpha: 0.12),
            const Color(0xFFE8D0A0).withValues(alpha: 0),
          ]),
      );
    }
    // Hayvan gölgeleri: perde gibi gövdenin iç duvarına düşer.
    final shade = Paint()
      ..color = const Color(0xFF120A06).withValues(alpha: 0.6);
    final walk = _t * 14;
    _repeat(w, cam.x * 0.3 - walk, 520, (x, rnd) {
      final kind = rnd.nextInt(3);
      for (final dx in [0.0, 70.0]) {
        canvas.save();
        canvas.translate(x + dx, h * 0.72);
        final bob = math.sin(_t * 2 + dx) * 2;
        canvas.translate(0, bob);
        switch (kind) {
          case 0: // fil
            canvas.drawOval(const Rect.fromLTWH(-34, -50, 68, 40), shade);
            canvas.drawCircle(const Offset(34, -40), 14, shade);
            canvas.drawRect(const Rect.fromLTWH(42, -36, 6, 34), shade);
            for (final lx in [-26.0, -12.0, 10.0, 22.0]) {
              canvas.drawRect(Rect.fromLTWH(lx, -14, 9, 16), shade);
            }
          case 1: // zürafa
            canvas.drawOval(const Rect.fromLTWH(-22, -50, 44, 24), shade);
            canvas.drawPath(
              Path()
                ..moveTo(14, -46)
                ..lineTo(30, -104)
                ..lineTo(38, -102)
                ..lineTo(24, -42)
                ..close(),
              shade,
            );
            canvas.drawOval(const Rect.fromLTWH(28, -112, 18, 9), shade);
            for (final lx in [-16.0, -6.0, 8.0, 16.0]) {
              canvas.drawRect(Rect.fromLTWH(lx, -30, 4, 30), shade);
            }
          default: // aslan
            canvas.drawOval(const Rect.fromLTWH(-26, -34, 52, 22), shade);
            canvas.drawCircle(const Offset(28, -30), 13, shade);
            canvas.drawPath(
              Path()
                ..moveTo(-26, -26)
                ..quadraticBezierTo(-44, -30, -46, -14)
                ..lineTo(-42, -14)
                ..quadraticBezierTo(-40, -26, -26, -22)
                ..close(),
              shade,
            );
            for (final lx in [-20.0, -8.0, 10.0, 18.0]) {
              canvas.drawRect(Rect.fromLTWH(lx, -16, 5, 16), shade);
            }
        }
        canvas.restore();
      }
    }, salt: 9);
    // Kaburgalar: iki derinlikte kıvrık kirişler.
    for (final (depth, color, thick, spacing) in [
      (0.35, const Color(0xFF2A190E), 16.0, 210.0),
      (0.6, const Color(0xFF170D07), 26.0, 300.0),
    ]) {
      final rib = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thick;
      _repeat(w, cam.x * depth, spacing, (x, rnd) {
        canvas.drawPath(
          Path()
            ..moveTo(x - spacing * 0.15, h + 20)
            ..quadraticBezierTo(
              x - spacing * 0.2,
              h * 0.1,
              x + spacing * 0.35,
              -20,
            ),
          rib,
        );
      });
    }
    // Asılı kandiller.
    _repeat(w, cam.x * 0.6, 380, (x, rnd) {
      final y = h * (0.25 + rnd.nextDouble() * 0.1);
      final sway = math.sin(_t * 0.8 + x * 0.01) * 4;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + sway, y),
        Paint()
          ..color = const Color(0xFF170D07)
          ..strokeWidth = 1.5,
      );
      _lightLeak(
        canvas,
        Offset(x + sway, y + 6),
        60,
        0.25,
        const Color(0xFFFFC27A),
      );
      canvas.drawCircle(
        Offset(x + sway, y + 6),
        3,
        Paint()..color = const Color(0xFFFFE2A8),
      );
    }, salt: 4);
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
        final headOn = i == 2 && variant == 1;
        _seatedGod(canvas, gx, base, s, stone, headOn: headOn, tiara: i.isEven);
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
    // Taht, gövde, dizler.
    canvas.drawRect(
      Rect.fromLTWH(x - 60 * s, base - 120 * s, 120 * s, 120 * s),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x - 46 * s, base - 120 * s)
        ..lineTo(x - 40 * s, base - 250 * s)
        ..quadraticBezierTo(x, base - 270 * s, x + 40 * s, base - 250 * s)
        ..lineTo(x + 46 * s, base - 120 * s)
        ..close(),
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 54 * s, base - 140 * s, 108 * s, 34 * s),
      p,
    );
    // Karla örtülü omuzlar ve dizler.
    final snow = Paint()
      ..color = const Color(0xFFDCE2EE).withValues(alpha: 0.85);
    canvas.drawRect(
      Rect.fromLTWH(x - 54 * s, base - 142 * s, 108 * s, 5 * s),
      snow,
    );
    canvas.drawOval(
      Rect.fromLTWH(x - 42 * s, base - 262 * s, 84 * s, 10 * s),
      snow,
    );
    if (headOn) {
      canvas.save();
      canvas.translate(x, base - 262 * s);
      _headShape(canvas, s, p, tiara: tiara);
      canvas.restore();
    } else {
      // Kırık boyun.
      canvas.drawRect(
        Rect.fromLTWH(x - 14 * s, base - 276 * s, 28 * s, 16 * s),
        p,
      );
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
    _headShape(canvas, s, Paint()..color = color, tiara: tiara);
    canvas.restore();
  }

  /// Dev baş: kıvırcık sakal, iri yüz, sivri Pers külahı ya da taç.
  void _headShape(Canvas canvas, double s, Paint p, {required bool tiara}) {
    canvas.drawOval(Rect.fromLTWH(-34 * s, -92 * s, 68 * s, 84 * s), p);
    // Sakal.
    canvas.drawPath(
      Path()
        ..moveTo(-28 * s, -40 * s)
        ..quadraticBezierTo(-24 * s, 4 * s, 0, 6 * s)
        ..quadraticBezierTo(24 * s, 4 * s, 28 * s, -40 * s)
        ..close(),
      p,
    );
    if (tiara) {
      // Sivri, öne kıvrık külah.
      canvas.drawPath(
        Path()
          ..moveTo(-36 * s, -78 * s)
          ..quadraticBezierTo(-30 * s, -150 * s, 6 * s, -176 * s)
          ..quadraticBezierTo(18 * s, -170 * s, 14 * s, -156 * s)
          ..quadraticBezierTo(30 * s, -120 * s, 36 * s, -78 * s)
          ..close(),
        p,
      );
    } else {
      // Kısa taç.
      canvas.drawRect(Rect.fromLTWH(-30 * s, -108 * s, 60 * s, 24 * s), p);
    }
    // Karlı tepe ve sabah ışığında bir yanak.
    canvas.drawOval(
      Rect.fromLTWH(-20 * s, (tiara ? -168 : -112) * s, 30 * s, 8 * s),
      Paint()..color = const Color(0xFFDCE2EE).withValues(alpha: 0.8),
    );
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
    for (final (depth, color, scale, base) in [
      (0.08, const Color(0xFF8A5A50), 0.6, 0.78),
      (0.2, const Color(0xFF5A3A38), 0.85, 0.86),
      (0.38, const Color(0xFF2E1E20), 1.15, 0.96),
    ]) {
      final p = Paint()..color = color;
      final cap = Paint()
        ..color = Color.lerp(color, const Color(0xFF000000), 0.35)!;
      final window = Paint()
        ..color = const Color(0xFFFFC27A).withValues(alpha: 0.75);
      _repeat(w, cam.x * depth, 150 * scale, (x, rnd) {
        if (rnd.nextDouble() < 0.2) return;
        final ht = (120 + rnd.nextDouble() * 160) * scale;
        final half = (16 + rnd.nextDouble() * 14) * scale;
        final b = h * base;
        final bx = x + rnd.nextDouble() * 40 * scale;
        canvas.drawPath(
          Path()
            ..moveTo(bx - half * 2.2, b)
            ..quadraticBezierTo(
              bx - half * 1.1,
              b - ht * 0.4,
              bx - half * 0.7,
              b - ht,
            )
            ..lineTo(bx + half * 0.7, b - ht)
            ..quadraticBezierTo(
              bx + half * 1.1,
              b - ht * 0.4,
              bx + half * 2.2,
              b,
            )
            ..close(),
          p,
        );
        // Bazalt şapka.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(bx, b - ht - 4 * scale),
            width: half * 3,
            height: 22 * scale,
          ),
          cap,
        );
        if (depth > 0.1 && rnd.nextDouble() < 0.6) {
          final wy = b - ht * (0.3 + rnd.nextDouble() * 0.4);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(bx, wy),
                width: 5 * scale,
                height: 8 * scale,
              ),
              Radius.circular(2.5 * scale),
            ),
            window,
          );
        }
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
    final dark = Paint()..color = const Color(0xFF0A0E18);
    final base = h * 0.82;
    // Uzaktaki kubbeler ve minareler.
    _repeat(w, cam.x * 0.1, 360, (x, rnd) {
      final r = 40 + rnd.nextDouble() * 30;
      canvas.drawRect(
        Rect.fromLTWH(x - r, base - r * 0.8, r * 2, r * 0.8 + 10),
        dark,
      );
      canvas.drawCircle(Offset(x, base - r * 0.8), r, dark);
      for (final side in [-1.0, 1.0]) {
        final mx = x + side * (r + 24);
        canvas.drawRect(
          Rect.fromLTWH(mx - 5, base - r * 3.2, 10, r * 3.2),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(mx - 6, base - r * 3.2)
            ..lineTo(mx, base - r * 3.8)
            ..lineTo(mx + 6, base - r * 3.2)
            ..close(),
          dark,
        );
      }
    }, salt: 2);
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
}
