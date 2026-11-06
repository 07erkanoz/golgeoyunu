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
    // Çoban kulübesi: üst üste kütükler (köşelerde yuvarlak başları),
    // kalın karlı beşik çatı, saçakta buzlar; kapının yanında fener, duvar
    // dibinde odun yığını, taş bacadan duman.
    final wood = Color.lerp(lt.deep, const Color(0xFF3A2414), 0.5)!;
    final dark = Color.lerp(wood, const Color(0xFF000000), 0.35)!;
    final bx = x - 10;
    const hw = 34.0, wallH = 34.0;
    final top = y - wallH;
    // Kütükler: her biri hafif yuvarlak, aralarında koyu derz.
    for (var k = 0; k < 6; k++) {
      final ly = top + k * wallH / 6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - hw, ly, hw * 2, wallH / 6 - 0.6),
          const Radius.circular(2.5),
        ),
        Paint()..color = k.isEven ? wood : Color.lerp(wood, dark, 0.25)!,
      );
      // Köşelerde kütük başları.
      for (final ex in [bx - hw - 2, bx + hw + 2]) {
        canvas.drawCircle(
          Offset(ex, ly + wallH / 12),
          wallH / 12 + 0.6,
          Paint()..color = Color.lerp(wood, lt.snowShade, 0.15)!,
        );
      }
    }
    // Gölgede kalan yan: duvarın sağ üçte biri koyu.
    canvas.drawRect(
      Rect.fromLTWH(bx + hw * 0.35, top, hw * 0.65, wallH),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.18),
    );
    // Kapı: ahşap, çerçeveli.
    final door = Rect.fromLTWH(bx - 22, y - 25, 12, 25);
    canvas.drawRect(door.inflate(1.5), Paint()..color = dark);
    canvas.drawRect(door, Paint()..color = const Color(0xFF1A100A));
    // Pencere: içeride ocak; çevresine ılık ışık.
    final win = Rect.fromLTWH(bx + 8, y - 25, 12, 10);
    final flick = 0.85 + 0.15 * math.sin(_t * 5.1);
    canvas.drawCircle(
      win.center,
      26,
      Paint()
        ..shader = Gradient.radial(win.center, 26, [
          const Color(0xFFFFC27A).withValues(alpha: 0.3 * flick),
          const Color(0x00FFC27A),
        ]),
    );
    canvas.drawRect(win.inflate(1.5), Paint()..color = dark);
    canvas.drawRect(
      win,
      Paint()..color = const Color(0xFFFFC27A).withValues(alpha: flick),
    );
    canvas.drawLine(win.topCenter, win.bottomCenter, Paint()..color = dark);
    canvas.drawRect(
      Rect.fromLTWH(win.left - 2, win.bottom + 1, win.width + 4, 2.5),
      Paint()..color = lt.snowLit,
    );
    // Kapının yanında fener.
    final lamp = Offset(bx - 6, y - 26);
    canvas.drawCircle(
      lamp,
      14,
      Paint()
        ..shader = Gradient.radial(lamp, 14, [
          const Color(0xFFFFC27A).withValues(alpha: 0.35 * flick),
          const Color(0x00FFC27A),
        ]),
    );
    canvas.drawCircle(lamp, 2, Paint()..color = const Color(0xFFFFD9A0));
    // Odun yığını: duvarın sağ dibinde yuvarlak kesitler, üstünde kar.
    for (var k = 0; k < 7; k++) {
      final row = k < 4 ? 0 : 1;
      final col = row == 0 ? k : k - 4;
      final c = Offset(bx + hw + 8 + col * 5.5 + row * 2.7, y - 3 - row * 5);
      canvas.drawCircle(c, 2.8, Paint()..color = wood);
      canvas.drawCircle(
        c,
        1.2,
        Paint()..color = Color.lerp(wood, const Color(0xFFC89A60), 0.5)!,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx + hw + 4, y - 13, 20, 3.5),
        const Radius.circular(2),
      ),
      Paint()..color = lt.snowLit,
    );
    // Taş baca ve duman.
    canvas.drawRect(
      Rect.fromLTWH(bx + 16, y - 70, 9, 22),
      Paint()..color = Color.lerp(lt.deep, lt.ridge, 0.3)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx + 14.5, y - 73, 12, 4),
        const Radius.circular(2),
      ),
      Paint()..color = lt.snowLit,
    );
    final smoke = Paint();
    for (var i = 0; i < 9; i++) {
      final u = ((_t * 0.18 + i / 9) % 1.0);
      smoke.color = Color.lerp(
        lt.snowShade,
        lt.skyLow,
        0.5,
      )!.withValues(alpha: 0.3 * (1 - u));
      canvas.drawCircle(
        Offset(bx + 20 + u * 40 + math.sin(_t + i) * 4, y - 76 - u * 90),
        4 + u * 13,
        smoke,
      );
    }
    // Beşik çatı: koyu ahşap saçak, üstünde kalın kar, saçakta buzlar.
    final eave = Path()
      ..moveTo(bx - hw - 12, top + 3)
      ..lineTo(bx, top - 26)
      ..lineTo(bx + hw + 12, top + 3)
      ..lineTo(bx + hw + 10, top + 7)
      ..lineTo(bx, top - 20)
      ..lineTo(bx - hw - 10, top + 7)
      ..close();
    canvas.drawPath(eave, Paint()..color = dark);
    final snow = Path()
      ..moveTo(bx - hw - 15, top + 4)
      ..quadraticBezierTo(bx - hw - 16, top - 2, bx - hw - 8, top - 3)
      ..lineTo(bx - 3, top - 33)
      ..quadraticBezierTo(bx, top - 35, bx + 3, top - 33)
      ..lineTo(bx + hw + 8, top - 3)
      ..quadraticBezierTo(bx + hw + 16, top - 2, bx + hw + 15, top + 4)
      ..lineTo(bx + hw + 9, top + 1)
      ..lineTo(bx, top - 24)
      ..lineTo(bx - hw - 9, top + 1)
      ..close();
    canvas.drawPath(snow, Paint()..color = lt.snowLit);
    final ice = Paint()..color = lt.snowShade;
    for (final (ix, len) in const [
      (-40.0, 6.0),
      (-31.0, 9.0),
      (-24.0, 4.0),
      (26.0, 7.0),
      (35.0, 5.0),
      (41.0, 8.0),
    ]) {
      final ey = top + 6;
      canvas.drawPath(
        Path()
          ..moveTo(bx + ix - 1.3, ey)
          ..lineTo(bx + ix + 1.3, ey)
          ..lineTo(bx + ix, ey + len)
          ..close(),
        ice,
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
    // Ön planda: ayak ekranın altına dek iner (dibi karın önünde kesik
    // kalmasın).
    canvas.drawPath(
      Path()
        ..moveTo(x0 - 58, y0 + 900)
        ..lineTo(x0 - 64, y0 - 60)
        ..lineTo(x0 - 52, top + 70)
        ..lineTo(x0 - 30, top + 20)
        ..lineTo(x0 + 2, top + 40)
        ..lineTo(x0 + 14, top + 104)
        ..lineTo(x0 + 8, y0 - 50)
        ..lineTo(x0 + 6, y0 + 900)
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
    // Erzurum köyü yamaçta: arka sırada sise karışan, önde iri taş evler;
    // toprak damlarda kalın kar ve buzlar, kimi iki katlı, kimi ahşap
    // çıkmalı, bacalardan duman. Ortada kubbeli cami ve şerefeli minare.
    double r(int i, int k) {
      final v = math.sin(i * 91.7 + k * 17.3) * 43758.5453;
      return v - v.floorToDouble();
    }

    for (final back in [true, false]) {
      for (var i = 0; i < 9; i++) {
        final hx =
            x + i * 70.0 + (back ? 35 : 0) + (r(i, back ? 1 : 2) - 0.5) * 20;
        final gy = surface.at(hx);
        if (gy == null) continue;
        final hy = gy + (back ? -6 : 6);
        final w = (back ? 30.0 : 40.0) + r(i, 3) * 18;
        final h = (back ? 20.0 : 24.0) + r(i, 4) * (back ? 10 : 18);
        if (!back && i == 4) {
          _mosque(canvas, hx, hy, lt);
          continue;
        }
        _villageHouse(
          canvas,
          hx,
          hy,
          w,
          h,
          i + (back ? 20 : 0),
          lt,
          back: back,
        );
      }
    }
  }

  void _villageHouse(
    Canvas canvas,
    double hx,
    double hy,
    double w,
    double h,
    int i,
    SkiLight lt, {
    required bool back,
  }) {
    double r(int k) {
      final v = math.sin(i * 53.1 + k * 29.7) * 43758.5453;
      return v - v.floorToDouble();
    }

    // Arka sıra sise karışır (gökle karışık, daha açık ve soluk).
    final stone = Color.lerp(
      Color.lerp(lt.deep, lt.ridge, 0.3)!,
      lt.skyLow,
      back ? 0.35 : 0,
    )!;
    final shade = Color.lerp(stone, lt.deep, 0.45)!;
    final wood = Color.lerp(stone, const Color(0xFF3A2414), back ? 0.3 : 0.55)!;
    final left = hx - w / 2;
    final top = hy - h;
    canvas.drawRect(
      Rect.fromLTWH(left, top, w, h + 20),
      Paint()..color = stone,
    );
    // Gölgedeki yan (güneş/ay soldan).
    canvas.drawRect(
      Rect.fromLTWH(left + w * 0.62, top, w * 0.38, h + 20),
      Paint()..color = shade.withValues(alpha: 0.5),
    );
    final twoStory = h > 32;
    if (twoStory) {
      canvas.drawRect(
        Rect.fromLTWH(left - 1, top + h * 0.48, w + 2, 2),
        Paint()..color = wood,
      );
    }
    // Ahşap çıkma: üst katın bir yanı dışa taşar, altında eğik payandalar.
    if (!back && twoStory && r(1) < 0.5) {
      final cx = r(2) < 0.5 ? left - 5 : left + w - 13;
      final cr = Rect.fromLTWH(cx, top + 4, 18, h * 0.44 - 4);
      canvas.drawRect(cr, Paint()..color = wood);
      final brace = Paint()
        ..color = Color.lerp(wood, lt.deep, 0.4)!
        ..strokeWidth = 1.4;
      canvas.drawLine(cr.bottomLeft, Offset(cr.left + 6, cr.bottom + 6), brace);
      canvas.drawLine(
        cr.bottomRight,
        Offset(cr.right - 6, cr.bottom + 6),
        brace,
      );
      final cw = Rect.fromLTWH(cr.left + 5, cr.top + 4, 8, 6);
      canvas.drawRect(
        cw,
        Paint()..color = const Color(0xFFFFC27A).withValues(alpha: 0.85),
      );
    }
    // Pencereler: gömme, kimi yanık; eşikte kar.
    final rows = twoStory ? 2 : 1;
    for (var row = 0; row < rows; row++) {
      final n = w > 46 ? 2 : 1;
      for (var k = 0; k < n; k++) {
        final wx =
            left + w * (n == 1 ? 0.3 + r(10 + k) * 0.3 : (k + 0.5) / n) - 3;
        final wy = top + 7 + row * h * 0.48 + r(20 + row) * 2;
        final lit = r(30 + row * 3 + k) < 0.55;
        final win = Rect.fromLTWH(wx, wy, back ? 4 : 6, back ? 5 : 7);
        canvas.drawRect(
          win,
          Paint()
            ..color = lit
                ? const Color(0xFFFFC27A).withValues(alpha: back ? 0.55 : 0.85)
                : Color.lerp(lt.deep, const Color(0xFF000000), 0.4)!,
        );
        if (!back) {
          canvas.drawRect(
            Rect.fromLTWH(win.left - 1.5, win.bottom, win.width + 3, 1.8),
            Paint()..color = lt.snowLit,
          );
        }
      }
    }
    // Kapı: alt katta, kemerli.
    if (!back && r(5) < 0.7) {
      final dx = left + w * (0.15 + r(6) * 0.5);
      canvas.drawPath(
        Path()
          ..moveTo(dx, hy + 2)
          ..lineTo(dx, hy - 9)
          ..quadraticBezierTo(dx + 4, hy - 14, dx + 8, hy - 9)
          ..lineTo(dx + 8, hy + 2)
          ..close(),
        Paint()..color = Color.lerp(wood, const Color(0xFF000000), 0.4)!,
      );
    }
    // Toprak dam: kiriş, ardıç direklerinin uçları, kalın kar, buzlar.
    canvas.drawRect(
      Rect.fromLTWH(left - 3, top - 2, w + 6, 3),
      Paint()..color = wood,
    );
    if (!back) {
      final pole = Paint()
        ..color = Color.lerp(wood, const Color(0xFFC89A60), 0.25)!;
      for (var px = left; px < left + w; px += 6) {
        canvas.drawCircle(Offset(px + 1, top - 0.5), 1.1, pole);
      }
    }
    final cap = Path()
      ..moveTo(left - 5, top - 1)
      ..quadraticBezierTo(left - 6, top - 6, left, top - 6 - r(7) * 2)
      ..quadraticBezierTo(hx, top - 9 - r(8) * 3, left + w, top - 6 - r(9) * 2)
      ..quadraticBezierTo(left + w + 6, top - 6, left + w + 5, top - 1)
      ..close();
    canvas.drawPath(cap, Paint()..color = lt.snowLit);
    if (!back) {
      final ice = Paint()..color = lt.snowShade;
      for (var ix = left + 2; ix < left + w - 1; ix += 5 + r(ix.toInt()) * 6) {
        final len = 2 + r(ix.toInt() + 1) * 5;
        canvas.drawPath(
          Path()
            ..moveTo(ix - 0.9, top + 1)
            ..lineTo(ix + 0.9, top + 1)
            ..lineTo(ix, top + 1 + len)
            ..close(),
          ice,
        );
      }
    }
    // Baca ve ince duman.
    if (r(11) < 0.6) {
      final cx = left + w * (0.2 + r(12) * 0.6);
      canvas.drawRect(
        Rect.fromLTWH(cx, top - 13, 5, 8),
        Paint()..color = stone,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - 1, top - 15, 7, 2.5),
        Paint()..color = lt.snowLit,
      );
      final smoke = Paint();
      for (var k = 0; k < 5; k++) {
        final u = ((_t * 0.14 + k / 5 + r(13)) % 1.0);
        smoke.color = Color.lerp(
          lt.snowShade,
          lt.skyLow,
          0.5,
        )!.withValues(alpha: (back ? 0.15 : 0.25) * (1 - u));
        canvas.drawCircle(
          Offset(cx + 2.5 + u * 22 + math.sin(_t + k) * 2, top - 18 - u * 50),
          2.5 + u * 8,
          smoke,
        );
      }
    }
  }

  /// Köyün camisi: sekizgen kasnak üstünde kubbe, yanında şerefeli minare;
  /// kubbede, şerefede ve külahta kar.
  void _mosque(Canvas canvas, double hx, double hy, SkiLight lt) {
    final stone = Color.lerp(lt.deep, lt.ridge, 0.3)!;
    final snow = Paint()..color = lt.snowLit;
    final body = Rect.fromLTWH(hx - 28, hy - 28, 56, 48);
    canvas.drawRect(body, Paint()..color = stone);
    canvas.drawRect(
      Rect.fromLTWH(hx + 6, hy - 28, 22, 48),
      Paint()..color = Color.lerp(stone, lt.deep, 0.45)!.withValues(alpha: 0.5),
    );
    // Kasnak ve kubbe.
    canvas.drawRect(
      Rect.fromLTWH(hx - 18, hy - 36, 36, 9),
      Paint()..color = stone,
    );
    final dome = Rect.fromCircle(center: Offset(hx, hy - 36), radius: 18);
    canvas.drawArc(dome, math.pi, math.pi, true, Paint()..color = stone);
    canvas.drawArc(
      dome.inflate(0.5),
      math.pi * 1.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = lt.snowLit
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.drawLine(
      Offset(hx, hy - 54),
      Offset(hx, hy - 60),
      Paint()
        ..color = const Color(0xFFD8B060)
        ..strokeWidth = 1.4,
    );
    // Kemerli pencereler.
    for (final wx in [hx - 18.0, hx - 4.0, hx + 10.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(wx, hy - 6)
          ..lineTo(wx, hy - 16)
          ..quadraticBezierTo(wx + 4, hy - 21, wx + 8, hy - 16)
          ..lineTo(wx + 8, hy - 6)
          ..close(),
        Paint()..color = const Color(0xFFFFC27A).withValues(alpha: 0.75),
      );
    }
    canvas.drawRect(Rect.fromLTWH(hx - 30, hy - 31, 60, 3.5), snow);
    // Minare: yukarı incelen gövde, şerefe, külah.
    final mx = hx + 38;
    canvas.drawPath(
      Path()
        ..moveTo(mx - 6, hy + 4)
        ..lineTo(mx - 4.5, hy - 100)
        ..lineTo(mx + 4.5, hy - 100)
        ..lineTo(mx + 6, hy + 4)
        ..close(),
      Paint()..color = stone,
    );
    canvas.drawRect(
      Rect.fromLTWH(mx - 8, hy - 84, 16, 3),
      Paint()..color = stone,
    );
    canvas.drawRect(Rect.fromLTWH(mx - 8.5, hy - 86, 17, 2.2), snow);
    canvas.drawPath(
      Path()
        ..moveTo(mx - 5.5, hy - 100)
        ..lineTo(mx, hy - 124)
        ..lineTo(mx + 5.5, hy - 100)
        ..close(),
      Paint()..color = Color.lerp(stone, lt.deep, 0.3)!,
    );
    canvas.drawPath(
      Path()
        ..moveTo(mx - 5.5, hy - 100)
        ..lineTo(mx, hy - 124)
        ..lineTo(mx - 1.5, hy - 104)
        ..close(),
      snow,
    );
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
