import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'myth_shapes.dart';
import 'wolf_rig.dart';

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

  /// Koşan Gökbörü (Ak Kurt): eklemli kurt iskeleti, dörtnala
  /// ([WolfRig]). [phase] 0-1 adım döngüsü (bir döngü
  /// [WolfRig.gallopStride] birim yol); [leap] 0-1 havada uzanma.
  static void gokboruRun(
    Canvas c,
    double t,
    double phase, {
    double leap = 0,
    double alpha = 1,
  }) {
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: 110 - leap * 40,
        height: 8,
      ),
      Paint()
        ..color = const Color(0xFF9CC4E4)
            .withValues(alpha: 0.35 * alpha * (1 - leap * 0.7))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    _wolfBody(c, t, WolfRig.frame(WolfGait.gallop, phase, leap: leap), alpha);
  }

  /// Yürüyen Gökbörü: aynı iskelet, adım adım (bir döngü
  /// [WolfRig.walkStride] birim yol).
  static void gokboruWalk(
    Canvas c,
    double t,
    double phase, {
    double alpha = 1,
  }) {
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 110, height: 8),
      Paint()
        ..color = const Color(0xFF9CC4E4).withValues(alpha: 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    _wolfBody(c, t, WolfRig.frame(WolfGait.walk, phase), alpha);
  }

  static void _wolfBody(Canvas c, double t, WolfFrame f, double alpha) {
    _skyBody(
      c,
      f.shape,
      t,
      top: const Color(0xFFEAF4FC),
      bottom: const Color(0xFF6E9CC8),
      glow: const Color(0xFF9CC4E4),
      star: const Color(0xFFFFFFFF),
      alpha: alpha,
    );
    _eyeGlow(c, f.eye, const Color(0xFFDDEFFF), alpha);
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
  static void tulpar(Canvas c, double t, {double alpha = 1, Path? shape}) {
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
      shape ?? MythShapes.horse,
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

  // Perde için tam siluetler (kalpak, sakal, cübbe, entari, saç dahil).
  static Path get akAnaSilhouette =>
      _union('akana', MythShapes.akAna, () => [_akDress]);
  static Path get ayazAtaSilhouette =>
      _union('ayaz', MythShapes.ayazAta, () => [_kalpak, _kalpakBrim, _beard]);
  static Path get kamSilhouette => _union(
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
  static Path get albastiSilhouette => _union(
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

  /// Kavuklu, cübbeli bir İstanbullu erkek (perde kalabalığı için).
  static Path get manSilhouette => _union(
    'man',
    MythShapes.kam,
    () => [
      Path()
        ..moveTo(-5, -89)
        ..lineTo(4, -89)
        ..cubicTo(9, -87, 13, -85, 14, -80)
        ..cubicTo(15, -60, 16, -30, 17, -2)
        ..lineTo(-18, -2)
        ..cubicTo(-17, -30, -16, -60, -15, -80)
        ..cubicTo(-14, -85, -10, -87, -5, -89)
        ..close(),
      Path()..addOval(
        Rect.fromCenter(center: const Offset(0, -104), width: 16, height: 16),
      ),
    ],
  );

  /// Tulpar'ın kanadının dış silueti (perde için).
  static Path get wingSilhouette => _wingRows()[0];

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
  /// Ağacın dal yapısı: bir kez, sabit tohumla kurulur. Yaşlı, hafif eğik
  /// bir kayın; ana dallar asimetrik yayılır, uçları sarkar (salkım kayın).
  static _TreeShape? _shapeCache;

  static _TreeShape get _treeShape => _shapeCache ??= _TreeShape.build();

  static ui.Image _tree(bool lit) {
    final i = lit ? 1 : 0;
    final cached = _treeImg[i];
    if (cached != null) return cached;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(_treePx);
    c.translate(-_treeBox.left, -_treeBox.top);
    // Buradan sonra gövdenin toprağa girdiği yer orijin; kökler y > 0.
    final tree = _treeShape;
    final rnd = math.Random(17);
    // Kökler toprağın altında, yüzeye yakın yayılır.
    final root = Paint()
      ..color = (lit ? const Color(0xFFC8A070) : const Color(0xFF5A4A3A))
          .withValues(alpha: lit ? 0.5 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      final dir = k.isEven ? 1.0 : -1.0;
      final len = 10.0 + rnd.nextDouble() * 10;
      root.strokeWidth = 1.6 - k * 0.15;
      c.drawPath(
        Path()
          ..moveTo(dir * 2, 0.5)
          ..quadraticBezierTo(
            dir * len * 0.6,
            2 + rnd.nextDouble() * 2,
            dir * len,
            5 + rnd.nextDouble() * 8,
          ),
        root,
      );
    }
    // Yaprak öbekleri: arkada koyu, önde açık; aralarından dallar görünür.
    void leaves(double shade, double alpha, int seed) {
      final paint = Paint();
      final r = math.Random(seed);
      for (final (pt, size) in tree.leaves) {
        if (r.nextDouble() > 0.62) continue;
        final tone = (shade + (r.nextDouble() - 0.5) * 0.25).clamp(0.0, 1.0);
        paint.color = Color.lerp(
          lit ? const Color(0xFF34502A) : const Color(0xFF26301F),
          lit ? const Color(0xFF94AA68) : const Color(0xFF586650),
          tone,
        )!.withValues(alpha: alpha);
        c.save();
        c.translate(
          pt.dx + (r.nextDouble() - 0.5) * 3,
          pt.dy + (r.nextDouble() - 0.5) * 2,
        );
        c.rotate((r.nextDouble() - 0.5) * 1.2);
        c.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: size * (0.9 + r.nextDouble() * 0.6),
            height: size * 0.6,
          ),
          paint,
        );
        c.restore();
      }
    }

    leaves(0.15, 0.85, 5);
    // Gövde ve dallar: ak kayın kabuğu, kara çizgiler.
    final bark = Paint()
      ..color = lit ? const Color(0xFFEDE8DC) : const Color(0xFFA8A89E);
    final barkEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = const Color(0xFF2E2620).withValues(alpha: 0.7);
    final mark = Paint()
      ..color = const Color(0xFF1A140E).withValues(alpha: 0.75)
      ..strokeCap = StrokeCap.round;
    for (final br in tree.branches) {
      final path = _strip(br.pts, br.w0, br.w1);
      c.drawPath(path, bark);
      c.drawPath(path, barkEdge);
      // Kayın kabuğunun yatay kara izleri (kalın dallarda).
      if (br.w0 > 1.2) {
        for (var j = 1; j < br.pts.length - 1; j++) {
          if (rnd.nextDouble() < 0.45) continue;
          final p0 = br.pts[j];
          final d = br.pts[j + 1] - br.pts[j - 1];
          final n = Offset(-d.dy, d.dx) / (d.distance + 1e-6);
          final w = br.w0 + (br.w1 - br.w0) * j / (br.pts.length - 1);
          mark.strokeWidth = 0.5 + w * 0.12;
          c.drawLine(p0 - n * w * 0.7, p0 + n * w * 0.15, mark);
        }
      }
    }
    // İnce sarkık dallar (salkım).
    final twig = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.35
      ..color = lit ? const Color(0xFF6A5A48) : const Color(0xFF3A3630);
    for (final tw in tree.twigs) {
      final path = Path()..moveTo(tw.first.dx, tw.first.dy);
      for (final q in tw.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      c.drawPath(path, twig);
    }
    leaves(0.75, 0.9, 11);
    final pic = rec.endRecording();
    final img = pic.toImageSync(
      (_treeBox.width * _treePx).ceil(),
      (_treeBox.height * _treePx).ceil(),
    );
    pic.dispose();
    return _treeImg[i] = img;
  }

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

  /// Umay ağacı (kontrol noktası): yaşlı, salkım dallı ak kayın; dal
  /// uçlarına bağlanmış uzun, ince çaputlar (çoğu ak, biraz gök mavisi, az
  /// al: Altay ve Anadolu dilek ağaçlarındaki gibi), dibinde dilek taşları.
  /// [lit] 0: uyuyan (soluk, çaputlar sarkık), 1: uyanmış (tacın içinden
  /// yumuşak ışık, rüzgârda kalkan çaputlar).
  /// Gövdenin toprağa girdiği yer orijindedir; kökler toprağın altındadır.
  static void umayTree(
    Canvas c,
    double t, {
    double lit = 1,
    bool bloom = false,
  }) {
    if (lit > 0) {
      // Işık tacın içinden: küçük, yumuşak; ağacı çevreleyen bir hâle değil.
      c.drawOval(
        Rect.fromCenter(center: const Offset(-4, -58), width: 90, height: 60),
        Paint()
          ..shader = ui.Gradient.radial(const Offset(-4, -58), 45, [
            const Color(0xFFFFE8B0)
                .withValues(alpha: (0.22 + 0.04 * math.sin(t * 1.3)) * lit),
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
    // Dibinde birkaç dilek taşı.
    final stone = Paint();
    final stoneRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = const Color(0xFF2A221C);
    for (final (x, y, w, h, tone) in const [
      (7.0, -1.6, 7.0, 3.4, 0.2),
      (13.0, -1.4, 5.5, 2.8, 0.6),
      (10.0, -4.2, 5.0, 2.8, 0.4),
      (-9.0, -1.4, 5.0, 2.6, 0.5),
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
    // Çaputlar: dal uçlarından sarkan uzun, ince bezler.
    const white = Color(0xFFF2EEE4);
    const blue = Color(0xFF8AB0D8);
    const red = Color(0xFFB0382E);
    final knots = _treeShape.knots;
    for (var i = 0; i < knots.length; i++) {
      final col = i % 7 == 3 ? red : (i % 3 == 1 ? blue : white);
      _caput(
        c,
        knots[i],
        col,
        12.0 + (i * 7 % 5) * 1.6,
        t,
        lit,
        i,
        width: 0.75,
      );
    }
    // Son ağaç: uyanınca çiçek açar.
    if (bloom && lit > 0) {
      final petal = Paint();
      final r = math.Random(9);
      for (final (pt, _) in _treeShape.leaves) {
        if (r.nextDouble() > 0.35) continue;
        petal.color =
            (r.nextBool() ? const Color(0xFFFFF6F4) : const Color(0xFFF6C8D0))
                .withValues(alpha: lit * 0.9);
        c.drawCircle(pt, 1.2 + r.nextDouble(), petal);
      }
    }
    // Uyanınca birkaç yaprak savrulur.
    if (lit > 0) {
      final leaf = Paint();
      for (var i = 0; i < 6; i++) {
        final u = (t * 0.08 + _hash(i + 70)) % 1;
        final x =
            (_hash(i + 80) - 0.5) * 70 + math.sin(t * 1.3 + i * 2) * 5 * u;
        final y = -70 + u * 70;
        leaf.color = const Color(0xFFC8C478)
            .withValues(alpha: lit * math.sin(u * math.pi) * 0.8);
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
    final shape = akAnaSilhouette;
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
    final shape = ayazAtaSilhouette;
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
    final shape = kamSilhouette;
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
    final shape = albastiSilhouette;
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

  /// Koşan at: eklemli beden, yürüyüşten dörtnalaya. [phase] 0-1 adım
  /// döngüsü, [weight] 0 duruş · 1 tam dörtnala, [leap] havada uzanma (ön
  /// ayaklar ileri kıvrılır, arka ayaklar geri itilir). Ölçü durağan at
  /// siluetiyle (MythShapes.horse) aynı: ayaklar 0'da, sağa bakar.
  static Path horseRun(double phase, {double weight = 1, double leap = 0}) {
    final th = phase * 2 * math.pi;
    final bob = -math.sin(th * 2).abs() * 3 * weight;
    Path leg(
      Offset root,
      double a,
      double knee,
      double up,
      double lo,
      double w0,
      bool hind,
    ) {
      final k = root + Offset(math.sin(a), math.cos(a)) * up;
      final b = a + knee;
      final f = k + Offset(math.sin(b), math.cos(b)) * lo;
      var out = _strip([root, k], w0, w0 * 0.55);
      for (final p in [
        Path()..addOval(Rect.fromCircle(center: k, radius: w0 * 0.3)),
        _strip([k, f], w0 * 0.45, w0 * 0.32),
        // Toynak.
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: f + const Offset(1.5, -1.5),
              width: w0 * 0.75,
              height: 5,
            ),
            const Radius.circular(1.5),
          ),
        ),
      ]) {
        out = Path.combine(PathOperation.union, out, p);
      }
      return out;
    }

    final parts = <Path>[];
    // Döner dörtnala: arka sol, arka sağ, ön sol, ön sağ. Kökler gövdenin
    // içinde (uyluk ve omuz gövdeye karışır).
    for (final (root, off, hind) in [
      (Offset(-34, -60 + bob), 0.0, true),
      (Offset(-29, -60 + bob), 0.1, true),
      (Offset(27, -58 + bob), 0.45, false),
      (Offset(32, -58 + bob), 0.55, false),
    ]) {
      final sw = math.sin(th + off * 2 * math.pi) * weight;
      final lift = math.max(0.0, math.cos(th + off * 2 * math.pi)) * weight;
      var a = sw * 0.55 + (hind ? -0.12 : 0.0);
      // Arka bacakta topuk geriye, ön bacakta diz öne kırılır.
      var knee = hind ? (0.45 + 0.7 * lift) : -(0.1 + 1.1 * lift);
      if (leap > 0) {
        a = a * (1 - leap) + (hind ? 0.9 : -1.0) * leap;
        knee = knee * (1 - leap) + (hind ? 0.2 : -1.2) * leap;
      }
      parts.add(
        leg(
          root,
          -a,
          -knee,
          hind ? 32 : 30,
          hind ? 30 : 30,
          hind ? 11 : 8.5,
          hind,
        ),
      );
    }
    // Gövde: yuvarlak sağrı, derin göğüs.
    parts.add(
      Path()
        ..moveTo(-48, -60 + bob)
        ..cubicTo(-48, -78 + bob, -26, -75 + bob, 0, -73 + bob)
        ..cubicTo(20, -73 + bob, 34, -76 + bob, 42, -64 + bob)
        ..cubicTo(46, -54 + bob, 40, -46 + bob, 30, -44 + bob)
        ..cubicTo(10, -42 + bob, -14, -45 + bob, -32, -46 + bob)
        ..cubicTo(-44, -48 + bob, -50, -52 + bob, -48, -60 + bob)
        ..close(),
    );
    // Kalın boyun ve uzun baş: koşarken boyun öne uzanır, adımla iner kalkar.
    final nod = math.sin(th * 2 + 0.6) * 3 * weight + leap * 4;
    final hx = nod * 0.5;
    final hy = bob + nod;
    parts.add(
      Path()
        ..moveTo(22, -70 + bob)
        ..cubicTo(26, -84 + bob, 34 + hx, -94 + hy, 42 + hx, -100 + hy)
        ..lineTo(44 + hx, -106 + hy)
        ..lineTo(48 + hx, -100 + hy)
        ..cubicTo(56 + hx, -96 + hy, 64 + hx, -86 + hy, 66 + hx, -80 + hy)
        ..cubicTo(66 + hx, -74 + hy, 60 + hx, -73 + hy, 55 + hx, -76 + hy)
        ..cubicTo(50 + hx, -78 + hy, 48, -70 + bob, 44, -58 + bob)
        ..cubicTo(40, -52 + bob, 34, -50 + bob, 30, -52 + bob)
        ..close(),
    );
    // Gür kuyruk: sağrıdan dalgalanarak geriye.
    final swish = math.sin(th * 2 + 1.4) * 5 * weight + leap * 6;
    parts.add(
      Path()
        ..moveTo(-46, -68 + bob)
        ..cubicTo(
          -58,
          -70 + bob,
          -64,
          -60 + bob + swish * 0.4,
          -66 - swish * 0.4,
          -42 + bob + swish,
        )
        ..cubicTo(-60, -38 + bob + swish, -54, -46 + bob, -50, -56 + bob)
        ..close(),
    );
    var shape = parts.first;
    for (final p in parts.skip(1)) {
      shape = Path.combine(PathOperation.union, shape, p);
    }
    return shape;
  }

  /// Çalkuyruk: Er Töştük'ün konuşan atı. Koyu doru beden, yerin altının
  /// soğuk mavi ışığıyla çevrili kenar; yelesi rüzgârda.
  static void calkuyruk(Canvas c, double t, {double alpha = 1, Path? shape}) {
    _inkBody(
      c,
      shape ?? MythShapes.horse,
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

  /// Er Töştük'ün duvara düşen gölgesi: kut ışığının vurduğu taşta, atının
  /// sırtında bir atlı.
  static void erTostukShadow(Canvas c, double t) {
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -55), width: 190, height: 140),
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -55), 95, [
          const Color(0xFFFFE0A0).withValues(alpha: 0.28),
          const Color(0x00FFE0A0),
        ]),
    );
    final ink = Paint()
      ..color = const Color(0xFF05030A).withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    c.save();
    c.translate(0, math.sin(t * 0.8) * 1.2);
    c.drawPath(MythShapes.horse, ink);
    // Atlı: insan siluetinin belden yukarısı, eyerde.
    c.save();
    c.translate(4, -31.75);
    c.scale(0.55);
    c.clipRect(const Rect.fromLTRB(-80, -130, 80, -55));
    c.drawPath(MythShapes.kam, ink);
    c.restore();
    c.restore();
  }

  // ----------------------------------------------------------- Ergenekon

  /// Asena: Göktürk efsanesinin dişi kurdu; gümüş-boz ışıktan, sıcak.
  /// Kurtardığı çocuğu koruyan ana kurt.
  static void asena(Canvas c, double t, {double alpha = 1}) {
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 110, height: 9),
      Paint()
        ..color = const Color(0xFFE8D8B0).withValues(alpha: 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    _skyBody(
      c,
      MythShapes.wolfStand,
      t,
      top: const Color(0xFFF6F0E2),
      bottom: const Color(0xFFB8A888),
      glow: const Color(0xFFF0E0B8),
      star: const Color(0xFFFFF8E8),
      alpha: alpha,
      stars: 20,
    );
    _eyeGlow(c, const Offset(39, -84), const Color(0xFFFFF0C8), alpha);
  }

  /// Demirci: örsün başında, elinde çekiç; ocağın ateşiyle kenarı yanar.
  static void demirci(Canvas c, double t) {
    final strike = math.pow((t * 0.9) % 1, 3).toDouble();
    const fire = Color(0xFFFF8A3A);
    _inkBody(c, MythShapes.kam, t, rim: fire);
    // Örs.
    final ink = Paint()..color = const Color(0xFF140C08);
    c.drawPath(
      Path()
        ..moveTo(18, -22)
        ..lineTo(46, -22)
        ..lineTo(42, -16)
        ..lineTo(36, -14)
        ..lineTo(36, 0)
        ..lineTo(26, 0)
        ..lineTo(26, -14)
        ..lineTo(20, -16)
        ..close(),
      ink,
    );
    // Örsün üstünde kızgın demir.
    c.drawRect(
      const Rect.fromLTWH(26, -25, 14, 3),
      Paint()..color = const Color(0xFFFFB050),
    );
    // Çekiç: sağ elden kalkıp iner.
    const hand = Offset(25, -46);
    final ang = -2.3 + strike * 1.6;
    final head = hand + Offset(math.cos(ang), math.sin(ang)) * 18;
    c.drawLine(
      hand,
      head,
      Paint()
        ..color = const Color(0xFF140C08)
        ..strokeWidth = 1.6,
    );
    c.drawRect(Rect.fromCenter(center: head, width: 7, height: 5), ink);
    if (strike > 0.9) {
      final spark = Paint()..color = const Color(0xFFFFE0A0);
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + (i - 2.5) * 0.4;
        c.drawCircle(
          const Offset(33, -26) + Offset(math.cos(a), math.sin(a)) * 8,
          0.9,
          spark,
        );
      }
    }
    _eyeGlow(c, const Offset(-0.8, -94), fire, 0.5);
  }

  /// Ülgen'in ışığı: biçimi olmayan, kendini anlatan bir aydınlık; dönen
  /// ışınlar ve ağır ağır atan bir öz.
  static void ulgenLight(Canvas c, double t) {
    const at = Offset(0, -70);
    c.drawCircle(
      at,
      90,
      Paint()
        ..shader = ui.Gradient.radial(at, 90, [
          const Color(0xFFFFFBEA).withValues(alpha: 0.9),
          const Color(0x00FFE8B0),
        ]),
    );
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFF4D0).withValues(alpha: 0.55);
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + t * 0.15;
      final len = 50 + 18 * math.sin(t * 1.3 + i * 1.7);
      ray.strokeWidth = i.isEven ? 2.2 : 1.2;
      c.drawLine(
        at + Offset(math.cos(a), math.sin(a)) * 22,
        at + Offset(math.cos(a), math.sin(a)) * len,
        ray,
      );
    }
    c.drawCircle(
      at,
      14 + 2 * math.sin(t * 2),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  /// Küçük Umay yeri (oba): dilek taşlarından bir yığın, tepesine dikili bir
  /// değnek ve ona bağlı çaputlar. Ağaca yakın kayıt noktalarında ağacın
  /// yerine durur. [lit] 0: uyuyan, 1: uyanmış.
  static void umayCairn(Canvas c, double t, {double lit = 1}) {
    if (lit > 0) {
      c.drawCircle(
        const Offset(0, -16),
        30,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(0, -16), 30, [
            const Color(0xFFFFE8B0).withValues(alpha: 0.35 * lit),
            const Color(0x00FFE8B0),
          ]),
      );
    }
    final stone = Paint();
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = Color.lerp(
        const Color(0xFF2A221C),
        const Color(0xFFFFE0A0),
        lit * 0.8,
      )!;
    for (final (x, y, w, h, tone) in const [
      (-7.0, -1.8, 7.5, 3.8, 0.1),
      (0.5, -2.0, 8.0, 4.2, 0.5),
      (7.5, -1.6, 6.5, 3.4, 0.3),
      (-3.5, -5.6, 6.5, 3.6, 0.7),
      (3.5, -5.8, 6.0, 3.4, 0.2),
      (0.0, -9.0, 5.0, 3.0, 0.6),
    ]) {
      final r = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
      stone.color = Color.lerp(
        const Color(0xFF4A423A),
        const Color(0xFF8A8074),
        tone,
      )!;
      c.drawOval(r, stone);
      c.drawOval(r, rim);
    }
    // Değnek: yığının tepesinden hafif eğik.
    const top = Offset(2, -34);
    c.drawLine(
      const Offset(0, -9),
      top,
      Paint()
        ..color = const Color(0xFF3A2414)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    const cols = [
      Color(0xFFF2EEE4),
      Color(0xFF8AB0D8),
      Color(0xFFF2EEE4),
      Color(0xFFB0382E),
    ];
    for (var i = 0; i < 4; i++) {
      final k = Offset.lerp(const Offset(0, -12), top, 0.45 + i * 0.17)!;
      _caput(c, k, cols[i], 7.5 - i * 0.6, t, lit, i + 40, width: 0.9);
    }
  }
}

class _Branch {
  _Branch(this.pts, this.w0, this.w1);
  final List<Offset> pts;
  final double w0;
  final double w1;
}

/// Kayının dal yapısı: dallar, sarkık ince dallar, yaprak yerleri ve çaput
/// düğümleri (bir kez, sabit tohumla).
class _TreeShape {
  _TreeShape(this.branches, this.twigs, this.leaves, this.knots);

  final List<_Branch> branches;
  final List<List<Offset>> twigs;
  final List<(Offset, double)> leaves;
  final List<Offset> knots;

  static _TreeShape build() {
    final rnd = math.Random(1453);
    final branches = <_Branch>[];
    final twigs = <List<Offset>>[];
    final leaves = <(Offset, double)>[];
    final ends = <Offset>[];

    // Bir dal: [angle] yönünde, uca doğru sarkarak büyür.
    void grow(Offset start, double angle, double len, double w, int depth) {
      final pts = <Offset>[start];
      var a = angle;
      const steps = 8;
      for (var j = 1; j <= steps; j++) {
        // Uca doğru yerçekimi: dal aşağı kıvrılır (derin dallarda daha çok).
        final droop = depth <= 1 ? 0.012 : 0.03 + (depth - 2) * 0.05;
        a +=
            (math.pi / 2 - a) * droop * (j / steps) +
            (rnd.nextDouble() - 0.5) * 0.18;
        pts.add(pts.last + Offset(math.cos(a), math.sin(a)) * (len / steps));
      }
      final wEnd = math.max(0.3, w * 0.45);
      branches.add(_Branch(pts, w, wEnd));
      final end = pts.last;
      if (depth >= 3 || len < 7) {
        ends.add(end);
        // Sarkık ince dallar ve yaprakları.
        final n = 2 + rnd.nextInt(3);
        for (var k = 0; k < n; k++) {
          final from = Offset.lerp(pts[2], end, 0.4 + rnd.nextDouble() * 0.6)!;
          final hang = 9 + rnd.nextDouble() * 12;
          final sway = (rnd.nextDouble() - 0.5) * 6;
          final tw = <Offset>[from];
          for (var j = 1; j <= 5; j++) {
            final u = j / 5;
            tw.add(from + Offset(sway * u + math.sin(u * 3) * 1.2, hang * u));
          }
          twigs.add(tw);
          for (var j = 1; j < tw.length; j++) {
            leaves.add((tw[j], 2.6 + rnd.nextDouble() * 1.4));
            if (rnd.nextBool()) {
              leaves.add((tw[j] + const Offset(1.4, 0.6), 2.4));
            }
          }
        }
        for (var j = 2; j < pts.length; j++) {
          leaves.add((pts[j], 3.0 + rnd.nextDouble() * 1.6));
        }
        return;
      }
      // İkinci kat dallarda da yaprak: tac dolgun ama seyrek kalsın.
      if (depth >= 2) {
        for (var j = 3; j < pts.length; j += 2) {
          leaves.add((pts[j] + Offset(0, -1.5), 3.2 + rnd.nextDouble() * 1.4));
        }
      }
      final kids = depth == 0 ? 3 : 2 + rnd.nextInt(2);
      for (var k = 0; k < kids; k++) {
        final spread = depth == 1 ? 0.7 : 0.5;
        final da =
            (k - (kids - 1) / 2) * spread + (rnd.nextDouble() - 0.5) * 0.3;
        final from = Offset.lerp(pts[3], end, 0.5 + rnd.nextDouble() * 0.5)!;
        grow(
          from,
          a + da - 0.15,
          len * (0.72 + rnd.nextDouble() * 0.12),
          w * 0.62,
          depth + 1,
        );
      }
    }

    // Gövde: hafif eğik, kalın; üstte dallara ayrılır.
    const trunk = <Offset>[
      Offset(0, 0),
      Offset(-0.8, -8),
      Offset(-2.2, -16),
      Offset(-2.6, -24),
      Offset(-1.8, -31),
    ];
    branches.add(_Branch(trunk, 4.2, 2.6));
    // Toprağa yayılan dip.
    branches.add(
      _Branch(
        const [Offset(-9, 1), Offset(-4.6, -1), Offset(-4, -6)],
        1.4,
        2.0,
      ),
    );
    // Ana dallar: iki yana dengeli, biri yukarı.
    grow(trunk.last, -math.pi / 2 - 0.85, 25, 2.0, 1);
    grow(trunk.last, -math.pi / 2 - 0.1, 26, 2.0, 1);
    grow(trunk.last, -math.pi / 2 + 0.7, 25, 1.9, 1);
    grow(const Offset(-2.4, -21), -math.pi / 2 - 1.25, 18, 1.4, 2);
    grow(const Offset(-2.2, -18), -math.pi / 2 + 1.15, 18, 1.4, 2);

    // Çaput düğümleri: dal uçlarından, tacın her yanına yayılmış ~14 tane.
    ends.sort((a, b) => a.dx.compareTo(b.dx));
    final knots = <Offset>[];
    final step = math.max(1, ends.length ~/ 14);
    for (var i = 0; i < ends.length; i += step) {
      knots.add(ends[i]);
    }
    return _TreeShape(branches, twigs, leaves, knots);
  }
}
