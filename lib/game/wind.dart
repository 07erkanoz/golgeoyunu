import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';

/// Rüzgâr akımları (`r`) ve süzülme izleri: görünmeyen havayı görünür kılar.
/// Akımın içinde yukarı kıvrılan rüzgâr çizgileri ve havalanan toz zerreleri;
/// süzülen Sâye'nin kanatlarından geriye akan hava.
class WindCurrents extends Component with HasGameReference<GolgeGame> {
  WindCurrents() : super(priority: 12);

  final _zones = <Rect>[];
  double _t = 0;

  @override
  void onMount() {
    super.onMount();
    final lv = game.level;
    // Aynı sütun aralığındaki ardışık satırlar tek bir bölge olur.
    final open = <(int, int), Rect>{};
    for (var r = 0; r < lv.height; r++) {
      final runs = <(int, int)>{};
      var c = 0;
      while (c < lv.width) {
        if (lv.cell(c, r) != 'r') {
          c++;
          continue;
        }
        final c0 = c;
        while (c < lv.width && lv.cell(c, r) == 'r') {
          c++;
        }
        runs.add((c0, c - 1));
      }
      for (final key in open.keys.toList()) {
        if (!runs.contains(key)) _zones.add(open.remove(key)!);
      }
      for (final run in runs) {
        final rect = Rect.fromLTRB(
          run.$1 * kTile,
          r * kTile,
          (run.$2 + 1) * kTile,
          (r + 1) * kTile,
        );
        open[run] = open.containsKey(run)
            ? open[run]!.expandToInclude(rect)
            : rect;
      }
    }
    _zones.addAll(open.values);
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect.inflate(64);
    for (final z in _zones) {
      if (!z.overlaps(view)) continue;
      _zone(canvas, z);
    }
    _trail(canvas);
  }

  /// Açık renkli göklerde (Kaf, Gökyolu) krem çizgiler kaybolur: orada
  /// akım beyaz ve daha belirgin çizilir.
  bool get _bright {
    final t = game.level.def.theme;
    return t.airy;
  }

  /// Sütunun tepesi havaya karışarak söner (itiş bölgenin tepesinde biter,
  /// görünüş birkaç kare yukarıda); dibi de yumuşakça başlar.
  static const double _riseOver = 3 * kTile;
  static const double _fadeTop = 4.5 * kTile;
  static const double _fadeBottom = 1.8 * kTile;

  /// Hava sütunu: yanlara ve uçlara doğru sönen küçük bir görüntü, bir kez
  /// çizilir ve bölgeye gerilerek basılır (her karede yalnız bir çizim; dilim
  /// dikişi yok).
  final _haze = <Rect, (Rect, Image)>{};
  final _hazePaint = Paint()..filterQuality = FilterQuality.low;

