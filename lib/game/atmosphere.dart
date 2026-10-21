import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'levels.dart';
import 'palette.dart';
import '../settings.dart';

part 'backdrops_east.dart';

/// Dünyanın arkasında, ekran koordinatlarında çizilen gökyüzü ve paralaks
/// siluet katmanları.
class Backdrop extends Component with HasGameReference<GolgeGame> {
  double _t = 0;

  /// Gemi ambarının her sütundaki tavanı ve tabanı (satır), bölüm başına
  /// bir kez hesaplanır.
  List<(int, int)?>? _hold;
  Object? _holdFor;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final size = game.camera.viewport.size;
    final w = size.x;
    final h = size.y;
    final cam = game.camera.viewfinder.position;
    final lv = game.level;
    // 0 = bölümün dibi, 1 = tepesi.
    final height = (1 - cam.y / lv.pixelHeight).clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(0, 0, w, h);

    switch (lv.def.theme) {
      case LevelTheme.cistern:
        // Yerebatan: kemerli sütun ormanı, tavandaki deliklerden süzülen yangın ışığı.
        _gradient(canvas, rect, const [
          Color(0xFF0E0807),
          Color(0xFF2A140D),
          Color(0xFF3A1A10),
        ]);
        if (!Settings.lowGraphics) {
          _lightShafts(canvas, w, h, offset: cam.x * 0.2);
        }
        _colonnade(
          canvas,
          w,
          h,
          offset: cam.x * 0.3,
          spacing: 120,
          width: 14,
          color: const Color(0xFF3A1E14),
        );
        _colonnade(
          canvas,
          w,
          h,
          offset: cam.x * 0.55,
          spacing: 170,
          width: 20,
          color: const Color(0xFF24120C),
        );
      case LevelTheme.cave:
        // Derinlik: aşağıdan köz ısısı vuran kömür karası mağara.
        _gradient(canvas, rect, const [
          Color(0xFF0E0A09),
          Color(0xFF2E1610),
          Color(0xFF6A2A15),
        ]);
        _lightLeak(canvas, Offset(w * 0.55, h * 1.05), h * 0.95, 0.20, kEmber);
        final dy = -cam.y * 0.05;
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.15,
          base: h * 0.2 + dy,
          amp: 40,
          freq: 0.012,
          seed: 1,
          color: const Color(0xFF3A1C13),
          fromTop: true,
        );
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.15,
          base: h * 0.76 + dy,
          amp: 45,
          freq: 0.01,
          seed: 2,
          color: const Color(0xFF4A2214),
        );
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.35,
          base: h * 0.1 + dy,
          amp: 55,
          freq: 0.016,
          seed: 3,
          color: const Color(0xFF22120D),
          fromTop: true,
        );
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.35,
          base: h * 0.86 + dy,
          amp: 55,
          freq: 0.013,
          seed: 4,
          color: const Color(0xFF2A140D),
        );
      case LevelTheme.cliffs:
        // Kayalıklar: tırmandıkça açılan pas rengi alacakaranlık.
        _gradient(canvas, rect, [
          lerpColor(0xFF3A1D16, 0xFFD07A45, height),
          lerpColor(0xFF1C0F0C, 0xFF7A3520, height),
        ]);
        _lightLeak(
          canvas,
          Offset(w * 0.5, -h * 0.1),
          h * 1.2,
          0.06 + height * 0.16,
          const Color(0xFFF0A060),
        );
        final rise = (lv.pixelHeight - cam.y) * 0.12;
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.1,
          base: h * 0.45 + rise,
          amp: 70,
          freq: 0.006,
          seed: 5,
          color: lerpColor(0xFF3E1F16, 0xFFA8542F, height),
        );
        _trees(
          canvas,
          w,
          offset: cam.x * 0.25,
          base: h * 0.62 + rise * 1.4,
          color: lerpColor(0xFF26140F, 0xFF6A2E1C, height),
        );
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.25,
          base: h * 0.64 + rise * 1.4,
          amp: 50,
          freq: 0.01,
          seed: 6,
          color: lerpColor(0xFF26140F, 0xFF6A2E1C, height),
        );
      case LevelTheme.kaf:
        _kaf(canvas, w, h, cam, height);
      case LevelTheme.snow:
        _snowPeaks(canvas, w, h, cam, height, lv.def.variant);
      case LevelTheme.ark:
        _arkHull(canvas, w, h, cam);
      case LevelTheme.nemrut:
        _nemrut(canvas, w, h, cam, lv.def.variant);
      case LevelTheme.peri:
        _fairyChimneys(canvas, w, h, cam);
      case LevelTheme.konya:
        _konya(canvas, w, h, cam);
      case LevelTheme.sky:
        // Gökyolu: dumanlı mor tepe, kızıl ufuk, kırık güneş.
        _gradient(canvas, rect, const [
          Color(0xFF2E2228),
          Color(0xFF9C4528),
          Color(0xFFE39B62),
        ]);
        _brokenSun(canvas, Offset(w * 0.72, h * 0.24), h * 0.11);
        _islands(canvas, w, h, offset: cam.x * 0.18);
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.1 + _t * 4,
          base: h * 0.72,
          amp: 26,
          freq: 0.012,
          seed: 7,
          color: const Color(0xFFB5603A),
          bumpy: true,
        );
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.25 + _t * 8,
          base: h * 0.83,
          amp: 32,
          freq: 0.01,
          seed: 8,
          color: const Color(0xFF8A3C24),
          bumpy: true,
        );
        _ridge(
          canvas,
          w,
          h,
          offset: cam.x * 0.45 + _t * 12,
          base: h * 0.94,
          amp: 30,
          freq: 0.009,
          seed: 9,
          color: const Color(0xFF5E281A),
          bumpy: true,
        );
    }
  }

  /// Sarnıcın derinliğe doğru sıralanan sütunları ve onları bağlayan kemerler.
  void _colonnade(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
    required double spacing,
    required double width,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    final top = h * 0.12;
    final bottom = h * 0.86;
    final first = (offset / spacing).floor() - 1;
    for (var i = first; i * spacing - offset < w + spacing; i++) {
      final x = i * spacing - offset;
      canvas.drawRect(
        Rect.fromLTRB(x - width / 2, top, x + width / 2, bottom),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          x - width * 0.85,
          top,
          x + width * 0.85,
          top + width * 0.6,
        ),
        paint,
      );
      final arch = Path()
        ..moveTo(x, top)
        ..lineTo(x, 0)
        ..lineTo(x + spacing, 0)
        ..lineTo(x + spacing, top)
        ..quadraticBezierTo(x + spacing / 2, top - spacing * 0.55, x, top)
        ..close();
      canvas.drawPath(arch, paint);
    }
    // Suyun üstündeki sütun yansımaları.
    final water = Paint()..color = color.withValues(alpha: 0.5);
    for (var i = first; i * spacing - offset < w + spacing; i++) {
      final x = i * spacing - offset + math.sin(_t * 1.3 + i) * 2;
      canvas.drawRect(
        Rect.fromLTRB(x - width / 2, bottom + 4, x + width / 2, h),
        water,
      );
    }
  }

  void _lightShafts(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
  }) {
    for (var i = 0; i < 4; i++) {
      final span = w + 600;
      final x = ((i * 410 + 180 - offset) % span + span) % span - 200;
      final pulse = 0.7 + 0.3 * math.sin(_t * 0.6 + i * 1.9);
      final beam = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 46, 0)
        ..lineTo(x + 170, h)
        ..lineTo(x + 60, h)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x + 120, h), [
            const Color(0xFFFFB070).withValues(alpha: 0.13 * pulse),
            const Color(0xFFFFB070).withValues(alpha: 0),
          ]),
      );
    }
  }

  void _gradient(Canvas canvas, Rect rect, List<Color> colors) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          colors,
          colors.length == 3 ? const [0, 0.5, 1] : null,
        ),
    );
  }

  void _lightLeak(
    Canvas canvas,
    Offset c,
    double r,
    double alpha, [
    Color color = kLight,
  ]) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]),
    );
  }

  void _ridge(
    Canvas canvas,
    double w,
    double h, {
    required double offset,
    required double base,
    required double amp,
    required double freq,
    required int seed,
    required Color color,
    bool fromTop = false,
    bool bumpy = false,
  }) {
    double f(double x) {
      var v =
          0.55 * math.sin(x * freq + seed) +
          0.3 * math.sin(x * freq * 2.3 + seed * 1.7) +
          0.15 * math.sin(x * freq * 5.1 + seed * 0.3);
      if (bumpy) v = -v.abs() * 1.3;
      return v * amp;
    }

    final path = Path()..moveTo(-10, fromTop ? 0 : h);
    for (var sx = -10.0; sx <= w + 20; sx += 10) {
      final y = fromTop
          ? base - f(sx + offset).abs() * 0.4 - f(sx * 3.1 + offset).abs() * 0.5
          : base + f(sx + offset);
      path.lineTo(sx, y);
    }
    path
      ..lineTo(w + 20, fromTop ? 0 : h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _trees(
    Canvas canvas,
    double w, {
    required double offset,
    required double base,
    required Color color,
  }) {
    const spacing = 180.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final first = ((offset - 100) / spacing).floor();
    for (var i = first; i * spacing - offset < w + 100; i++) {
      final rnd = math.Random(i * 92821 + 7);
      if (rnd.nextDouble() < 0.35) continue;
      final x = i * spacing - offset + rnd.nextDouble() * 60;
      final th = 60 + rnd.nextDouble() * 70;
      paint.strokeWidth = 4 + rnd.nextDouble() * 3;
      canvas.drawLine(Offset(x, base + 20), Offset(x, base - th), paint);
      for (var b = 0; b < 4; b++) {
        final by = base - th * (0.45 + b * 0.14);
        final side = b.isEven ? 1 : -1;
        paint.strokeWidth = 2;
        canvas.drawLine(
          Offset(x, by),
          Offset(
            x + side * (12 + rnd.nextDouble() * 18),
            by - 10 - rnd.nextDouble() * 12,
          ),
          paint,
        );
      }
    }
  }

  void _brokenSun(Canvas canvas, Offset c, double r) {
    _lightLeak(canvas, c, r * 4, 0.35, const Color(0xFFFFC890));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFBE3C4));
    final crack = Path()
      ..moveTo(c.dx - r * 0.2, c.dy - r * 1.05)
      ..lineTo(c.dx + r * 0.05, c.dy - r * 0.45)
      ..lineTo(c.dx - r * 0.15, c.dy - r * 0.1)
      ..lineTo(c.dx + r * 0.2, c.dy + r * 0.35)
      ..lineTo(c.dx + r * 0.02, c.dy + r * 1.05);
    canvas.drawPath(
      crack,
      Paint()
        ..color = const Color(0xFFB4643C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07,
    );
  }

  void _islands(Canvas canvas, double w, double h, {required double offset}) {
    const spacing = 420.0;
    final paint = Paint()..color = const Color(0xFF6E3326);
    final first = ((offset - 200) / spacing).floor();
    for (var i = first; i * spacing - offset < w + 200; i++) {
      final rnd = math.Random(i * 4513 + 3);
      final x = i * spacing - offset + rnd.nextDouble() * 120;
      final y = h * (0.35 + rnd.nextDouble() * 0.25);
      final s = 0.6 + rnd.nextDouble() * 0.8;
      canvas.drawPath(
        Path()
          ..moveTo(x - 50 * s, y)
          ..lineTo(x + 50 * s, y)
          ..lineTo(x + 30 * s, y + 18 * s)
          ..lineTo(x + 8 * s, y + 45 * s)
          ..lineTo(x - 12 * s, y + 22 * s)
          ..lineTo(x - 40 * s, y + 12 * s)
          ..close(),
        paint,
      );
    }
  }
}

