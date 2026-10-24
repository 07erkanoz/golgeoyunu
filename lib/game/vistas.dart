import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'golge_game.dart';
import 'level.dart';
import 'strings.dart';

// ======================================================== Manzara anları
//
// Büyük manzaralar kısa birer görsel ödüldür: Sâye önemli bir yere varınca
// kamera açılır, yukarı bakar; uzak katmanda o yerin manzarası belirir
// (Kule'den Haliç, Gün Doğumu'nda dev başlar arasından doğan güneş,
// Ötüken'de açılan vadi). Birkaç saniye sürer; denetim oyuncudadır.

/// Manzaranın süreleri: açılış, kalış, kapanış.
const _vistaIn = 1.2;
const _vistaHold = 3.2;
const _vistaOut = 1.4;
const vistaLength = _vistaIn + _vistaHold + _vistaOut;

/// Manzara anı başlar mı: Sâye noktaya gelince bir kez.
class VistaPoint extends Component with HasGameReference<GolgeGame> {
  VistaPoint(this.at, this.kind);

  final Vector2 at;
  final String kind;

  @override
  void update(double dt) {
    final p = game.player;
    if (p == null || p.isDead || game.cinematic || !p.onGround) return;
    final d = p.center - at;
    if (d.x.abs() < kTile * 1.5 && d.y.abs() < kTile * 3) {
      game.startVista(kind, at);
      removeFromParent();
    }
  }
}

/// Manzaranın adı (yer adı satırında görünür).
String vistaCaption(String kind) => switch (kind) {
  'halic' => S.en ? 'The Golden Horn' : 'Haliç',
  'sunrise' =>
    S.en ? 'Sunrise over the gods' : 'Tanrıların üstünde doğan güneş',
  'valley' => S.en ? 'The Ötüken Valley' : 'Ötüken Vadisi',
  _ => '',
};

/// Manzaranın görünürlüğü (0 – 1): yumuşak açılış ve kapanış.
double vistaEnvelope(double t) {
  double s(double x) => x * x * (3 - 2 * x);
  if (t < _vistaIn) return s(t / _vistaIn);
  if (t < _vistaIn + _vistaHold) return 1;
  return s((1 - (t - _vistaIn - _vistaHold) / _vistaOut).clamp(0.0, 1.0));
}

/// Arka planın üstüne, dünyanın arkasına çizilir (ekran uzayı).
void paintVista(Canvas canvas, double w, double h, String kind, double t) {
  final a = vistaEnvelope(t);
  if (a <= 0.01) return;
  switch (kind) {
    case 'halic':
      _halic(canvas, w, h, a, t);
    case 'sunrise':
      _sunrise(canvas, w, h, a, t);
    case 'valley':
      _valley(canvas, w, h, a, t);
  }
}

Paint _fill(Color c, double a) => Paint()..color = c.withValues(alpha: c.a * a);

void _sky(Canvas canvas, double w, double h, double a, List<Color> cs) {
  final r = Rect.fromLTWH(0, 0, w, h);
  canvas.drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.linear(
        r.topCenter,
        r.bottomCenter,
        [for (final c in cs) c.withValues(alpha: c.a * a)],
        [for (var i = 0; i < cs.length; i++) i / (cs.length - 1)],
      ),
  );
}

