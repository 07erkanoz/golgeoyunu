// Görsel deneme: ışık ve derinlik (Yerebatan). Bkz. [Realism].
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'creatures.dart';
import 'entities.dart';
import 'fairy_chimney.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';
import 'terrain.dart';
import '../settings.dart';

/// Işık ve derinliğin çizildiği bölüm türleri.
enum DepthKind { cistern, snow, peri, konya }

/// Bu bölümün derinlik türü (yoksa null: kayak bölümleri ve henüz
/// denenmeyenler).
DepthKind? depthKind(Level lv) => switch (lv.def.theme) {
  LevelTheme.cistern => DepthKind.cistern,
  LevelTheme.snow when lv.def.skiSurface == null => DepthKind.snow,
  LevelTheme.peri => DepthKind.peri,
  LevelTheme.konya => DepthKind.konya,
  _ => null,
};

/// Bu bölümde ışık ve derinlik denemesi çizilsin mi.
bool realismHere(GolgeGame game) =>
    Realism.on && !Settings.lowGraphics && depthKind(game.level) != null;

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
    if (lv.def.theme == LevelTheme.cistern) {
      _columns
        ..addAll(lv.frontColumns)
        ..addAll(cisternBackColumns(lv));
    }
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

/// Saklanan bir şekil: resim ve sol üst köşesinin yerel konumu.
typedef _Shape = (ui.Image, Offset);

/// Yakın şeklin dayandığı yer: ekranın üstü, ekranın dibi ya da Sâye'nin
/// yürüdüğü çizginin hemen önü.
enum _Anchor { top, bottom, ground }

/// Yakın katmanda aralıklarla dizilen bir şekil sırası.
class _Row {
  const _Row(this.shapes, this.every, this.phase, {this.at = _Anchor.top});

  final List<_Shape> shapes;

  /// Dünyada kaç karede bir (kare = kTile).
  final double every;
  final double phase;

  final _Anchor at;
}

/// Kameranın hemen önünden geçen koyu, bulanık şekiller (Yerebatan'da
/// tavandan sarkan kemerler, zincirler, kırık sütun kütükleri; karda çam
/// dalları, kar yığınları; Kapadokya'da önden geçen peri bacaları; Konya'da
/// saçak, kandil, korkuluk). Oyun katmanından daha hızlı kayar (paralaks),
/// göz derinliği buradan okur. Karda kameraya yakın iri, bulanık kar
/// taneleri, Kapadokya'da sıcak toz da bu katmandadır.
///
/// Şekiller bir kez, bulanık olarak resme çizilip saklanır; her karede
/// yalnız resim yerine konur (her karede yeniden bulanıklaştırmak telefonu
/// ısıtıyordu).
class NearLayer extends Component with HasGameReference<GolgeGame> {
  NearLayer() : super(priority: 34);

  static const double parallax = 1.45;

  /// Şekillerin çizildiği başvuru yüksekliği (ekran yüksekliğine ölçeklenir).
  static const double _refH = 640;

  static Paint _inkOf(Color c, [double blur = 6]) => Paint()
    ..color = c
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  static Paint _lineOf(Color c, double width, [double blur = 3]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

  static final _rows = <DepthKind, List<_Row>>{};
  static _Shape? _flake;
  static _Shape? _mote;

  double _t = 0;

  static _Shape _bake(Rect bounds, void Function(Canvas) draw) {
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

  static List<_Row> _rowsOf(DepthKind kind) => _rows.putIfAbsent(
    kind,
    () => switch (kind) {
      DepthKind.cistern => _cistern(),
      DepthKind.snow => _snow(),
      DepthKind.peri => _peri(),
      DepthKind.konya => _konya(),
    },
  );

  // ------------------------------------------------------------ Yerebatan

  static List<_Row> _cistern() {
    const ink = Color(0xFF0A0706);
    final fill = _inkOf(ink);
    final chain = _lineOf(ink, 7);
    // Kemer: üstü düz, altı kavisli; yerel (0, 0) ekranın üst ortası.
    const half = 5.0 * kTile;
    const low = _refH * 0.2;
    final arch = _bake(
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
        fill,
      ),
    );
    // Kütükler: yerel (0, 0) zeminin ortası.
    final stumps = [
      for (var i = 0; i < 3; i++)
        () {
          const w = 1.8 * kTile;
          final h = _refH * (0.07 + i * 0.02);
          return _bake(
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
              fill,
            ),
          );
        }(),
    ];
    // Zincirler: yerel (0, 0) ekranın üstü; ucunda ağırlık.
    final chains = [
      for (var i = 0; i < 4; i++)
        () {
          final len = _refH * (0.16 + i * 0.04);
          return _bake(Rect.fromLTRB(-40, -20, 40, len + 50), (c) {
            _chain(c, len, chain);
            c.drawCircle(Offset(0, len + 14), 20, fill);
          });
        }(),
    ];
    return [
      _Row([arch], 21, 7),
      _Row(stumps, 19, 15, at: _Anchor.bottom),
      _Row(chains, 17, 13),
    ];
  }

