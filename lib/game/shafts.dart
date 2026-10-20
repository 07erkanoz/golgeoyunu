import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import '../settings.dart';

/// Tavandaki açıklıklardan süzülen ışık: kapalı mekânlarda (sarnıç, gemi
/// ambarı, yeraltı şehri, semâhane) yukarıdan eğik inen yumuşak ışınlar.
/// Işının içinde ağır ağır dönen toz zerreleri, tavanda açıklığın parıltısı,
/// yerde ışığın bıraktığı soluk bir havuz. Karanlık örtünün üstünde, ekleyerek
/// (plus) çizilir; böylece altında kalan her şey gerçekten aydınlanmış görünür.
class LightShafts extends Component with HasGameReference<GolgeGame> {
  LightShafts() : super(priority: 41);

  final _shafts = <_Shaft>[];
  double _t = 0;

  /// Temanın ışık rengi ve titremesi; ışık yoksa null.
  static (Color, double)? styleFor(LevelTheme theme) => switch (theme) {
    // Yukarıdaki yangının turuncu ışığı, alev gibi titrer.
    LevelTheme.cistern => (const Color(0xFFFFA860), 1.0),
    // Güverte aralıklarından ay ışığı.
    LevelTheme.ark => (const Color(0xFFB8CCF0), 0.15),
    // Hava bacalarından gün ışığı.
    LevelTheme.cave => (const Color(0xFFFFE2B0), 0.2),
    // Semâhane pencerelerinden kış ayı.
    LevelTheme.konya => (const Color(0xFFC8D8FF), 0.1),
    _ => null,
  };

  static const double _slant = 0.3;

  @override
  void onMount() {
    super.onMount();
    final style = styleFor(game.level.def.theme);
    if (style == null) return;
    final lv = game.level;
    final rnd = math.Random(lv.width * 31 + lv.height);
    var c = 3 + rnd.nextInt(6);
    while (c < lv.width - 2) {
      _scan(lv, c, rnd);
      c += 9 + rnd.nextInt(8);
    }
  }

  /// Sütunda kalın bir tavanın altını arar; oradan zemine kadar bir ışın.
  void _scan(Level lv, int c, math.Random rnd) {
    for (var r = 1; r < lv.height - 4; r++) {
      if (!lv.solid(c, r - 1) || lv.solid(c, r)) continue;
      // İnce raflar değil, en az iki kare kalın tavan (ya da haritanın üstü).
      if (r >= 2 && !lv.solid(c, r - 2)) continue;
      var floor = r;
      while (floor < lv.height &&
          !lv.solid(c, floor) &&
          lv.cell(c, floor) != 'w') {
        floor++;
      }
      final len = (floor - r) * kTile;
      if (len < 5 * kTile) continue;
      final top = Offset(c * kTile + kTile / 2, r * kTile.toDouble());
      final bottom = top.translate(len * _slant, len);
      // Karanlık bölgeler karanlık kalır.
      if (lv.darkZones.any(
        (z) => z.contains(top) || z.contains(Offset.lerp(top, bottom, 0.5)!),
      )) {
        continue;
      }
      _shafts.add(
        _Shaft(
          top,
          bottom,
          width: 18 + rnd.nextDouble() * 22,
          phase: rnd.nextDouble() * 10,
        ),
      );
    }
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    if (_shafts.isEmpty || Settings.lowGraphics) return;
    final style = styleFor(game.level.def.theme);
    if (style == null) return;
    final (color, flicker) = style;
    final view = game.camera.visibleWorldRect.inflate(120);
    // Işık ön plandaki sütunların arkasından geçer.
    final columns = game.level.frontColumns.where(view.overlaps).toList();
    canvas.save();
    if (columns.isNotEmpty) {
      final clip = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(view);
      for (final c in columns) {
        clip.addRect(c);
      }
      canvas.clipPath(clip);
    }
    for (final s in _shafts) {
      if (!s.bounds.overlaps(view)) continue;
      _shaft(canvas, s, color, flicker);
    }
    canvas.restore();
  }

