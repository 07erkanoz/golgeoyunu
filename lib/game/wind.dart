import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
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
    return t == LevelTheme.kaf || t == LevelTheme.sky;
  }

  void _zone(Canvas canvas, Rect z) {
    final bright = _bright;
    final air = bright ? const Color(0xFFFFFFFF) : kWarmLight;
    // Soluk bir hava sütunu: kenarları yumuşak.
    canvas.drawRect(
      z,
      Paint()
        ..shader = Gradient.linear(
          Offset(z.left, 0),
          Offset(z.right, 0),
          [
            air.withValues(alpha: 0),
            air.withValues(alpha: bright ? 0.24 : 0.13),
            air.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );
    // Yukarı kıvrılan rüzgâr çizgileri.
    final streak = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bright ? 2.4 : 1.9
      ..strokeCap = StrokeCap.round;
    final count = (z.width * z.height / 1700).clamp(8, 90).toInt();
    for (var i = 0; i < count; i++) {
      final seed = i * 0.6180339;
      final speed = 150 + (i * 37 % 90);
      final y = z.bottom - ((_t * speed + i * 97) % (z.height + 60));
      final x = z.left + (seed % 1.0) * z.width;
      final sway = math.sin(_t * 1.7 + i) * 6;
      final len = 18 + (i % 4) * 8.0;
      final fadeTop = ((y - z.top) / 60).clamp(0.0, 1.0);
      final fadeBot = ((z.bottom - y) / 40).clamp(0.0, 1.0);
      final a = (bright ? 0.9 : 0.55) * fadeTop * fadeBot;
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
    // Havalanan toz zerreleri.
    final mote = Paint();
    for (var i = 0; i < count ~/ 2; i++) {
      final y = z.bottom - ((_t * (60 + i * 7 % 40) + i * 53) % z.height);
      final x =
          z.left + ((i * 0.37) % 1.0) * z.width + math.sin(_t * 2 + i) * 8;
      mote.color = air.withValues(alpha: bright ? 0.8 : 0.5);
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
