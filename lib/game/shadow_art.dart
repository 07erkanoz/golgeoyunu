import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import 'rig.dart';

/// Bekçi ve Medusa çizimleri (kullanıcının verdiği paketteki vektörler,
/// assets/art/bekci_medusa.json). Her parça yüklemede bir kez `Picture`
/// olarak kaydedilir; karede yalnız yerleştirilir. Yüklenemezse eski kod
/// çizimleri kullanılır.
abstract final class ShadowArt {
  static Map<String, dynamic>? _data;
  static final _guard = <String, ui.Picture>{};
  static final _medusa = <String, ui.Picture>{};

  static bool get ready => _data != null;

  static Future<void> load() async {
    if (_data != null) return;
    try {
      final text = await rootBundle.loadString('assets/art/bekci_medusa.json');
      final data = jsonDecode(text) as Map<String, dynamic>;
      _record(data['guard'] as Map<String, dynamic>, _guard);
      _record(data['medusa'] as Map<String, dynamic>, _medusa);
      _data = data;
    } catch (_) {
      // Çizim yoksa kod çizimine düşülür.
    }
  }

  static List<Offset> snakeRoots(int i) => [
    for (final p in (_data!['snakes'] as List)[i] as List)
      Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
  ];

  static void guard(Canvas c, String id) {
    final p = _guard[id];
    if (p != null) c.drawPicture(p);
  }

  static void medusa(Canvas c, String id) {
    final p = _medusa[id];
    if (p != null) c.drawPicture(p);
  }

  // ------------------------------------------------------ vektör okuma

  static void _record(Map<String, dynamic> src, Map<String, ui.Picture> out) {
    final parts = src['parts'] as Map<String, dynamic>;
    for (final id in parts.keys) {
      final rec = ui.PictureRecorder();
      _node(ui.Canvas(rec), parts[id], 1, src);
      out[id] = rec.endRecording();
    }
  }

  static double _num(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return s.endsWith('%')
        ? double.parse(s.substring(0, s.length - 1)) / 100
        : double.parse(s);
  }

  static Color _hex(String s, [double opacity = 1]) =>
      Color(int.parse(s.substring(1), radix: 16) | 0xff000000)
          .withAlpha((opacity * 255).round().clamp(0, 255));

  static Path _path(dynamic n) {
    final p = Path();
    final a = n['a'] as Map<String, dynamic>;
    if (n['tag'] == 'ellipse') {
      return p..addOval(
        Rect.fromCenter(
          center: Offset(_num(a['cx']), _num(a['cy'])),
          width: 2 * _num(a['rx']),
          height: 2 * _num(a['ry']),
        ),
      );
    }
    for (final dynamic row in n['ops'] as List) {
      final v = (row as List).skip(1).map(_num).toList();
      switch (row[0]) {
        case 'M':
          p.moveTo(v[0], v[1]);
        case 'L':
          p.lineTo(v[0], v[1]);
        case 'Q':
          p.quadraticBezierTo(v[0], v[1], v[2], v[3]);
        case 'C':
          p.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
        case 'Z':
          p.close();
      }
    }
    return p;
  }

  static Paint _paint(
    String value,
    List box,
    double opacity,
    Map<String, dynamic> src,
  ) {
    final paint = Paint()..isAntiAlias = true;
    if (!value.startsWith('url(')) return paint..color = _hex(value, opacity);
    final g = src['gradients'][value.substring(5, value.length - 1)];
    final a = g['a'];
    final x = _num(box[0]), y = _num(box[1]);
    final w = _num(box[2]), h = _num(box[3]);
    final colors = <Color>[];
    final stops = <double>[];
    for (final st in g['stops'] as List) {
      colors.add(
        _hex(
          st['stop-color'] ?? '#000000',
          _num(st['stop-opacity'], 1) * opacity,
        ),
      );
      stops.add(_num(st['offset']));
    }
    if (g['kind'] == 'linearGradient') {
      paint.shader = ui.Gradient.linear(
        Offset(x + _num(a['x1']) * w, y + _num(a['y1']) * h),
        Offset(x + _num(a['x2'], 1) * w, y + _num(a['y2']) * h),
        colors,
        stops,
      );
    } else {
      paint.shader = ui.Gradient.radial(
        Offset(x + _num(a['cx'], .5) * w, y + _num(a['cy'], .5) * h),
        math.max(.001, _num(a['r'], .5) * math.max(w, h)),
        colors,
        stops,
      );
    }
    return paint;
  }