  (Rect, Image) _hazeOf(Rect z, Color air, double peak) =>
      _haze.putIfAbsent(z, () {
        final box = Rect.fromLTRB(
          z.left - kTile / 2,
          z.top - _riseOver,
          z.right + kTile / 2,
          z.bottom + kTile * 0.6,
        );
        final sTop = (_fadeTop / box.height).clamp(0.0, 0.48);
        final sBot = (_fadeBottom / box.height).clamp(0.0, 0.48);
        const iw = 48, ih = 192;
        const full = Rect.fromLTWH(0, 0, iw + 0.0, ih + 0.0);
        const n = 12;
        final rec = PictureRecorder();
        Canvas(rec)
          ..saveLayer(full, Paint())
          ..drawRect(
            full,
            Paint()
              ..shader = Gradient.linear(
                Offset.zero,
                const Offset(iw + 0.0, 0),
                [
                  for (var i = 0; i <= n; i++)
                    air.withValues(
                      alpha: peak * math.pow(math.sin(math.pi * i / n), 1.6),
                    ),
                ],
                [for (var i = 0; i <= n; i++) i / n],
              ),
          )
          ..drawRect(
            full,
            Paint()
              ..blendMode = BlendMode.dstIn
              ..shader = Gradient.linear(
                Offset.zero,
                const Offset(0, ih + 0.0),
                const [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                [0, sTop, 1 - sBot, 1],
              ),
          )
          ..restore();
        return (box, rec.endRecording().toImageSync(iw, ih));
      });

  @override
  void onRemove() {
    for (final (_, img) in _haze.values) {
      img.dispose();
    }
    _haze.clear();
    super.onRemove();
  }

  /// Akımın uçlarına doğru solma (0-1): tepede havaya karışır, dipte
  /// yavaşça belirir.
  double _ends(Rect z, double y) {
    final top = ((y - (z.top - _riseOver)) / _fadeTop).clamp(0.0, 1.0);
    final bottom = ((z.bottom + kTile * 0.6 - y) / _fadeBottom).clamp(
      0.0,
      1.0,
    );
    return top * bottom;
  }

  void _zone(Canvas canvas, Rect z) {
    final bright = _bright;
    final air = bright ? const Color(0xFFFFFFFF) : kWarmLight;
    // Soluk bir hava sütunu: kenarları ve uçları yumuşak.
    final (box, img) = _hazeOf(z, air, bright ? 0.24 : 0.13);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width + 0.0, img.height + 0.0),
      box,
      _hazePaint,
    );
    // Yukarı kıvrılan rüzgâr çizgileri: tepeyi aşıp havada söner.
    final streak = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bright ? 2.4 : 1.9
      ..strokeCap = StrokeCap.round;
    final count = (z.width * z.height / 1700).clamp(8, 90).toInt();
    final span = z.height + _riseOver + kTile;
    for (var i = 0; i < count; i++) {
      final seed = i * 0.6180339;
      final speed = 150 + (i * 37 % 90);
      final y = z.bottom + kTile * 0.6 - ((_t * speed + i * 97) % span);
      final x = z.left + (seed % 1.0) * z.width;
      // Tepede akım dağılır: çizgiler yana açılır.
      final above = ((z.top - y) / _riseOver).clamp(0.0, 1.0);
      final sway =
          math.sin(_t * 1.7 + i) * 6 + (seed % 1.0 - 0.5) * 40 * above;
      final len = 18 + (i % 4) * 8.0;
      final a = (bright ? 0.9 : 0.55) * _ends(z, y);
      if (a <= 0.01) continue;
      streak.color =
          (bright ? const Color(0xFFFFFFFF) : const Color(0xFFFFF0D0))
              .withValues(alpha: a);
      canvas.drawPath(
        Path()
          ..moveTo(x + sway, y + len)
          ..quadraticBezierTo(x + sway + 5, y + len / 2, x + sway, y),
        streak,
      );
    }
    // Havalanan toz zerreleri: dipte belirir, tepede söner.
    final mote = Paint();
    for (var i = 0; i < count ~/ 2; i++) {
      final y =
          z.bottom + kTile * 0.6 - ((_t * (60 + i * 7 % 40) + i * 53) % span);
      final x =
          z.left + ((i * 0.37) % 1.0) * z.width + math.sin(_t * 2 + i) * 8;
      final a = (bright ? 0.8 : 0.5) * _ends(z, y);
      if (a <= 0.01) continue;
      mote.color = air.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 1.6, mote);
    }
  }

  /// Süzülürken kanatlardan geriye akan hava çizgileri.
  void _trail(Canvas canvas) {
    final p = game.player;
    if (p == null || !p.isMounted || p.isDead || !p.gliding) return;
    final dir = p.velocity.x.abs() > 20
        ? p.velocity.x.sign
        : p.facing.toDouble();
    final c = Offset(p.center.x, p.center.y - 6);
    final line = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final k = (_t * 2.6 + i / 6) % 1.0;
      final back = 14 + k * 46;
      final y = c.dy + (i - 2.5) * 5 + math.sin(_t * 5 + i) * 2;
      line.color = const Color(0xFFFFF0D0).withValues(alpha: 0.35 * (1 - k));
      canvas.drawLine(
        Offset(c.dx - dir * back, y),
        Offset(c.dx - dir * (back + 12), y - 1),
        line,
      );
    }
  }
}
