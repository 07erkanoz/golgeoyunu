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

  // ----------------------------------------------------------- Ergenekon

  /// Ergenekon: dört yanı aşılmaz dağlarla çevrili, çayırlı, ırmaklı, meyve
  /// ağaçlı vadi; ortada pas renkli, kızıl damarlı demir dağ. Bölümde
  /// ilerledikçe şafak söker: çıkışta Nevruz güneşi doğar.
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
    // Aşılmaz dağlar: dik, yüksek, mavi-gri.
    _ridge(
      canvas,
      w,
      h,
      offset: cam.x * 0.08,
      base: h * 0.42 + dy,
      amp: h * 0.3,
      freq: 0.009,
      seed: 21,
      color: Color.lerp(const Color(0xFF3E4A5E), const Color(0xFF6A5A5A), sun)!,
      bumpy: true,
    );
    // Demir dağ: pas renkli gövde, içinde kızıl damarlar.
    final ironX = w * 0.55 - cam.x * 0.16 % (w * 2.2);
    final iron = Path()
      ..moveTo(ironX - w * 0.35, h * 0.78)
      ..lineTo(ironX - w * 0.12, h * 0.3 + dy)
      ..lineTo(ironX, h * 0.24 + dy)
      ..lineTo(ironX + w * 0.1, h * 0.32 + dy)
      ..lineTo(ironX + w * 0.38, h * 0.78)
      ..close();
    canvas.drawPath(iron, Paint()..color = const Color(0xFF3A2A26));
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE0603A)
          .withValues(alpha: 0.35 + 0.15 * math.sin(_t * 0.7));
    for (var i = 0; i < 5; i++) {
      final x0 = ironX - w * 0.2 + i * w * 0.09;
      canvas.drawPath(
        Path()
          ..moveTo(x0, h * 0.75)
          ..quadraticBezierTo(x0 + 18, h * 0.55, x0 - 6 + i * 4, h * 0.36 + dy),
        vein,
      );
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

  // ------------------------------------------------------ Göğün katları

  /// Göğün katları: önce ay katı (soğuk, yumuşak, büyük ay: Ay Ata), sonra
  /// gün katı (sıcak, yakıcı: Gün Ana), Ülgen'in kapısında kırık güneşin
  /// parçası; en sonda Erlik'in fırtınası.
  void _heavens(Canvas canvas, double w, double h, Vector2 cam) {
    final lv = game.level;
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
    // Bulut katları: üst üste, ağır ağır kayan.
    for (var k = 0; k < 3; k++) {
      final c = Color.lerp(
        Color.lerp(const Color(0xFF34406E), const Color(0xFFFFF4E4), day)!,
        const Color(0xFF2A1C34),
        storm,
      )!.withValues(alpha: 0.5 + k * 0.15);
      _ridge(
        canvas,
        w,
        h,
        offset: cam.x * (0.08 + k * 0.1) + _t * (3 + k * 3),
        base: h * (0.55 + k * 0.14),
        amp: 30 - k * 4,
        freq: 0.012 + k * 0.002,
        seed: 31 + k,
        color: c,
        bumpy: true,
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