// ------------------------------------------------------------ Haliç
// Galata'nın tepesinden: karşıda tarihî yarımada; kubbeler ve minareler,
// yangının kızıllığı ufukta, Haliç'in suyu şehrin ışıklarını titreterek
// yansıtır. Gökte hilal.
void _halic(Canvas canvas, double w, double h, double a, double t) {
  _sky(canvas, w, h, a, const [
    Color(0xF20A0E22),
    Color(0xF2261A34),
    Color(0xF2702E1E),
  ]);
  // Hilal.
  final moon = Offset(w * 0.8, h * 0.17);
  canvas.drawCircle(
    moon,
    h * 0.12,
    Paint()
      ..shader = ui.Gradient.radial(moon, h * 0.12, [
        const Color(0xFFFFF2D0).withValues(alpha: 0.18 * a),
        const Color(0x00FFF2D0),
      ]),
  );
  canvas.saveLayer(Rect.fromCircle(center: moon, radius: h * 0.05), Paint());
  canvas.drawCircle(moon, h * 0.032, _fill(const Color(0xFFFFF0CC), a));
  canvas.drawCircle(
    moon + Offset(h * 0.014, -h * 0.006),
    h * 0.028,
    Paint()..blendMode = BlendMode.clear,
  );
  canvas.restore();

  final horizon = h * 0.66;
  final k = h / 391;
  final ink = _fill(const Color(0xFF120A0C), a);
  // Yangının ışığı ufukta.
  canvas.drawRect(
    Rect.fromLTWH(0, horizon - h * 0.2, w, h * 0.2),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, horizon - h * 0.2),
        Offset(0, horizon),
        [
          const Color(0x00E07030),
          const Color(0xFFE07030).withValues(alpha: 0.35 * a),
        ],
      ),
  );
  // Evler: alçak, sık damlar.
  final rnd = math.Random(1453);
  final roofs = Path()..moveTo(0, horizon);
  var x = 0.0;
  while (x < w) {
    final bw = (10 + rnd.nextDouble() * 18) * k;
    final bh = (6 + rnd.nextDouble() * 14) * k;
    roofs
      ..lineTo(x, horizon - bh)
      ..lineTo(x + bw * 0.5, horizon - bh - 4 * k)
      ..lineTo(x + bw, horizon - bh);
    x += bw;
  }
  roofs
    ..lineTo(w, horizon)
    ..close();
  canvas.drawPath(roofs, ink);
  // Camiler: büyük kubbe, yarım kubbeler, kalem minareler.
  void mosque(double cx, double s) {
    final r = 34 * k * s;
    final base = horizon - 16 * k * s;
    canvas.drawRect(
      Rect.fromLTRB(cx - r * 1.6, base, cx + r * 1.6, horizon),
      ink,
    );
    for (final dx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(cx + dx * r * 0.95, base), r * 0.55, ink);
    }
    canvas.drawCircle(Offset(cx, base - r * 0.1), r, ink);
    canvas.drawRect(
      Rect.fromLTRB(
        cx - 1.2 * k,
        base - r * 1.25,
        cx + 1.2 * k,
        base - r * 0.9,
      ),
      ink,
    );
    for (final dx in [-1.9, -1.55, 1.55, 1.9]) {
      final mx = cx + dx * r;
      final top = base - r * (dx.abs() > 1.7 ? 2.3 : 2.7);
      canvas.drawRect(Rect.fromLTRB(mx - 2 * k, top, mx + 2 * k, horizon), ink);
      canvas.drawPath(
        Path()
          ..moveTo(mx - 2.4 * k, top)
          ..lineTo(mx, top - 12 * k * s)
          ..lineTo(mx + 2.4 * k, top)
          ..close(),
        ink,
      );
      // Şerefe.
      canvas.drawRect(
        Rect.fromLTRB(mx - 3.4 * k, top + 14 * k, mx + 3.4 * k, top + 16 * k),
        ink,
      );
    }
  }

  mosque(w * 0.3, 1.0);
  mosque(w * 0.62, 0.7);
  mosque(w * 0.86, 0.5);
  // Pencerelerde kandiller.
  final lit = <Offset>[];
  for (var i = 0; i < 46; i++) {
    final lx = rnd.nextDouble() * w;
    final ly = horizon - (2 + rnd.nextDouble() * 10) * k;
    lit.add(Offset(lx, ly));
    final f = 0.6 + 0.4 * math.sin(t * (2 + i % 5) + i);
    canvas.drawCircle(
      Offset(lx, ly),
      1.1 * k,
      _fill(const Color(0xFFFFC870), a * f),
    );
  }
  // Haliç: koyu su, şehrin ışıkları titreyerek uzar.
  final water = Rect.fromLTWH(0, horizon, w, h - horizon);
  canvas.drawRect(
    water,
    Paint()
      ..shader = ui.Gradient.linear(water.topCenter, water.bottomCenter, [
        const Color(0xFF2A1A2A).withValues(alpha: a),
        const Color(0xFF0C0810).withValues(alpha: a),
      ]),
  );
  final glint = Paint()..strokeWidth = 1.2 * k;
  for (var i = 0; i < lit.length; i += 2) {
    final l = lit[i];
    for (var j = 1; j <= 4; j++) {
      final y = horizon + j * 6 * k;
      final wob = math.sin(t * 2.2 + i + j * 1.3) * 3 * k;
      glint.color = const Color(0xFFFFC870).withValues(alpha: a * 0.5 / j);
      canvas.drawLine(
        Offset(l.dx - 5 * k + wob, y),
        Offset(l.dx + 5 * k + wob, y),
        glint,
      );
    }
  }
  // Ayın yolu.
  for (var j = 0; j < 7; j++) {
    final y = horizon + 4 * k + j * 5 * k;
    final wob = math.sin(t * 1.7 + j) * 4 * k;
    canvas.drawLine(
      Offset(moon.dx - 12 * k + wob, y),
      Offset(moon.dx + 12 * k + wob, y),
      glint..color = const Color(0xFFFFF0CC).withValues(alpha: a * 0.35),
    );
  }
}

