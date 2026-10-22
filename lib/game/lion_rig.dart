import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'ark_animals.dart' show smoothClosed;
import 'lion_shapes.dart';

/// Aslanın yürüyüşü ya da dörtnalası.
enum LionGait { walk, gallop }

/// Bir karenin silueti ve kabartma işlemesinin dayandığı noktalar.
class LionFrame {
  const LionFrame(this.shape, this.hip, this.shoulder, this.head, this.tilt);
  final Path shape;
  final Offset hip;
  final Offset shoulder;

  /// Baş-yele parçasının boyna bağlandığı yer ve eğimi (radyan).
  final Offset head;
  final double tilt;
}

/// Aslan Horoskobu'nun iskeleti: Gökbörü'nün eklemli kurt iskeletinden
/// (wolf_rig.dart) türetildi; aslan oranlarıyla: kalın bacaklar, iri
/// pençeler, derin göğüs, ucu püsküllü kuyruk. Baş ve yele, CC0 aslan
/// siluetinden (Margot Michaud) kesilip boyna bağlanır. Ölçü: ~100 birim
/// boy, ayaklar 0'da, sağa bakar.
///
/// [crouch] (0–1): saldırı öncesi çömelme (göğüs yere yaklaşır, sağrı
/// toplanır, kuyruk savrulur).
class LionRig {
  LionRig._();

  /// Bir dörtnala döngüsünde alınan yol (birim).
  static const double gallopStride = 170;

  /// Bir yürüyüş döngüsünde alınan yol (birim).
  static const double walkStride = 150;

  static Path? _headCache;

  /// Siluetin baş-yele parçası (kaynakta boynun arkası (16, -64)).
  static Path get headPiece => _headCache ??= Path.combine(
    PathOperation.intersect,
    _decode(lionWalkData),
    Path()..addRect(const Rect.fromLTRB(10, -104, 80, -36)),
  );

  static const Offset _neckInSource = Offset(16, -64);

  static Path _decode(List<double> d) {
    final p = Path();
    var i = 0;
    while (i < d.length) {
      switch (d[i].toInt()) {
        case 0:
          p.moveTo(d[i + 1], d[i + 2]);
          i += 3;
        case 1:
          p.lineTo(d[i + 1], d[i + 2]);
          i += 3;
        case 2:
          p.cubicTo(d[i + 1], d[i + 2], d[i + 3], d[i + 4], d[i + 5], d[i + 6]);
          i += 7;
        default:
          p.close();
          i += 1;
      }
    }
    return p;
  }

  static const double _foreA = 30, _foreB = 30, _foreC = 11;
  static const double _hindA = 28, _hindB = 30, _hindC = 18;

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
    final sweep = (gallop ? LionRig.gallopStride : LionRig.walkStride) * stance;
    final lift = gallop ? (front ? 24.0 : 20.0) : (front ? 12.0 : 9.0);
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

  static LionFrame frame(
    LionGait gait,
    double phase, {
    double leap = 0,
    double crouch = 0,
    double t = 0,
  }) {
    final gallop = gait == LionGait.gallop;
    final th = phase % 1.0;
    final pi2 = 2 * math.pi;
    final l = leap.clamp(0.0, 1.0);
    final cr = crouch.clamp(0.0, 1.0);
    final flex = gallop ? math.cos(pi2 * (th - 0.92)) * (1 - l) - l : 0.0;
    final bob = gallop
        ? -3.5 * math.cos(2 * pi2 * (th - 0.4)) * (1 - l) - 6 * l
        : -2.0 * math.cos(2 * pi2 * (th - 0.2));
    final pitch = gallop ? -3.0 * math.sin(pi2 * (th - 0.2)) * (1 - l) : 0.0;
    // Çömelince göğüs iner, sağrı biraz daha az iner (atılmaya hazır).
    final hip = Offset(
      -40 + 5 * flex + 4 * cr,
      -62 + bob - pitch * 0.5 + 14 * cr,
    );
    final sho = Offset(30 - 2 * flex - 2 * cr, -64 + bob + pitch + 22 * cr);
    final mid = (hip + sho) / 2;

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
    final stance = gallop ? 0.30 : 0.5;
    final parts = <Path>[];
    for (final (front, off, near) in legs) {
      final baseX = front ? 30.0 : -40.0;
      var (paw, dir) = _foot(
        front: front,
        gallop: gallop,
        baseX: baseX,
        u: cr > 0 ? 0.25 : (th - off) % 1.0,
        stance: cr > 0 ? 1.0 : stance,
      );
      if (cr > 0) {
        // Çömelme: pençeler yerde, ön ayaklar biraz önde.
        paw = Offset(baseX + (front ? 8 : -2) + (near ? 0 : 6), 0);
      }
      final root = (front ? sho : hip) + Offset(near ? 0 : 3, near ? 0 : -1);
      if (l > 0) {
        final reach = front
            ? sho + Offset(near ? 48 : 42, near ? 30 : 34)
            : hip + Offset(near ? -48 : -42, near ? 26 : 30);
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
              ? [13 * shrink, 8 * shrink, 5.5, 4.6]
              : [16 * shrink, 8.5 * shrink, 5.6, 4.6],
        ),
      );
      parts.add(
        Path()..addOval(
          Rect.fromCenter(
            center: paw + const Offset(3.2, -2.6),
            width: 15,
            height: 7.5,
          ),
        ),
      );
    }

