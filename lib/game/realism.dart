// Görsel deneme: ışık ve derinlik (Yerebatan). Bkz. [Realism].
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'creatures.dart';
import 'erlik.dart' show Kormos;
import 'entities.dart';
import 'fairy_chimney.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'nemrut.dart' show StoneGiant;
import 'palette.dart';
import 'terrain.dart';
import 'winter.dart' show Wolf;
import '../settings.dart';

/// Işık ve derinliğin çizildiği bölüm türleri.
enum DepthKind {
  cistern,
  snow,
  peri,
  konya,
  cliffs,
  sky,
  kaf,
  ark,
  nemrut,
  cave,
  underworld,
  ergenekon,
  heavens,
}

/// Bu bölümün derinlik türü (kayak bölümlerinde yok: hız ve okunurluk).
DepthKind? depthKind(Level lv) => switch (lv.def.theme) {
  LevelTheme.cistern => DepthKind.cistern,
  LevelTheme.snow when lv.def.skiSurface != null => null,
  LevelTheme.snow => DepthKind.snow,
  LevelTheme.peri => DepthKind.peri,
  LevelTheme.konya => DepthKind.konya,
  LevelTheme.cliffs => DepthKind.cliffs,
  LevelTheme.sky => DepthKind.sky,
  LevelTheme.kaf => DepthKind.kaf,
  LevelTheme.ark => DepthKind.ark,
  LevelTheme.nemrut => DepthKind.nemrut,
  LevelTheme.cave => DepthKind.cave,
  LevelTheme.underworld => DepthKind.underworld,
  LevelTheme.ergenekon => DepthKind.ergenekon,
  LevelTheme.heavens => DepthKind.heavens,
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
    if (!realismHere(game) || Realism.debugNoLight) return;
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
      // Yüzey: ışık taşın üstüne yumuşakça yayılır. "Screen" karışımı
      // ekran kartında doğrudan yapılır (softLight her ışık için ekranı
      // kopyalatıyordu).
      final glowR = radius * 0.7;
      canvas.drawCircle(
        at,
        glowR,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = ui.Gradient.radial(at, glowR, [
            color.withValues(alpha: 0.09),
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
  const _Row(
    this.shapes,
    this.every,
    this.phase, {
    this.at = _Anchor.top,
    this.glows,
    this.drop = 0,
  });

  final List<_Shape> shapes;

  /// Dünyada kaç karede bir (kare = kTile).
  final double every;
  final double phase;

  final _Anchor at;

  /// Her şeklin (sırayla) sıcak ışık saçan noktası, şeklin yerel
  /// biriminde (fener camı gibi); yoksa null.
  final List<Offset>? glows;

  /// Üste asılı şeklin ekranın üstünden ne kadar aşağıda başladığı
  /// (başvuru biriminde; iç mekânda koyu tavan bandından aşağı insin diye).
  final double drop;
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
  static final _dotCache = <int, _Shape>{};

  /// Renkli, yumuşak küçük zerre (toz, kıvılcım, ışık).
  static _Shape _dot(Color color, double r) =>
      _dotCache.putIfAbsent(color.toARGB32() ^ r.hashCode, () {
        final e = r * 3;
        return _bake(
          Rect.fromLTRB(-e, -e, e, e),
          (c) => c.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..color = color
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7),
          ),
        );
      });

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

  static List<_Row> _rowsOf(DepthKind kind) =>
      _rows.putIfAbsent(kind, () => _withRim(kind, _buildRows(kind)));

  /// Koyu ortamda kenar ışığı şeklin resmine bir kez işlenir (her karede
  /// ikinci bir renkli kopya çizmek pahalıydı).
  static List<_Row> _withRim(DepthKind kind, List<_Row> rows) {
    final rim = _rimOf(kind);
    if (rim == null) return rows;
    final tint = Paint()..colorFilter = ColorFilter.mode(rim, BlendMode.srcIn);
    _Shape lit(_Shape shape) {
      final (img, origin) = shape;
      final bounds = Rect.fromLTWH(
        origin.dx - 3,
        origin.dy - 4,
        img.width + 3.0,
        img.height + 4.0,
      );
      final out = _bake(bounds, (c) {
        c.drawImage(img, origin.translate(-3, -4), tint);
        c.drawImage(img, origin, Paint());
      });
      img.dispose();
      return out;
    }

    return [
      for (final r in rows)
        _Row(
          [for (final sh in r.shapes) lit(sh)],
          r.every,
          r.phase,
          at: r.at,
          glows: r.glows,
          drop: r.drop,
        ),
    ];
  }

  static List<_Row> _buildRows(DepthKind kind) => switch (kind) {
    DepthKind.cistern => _cistern(),
    DepthKind.snow => _snow(),
    DepthKind.peri => _peri(),
    DepthKind.konya => _konya(),
    DepthKind.cliffs => _cliffs(),
    DepthKind.sky => _sky(),
    DepthKind.kaf => _kaf(),
    DepthKind.ark => _ark(),
    DepthKind.nemrut => _nemrut(),
    DepthKind.cave => _cave(),
    DepthKind.underworld => _underworld(),
    DepthKind.ergenekon => _ergenekon(),
    DepthKind.heavens => _heavens(),
  };

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
      _Row(
        lamps,
        19,
        14,
        glows: [
          for (var i = 0; i < 2; i++) Offset(0, _refH * (0.14 + i * 0.07) + 29),
        ],
      ),
      _Row([railing], 21, 3, at: _Anchor.ground),
    ];
  }

  // ------------------------------------------------------------ ortak parçalar

  /// Zemine oturan şekil: gövdesi aşağı uzar ve zeminin altında erir
  /// (koyu zeminin önünde kesik kenarlı kutu kalmasın).
  static _Shape _bakeGround(Rect bounds, void Function(Canvas) draw) =>
      _bake(bounds, (c) {
        c.saveLayer(bounds, Paint());
        draw(c);
        c.drawRect(
          bounds,
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

  /// Tavandan sarkan sivri kaya dişleri (sarkıtlar).
  static _Shape _stalactites(Color ink, int seed) {
    final r = math.Random(seed);
    return _bake(const Rect.fromLTRB(-300, -90, 300, 280), (c) {
      final p = Path()
        ..moveTo(-280, -70)
        ..lineTo(280, -70)
        ..lineTo(280, 10);
      var x = 280.0;
      while (x > -280) {
        final w = 22 + r.nextDouble() * 40;
        final len = 20 + r.nextDouble() * (r.nextDouble() < 0.3 ? 200 : 70);
        p
          ..lineTo(x - w * 0.45, 10 + len)
          ..lineTo(x - w, 6 + r.nextDouble() * 18);
        x -= w;
      }
      p
        ..lineTo(-280, 10)
        ..close();
      c.drawPath(p, _inkOf(ink));
    });
  }

  /// Tavandan sarkan kökler: dalgalı, ince uçlu.
  static _Shape _roots(Color ink, int seed) {
    final r = math.Random(seed);
    return _bake(const Rect.fromLTRB(-240, -40, 240, 380), (c) {
      for (var k = 0; k < 6; k++) {
        final x0 = -190 + r.nextDouble() * 380;
        final len = 110 + r.nextDouble() * 220;
        final p = Path()..moveTo(x0, -20);
        var y = -20.0;
        var x = x0;
        while (y < len) {
          final ny = y + 40 + r.nextDouble() * 30;
          final nx = x + (r.nextDouble() - 0.5) * 36;
          p.quadraticBezierTo(
            x + (r.nextDouble() - 0.5) * 40,
            (y + ny) / 2,
            nx,
            ny,
          );
          x = nx;
          y = ny;
        }
        c.drawPath(p, _lineOf(ink, 3 + r.nextDouble() * 6));
      }
    });
  }

  /// Zemine oturan iri kaya; üst kenarı hafif ışık alır, istenirse içinde
  /// kızgın çatlaklar.
  static _Shape _rock(Color ink, Color rim, int seed, {Color? crack}) {
    final r = math.Random(seed);
    final w = 120 + r.nextDouble() * 110;
    final h = 50 + r.nextDouble() * 90;
    double j(double v) => v * (0.85 + r.nextDouble() * 0.3);
    final top = [
      Offset(-w, 10),
      Offset(-w * 0.8, -j(h * 0.5)),
      Offset(-w * 0.45, -j(h * 0.9)),
      Offset(-w * 0.1, -h),
      Offset(w * 0.3, -j(h * 0.8)),
      Offset(w * 0.7, -j(h * 0.45)),
      Offset(w, 0),
    ];
    return _bakeGround(Rect.fromLTRB(-w - 40, -h * 1.3 - 40, w + 40, 200), (c) {
      c.drawPath(
        Path()..addPolygon([
          const Offset(0, 200) + Offset(-w, 0),
          ...top,
          Offset(w, 200),
        ], true),
        _inkOf(ink),
      );
      c.drawPath(Path()..addPolygon(top, false), _lineOf(rim, 4));
      if (crack != null) {
        for (var k = 0; k < 3; k++) {
          final x = -w * 0.6 + k * w * 0.55 + r.nextDouble() * 20;
          final p = Path()..moveTo(x, -h * 0.6);
          var y = -h * 0.6;
          var cx = x;
          while (y < 60) {
            cx += (r.nextDouble() - 0.5) * 30;
            y += 18 + r.nextDouble() * 14;
            p.lineTo(cx, y);
          }
          c.drawPath(p, _lineOf(crack.withValues(alpha: 0.35), 12, 8));
          c.drawPath(p, _lineOf(crack, 3, 1.5));
        }
      }
    });
  }

  /// Kameranın önünden geçen bulut öbeği (yuvarlakların birleşimi).
  static _Shape _cloud(Color col, int seed, {bool hang = false}) {
    final r = math.Random(seed);
    return _bake(const Rect.fromLTRB(-360, -230, 360, 230), (c) {
      final paint = _inkOf(col, 16);
      for (var k = 0; k < 7; k++) {
        final x = -250 + k * 83 + (r.nextDouble() - 0.5) * 40;
        final rad = 55 + r.nextDouble() * 70 - (k - 3).abs() * 8;
        final y = (hang ? 1 : -1) * rad * (0.4 + r.nextDouble() * 0.3);
        c.drawCircle(Offset(x, y), rad, paint);
      }
    });
  }

  /// Zümrüt kristal öbeği: eğik altıgen prizmalar, ışığa bakan kenar parlak.
  static _Shape _crystals(int seed) {
    final r = math.Random(seed);
    return _bakeGround(const Rect.fromLTRB(-200, -280, 200, 200), (c) {
      final n = 3 + r.nextInt(3);
      for (var k = 0; k < n; k++) {
        final bx = -120 + r.nextDouble() * 240;
        final h = 80 + r.nextDouble() * 150;
        final w = 16 + r.nextDouble() * 18;
        final lean = (r.nextDouble() - 0.5) * 0.7;
        c.save();
        c.translate(bx, 30);
        c.rotate(lean);
        c.drawPath(
          Path()..addPolygon([
            Offset(-w, 160),
            Offset(-w, -h + w),
            Offset(0, -h),
            Offset(w, -h + w),
            Offset(w, 160),
          ], true),
          _inkOf(const Color(0xFF082A22), 4),
        );
        c.drawLine(
          Offset(0, -h),
          const Offset(0, 140),
          _lineOf(const Color(0x661E6A54), 4, 2),
        );
        c.drawPath(
          Path()..addPolygon([
            Offset(-w, 120),
            Offset(-w, -h + w),
            Offset(0, -h),
          ], false),
          _lineOf(const Color(0x995AEBB0), 3, 2),
        );
        c.restore();
      }
    });
  }

  /// İpe asılı fener; camından sıcak ışık sızar.
  static _Shape _lantern(Color ink, double len, Paint rope) {
    final fill = _inkOf(ink);
    return _bake(Rect.fromLTRB(-50, -20, 50, len + 90), (c) {
      if (rope.style == PaintingStyle.stroke && rope.strokeWidth > 5) {
        _chain(c, len, rope);
      } else {
        c.drawLine(const Offset(0, -10), Offset(0, len + 6), rope);
      }
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
          ..color = const Color(0xBFFFB060)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      c.drawOval(Rect.fromLTWH(-20, len + 48, 40, 14), fill);
    });
  }

  // ------------------------------------------------------------ Kule

  static List<_Row> _cliffs() {
    const ink = Color(0xFF0C0705);
    const rim = Color(0x55C07848);
    return [
      _Row([_roots(ink, 1), _roots(ink, 2)], 18, 6),
      _Row(
        [for (var i = 0; i < 3; i++) _rock(ink, rim, 10 + i)],
        16,
        12,
        at: _Anchor.ground,
      ),
    ];
  }

  // ------------------------------------------------------------ Gökyolu

  static List<_Row> _sky() => [
    _Row(
      [_cloud(const Color(0xB8A0583C), 1), _cloud(const Color(0xA8B4684A), 2)],
      22,
      4,
      at: _Anchor.bottom,
    ),
    _Row([_cloud(const Color(0x80C07A58), 3, hang: true)], 27, 15),
  ];

  // ------------------------------------------------------------ Kaf

  static List<_Row> _kaf() => [
    _Row([_crystals(1), _crystals(2), _crystals(3)], 18, 7, at: _Anchor.ground),
    _Row([_stalactites(const Color(0xFF061A16), 4)], 31, 19),
  ];

  // ------------------------------------------------------------ Nuh'un Gemisi

  static List<_Row> _ark() {
    const ink = Color(0xFF0C0705);
    final fill = _inkOf(ink);
    final rope = _lineOf(ink, 4, 2);
    // Tavan kirişi ve iki dirsek.
    final beam = _bake(const Rect.fromLTRB(-360, -80, 360, 200), (c) {
      c.drawRect(const Rect.fromLTRB(-330, -60, 330, 26), fill);
      final brace = _lineOf(ink, 22, 6);
      c.drawLine(const Offset(-240, 20), const Offset(-320, 160), brace);
      c.drawLine(const Offset(240, 20), const Offset(320, 160), brace);
      for (var x = -300.0; x <= 300; x += 75) {
        c.drawCircle(Offset(x, -10), 7, _inkOf(const Color(0xFF2A1A10), 3));
      }
    });
    // Fıçı ve sandık.
    final hoop = _lineOf(const Color(0xFF2A1A10), 5, 3);
    final cargo = [
      _bakeGround(const Rect.fromLTRB(-90, -170, 200, 200), (c) {
        c.drawRRect(
          RRect.fromLTRBR(-60, -140, 60, 180, const Radius.circular(40)),
          fill,
        );
        for (final y in [-100.0, -20.0]) {
          c.drawLine(Offset(-58, y), Offset(58, y), hoop);
        }
        c.drawRect(const Rect.fromLTRB(70, -90, 180, 180), fill);
        c.drawLine(const Offset(74, -86), const Offset(176, 0), hoop);
        c.drawLine(const Offset(176, -86), const Offset(74, 0), hoop);
      }),
      _bakeGround(const Rect.fromLTRB(-150, -210, 150, 200), (c) {
        c.drawRect(const Rect.fromLTRB(-130, -70, 0, 180), fill);
        c.drawRect(const Rect.fromLTRB(-90, -180, 30, -70), fill);
        c.drawRect(const Rect.fromLTRB(10, -60, 130, 180), fill);
        c.drawLine(const Offset(-126, -66), const Offset(-4, 20), hoop);
        c.drawLine(const Offset(14, -56), const Offset(126, 20), hoop);
      }),
    ];
    return [
      _Row([beam], 15, 3, drop: _refH * 0.12),
      _Row(
        [_lantern(ink, _refH * 0.16, rope), _lantern(ink, _refH * 0.24, rope)],
        23,
        11,
        drop: _refH * 0.1,
        glows: [Offset(0, _refH * 0.16 + 29), Offset(0, _refH * 0.24 + 29)],
      ),
      _Row(cargo, 19, 8, at: _Anchor.ground),
    ];
  }

  // ------------------------------------------------------------ Nemrut

  static List<_Row> _nemrut() {
    const ink = Color(0xFF0A080E);
    final fill = _inkOf(ink);
    final snow = _inkOf(const Color(0x8CB8C0D4), 5);
    // Devrik taş baş: yüzü yana dönük, külahı yerde; üstünde kar.
    final head = _bakeGround(const Rect.fromLTRB(-260, -240, 260, 200), (c) {
      c.drawOval(const Rect.fromLTRB(-120, -190, 90, 60), fill);
      c.drawPath(
        Path()
          ..moveTo(60, -170)
          ..quadraticBezierTo(200, -150, 240, -30)
          ..lineTo(70, 40)
          ..close(),
        fill,
      );
      c.drawRect(const Rect.fromLTRB(-200, 20, 200, 200), fill);
      c.drawOval(const Rect.fromLTRB(-100, -196, 40, -172), snow);
      c.drawOval(const Rect.fromLTRB(90, -160, 200, -140), snow);
    });
    // Kırık kaide taşları.
    final blocks = _bakeGround(const Rect.fromLTRB(-220, -180, 220, 200), (c) {
      c.drawRect(const Rect.fromLTRB(-190, -60, 40, 200), fill);
      c.drawPath(
        Path()..addPolygon(const [
          Offset(-20, -60),
          Offset(-10, -150),
          Offset(110, -130),
          Offset(150, -40),
          Offset(150, 200),
          Offset(-20, 200),
        ], true),
        fill,
      );
      c.drawOval(const Rect.fromLTRB(-186, -70, 30, -50), snow);
    });
    return [
      _Row([head, blocks], 24, 10, at: _Anchor.ground),
    ];
  }

  // ------------------------------------------------------------ Derinkuyu

  static List<_Row> _cave() {
    const ink = Color(0xFF0A0605);
    final fill = _inkOf(ink);
    // Oyma kapı kemeri: yeraltı şehrinin geçitleri.
    final door = _bake(const Rect.fromLTRB(-200, -330, 200, 40), (c) {
      c.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(const Rect.fromLTRB(-180, -310, 180, 30))
          ..addRRect(
            RRect.fromLTRBAndCorners(
              -70,
              -220,
              70,
              30,
              topLeft: const Radius.circular(70),
              topRight: const Radius.circular(70),
            ),
          ),
        fill,
      );
    });
    return [
      _Row(
        [_stalactites(ink, 1), _stalactites(ink, 2)],
        17,
        5,
        drop: _refH * 0.08,
      ),
      _Row([door], 23, 14, at: _Anchor.bottom),
    ];
  }

  // ------------------------------------------------------------ Erlik

  static List<_Row> _underworld() {
    const ink = Color(0xFF06040A);
    const rim = Color(0x447A5AB0);
    return [
      _Row(
        [_stalactites(ink, 3), _stalactites(ink, 4)],
        16,
        4,
        drop: _refH * 0.06,
      ),
      _Row(
        [_rock(ink, rim, 5), _rock(ink, rim, 6)],
        19,
        11,
        at: _Anchor.ground,
      ),
    ];
  }

  // ------------------------------------------------------------ Ergenekon

  static List<_Row> _ergenekon() {
    const ink = Color(0xFF08070A);
    const rim = Color(0x447080A0);
    const ember = Color(0xFFFF7A30);
    return [
      _Row(
        [for (var i = 0; i < 3; i++) _rock(ink, rim, 20 + i, crack: ember)],
        17,
        9,
        at: _Anchor.ground,
      ),
    ];
  }

  // ------------------------------------------------------------ Göğün Katları

  static List<_Row> _heavens() => [
    _Row(
      [_cloud(const Color(0xB8485A8C), 5), _cloud(const Color(0xA8566A9C), 6)],
      20,
      6,
      at: _Anchor.bottom,
    ),
    _Row([_cloud(const Color(0x80607AAE), 7, hang: true)], 29, 17),
  ];

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

  // Yumuşak, bulanık şekiller: ucuz örnekleme yeter.
  static final _imgPaint = Paint()..filterQuality = FilterQuality.low;
  static final _fadePaint = Paint()..filterQuality = FilterQuality.low;

  /// Yakın şeklin ne kadar görüneceği (0–1): Sâye'ye ya da bir düşmana
  /// değiyorsa çok soluk, dört karelik mesafeden uzaktaysa tam.
  static double _clearance(Rect box, List<Rect> actors) {
    var see = 1.0;
    for (final a in actors) {
      final dx = math.max(
        0.0,
        math.max(box.left - a.right, a.left - box.right),
      );
      final dy = math.max(
        0.0,
        math.max(box.top - a.bottom, a.top - box.bottom),
      );
      final d = math.sqrt(dx * dx + dy * dy);
      see = math.min(see, 0.12 + 0.88 * (d / (4 * kTile)).clamp(0.0, 1.0));
    }
    return see;
  }

  /// Bölümün ortam ışığı: koyu ortamda yakın şekillerin kenarı bununla
  /// seçilir (Yerebatan, kar, Kapadokya ve Konya'da gerek yok: arka plan
  /// zaten açık).
  static Color? _rimOf(DepthKind kind) => switch (kind) {
    DepthKind.cliffs => const Color(0x8C8A4A2A),
    DepthKind.sky => const Color(0x80E09060),
    DepthKind.kaf => const Color(0x8C2EA07A),
    DepthKind.ark => const Color(0x99A06A38),
    DepthKind.nemrut => const Color(0x8C8478A8),
    DepthKind.cave => const Color(0x998A5428),
    DepthKind.underworld => const Color(0x997050B0),
    DepthKind.ergenekon => const Color(0x806A7898),
    DepthKind.heavens => const Color(0x80A8B8E8),
    _ => null,
  };
  final _dotPaint = Paint()..filterQuality = FilterQuality.low;

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
    if (!realismHere(game) || Realism.debugNoNear) return;
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
    // Önemli varlıkların (taş dev) önüne zeminden şekil düşmesin: duruşu
    // ve atışı okunmalı.
    final keep = [
      for (final c in game.world.children)
        if (c is StoneGiant) c.toRect().inflate(3 * kTile),
    ];
    // Oyunun okunması gerekenler: Sâye ve düşmanlar. Yakın şekil bunlara
    // yaklaştıkça saydamlaşır, üstlerini hiç örtmez.
    final actors = <Rect>[
      if (game.player case final p? when p.isMounted) p.toRect(),
      for (final c in game.world.children)
        if (c is Guard || c is Watcher || c is Wolf || c is Kormos)
          (c as PositionComponent).toRect()
        else if (c is StoneGiant)
          c.toRect(),
    ];
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
        if (row.at != _Anchor.top &&
            keep.any((r) => x > r.left - 200 * k && x < r.right + 200 * k)) {
          continue;
        }
        final at = Offset(x, y + row.drop * k);
        final (img, origin) = shape;
        final box = Rect.fromLTWH(
          at.dx + origin.dx * k,
          at.dy + origin.dy * k,
          img.width * k,
          img.height * k,
        );
        final see = _clearance(box, actors);
        if (see <= 0.02) continue;
        if (see < 1) {
          _fadePaint.color = Color.fromRGBO(255, 255, 255, see);
          _put(canvas, shape, at, k, _fadePaint);
        } else {
          _put(canvas, shape, at, k);
        }
        final glows = row.glows;
        if (glows != null) {
          _glow(canvas, at + glows[i % glows.length] * k, k);
        }
      }
    }
    // (zerre, adet, düşüş hızı (eksi: yükselir), parlaklık, rüzgâr)
    final dots = switch (kind) {
      DepthKind.snow ||
      DepthKind.konya ||
      DepthKind.nemrut => (_flakeShape, 26, 70.0, 0.55, -18.0),
      DepthKind.peri => (_moteShape, 30, -14.0, 0.8, 10.0),
      DepthKind.cliffs ||
      DepthKind.ark ||
      DepthKind.cave => (_dot(const Color(0xFFE8C8A0), 3), 24, 6.0, 0.45, 5.0),
      DepthKind.sky => (
        _dot(const Color(0xFFFFB070), 3.5),
        26,
        -22.0,
        0.7,
        14.0,
      ),
      DepthKind.kaf => (
        _dot(const Color(0xFF8CFFD8), 3.5),
        24,
        -10.0,
        0.7,
        4.0,
      ),
      DepthKind.underworld => (
        _dot(const Color(0xFFB8A0FF), 4),
        18,
        -8.0,
        0.5,
        2.0,
      ),
      DepthKind.ergenekon => (
        _dot(const Color(0xFFFF8A40), 3),
        30,
        -34.0,
        0.85,
        8.0,
      ),
      DepthKind.heavens => (
        _dot(const Color(0xFFDDE6FF), 2.5),
        30,
        4.0,
        0.6,
        -6.0,
      ),
      DepthKind.cistern => null,
    };
    if (dots != null) {
      final (shape, count, fall, alpha, wind) = dots;
      _dots(canvas, view, cam.x, k, shape, count, fall, alpha, wind);
    }
  }

  /// Fener camının çevresine taşan sıcak ışık.
  void _glow(Canvas canvas, Offset at, double k) {
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
