import 'dart:math' as math;
import 'dart:ui';

import 'ark_animals.dart' show smoothClosed;

/// Kurdun tırısı (yürür gibi ilerleyişi) ya da dörtnalası.
enum WolfGait { walk, gallop }

/// Bir karenin silueti ve gözün yeri.
class WolfFrame {
  const WolfFrame(this.shape, this.eye);
  final Path shape;
  final Offset eye;
}

/// Eklemli kurt iskeleti: gerçek anatomiye göre bükülen bacaklar (ön
/// bacakta dirsek geriye, arka bacakta diz öne, topuk geriye), basarken
/// yerde duran pençeler, dörtnalada toplanıp gerilen sırt. Ölçü: ~100 birim
/// boy, ayaklar 0'da, sağa bakar.
///
/// Basan pençe yerde kaymasın diye adım uzunluğu, çağıranın evreyi
/// ilerletme oranına eşittir: dörtnala [gallopStride], yürüyüş
/// [walkStride] birim yol başına bir döngü.
class WolfRig {
  WolfRig._();

  /// Bir dörtnala döngüsünde alınan yol (birim).
  static const double gallopStride = 145;

  /// Bir yürüyüş döngüsünde alınan yol (birim).
  static const double walkStride = 140;

  // Bacak boyları: üst kemik, alt kemik, uç (tarak) kemiği.
  static const double _foreA = 26, _foreB = 26, _foreC = 10;
  static const double _hindA = 24, _hindB = 26, _hindC = 17;

  static double _ease(double v) => v * v * (3 - 2 * v);

  static Offset _lerp(Offset a, Offset b, double t) => a + (b - a) * t;

  static Offset _norm(Offset v, double len) => v / v.distance * len;

  /// İki kemikli ters kinematik: kökten eklem hedefine; [bendSign] dizin
  /// hangi yana kırılacağı (+1 ön bacak: geriye, -1 arka bacak: öne).
  static Offset _knee(Offset root, Offset joint, double a, double b, int bend) {
    final d = joint - root;
    final dist = d.distance.clamp((a - b).abs() + 0.5, a + b - 0.05);
    final base = math.atan2(d.dy, d.dx);
    final cosA = ((a * a + dist * dist - b * b) / (2 * a * dist)).clamp(
      -1.0,
      1.0,
    );
    final alpha = math.acos(cosA);
    Offset at(double s) =>
        root +
        Offset(math.cos(base + s * alpha), math.sin(base + s * alpha)) * a;
    final k1 = at(1);
    final k2 = at(-1);
    double cross(Offset k) => d.dx * (k - root).dy - d.dy * (k - root).dx;
    // Çapraz çarpımın işareti, dizin çizginin hangi yanında kaldığını söyler.
    return (cross(k1) > 0) == (bend > 0) ? k1 : k2;
  }

