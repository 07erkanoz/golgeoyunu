// Kaf'ın renk ve doku ayrıntıları (CARTOON açıkken). Dağların biçimi, karı
// ve renkleri olduğu gibi kalır; üstlerine siluet dilinde ayrıntı eklenir:
// doruğa oyulmuş tüy, kayadan zümrüt ışık sızdıran damarlar ve altın
// kenarlı süzülen tüyler.
import 'dart:math' as math;
import 'dart:ui';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _emerald = Color(0xFF7FFFC8);
const _gold = Color(0xFFFFD27A);

/// Dağlardan sonra çizilir. [peak]: Kaf doruğunun ucu, [peakBase]: eteği,
/// [nearBase]: yakın sıradağın tabanı (ekran).
void paintKafDetails(
  Canvas canvas,
  double w,
  double h,
  Offset cam,
  double t, {
  required Offset peak,
  required double peakBase,
  required double nearBase,
}) {
  final tall = peakBase - peak.dy;
  final glow = 0.6 + 0.4 * math.sin(t * 0.8);
  // Doruğun gövdesine oyulmuş tüy: karın altında, kayanın koyu yüzünde.
  canvas.save();
  canvas.translate(peak.dx, peak.dy + tall * 0.5);
  _feather(
    canvas,
    tall * 0.13,
    const Color(0x00000000),
    const Color(0xFF0E2C26).withValues(alpha: 0.8),
    barbs: true,
  );
  for (var k = 0; k < 5; k++) {
    canvas.drawCircle(
      Offset(0, -tall * 0.1 + k * tall * 0.05),
      1.6,
      Paint()..color = _gold.withValues(alpha: 0.3 + 0.3 * glow),
    );
  }
  canvas.restore();
  // Doruğun eteğinde zümrüt damarlar.
  for (var k = 0; k < 5; k++) {
    final u = (k - 2) * 0.2 + (_hash(k, 61) - 0.5) * 0.1;
    final x = peak.dx + u * tall * 0.7;
    final y0 = peak.dy + tall * (0.62 + 0.1 * _hash(k, 62));
    _vein(canvas, Offset(x, y0), 3, 0.8, t + k);
  }
  // Yakın sıradağda, kayanın içinden sızan zümrüt ışık.
  const spacing = 170.0;
  final off = cam.dx * 0.18;
  final first = (off / spacing).floor() - 1;
  for (var i = first; i * spacing - off < w + spacing; i++) {
    if (_hash(i, 63) < 0.45) continue;
    final x = i * spacing - off + _hash(i, 64) * 90;
    final y = nearBase + 14 + _hash(i, 65) * (h - nearBase) * 0.4;
    _vein(canvas, Offset(x, y), 2 + (_hash(i, 66) * 2).floor(), 1, t + i);
  }
  // Süzülen Simurg tüyleri: siluet, altın kenarlı.
  for (var i = 0; i < 7; i++) {
    final k = (t * (0.02 + i * 0.004) + i * 0.37) % 1.0;
    final x =
        ((i * 211.0 + math.sin(t * 0.5 + i) * 60 - cam.dx * 0.3) % w + w) % w;
    canvas.save();
    canvas.translate(x, h * k);
    canvas.rotate(math.sin(t + i) * 0.8);
    _feather(
      canvas,
      11,
      const Color(0xFF14302A),
      _gold.withValues(alpha: 0.55),
    );
    canvas.restore();
  }
}

/// Aşağı inen bir sıra baklava oyuk; içlerinden nabız gibi zümrüt ışık.
void _vein(Canvas canvas, Offset at, int n, double a, double phase) {
  final pulse = 0.6 + 0.4 * math.sin(phase * 0.9);
  for (var k = 0; k < n; k++) {
    final c = at + Offset(k * 1.5, k * 12.0);
    final s = 3.0 - k * 0.5;
    canvas.drawCircle(
      c,
      s * 5,
      Paint()
        ..shader = Gradient.radial(c, s * 5, [
          _emerald.withValues(alpha: 0.26 * a * pulse),
          _emerald.withValues(alpha: 0),
        ]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - s * 1.5)
        ..lineTo(c.dx + s, c.dy)
        ..lineTo(c.dx, c.dy + s * 1.5)
        ..lineTo(c.dx - s, c.dy)
        ..close(),
      Paint()..color = _emerald.withValues(alpha: 0.7 * a * pulse),
    );
  }
}

/// Tüy: sap, iki yanda kavisli yaprak; [barbs] ise tel çizgileri.
void _feather(
  Canvas canvas,
  double len,
  Color fill,
  Color line, {
  bool barbs = false,
}) {
  final vane = Path()
    ..moveTo(0, -len)
    ..quadraticBezierTo(len * 0.32, -len * 0.3, len * 0.08, len * 0.7)
    ..lineTo(0, len * 0.75)
    ..lineTo(-len * 0.08, len * 0.7)
    ..quadraticBezierTo(-len * 0.32, -len * 0.3, 0, -len)
    ..close();
  if (fill.a > 0) canvas.drawPath(vane, Paint()..color = fill);
  final stroke = Paint()
    ..color = line
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1, len * 0.014);
  canvas.drawPath(vane, stroke);
  canvas.drawLine(Offset(0, -len * 0.9), Offset(0, len), stroke);
  if (!barbs) return;
  for (var k = 1; k < 9; k++) {
    final y = -len * 0.8 + k * len * 0.17;
    final half = len * 0.22 * math.sin(k / 9 * math.pi);
    canvas.drawLine(Offset(0, y), Offset(half, y - len * 0.08), stroke);
    canvas.drawLine(Offset(0, y), Offset(-half, y - len * 0.08), stroke);
  }
}
