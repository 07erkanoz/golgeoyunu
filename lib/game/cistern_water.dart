import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'puzzles.dart';

/// Açılış perdesindeki sakin sarnıç suyu, dünya koordinatlarında.
abstract final class CisternWater {
  static const palette = [Color(0xFF29252A), Color(0xFF101015)];
  static const surfaceLight = Color(0xFFE4B585);

  static void edge(
    Canvas canvas,
    double left,
    double right,
    double top,
    double time, {
    double agitation = 0,
  }) {
    final edge = Path()..moveTo(left, top + 1);
    for (var x = left + 4; x <= right; x += 4) {
      final y =
          math.sin(x * 0.085 + time * (1.5 + agitation * 2)) *
          (0.65 + agitation * 1.35);
      edge.lineTo(x, top + 1 + y);
    }
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35 + agitation
        ..color = surfaceLight.withValues(alpha: 0.37 + agitation * 0.29),
    );
  }
}

/// Sızan su tavandan düşer, ilk yüzeye değdiğinde ses ve küçük bir iz bırakır.
class CisternDrips extends Component with HasGameReference<GolgeGame> {
  CisternDrips(this._level) : super(priority: 28) {
    final random = math.Random(1660);
    // Beş karo başına en fazla bir kaynak; önü açık havuzlar öncelikli.
    for (var start = 2; start < _level.width - 1; start += 5) {
      _Drip? source;
      for (var c = start; c < math.min(start + 5, _level.width - 1); c++) {
        int? ceiling;
        for (var r = 0; r < _level.height; r++) {
          final cell = _level.cell(c, r);
          final stone = _level.solid(c, r) || cell == '=';
          final water = cell == 'w';
          if (!stone && !water) continue;
          if (ceiling != null &&
              r - ceiling >= 3 &&
              (source == null || water && !source.endsInWater)) {
            source = _Drip(
              x: (c + 0.27 + random.nextDouble() * 0.46) * kTile,
              ceiling: ceiling * kTile,
              floor: r * kTile,
              endsInWater: water,
              delay: random.nextDouble() * 4.2 + 0.15,
            );
          }
          // Taşın altından yeni bir damla başlayabilir; suyun altından değil.
          if (water) break;
          ceiling = r + 1;
        }
      }
      if (source != null) _sources.add(source);
    }
  }

  static const _gravity = 840.0;
  static const _impactLifetime = 0.82;
  final Level _level;
  final _sources = <_Drip>[];
  final _random = math.Random(714);
  late final _basins = game.world.children.whereType<WaterBasin>().toList();

  @override
  void update(double dt) {
    for (final drop in _sources) {
      drop.impactAge += dt;
      if (drop.delay > 0) {
        drop.delay -= dt;
        continue;
      }
      drop.fall += dt;
      var floor = drop.floor;
      WaterBasin? basinHit;
      for (final basin in _basins) {
        if (drop.x > basin.area.left &&
            drop.x < basin.area.right &&
            basin.surface > drop.ceiling &&
            basin.surface < floor) {
          floor = basin.surface;
          basinHit = basin;
        }
      }
      if (drop.y < floor) continue;

      final water = basinHit != null || drop.endsInWater;
      drop
        ..impactY = floor
        ..impactWater =
            basinHit?.area ?? (water ? _poolAt(drop.x, floor) : null)
        ..impactAge = 0
        ..fall = 0
        ..delay = 2.6 + _random.nextDouble() * 4.1;
      final p = game.player;
      if (p == null || p.isDead || game.menuMode.value || game.cinematic) {
        continue;
      }
      final dx = drop.x - p.center.x;
      final dy = floor - p.center.y;
      final distance = math.sqrt(dx * dx + dy * dy);
      final near = (1 - distance / 285).clamp(0.0, 1.0);
      if (near > 0) {
        GameAudio.instance.play(
          'drip',
          volume: near * (water ? 0.58 : 0.28),
          pan: (dx / 180).clamp(-0.85, 0.85),
          minGapMs: 140,
        );
      }
    }
  }

  Rect _poolAt(double x, double y) {
    final row = (y / kTile).round();
    var left = (x / kTile).floor();
    var right = left;
    while (_level.cell(left - 1, row) == 'w') {
      left--;
    }
    while (_level.cell(right + 1, row) == 'w') {
      right++;
    }
    return Rect.fromLTWH(left * kTile, y, (right - left + 1) * kTile, kTile);
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect.inflate(28);
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final drop in _sources) {
      if (drop.x < view.left || drop.x > view.right) continue;
      final y = drop.y;
      if (drop.delay <= 0 && y >= view.top && y <= view.bottom) {
        final trail = (drop.fall * _gravity * 0.019).clamp(2.0, 10.0);
        canvas.drawLine(
          Offset(drop.x, math.max(drop.ceiling, y - trail)),
          Offset(drop.x, y),
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.15
            ..color = const Color(0x8FB7D4D4),
        );
        canvas.drawCircle(
          Offset(drop.x, y),
          1.15,
          paint
            ..style = PaintingStyle.fill
            ..color = const Color(0xC5E0ECE7),
        );
      }
      if (drop.impactAge >= _impactLifetime ||
          !view.contains(Offset(drop.x, drop.impactY))) {
        continue;
      }
      if (drop.impactWater case final area?) {
        canvas.save();
        canvas.clipRect(area);
        for (var ring = 0; ring < 2; ring++) {
          final t = (drop.impactAge - ring * 0.13) / 0.64;
          if (t <= 0 || t >= 1) continue;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(drop.x, drop.impactY + 2.2 + t * 2),
              width: 3 + 37 * t,
              height: 1.5 + 8 * t,
            ),
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0xFFC1DBD4)
                  .withValues(alpha: 0.43 * (1 - t)),
          );
        }
        canvas.restore();
      }
      final t = drop.impactAge / 0.17;
      if (t >= 1) continue;
      for (final side in const [-1, 1]) {
        canvas.drawCircle(
          Offset(drop.x + side * (2 + t * 7), drop.impactY - 17 * t * (1 - t)),
          0.95,
          paint
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFDDE8D9).withValues(alpha: 0.7 * (1 - t)),
        );
      }
    }
  }
}

class _Drip {
  _Drip({
    required this.x,
    required this.ceiling,
    required this.floor,
    required this.endsInWater,
    required this.delay,
  });

  final double x, ceiling, floor;
  final bool endsInWater;
  double delay;
  double fall = 0;
  double impactAge = CisternDrips._impactLifetime;
  double impactY = 0;
  Rect? impactWater;

  double get y => ceiling + 0.5 * CisternDrips._gravity * fall * fall;
}
