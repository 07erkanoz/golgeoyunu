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
      // Kenar ışığı: ışığa bakan yan, uzaklıkla söner. Yumuşaklık bir
      // geniş-soluk, bir dar-parlak çizgiyle verilir (her çizgiyi ayrı
      // bulanıklaştırmak pahalıydı).
      Paint edge(double a, double width) => Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..shader = ui.Gradient.radial(
          at,
          radius,
          [
            color.withValues(alpha: 0.32 * a),
            color.withValues(alpha: 0.1 * a),
            color.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        );
      final colWide = edge(0.35, 9);
      final colNarrow = edge(0.7, 3);
      for (final col in _columns) {
        if (!col.overlaps(area)) continue;
        final x = at.dx < col.center.dx ? col.left + 2 : col.right - 2;
        canvas.drawLine(Offset(x, col.top), Offset(x, col.bottom), colWide);
        canvas.drawLine(Offset(x, col.top), Offset(x, col.bottom), colNarrow);
      }
      final lipWide = edge(0.35, 7);
      final lipNarrow = edge(0.7, 2.5);
      for (final (x0, x1, y) in _lips) {
        if (x1 < area.left || x0 > area.right) continue;
        if (y < area.top || y > area.bottom) continue;
        canvas.drawLine(Offset(x0, y + 1.5), Offset(x1, y + 1.5), lipWide);
        canvas.drawLine(Offset(x0, y + 1.5), Offset(x1, y + 1.5), lipNarrow);
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

/// Kameranın hemen önünden geçen koyu, bulanık şekiller: tavandan sarkan
/// iri kemerler, zincirler, dipte kırık sütun kütükleri. Oyun katmanından
/// daha hızlı kayar (paralaks), göz derinliği buradan okur.
///
/// Şekiller bir kez, bulanık olarak resme çizilip saklanır; her karede
/// yalnız resim yerine konur (her karede yeniden bulanıklaştırmak telefonu
/// ısıtıyordu).
class NearLayer extends Component with HasGameReference<GolgeGame> {
  NearLayer() : super(priority: 34);

  static const double parallax = 1.45;

  /// Şekillerin çizildiği başvuru yüksekliği (ekran yüksekliğine ölçeklenir).
  static const double _refH = 640;

  static final _ink = Paint()
    ..color = const Color(0xFF0A0706)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final _chainPaint = Paint()
    ..color = const Color(0xFF0A0706)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  /// Saklanan resim ve sol üst köşesinin yerel konumu.
  static (ui.Image, Offset)? _arch;
  static final _stumps = <(ui.Image, Offset)>[];
  static final _chains = <(ui.Image, Offset)>[];

  static (ui.Image, Offset) _bake(Rect bounds, void Function(Canvas) draw) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.translate(-bounds.left, -bounds.top);
    draw(c);
    final img = rec.endRecording().toImageSync(
      bounds.width.ceil(),
      bounds.height.ceil(),
    );
    return (img, bounds.topLeft);
  }

  static void _bakeAll() {
    if (_arch != null) return;
    // Kemer: üstü düz, altı kavisli; yerel (0, 0) ekranın üst ortası.
    const half = 5.0 * kTile;
    const low = _refH * 0.2;
    _arch = _bake(
      const Rect.fromLTRB(-half - 70, -80, half + 70, low + 60),
      (c) => c.drawPath(
        Path()
          ..moveTo(-half - 40, -60)
          ..lineTo(half + 40, -60)
          ..lineTo(half + 40, low + 30)
          ..lineTo(half - 10, low + 30)
          ..quadraticBezierTo(0, -_refH * 0.1, -half + 10, low + 30)
          ..lineTo(-half - 40, low + 30)
          ..close(),
        _ink,
      ),
    );
    // Kütükler: yerel (0, 0) zeminin ortası.
    for (var i = 0; i < 3; i++) {
      const w = 1.8 * kTile;
      final h = _refH * (0.07 + i * 0.02);
      _stumps.add(
        _bake(
          Rect.fromLTRB(-w / 2 - 24, -h - 44, w / 2 + 24, 24),
          (c) => c.drawPath(
            Path()
              ..moveTo(-w / 2, 0)
              ..lineTo(-w / 2, -h)
              ..lineTo(-w * 0.15, -h - 18)
              ..lineTo(w * 0.1, -h + 6)
              ..lineTo(w / 2, -h - 10)
              ..lineTo(w / 2, 0)
              ..close(),
            _ink,
          ),
        ),
      );
    }
    // Zincirler: yerel (0, 0) ekranın üstü; ucunda ağırlık.
    for (var i = 0; i < 4; i++) {
      final len = _refH * (0.16 + i * 0.04);
      _chains.add(
        _bake(Rect.fromLTRB(-40, -20, 40, len + 50), (c) {
          var y = -10.0;
          var k = 0;
          while (y < len) {
            if (k.isEven) {
              c.drawOval(Rect.fromLTWH(-12, y, 24, 32), _chainPaint);
            } else {
              c.drawLine(Offset(0, y + 2), Offset(0, y + 30), _chainPaint);
            }
            y += 26;
            k++;
          }
          c.drawCircle(Offset(0, len + 14), 20, _ink);
        }),
      );
    }
  }

  static final _imgPaint = Paint()..filterQuality = FilterQuality.medium;

  void _put(Canvas canvas, (ui.Image, Offset) shape, Offset at, double k) {
    final (img, origin) = shape;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(k);
    canvas.drawImage(img, origin, _imgPaint);
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    if (!realismHere(game)) return;
    _bakeAll();
    final cam = game.camera.viewfinder.position;
    final view = game.camera.visibleWorldRect;
    final lv = game.level;
    final k = view.height / _refH;
    // Dünyadaki yeri x olan şeyin bu katmandaki yeri.
    double near(double x) => cam.x + (x - cam.x) * parallax;
    final span = view.width * 1.2;
    const archEvery = 21 * kTile;
    final first = ((cam.x - span) / archEvery).floor();
    for (var i = first; i * archEvery < cam.x + span; i++) {
      final x = near(i * archEvery + 7.0 * kTile);
      if (x < view.left - 400 || x > view.right + 400) continue;
      _put(canvas, _arch!, Offset(x, view.top), k);
    }
    const stumpEvery = 19 * kTile;
    final firstS = ((cam.x - span) / stumpEvery).floor();
    final floor = math.min(view.bottom, lv.pixelHeight.toDouble()) + 20;
    for (var i = firstS; i * stumpEvery < cam.x + span; i++) {
      final x = near(i * stumpEvery + 15.0 * kTile);
      if (x < view.left - 200 || x > view.right + 200) continue;
      _put(canvas, _stumps[i % 3], Offset(x, floor), k);
    }
    const chainEvery = 17 * kTile;
    final firstC = ((cam.x - span) / chainEvery).floor();
    for (var i = firstC; i * chainEvery < cam.x + span; i++) {
      final x = near(i * chainEvery + 13.0 * kTile);
      if (x < view.left - 60 || x > view.right + 60) continue;
      _put(canvas, _chains[i % 4], Offset(x, view.top), k);
    }
  }
}
