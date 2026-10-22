part of 'atmosphere.dart';

/// Kayak yamaçlarının göğü: pistte ilerledikçe gün döner (SkiLight). Katman
/// katman karlı sırtlar, akan bulutlar, güneş ya da ay, gece yıldızlar ve
/// Samanyolu; Palandöken'de uzakta Erzurum'un ışıkları.
extension _SkiBackdrop on Backdrop {
  void _skiSky(Canvas canvas, double w, double h, Vector2 cam) {
    final lt = game.skiLight;
    final progress = game.skiProgress;
    final storm = game.level.def.variant == 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          [lt.skyTop, lt.skyMid, lt.skyLow],
          const [0, 0.55, 1],
        ),
    );
    // Gece: yıldızlar ve Samanyolu.
    if (lt.night > 0.05) {
      final p = Paint();
      for (var i = 0; i < 140; i++) {
        final rnd = math.Random(i * 7349 + 11);
        final x = ((rnd.nextDouble() * w * 1.5 - cam.x * 0.01) % w + w) % w;
        final y = rnd.nextDouble() * h * 0.65;
        final tw = 0.5 + 0.5 * math.sin(_t * (0.8 + rnd.nextDouble()) + i);
        p.color = const Color(0xFFEFF4FF)
            .withValues(alpha: lt.night * (0.15 + 0.6 * tw * rnd.nextDouble()));
        canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 1.1, p);
      }
      canvas.save();
      canvas.translate(w * 0.55 - cam.x * 0.005, h * 0.3);
      canvas.rotate(-0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * 1.4, height: h * 0.18),
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, w * 0.7, [
            const Color(0xFFCFD8FF).withValues(alpha: 0.045 * lt.night),
            const Color(0x00CFD8FF),
          ]),
      );
      canvas.restore();
    }
    // Güneş ve ay: yumuşak, geniş bir hale içinde.
    final horizon = h * 0.8;
    final sun = LightPos.of(SkiLight.sunAt(progress), w, horizon);
    if (sun.dy < horizon + 40 && !storm) {
      _halo(canvas, sun, h * 0.75, lt.sun, 0.45 * (1 - lt.night * 0.5));
      canvas.drawCircle(
        sun,
        h * 0.055,
        Paint()..color = Color.lerp(lt.sun, const Color(0xFFFFFFFF), 0.55)!,
      );
    }
    if (lt.night > 0.2) {
      final moon = LightPos.of(SkiLight.moonAt(progress), w, horizon);
      _halo(canvas, moon, h * 0.45, const Color(0xFFE8ECFF), 0.22 * lt.night);
      canvas.drawCircle(
        moon,
        h * 0.04,
        Paint()..color = const Color(0xFFF6F3EA).withValues(alpha: lt.night),
      );
    }
    // Uzun, yumuşak bulutlar (uzak katmanların ardında).
    _clouds(canvas, w, h, cam, lt, storm, far: true);
    // Kat kat sıradağlar: uzaktaki göğe karışır, aralarında sis.
    final rise = (game.level.pixelHeight - cam.y) * 0.02;
    final layers = [
      // (parallax, taban, yükseklik, tohum, göğe karışma, sivrilik, orman)
      (0.02, 0.48, 100.0, 41, 0.80, 1.0, false),
      (0.05, 0.58, 85.0, 42, 0.62, 0.85, false),
      (0.10, 0.69, 40.0, 43, 0.44, 0.0, true),
      (0.18, 0.80, 30.0, 44, 0.26, 0.0, true),
    ];
    for (final (depth, base, amp, seed, mix, sharp, forest) in layers) {
      final body = Color.lerp(
        Color.lerp(lt.ridge, lt.deep, 0.55)!,
        lt.skyLow,
        mix,
      )!;
      final by = h * base + rise * depth * 10;
      _range(
        canvas,
        w,
        h,
        offset: cam.x * depth,
        base: by,
        amp: amp,
        seed: seed,
        sharp: sharp,
        body: body,
        cap: sharp > 0.5 ? Color.lerp(lt.snowLit, lt.skyLow, mix * 0.8)! : null,
        forest: forest,
      );
      // Katmanın eteğinde sis: bir sonraki katmanı ayırır.
      canvas.drawRect(
        Rect.fromLTRB(0, by - amp * 0.6, w, by + h * 0.12),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, by - amp * 0.6),
            Offset(0, by + h * 0.12),
            [
              lt.skyLow.withValues(alpha: 0),
              lt.skyLow.withValues(alpha: 0.55 * (1 - mix * 0.4)),
              lt.skyLow.withValues(alpha: 0),
            ],
            const [0, 0.55, 1],
          ),
      );
    }
    // Erzurum'un ışıkları (gece, uzakta).
    if (!storm && lt.night > 0.1) {
      final city = Paint()
        ..color = const Color(0xFFFFC27A).withValues(alpha: 0.6 * lt.night);
      for (var i = 0; i < 30; i++) {
        final rnd = math.Random(i * 31 + 5);
        final x = ((rnd.nextDouble() * w * 1.4 - cam.x * 0.06) % w + w) % w;
        canvas.drawCircle(Offset(x, h * 0.8 + rnd.nextDouble() * 6), 1.1, city);
      }
    }
    _clouds(canvas, w, h, cam, lt, storm, far: false);
    if (storm) {
      // Tipi: gök soluk beyaza boğulur, nefes alır gibi.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFDDE6F0)
              .withValues(alpha: 0.1 + 0.06 * math.sin(_t * 0.7)),
      );
    }
  }

  /// Işık kaynağının çevresinde yumuşak, geniş hale.
  void _halo(Canvas canvas, Offset at, double r, Color c, double a) {
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          at,
          r,
          [
            c.withValues(alpha: a),
            c.withValues(alpha: a * 0.35),
            c.withValues(alpha: 0),
          ],
          const [0, 0.25, 1],
        ),
    );
  }

  /// Uzun, bulanık kenarlı bulutlar; güneşin rengini alır, rüzgârla akar.
  void _clouds(
    Canvas canvas,
    double w,
    double h,
    Vector2 cam,
    SkiLight lt,
    bool storm, {
    required bool far,
  }) {
    final n = far ? 4 : 2;
    for (var i = 0; i < n; i++) {
      final rnd = math.Random(i * 977 + (far ? 3 : 91));
      final span = w + 900;
      final speed = far ? 4 + rnd.nextDouble() * 5 : 10 + rnd.nextDouble() * 8;
      final par = far ? 0.01 : 0.04;
      final x =
          ((rnd.nextDouble() * span - _t * speed - cam.x * par) % span + span) %
              span -
          450;
      final y =
          h *
          (far
              ? 0.18 + rnd.nextDouble() * 0.22
              : 0.08 + rnd.nextDouble() * 0.12);
      final cw = (far ? 380 : 520) + rnd.nextDouble() * 300;
      final ch = (far ? 26 : 34) + rnd.nextDouble() * 18;
      final a = (storm ? 0.55 : 0.3) * (1 - lt.night * 0.55);
      final lit = Color.lerp(lt.sun, const Color(0xFFFFFFFF), 0.45)!;
      final paint = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ch * 0.45);
      // Gövde ve ışık alan üst kenar.
      paint.color = Color.lerp(lt.skyMid, lt.skyLow, 0.4)!.withValues(alpha: a);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: cw, height: ch),
        paint,
      );
      paint.color = lit.withValues(alpha: a * 0.8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - cw * 0.08, y - ch * 0.25),
          width: cw * 0.7,
          height: ch * 0.5,
        ),
        paint,
      );
    }
  }

  /// Sıradağ katmanı: [sharp] 1 sivri kayalık tepeler (karlı), 0 yumuşak
  /// tepeler; [forest] tepelerin üstünde çam ormanı silueti.
  void _range(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
    required double base,
    required double amp,
    required int seed,
    required double sharp,
    required Color body,
    Color? cap,
    bool forest = false,
  }) {
    // Üçgen dalga: sivri tepe, V vadi (yuvarlak, pul pul etek olmasın).
    double tri(double v) {
      final f = v - v.floorToDouble();
      return 1 - (f - 0.5).abs() * 2;
    }

    double ridged(double x) {
      final spiky =
          0.58 * math.pow(tri(x * 0.0019 + seed * 0.37), 1.4) +
          0.28 * tri(x * 0.0051 + seed * 0.11) +
          0.14 * tri(x * 0.017 + seed * 0.7);
      final soft =
          0.5 +
          0.3 * math.sin(x * 0.0031 + seed) +
          0.2 * math.sin(x * 0.0083 + seed * 2);
      return spiky * sharp + soft * (1 - sharp);
    }

    final top = <Offset>[];
    for (var sx = -24.0; sx <= w + 24; sx += 6) {
      top.add(Offset(sx, base - ridged(sx + offset) * amp * 2));
    }
    final path = Path()..moveTo(-24, h);
    for (final p in top) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(w + 24, h)
      ..close();
    if (forest) {
      // Tepelerin üstünde sık çam ormanı: ince, sivri siluetler.
      for (var i = 0; i < top.length; i++) {
        final q = top[i];
        final k = ((q.dx + offset) / 6).floor();
        final hv = ((k * 2654435761) & 0xffff) / 65535.0;
        if (hv < 0.35) continue;
        final th = amp * (0.28 + hv * 0.42);
        final tw = th * 0.22;
        path.addPolygon([
          Offset(q.dx - tw, q.dy + 2),
          Offset(q.dx, q.dy - th),
          Offset(q.dx + tw, q.dy + 2),
        ], true);
      }
    }
    canvas.drawPath(path, Paint()..color = body);
    if (cap != null) {
      // Yüksek sırtlarda kar: tepeden aşağı sarkan dilimler.
      canvas.save();
      canvas.clipPath(path);
      final snow = Path()..moveTo(-24, -10);
      for (var sx = -24.0; sx <= w + 24; sx += 6) {
        final jag =
            math.sin((sx + offset) * 0.07 + seed) * 6 +
            math.sin((sx + offset) * 0.023) * 9;
        snow.lineTo(sx, base - amp * 0.95 + jag);
      }
      snow
        ..lineTo(w + 24, -10)
        ..close();
      canvas.drawPath(snow, Paint()..color = cap);
      canvas.restore();
    }
  }
}

/// Gökteki oran konumunu ekrana çevirir (y 1 = ufuk).
abstract final class LightPos {
  static Offset of(Offset k, double w, double horizon) =>
      Offset(k.dx * w, k.dy * horizon);
}