// ---------------------------------------------------------- Gün doğumu
// Nemrut'un doğu terası: Antiochos'un, tanrıların, kartalın ve aslanın dev
// başları sırayla dizili; güneş aralarından doğar, ışınları taşa vurur.
void _sunrise(Canvas canvas, double w, double h, double a, double t) {
  _sky(canvas, w, h, a, const [
    Color(0xF2281834),
    Color(0xF2A04434),
    Color(0xF2F0A85A),
  ]);
  final ground = h * 0.7;
  final k = h / 391;
  // Güneş: manzara boyunca yükselir.
  final rise = (t / vistaLength).clamp(0.0, 1.0);
  final sun = Offset(w * 0.5, ground - h * (0.02 + 0.14 * rise));
  canvas.drawCircle(
    sun,
    h * 0.5,
    Paint()
      ..shader = ui.Gradient.radial(sun, h * 0.5, [
        const Color(0xFFFFE0A0).withValues(alpha: 0.55 * a),
        const Color(0x00FFC070),
      ]),
  );
  // Işınlar.
  for (var i = 0; i < 9; i++) {
    final ang = -math.pi / 2 + (i - 4) * 0.28 + math.sin(t * 0.3 + i) * 0.02;
    final len = h * (0.7 + (i % 3) * 0.15);
    final half = 0.03;
    canvas.drawPath(
      Path()
        ..moveTo(sun.dx, sun.dy)
        ..lineTo(
          sun.dx + math.cos(ang - half) * len,
          sun.dy + math.sin(ang - half) * len,
        )
        ..lineTo(
          sun.dx + math.cos(ang + half) * len,
          sun.dy + math.sin(ang + half) * len,
        )
        ..close(),
      Paint()
        ..shader = ui.Gradient.radial(sun, len, [
          const Color(0xFFFFE8B0).withValues(alpha: 0.16 * a),
          const Color(0x00FFE8B0),
        ]),
    );
  }
  canvas.drawCircle(sun, h * 0.055, _fill(const Color(0xFFFFF0C8), a));
  // Uzak sıradağlar.
  final far = Path()..moveTo(0, ground);
  for (var x = 0.0; x <= w; x += 8) {
    far.lineTo(x, ground - h * 0.08 - math.sin(x * 0.011) * h * 0.03);
  }
  far
    ..lineTo(w, ground)
    ..close();
  canvas.drawPath(far, _fill(const Color(0xFF5A2E34), a));
  // Teras ve dev başlar.
  final ink = _fill(const Color(0xFF1A0E10), a);
  canvas.drawRect(Rect.fromLTRB(0, ground, w, h), ink);
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6 * k
    ..color = const Color(0xFFFFC070).withValues(alpha: 0.8 * a);
  void head(double cx, double s, String kind) {
    final r = 22 * k * s;
    final base = ground;
    // Başın düştüğü yer: yere gömülü kaide taşı.
    canvas.drawRect(
      Rect.fromLTRB(cx - r * 1.2, base - r * 0.35, cx + r * 1.2, base),
      ink,
    );
    final c = Offset(cx, base - r * 1.15);
    // Güneşe bakan yanı ışık alır.
    final toSun = (sun.dx - cx).sign;
    final shape = Path();
    switch (kind) {
      case 'eagle':
        shape
          ..addOval(Rect.fromCenter(center: c, width: r * 1.4, height: r * 1.5))
          ..moveTo(c.dx + toSun * r * 0.5, c.dy - r * 0.25)
          ..quadraticBezierTo(
            c.dx + toSun * r * 1.35,
            c.dy,
            c.dx + toSun * r * 0.75,
            c.dy + r * 0.5,
          )
          ..lineTo(c.dx + toSun * r * 0.4, c.dy + r * 0.2)
          ..close();
      case 'lion':
        shape.addOval(Rect.fromCircle(center: c, radius: r * 0.95));
        for (var i = 0; i < 12; i++) {
          final ang = i * math.pi / 6;
          shape.addOval(
            Rect.fromCircle(
              center: c + Offset(math.cos(ang), math.sin(ang)) * r * 0.9,
              radius: r * 0.28,
            ),
          );
        }
      default:
        // Tanrı ya da kral: yüz, kıvırcık sakal, kulak kapaklı sivri başlık.
        shape
          ..addOval(
            Rect.fromCenter(center: c, width: r * 1.3, height: r * 1.55),
          )
          ..addOval(
            Rect.fromCenter(
              center: c + Offset(0, r * 0.75),
              width: r * 0.95,
              height: r * 0.8,
            ),
          )
          ..moveTo(c.dx - r * 0.72, c.dy - r * 0.35)
          ..quadraticBezierTo(
            c.dx - r * 0.6,
            c.dy - r * 1.6,
            c.dx + toSun * r * 0.25,
            c.dy - r * 1.95,
          )
          ..quadraticBezierTo(
            c.dx + r * 0.55,
            c.dy - r * 1.3,
            c.dx + r * 0.72,
            c.dy - r * 0.35,
          )
          ..close()
          // Kulak kapakları.
          ..addRect(
            Rect.fromLTRB(
              c.dx - r * 0.78,
              c.dy - r * 0.4,
              c.dx - r * 0.5,
              c.dy + r * 0.4,
            ),
          )
          ..addRect(
            Rect.fromLTRB(
              c.dx + r * 0.5,
              c.dy - r * 0.4,
              c.dx + r * 0.78,
              c.dy + r * 0.4,
            ),
          );
    }
    canvas.drawPath(shape, ink);
    // Işık kenarı: yalnız güneşe bakan yarıda.
    canvas.save();
    canvas.clipRect(
      toSun > 0 ? Rect.fromLTRB(cx, 0, w, base) : Rect.fromLTRB(0, 0, cx, base),
    );
    canvas.drawPath(shape, rim);
    canvas.restore();
  }

  head(w * 0.1, 0.95, 'lion');
  head(w * 0.24, 1.15, 'god');
  head(w * 0.37, 1.3, 'god');
  head(w * 0.63, 1.3, 'god');
  head(w * 0.76, 1.15, 'god');
  head(w * 0.9, 0.95, 'eagle');
  // Işık başların kenarına vurur.
  canvas.drawRect(
    Rect.fromLTRB(0, ground - h * 0.4, w, ground),
    Paint()
      ..shader = ui.Gradient.radial(sun, w * 0.45, [
        const Color(0xFFFFC070).withValues(alpha: 0.12 * a),
        const Color(0x00FFC070),
      ])
      ..blendMode = BlendMode.plus,
  );
}

