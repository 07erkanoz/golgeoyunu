import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'ski.dart';
import 'ski_light.dart';

/// Kayak yamacının doğası (harita üretecindeki `deco` işaretleri): çoban
/// kulübesi, orman, donmuş göl, geyikler, kuşlar, taş kemer, donmuş şelale,
/// Erzurum köyü, donmuş kervan. Arka katman yamacın üstünde, ön katman
/// (büyük çamlar, kemerin ön ayağı) Sâye'nin önünde çizilir.
class SkiDecor extends Component with HasGameReference<GolgeGame> {
  SkiDecor(this.surface, this.items, {this.front = false})
    : super(priority: front ? 25 : 2);

  final SkiSurface surface;
  final List<(String, int)> items;
  final bool front;
  double _t = 0;

  /// Kaçan hayvanlar: kaçışın başladığı an (sütuna göre).
  final _fled = <int, double>{};

  double _x(int col) => (col + 0.5) * kTile;

  /// Ormanlık sütun aralıkları: her 'forest' işaretinden 70 sütun.
  late final List<(int, int)> forests = [
    for (final (k, c) in items)
      if (k == 'forest') (c, c + 70),
  ];

  @override
  void update(double dt) {
    _t += dt;
    if (front) return;
    final p = game.player;
    if (p == null) return;
    for (final (k, c) in items) {
      if ((k == 'deer' || k == 'birds') && !_fled.containsKey(c)) {
        if (_x(c) - p.center.x < 9 * kTile) _fled[c] = _t;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect.inflate(400);
    final lt = game.skiLight;
    if (front) {
      _frontPines(canvas, view, lt);
    }
    for (final (k, c) in items) {
      final x = _x(c);
      if (x < view.left - 600 || x > view.right + 600) continue;
      final y = surface.at(x);
      if (front) {
        if (k == 'arch' && y != null) _archFront(canvas, x, y, lt);
        continue;
      }
      switch (k) {
        case 'hut' when y != null:
          _hut(canvas, x, y, lt);
        case 'lake':
          _lake(canvas, c, lt);
        case 'deer' when y != null:
          _deer(canvas, c, x, y, lt);
        case 'birds' when y != null:
          _birds(canvas, c, x, y, lt);
        case 'arch' when y != null:
          _archBack(canvas, x, y, lt);
        case 'waterfall':
          _waterfall(canvas, c, lt);
        case 'village' when y != null:
          _village(canvas, x, y, lt);
        case 'caravan' when y != null:
          _caravan(canvas, x, lt);
      }
    }
  }

  // ------------------------------------------------------------ ön çamlar

  /// Ormanda kameraya yakın, iri ve koyu çamlar: Sâye'nin önünden geçer,
  /// derinlik verir (yamacın biraz altında, ön planda).
  void _frontPines(Canvas canvas, Rect view, SkiLight lt) {
    // Neredeyse kara silüetler: Alto'daki gibi önden hızla geçer.
    final dark = Color.lerp(lt.deep, const Color(0xFF000000), 0.7)!;
    final paint = Paint()..color = dark;
    for (final (a, b) in forests) {
      for (var c = a; c < b; c += 9) {
        final h = (c * 2654435761) & 0xffff;
        if (h % 3 == 0) continue;
        final x = _x(c) + (h % 40) - 20;
        if (x < view.left || x > view.right) continue;
        final g = surface.at(x);
        if (g == null) continue;
        drawAltoPine(canvas, x, g + 80 + (h % 30), 170.0 + (h % 90), paint);
      }
    }
  }

  // ----------------------------------------------------------- kulübe

  void _hut(Canvas canvas, double x, double y, SkiLight lt) {
    final wall = Paint()
      ..color = Color.lerp(lt.deep, const Color(0xFF3A2414), 0.5)!;
    final roof = Paint()..color = lt.snowLit;
    final bx = x - 10;
    canvas.drawRect(Rect.fromLTWH(bx - 34, y - 38, 68, 40), wall);
    // Kütük çizgileri.
    final log = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var k = 1; k < 5; k++) {
      canvas.drawLine(
        Offset(bx - 34, y - 38 + k * 8),
        Offset(bx + 34, y - 38 + k * 8),
        log,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(bx - 44, y - 36)
        ..lineTo(bx, y - 66)
        ..lineTo(bx + 44, y - 36)
        ..lineTo(bx + 40, y - 30)
        ..lineTo(bx, y - 58)
        ..lineTo(bx - 40, y - 30)
        ..close(),
      roof,
    );
    // Sıcak pencere ve kapı.
    final win = Rect.fromLTWH(bx + 10, y - 26, 12, 10);
    canvas.drawCircle(
      win.center,
      26,
      Paint()
        ..shader = Gradient.radial(win.center, 26, [
          const Color(0xFFFFC27A).withValues(alpha: 0.35),
          const Color(0x00FFC27A),
        ]),
    );
    canvas.drawRect(win, Paint()..color = const Color(0xFFFFC27A));
    canvas.drawRect(
      Rect.fromLTWH(bx - 22, y - 24, 12, 26),
      Paint()..color = const Color(0xFF1A100A),
    );
    // Bacadan tüten duman.
    canvas.drawRect(Rect.fromLTWH(bx + 18, y - 66, 8, 16), wall);
    final smoke = Paint();
    for (var i = 0; i < 9; i++) {
      final u = ((_t * 0.18 + i / 9) % 1.0);
      smoke.color = Color.lerp(
        lt.snowShade,
        lt.skyLow,
        0.5,
      )!.withValues(alpha: 0.35 * (1 - u));
      canvas.drawCircle(
        Offset(bx + 22 + u * 40 + math.sin(_t + i) * 4, y - 70 - u * 90),
        5 + u * 14,
        smoke,
      );
    }
  }

  // ------------------------------------------------------------- göl

  /// Donmuş göl: düzlüğün üstünde buz; gökyüzünü yansıtır, çatlaklar.
  void _lake(Canvas canvas, int c, SkiLight lt) {
    var end = c + 1;
    for (final (k, c2) in items) {
      if (k == 'lake_end' && c2 > c) {
        end = c2;
        break;
      }
    }
    final x0 = _x(c) - kTile / 2;
    final x1 = _x(end) - kTile / 2;
    final y = surface.at((x0 + x1) / 2);
    if (y == null) return;
    final ice = Rect.fromLTRB(x0 + 6, y + 1.5, x1 - 6, y + 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ice, const Radius.circular(4)),
      Paint()
        ..shader = Gradient.linear(ice.topLeft, ice.bottomLeft, [
          Color.lerp(
            lt.skyLow,
            const Color(0xFFCFE8FF),
            0.5,
          )!.withValues(alpha: 0.85),
          Color.lerp(lt.skyMid, lt.snowShade, 0.5)!.withValues(alpha: 0.6),
        ]),
    );
    // Yansıyan güneş/ay ışığı: kayan bir parıltı.
    final sheen = (x0 + (x1 - x0) * ((_t * 0.07) % 1.0));
    canvas.drawRect(
      Rect.fromLTWH(sheen - 40, y + 2, 80, 3),
      Paint()..color = lt.sun.withValues(alpha: 0.8),
    );
    final crack = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < (x1 - x0) / 60; k++) {
      final cx = x0 + 20 + k * 60.0;
      canvas.drawPath(
        Path()
          ..moveTo(cx, y + 3)
          ..lineTo(cx + 10, y + 8)
          ..lineTo(cx + 6, y + 12)
          ..moveTo(cx + 10, y + 8)
          ..lineTo(cx + 22, y + 6),
        crack,
      );
    }
  }