/// Dünyanın önünde: sis, vinyet, film greni, titreme ve geçiş kararması.
class ScreenEffects extends Component with HasGameReference<GolgeGame> {
  ScreenEffects() : super(priority: 10);

  double fade = 1;
  Color fadeColor = kInk;
  double _fadeTarget = 1;
  double _fadeSpeed = 1;
  VoidCallback? _onFaded;
  double _t = 0;
  final _rnd = math.Random();
  final _grain = Float32List(2 * 260);
  Size? _vignetteSize;
  Paint? _vignette;

  void fadeTo(
    double target,
    double seconds, {
    Color? color,
    VoidCallback? onDone,
  }) {
    if (color != null) fadeColor = color;
    _fadeTarget = target;
    _fadeSpeed = (target - fade).abs() / math.max(seconds, 0.001);
    _onFaded = onDone;
  }

  void setFade(double value, Color color) {
    fade = _fadeTarget = value;
    fadeColor = color;
    _onFaded = null;
  }

  double _wait = 0;
  VoidCallback? _afterWait;

  /// Korku nabzı (0-1): çakma, kararan kenarlar, kalp gibi atan karanlık.
  double _scare = 0;
  double _scareT = 9;

  void scare(double amount) {
    _scare = math.max(_scare, amount.clamp(0.0, 1.0));
    _scareT = 0;
  }

