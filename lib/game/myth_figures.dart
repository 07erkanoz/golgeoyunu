import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'myth_shapes.dart';

/// Gökbörü'nün duruşları; her biri gerçek bir kurt çiziminden alınmış
/// siluettir (myth_shapes.dart).
enum WolfPose { walk, stand, howl }

/// Gerçek siluetlerin üstüne oyunun dilini ekleyen çizimler: Gökbörü
/// gökten inmiş bir ışık kurdudur (içinde yıldızlar kıpırdar), Tulpar
/// kanatlı, altın ışıklı attır. Ayakların ortası orijindedir, yüz sağa
/// bakar, boy 100 birimdir; çağıran ölçekler. [t] saniye cinsinden zaman.
class MythFigures {
  MythFigures._();

  static Path _shape(WolfPose p) => switch (p) {
    WolfPose.walk => MythShapes.wolfWalk,
    WolfPose.stand => MythShapes.wolfStand,
    WolfPose.howl => MythShapes.wolfHowl,
  };

  // Göz, siluetin üstünden ölçüldü.
  static Offset _eye(WolfPose p) => switch (p) {
    WolfPose.walk => const Offset(50.5, -80),
    WolfPose.stand => const Offset(39, -84),
    WolfPose.howl => const Offset(40.5, -89),
  };

  static double _hash(int i) {
    final v = math.sin(i * 12.9898 + 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// İçinde yıldızlar kıpırdayan, kenarı titreyen ışık bedeni.
  static void _skyBody(
    Canvas c,
    Path shape,
    double t, {
    required Color top,
    required Color bottom,
    required Color glow,
    required Color star,
    double alpha = 1,
    int stars = 34,
  }) {
    final b = shape.getBounds();
    // Dış hâle: siluetin bulanık bir kopyası.
    c.drawPath(
      shape,
      Paint()
        ..color = glow.withValues(alpha: 0.55 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    c.drawPath(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(b.topCenter, b.bottomCenter, [
          top.withValues(alpha: 0.96 * alpha),
          bottom.withValues(alpha: 0.9 * alpha),
        ]),
    );
    c.save();
    c.clipPath(shape);
    // İçe doğru ak kenar ışığı: bedenin hacmi.
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Karına doğru gök mavisi koyulaşır.
    c.drawRect(
      b,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, b.top + b.height * 0.45),
          b.bottomCenter,
          [bottom.withValues(alpha: 0), bottom.withValues(alpha: 0.6 * alpha)],
        ),
    );
    // Yıldızlar: yerleri sabit, ışıkları ağır ağır kıpırdar.
    final sp = Paint();
    for (var i = 0; i < stars; i++) {
      final p = Offset(
        b.left + _hash(i) * b.width,
        b.top + _hash(i + 97) * b.height,
      );
      final tw = math.sin(t * (0.8 + _hash(i + 31)) + i * 1.7);
      final r = 0.5 + _hash(i + 53) * 0.9;
      sp.color = star.withValues(alpha: (0.35 + 0.45 * tw * tw) * alpha);
      c.drawCircle(p, r, sp);
      if (_hash(i + 7) > 0.8) {
        // Büyük yıldızlara dört köşeli parıltı.
        final l = r * 3.2 * (0.6 + 0.4 * tw.abs());
        final line = Paint()
          ..color = sp.color
          ..strokeWidth = 0.35;
        c.drawLine(p - Offset(l, 0), p + Offset(l, 0), line);
        c.drawLine(p - Offset(0, l), p + Offset(0, l), line);
      }
    }
    c.restore();
    // Titreyen ak kenar.
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: (0.55 + 0.25 * math.sin(t * 6.3)) * alpha),
    );
  }

  static void _eyeGlow(Canvas c, Offset at, Color color, double alpha) {
    c.drawCircle(
      at,
      7,
      Paint()
        ..shader = ui.Gradient.radial(at, 7, [
          color.withValues(alpha: 0.9 * alpha),
          color.withValues(alpha: 0),
        ]),
    );
    c.drawOval(
      Rect.fromCenter(center: at, width: 3.2, height: 1.5),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
    );
  }

  // -------------------------------------------------------------- Gökbörü

  /// Gökbörü: gök mavisi ışıktan kurt; içinde yıldızlar kıpırdar, gözleri
  /// ak yanar.
  static void gokboru(
    Canvas c,
    double t, {
    WolfPose pose = WolfPose.walk,
    double alpha = 1,
  }) {
    final shape = _shape(pose);
    // Yerdeki ışık gölgesi.
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 120, height: 9),
      Paint()
        ..color = const Color(0xFF9CC4E4).withValues(alpha: 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    _skyBody(
      c,
      shape,
      t,
      top: const Color(0xFFEAF4FC),
      bottom: const Color(0xFF6E9CC8),
      glow: const Color(0xFF9CC4E4),
      star: const Color(0xFFFFFFFF),
      alpha: alpha,
    );
    _eyeGlow(c, _eye(pose), const Color(0xFFDDEFFF), alpha);
  }