  // ---------------------------------------------------------- geyikler

  void _deer(Canvas canvas, int c, double x, double y, SkiLight lt) {
    final t0 = _fled[c];
    final run = t0 == null ? 0.0 : (_t - t0);
    if (run > 6) return;
    final body = Color.lerp(lt.deep, const Color(0xFF2A1A12), 0.4)!;
    for (var i = 0; i < 3; i++) {
      final dx = run * (260 + i * 30);
      final gx = x + i * 46 - 30 + dx;
      final gy = surface.at(gx) ?? y;
      final hop = run > 0 ? -(math.sin(run * 9 + i).abs() * 16) : 0.0;
      final a = (1 - (run - 4).clamp(0.0, 2.0) / 2);
      _deerShape(
        canvas,
        Offset(gx, gy + hop),
        run > 0 ? run * 9 + i : 0,
        body.withValues(alpha: a),
        grazing: run == 0 && i == 1,
      );
    }
  }

  void _deerShape(
    Canvas canvas,
    Offset at,
    double phase,
    Color col, {
    bool grazing = false,
  }) {
    final p = Paint()..color = col;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(0.9);
    // Gövde.
    canvas.drawOval(const Rect.fromLTRB(-16, -30, 14, -18), p);
    // Bacaklar.
    final leg = Paint()
      ..color = col
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final (lx, off) in const [
      (-12.0, 0.0),
      (-8.0, 1.6),
      (8.0, 3.1),
      (11.0, 4.7),
    ]) {
      final sw = phase == 0 ? 0.0 : math.sin(phase + off) * 0.6;
      canvas.drawLine(
        Offset(lx, -21),
        Offset(lx + math.sin(sw) * 12, -21 + math.cos(sw) * 21),
        leg,
      );
    }
    // Boyun, baş, boynuzlar (otlayan biri başını eğmiş).
    final head = grazing ? const Offset(20, -8) : const Offset(19, -42);
    canvas.drawLine(const Offset(10, -27), head, leg..strokeWidth = 5);
    canvas.drawOval(
      Rect.fromCenter(center: head + const Offset(3, 0), width: 11, height: 6),
      p,
    );
    final antler = Paint()
      ..color = col
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - 1, head.dy - 2)
        ..lineTo(head.dx - 5, head.dy - 14)
        ..moveTo(head.dx - 3, head.dy - 8)
        ..lineTo(head.dx - 9, head.dy - 11)
        ..moveTo(head.dx + 1, head.dy - 2)
        ..lineTo(head.dx + 3, head.dy - 13),
      antler,
    );
    // Kuyruk ucu ak.
    canvas.drawCircle(
      const Offset(-16, -26),
      2.4,
      Paint()..color = const Color(0xFFEDE6DC).withValues(alpha: col.a),
    );
    canvas.restore();
  }

  // ------------------------------------------------------------- kuşlar

  void _birds(Canvas canvas, int c, double x, double y, SkiLight lt) {
    final t0 = _fled[c];
    final fly = t0 == null ? 0.0 : _t - t0;
    if (fly > 7) return;
    final col = Color.lerp(lt.deep, const Color(0xFF000000), 0.3)!;
    final p = Paint()
      ..color = col
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final h = (i * 7919) % 17;
      final bx = x + i * 14 - 60 + fly * (120 + h * 8);
      final by =
          (surface.at(x + i * 14 - 60) ?? y) -
          3 -
          fly * (70 + h * 6) -
          fly * fly * 8;
      if (fly == 0) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(bx, by - 3), width: 7, height: 5),
          p..style = PaintingStyle.fill,
        );
        p.style = PaintingStyle.stroke;
        continue;
      }
      final flap = math.sin(_t * 14 + i) * 5;
      canvas.drawPath(
        Path()
          ..moveTo(bx - 7, by - flap)
          ..quadraticBezierTo(bx - 3, by - 3, bx, by)
          ..quadraticBezierTo(bx + 3, by - 3, bx + 7, by - flap),
        p,
      );
    }
  }

  // ------------------------------------------------------------- kemer

  /// Doğal taş kemerin gövdesi: iki kalın ayak ve kalın, düzensiz bir
  /// kemer; içi yamaçtan yukarı açık.
  Path _archPath(double x0, double y0, double x1, double y1, double top) {
    final p = Path()..moveTo(x0 - 60, y0 + 30);
    // Sol ayağın dış yüzü, kemerin üstü, sağ ayağın dış yüzü.
    p
      ..lineTo(x0 - 64, y0 - 60)
      ..lineTo(x0 - 52, top + 70)
      ..lineTo(x0 - 30, top + 20)
      ..quadraticBezierTo((x0 + x1) / 2, top - 70, x1 + 30, top + 20)
      ..lineTo(x1 + 56, top + 76)
      ..lineTo(x1 + 62, y1 - 40)
      ..lineTo(x1 + 58, y1 + 30)
      // Sağ ayağın iç yüzü, kemerin altı, sol ayağın iç yüzü.
      ..lineTo(x1 - 4, y1 + 30)
      ..lineTo(x1 - 8, y1 - 50)
      ..lineTo(x1 - 14, top + 104)
      ..quadraticBezierTo((x0 + x1) / 2, top + 12, x0 + 14, top + 104)
      ..lineTo(x0 + 8, y0 - 50)
      ..lineTo(x0 + 4, y0 + 30)
      ..close();
    return p;
  }

  (double, double, double, double, double) _archGeo(double x, double y) {
    final x0 = x - 170;
    final x1 = x + 170;
    final y0 = surface.at(x0) ?? y;
    final y1 = surface.at(x1) ?? y;
    return (x0, y0, x1, y1, math.min(y0, y1) - 250);
  }

  /// Doğal taş kemer: bütün gövdesi yamacın arkasında (sağ ayak dahil).
  void _archBack(Canvas canvas, double x, double y, SkiLight lt) {
    final (x0, y0, x1, y1, top) = _archGeo(x, y);
    final rock = Paint()
      ..shader = Gradient.linear(Offset(0, top), Offset(0, y1), [
        Color.lerp(lt.ridge, lt.deep, 0.45)!,
        Color.lerp(lt.deep, const Color(0xFF000000), 0.2)!,
      ]);
    canvas.drawPath(_archPath(x0, y0, x1, y1, top), rock);
    // Işık kenarı ve kemerin üstünde kar.
    canvas.drawPath(
      Path()
        ..moveTo(x0 - 30, top + 22)
        ..quadraticBezierTo(x, top - 68, x1 + 30, top + 22)
        ..quadraticBezierTo(x, top - 46, x0 - 30, top + 22)
        ..close(),
      Paint()..color = lt.snowLit,
    );
    final ice = Paint()..color = lt.snowLit.withValues(alpha: 0.8);
    for (var k = 0; k < 14; k++) {
      final u = (k + 1) / 15;
      final ix = (x0 + 14) + (x1 - x0 - 28) * u;
      final iy = top + 104 - math.sin(u * math.pi) * 54;
      canvas.drawPath(
        Path()
          ..moveTo(ix - 3, iy - 2)
          ..lineTo(ix + 3, iy - 2)
          ..lineTo(ix, iy + 8 + (k * 7 % 11))
          ..close(),
        ice,
      );
    }
  }

  /// Kemerin sol ayağının önü: Sâye geçerken önünden akar.
  void _archFront(Canvas canvas, double x, double y, SkiLight lt) {
    final (x0, y0, _, _, top) = _archGeo(x, y);
    final rock = Paint()
      ..color = Color.lerp(lt.deep, const Color(0xFF000000), 0.4)!;
    canvas.drawPath(
      Path()
        ..moveTo(x0 - 60, y0 + 60)
        ..lineTo(x0 - 64, y0 - 60)
        ..lineTo(x0 - 52, top + 70)
        ..lineTo(x0 - 30, top + 20)
        ..lineTo(x0 + 2, top + 40)
        ..lineTo(x0 + 14, top + 104)
        ..lineTo(x0 + 8, y0 - 50)
        ..lineTo(x0 + 4, y0 + 60)
        ..close(),
      rock,
    );
  }

  // ------------------------------------------------------------ şelale

  /// Donmuş şelale: uçurumun kaya yüzünden aşağı inen buz sütunları.
  void _waterfall(Canvas canvas, int c, SkiLight lt) {
    // Şelale, işaretten sonraki ilk uçurumun karşı kenarında.
    var g = c;
    while (g < surface.rows.length && surface.rows[g] >= 0) {
      g++;
    }
    var e = g;
    while (e < surface.rows.length && surface.rows[e] < 0) {
      e++;
    }
    if (e >= surface.rows.length) return;
    final lip = surface.rows[g - 1] * kTile;
    final x = g * kTile.toDouble();
    final bottom = surface.rows[e] * kTile + 260;
    final ice = Paint()
      ..shader = Gradient.linear(Offset(0, lip), Offset(0, bottom), [
        Color.lerp(lt.snowLit, const Color(0xFFBFE8FF), 0.4)!,
        Color.lerp(
          lt.snowShade,
          const Color(0xFF6FA8D8),
          0.3,
        )!.withValues(alpha: 0.6),
      ]);
    for (var k = 0; k < 6; k++) {
      final cx = x - 6 - k * 9.0;
      final w = 6.0 + (k * 5 % 4);
      final len = (bottom - lip) * (0.6 + (k * 37 % 40) / 100);
      canvas.drawPath(
        Path()
          ..moveTo(cx - w, lip + 4)
          ..lineTo(cx + w, lip + 4)
          ..lineTo(cx + w * 0.5, lip + len)
          ..lineTo(cx, lip + len + 14)
          ..lineTo(cx - w * 0.6, lip + len)
          ..close(),
        ice,
      );
    }
    // Parıltı.
    final tw = 0.5 + 0.5 * math.sin(_t * 2);
    canvas.drawCircle(
      Offset(x - 20, lip + 60),
      2 + tw * 2,
      Paint()..color = lt.sun.withValues(alpha: 0.4 + 0.4 * tw),
    );
  }

  // ---------------------------------------------------------------- köy

  /// Erzurum köyü: yamacın aşağısında düz damlı evler, ışıklı pencereler,
  /// bir minare, tüten bacalar.
  void _village(Canvas canvas, double x, double y, SkiLight lt) {
    final house = Paint()..color = Color.lerp(lt.deep, lt.ridge, 0.3)!;
    final roof = Paint()..color = lt.snowLit;
    final win = Paint()
      ..color = const Color(0xFFFFC27A).withValues(alpha: 0.85);
    for (var i = 0; i < 9; i++) {
      final hx = x + i * 70.0 + (i * 23 % 17);
      final hy = (surface.at(hx) ?? y) + 6;
      final w = 40.0 + (i * 13 % 20);
      final h = 26.0 + (i * 7 % 14);
      canvas.drawRect(Rect.fromLTWH(hx - w / 2, hy - h, w, h + 20), house);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(hx - w / 2 - 3, hy - h - 5, w + 6, 7),
          const Radius.circular(3),
        ),
        roof,
      );
      canvas.drawRect(Rect.fromLTWH(hx - 6, hy - h + 9, 6, 6), win);
      if (i == 4) {
        // Minare.
        canvas.drawRect(
          Rect.fromLTWH(hx + w / 2 + 8, hy - 110, 10, 112),
          house,
        );
        canvas.drawPath(
          Path()
            ..moveTo(hx + w / 2 + 6, hy - 110)
            ..lineTo(hx + w / 2 + 13, hy - 134)
            ..lineTo(hx + w / 2 + 20, hy - 110)
            ..close(),
          roof,
        );
        canvas.drawRect(Rect.fromLTWH(hx + w / 2 + 4, hy - 82, 18, 3), roof);
      }
    }
  }

  // ------------------------------------------------------------- kervan

  /// Donmuş kervan (Çığ efsanesi): ayakta donmuş develer, sırtlarında kar,
  /// boyunlarında rüzgârda sallanan çanlar.
  void _caravan(Canvas canvas, double x, SkiLight lt) {
    final body = Paint()..color = Color.lerp(lt.snowShade, lt.deep, 0.55)!;
    final snow = Paint()..color = lt.snowLit;
    final bell = Paint()..color = const Color(0xFFD8B060);
    for (var i = 0; i < 4; i++) {
      final cx = x + i * 150.0;
      final gy = surface.at(cx);
      if (gy == null) continue;
      canvas.save();
      canvas.translate(cx, gy + 4);
      canvas.scale(1.6);
      final legs = Paint()
        ..color = body.color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      for (final lx in const [-20.0, -12.0, 14.0, 22.0]) {
        canvas.drawLine(Offset(lx, -34), Offset(lx + 1, 0), legs);
      }
      canvas.drawPath(
        Path()
          ..moveTo(-30, -36)
          ..quadraticBezierTo(-22, -68, -6, -48)
          ..quadraticBezierTo(4, -64, 18, -44)
          ..quadraticBezierTo(30, -46, 30, -34)
          ..close(),
        body,
      );
      // Boyun ve baş.
      canvas.drawPath(
        Path()
          ..moveTo(26, -44)
          ..quadraticBezierTo(42, -50, 40, -70)
          ..lineTo(52, -72)
          ..lineTo(52, -64)
          ..lineTo(46, -64)
          ..quadraticBezierTo(46, -44, 30, -36)
          ..close(),
        body,
      );
      // Hörgüçlerde kar.
      canvas.drawOval(const Rect.fromLTRB(-24, -56, -8, -50), snow);
      canvas.drawOval(const Rect.fromLTRB(1, -54, 15, -48), snow);
      canvas.drawOval(const Rect.fromLTRB(40, -74, 52, -70), snow);
      // Çan: rüzgârda sallanır.
      final sw = math.sin(_t * 3 + i) * 0.4;
      final b = Offset(34 + math.sin(sw) * 6, -42 + math.cos(sw) * 6);
      canvas.drawLine(
        const Offset(34, -46),
        b,
        Paint()
          ..color = body.color
          ..strokeWidth = 1,
      );
      canvas.drawCircle(b, 3, bell);
      canvas.restore();
    }
  }
}