  static void _node(
    Canvas canvas,
    dynamic n,
    double inherited,
    Map<String, dynamic> src,
  ) {
    final a = n['a'] as Map<String, dynamic>;
    final opacity = inherited * _num(a['opacity'], 1);
    canvas.save();
    final transform = a['transform'];
    if (transform != null) {
      for (final m in RegExp(
        r'(translate|rotate|scale)\(([^)]+)\)',
      ).allMatches(transform as String)) {
        final v = m[2]!
            .trim()
            .split(RegExp(r'[ ,]+'))
            .map(double.parse)
            .toList();
        switch (m[1]) {
          case 'translate':
            canvas.translate(v[0], v.length > 1 ? v[1] : 0);
          case 'rotate':
            canvas.rotate(v[0] * math.pi / 180);
          case 'scale':
            canvas.scale(v[0], v.length > 1 ? v[1] : v[0]);
        }
      }
    }
    final clip = a['clip-path'];
    if (clip != null) {
      final paths =
          src['clips'][(clip as String).substring(5, clip.length - 1)] as List?;
      if (paths != null && paths.isNotEmpty) {
        canvas.clipPath(_path(paths.first));
      }
    }
    if (n['tag'] == 'g') {
      for (final child in n['children'] as List) {
        _node(canvas, child, opacity, src);
      }
    } else if (n['tag'] == 'path' || n['tag'] == 'ellipse') {
      final p = _path(n);
      final box = n['box'] as List;
      final fill = a['fill'] ?? '#000000';
      if (fill != 'none') canvas.drawPath(p, _paint(fill, box, opacity, src));
      final stroke = a['stroke'];
      if (stroke != null && stroke != 'none') {
        canvas.drawPath(
          p,
          _paint(stroke, box, opacity, src)
            ..style = PaintingStyle.stroke
            ..strokeWidth = _num(a['stroke-width'], 1)
            ..strokeCap = a['stroke-linecap'] == 'round'
                ? StrokeCap.round
                : StrokeCap.butt
            ..strokeJoin = a['stroke-linejoin'] == 'round'
                ? StrokeJoin.round
                : StrokeJoin.miter,
        );
      }
    }
    canvas.restore();
  }
}

// ================================================================ Bekçi

/// Çizimin ölçeği (sanat birimi → dünya pikseli) ve ayak noktası.
const double guardArtScale = 0.08;
const Offset guardArtFeet = Offset(275, 777);

/// Fenerin asılı olduğu kanca ve fenerin ortası (sanat birimi).
const Offset guardLampPivot = Offset(542, 184);
const Offset guardLampCenter = Offset(550, 303);

/// Bekçinin karanlık silueti. Çizim bekçinin yerel alanında, ayakları
/// [feet]'te; [phase] adım döngüsü (0-1), [weight] yürüyüş miktarı, [run]
/// koşu, [lean] öne eğilme, [lampAngle] fenerin kancadaki salınımı, [doubt]
/// başın şüpheyle kalkışı. Gözler [eye] renginde yanar; fener ışığı
/// çağıran kod tarafından çizilir (ışığın yeri oyunun mantığıyla aynı).
void drawShadowGuard(
  Canvas c, {
  required Offset feet,
  required double phase,
  required double weight,
  required double run,
  required double lean,
  required double lampAngle,
  required double doubt,
  required Color ink,
  required Color rim,
  required Color eye,
  required Color lampGlass,
}) {
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(guardArtScale);
  c.translate(-guardArtFeet.dx, -guardArtFeet.dy);
  const bounds = Rect.fromLTRB(60, 80, 760, 820);
  void body() => _guardBody(c, phase, weight, run, lean, lampAngle, doubt);
  // Kenar ışığı: gövdenin biraz kaydırılmış kopyası, ışık renginde.
  c.saveLayer(
    bounds,
    Paint()..colorFilter = ColorFilter.mode(rim, BlendMode.srcIn),
  );
  c.translate(-10, -8);
  body();
  c.translate(10, 8);
  c.restore();
  c.saveLayer(
    bounds,
    Paint()..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn),
  );
  body();
  c.restore();
  // Başlığın karanlığında iki göz.
  c.save();
  _headFrame(c, phase, weight, run, lean, doubt);
  final e = Paint()..color = eye;
  c.drawOval(
    Rect.fromCenter(center: const Offset(349, 247), width: 30, height: 13),
    e,
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(369, 250), width: 24, height: 11),
    e,
  );
  c.restore();
  // Fenerin camı: ışıklı.
  final lamp = guardLampArt(phase, weight, run, lean, lampAngle);
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: lamp, width: 70, height: 96),
      const Radius.circular(18),
    ),
    Paint()..color = lampGlass,
  );
  c.restore();
}

