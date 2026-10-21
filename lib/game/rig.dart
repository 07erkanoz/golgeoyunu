import 'dart:math' as math;
import 'dart:ui';

/// Karakter çizimlerinin ortak iskelet yardımcıları: iki kemikli uzuv,
/// kare hızından bağımsız yay ve yumuşak geçiş. Sâye, Kandilci ve öteki
/// figürler aynı kurallarla hareket eder.

/// İki kemikli uzuv (bacak, kol): kökten hedefe. Eklem (diz, dirsek)
/// [bend] yönünde kırılır: +1 ileri (+x), -1 geri. Hedef erişilemeyecek kadar
/// uzaksa uç, uzvun boyunca hedefe doğru kısaltılır: kemik hiçbir zaman
/// uzamaz.
(Offset joint, Offset end) solveLimb(
  Offset root,
  Offset target,
  double upper,
  double lower, {
  double bend = 1,
}) {
  final reach = upper + lower - 0.01;
  var d = target - root;
  var dist = d.distance;
  if (dist < 0.01) {
    d = const Offset(0, 0.01);
    dist = 0.01;
  }
  final end = dist > reach ? root + d * (reach / dist) : target;
  final len = math.min(dist, reach);
  final base = math.atan2(d.dy, d.dx);
  final cosA = ((upper * upper + len * len - lower * lower) / (2 * upper * len))
      .clamp(-1.0, 1.0);
  final a = math.acos(cosA);
  final j1 = root + Offset(math.cos(base - a), math.sin(base - a)) * upper;
  final j2 = root + Offset(math.cos(base + a), math.sin(base + a)) * upper;
  final joint = (j1.dx - j2.dx) * bend >= 0 ? j1 : j2;
  return (joint, end);
}

/// Kökün, [foot] noktasına [reach] uzunluktaki uzuvla erişebilmesi için en az
/// ne kadar aşağıda (büyük y) olması gerektiği. Erişiliyorsa [rootY] döner.
double lowerToReach(double rootX, double rootY, Offset foot, double reach) {
  final dx = (foot.dx - rootX).abs();
  if (dx >= reach) return foot.dy;
  final dy = math.sqrt(reach * reach - dx * dx);
  return math.max(rootY, foot.dy - dy);
}

/// Hedefe üstel yaklaşma: [tau] saniyede yolun ~%63'ü. Kare hızından
/// bağımsızdır.
double approach(double x, double target, double dt, double tau) =>
    tau <= 0 ? target : x + (target - x) * (1 - math.exp(-dt / tau));

/// Sönümlü yay: gecikmeli salınım (kavanoz, fener, atkı, etek). 1/120
/// saniyelik alt adımlarla ilerler; 30 ile 144 Hz arasında aynı davranır.
class Spring {
  Spring({required this.stiffness, required this.damping});

  /// Yay sertliği (1/sn²): yüksekse hızlı döner.
  final double stiffness;

  /// Sönüm (1/sn): yüksekse az salınır.
  final double damping;

  double value = 0;
  double velocity = 0;

  void update(double target, double dt) {
    var left = math.min(dt, 0.1);
    while (left > 1e-6) {
      final h = math.min(left, 1 / 120);
      final a = stiffness * (target - value) - damping * velocity;
      velocity += a * h;
      value += velocity * h;
      left -= h;
    }
  }

  /// Dışarıdan bir itki (ör. iniş, çarpma).
  void kick(double v) => velocity += v;

  void reset([double v = 0]) {
    value = v;
    velocity = 0;
  }
}

/// İki pozu karıştırır.
Offset blendPose(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;
