import 'dart:ui';

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