  static void _chain(Canvas c, double len, Paint paint) {
    var y = -10.0;
    var k = 0;
    while (y < len) {
      if (k.isEven) {
        c.drawOval(Rect.fromLTWH(-12, y, 24, 32), paint);
      } else {
        c.drawLine(Offset(0, y + 2), Offset(0, y + 30), paint);
      }
      y += 26;
      k++;
    }
  }

  // ------------------------------------------------------------ kar

  static List<_Row> _snow() {
    const ink = Color(0xFF020305);
    const snow = Color(0xFFB4BFD0);
    final fill = _inkOf(ink);
    final white = _inkOf(snow, 5);
    final limb = _lineOf(ink, 16, 5);
    final stalk = _lineOf(ink, 4, 2.5);
    // Kar yüklü çam dalı: ekranın üstünden çapraz sarkar; boyunca aşağı
    // dönük ince dallar ve iğneler, üstünde düzensiz kar öbekleri.
    final twig = _lineOf(ink, 5, 2.5);
    final needle = _lineOf(ink, 3, 2);
    double hash(double v) => (math.sin(v * 12.9898) * 43758.5453) % 1;
    _Shape branch(bool flip) =>
        _bake(const Rect.fromLTRB(-760, -140, 760, 720), (c) {
          c.scale(flip ? -1.7 : 1.7, 1.7);
          final bough = Path()
            ..moveTo(-420, -60)
            ..quadraticBezierTo(-90, 70, 340, 250);
          c.drawPath(bough, limb);
          for (final m in bough.computeMetrics()) {
            for (var d = 30.0; d < m.length - 6; d += 24) {
              final t = m.getTangentForOffset(d)!;
              final s = 1.3 - d / m.length * 0.7;
              final dir = t.angle + 1.0 + hash(d) * 0.4;
              final len = (55 + hash(d + 1) * 30) * s;
              final a = t.position;
              final b = a + Offset(math.cos(dir), math.sin(dir)) * len;
              c.drawLine(a, b, twig);
              // İğneler: dalın iki yanına aşağı doğru kısa çizgiler.
              for (var n = 0.15; n < 1; n += 0.14) {
                final at = Offset.lerp(a, b, n)!;
                final l = (16 + hash(d + n) * 10) * s * (1.1 - n * 0.5);
                for (final side in const [-0.7, 0.7]) {
                  final an = dir + side + 0.5;
                  c.drawLine(
                    at,
                    at + Offset(math.cos(an), math.sin(an)) * l,
                    needle,
                  );
                }
              }
              // Kar: dalın üstünde yassı, düzensiz öbekler.
              if (hash(d + 7) < 0.7) {
                c.drawOval(
                  Rect.fromCenter(
                    center: a + Offset(4, -6 * s),
                    width: (34 + hash(d + 3) * 30) * s,
                    height: (9 + hash(d + 5) * 6) * s,
                  ),
                  white,
                );
              }
            }
          }
        });
    // Kar yığını: önden geçen engebeli tümsek; gövdesi koyu (yüzü
    // ışıksız), üstünde ay ışığı alan kar, içinden kara bir taş ve kuru
    // otlar çıkar. Gövde aşağı uzar: zeminin önünde kesik kenar görünmez.
    _Shape drift(int i) {
      final w = 170.0 + i * 50;
      final h = 40.0 + i * 16;
      return _bake(Rect.fromLTRB(-w - 40, -h - 100, w + 40, 200), (c) {
        c.saveLayer(Rect.fromLTRB(-w - 40, -h - 100, w + 40, 200), Paint());
        final hump = Path()
          ..moveTo(-w, 200)
          ..lineTo(-w, 10)
          ..quadraticBezierTo(-w * 0.75, -h * 0.9, -w * 0.4, -h * 0.55)
          ..quadraticBezierTo(-w * 0.05, -h * 1.5, w * 0.35, -h * 0.7)
          ..quadraticBezierTo(w * 0.7, -h * 0.35, w, 10)
          ..lineTo(w, 200)
          ..close();
        c.drawPath(hump, fill);
        // Kar kabuğu: tümseğin sırtı boyunca ince açık şerit.
        c.save();
        c.clipPath(hump);
        c.drawPath(
          hump.shift(const Offset(0, 14)),
          Paint()
            ..color = ink
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        c.restore();
        c.save();
        c.clipPath(hump);
        c.drawRect(
          Rect.fromLTRB(-w, -h * 1.6, w, 40),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, -h * 1.5),
              const Offset(0, 30),
              [snow.withValues(alpha: 0.55), snow.withValues(alpha: 0)],
            ),
        );
        c.restore();
        c.drawPath(
          Path()
            ..moveTo(w * 0.05, 20)
            ..lineTo(w * 0.12, -h * 0.95)
            ..lineTo(w * 0.3, -h * 1.15)
            ..lineTo(w * 0.42, 20)
            ..close(),
          fill,
        );
        for (var k = 0; k < 6; k++) {
          final x = -w * 0.55 + k * 14.0;
          c.drawLine(
            Offset(x, -h * 0.6),
            Offset(x + (k - 2.5) * 10, -h * 0.6 - 46 - (k % 2) * 24),
            stalk,
          );
        }
        // Gövde zeminin altına doğru erir (zeminden koyu kutu kalmasın).
        c.drawRect(
          Rect.fromLTRB(-w - 40, -h - 100, w + 40, 200),
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.linear(
              const Offset(0, 20),
              const Offset(0, 150),
              [const Color(0xFF000000), const Color(0x00000000)],
            ),
        );
        c.restore();
      });
    }