  /// Kökten uca incelen, eklemleri yuvarlak bacak.
  static Path _limb(List<Offset> pts, List<double> half) {
    var out = Path();
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final d = b - a;
      final n = Offset(-d.dy, d.dx) / (d.distance + 1e-6);
      out = Path.combine(
        PathOperation.union,
        out,
        Path()
          ..moveTo(a.dx + n.dx * half[i], a.dy + n.dy * half[i])
          ..lineTo(b.dx + n.dx * half[i + 1], b.dy + n.dy * half[i + 1])
          ..lineTo(b.dx - n.dx * half[i + 1], b.dy - n.dy * half[i + 1])
          ..lineTo(a.dx - n.dx * half[i], a.dy - n.dy * half[i])
          ..close(),
      );
      out = Path.combine(
        PathOperation.union,
        out,
        Path()..addOval(Rect.fromCircle(center: b, radius: half[i + 1])),
      );
    }
    return out;
  }

  /// Bir bacağın pençe hedefi ve uç kemiğin yönü (pençeden ekleme).
  static (Offset, Offset) _foot({
    required bool front,
    required bool gallop,
    required double baseX,
    required double u,
    required double stance,
  }) {
    final sweep = (gallop ? gallopStride : walkStride) * stance;
    final lift = gallop ? (front ? 22.0 : 18.0) : (front ? 13.0 : 10.0);
    final neutral = baseX + (front ? 2 : 4);
    if (u < stance) {
      // Basış: pençe yerde, gövde ilerledikçe geriye kalır.
      final k = u / stance;
      final paw = Offset(neutral + sweep * (0.5 - k), 0);
      final dir = front
          ? _lerp(const Offset(-1, -11), const Offset(-5, -9), k)
          : _lerp(const Offset(-7, -15), const Offset(-11, -13), k);
      return (paw, dir);
    }
    // Salınım: pençe kalkar, bilek/topuk bükülür, öne uzanıp yere iner.
    final v = (u - stance) / (1 - stance);
    final x = neutral + sweep * (-0.5 + _ease(v));
    final y = -lift * math.sin(math.pi * math.pow(v, 0.8));
    final Offset dir;
    if (front) {
      dir = v < 0.5
          ? _lerp(const Offset(-5, -9), const Offset(9, -5), v * 2)
          : _lerp(const Offset(9, -5), const Offset(-1, -11), v * 2 - 1);
    } else {
      dir = v < 0.5
          ? _lerp(const Offset(-11, -13), const Offset(-13, -8), v * 2)
          : _lerp(const Offset(-13, -8), const Offset(-7, -15), v * 2 - 1);
    }
    return (Offset(x, y), dir);
  }

  static WolfFrame frame(WolfGait gait, double phase, {double leap = 0}) {
    final gallop = gait == WolfGait.gallop;
    final th = phase % 1.0;
    final pi2 = 2 * math.pi;
    final l = leap.clamp(0.0, 1.0);
    // Sırt: +1 toplanmış (ayaklar gövdenin altında), -1 gerilmiş.
    final flex = gallop ? math.cos(pi2 * (th - 0.92)) * (1 - l) - l : 0.0;
    final bob = gallop
        ? -3.0 * math.cos(2 * pi2 * (th - 0.4)) * (1 - l) - 6 * l
        : -1.8 * math.cos(2 * pi2 * (th - 0.2));
    final pitch = gallop ? -3.0 * math.sin(pi2 * (th - 0.2)) * (1 - l) : 0.0;
    final hip = Offset(-36 + 5 * flex, -54 + bob - pitch * 0.5);
    final sho = Offset(30 - 2 * flex, -56 + bob + pitch);
    final mid = (hip + sho) / 2;

    // Ayak sırası: dörtnala (döner): arka sol, arka sağ, ön sağ, ön sol;
    // ön ayaklar kalktıktan sonra hepsi gövdenin altında toplanıp havada.
    // Tırıs: çapraz ön ve arka ayak birlikte basar.
    final legs = gallop
        ? const [
            (false, 0.00, true),
            (false, 0.08, false),
            (true, 0.42, false),
            (true, 0.52, true),
          ]
        : const [
            (false, 0.00, true),
            (true, 0.03, false),
            (false, 0.50, false),
            (true, 0.53, true),
          ];
    final stance = gallop ? 0.30 : 0.45;
    final parts = <Path>[];
    for (final (front, off, near) in legs) {
      final baseX = front ? 30.0 : -36.0;
      var (paw, dir) = _foot(
        front: front,
        gallop: gallop,
        baseX: baseX,
        u: (th - off) % 1.0,
        stance: stance,
      );
      final root = (front ? sho : hip) + Offset(near ? 0 : 3, near ? 0 : -1);
      if (l > 0) {
        // Havada: ön ayaklar ileri uzanır, arka ayaklar geri itilir.
        final reach = front
            ? sho + Offset(near ? 44 : 38, near ? 30 : 34)
            : hip + Offset(near ? -44 : -38, near ? 26 : 30);
        paw = _lerp(paw, reach, l);
        dir = _lerp(
          dir,
          front ? const Offset(-6, -8) : const Offset(9, -14),
          l,
        );
      }
      final joint = paw + _norm(dir, front ? _foreC : _hindC);
      final a = front ? _foreA : _hindA;
      final b = front ? _foreB : _hindB;
      final knee = _knee(root, joint, a, b, front ? 1 : -1);
      final shrink = near ? 1.0 : 0.9;
      parts.add(
        _limb(
          [root, knee, joint, paw],
          front
              ? [8.5 * shrink, 5 * shrink, 3.4, 3.0]
              : [11.5 * shrink, 5.8 * shrink, 3.6, 3.0],
        ),
      );
      parts.add(
        Path()..addOval(
          Rect.fromCenter(
            center: paw + const Offset(2.4, -2),
            width: 10.5,
            height: 5.4,
          ),
        ),
      );
    }

    // Gövde: derin göğüs, içe çekik karın, güçlü sağrı. Toplanınca sırt
    // kamburlaşır.
    final arch = 3.5 * math.max(0.0, flex);
    parts.add(
      smoothClosed([
        hip + const Offset(-14, -4),
        hip + const Offset(-4, -12),
        mid + Offset(0, -12 - arch),
        sho + const Offset(-6, -16),
        sho + const Offset(10, -10),
        sho + const Offset(19, 5),
        sho + const Offset(8, 24),
        sho + const Offset(-10, 25),
        mid + const Offset(6, 15),
        hip + const Offset(12, 12),
        hip + const Offset(3, 17),
        hip + const Offset(-13, 11),
        hip + const Offset(-17, 0),
      ]),
    );

    // Boyun ve baş: koşarken baş öne ve aşağıda, yürürken biraz yukarıda;
    // adımla hafifçe iner kalkar.
    final nod = gallop
        ? 2 * math.cos(2 * pi2 * (th - 0.4)) * (1 - l)
        : 1.5 * math.sin(2 * pi2 * th);
    final head =
        sho +
        (gallop ? const Offset(33, -17) : const Offset(28, -24)) +
        Offset(0, nod);
    final ang = gallop ? 0.06 : -0.04;
    // Baş biraz iri (ölçek 1,15).
    Offset hp(double x, double y) =>
        head +
        Offset(
              x * math.cos(ang) - y * math.sin(ang),
              x * math.sin(ang) + y * math.cos(ang),
            ) *
            1.15;
    parts.add(
      smoothClosed([
        // Yeleli kalın boyun.
        sho + const Offset(-8, -16),
        sho + const Offset(2, -23),
        hp(-11, -8),
        hp(-2, -2),
        hp(3, 7),
        sho + const Offset(21, 4),
        sho + const Offset(13, -6),
      ]),
    );
    parts.add(
      smoothClosed([
        hp(-12, -1),
        hp(-8, -8),
        hp(0, -10),
        hp(8, -8),
        hp(14, -5.5),
        hp(24, -3.5),
        hp(27.5, -1),
        hp(25, 2.2),
        hp(15, 3.8),
        hp(6, 6),
        hp(-6, 7),
        hp(-12, 4),
      ]),
    );
    // Sivri kulaklar (yakın ve uzak).
    for (final (b0, b1, tip) in [
      (hp(-7, -7), hp(1, -9.5), hp(-6, -21)),
      (hp(-11, -6), hp(-4, -8.5), hp(-12, -18.5)),
    ]) {
      parts.add(
        Path()
          ..moveTo(b0.dx, b0.dy)
          ..quadraticBezierTo(
            (b0.dx + tip.dx) / 2 + 1.5,
            (b0.dy + tip.dy) / 2,
            tip.dx,
            tip.dy,
          )
          ..lineTo(b1.dx, b1.dy)
          ..close(),
      );
    }

    // Gür kuyruk: koşarken geriye uzanır, yürürken aşağı sarkar; adımla
    // dalgalanır.
    final wave = math.sin(pi2 * th * (gallop ? 1 : 2) + 1) * (gallop ? 3 : 1.5);
    final tb = hip + const Offset(-12, -5);
    final spine = gallop
        ? [
            tb,
            tb + Offset(-13, 1 + wave * 0.4),
            tb + Offset(-26, 4 + wave),
            tb + Offset(-38, 7 + wave * 1.4),
          ]
        : [
            tb,
            tb + const Offset(-8, 6),
            tb + Offset(-13, 15 + wave * 0.5),
            tb + Offset(-15, 26 + wave),
          ];
    const tw = [3.5, 6.5, 6.0, 1.2];
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < spine.length; i++) {
      final d =
          spine[math.min(i + 1, spine.length - 1)] - spine[math.max(i - 1, 0)];
      final n = Offset(-d.dy, d.dx) / (d.distance + 1e-6);
      left.add(spine[i] + n * tw[i]);
      right.add(spine[i] - n * tw[i]);
    }
    parts.add(smoothClosed([...left, ...right.reversed]));

    var shape = parts.first;
    for (final p in parts.skip(1)) {
      shape = Path.combine(PathOperation.union, shape, p);
    }
    return WolfFrame(shape, hp(11, -5));
  }
}