/// Fenerin ortası (sanat birimi): ışık ve görüş buradan çıkar.
Offset guardLampArt(
  double phase,
  double weight,
  double run,
  double lean,
  double lampAngle,
) {
  final shift = _shift(phase, weight);
  final bob = _bob(phase, weight);
  final hip = Offset(276, 588 + bob);
  final hook = _rot(guardLampPivot + shift + Offset(0, bob), hip, lean);
  final d = guardLampCenter - guardLampPivot;
  return hook + _rotV(d, lampAngle);
}

double _bob(double phase, double weight) =>
    -math.cos(2 * math.pi * phase * 2) * 3.4 * weight;

Offset _shift(double phase, double weight) => Offset(
  math.sin(2 * math.pi * phase) * 4 * weight,
  math.cos(2 * math.pi * phase) * 2.5 * weight,
);

Offset _rotV(Offset v, double a) => Offset(
  v.dx * math.cos(a) - v.dy * math.sin(a),
  v.dx * math.sin(a) + v.dy * math.cos(a),
);

Offset _rot(Offset p, Offset about, double a) => about + _rotV(p - about, a);

/// Ayağın yeri (sanat birimi, kalçanın altına göre): duruşta yerde geriye
/// kayar (dünyada sabit), salınımda kalkıp öne gelir.
Offset _foot(double p, double weight, double run) {
  p %= 1;
  const duty = 0.62;
  final cycle = (26 + 20 * run) / guardArtScale;
  final span = cycle * duty * weight;
  if (p < duty) return Offset(span * (.5 - p / duty), 0);
  final u = (p - duty) / (1 - duty);
  final e = 0.5 - math.cos(u * math.pi) / 2;
  final wave = math.sin(math.pi * u);
  return Offset(-span / 2 + span * e, -(43 + 30 * run) * wave * wave * weight);
}

void _headFrame(
  Canvas c,
  double phase,
  double weight,
  double run,
  double lean,
  double doubt,
) {
  final bob = _bob(phase, weight);
  final hip = Offset(276, 588 + bob);
  c.translate(hip.dx, hip.dy);
  c.rotate(lean);
  c.translate(-hip.dx, -hip.dy + bob);
  const neck = Offset(305, 282);
  c.translate(neck.dx, neck.dy);
  c.rotate(-0.22 * doubt);
  c.translate(-neck.dx + doubt * 14, -neck.dy);
}

void _bone(Canvas c, Offset a, Offset b, double r1, double r2) {
  final v = b - a;
  final l = math.max(.001, v.distance);
  final n = Offset(-v.dy / l, v.dx / l);
  final paint = Paint()..color = const Color(0xFF000000);
  c.drawPath(
    Path()..addPolygon([a + n * r1, b + n * r2, b - n * r2, a - n * r1], true),
    paint,
  );
  c.drawCircle(a, r1, paint);
  c.drawCircle(b, r2, paint);
}