  /// [seconds] sonra [then] çağrılır (karartı beklerken).
  void after(double seconds, VoidCallback then) {
    _wait = seconds;
    _afterWait = then;
  }

  @override
  void update(double dt) {
    _t += dt;
    _scareT += dt;
    _scare = math.max(0, _scare - dt * 0.45);
    if (_afterWait != null) {
      _wait -= dt;
      if (_wait <= 0) {
        final cb = _afterWait;
        _afterWait = null;
        cb?.call();
      }
    }
    if (fade != _fadeTarget) {
      final step = _fadeSpeed * dt;
      fade = (fade - _fadeTarget).abs() <= step
          ? _fadeTarget
          : fade + step * (_fadeTarget > fade ? 1 : -1);
      if (fade == _fadeTarget) {
        final cb = _onFaded;
        _onFaded = null;
        cb?.call();
      }
    }
  }

  /// Yükselen közler ve (açık havada) düşen kül; Kaf'ta zümrüt kıvılcımlar.
  void _embers(
    Canvas canvas,
    double w,
    double h,
    double camX,
    LevelTheme theme,
  ) {
    final cam = Vector2(camX, 0);
    final ember = Paint();
    final emberCount = Settings.lowGraphics ? 14 : 36;
    for (var i = 0; i < emberCount; i++) {
      final speed = 18 + (i * 37 % 23);
      final k = ((_t * speed / h + i * 0.618) % 1.0);
      final x =
          ((i * 211.0 + math.sin(_t * 0.7 + i) * 30 - cam.x * 0.3) % w + w) % w;
      final y = h * (1 - k);
      final flicker = 0.5 + 0.5 * math.sin(_t * 9 + i * 2.3);
      ember.color = (theme == LevelTheme.kaf ? const Color(0xFF9FF0C8) : kEmber)
          .withValues(alpha: (1 - k) * (0.35 + 0.5 * flicker));
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.5, ember);
    }
    if (!theme.indoor) {
      final ash = Paint()
        ..color = const Color(0xFFCFC2B6).withValues(alpha: 0.35);
      for (var i = 0; i < (Settings.lowGraphics ? 10 : 28); i++) {
        final k = ((_t * (10 + i % 7) / h + i * 0.381) % 1.0);
        final x =
            ((i * 157.0 + math.sin(_t * 0.5 + i * 1.7) * 40 - cam.x * 0.5) % w +
                w) %
            w;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, h * k), width: 2.2, height: 1.4),
          ash,
        );
      }
    }

    // Vinyet.
    if (_vignetteSize != Size(w, h)) {
      _vignetteSize = Size(w, h);
      _vignette = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          math.max(w, h) * 0.72,
          [
            const Color(0x000A0605),
            const Color(0x590A0605),
            const Color(0xEB0A0605),
          ],
          const [0.0, 0.55, 1.0],
        );
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _vignette!);
  }

  /// Korku anı: kısa soğuk çakma, sonra kenarlardan içeri sızan ve kalp
  /// gibi atan mürekkep karanlığı.
  /// Kar fırtınası. Ekranı düz bir beyazla boğmaz: kenarlara doğru koyulaşan
  /// bir boran perdesi (Sâye'nin çevresi açık kalır), esintiyle dalgalanan
  /// savrulan kar perdeleri ve üç derinlikte taneler (uzakta küçük ve soluk,
  /// yakında iri, hızdan uzayan).
  void _blizzard(Canvas canvas, double w, double h, double storm) {
    final low = Settings.lowGraphics;
    // Esinti: birkaç saniyede bir kabarıp söner.
    final gust =
        0.95 + 0.14 * math.sin(_t * 0.9) + 0.06 * math.sin(_t * 2.3 + 1.1);
    // Sâye'nin ekrandaki yeri: perde orada incelir.
    var focus = Offset(w * 0.5, h * 0.55);
    final p = game.player;
    if (p != null && p.isMounted) {
      final view = game.camera.visibleWorldRect;
      focus = Offset(
        (p.center.x - view.left) / view.width * w,
        (p.center.y - view.top) / view.height * h,
      );
    }
    final r = math.max(w, h);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          focus,
          r * 0.75,
          [
            const Color(0xFFE6EEF7).withValues(alpha: 0.05 * storm),
            const Color(0xFFDCE6F2).withValues(alpha: 0.22 * storm * gust),
            const Color(0xFFD2DDEA).withValues(alpha: 0.46 * storm * gust),
          ],
          const [0.12, 0.45, 1],
        ),
    );
    // Savrulan kar perdeleri: sağdan sola hızla geçen uzun, yumuşak bantlar.
    if (!low) {
      for (var k = 0; k < 4; k++) {
        final bandY =
            h * (0.18 + 0.22 * k) + math.sin(_t * 0.4 + k * 1.7) * h * 0.06;
        final span = w * 1.6;
        final x =
            w - ((_t * (260 + k * 70) * (0.6 + gust) + k * 431) % (span + w));
        final rect = Rect.fromCenter(
          center: Offset(x + span / 2, bandY),
          width: span,
          height: h * (0.08 + 0.04 * (k % 2)),
        );
        canvas.drawOval(
          rect,
          Paint()
            ..shader = ui.Gradient.radial(rect.center, span / 2, [
              const Color(0xFFF2F6FA).withValues(alpha: 0.24 * storm * gust),
              const Color(0xFFF2F6FA).withValues(alpha: 0),
            ]),
        );
      }
    }
    // Taneler: üç derinlik.
    final flake = Paint()..strokeCap = StrokeCap.round;
    final count = low ? 70 : 170;
    for (var i = 0; i < count; i++) {
      final depth = i % 3; // 0 uzak, 2 yakın
      final seed = (i * 0.6180339) % 1.0;
      final seed2 = (i * 0.4142135) % 1.0;
      final speed = (420 + depth * 380) * (0.55 + gust * 0.6);
      final fall = 70 + depth * 55;
      final wobble = math.sin(_t * (1.5 + depth) + i) * (10 + depth * 8);
      final x = w + 40 - ((seed * (w + 80) * 3 + _t * speed) % (w + 80));
      final y = (seed2 * h + _t * fall + wobble) % (h + 20) - 10;
      final a = (0.35 + 0.25 * depth) * storm;
      flake.color = const Color(0xFFF8FBFF).withValues(alpha: a);
      if (depth == 2) {
        // Yakın taneler hızdan uzar.
        final len = speed * 0.022;
        flake.strokeWidth = 2.2;
        canvas.drawLine(
          Offset(x, y),
          Offset(x + len, y - len * fall / speed),
          flake,
        );
      } else {
        canvas.drawCircle(Offset(x, y), 0.9 + depth * 0.8, flake);
      }
    }
  }

  void _scarePulse(Canvas canvas, double w, double h) {
    final s = _scare;
    if (s <= 0.01) return;
    if (_scareT < 0.28) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFE8F4FF).withValues(
            alpha: 0.6 * s * (1 - _scareT / 0.28) * Settings.flashScale,
          ),
      );
    }
    // İki vuruşlu kalp: güm-güm, sessizlik.
    final beat = (_t * 1.3) % 1.0;
    final pulse = beat < 0.12
        ? math.sin(beat / 0.12 * math.pi)
        : (beat < 0.3 ? 0.6 * math.sin((beat - 0.15) / 0.15 * math.pi) : 0.0);
    final r = math.max(w, h) * (0.6 - 0.24 * s - 0.06 * pulse);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          r,
          [
            const Color(0x00200303),
            const Color(0xFF200303).withValues(alpha: 0.75 * s),
            const Color(0xFF0A0101).withValues(alpha: s),
          ],
          const [0.25, 0.62, 0.95],
        ),
    );
    // Kalp atışıyla bütün ekrana vuran kızıl nabız.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = const Color(0xFF8A0E0E)
            .withValues(alpha: s * (0.06 + 0.12 * pulse)),
    );
    // Kenarlardan uzanan titrek kara çizgiler (mürekkep damarları); altında
    // kızıl bir hare, karanlıkta seçilsinler.
    final glow = Paint()
      ..color = const Color(0xFFB01818).withValues(alpha: 0.35 * s)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final ink = Paint()
      ..color = const Color(0xFF050202).withValues(alpha: 0.9 * s)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final ang = i / 26 * 2 * math.pi + math.sin(_t * 0.7 + i) * 0.05;
      final edge = Offset(
        w / 2 + math.cos(ang) * w * 0.56,
        h / 2 + math.sin(ang) * h * 0.56,
      );
      final len = (0.25 + 0.2 * ((i * 37) % 5) / 5) * s * (1 + 0.3 * pulse);
      var p = edge;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var k = 1; k <= 5; k++) {
        final t = k / 5 * len;
        final jitter = math.sin(_t * 9 + i * 3 + k) * 6;
        p =
            Offset.lerp(edge, Offset(w / 2, h / 2), t)! +
            Offset(-math.sin(ang) * jitter, math.cos(ang) * jitter);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, ink..style = PaintingStyle.stroke);
    }
  }

  /// Kar: yakındakiler büyük ve hızlı, uzaktakiler küçük; rüzgârla savrulur.
  void _snow(Canvas canvas, double w, double h, double camX) {
    final flake = Paint();
    final count = Settings.lowGraphics ? 40 : 110;
    final gust = math.sin(_t * 0.4) * 0.5 + 0.5;
    for (var i = 0; i < count; i++) {
      final depth = 0.3 + (i % 5) * 0.18;
      final speed = 30 + depth * 60;
      final k = ((_t * speed / h + i * 0.618) % 1.0);
      final drift = _t * (20 + gust * 60) * depth;
      final x =
          ((i * 173.0 +
                          drift +
                          math.sin(_t * 0.9 + i) * 18 -
                          camX * depth * 0.6) %
                      (w + 40) +
                  w +
                  40) %
              (w + 40) -
          20;
      flake.color = const Color(0xFFF2F6FA)
          .withValues(alpha: 0.25 + 0.5 * depth);
      canvas.drawCircle(Offset(x, h * k), 0.8 + depth * 1.8, flake);
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.camera.viewport.size;
    final w = size.x;
    final h = size.y;
    final cam = game.camera.viewfinder.position;
    final theme = game.level.def.theme;

    // Sürüklenen sis: mağarada köz, kayalıkta kül, gökte toz rengi.
    final (fogColor, fogAlpha) = switch (theme) {
      LevelTheme.cistern => (const Color(0xFFD08A5A), 0.05),
      LevelTheme.cave => (kEmber, 0.05),
      LevelTheme.cliffs => (const Color(0xFFB09080), 0.06),
      LevelTheme.sky => (const Color(0xFFF0C8A0), 0.09),
      LevelTheme.kaf => (const Color(0xFF8FE0C0), 0.07),
      LevelTheme.snow => (const Color(0xFFD8E4F0), 0.09),
      LevelTheme.ark => (const Color(0xFFD09A6A), 0.05),
      LevelTheme.nemrut => (const Color(0xFFF0C4A0), 0.07),
      LevelTheme.peri => (const Color(0xFFF0C8A0), 0.07),
      LevelTheme.konya => (const Color(0xFFC8D8F0), 0.07),
    };
    if (!Settings.lowGraphics) {
      for (var i = 0; i < 5; i++) {
        final span = w + 700;
        final x =
            ((i * 373 + _t * (8 + i * 3) - cam.x * (0.5 + i * 0.12)) % span +
                    span) %
                span -
            350;
        final y = h * (0.25 + (i % 3) * 0.25) + math.sin(_t * 0.2 + i) * 20;
        // Yassı, yumuşak kenarlı sis bulutu: degrade daireyi dikeyde ezer.
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(1, 0.3);
        glowDot(canvas, Offset.zero, 280, fogColor, fogAlpha * 1.6);
        canvas.restore();
      }
    }

    if (theme.snowy) {
      _snow(canvas, w, h, cam.x);
    } else {
      _embers(canvas, w, h, cam.x, theme);
    }

    // Şimşek: çift çakan beyaz bir an.
    final bolt = game.lightning;
    if (bolt > 0.01) {
      final flicker = bolt > 0.6 ? 1.0 : (bolt > 0.4 ? 0.3 : 0.8);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFEAF0FF).withValues(
            alpha:
                0.55 *
                bolt *
                (Settings.calmEffects ? 0.35 : flicker) *
                Settings.flashScale,
          ),
      );
    }

    // Tipi: kar katman katman savrulur; Sâye'nin çevresi okunur kalır.
    final storm = game.blizzard;
    if (storm > 0.01) _blizzard(canvas, w, h, storm);

    _scarePulse(canvas, w, h);

    // Gerilim: şüphe arttıkça kenarlar kararır; saklanırken renkler solar.
    final threat = game.threat;
    if (threat > 0.02) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w / 2, h / 2),
            math.max(w, h) * 0.62,
            [
              const Color(0x000A0605),
              const Color(0xFF0A0605).withValues(alpha: 0.75 * threat),
            ],
            const [0.45, 1.0],
          ),
      );
    }
    // Saklanırken renkler solar: soğuk gri bir örtü. (Önceden doygunluk
    // karışımıyla yapılıyordu; o karışım telefon ekran kartlarında her karede
    // bütün ekranı yeniden okutuyor, saklanırken kare hızı düşüyordu.)
    final hide = game.hideAmount;
    if (hide > 0.02) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF2E3036).withValues(alpha: 0.3 * hide),
      );
    }

    // Parlaklık: hafif sıcak bir aydınlatma ya da karartma.
    final b = Settings.brightness;
    if (b > 1.001) {
      // Düz karışım (ekran karışımı telefonda her karede pahalıydı).
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFFFE8D0).withValues(alpha: (b - 1) * 0.16),
      );
    } else if (b < 0.999) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = kInk.withValues(alpha: (1 - b) * 0.9),
      );
    }

    if (Settings.lowGraphics) {
      if (fade > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = fadeColor.withValues(alpha: fade.clamp(0.0, 1.0)),
        );
      }
      return;
    }

    // Film greni.
    for (var i = 0; i < _grain.length; i += 2) {
      _grain[i] = _rnd.nextDouble() * w;
      _grain[i + 1] = _rnd.nextDouble() * h;
    }
    canvas.drawRawPoints(
      PointMode.points,
      _grain,
      Paint()
        ..color = const Color(0x14FFFFFF)
        ..strokeWidth = 1.6,
    );
    for (var i = 0; i < _grain.length; i += 2) {
      _grain[i] = _rnd.nextDouble() * w;
      _grain[i + 1] = _rnd.nextDouble() * h;
    }
    canvas.drawRawPoints(
      PointMode.points,
      _grain,
      Paint()
        ..color = const Color(0x22000000)
        ..strokeWidth = 2,
    );

    // Eski film titremesi.
    final flicker = (math.sin(_t * 23) * math.sin(_t * 7.3)).abs() * 0.05;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = kInk.withValues(alpha: flicker),
    );

    if (fade > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = fadeColor.withValues(alpha: fade.clamp(0.0, 1.0)),
      );
    }
  }
}
