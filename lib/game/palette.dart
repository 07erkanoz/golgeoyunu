import 'dart:ui';
import 'dart:ui' as ui;

/// "Kızıl kül" paleti: kömür siluetler, pas tonlu dünya. Sıcak ışık güvenli,
/// fenercilerin soğuk camgöbeği ışığı tehlike demek.
const kInk = Color(0xFF0A0706);
const kCloud = Color(0xFF24161A);
const kLight = Color(0xFFF7EEE2);
const kText = Color(0xFFEBDDCB);
const kEmber = Color(0xFFE0703A);
const kWarmLight = Color(0xFFFFD9A0);
const kCold = Color(0xFF7FE6D2);

Color lerpColor(int a, int b, double t) =>
    Color.lerp(Color(a), Color(b), t.clamp(0.0, 1.0))!;

/// Yumuşak ışık lekesi. Bulanıklık filtresi yerine radyal degrade kullanır:
/// görüntü aynı, ama dahili ekran kartlarında çok daha ucuz.
void glowDot(
  Canvas canvas,
  Offset c,
  double radius,
  Color color,
  double alpha,
) {
  if (alpha <= 0 || radius <= 0) return;
  canvas.drawCircle(
    c,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        c,
        radius,
        [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.45),
          color.withValues(alpha: 0),
        ],
        const [0, 0.4, 1],
      ),
  );
}
