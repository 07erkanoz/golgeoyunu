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
}