void _guardBody(
  Canvas c,
  double phase,
  double weight,
  double run,
  double lean,
  double lampAngle,
  double doubt,
) {
  final bob = _bob(phase, weight);
  final hipY = 588 + bob;
  // Bacaklar (kalçadan bileğe iki kemik, çizilmiş çizme).
  void leg(double hipX, double footX, double p, String boot, double bootX) {
    final f = _foot(p, weight, run);
    final foot = Offset(footX + f.dx, 777 + f.dy);
    final ankle = foot - const Offset(0, 46);
    final hip = Offset(hipX, hipY);
    final (knee, end) = solveLimb(hip, ankle, 94, 90, bend: 1);
    _bone(c, hip, knee, 14, 12);
    _bone(c, knee, end, 12, 9);
    c.save();
    c.translate(end.dx - bootX, end.dy + 46 - 777);
    ShadowArt.guard(c, boot);
    c.restore();
  }

  leg(244, 244, phase + .5, 'boot-back', 224);
  leg(309, 309, phase, 'boot-front', 350);
  // Üst beden kalçadan öne eğilir.
  final hip = Offset(276, hipY);
  c.save();
  c.translate(hip.dx, hip.dy);
  c.rotate(lean);
  c.translate(-hip.dx, -hip.dy + bob);
  c.save();
  c.translate(192, 350);
  c.rotate(-.06 * math.sin(2 * math.pi * phase) * weight - run * 0.2);
  c.translate(-192, -350);
  ShadowArt.guard(c, 'arm-back');
  c.restore();
  for (final id in ['torso', 'belt-and-pouch', 'coat-wear']) {
    ShadowArt.guard(c, id);
  }
  c.save();
  c.translate(251, 459);
  c.rotate(.08 * math.sin(2 * math.pi * phase + .5) * weight);
  c.translate(-251, -459);
  ShadowArt.guard(c, 'keys');
  c.restore();
  c.save();
  const neck = Offset(305, 282);
  c.translate(neck.dx, neck.dy);
  c.rotate(-0.22 * doubt);
  c.translate(-neck.dx + doubt * 14, -neck.dy);
  ShadowArt.guard(c, 'head');
  c.restore();
  final shift = _shift(phase, weight);
  const shoulder = Offset(301, 341);
  final wrist = const Offset(440, 350) + shift;
  final (elbow, end) = solveLimb(shoulder, wrist, 90, 87, bend: -1);
  _bone(c, shoulder, elbow, 17, 15);
  _bone(c, elbow, end, 14, 11);
  c.save();
  c.translate(shift.dx, shift.dy);
  ShadowArt.guard(c, 'staff');
  ShadowArt.guard(c, 'hand-front');
  c.translate(guardLampPivot.dx, guardLampPivot.dy);
  c.rotate(lampAngle);
  c.translate(-guardLampPivot.dx, -guardLampPivot.dy);
  ShadowArt.guard(c, 'lantern');
  c.restore();
  c.restore();
}

// ================================================================ Medusa

/// Medusa'nın görsel durumu: yılanların zamanı ve enerjisi (gözler açıldıkça
/// kıvranır, taşa dönünce donar).
class MedusaArtState {
  double snakeTime = 0;
  double energy = .25;

  void update(double dt, {required double eyes, required bool sealed}) {
    if (sealed) return;
    snakeTime += dt;
    energy += (.25 + .75 * eyes - energy) * (1 - math.exp(-dt * 4));
  }
}

/// Çizimin ölçeği ve gözlerin ortası (sanat birimi).
const double medusaArtScale = 0.105;
const Offset medusaEyes = Offset(363, 392);

