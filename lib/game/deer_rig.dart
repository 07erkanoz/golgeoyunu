import 'dart:math' as math;
import 'dart:ui';

import 'ark_animals.dart' show smoothClosed;
import 'wolf_rig.dart' show WolfFrame;

/// Ak Geyik'in eklemli iskeleti (Gökbörü'nün kurt iskeletinden uyarlandı):
/// ince uzun bacaklar (ön bacakta dirsek geriye, arka bacakta topuk geriye),
/// uzun dik boyun, dallı boynuzlar, kalkık kısa kuyruk. Ölçü: omuz ~80
/// birim, boynuz ucu ~135 birim; ayaklar 0'da, sağa bakar.
class DeerRig {
  DeerRig._();

  /// Bir yürüyüş döngüsünde alınan yol (birim).
  static const double walkStride = 120;

  static const double _foreA = 25, _foreB = 26, _foreC = 13;
  static const double _hindA = 26, _hindB = 27, _hindC = 19;

  static double _ease(double v) => v * v * (3 - 2 * v);

  static Offset _lerp(Offset a, Offset b, double t) => a + (b - a) * t;

  static Offset _norm(Offset v, double len) => v / v.distance * len;

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
    return (cross(k1) > 0) == (bend > 0) ? k1 : k2;
  }

  /// Kökten uca incelen, eklemleri yuvarlak dal (bacak ya da boynuz).
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

  static (Offset, Offset) _foot({
    required bool front,
    required double baseX,
    required double u,
    required double stance,
  }) {
    final sweep = walkStride * stance;
    final lift = front ? 16.0 : 12.0;
    final neutral = baseX + (front ? 2 : 4);
    if (u < stance) {
      final k = u / stance;
      final hoof = Offset(neutral + sweep * (0.5 - k), 0);
      final dir = front
          ? _lerp(const Offset(-1, -13), const Offset(-5, -12), k)
          : _lerp(const Offset(-6, -18), const Offset(-10, -16), k);
      return (hoof, dir);
    }
    // Salınım: toynak kalkar, bilek bükülür (geyik ayağını yüksek kaldırır).
    final v = (u - stance) / (1 - stance);
    final x = neutral + sweep * (-0.5 + _ease(v));
    final y = -lift * math.sin(math.pi * math.pow(v, 0.8));
    final Offset dir;
    if (front) {
      dir = v < 0.5
          ? _lerp(const Offset(-5, -12), const Offset(11, -4), v * 2)
          : _lerp(const Offset(11, -4), const Offset(-1, -13), v * 2 - 1);
    } else {
      dir = v < 0.5
          ? _lerp(const Offset(-10, -16), const Offset(-14, -9), v * 2)
          : _lerp(const Offset(-14, -9), const Offset(-6, -18), v * 2 - 1);
    }
    return (Offset(x, y), dir);
  }

  /// [phase] yürüyüş evresi; [leap] sıçrayış (0-1); [graze] baş yerde
  /// otlar (0-1); [alert] baş dik, kulaklar kalkık (0-1).
  static WolfFrame frame(
    double phase, {
    double leap = 0,
    double graze = 0,
    double alert = 0,
    bool still = false,
  }) {
    final th = phase % 1.0;
    final pi2 = 2 * math.pi;
    final l = leap.clamp(0.0, 1.0);
    final g = graze.clamp(0.0, 1.0);
    final bob = still ? 0.0 : -1.6 * math.cos(2 * pi2 * (th - 0.2));
    final hip = Offset(-34, -68 + bob - 8 * l);
    final sho = Offset(28, -70 + bob - 12 * l);
    final mid = (hip + sho) / 2;

    const legs = [
      (false, 0.00, true),
      (true, 0.03, false),
      (false, 0.50, false),
      (true, 0.53, true),
    ];
    const stance = 0.55;
    final parts = <Path>[];
    for (final (front, off, near) in legs) {
      final baseX = front ? 28.0 : -34.0;
      var (hoof, dir) = _foot(
        front: front,
        baseX: baseX,
        u: still ? (near ? 0.27 : 0.27) : (th - off) % 1.0,
        stance: stance,
      );
      if (still) hoof = Offset(baseX + (front ? 2 : 4) + (near ? 3 : -3), 0);
      final root = (front ? sho : hip) + Offset(near ? 0 : 3, near ? 0 : -1);
      if (l > 0) {
        // Havada: ön bacaklar göğse katlanır, arka bacaklar geri uzanır.
        final reach = front
            ? sho + Offset(near ? 22 : 18, near ? 40 : 44)
            : hip + Offset(near ? -48 : -42, near ? 34 : 38);
        hoof = _lerp(hoof, reach, l);
        dir = _lerp(
          dir,
          front ? const Offset(14, -8) : const Offset(12, -18),
          l,
        );
      }
      final joint = hoof + _norm(dir, front ? _foreC : _hindC);
      final a = front ? _foreA : _hindA;
      final b = front ? _foreB : _hindB;
      final knee = _knee(root, joint, a, b, front ? 1 : -1);
      final shrink = near ? 1.0 : 0.88;
      parts.add(
        _limb(
          [root, knee, joint, hoof],
          front
              ? [8.5 * shrink, 3.8 * shrink, 2.6, 2.2]
              : [12 * shrink, 4.6 * shrink, 2.8, 2.2],
        ),
      );
      // Küçük, sivri toynak.
      parts.add(
        Path()
          ..moveTo(hoof.dx - 3, hoof.dy - 3)
          ..lineTo(hoof.dx + 5, hoof.dy + 0.5)
          ..lineTo(hoof.dx - 3, hoof.dy + 0.8)
          ..close(),
      );
    }

    // Gövde: ince bel, yuvarlak sağrı, derin göğüs.
    parts.add(
      smoothClosed([
        hip + const Offset(-15, -3),
        hip + const Offset(-6, -14),
        mid + const Offset(0, -12),
        sho + const Offset(-6, -15),
        sho + const Offset(10, -10),
        sho + const Offset(17, 4),
        sho + const Offset(7, 20),
        sho + const Offset(-10, 20),
        mid + const Offset(6, 13),
        hip + const Offset(11, 11),
        hip + const Offset(3, 16),
        hip + const Offset(-12, 11),
        hip + const Offset(-17, 1),
      ]),
    );

    // Boyun ve baş: yürürken baş dik, adımla hafifçe iner kalkar; otlarken
    // yere eğilir; sıçrarken ileri uzanır.
    final nod = still ? 0.0 : 1.4 * math.sin(2 * pi2 * th);
    final up = sho + const Offset(20, -42) + Offset(0, nod - 4 * alert);
    final down = sho + const Offset(34, 52);
    final fly = sho + const Offset(34, -28);
    final head = _lerp(_lerp(up, down, _ease(g)), fly, l);
    final ang = -0.15 + 1.2 * _ease(g) + 0.25 * l;
    Offset hp(double x, double y) =>
        head +
        Offset(
          x * math.cos(ang) - y * math.sin(ang),
          x * math.sin(ang) + y * math.cos(ang),
        );
    // Boyun: üst kenar omuzdan başın arkasına, alt kenar göğüsten çeneye.
    final ge = _ease(g);
    Offset nk(Offset upA, Offset downA) => sho + _lerp(upA, downA, ge);
    parts.add(
      smoothClosed([
        nk(const Offset(-8, -13), const Offset(-6, -14)),
        nk(const Offset(4, -26), const Offset(14, -8)),
        hp(-6, -4),
        hp(0, -5),
        hp(2, 5),
        nk(const Offset(20, -12), const Offset(28, 26)),
        nk(const Offset(17, 2), const Offset(16, 14)),
      ]),
    );
    // İnce, uzun baş; burun ucu yuvarlak.
    parts.add(
      smoothClosed([
        hp(-7, -1),
        hp(-4, -6),
        hp(3, -6.5),
        hp(10, -4),
        hp(17, -2),
        hp(20, 0.5),
        hp(18, 3),
        hp(10, 4),
        hp(2, 5),
        hp(-5, 4),
      ]),
    );
    // Yaprak biçimli kulaklar: dikkat kesilince dikleşir.
    for (final (base, tipBack, tipUp) in [
      (hp(-3, -5), hp(-14, -9), hp(-6, -16)),
      (hp(-6, -4), hp(-16, -6), hp(-10, -14)),
    ]) {
      final tip = _lerp(tipBack, tipUp, alert);
      final side = Offset(-(tip - base).dy, (tip - base).dx) * 0.22;
      parts.add(
        Path()
          ..moveTo(base.dx - side.dx, base.dy - side.dy)
          ..quadraticBezierTo(
            (base.dx + tip.dx) / 2 + side.dx * 2.2,
            (base.dy + tip.dy) / 2 + side.dy * 2.2,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            (base.dx + tip.dx) / 2 - side.dx * 0.6,
            (base.dy + tip.dy) / 2 - side.dy * 0.6,
            base.dx + side.dx,
            base.dy + side.dy,
          )
          ..close(),
      );
    }
    // Dallı boynuzlar: ana dal geriye ve yukarı kıvrılır; dört çatal.
    for (final (shift, k) in [
      (const Offset(0, 0), 1.0),
      (const Offset(4, 1), 0.9),
    ]) {
      Offset ap(double x, double y) => hp(x * k + shift.dx, y * k + shift.dy);
      final beam = [ap(-1, -6), ap(-7, -22), ap(-4, -36), ap(2, -50)];
      parts.add(_limb(beam, const [2.4, 2.0, 1.6, 1.0]));
      for (final (from, to) in [
        (ap(-6, -15), ap(5, -20)),
        (ap(-6, -28), ap(-17, -34)),
        (ap(-4, -36), ap(7, -42)),
        (ap(-2, -43), ap(-10, -53)),
      ]) {
        parts.add(_limb([from, to], const [1.5, 0.8]));
      }
    }

    // Kısa, kalkık kuyruk.
    final tb = hip + const Offset(-13, -5);
    parts.add(
      smoothClosed([
        tb,
        tb + const Offset(-7, -6),
        tb + const Offset(-11, -2),
        tb + const Offset(-6, 4),
      ]),
    );

    var shape = parts.first;
    for (final p in parts.skip(1)) {
      shape = Path.combine(PathOperation.union, shape, p);
    }
    return WolfFrame(shape, hp(6, -2));
  }
}