    return [
      _Row([branch(false), branch(true)], 23, 9),
      _Row([drift(0), drift(1), drift(2)], 17, 5, at: _Anchor.ground),
    ];
  }

  // ------------------------------------------------------------ Kapadokya

  static List<_Row> _peri() {
    // Kameraya yakın, gölgede kalan koyu toprak renkli peri bacaları
    // (arka plandakilerle aynı biçim), bulanık.
    const tones = ChimneyTones(
      Color(0xFF4A3A30),
      Color(0xFF261C16),
      Color(0xFF16100C),
    );
    _Shape chimney(int seed, double h, int peaks) =>
        _bake(Rect.fromLTRB(-h * 1.3, -h * 1.15, h * 1.3, 40), (c) {
          drawFairyCluster(
            c,
            const Offset(0, 30),
            h,
            tones,
            math.Random(seed),
            peaks: peaks,
            openings: 0.3,
            blur: 6,
          );
        });
    return [
      _Row(
        [
          chimney(3, _refH * 0.6, 1),
          chimney(5, _refH * 0.42, 2),
          chimney(8, _refH * 0.52, 3),
        ],
        26,
        11,
        at: _Anchor.bottom,
      ),
    ];
  }

  // ------------------------------------------------------------ Konya

  static List<_Row> _konya() {
    const ink = Color(0xFF06070C);
    const ice = Color(0xFF7C8AA2);
    const warm = Color(0xFFFFB060);
    final fill = _inkOf(ink);
    final pale = _inkOf(ice.withValues(alpha: 0.55), 4);
    final chain = _lineOf(ink, 6);
    final rail = _lineOf(ink, 9, 4);
    // Saçak: ahşap çatı kenarı, kiriş uçları, sarkan buz sarkıtları.
    final eave = _bake(const Rect.fromLTRB(-240, -80, 240, 150), (c) {
      c.drawRect(const Rect.fromLTRB(-220, -60, 220, 42), fill);
      for (var x = -200.0; x <= 200; x += 36) {
        c.drawRect(Rect.fromLTWH(x - 7, 40, 14, 18), fill);
      }
      for (var x = -190.0; x <= 190; x += 23) {
        final len = 22 + (x * 7 % 40).abs();
        c.drawPath(
          Path()
            ..moveTo(x - 5, 56)
            ..lineTo(x + 5, 56)
            ..lineTo(x, 56 + len)
            ..close(),
          pale,
        );
      }
    });
    // Kandil: zincirde asılı, camından sıcak ışık sızar.
    final lamps = [
      for (var i = 0; i < 2; i++)
        () {
          final len = _refH * (0.14 + i * 0.07);
          return _bake(Rect.fromLTRB(-50, -20, 50, len + 90), (c) {
            _chain(c, len, chain);
            c.drawPath(
              Path()
                ..moveTo(-16, len + 6)
                ..lineTo(16, len + 6)
                ..lineTo(26, len + 50)
                ..lineTo(-26, len + 50)
                ..close(),
              fill,
            );
            c.drawRect(
              Rect.fromLTWH(-12, len + 16, 24, 26),
              Paint()
                ..color = warm.withValues(alpha: 0.75)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            );
            c.drawOval(Rect.fromLTWH(-20, len + 48, 40, 14), fill);
          });
        }(),
    ];
    // Korkuluk: alçak, karlı ahşap parmaklık.
    final railing = _bake(const Rect.fromLTRB(-200, -130, 200, 30), (c) {
      c.drawRect(const Rect.fromLTRB(-180, -30, 180, 20), fill);
      c.drawLine(const Offset(-180, -100), const Offset(180, -100), rail);
      for (var x = -180.0; x <= 180; x += 60) {
        c.drawLine(Offset(x, -100), Offset(x, -30), rail);
        if (x < 180) {
          c.drawLine(Offset(x, -100), Offset(x + 60, -30), rail);
          c.drawLine(Offset(x + 60, -100), Offset(x, -30), rail);
        }
      }
      c.drawRRect(
        RRect.fromLTRBR(-184, -110, 184, -102, const Radius.circular(4)),
        pale,
      );
    });
    return [
      _Row([eave], 25, 6),
      _Row(lamps, 19, 14),
      _Row([railing], 21, 3, at: _Anchor.ground),
    ];
  }

  // ------------------------------------------------------------ zerreler

  /// Kameraya yakın kar tanesi: yumuşak, bulanık, açık renk bir benek.
  static _Shape get _flakeShape => _flake ??= _bake(
    const Rect.fromLTRB(-24, -24, 24, 24),
    (c) => c.drawCircle(
      Offset.zero,
      11,
      Paint()
        ..color = const Color(0xFFE6ECF5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    ),
  );

  /// Kapadokya tozu: küçük, sıcak.
  static _Shape get _moteShape => _mote ??= _bake(
    const Rect.fromLTRB(-12, -12, 12, 12),
    (c) => c.drawCircle(
      Offset.zero,
      4,
      Paint()
        ..color = const Color(0xFFFFC890)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    ),
  );

  static final _imgPaint = Paint()..filterQuality = FilterQuality.medium;
  final _dotPaint = Paint()..filterQuality = FilterQuality.medium;

  void _put(Canvas canvas, _Shape shape, Offset at, double k, [Paint? paint]) {
    final (img, origin) = shape;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(k);
    canvas.drawImage(img, origin, paint ?? _imgPaint);
    canvas.restore();
  }

  /// Sâye'nin ayaklarının yumuşatılmış yüksekliği (zıplayınca yakın
  /// şekiller sıçramasın diye yavaş izler).
  double? _ground;

  @override
  void update(double dt) {
    _t += dt;
    final p = game.player;
    if (p == null || !p.isMounted || p.isDead) return;
    final feet = p.position.y + p.size.y;
    final g = _ground;
    _ground = g == null ? feet : g + (feet - g) * math.min(1, dt * 1.5);
  }

  @override
  void render(Canvas canvas) {
    if (!realismHere(game)) return;
    final kind = depthKind(game.level)!;
    final cam = game.camera.viewfinder.position;
    final view = game.camera.visibleWorldRect;
    final lv = game.level;
    final k = view.height / _refH;
    // Dünyadaki yeri x olan şeyin bu katmandaki yeri.
    double near(double x) => cam.x + (x - cam.x) * parallax;
    final span = view.width * 1.2;
    final floor = math.min(view.bottom, lv.pixelHeight.toDouble()) + 20;
    // Sâye'nin yürüdüğü çizgi, kameraya yakın katmana izdüşürülmüş
    // (yakın şey ekranda daha aşağıda görünür).
    final ground = cam.y + ((_ground ?? cam.y) - cam.y) * parallax + 8 * k;
    for (final row in _rowsOf(kind)) {
      final every = row.every * kTile;
      final first = ((cam.x - span) / every).floor();
      final y = switch (row.at) {
        _Anchor.top => view.top,
        _Anchor.bottom => floor,
        _Anchor.ground => ground,
      };
      for (var i = first; i * every < cam.x + span; i++) {
        final x = near(i * every + row.phase * kTile);
        if (x < view.left - 400 * k || x > view.right + 400 * k) continue;
        final shape = row.shapes[i % row.shapes.length];
        _put(canvas, shape, Offset(x, y), k);
        if (kind == DepthKind.konya && row.shapes.length == 2) {
          _lampGlow(canvas, x, view.top, k, i % 2);
        }
      }
    }
    switch (kind) {
      case DepthKind.snow || DepthKind.konya:
        _dots(canvas, view, cam.x, k, _flakeShape, 26, 70, 0.55, -18);
      case DepthKind.peri:
        _dots(canvas, view, cam.x, k, _moteShape, 30, -14, 0.8, 10);
      case DepthKind.cistern:
        break;
    }
  }

  /// Kandil camının çevresine taşan sıcak ışık.
  void _lampGlow(Canvas canvas, double x, double top, double k, int i) {
    final at = Offset(x, top + (_refH * (0.14 + i * 0.07) + 29) * k);
    final r = 110 * k;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(at, r, const [
          Color(0x30FFB060),
          Color(0x00FFB060),
        ]),
    );
  }

  /// Kameraya yakın zerreler (kar ya da toz): ekranda süzülür, kamera
  /// kayınca oyun katmanından hızlı kayar.
  void _dots(
    Canvas canvas,
    Rect view,
    double camX,
    double k,
    _Shape shape,
    int count,
    double fall,
    double alpha,
    double wind,
  ) {
    final w = view.width + 200 * k;
    final h = view.height + 200 * k;
    for (var i = 0; i < count; i++) {
      final a = (i * 0.618034) % 1;
      final b = (i * 0.414214 + 0.3) % 1;
      final size = 0.45 + ((i * 0.7548) % 1) * 1.1;
      final speed = 0.6 + size * 0.5;
      final sx =
          (a * w + (wind * _t - camX * 0.6) * speed * k + 1e6 * w) % w +
          math.sin(_t * 0.8 + i) * 20 * k;
      final sy = (b * h + fall * _t * speed * k + 1e6 * h) % h;
      _dotPaint.color = Color.fromRGBO(
        255,
        255,
        255,
        alpha * (0.4 + size * 0.45).clamp(0, 1),
      );
      _put(
        canvas,
        shape,
        Offset(view.left - 100 * k + sx, view.top - 100 * k + sy),
        k * size,
        _dotPaint,
      );
    }
  }
}