/// Sarnıç taşı tonunda Medusa: canlı yılanlar, açılıp kapanan gözler.
/// Gözlerin ortası yerelde [eyesAt]'tadır.
void drawStoneMedusa(
  Canvas c,
  MedusaArtState s, {
  required Offset eyesAt,
  required double eyes,
  required bool sealed,
}) {
  c.save();
  c.translate(eyesAt.dx, eyesAt.dy);
  c.scale(medusaArtScale);
  c.translate(-medusaEyes.dx, -medusaEyes.dy);
  c.saveLayer(
    const Rect.fromLTRB(-60, -60, 760, 760),
    Paint()
      ..colorFilter = ColorFilter.matrix(
        sealed
            ? const <double>[
                0.28, 0.42, 0.10, 0, 0, //
                0.27, 0.42, 0.10, 0, 0, //
                0.25, 0.40, 0.10, 0, 0, //
                0, 0, 0, 1, 0,
              ]
            : const <double>[
                0.30, 0.45, 0.10, 0, 0, //
                0.28, 0.45, 0.10, 0, 0, //
                0.24, 0.38, 0.10, 0, 0, //
                0, 0, 0, 1, 0,
              ],
      ),
  );
  for (var i = 0; i < 9; i++) {
    _snake(c, s, i);
  }
  for (final id in ['stone-base', 'face-planes', 'ears', 'eye-sockets']) {
    ShadowArt.medusa(c, id);
  }
  final e = eyes.clamp(0.0, 1.0);
  if (e < 1) {
    c.saveLayer(
      const Rect.fromLTRB(280, 360, 450, 430),
      Paint()..color = Color.fromRGBO(255, 255, 255, 1 - e),
    );
    ShadowArt.medusa(c, 'eyes-closed');
    c.restore();
  }
  if (e > 0) {
    c.save();
    c.translate(0, 392);
    c.scale(1, math.max(.02, e));
    c.translate(0, -392);
    ShadowArt.medusa(c, 'eyes-awake');
    c.restore();
  }
  for (final id in [
    'nose',
    'mouth',
    'carved-hair-band',
    'temple-curls',
    'cracks',
    'medusa-face-texture',
    'stone-edge-light',
  ]) {
    ShadowArt.medusa(c, id);
  }
  c.restore();
  c.restore();
}

void _snake(Canvas c, MedusaArtState s, int index) {
  final raw = ShadowArt.snakeRoots(index);
  final pts = <Offset>[];
  for (var j = 0; j < raw.length; j++) {
    if (j == 0) {
      pts.add(raw[j]);
      continue;
    }
    final w = math.pow(j / 6, 1.2).toDouble();
    pts.add(
      raw[j] +
          Offset(
            math.sin(
                  s.snakeTime * (1.15 + index * .071) + index * 1.7 + j * .6,
                ) *
                10 *
                w *
                s.energy,
            math.sin(s.snakeTime * (.86 + index * .053) + index + j * .8) *
                8 *
                w *
                s.energy,
          ),
    );
  }
  final samples = <Offset>[];
  for (var seg = 0; seg < pts.length - 1; seg++) {
    final a = pts[math.max(0, seg - 1)], b = pts[seg], cc = pts[seg + 1];
    final d = pts[math.min(pts.length - 1, seg + 2)];
    for (var j = 0; j < 6; j++) {
      final t = j / 6, t2 = t * t, t3 = t2 * t;
      samples.add(
        (b * 2 +
                (cc - a) * t +
                (a * 2 - b * 5 + cc * 4 - d) * t2 +
                (-a + b * 3 - cc * 3 + d) * t3) *
            .5,
      );
    }
  }
  samples.add(pts.last);
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < samples.length; i++) {
    final v =
        samples[math.min(i + 1, samples.length - 1)] -
        samples[math.max(i - 1, 0)];
    final l = math.max(.001, v.distance);
    final r = 16 + (10 - 16) * (i / (samples.length - 1));
    final n = Offset(-v.dy / l * r, v.dx / l * r);
    left.add(samples[i] + n);
    right.add(samples[i] - n);
  }
  final outline = Path()..addPolygon([...left, ...right.reversed], true);
  c.drawPath(outline, Paint()..color = const Color(0xFF4E6A60));
  c.drawPath(
    outline,
    Paint()
      ..color = const Color(0xFF263B39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  final tangent = samples.last - samples[samples.length - 2];
  c.save();
  c.translate(samples.last.dx, samples.last.dy);
  c.rotate(math.atan2(tangent.dy, tangent.dx));
  ShadowArt.medusa(c, 'snake-${(index + 1).toString().padLeft(2, '0')}-head');
  c.restore();
}