// -------------------------------------------------------- Ötüken vadisi
// Ağaçlar açılır: aşağıda kıvrılan ırmak, katman katman yeşil tepeler, en
// uzakta mavi Ötüken yışı; üstünde süzülen kuşlar.
void _valley(Canvas canvas, double w, double h, double a, double t) {
  _sky(canvas, w, h, a, const [
    Color(0xE6A8C8B0),
    Color(0xE6D8E0B8),
    Color(0xE6F0E2B0),
  ]);
  final k = h / 391;
  Path ridge(double base, double amp, double f, double seed) {
    final p = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 6) {
      p.lineTo(
        x,
        base -
            math.sin(x * f + seed) * amp -
            math.sin(x * f * 2.3 + seed * 1.7) * amp * 0.35,
      );
    }
    return p
      ..lineTo(w, h)
      ..close();
  }

  canvas.drawPath(
    ridge(h * 0.5, h * 0.07, 0.006, 1),
    _fill(const Color(0xFF7E9AB0), a),
  );
  canvas.drawPath(
    ridge(h * 0.6, h * 0.05, 0.009, 4),
    _fill(const Color(0xFF5E8270), a),
  );
  // Irmak: vadinin dibinde kıvrılarak uzaklaşır.
  final river = Path();
  for (var i = 0; i <= 40; i++) {
    final s = i / 40;
    final x = w * 0.5 + math.sin(s * 7 + 1) * w * 0.18 * (1 - s * 0.7);
    final y = h * 0.95 - s * h * 0.3;
    if (i == 0) {
      river.moveTo(x, y);
    } else {
      river.lineTo(x, y);
    }
  }
  canvas.drawPath(
    ridge(h * 0.7, h * 0.05, 0.012, 2),
    _fill(const Color(0xFF3E6A48), a),
  );
  canvas.drawPath(
    river,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * k
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE8F2E0).withValues(alpha: 0.75 * a),
  );
  canvas.drawPath(
    ridge(h * 0.86, h * 0.04, 0.016, 5),
    _fill(const Color(0xFF1E3A26), a),
  );
  // Kuşlar.
  final bird = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3 * k
    ..color = const Color(0xFF2A3A30).withValues(alpha: 0.8 * a);
  for (var i = 0; i < 6; i++) {
    final bx = (w * (0.2 + i * 0.13) + t * 22 * k) % w;
    final by = h * (0.22 + (i % 3) * 0.05) + math.sin(t * 1.3 + i) * 4 * k;
    final flap = math.sin(t * 6 + i * 1.7) * 3 * k;
    canvas.drawPath(
      Path()
        ..moveTo(bx - 6 * k, by - flap)
        ..quadraticBezierTo(bx - 3 * k, by - 2 * k, bx, by)
        ..quadraticBezierTo(bx + 3 * k, by - 2 * k, bx + 6 * k, by - flap),
      bird,
    );
  }
}
