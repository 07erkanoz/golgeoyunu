import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';

/// Dünyanın üstüne serilen karanlık. Işık kaynakları (kavanoz, fener, çıkış,
/// hatıralar, ateşböcekleri) bu örtüde delik açar; gerisi karanlıkta kalır.
class LightingLayer extends Component with HasGameReference<GolgeGame> {
  LightingLayer() : super(priority: 40);

  static double darknessFor(LevelTheme theme) => switch (theme) {
    LevelTheme.cistern => 0.48,
    LevelTheme.cave => 0.45,
    LevelTheme.cliffs => 0.32,
    LevelTheme.sky => 0.18,
  };

  final _cut = Paint()..blendMode = BlendMode.dstOut;

  void _light(Canvas canvas, Offset c, double radius, [double strength = 1]) {
    if (radius <= 0 || strength <= 0) return;
    _cut.shader = ui.Gradient.radial(
      c,
      radius,
      [
        Color.fromRGBO(0, 0, 0, strength.clamp(0.0, 1.0)),
        Color.fromRGBO(0, 0, 0, strength.clamp(0.0, 1.0) * 0.55),
        const Color(0x00000000),
      ],
      const [0, 0.45, 1],
    );
    canvas.drawCircle(c, radius, _cut);
  }

  @override
  void render(Canvas canvas) {
    final rect = game.camera.visibleWorldRect.inflate(80);
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF040201)
            .withValues(alpha: darknessFor(game.level.def.theme)),
    );

    final p = game.player;
    if (p != null && p.isMounted && !p.isDead) {
      final (pos, radius) = p.light;
      _light(canvas, pos.toOffset(), radius);
    }
    for (final c in game.world.children) {
      switch (c) {
        case Guard g:
          final lantern = g.lanternWorld;
          _light(canvas, lantern.toOffset(), 90, 0.9);
          // Fenerin konisi de karanlığı yarar.
          final range = g.coneRange;
          final f = g.facing.toDouble();
          final cone = Path()
            ..moveTo(lantern.x, lantern.y - 3)
            ..lineTo(lantern.x + f * range, lantern.y - range * 0.5 - 34)
            ..lineTo(lantern.x + f * range, lantern.y + range * 0.5 + 34)
            ..lineTo(lantern.x, lantern.y + 3)
            ..close();
          _cut.shader = ui.Gradient.linear(
            lantern.toOffset(),
            Offset(lantern.x + f * range, lantern.y),
            const [Color(0xB0000000), Color(0x00000000)],
          );
          canvas.drawPath(cone, _cut);
        case ExitPortal e:
          _light(
            canvas,
            (e.position + Vector2(kTile / 2, kTile)).toOffset(),
            230,
          );
        case MemoryShard m:
          _light(canvas, m.position.toOffset(), 80, 0.8);
        case Bird b:
          _light(canvas, b.position.toOffset().translate(0, -6), 60, 0.6);
        case Lever l when !l.pulled:
          _light(canvas, l.position.toOffset().translate(0, -14), 46, 0.5);
        case FireflyLure l:
          _light(
            canvas,
            l.position.toOffset(),
            130 * math.max(0.3, l.strength),
            l.strength,
          );
      }
    }
    canvas.restore();
  }
}
