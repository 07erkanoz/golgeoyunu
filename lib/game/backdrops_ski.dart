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
            const Color(0xFFCFD8FF).withValues(alpha: 0.12 * lt.night),
            const Color(0x00CFD8FF),
          ]),
      );
      canvas.restore();
    }
    // Güneş ve ay.
    final horizon = h * 0.8;
    final sun = LightPos.of(SkiLight.sunAt(progress), w, horizon);
    if (sun.dy < horizon + 40 && !storm) {
      _lightLeak(canvas, sun, h * 0.9, 0.32, lt.sun);
      canvas.drawCircle(sun, h * 0.06, Paint()..color = lt.sun);
      canvas.drawCircle(
        sun,
        h * 0.06,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35),
      );
    }
    if (lt.night > 0.2) {
      final moon = LightPos.of(SkiLight.moonAt(progress), w, horizon);
      _lightLeak(canvas, moon, h * 0.4, 0.2 * lt.night, lt.sun);
      canvas.drawCircle(
        moon,
        h * 0.045,
        Paint()..color = const Color(0xFFF4F1E6).withValues(alpha: lt.night),
      );
    }
    // Uzak sırtlar: üç kat, uzaktakiler göğe karışır.
    final rise = (game.level.pixelHeight - cam.y) * 0.02;
    for (final (depth, base, amp, seed, mix) in const [
      (0.03, 0.56, 70.0, 41, 0.62),
      (0.07, 0.66, 55.0, 42, 0.42),
      (0.13, 0.76, 40.0, 43, 0.22),
    ]) {
      final body = Color.lerp(
        Color.lerp(lt.ridge, lt.deep, 0.35)!,
        lt.skyLow,
        mix,
      )!;
      final cap = Color.lerp(lt.snowLit, lt.skyLow, mix + 0.15)!;
      _snowRidge(
        canvas,
        w,
        h,
        offset: cam.x * depth,
        base: h * base + rise * depth * 10,
        amp: amp,
        seed: seed,
        body: body,
        cap: cap,
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
    // Akan bulutlar: güneşin rengini alır, rüzgârla yavaşça sürüklenir.
    final cloud = Paint();
    for (var i = 0; i < 7; i++) {
      final rnd = math.Random(i * 977 + 3);
      final span = w + 600;
      final x =
          ((rnd.nextDouble() * span -
                          _t * (6 + rnd.nextDouble() * 10) -
                          cam.x * (0.02 + 0.02 * rnd.nextDouble())) %
                      span +
                  span) %
              span -
          300;
      final y = h * (0.12 + rnd.nextDouble() * 0.38);
      final cw = 160 + rnd.nextDouble() * 220;
      final a = (storm ? 0.5 : 0.28) * (1 - lt.night * 0.6);
      cloud.shader = ui.Gradient.linear(Offset(0, y - 20), Offset(0, y + 20), [
        Color.lerp(lt.sun, const Color(0xFFFFFFFF), 0.4)!.withValues(alpha: a),
        lt.skyMid.withValues(alpha: a * 0.6),
      ]);
      for (var k = 0; k < 5; k++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + (k - 2) * cw * 0.18, y + (k.isEven ? 0 : -6)),
            width: cw * (0.5 - (k - 2).abs() * 0.08),
            height: 22 + (2 - (k - 2).abs()) * 8.0,
          ),
          cloud,
        );
      }
    }
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

  /// Karlı dağ sırası: sivri tepeler, yalnız yükseklerinde kar; karın alt
  /// kenarı yamaç yarıklarında aşağı sarkar.
  void _snowRidge(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
    required double base,
    required double amp,
    required int seed,
    required Color body,
    required Color cap,
  }) {
    // Üçgen dalga: sivri tepe, düz yamaç.
    double tri(double x) {
      final f = x - x.floorToDouble();
      return 1 - (f - 0.5).abs() * 2;
    }

    double peak(double x) =>
        0.62 * math.pow(tri(x * 0.0021 + seed * 0.37), 1.6) +
        0.28 * tri(x * 0.0057 + seed * 0.11) +
        0.1 * tri(x * 0.019 + seed);
    final top = <Offset>[];
    for (var sx = -20.0; sx <= w + 20; sx += 8) {
      top.add(Offset(sx, base - peak(sx + offset) * amp * 2.2));
    }
    final path = Path()..moveTo(-20, h);
    for (final p in top) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(w + 20, h)
      ..close();
    canvas.drawPath(path, Paint()..color = body);
    // Kar: belli bir yükseklikten yukarısı; alt kenarı dişli.
    final line = base - amp * 1.0;
    canvas.save();
    canvas.clipPath(path);
    final snow = Path()..moveTo(-20, -10);
    for (var sx = -20.0; sx <= w + 20; sx += 8) {
      final jag =
          math.sin((sx + offset) * 0.09 + seed) * 7 +
          math.sin((sx + offset) * 0.031) * 10;
      snow.lineTo(sx, line + jag);
    }
    snow
      ..lineTo(w + 20, -10)
      ..close();
    canvas.drawPath(snow, Paint()..color = cap);
    canvas.restore();
  }
}

/// Gökteki oran konumunu ekrana çevirir (y 1 = ufuk).
abstract final class LightPos {
  static Offset of(Offset k, double w, double horizon) =>
      Offset(k.dx * w, k.dy * horizon);
}
