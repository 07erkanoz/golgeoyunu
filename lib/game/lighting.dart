import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'creatures.dart';
import 'entities.dart';
import 'legends.dart';
import 'mechanics.dart';
import 'puzzles.dart';
import '../settings.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';

/// Dünyanın üstüne serilen karanlık. Işık kaynakları (kavanoz, fener, çıkış,
/// hatıralar, ateşböcekleri) bu örtüde delik açar; gerisi karanlıkta kalır.
class LightingLayer extends Component with HasGameReference<GolgeGame> {
  LightingLayer() : super(priority: 40);

  /// Temanın karanlığı, parlaklık ayarına göre biraz açılır ya da koyulaşır.
  static double darknessFor(LevelTheme theme) =>
      (_baseDarkness(theme) * (2 - Settings.brightness)).clamp(0.05, 0.9);

  static double _baseDarkness(LevelTheme theme) => switch (theme) {
    LevelTheme.cistern => 0.48,
    LevelTheme.cave => 0.45,
    LevelTheme.cliffs => 0.32,
    LevelTheme.sky => 0.18,
    LevelTheme.kaf => 0.3,
    LevelTheme.snow => 0.3,
    LevelTheme.ark => 0.5,
    LevelTheme.nemrut => 0.24,
    LevelTheme.peri => 0.26,
    LevelTheme.konya => 0.38,
  };

  final _cut = Paint()..blendMode = BlendMode.dstOut;

  Rect _view = Rect.zero;

  void _light(Canvas canvas, Offset c, double radius, [double strength = 1]) {
    if (radius <= 0 || strength <= 0) return;
    // Ekran dışındaki ışıklar hiç çizilmez.
    if (!_view.overlaps(Rect.fromCircle(center: c, radius: radius))) return;
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

  /// Karanlık bölgeler örtünün altında daha da kararır; kenarları yumuşak.
  void _darkZones(Canvas canvas, Rect view) {
    for (final z in game.level.darkZones) {
      if (!z.overlaps(view)) continue;
      const edge = 96.0;
      final paint = Paint()
        ..color = const Color(0xFF040201).withValues(alpha: 0.5);
      canvas.drawRect(z.deflate(edge / 2), paint);
      // Kenarlarda yumuşak geçiş: iç içe birkaç saydam kuşak.
      for (var i = 1; i <= 4; i++) {
        canvas.drawRect(
          z.deflate(edge / 2 - i * edge / 8),
          Paint()..color = const Color(0xFF040201).withValues(alpha: 0.1),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = game.camera.visibleWorldRect.inflate(80);
    _view = rect;
    if (Settings.lowGraphics) {
      _renderCheap(canvas, rect);
      return;
    }
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF040201).withValues(
          alpha: darknessFor(game.level.def.theme) * (1 - game.lightning),
        ),
    );
    _darkZones(canvas, rect);

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
        case Watcher w when w.dazzled > 0:
          _light(canvas, w.lamp.toOffset(), 40, 0.5);
        case Watcher w:
          _light(canvas, w.lamp.toOffset(), 70, 0.8);
          _cut.shader = ui.Gradient.radial(
            w.lamp.toOffset(),
            Watcher.beamLength,
            [const Color(0xC0000000), const Color(0x00000000)],
          );
          canvas.drawPath(w.beamPath(), _cut);
        case WingsPickup k:
          _light(canvas, k.position.toOffset().translate(0, -10), 110, 0.9);
        case FireVent v when v.burning:
          _light(canvas, v.position.toOffset().translate(0, -40), 120, 0.9);
        case LanternBalloon b:
          _light(canvas, b.position.toOffset(), 60, 0.8);
        case MedusaHead m when m.eyes > 0.2:
          _light(canvas, m.position.toOffset(), 50, 0.6 * m.eyes);
        case SimurgFeather f when !f.taken:
          _light(canvas, f.position.toOffset(), 50, 0.6);
        case GiantPerde g:
          _light(canvas, g.glowCenter, g.glowRadius, 0.75);
        case SunBeam b:
          for (final (a, z) in b.segments) {
            final len = (z - a).distance;
            for (var d = 0.0; d <= len; d += 36) {
              _light(
                canvas,
                Offset.lerp(a, z, len == 0 ? 0 : d / len)!,
                46,
                0.55,
              );
            }
          }
        case SunLock l when l.open || l.charge > 0:
          _light(canvas, l.position.toOffset(), 60, 0.6);
        case FireflySwarm f:
          _light(canvas, f.position.toOffset(), 70, 0.7 * f.strength);
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

  /// Düşük grafik: ara katman olmadan tek geçişte karanlık. Işık yalnızca
  /// oyuncunun çevresinden gelir.
  void _renderCheap(Canvas canvas, Rect rect) {
    final dark = const Color(0xFF040201)
        .withValues(alpha: darknessFor(game.level.def.theme));
    final p = game.player;
    if (p == null || !p.isMounted || p.isDead) {
      canvas.drawRect(rect, Paint()..color = dark);
      return;
    }
    for (final z in game.level.darkZones) {
      if (z.overlaps(rect)) {
        canvas.drawRect(
          z,
          Paint()..color = const Color(0xFF040201).withValues(alpha: 0.45),
        );
      }
    }
    final (pos, radius) = p.light;
    final c = pos.toOffset();
    final r = radius * 1.4;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          [
            dark.withValues(alpha: 0),
            dark.withValues(alpha: dark.a * 0.5),
            dark,
          ],
          const [0, 0.45, 1],
        ),
    );
  }
}
