// Görsel deneme: ışık ve derinlik (Yerebatan). Bkz. [Realism].
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'creatures.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';
import 'terrain.dart';
import '../settings.dart';

/// Bu bölümde ışık ve derinlik denemesi çizilsin mi.
bool realismHere(GolgeGame game) =>
    Realism.on &&
    !Settings.lowGraphics &&
    game.level.def.theme == LevelTheme.cistern;

const _cyan = Color(0xFF5AEBDC);
const _amber = Color(0xFFFFB050);

/// Işığa bakan taş kenarları ve ışıkların çevresine taşan parlama: karanlık
/// katmanının üstüne eklenir (ışık topluyormuş gibi).
class RealismLayer extends Component with HasGameReference<GolgeGame> {
  RealismLayer() : super(priority: 42);

  /// Işık alabilen kenarlar: sütunların iki yanı ve basılabilir taşların
  /// üst dudağı (bölüm başına bir kez).
  final _columns = <Rect>[];
  final _lips = <(double, double, double)>[];

  @override
  void onMount() {
    super.onMount();
    final lv = game.level;
    _columns
      ..addAll(lv.frontColumns)
      ..addAll(cisternBackColumns(lv));
    for (var r = 1; r < lv.height; r++) {
      int? start;
      for (var c = 0; c <= lv.width; c++) {
        final edge = c < lv.width && lv.solid(c, r) && !lv.solid(c, r - 1);
        if (edge && start == null) start = c;
        if (!edge && start != null) {
          _lips.add((
            start * kTile.toDouble(),
            c * kTile.toDouble(),
            r * kTile.toDouble(),
          ));
          start = null;
        }
      }
    }
  }

  /// Görünen ışıklar: Kandilci fenerleri, Gözcüler, Sâye'nin kavanozu.
  List<(Offset, Color, double)> _lights(Rect view) {
    final out = <(Offset, Color, double)>[];
    for (final c in game.world.children) {
      switch (c) {
        case Guard g:
          final l = g.lanternWorld.toOffset();
          if (view.inflate(300).contains(l)) out.add((l, _cyan, 320));
        case Watcher w:
          final l = w.lamp.toOffset();
          if (view.inflate(300).contains(l)) out.add((l, _cyan, 300));
      }
    }
    final p = game.player;
    if (p != null && p.isMounted && !p.isDead) {
      final strength = p.crouching ? 0.35 : 1.0;
      out.add((p.lightVisual.toOffset(), _amber, 230 * strength));
    }
    return out;
  }

  @override
  void render(Canvas canvas) {
    if (!realismHere(game)) return;
    final view = game.camera.visibleWorldRect;
    for (final (at, color, radius) in _lights(view)) {
      final area = Rect.fromCircle(center: at, radius: radius);
      // Kenar ışığı: ışığa bakan yan, uzaklıkla söner (yumuşak, bulanık).
      final edge = Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
        ..shader = ui.Gradient.radial(
          at,
          radius,
          [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        );
      edge.strokeWidth = 5;
      for (final col in _columns) {
        if (!col.overlaps(area)) continue;
        final x = at.dx < col.center.dx ? col.left + 2 : col.right - 2;
        canvas.drawLine(Offset(x, col.top), Offset(x, col.bottom), edge);
      }
      edge.strokeWidth = 3.5;
      for (final (x0, x1, y) in _lips) {
        if (x1 < area.left || x0 > area.right) continue;
        if (y < area.top || y > area.bottom) continue;
        canvas.drawLine(Offset(x0, y + 1.5), Offset(x1, y + 1.5), edge);
      }
      // Yüzey: ışık taşın üstüne yumuşakça yayılır (koyular koyu kalır).
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..blendMode = BlendMode.softLight
          ..shader = ui.Gradient.radial(at, radius, [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0),
          ]),
      );
      // Parlama: ışık kaynağın çevresine hafifçe taşar.
      canvas.drawCircle(
        at,
        radius * 0.16,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(
            at,
            radius * 0.16,
            [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.06),
              color.withValues(alpha: 0),
            ],
            const [0, 0.4, 1],
          ),
      );
    }
  }
}