    // Gövde: derin göğüs, ağır sağrı, karında hafif sarkma.
    final arch = 3.5 * math.max(0.0, flex);
    parts.add(
      smoothClosed([
        hip + const Offset(-16, -4),
        hip + const Offset(-6, -16),
        mid + Offset(0, -17 - arch),
        sho + const Offset(-8, -20),
        sho + const Offset(12, -12),
        sho + const Offset(22, 6),
        sho + const Offset(10, 30),
        sho + const Offset(-12, 30),
        mid + const Offset(6, 19),
        hip + const Offset(14, 15),
        hip + const Offset(3, 20),
        hip + const Offset(-15, 13),
        hip + const Offset(-20, 0),
      ]),
    );

    // Baş ve yele: siluetten kesilen parça boyna bağlanır; adımla iner
    // kalkar, çömelince alçalıp öne uzanır.
    final nod = gallop
        ? 2 * math.cos(2 * pi2 * (th - 0.4)) * (1 - l)
        : 1.6 * math.sin(2 * pi2 * th);
    final head = sho + Offset(-6 + 4 * cr, -4 + nod + 6 * cr);
    final tilt = (gallop ? 0.12 : 0.0) + 0.14 * cr;
    final m = Matrix4Lite.rotateAround(tilt, head, _neckInSource);
    parts.add(headPiece.transform(m));

    // Kuyruk: uzun, ince; ucunda püskül. Yürürken sarkar, koşarken geriye
    // uzanır, çömelince sağa sola savrulur.
    final lash = math.sin(t * 6) * 10 * cr;
    final wave = math.sin(pi2 * th * (gallop ? 1 : 2) + 1) * (gallop ? 4 : 2);
    final tb = hip + const Offset(-16, -6);
    final spine = gallop
        ? [
            tb,
            tb + Offset(-16, 1 + wave * 0.4),
            tb + Offset(-32, 3 + wave),
            tb + Offset(-46, 2 + wave * 1.6),
          ]
        : [
            tb,
            tb + Offset(-10, 8 + lash * 0.3),
            tb + Offset(-15 + lash * 0.6, 22 + wave * 0.5 - cr * 14),
            tb + Offset(-14 + lash, 38 + wave - cr * 30),
          ];
    const tw = [3.6, 2.6, 2.2, 1.8];
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
    final tip = spine.last;
    parts.add(
      Path()..addOval(Rect.fromCenter(center: tip, width: 9, height: 12)),
    );

    var shape = parts.first;
    for (final p in parts.skip(1)) {
      shape = Path.combine(PathOperation.union, shape, p);
    }
    return LionFrame(shape, hip, sho, head, tilt);
  }
}

/// Döndürme + taşıma: kaynaktaki [pivot] noktası [to] noktasına gelir,
/// [angle] kadar döner (Path.transform için 4×4 dizi).
abstract final class Matrix4Lite {
  static Float64List rotateAround(double angle, Offset to, Offset pivot) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    // x' = c(x - px) - s(y - py) + tx ; y' = s(x - px) + c(y - py) + ty
    final tx = to.dx - c * pivot.dx + s * pivot.dy;
    final ty = to.dy - s * pivot.dx - c * pivot.dy;
    return Float64List.fromList([
      c, s, 0, 0, //
      -s, c, 0, 0,
      0, 0, 1, 0,
      tx, ty, 0, 1,
    ]);
  }
}