  /// Gökbörü'nün karanlıkta parlayan pençe izi (yalnız kavanoz örtülüyken
  /// görünür).
  static void pawPrint(Canvas c, double alpha) {
    final glow = Paint()
      ..color = const Color(0xFF9CC4E4).withValues(alpha: 0.5 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final p = Paint()..color = const Color(0xFFEAF4FC).withValues(alpha: alpha);
    for (final paint in [glow, p]) {
      c.drawPath(
        Path()
          ..moveTo(-4.5, 1)
          ..cubicTo(-5, -3.5, 5, -3.5, 4.5, 1)
          ..cubicTo(3, 3.4, -3, 3.4, -4.5, 1)
          ..close(),
        paint,
      );
      for (final (x, y, r) in [
        (-5.4, -4.6, -0.5),
        (-1.8, -7.0, -0.15),
        (1.8, -7.0, 0.15),
        (5.4, -4.6, 0.5),
      ]) {
        c.save();
        c.translate(x, y);
        c.rotate(r);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 2.6, height: 3.6),
          paint,
        );
        c.restore();
      }
    }
  }

  // --------------------------------------------------------------- Tulpar

  static List<Path>? _wingCache;

  /// Tüy tüy kanat: kök orijinde, kol (ön kenar) yukarı-geriye kıvrılır,
  /// tüyler koldan geriye-aşağı yelpazelenir. Üç sıra: uzun uç tüyleri,
  /// orta tüyler, kısa örtü tüyleri. Bir kez kurulur.
  static List<Path> _wingRows() {
    if (_wingCache != null) return _wingCache!;
    const arm = [
      Offset(0, 0),
      Offset(-8, -16),
      Offset(-22, -30),
      Offset(-46, -40),
    ];
    Offset along(double s) {
      final f = s * (arm.length - 1);
      final i = f.floor().clamp(0, arm.length - 2);
      return Offset.lerp(arm[i], arm[i + 1], f - i)!;
    }

    Path feather(Offset a, double ang, double len, double w) {
      final dir = Offset(math.cos(ang), math.sin(ang));
      final nrm = Offset(-dir.dy, dir.dx);
      final tip = a + dir * len;
      return Path()
        ..moveTo(a.dx + nrm.dx * w * 0.5, a.dy + nrm.dy * w * 0.5)
        ..cubicTo(
          a.dx + dir.dx * len * 0.5 + nrm.dx * w * 0.6,
          a.dy + dir.dy * len * 0.5 + nrm.dy * w * 0.6,
          tip.dx + nrm.dx * w * 0.55 - dir.dx * 2,
          tip.dy + nrm.dy * w * 0.55 - dir.dy * 2,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          tip.dx - nrm.dx * w * 0.5 - dir.dx * 3,
          tip.dy - nrm.dy * w * 0.5 - dir.dy * 3,
          a.dx + dir.dx * len * 0.5 - nrm.dx * w * 0.55,
          a.dy + dir.dy * len * 0.5 - nrm.dy * w * 0.55,
          a.dx - nrm.dx * w * 0.5,
          a.dy - nrm.dy * w * 0.5,
        )
        ..close();
    }

    // (sayı, uzunluk kökte → uçta, en, kolda başlangıç)
    const rows = [
      (10, 20.0, 34.0, 8.0, 0.18),
      (9, 12.0, 19.0, 7.0, 0.1),
      (8, 7.0, 11.0, 6.0, 0.04),
    ];
    final out = <Path>[];
    for (final (n, l0, l1, w, s0) in rows) {
      // Kol: kökte yuvarlak, uca doğru incelir.
      var row = Path()
        ..moveTo(2, 0)
        ..cubicTo(-2, -14, -20, -34, -47, -41)
        ..cubicTo(-32, -33, -15, -18, -7, -1)
        ..quadraticBezierTo(-3, 5, 2, 0)
        ..close();
      for (var k = 0; k < n; k++) {
        final s = k / (n - 1);
        final u = s0 + s * (1 - s0) * 0.97;
        // Tüy kökü ön kenarın biraz gerisinde: kenarda diş kalmasın.
        final tan = along(math.min(1, u + 0.02)) - along(math.max(0, u - 0.02));
        final tn = tan / tan.distance;
        final a = along(u) + Offset(tn.dy, -tn.dx) * 4;
        // Kökte aşağı-geri, uçta geriye uzanır.
        final ang = math.pi * (0.62 + 0.42 * s);
        row = Path.combine(
          PathOperation.union,
          row,
          feather(a, ang, l0 + (l1 - l0) * s, w),
        );
      }
      out.add(row);
    }
    return _wingCache = out;
  }

  static void _wing(Canvas c, double alpha, {bool far = false}) {
    final rows = _wingRows();
    const fill = [Color(0xFFE8B868), Color(0xFFF4D594), Color(0xFFFFF0CC)];
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0xFF8A5A20).withValues(alpha: 0.75 * alpha);
    for (var r = 0; r < rows.length; r++) {
      final col = far
          ? Color.lerp(fill[r], const Color(0xFF6A4A2A), 0.35)!
          : fill[r];
      c.drawPath(rows[r], Paint()..color = col.withValues(alpha: 0.96 * alpha));
      c.drawPath(rows[r], edge);
    }
  }

  /// Omuz tüyleri: kanadın örtü tüyleri sırttan omza taşar ve aşağıya
  /// doğru gövdenin ışığında erir; kanatla gövdenin birleşimi.
  static void _shoulder(Canvas c, double alpha) {
    const back = [
      (-4.0, -73.0),
      (1.0, -72.5),
      (6.0, -72.5),
      (11.0, -74.0),
      (15.0, -76.5),
    ];
    var tuft = Path();
    for (var i = 0; i < back.length; i++) {
      final (x, y) = back[i];
      final ang = math.pi * (0.58 + 0.06 * i);
      final dir = Offset(math.cos(ang), math.sin(ang));
      final nrm = Offset(-dir.dy, dir.dx);
      final a = Offset(x, y - 1.5);
      final len = 11.0 + i * 1.2;
      final tip = a + dir * len;
      tuft = Path.combine(
        PathOperation.union,
        tuft,
        Path()
          ..moveTo(a.dx + nrm.dx * 3.5, a.dy + nrm.dy * 3.5)
          ..quadraticBezierTo(
            tip.dx + nrm.dx * 3.5 - dir.dx * 3,
            tip.dy + nrm.dy * 3.5 - dir.dy * 3,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            tip.dx - nrm.dx * 3.5 - dir.dx * 3,
            tip.dy - nrm.dy * 3.5 - dir.dy * 3,
            a.dx - nrm.dx * 3.5,
            a.dy - nrm.dy * 3.5,
          )
          ..close(),
      );
    }
    Paint fade(Color col, double a0) => Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -75),
        const Offset(0, -57),
        [col.withValues(alpha: a0 * alpha), col.withValues(alpha: 0)],
      );
    c.save();
    c.clipPath(MythShapes.horse);
    c.drawPath(tuft, fade(const Color(0xFFFFF0CC), 0.95));
    c.drawPath(
      tuft,
      fade(const Color(0xFF8A5A20), 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    c.restore();
  }

  /// Tulpar: altın ışıklı kanatlı at. Kanatlar ağır ağır çırpar, yelesi
  /// ışıktan tellerle savrulur.
  static void tulpar(Canvas c, double t, {double alpha = 1}) {
    // Kanat kökü sırtın içinde (sırt çizgisi burada y ≈ -72.5): gövde
    // kanatların dibini örter, kanat sırttan çıkıyor görünür.
    const root = Offset(5, -65);
    final flap = math.sin(t * 1.6);
    const gold = Color(0xFFF6D88A);
    // Arkadaki kanat: biraz daha yukarıda ve soluk.
    c.save();
    c.translate(root.dx + 6, root.dy - 3);
    c.rotate(0.22 + flap * 0.22);
    c.scale(0.92);
    _wing(c, alpha, far: true);
    c.restore();
    // Öndeki kanat.
    c.save();
    c.translate(root.dx, root.dy);
    c.rotate(flap * 0.25);
    c.drawPath(
      _wingRows()[0],
      Paint()
        ..color = gold.withValues(alpha: 0.45 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    _wing(c, alpha);
    c.restore();
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 110, height: 9),
      Paint()
        ..color = gold.withValues(alpha: 0.3 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    _skyBody(
      c,
      MythShapes.horse,
      t,
      top: const Color(0xFFFFF6E0),
      bottom: const Color(0xFFD9A858),
      glow: gold,
      star: const Color(0xFFFFFFFF),
      alpha: alpha,
      stars: 26,
    );
    _shoulder(c, alpha);
    // Yele: boyun sırtından geriye savrulan ışık telleri.
    const crest = [
      Offset(18, -78),
      Offset(28, -86),
      Offset(37, -94),
      Offset(45, -99),
    ];
    final strand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4 * alpha);
    for (var i = 0; i < 10; i++) {
      final s = i / 9;
      final f = (s * 3).floor().clamp(0, 2);
      final a = Offset.lerp(crest[f], crest[f + 1], s * 3 - f)!;
      final w = math.sin(t * 2.6 + i * 0.8);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(
            a.dx - 6,
            a.dy - 4 + w * 2,
            a.dx - 12,
            a.dy + 2 - w * 2,
            a.dx - 17 - s * 4,
            a.dy - 1 + w * 3,
          ),
        strand,
      );
    }
    _eyeGlow(c, const Offset(50, -88), const Color(0xFFFFE8B0), alpha);
  }

  // ------------------------------------------------------- ortak çizimler

  /// Karanlık (mürekkep) beden: içten ve dıştan [rim] renginde ışık alır;
  /// ateş başındaki Kam, Albastı gibi ışıktan olmayan varlıklar için.
  static void _inkBody(
    Canvas c,
    Path shape,
    double t, {
    required Color rim,
    double alpha = 1,
  }) {
    final b = shape.getBounds();
    c.drawPath(
      shape,
      Paint()
        ..color = rim.withValues(alpha: 0.32 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    c.drawPath(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(b.topCenter, b.bottomCenter, [
          const Color(0xFF1E120C).withValues(alpha: alpha),
          const Color(0xFF0A0604).withValues(alpha: alpha),
        ]),
    );
    c.save();
    c.clipPath(shape);
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = rim.withValues(
          alpha: (0.5 + 0.12 * math.sin(t * 5.1)) * alpha,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    c.restore();
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = rim.withValues(alpha: 0.55 * alpha),
    );
  }

  static final Map<String, Path> _unions = {};

  /// Siluete eklenen sabit parçalar (kalpak, sakal, cübbe...) bir kez
  /// birleştirilir.
  static Path _union(String key, Path base, List<Path> Function() parts) =>
      _unions.putIfAbsent(key, () {
        var p = base;
        for (final part in parts()) {
          p = Path.combine(PathOperation.union, p, part);
        }
        return p;
      });

  // ------------------------------------------------------------ Umay ağacı

  static const double _treePx = 6;
  static const Rect _treeBox = Rect.fromLTRB(-54, -112, 54, 36);
  static final List<ui.Image?> _treeImg = [null, null];

  /// Ağacın kendisi (yaprak yaprak binlerce eğri): bir kez resme dökülür,
  /// sonra her karede yalnız resim çizilir.
  static ui.Image _tree(bool lit) {
    final i = lit ? 1 : 0;
    final cached = _treeImg[i];
    if (cached != null) return cached;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(_treePx);
    c.translate(-_treeBox.left, -_treeBox.top);
    // Buradan sonra gövdenin toprağa girdiği yer orijin; kökler y > 0.
    final shape = MythShapes.umayTree;
    // Siluetin taç kısmı (tek bir yaprak öbeği): [at] noktasına, [sx]/[sy]
    // ölçeğiyle yerleştirilir. Birkaç öbek üst üste tacı doldurur.
    void crown(Offset at, double sx, double sy, Paint paint) {
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(sx, sy);
      c.translate(0, 76);
      c.clipRect(const Rect.fromLTRB(-60, -200, 60, -52));
      c.drawPath(shape, paint);
      c.restore();
    }

    // Kökler: toprağın altında, gövde kalınlaştığı için daha geniş.
    c.save();
    c.clipRect(const Rect.fromLTRB(-60, 0, 60, 40));
    c.scale(1.9, 1.1);
    c.translate(0, 30);
    c.drawPath(
      shape,
      Paint()
        ..color = (lit ? const Color(0xFFF2C878) : const Color(0xFF6A5A48))
            .withValues(alpha: lit ? 0.55 : 0.3),
    );
    c.restore();
    const back = [(Offset(0, -50), -1.8, 1.4)];
    const mid = [
      (Offset(-19, -38), -1.05, 0.95),
      (Offset(19, -40), 1.05, 0.95),
      (Offset(-10, -60), 0.95, 0.9),
      (Offset(12, -62), -0.9, 0.9),
    ];
    const front = [(Offset(0, -44), 1.0, 1.0), (Offset(1, -68), -0.85, 0.8)];
    // Hâle: bütün tacın bulanık kopyası.
    final glow = Paint()
      ..color = (lit ? const Color(0xFFFFF0C0) : const Color(0xFF8A9A88))
          .withValues(alpha: lit ? 0.6 : 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, lit ? 8 : 4);
    for (final (at, sx, sy) in [...back, ...mid]) {
      crown(at, sx, sy, glow);
    }
    for (final (at, sx, sy) in back) {
      crown(
        at,
        sx,
        sy,
        Paint()
          ..color = lit ? const Color(0xFFA8BC80) : const Color(0xFF3A4638),
      );
    }
    for (final (at, sx, sy) in mid) {
      crown(
        at,
        sx,
        sy,
        Paint()
          ..color = lit ? const Color(0xFFCCDCA0) : const Color(0xFF4E5C4A),
      );
    }
    // Gövde ve dallar: kalın, ak kayın; dibi toprağa yayılır.
    final bark = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-5, 0),
        const Offset(5, 0),
        lit
            ? const [Color(0xFFE8E4DA), Color(0xFFFFFFFF), Color(0xFFD8D2C4)]
            : const [Color(0xFF9A9C94), Color(0xFFC4C6BC), Color(0xFF8A8C84)],
        const [0, 0.45, 1],
      );
    final limbs = <Path>[
      _strip(
        const [
          Offset(0, 1),
          Offset(-0.3, -10),
          Offset(-0.6, -20),
          Offset(-0.2, -30),
          Offset(0.4, -38),
        ],
        4.4,
        2.4,
      ),
      // Toprağa yayılan dip.
      Path()
        ..moveTo(-9, 1)
        ..quadraticBezierTo(-4.5, -1, -4, -8)
        ..lineTo(4, -8)
        ..quadraticBezierTo(4.5, -1, 9.5, 1)
        ..close(),
      _strip(
        const [
          Offset(-0.5, -24),
          Offset(-6, -31),
          Offset(-13, -37),
          Offset(-21, -41),
        ],
        2.0,
        0.6,
      ),
      _strip(
        const [
          Offset(0.3, -28),
          Offset(6, -34),
          Offset(13, -40),
          Offset(21, -44),
        ],
        1.9,
        0.6,
      ),
      _strip(
        const [
          Offset(0.4, -36),
          Offset(-2, -46),
          Offset(-6, -55),
          Offset(-10, -62),
        ],
        1.7,
        0.5,
      ),
      _strip(
        const [
          Offset(0.4, -37),
          Offset(3, -47),
          Offset(7, -57),
          Offset(11, -64),
        ],
        1.6,
        0.5,
      ),
    ];
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = const Color(0xFF3A3028).withValues(alpha: 0.6);
    for (final l in limbs) {
      c.drawPath(l, bark);
      c.drawPath(l, edge);
    }
    // Kayın kabuğunun kara çizgileri.
    final mark = Paint()
      ..color = const Color(0xFF1A140E).withValues(alpha: 0.75)
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.round;
    for (final (y, x0, x1) in const [
      (-4.0, -3.6, -0.5),
      (-8.5, 0.6, 3.6),
      (-13.0, -3.4, -1.0),
      (-17.0, -0.2, 3.0),
      (-21.5, -3.0, 0.2),
      (-26.0, 0.0, 2.6),
      (-31.0, -2.2, 0.0),
    ]) {
      c.drawLine(Offset(x0, y), Offset(x1, y + 0.5), mark);
    }
    for (final (a, b) in const [
      (Offset(-8, -31), Offset(-6.5, -30)),
      (Offset(9, -36), Offset(10.6, -37)),
      (Offset(-3.6, -50), Offset(-2.4, -49.4)),
    ]) {
      c.drawLine(a, b, mark);
    }
    // Ön taç: en açık öbekler, dalların bir kısmını örter.
    for (final (at, sx, sy) in front) {
      crown(
        at,
        sx,
        sy,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, at.dy - 26),
            Offset(0, at.dy + 24),
            lit
                ? const [Color(0xFFFFF8DE), Color(0xFFDCE8B8)]
                : const [Color(0xFF7E8C78), Color(0xFF5E6A5A)],
          ),
      );
    }
    final pic = rec.endRecording();
    final img = pic.toImageSync(
      (_treeBox.width * _treePx).ceil(),
      (_treeBox.height * _treePx).ceil(),
    );
    pic.dispose();
    return _treeImg[i] = img;
  }

  // Çaputların bağlandığı dallar (gövdenin toprağa girdiği yer orijin).
  static const _knots = [
    (Offset(-28, -24), Color(0xFFF5F0E6)),
    (Offset(-22, -20), Color(0xFFC8282A)),
    (Offset(-15, -18), Color(0xFF3A7CC8)),
    (Offset(-8, -17.5), Color(0xFFF5F0E6)),
    (Offset(6, -18), Color(0xFFC8282A)),
    (Offset(12.5, -17.5), Color(0xFFE8C040)),
    (Offset(19, -20), Color(0xFFF5F0E6)),
    (Offset(26, -24), Color(0xFFC8282A)),
    (Offset(-24, -38), Color(0xFFE8C040)),
    (Offset(-12, -30), Color(0xFFC8282A)),
    (Offset(10, -31), Color(0xFFF5F0E6)),
    (Offset(23, -40), Color(0xFF3A7CC8)),
    (Offset(-6, -46), Color(0xFFF5F0E6)),
    (Offset(8, -50), Color(0xFFC8282A)),
    (Offset(-18, -55), Color(0xFFF5F0E6)),
    (Offset(17, -58), Color(0xFFE8C040)),
  ];

  /// Bir orta çizgiden, kökten uca incelen şerit.
  static Path _strip(List<Offset> pts, double w0, double w1) {
    final left = <Offset>[];
    final right = <Offset>[];
    for (var j = 0; j < pts.length; j++) {
      final d = pts[math.min(j + 1, pts.length - 1)] - pts[math.max(j - 1, 0)];
      final n = Offset(-d.dy, d.dx) / (d.distance + 1e-6);
      final w = w0 + (w1 - w0) * j / (pts.length - 1);
      left.add(pts[j] + n * w);
      right.add(pts[j] - n * w);
    }
    final p = Path()..moveTo(left.first.dx, left.first.dy);
    for (final q in left.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    for (final q in right.reversed) {
      p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  /// Çaput: [k] düğümünden sarkan, rüzgârda dalgalanan kumaş şerit.
  static void _caput(
    Canvas c,
    Offset k,
    Color col,
    double len,
    double t,
    double lit,
    int i, {
    double width = 1.15,
  }) {
    final lift = lit * (1.0 + 0.15 * math.sin(t * 1.7 + i));
    final pts = <Offset>[k];
    for (var j = 1; j <= 6; j++) {
      final u = j / 6;
      // Kumaş: kökte sarkar, uca doğru rüzgâra kapılır, dalgalanır.
      final ang =
          math.pi / 2 -
          lift * (0.35 + 0.55 * u) +
          math.sin(t * (1.6 + lit * 2.6) + i * 1.3 - u * 4) *
              (0.08 + 0.3 * lit) *
              (0.3 + u);
      pts.add(pts.last + Offset(math.cos(ang), math.sin(ang)) * (len / 6));
    }
    final strip = _strip(pts, width, width * 0.75);
    c.drawPath(
      strip,
      Paint()
        ..color = Color.lerp(col, const Color(0xFF5A5650), 0.45 * (1 - lit))!,
    );
    c.drawPath(
      strip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = const Color(0xFF2A1A10).withValues(alpha: 0.8),
    );
    c.drawCircle(k, 0.9, Paint()..color = const Color(0xFF2A1A10));
  }

  /// Umay ağacı (kontrol noktası): köklü ak kayın; dallarında ak, al, gök
  /// ve sarı çaputlar, dallar arasında çaput ipi, daldan sarkan beşik,
  /// dibinde dilek taşları. [lit] 0: uyuyan (soluk, çaputlar sarkık), 1:
  /// uyanmış (ışıyan taç, rüzgârda kalkan çaputlar, altın yapraklar).
  /// Gövdenin toprağa girdiği yer orijindedir; kökler toprağın altındadır.
  static void umayTree(Canvas c, double t, {double lit = 1}) {
    if (lit > 0) {
      c.drawCircle(
        const Offset(0, -48),
        66,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(0, -48), 66, [
            const Color(0xFFFFE8B0)
                .withValues(alpha: (0.38 + 0.06 * math.sin(t * 1.3)) * lit),
            const Color(0x00FFE8B0),
          ]),
      );
    }
    final dst = Rect.fromLTRB(
      _treeBox.left,
      _treeBox.top,
      _treeBox.right,
      _treeBox.bottom,
    );
    for (final on in [false, true]) {
      final a = on ? lit : 1 - lit;
      if (a <= 0) continue;
      final img = _tree(on);
      c.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, a)
          ..filterQuality = FilterQuality.medium,
      );
    }
    // Dibinde taş yığını (oba): dilekle bırakılmış taşlar.
    final stone = Paint();
    final stoneRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = Color.lerp(
        const Color(0xFF2A221C),
        const Color(0xFFFFE0A0),
        lit * 0.8,
      )!;
    for (final (x, y, w, h, tone) in const [
      (-13.0, -1.8, 9.0, 4.4, 0.0),
      (-5.0, -2.0, 8.5, 4.8, 0.4),
      (4.5, -1.9, 9.5, 4.4, 0.2),
      (13.0, -1.6, 8.0, 3.8, 0.6),
      (-9.0, -5.6, 7.0, 4.0, 0.7),
      (0.5, -6.2, 7.5, 4.2, 0.1),
      (9.0, -5.4, 6.5, 3.8, 0.5),
      (-4.0, -9.6, 6.0, 3.6, 0.3),
      (4.5, -9.8, 5.4, 3.4, 0.8),
      (0.5, -12.8, 4.4, 3.0, 0.2),
    ]) {
      final r = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
      stone.color = Color.lerp(
        const Color(0xFF4A423A),
        const Color(0xFF8A8074),
        tone,
      )!;
      c.drawOval(r, stone);
      c.drawOval(r, stoneRim);
    }
    // Dallar arasına gerilmiş çaput ipi.
    const ropeA = Offset(-26, -32);
    const ropeB = Offset(24, -34);
    final sway = math.sin(t * 1.2) * (0.4 + 0.8 * lit);
    Offset rope(double u) =>
        Offset.lerp(ropeA, ropeB, u)! +
        Offset(0, math.sin(u * math.pi) * (7 + sway));
    final ropePath = Path()..moveTo(ropeA.dx, ropeA.dy);
    for (var j = 1; j <= 12; j++) {
      final p = rope(j / 12);
      ropePath.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      ropePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = const Color(0xFF3A2A1A),
    );
    for (var j = 1; j <= 9; j++) {
      final cols = [
        const Color(0xFFC8282A),
        const Color(0xFFF5F0E6),
        const Color(0xFF3A7CC8),
        const Color(0xFFE8C040),
      ];
      _caput(c, rope(j / 10), cols[j % 4], 6, t, lit, j + 20, width: 0.85);
    }
    for (var i = 0; i < _knots.length; i++) {
      final (k, col) = _knots[i];
      _caput(c, k, col, 9.0 + (i * 5 % 4) * 1.5, t, lit, i);
    }
    // Daldan sarkan beşik: Umay çocukları korur.
    const hook = Offset(-31, -27);
    final swing = math.sin(t * 1.1) * (0.08 + 0.12 * lit);
    c.save();
    c.translate(hook.dx, hook.dy);
    c.rotate(swing);
    final cord = Paint()
      ..color = const Color(0xFF3A2A1A)
      ..strokeWidth = 0.4;
    c.drawLine(Offset.zero, const Offset(-2.6, 9), cord);
    c.drawLine(Offset.zero, const Offset(2.6, 9), cord);
    final cradle = Path()
      ..moveTo(-4.2, 9)
      ..quadraticBezierTo(0, 15, 4.2, 9)
      ..lineTo(3.4, 9)
      ..quadraticBezierTo(0, 12.6, -3.4, 9)
      ..close();
    c.drawPath(
      Path()
        ..moveTo(-4.2, 9)
        ..quadraticBezierTo(0, 15, 4.2, 9)
        ..close(),
      Paint()..color = const Color(0xFF6A4228),
    );
    c.drawPath(cradle, Paint()..color = const Color(0xFF3A2414));
    // Beşik örtüsü: al.
    c.drawPath(
      Path()
        ..moveTo(-3.6, 9)
        ..quadraticBezierTo(0, 7.4, 3.6, 9)
        ..close(),
      Paint()..color = const Color(0xFFB8282A),
    );
    if (lit > 0) {
      c.drawCircle(
        const Offset(0, 10),
        5,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(0, 10), 5, [
            const Color(0xFFFFF0C0).withValues(alpha: 0.5 * lit),
            const Color(0x00FFF0C0),
          ]),
      );
    }
    c.restore();
    // Uyanınca tacından süzülen altın yapraklar.
    if (lit > 0) {
      final leaf = Paint();
      for (var i = 0; i < 9; i++) {
        final u = (t * 0.09 + _hash(i + 70)) % 1;
        final x =
            (_hash(i + 80) - 0.5) * 60 + math.sin(t * 1.3 + i * 2) * 4 * u;
        final y = -72 + u * 72;
        leaf.color = const Color(0xFFF2D070)
            .withValues(alpha: lit * math.sin(u * math.pi) * 0.9);
        c.save();
        c.translate(x, y);
        c.rotate(t * 2 + i);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 2.2, height: 1.1),
          leaf,
        );
        c.restore();
      }
    }
    // Uyanınca gövdeden yükselen ışık zerreleri.
    if (lit > 0) {
      final mote = Paint();
      for (var i = 0; i < 10; i++) {
        final u = (t * 0.16 + _hash(i + 11)) % 1;
        final x = (_hash(i + 3) - 0.5) * 50 + math.sin(t + i) * 3;
        mote.color = const Color(0xFFFFF4C8)
            .withValues(alpha: lit * math.sin(u * math.pi) * 0.85);
        c.drawCircle(Offset(x, -8 - u * 80), 0.8, mote);
      }
    }
  }

  // ------------------------------------------------------------ Umay kuşu

  /// Umay kuşu (Hüma): altın ak ışıklı büyük kuş. [glide] doğruysa kanatlar
  /// açık süzülür (önden), değilse çapraz kanat çırparak iner.
  static void umayBird(Canvas c, double t, {bool glide = true}) {
    final shape = glide ? MythShapes.birdGlide : MythShapes.birdFlap;
    c.save();
    c.translate(0, math.sin(t * 1.4) * 1.5);
    _skyBody(
      c,
      shape,
      t,
      top: const Color(0xFFFFFBEA),
      bottom: const Color(0xFFE6B860),
      glow: const Color(0xFFFFD890),
      star: const Color(0xFFFFFFFF),
      stars: glide ? 30 : 26,
    );
    _eyeGlow(
      c,
      glide ? const Offset(0, -37) : const Offset(8, -47),
      const Color(0xFFFFE8B0),
      1,
    );
    c.restore();
  }

  // --------------------------------------------------------------- Ak Ana

  static final Path _akDress = Path()
    ..moveTo(-5, -85)
    ..cubicTo(-8, -83, -11, -82, -11, -79)
    ..cubicTo(-10.5, -72, -10, -66, -10.5, -60)
    ..cubicTo(-11.5, -50, -13, -40, -15, -28)
    ..cubicTo(-16, -20, -17, -12, -17.5, -4)
    ..lineTo(17.5, -4)
    ..cubicTo(17, -12, 16, -20, 15, -28)
    ..cubicTo(13, -40, 11.5, -50, 10.5, -60)
    ..cubicTo(10, -66, 10.5, -72, 11, -79)
    ..cubicTo(11, -82, 8, -83, 5, -85)
    ..close();

  /// Örgü: başın yanından omzun önüne inen, uca doğru incelen, ucunda al
  /// bağlı altın püskül.
  static void _braid(Canvas c, double side, double t) {
    final sway = math.sin(t * 1.1 + side) * 0.7;
    const n = 11;
    final pts = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final u = k / n;
      // İkinci dereceden eğri: kulak altı → omuz önü → bele doğru.
      final p0 = Offset(side * 5.2, -92);
      final p1 = Offset(side * 9.5, -82);
      final p2 = Offset(side * 7.2 + sway, -61);
      final a = Offset.lerp(p0, p1, u)!;
      final b = Offset.lerp(p1, p2, u)!;
      pts.add(Offset.lerp(a, b, u)!);
    }
    const hair = Color(0xFFEAD2A4);
    const dark = Color(0xFFB8945E);
    c.drawPath(_strip(pts, 1.5, 1.0), Paint()..color = hair);
    final knot = Paint()..color = const Color(0xFFF6E4C0);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = dark;
    for (var k = 1; k < n; k++) {
      final d = pts[k + 1] - pts[k - 1];
      final ang = math.atan2(d.dy, d.dx) + (k.isEven ? 0.55 : -0.55);
      final w = 2.7 - k * 0.1;
      c.save();
      c.translate(pts[k].dx, pts[k].dy);
      c.rotate(ang);
      final r = Rect.fromCenter(center: Offset.zero, width: w, height: 1.5);
      c.drawOval(r, knot);
      c.drawOval(r, line);
      c.restore();
    }
    final tip = pts.last;
    c.drawRect(
      Rect.fromCenter(center: tip + const Offset(0, 0.4), width: 2, height: 1),
      Paint()..color = const Color(0xFFC8282A),
    );
    final tassel = Paint()
      ..color = const Color(0xFFE8B848)
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;
    for (var k = -2; k <= 2; k++) {
      c.drawLine(
        tip + Offset(k * 0.35, 1),
        tip + Offset(k * 0.6 + sway * 0.4, 4.2 - k.abs() * 0.3),
        tassel,
      );
    }
  }

  /// Ak Ana: ilk suyun içinden yükselen ak ana; cana yakın, anaç. Ak
  /// entarisi belden aşağı suda erir, iki örgüsü omuzlarından önüne
  /// düşer, alnında altın bağ, gözleri gülümseyerek kapalı.
  static void akAna(Canvas c, double t) {
    const water = -30.0;
    final breathe = math.sin(t * 0.9);
    // Sıcak hâle: başın ardında güneş gibi, bedenin çevresinde yumuşak.
    c.drawCircle(
      const Offset(0, -70),
      46,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -70), 46, [
          const Color(0xFFFFE8C8).withValues(alpha: 0.22),
          const Color(0x00FFE8C8),
        ]),
    );
    c.drawCircle(
      const Offset(0, -92),
      17,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -92), 17, [
          const Color(0xFFFFF4DC).withValues(alpha: 0.7 + 0.1 * breathe),
          const Color(0x00FFE8C0),
        ]),
    );
    // Sırttaki saç: boynun iki yanından görünür.
    c.drawPath(
      Path()
        ..moveTo(-5.5, -96)
        ..cubicTo(-8.5, -90, -9, -84, -8, -78)
        ..lineTo(8, -78)
        ..cubicTo(9, -84, 8.5, -90, 5.5, -96)
        ..close(),
      Paint()..color = const Color(0xFFE2C694),
    );
    final shape = _union('akana', MythShapes.akAna, () => [_akDress]);
    c.save();
    c.clipRect(const Rect.fromLTRB(-80, -140, 80, water));
    _skyBody(
      c,
      shape,
      t,
      top: const Color(0xFFFFFDF8),
      bottom: const Color(0xFFF0D8B8),
      glow: const Color(0xFFFFE2B8),
      star: const Color(0xFFFFF4D8),
      stars: 14,
    );
    // Entari kıvrımları ve altın kuşak.
    c.clipPath(shape);
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFFD8B890).withValues(alpha: 0.45);
    for (final x in [-6.0, -2.0, 2.5, 6.5]) {
      c.drawPath(
        Path()
          ..moveTo(x * 0.8, -58)
          ..quadraticBezierTo(x * 1.1, -45, x * 1.35, -30),
        fold,
      );
    }
    c.drawRect(
      const Rect.fromLTRB(-10.6, -61.8, 10.6, -58.6),
      Paint()..color = const Color(0xFFE6B858),
    );
    c.drawLine(
      const Offset(-10.6, -60.2),
      const Offset(10.6, -60.2),
      Paint()
        ..color = const Color(0xFFC8282A)
        ..strokeWidth = 0.6,
    );
    c.restore();
    // Başında saç: ortadan ayrılmış, yumuşak.
    const hairTone = Color(0xFFEAD2A4);
    c.drawPath(
      Path()
        ..moveTo(-5.9, -91)
        ..cubicTo(-6.8, -101.8, 6.8, -101.8, 5.9, -91)
        ..quadraticBezierTo(4.8, -96.4, 0, -97.2)
        ..quadraticBezierTo(-4.8, -96.4, -5.9, -91)
        ..close(),
      Paint()..color = hairTone,
    );
    c.drawLine(
      const Offset(0, -100.4),
      const Offset(0, -97.4),
      Paint()
        ..color = const Color(0xFFB8945E)
        ..strokeWidth = 0.35,
    );
    // Alın bağı: altın, küçük sikkeli.
    c.drawPath(
      Path()
        ..moveTo(-5.6, -95.4)
        ..quadraticBezierTo(0, -97.8, 5.6, -95.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = const Color(0xFFE6B858),
    );
    for (final x in [-3.6, -1.2, 1.2, 3.6]) {
      c.drawCircle(
        Offset(x, -96.2 + x.abs() * 0.12 + 0.9),
        0.55,
        Paint()..color = const Color(0xFFF2CC6A),
      );
    }
    // Gülümseyen kapalı gözler ve al yanaklar.
    final eye = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9A7A58);
    for (final x in [-2.1, 2.1]) {
      c.drawArc(
        Rect.fromCenter(center: Offset(x, -92.6), width: 1.9, height: 1.3),
        0.2,
        math.pi - 0.4,
        false,
        eye,
      );
      c.drawCircle(
        Offset(x * 1.3, -90.4),
        0.9,
        Paint()..color = const Color(0xFFF2A8A0).withValues(alpha: 0.35),
      );
    }
    _braid(c, -1, t);
    _braid(c, 1, t);
    // Suyun altında kalan beden: dalgalanarak erir.
    c.save();
    c.clipRect(const Rect.fromLTRB(-80, water, 80, 10));
    c.translate(math.sin(t * 2) * 0.8, 0);
    c.drawPath(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, water),
          const Offset(0, -10),
          [const Color(0x99F0DCC0), const Color(0x00BFE0F4)],
        ),
    );
    c.restore();
    // Su yüzü ve halkalar.
    c.drawLine(
      const Offset(-70, water),
      const Offset(70, water),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-70, water),
          const Offset(70, water),
          const [Color(0x00CFE6F6), Color(0xCCEAF6FF), Color(0x00CFE6F6)],
          const [0, 0.5, 1],
        )
        ..strokeWidth = 0.8,
    );
    for (var i = 0; i < 3; i++) {
      final u = (t * 0.25 + i / 3) % 1;
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(0, water),
          width: 22 + u * 70,
          height: 3 + u * 6,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = const Color(0xFFEAF6FF).withValues(alpha: 0.6 * (1 - u)),
      );
    }
  }

  // ------------------------------------------------------------- Ayaz Ata

  /// Ayaz Ata: kalpaklı, ak sakallı, bastonlu ayaz ihtiyarı; buz ışığından
  /// bedeninin çevresinde kar taneleri döner.
  static final Path _kalpak = Path()
    ..moveTo(-4, -93)
    ..cubicTo(-5, -103, 1, -111, 8, -111)
    ..cubicTo(15, -111, 20, -103, 19, -92)
    ..close();
  static final Path _kalpakBrim = Path()
    ..addRRect(RRect.fromLTRBR(-5.5, -96, 20, -90, const Radius.circular(2.8)));
  static final Path _beard = Path()
    ..moveTo(7.5, -87)
    ..cubicTo(7, -79, 9.5, -70, 13.5, -61)
    ..cubicTo(15.5, -69, 18, -78, 17.5, -86)
    ..cubicTo(14, -84, 10, -84, 7.5, -87)
    ..close();

  static void ayazAta(Canvas c, double t) {
    final shape = _union(
      'ayaz',
      MythShapes.ayazAta,
      () => [_kalpak, _kalpakBrim, _beard],
    );
    _skyBody(
      c,
      shape,
      t,
      top: const Color(0xFFF6FCFF),
      bottom: const Color(0xFF86AED0),
      glow: const Color(0xFFBFE0F4),
      star: const Color(0xFFFFFFFF),
      stars: 22,
    );
    // Kalpak: koyu gök mavisi keçe, ak kürk kenar.
    c.drawPath(
      _kalpak,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -111),
          const Offset(0, -92),
          [const Color(0xFF4A78A8), const Color(0xFF2E5680)],
        ),
    );
    c.drawPath(
      _kalpak,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFFDDEFFF),
    );
    c.drawPath(_kalpakBrim, Paint()..color = const Color(0xFFF4FAFF));
    final fur = Paint()
      ..color = const Color(0xFFB8D0E4)
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final x = -4.5 + i * 2.1;
      c.drawLine(Offset(x, -95), Offset(x + 0.8, -91), fur);
    }
    // Sakal: ak, uzun, tel tel.
    c.drawPath(_beard, Paint()..color = const Color(0xFFFFFFFF));
    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = const Color(0xFF9CC0DC);
    for (var i = 0; i < 4; i++) {
      c.drawPath(
        Path()
          ..moveTo(9 + i * 2.1, -85)
          ..quadraticBezierTo(10 + i * 1.8, -74, 13 + i * 0.3, -64),
        hair,
      );
    }
    c.drawPath(
      _beard,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = const Color(0xFF8AB0D0),
    );
    _eyeGlow(c, const Offset(13, -89), const Color(0xFFE6F6FF), 0.9);
    // Dönen kar taneleri.
    final flake = Paint()
      ..strokeWidth = 0.35
      ..color = const Color(0xFFF4FBFF);
    for (var i = 0; i < 16; i++) {
      final u = (t * 0.12 + _hash(i + 40)) % 1;
      final x = (_hash(i + 60) - 0.5) * 90 + math.sin(t * 0.8 + i) * 5;
      final y = -115 + u * 115;
      flake.color = const Color(0xFFF4FBFF)
          .withValues(alpha: math.sin(u * math.pi) * 0.9);
      final r = 0.9 + _hash(i) * 0.9;
      for (var k = 0; k < 3; k++) {
        final a = k * math.pi / 3 + t * 0.5;
        final d = Offset(math.cos(a), math.sin(a)) * r;
        c.drawLine(Offset(x, y) - d, Offset(x, y) + d, flake);
      }
    }
  }

  // ------------------------------------------------------------------ Kam

  /// Kam: saçaklı cübbesi, tüylü başlığı, elinde resimli davulu ve tokmağıyla
  /// ateş başında. Tokmak vurdukça davulun üzerindeki resimler parlar.
  static void kam(Canvas c, double t) {
    final shape = _union(
      'kam',
      MythShapes.kam,
      () => [
        // Cübbe: omuzlardan dize genişler.
        Path()
          ..moveTo(-14, -84)
          ..lineTo(13, -84)
          ..lineTo(20, -31)
          ..lineTo(-21, -31)
          ..close(),
        // Başlık: alın bağı ve yukarı uzanan tüyler.
        Path()..addRRect(
          RRect.fromLTRBR(-6.5, -102, 5, -97.5, const Radius.circular(1.5)),
        ),
        for (var i = 0; i < 5; i++)
          Path()
            ..moveTo(-5 + i * 2.4, -100)
            ..quadraticBezierTo(
              -9 + i * 4.2,
              -110,
              -12 + i * 6 + (i - 2) * 1.0,
              -116 + (i - 2).abs() * 2.5,
            )
            ..quadraticBezierTo(-6 + i * 3.6, -108, -3 + i * 2.4, -100)
            ..close(),
      ],
    );
    // Davul vuruşu: yaklaşık saniyede bir.
    final beat = (t * 1.1) % 1;
    final hit = math.pow(1 - beat, 4).toDouble();
    const fire = Color(0xFFFF9A3A);
    _inkBody(c, shape, t, rim: fire);
    // Etek saçakları: yürüdükçe, davul vurdukça sallanır.
    final fringe = Paint()
      ..color = const Color(0xFF140C08)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final fringeRim = Paint()
      ..color = fire.withValues(alpha: 0.45)
      ..strokeWidth = 0.3;
    for (var i = 0; i < 17; i++) {
      final x = -20.5 + i * 2.55;
      final sw = math.sin(t * 3 + i * 0.7) * 1.2 + hit * 1.5;
      final a = Offset(x, -32);
      final b = Offset(x + sw, -22 - (i % 2) * 1.5);
      c.drawLine(a, b, fringe);
      c.drawLine(a + const Offset(0.5, 0), b + const Offset(0.5, 0), fringeRim);
    }
    // Cübbedeki demir çıngıraklar ve şeritler: ateşi yansıtır.
    for (var i = 0; i < 7; i++) {
      final x = -12.0 + i * 4;
      final y = -62.0 + (i.isOdd ? 3 : 0);
      final sw = math.sin(t * 3.4 + i) * 0.8 + hit * 1.2;
      c.drawLine(
        Offset(x, y - 6),
        Offset(x + sw, y + 3),
        Paint()
          ..color = const Color(0xFF2A1A10)
          ..strokeWidth = 0.7,
      );
      c.drawCircle(
        Offset(x + sw, y + 3.5),
        1.1,
        Paint()..color = fire.withValues(alpha: 0.55 + 0.4 * hit),
      );
    }
    // Davul: sol elde, hafif yan dönük kasnak.
    const drum = Offset(-33, -54);
    c.drawOval(
      Rect.fromCenter(center: drum, width: 20, height: 28),
      Paint()
        ..color = fire.withValues(alpha: 0.25 + 0.35 * hit)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawOval(
      Rect.fromCenter(center: drum, width: 18, height: 26),
      Paint()..color = const Color(0xFF2A1810),
    );
    c.drawOval(
      Rect.fromCenter(center: drum, width: 15.5, height: 23.5),
      Paint()..color = const Color(0xFF5A3420),
    );
    // Davul resmi: ortada hayat ağacı, üstte Gün, yanda Ay, altta yer.
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        const Color(0xFFC88A50),
        const Color(0xFFFFE6A0),
        hit,
      )!;
    c.drawLine(drum + const Offset(0, 9), drum + const Offset(0, -6), ink);
    for (final s in [-1.0, 1.0]) {
      c.drawLine(drum + const Offset(0, -2), drum + Offset(s * 3.5, -5), ink);
      c.drawLine(drum + const Offset(0, 3), drum + Offset(s * 4, 1), ink);
    }
    c.drawCircle(drum + const Offset(-3, -9), 1.6, ink);
    c.drawArc(
      Rect.fromCircle(center: drum + const Offset(4, -8.5), radius: 1.7),
      -1.2,
      3.6,
      false,
      ink,
    );
    c.drawLine(drum + const Offset(-5, 9.5), drum + const Offset(5, 9.5), ink);
    // Tokmak: sağ elde, vuruşta davula doğru savrulur.
    const hand = Offset(25, -46);
    final ang = -1.9 + hit * 0.9;
    final tip = hand + Offset(math.cos(ang), math.sin(ang)) * 15;
    c.drawLine(
      hand,
      tip,
      Paint()
        ..color = const Color(0xFF140C08)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(tip, 1.8, Paint()..color = const Color(0xFF140C08));
    c.drawCircle(
      tip,
      1.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4
        ..color = fire.withValues(alpha: 0.6),
    );
  }

  // -------------------------------------------------------------- Albastı

  /// Albastı (Al Karısı): uzun, dağınık saçlı, kızıl ışıklı karanlık kadın;
  /// gözleri kor gibi yanar. Demirden korkar.
  static void albasti(Canvas c, double t) {
    final shape = _union(
      'albasti',
      MythShapes.albasti,
      () => [
        // Başın ardından bele dökülen saç kütlesi.
        Path()
          ..moveTo(-1, -102)
          ..cubicTo(-14, -104, -20, -93, -19, -80)
          ..cubicTo(-20, -68, -24, -60, -27, -51)
          ..cubicTo(-21, -57, -16, -66, -13, -74)
          ..cubicTo(-9, -84, -5, -91, 0, -95)
          ..close(),
      ],
    );
    const red = Color(0xFFD8302A);
    // Saç telleri: ağır ağır, suyun içindeymiş gibi dalgalanır.
    final strand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1
      ..color = const Color(0xFF140A08);
    for (var i = 0; i < 6; i++) {
      final a = Offset(-12 - i * 1.6, -92 + i * 6);
      final w = math.sin(t * 1.1 + i * 0.9) * 3;
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(
            a.dx - 6,
            a.dy + 4 + w,
            a.dx - 10,
            a.dy + 10 - w,
            a.dx - 13 - i * 0.5,
            a.dy + 16 + w,
          ),
        strand,
      );
    }
    _inkBody(c, shape, t, rim: red);
    final glow = 0.75 + 0.25 * math.sin(t * 2.3);
    c.drawCircle(
      const Offset(0.5, -92),
      4,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0.5, -92), 4, [
          const Color(0xFFFF5040).withValues(alpha: 0.9 * glow),
          const Color(0x00FF5040),
        ]),
    );
    c.drawCircle(
      const Offset(0.5, -92),
      0.8,
      Paint()..color = const Color(0xFFFFD0B0).withValues(alpha: glow),
    );
  }

  // ---------------------------------------------------------- Erlik'in katı

  /// Körmös: Erlik'in gölge hizmetkârı. Kolları ışığa uzanmış koyu bir
  /// gölge; belden aşağısı dumana karışır, gözleri kor gibi yanar.
  /// [reach] 0-1: ışığa ne kadar uzandığı (kollar öne eğilir).
  static void kormos(Canvas c, double t, {double reach = 0, double alpha = 1}) {
    c.save();
    // Işığa doğru öne eğilir.
    c.translate(0, -2);
    c.rotate(0.18 * reach);
    final shape = MythShapes.kam;
    final b = shape.getBounds();
    // Dış duman hâlesi.
    c.drawPath(
      shape,
      Paint()
        ..color = const Color(0xFF1A0E1E).withValues(alpha: 0.55 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Beden ve duman tek katmanda çizilir; belden aşağısı yumuşakça erir.
    final layer = Rect.fromLTRB(b.left - 30, b.top - 30, b.right + 30, 20);
    c.saveLayer(layer, Paint());
    _inkBody(c, shape, t, rim: const Color(0xFFB27AE8), alpha: alpha);
    // Duman tutamları: bedenin altından aşağı dalgalanır.
    final smoke = Paint();
    for (var i = 0; i < 7; i++) {
      final u = i / 6;
      final x = -12 + u * 24 + math.sin(t * 2.1 + i) * 2.5;
      final len = 26 + 14 * math.sin(i * 1.7 + 0.3).abs();
      smoke.color = const Color(0xFF2A1838).withValues(alpha: 0.9 * alpha);
      c.drawPath(
        Path()
          ..moveTo(x - 4, -56)
          ..quadraticBezierTo(
            x + math.sin(t * 3 + i) * 4,
            -56 + len * 0.5,
            x + math.sin(t * 2.4 + i * 2) * 5,
            -56 + len,
          )
          ..quadraticBezierTo(x + 2, -56 + len * 0.5, x + 4, -56)
          ..close(),
        smoke,
      );
    }
    c.drawRect(
      layer,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          const Offset(0, -62),
          const Offset(0, -22),
          const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        ),
    );
    c.restore();
    // Kor gözler.
    for (final x in [-2.6, 2.2]) {
      final at = Offset(x, -92);
      c.drawCircle(
        at,
        4,
        Paint()
          ..shader = ui.Gradient.radial(at, 4, [
            const Color(0xFFFF6A3A).withValues(alpha: 0.9 * alpha),
            const Color(0x00FF6A3A),
          ]),
      );
      c.drawCircle(
        at,
        0.8,
        Paint()..color = const Color(0xFFFFD8B0).withValues(alpha: alpha),
      );
    }
    c.restore();
  }

  /// Çalkuyruk: Er Töştük'ün konuşan atı. Koyu doru beden, yerin altının
  /// soğuk mavi ışığıyla çevrili kenar; yelesi rüzgârda.
  static void calkuyruk(Canvas c, double t, {double alpha = 1}) {
    _inkBody(
      c,
      MythShapes.horse,
      t,
      rim: const Color(0xFF7AB8FF),
      alpha: alpha,
    );
    const crest = [
      Offset(18, -78),
      Offset(28, -86),
      Offset(37, -94),
      Offset(45, -99),
    ];
    final strand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3
      ..color = const Color(0xFF9CCBFF).withValues(alpha: 0.5 * alpha);
    for (var i = 0; i < 10; i++) {
      final s = i / 9;
      final f = (s * 3).floor().clamp(0, 2);
      final a = Offset.lerp(crest[f], crest[f + 1], s * 3 - f)!;
      final w = math.sin(t * 3.2 + i * 0.8);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(
            a.dx - 6,
            a.dy - 4 + w * 2,
            a.dx - 12,
            a.dy + 2 - w * 2,
            a.dx - 18 - s * 4,
            a.dy - 1 + w * 3,
          ),
        strand,
      );
    }
    _eyeGlow(c, const Offset(50, -88), const Color(0xFFB8DCFF), alpha);
  }

  /// Hapsedilmiş kut: kara demir kafeste çırpınan bir can ışığı. [open]
  /// 0-1 kafesin açılışı (ışık kavanoza uçmuş olur).
  static void kutCage(Canvas c, double t, {double open = 0}) {
    const w = 22.0;
    const h = 30.0;
    final light = 1 - open;
    if (light > 0) {
      final pulse = 0.8 + 0.2 * math.sin(t * 3.1);
      final at = Offset(
        math.sin(t * 1.7) * 2.5,
        -h / 2 + math.cos(t * 2.3) * 2,
      );
      c.drawCircle(
        at,
        20,
        Paint()
          ..shader = ui.Gradient.radial(at, 20, [
            const Color(0xFFFFF2C8).withValues(alpha: 0.75 * light * pulse),
            const Color(0x00FFE0A0),
          ]),
      );
      c.drawCircle(
        at,
        3.4,
        Paint()..color = const Color(0xFFFFFBEA).withValues(alpha: light),
      );
    }
    // Kafes: kara demir çubuklar, üstte kubbe ve halka.
    final iron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF16100E);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF8A6A50).withValues(alpha: 0.6);
    final doorSwing = open * 0.55;
    for (var i = 0; i <= 4; i++) {
      final x = -w / 2 + i * w / 4;
      final bar = Path()
        ..moveTo(x, 0)
        ..lineTo(x, -h + 6)
        ..quadraticBezierTo(x * 0.6, -h - 2, 0, -h - 3);
      if (i == 4 && open > 0) {
        // Kapı (sağ çubuk) açılır.
        c.save();
        c.translate(w / 2, 0);
        c.rotate(-doorSwing);
        c.translate(-w / 2, 0);
        c.drawPath(bar, iron);
        c.restore();
        continue;
      }
      c.drawPath(bar, iron);
      c.drawPath(bar, rim);
    }
    c.drawLine(const Offset(-w / 2 - 2, 0), const Offset(w / 2 + 2, 0), iron);
    c.drawCircle(const Offset(0, -h - 6), 3, iron);
  }
}