/// Kameranın hemen önünden geçen koyu, bulanık şekiller: iri sütunlar,
/// tavandan sarkan zincirler, dipte yıkık taşlar. Oyun katmanından daha
/// hızlı kayar (paralaks), göz derinliği buradan okur.
class NearLayer extends Component with HasGameReference<GolgeGame> {
  NearLayer() : super(priority: 34);

  static const double parallax = 1.45;

  static final _ink = Paint()
    ..color = const Color(0xFF0A0706)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final _chain = Paint()
    ..color = const Color(0xFF0A0706)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  @override
  void render(Canvas canvas) {
    if (!realismHere(game)) return;
    final cam = game.camera.viewfinder.position;
    final view = game.camera.visibleWorldRect;
    final lv = game.level;
    // Dünyadaki yeri x olan şeyin bu katmandaki yeri.
    double near(double x) => cam.x + (x - cam.x) * parallax;
    final span = view.width * 1.2;
    // Tavandan sarkan iri kemerler: oyun bandının üstünde kalır.
    const archEvery = 21 * kTile;
    final first = ((cam.x - span) / archEvery).floor();
    final archLow = view.top + view.height * 0.2;
    for (var i = first; i * archEvery < cam.x + span; i++) {
      final x = near(i * archEvery + 7.0 * kTile);
      if (x < view.left - 400 || x > view.right + 400) continue;
      final half = 5.0 * kTile;
      canvas.drawPath(
        Path()
          ..moveTo(x - half - 40, view.top - 60)
          ..lineTo(x + half + 40, view.top - 60)
          ..lineTo(x + half + 40, archLow + 30)
          ..lineTo(x + half - 10, archLow + 30)
          ..quadraticBezierTo(
            x,
            view.top - view.height * 0.1,
            x - half + 10,
            archLow + 30,
          )
          ..lineTo(x - half - 40, archLow + 30)
          ..close(),
        _ink,
      );
    }
    // Dipte kırık sütun kütükleri: oyun bandının altında kalır.
    const stumpEvery = 19 * kTile;
    final firstS = ((cam.x - span) / stumpEvery).floor();
    final floor = math.min(view.bottom, lv.pixelHeight.toDouble()) + 20;
    for (var i = firstS; i * stumpEvery < cam.x + span; i++) {
      final x = near(i * stumpEvery + 15.0 * kTile);
      if (x < view.left - 200 || x > view.right + 200) continue;
      final w = 1.8 * kTile;
      final h = view.height * (0.07 + (i % 3) * 0.02);
      canvas.drawPath(
        Path()
          ..moveTo(x - w / 2, floor)
          ..lineTo(x - w / 2, floor - h)
          ..lineTo(x - w * 0.15, floor - h - 18)
          ..lineTo(x + w * 0.1, floor - h + 6)
          ..lineTo(x + w / 2, floor - h - 10)
          ..lineTo(x + w / 2, floor)
          ..close(),
        _ink,
      );
    }
    // Zincirler: tavandan sarkan, ucunda ağırlık.
    const chainEvery = 17 * kTile;
    final firstC = ((cam.x - span) / chainEvery).floor();
    for (var i = firstC; i * chainEvery < cam.x + span; i++) {
      final x = near(i * chainEvery + 13.0 * kTile);
      if (x < view.left - 60 || x > view.right + 60) continue;
      final len = view.height * (0.16 + (i % 4) * 0.04);
      var y = view.top - 10;
      var k = 0;
      while (y < view.top + len) {
        if (k.isEven) {
          canvas.drawOval(Rect.fromLTWH(x - 12, y, 24, 32), _chain);
        } else {
          canvas.drawLine(Offset(x, y + 2), Offset(x, y + 30), _chain);
        }
        y += 26;
        k++;
      }
      canvas.drawCircle(Offset(x, view.top + len + 14), 20, _ink);
    }
  }
}
