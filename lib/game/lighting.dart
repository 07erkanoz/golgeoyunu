import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'creatures.dart';
import 'entities.dart';
import 'konya.dart';
import 'legends.dart';
import 'mechanics.dart';
import 'nemrut.dart';
import 'palette.dart';
import 'puzzles.dart';
import 'umay.dart';
import 'gokboru.dart';
import 'cameos.dart';
import 'erlik.dart';
import 'ergenekon.dart';
import 'heavens.dart';
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
      (_baseDarkness(theme) * (1 - (Settings.brightness - 1) * 0.9)).clamp(
        0.03,
        0.92,
      );

  /// Karanlığın rengi: ormanda serin yeşil, öbür yerlerde is kahvesi.
  static Color shadowInk(LevelTheme theme) => theme == LevelTheme.forest
      ? const Color(0xFF020805)
      : const Color(0xFF040201);

  static double _baseDarkness(LevelTheme theme) => switch (theme) {
    // Görsel deneme: renk dili okunsun diye sarnıç çok daha aydınlık.
    LevelTheme.cistern => Cartoon.on ? Cartoon.darkness : 0.48,
    LevelTheme.cave => 0.45,
    LevelTheme.cliffs => 0.32,
    LevelTheme.sky => 0.18,
    LevelTheme.kaf => 0.3,
    LevelTheme.snow => 0.3,
    LevelTheme.ark => 0.34,
    LevelTheme.nemrut => 0.24,
    LevelTheme.peri => 0.26,
    LevelTheme.konya => 0.38,
    LevelTheme.underworld => 0.42,
    LevelTheme.ergenekon => 0.2,
    LevelTheme.heavens => 0.12,
    // Ötüken Ormanı: oyunun aydınlık, yeşil yeri.
    LevelTheme.forest => 0.16,
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

  /// Kaya duvarda kesilen ışık: ışık merkezden ışınlarla taranır, ilk kaya
  /// hücresinde durur; karanlık yalnızca görünen bölgede yarılır. Oynanıştaki
  /// ışık sorgusu da duvarda kesilir: tahtanın yanıp yanmadığı ekranda
  /// görülenle aynıdır.
  void _occluded(Canvas canvas, Offset c, double radius, [double s = 1]) {
    if (radius <= 0 || s <= 0) return;
    if (!_view.overlaps(Rect.fromCircle(center: c, radius: radius))) return;
    final shape = game.level.visibility(c, radius);
    if (shape == null) {
      // Hiçbir yerde kaya yok: düz daire (daha ucuz).
      _light(canvas, c, radius, s);
      return;
    }
    if (!SoftEdge.on) {
      canvas.save();
      canvas.clipPath(shape);
      _light(canvas, c, radius, s);
      canvas.restore();
      return;
    }
    // Kayanın gölgesi keskin bir çizgiyle değil, yarı gölgeyle başlar:
    // ışık birkaç komşu noktadan gelir, her biri kendi gölgesini düşürür;
    // gölge kenarı uzaklaştıkça genişleyen yumuşak bir geçiş olur.
    final spread = (radius * 0.05).clamp(6.0, 12.0);
    const n = 6;
    final each = math.min(1.0, s * 1.5 / n);
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n + 0.3;
      final o = c + Offset(math.cos(a), math.sin(a)) * spread;
      final sh = game.level.visibility(o, radius);
      if (sh == null) {
        _light(canvas, o, radius, each);
        continue;
      }
      canvas.save();
      canvas.clipPath(sh);
      _light(canvas, o, radius, each);
      canvas.restore();
    }
  }

  /// Karanlık bölgeler örtünün altında daha da kararır; kenarları yumuşak.
  void _darkZones(Canvas canvas, Rect view) {
    for (final z in game.level.darkZones) {
      if (!z.overlaps(view)) continue;
      const edge = 96.0;
      final paint = Paint()
        ..color = shadowInk(game.level.def.theme).withValues(alpha: 0.5);
      canvas.drawRect(z.deflate(edge / 2), paint);
      // Kenarlarda yumuşak geçiş: iç içe birkaç saydam kuşak.
      for (var i = 1; i <= 4; i++) {
        canvas.drawRect(
          z.deflate(edge / 2 - i * edge / 8),
          Paint()
            ..color = shadowInk(game.level.def.theme).withValues(alpha: 0.1),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = game.camera.visibleWorldRect.inflate(80);
    _view = rect;
    SoftEdge.on = SoftEdge.force ?? !Settings.lowGraphics;
    if (Settings.lowGraphics) {
      _renderCheap(canvas, rect);
      return;
    }
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..color = shadowInk(game.level.def.theme).withValues(
          alpha: darknessFor(game.level.def.theme) * (1 - game.lightning),
        ),
    );
    _darkZones(canvas, rect);

    for (final c in game.world.children) {
      switch (c) {
        case Guard g:
          final lantern = g.lanternWorld;
          _light(canvas, lantern.toOffset(), 90, 0.9);
          // Fenerin konisi de karanlığı yarar.
          // Fenerin konisi de karanlığı yarar: kayada kesilir (fener duvarın
          // ardını aydınlatmaz), ucu düz değil, uzaklıkla söner; kenarı
          // yumuşak.
          final range = g.coneRange;
          _cut.shader = ui.Gradient.radial(
            lantern.toOffset(),
            range * 1.12,
            const [Color(0xB0000000), Color(0x60000000), Color(0x00000000)],
            const [0, 0.45, 1],
          );
          final seen = g.coneShape;
          canvas.save();
          if (seen != null) canvas.clipPath(seen);
          SoftEdge.beam(canvas, g.beamShape, _cut);
          canvas.restore();
        case ExitPortal e:
          _light(
            canvas,
            (e.position + Vector2(kTile / 2, kTile)).toOffset(),
            230,
          );
        case MemoryShard m:
          _light(canvas, m.position.toOffset(), 80, 0.8);
        case IronVein v when v.lit || v.melt > 0:
          _light(canvas, v.forge, 90 + 60 * v.melt, 0.7);
        case TulparMount t:
          _light(canvas, t.glowCenter, 80, 0.6);
        case KutCage k when !k.freed:
          _light(canvas, k.glowCenter, 70, 0.6);
        case Calkuyruk c:
          _light(canvas, c.glowCenter, 60, 0.45);
        case Apparition a:
          _light(canvas, a.glowCenter, a.glowRadius, 0.7 * a.alpha);
        case Anvil a:
          _light(canvas, a.glowCenter, 70, 0.55);
        case AkAnaRise a:
          _light(canvas, a.glowCenter, 150, 0.85 * a.alpha);
        case SkiGuide s when s.alpha > 0:
          _light(
            canvas,
            Offset(s.position.x, s.position.y - 20),
            90,
            0.7 * s.alpha,
          );
        case GokboruSpirit g:
          _light(canvas, g.glowCenter, 90, 0.75 * g.alpha);
        case UmayTree u:
          _light(canvas, u.glowCenter, u.glowRadius, 0.45 + 0.4 * u.lit);
        case Bird b:
          _light(canvas, b.position.toOffset().translate(0, -6), 60, 0.6);
        case Gate g:
          for (final at in g.litLamps) {
            _light(canvas, at, 64, 0.55);
          }
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
          SoftEdge.beam(canvas, (k) => w.beamPath(k), _cut);
        case WingsPickup k:
          _light(canvas, k.position.toOffset().translate(0, -10), 110, 0.9);
        case FireVent v when v.burning:
          _light(canvas, v.position.toOffset().translate(0, -40), 120, 0.9);
        case LanternBalloon b:
          _light(canvas, b.lanternAt.toOffset(), 60, 0.8);
        case MedusaHead m when m.eyes > 0.2:
          _light(canvas, m.position.toOffset(), 50, 0.6 * m.eyes);
        case SimurgFeather f when !f.taken:
          _light(canvas, f.position.toOffset(), 50, 0.6);
        case StoneGiant g when !g.fallen:
          _light(canvas, g.ear.toOffset(), 40, 0.5);
        case StarStone s when s.correct:
          _light(canvas, s.position.toOffset().translate(0, -24), 50, 0.6);
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
        case CandleTray t:
          _light(canvas, (t.position + Vector2(kTile, -8)).toOffset(), 70, 0.8);
        case Chandelier c:
          _light(canvas, c.position.toOffset(), 60, 0.5);
        case Semazen s when s.inFront:
          _light(canvas, (s.position - Vector2(0, 30)).toOffset(), 46, 0.35);
        case GreatLamp g:
          _light(canvas, g.position.toOffset(), 90, 0.9);
          canvas.save();
          canvas.translate(g.position.x, g.position.y);
          _cut.shader = ui.Gradient.radial(
            Offset.zero,
            GreatLamp.reach,
            const [Color(0xA0000000), Color(0x80000000), Color(0x00000000)],
            const [0, 0.6, 1],
          );
          canvas.drawPath(g.beamPath(), _cut);
          canvas.restore();
        case LightFlood f when f.awake && !f.dark:
          final top = f.surface - 60;
          if (top < _view.bottom) {
            _cut.shader = ui.Gradient.linear(
              Offset(0, top),
              Offset(0, top + 120),
              const [Color(0x00000000), Color(0xFF000000)],
            );
            canvas.drawRect(
              Rect.fromLTRB(_view.left, top, _view.right, _view.bottom),
              _cut,
            );
          }
        case FireflySwarm f:
          _light(canvas, f.position.toOffset(), 70, 0.7 * f.strength);
        case FireflyLure l:
          _occluded(
            canvas,
            l.position.toOffset(),
            130 * math.max(0.3, l.strength),
            l.strength,
          );
      }
    }
    // Ön plandaki sütunlar ve direkler ışığın önünde durur: üstlerine düşen
    // fener ve kandil ışığı geri örtülür, ışık arkalarından geçiyormuş gibi.
    final shade = Paint()
      ..color = shadowInk(game.level.def.theme).withValues(
        alpha: darknessFor(game.level.def.theme) * 0.85 * (1 - game.lightning),
      );
    for (final col in game.level.frontColumns) {
      if (col.overlaps(rect)) canvas.drawRect(col, shade);
    }
    // Sâye'nin kendi ışığı en son: yanındaki sütunu o aydınlatır.
    final p = game.player;
    if (p != null && p.isMounted && !p.isDead) {
      // Görünen ışık kavanozun çizildiği yerden çıkar (sallanırken de).
      final (_, radius) = p.light;
      _occluded(canvas, p.lightVisual.toOffset(), radius);
    }
    canvas.restore();
  }

  /// Düşük grafik: ara katman olmadan tek geçişte karanlık. Işık yalnızca
  /// oyuncunun çevresinden gelir.
  void _renderCheap(Canvas canvas, Rect rect) {
    final dark = shadowInk(game.level.def.theme)
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
          Paint()
            ..color = shadowInk(game.level.def.theme).withValues(alpha: 0.45),
        );
      }
    }
    final (_, radius) = p.light;
    final c = p.lightVisual.toOffset();
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
    _cheapSignals(canvas);
  }

  /// Düşük grafikte de oynanışı taşıyan ışıklar görünür kalır: Kandilci'nin
  /// konisi, gözcü ve fener huzmeleri, çıkış, ateşböcekleri, güneş huzmesi,
  /// kandil tablaları. Ara katman yerine karanlığın üstüne eklenen (plus)
  /// yumuşak parıltı: ucuz, ama ışığın nereye vurduğu okunur.
  void _cheapSignals(Canvas canvas) {
    void glow(Offset c, double r, Color color, double a) {
      if (a <= 0 || !_view.overlaps(Rect.fromCircle(center: c, radius: r))) {
        return;
      }
      _glow.shader = ui.Gradient.radial(c, r, [
        color.withValues(alpha: a),
        color.withValues(alpha: 0),
      ]);
      canvas.drawCircle(c, r, _glow);
    }

    void beam(Path path, Offset from, Offset to, Color color, double a) {
      if (!_view.overlaps(path.getBounds())) return;
      _glow.shader = ui.Gradient.linear(from, to, [
        color.withValues(alpha: a),
        color.withValues(alpha: 0),
      ]);
      canvas.drawPath(path, _glow);
    }

    const cold = Color(0xFFBFEFE8);
    for (final c in game.world.children) {
      switch (c) {
        case Guard g when !g.falling:
          final l = g.lanternWorld.toOffset();
          final range = g.coneRange;
          final f = g.facing.toDouble();
          glow(l, 70, cold, 0.22);
          beam(
            Path()
              ..moveTo(l.dx, l.dy - 3)
              ..lineTo(l.dx + f * range, l.dy - range * 0.5 - 34)
              ..lineTo(l.dx + f * range, l.dy + range * 0.5 + 34)
              ..lineTo(l.dx, l.dy + 3)
              ..close(),
            l,
            l.translate(f * range, 0),
            cold,
            0.16,
          );
        case Watcher w when w.dazzled <= 0:
          final o = w.lamp.toOffset();
          glow(o, 50, cold, 0.2);
          final path = w.beamPath();
          final b = path.getBounds();
          beam(path, o, b.center, cold, 0.14);
        case LanternBalloon b:
          final o = b.lanternAt.toOffset().translate(0, -10);
          glow(o, 50, kWarmLight, 0.2);
          const len = LanternBalloon.beamLength;
          beam(
            Path()
              ..moveTo(o.dx - 10, o.dy + 10)
              ..lineTo(o.dx + 10, o.dy + 10)
              ..lineTo(o.dx + 10 + len * 0.32, o.dy + len)
              ..lineTo(o.dx - 10 - len * 0.32, o.dy + len)
              ..close(),
            o,
            o.translate(0, len),
            kWarmLight,
            0.14,
          );
        case GreatLamp g:
          final o = g.position.toOffset();
          glow(o, 70, kWarmLight, 0.22);
          beam(
            g.beamPath().shift(o),
            o,
            o.translate(0, GreatLamp.reach * 0.6),
            kWarmLight,
            0.12,
          );
        case ExitPortal e:
          glow(
            (e.position + Vector2(kTile / 2, kTile)).toOffset(),
            150,
            kWarmLight,
            0.22,
          );
        case FireflyLure l:
          glow(
            l.position.toOffset(),
            110 * math.max(0.3, l.strength),
            kWarmLight,
            0.26 * l.strength,
          );
        case FireflySwarm f:
          glow(f.position.toOffset(), 50, kWarmLight, 0.16 * f.strength);
        case MemoryShard m:
          glow(m.position.toOffset(), 56, kWarmLight, 0.16);
        case FireVent v when v.burning:
          glow(v.position.toOffset().translate(0, -40), 90, kWarmLight, 0.2);
        case CandleTray t:
          glow(
            (t.position + Vector2(kTile, -8)).toOffset(),
            56,
            kWarmLight,
            0.16,
          );
        case SunBeam b:
          for (final (a, z) in b.segments) {
            _glowLine
              ..color = kWarmLight.withValues(alpha: 0.12)
              ..strokeWidth = 40;
            canvas.drawLine(a, z, _glowLine);
          }
        case GiantPerde g:
          glow(g.glowCenter, g.glowRadius, kWarmLight, 0.18);
      }
    }
  }

  final _glow = Paint()..blendMode = BlendMode.plus;
  final _glowLine = Paint()
    ..blendMode = BlendMode.plus
    ..strokeCap = StrokeCap.round;
}