  void _shaft(Canvas canvas, _Shaft s, Color color, double flicker) {
    final t = _t + s.phase;
    // Alev gibi titreyen ya da ay gibi yavaşça soluyan parlaklık.
    final noise =
        math.sin(t * 7.3) * 0.5 +
        math.sin(t * 11.1 + 1.3) * 0.3 +
        math.sin(t * 2.1) * 0.2;
    final breath = 0.85 + 0.15 * math.sin(t * 0.5);
    final k = breath * (1 - flicker * 0.18 + flicker * 0.18 * noise);
    final sway = math.sin(t * 0.37) * 6;
    final top = s.top;
    final bottom = s.bottom.translate(sway, 0);
    final w0 = s.width;
    final w1 = s.width * 2.6;

    Path beam(double grow) => Path()
      ..moveTo(top.dx - w0 / 2 * grow, top.dy)
      ..lineTo(top.dx + w0 / 2 * grow, top.dy)
      ..lineTo(bottom.dx + w1 / 2 * grow, bottom.dy)
      ..lineTo(bottom.dx - w1 / 2 * grow, bottom.dy)
      ..close();

    final add = Paint()..blendMode = BlendMode.plus;
    // Yumuşak kenar: dıştan içe üç saydam kat; en içteki çekirdek en parlak.
    for (final (grow, a) in const [(1.5, 0.05), (1.0, 0.07), (0.45, 0.08)]) {
      add.shader = Gradient.linear(top, bottom, [
        color.withValues(alpha: a * k),
        color.withValues(alpha: a * k * 0.55),
        color.withValues(alpha: 0),
      ], const [0, 0.55, 1]);
      canvas.drawPath(beam(grow), add);
    }
    add.shader = null;
    // Tavandaki açıklık: ışığın sızdığı ince bir yarık ve çevresindeki hale.
    add.shader = Gradient.radial(top, w0 * 1.4, [
      color.withValues(alpha: 0.16 * k),
      color.withValues(alpha: 0),
    ]);
    canvas.drawOval(
      Rect.fromCenter(center: top, width: w0 * 2.8, height: w0 * 0.9),
      add,
    );
    add.shader = null;
    add.color = color.withValues(alpha: 0.45 * k);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: top.translate(0, 1), width: w0, height: 2.5),
        const Radius.circular(1.2),
      ),
      add,
    );
    // Yerde ışığın havuzu.
    final pool = bottom.translate(0, -2);
    add.shader = Gradient.radial(pool, w1 * 0.9, [
      color.withValues(alpha: 0.16 * k),
      color.withValues(alpha: 0),
    ]);
    canvas.save();
    canvas.translate(pool.dx, pool.dy);
    canvas.scale(1, 0.22);
    canvas.translate(-pool.dx, -pool.dy);
    canvas.drawCircle(pool, w1 * 0.9, add);
    canvas.restore();
    add.shader = null;
    // Işığın içinde ağır ağır dönen toz zerreleri.
    final len = (s.bottom.dy - s.top.dy);
    final count = (len / 14).clamp(10, 40).toInt();
    for (var i = 0; i < count; i++) {
      final seed = (i * 0.618034 + s.phase) % 1.0;
      final speed = 0.012 + (i % 5) * 0.004;
      final u = (seed + _t * speed) % 1.0;
      final across = math.sin(i * 12.9898 + s.phase) * 0.42 +
          math.sin(_t * 0.6 + i * 1.7) * 0.06;
      final p = Offset.lerp(top, bottom, u)!;
      final width = w0 + (w1 - w0) * u;
      final twinkle = 0.5 + 0.5 * math.sin(_t * (1.4 + i % 3) + i);
      final fade = math.min(u * 6, 1.0) * (1 - u);
      final a = 0.55 * twinkle * fade * k;
      if (a < 0.02) continue;
      add.color = color.withValues(alpha: a);
      canvas.drawCircle(
        p.translate(across * width, 0),
        0.8 + (i % 3) * 0.45,
        add,
      );
    }
  }
}

class _Shaft {
  _Shaft(this.top, this.bottom, {required this.width, required this.phase})
    : bounds = Rect.fromPoints(
        top.translate(-width * 2, 0),
        bottom.translate(width * 3, 0),
      );

  final Offset top;
  final Offset bottom;
  final double width;
  final double phase;
  final Rect bounds;
}
