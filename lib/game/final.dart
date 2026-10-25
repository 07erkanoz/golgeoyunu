import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'persist.dart';
import 'player.dart';
import 'puzzles.dart';

// ================================================================ Final
//
// XX · Yeşil Kubbe'nin tepesi: Kandilci Başı ustanın kandilini tutar.
// Büyük feneri sahanlığı tarar (huzmede kalan gölge silinir; sütunların
// gölgesinde saklanılır). Üç aynadan inen ay ışığı Kandilci Başı'nın
// çevresindeki üç kilide düştükçe ardındaki dev perdede kendi gölgesi
// belirir. Üçüncüsünde gölgesini görür: fenerini bırakır, diz çöker;
// kafeslerdeki ışıklar göğe yükselir, çıkış kapısı açılır.

/// Kandilci Başı'nın çevresindeki ay kilidi: ışık düşünce yanar, kapı
/// açmaz (Kandilci Başı sayar).
class FinaleLock extends SunLock {
  FinaleLock(super.cell) : super(opensGate: false);
}

class KandilciBasi extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  KandilciBasi(Vector2 feet)
    : super(position: feet, anchor: Anchor.bottomCenter, priority: 12) {
    size = Vector2(60, 110);
  }

  /// Huzmenin uzunluğu, yarı açısı; tarama süresi.
  static const double reach = 15 * kTile;
  static const double halfWidth = 0.12;
  static const double period = 6.5;

  /// Huzmede bu kadar kalan gölge silinir.
  static const double exposureLimit = 0.3;

  /// Önizleme için: huzme yakalamaz.
  static bool debugHarmless = false;

  /// Bitiş: gölgesini görüp diz çöküşünden kapının açılışına dek.
  static const double endLength = 6;

  double _t = 0;
  double exposure = 0;

  /// Yanan kilit sayısı (0-3) ve perdede beliren gölgenin boyu (0-1).
  int lit = 0;
  double _shadow = 0;

  /// Bitti mi; bitişten beri geçen süre.
  bool solved = false;
  double _end = 0;
  bool _gateOpened = false;
  bool _framed = false;
  double _sweep = 0;

  /// Huzmenin açısı (radyan): sağdan sola, aşağıdan geçerek tarar.
  double get beamAngle =>
      math.pi / 2 + 1.3 * math.sin(_sweep * 2 * math.pi / period);

  /// Fenerin yeri (dünya).
  Vector2 get lantern => position + Vector2(-26, -78);

  /// Perdenin dikdörtgeni (dünya): Kandilci Başı'nın ardında.
  Rect get screen => Rect.fromLTWH(
    position.x - 5 * kTile,
    position.y - 7 * kTile,
    10 * kTile.toDouble(),
    7 * kTile - 6,
  );

  Offset get glowCenter => lantern.toOffset();

  @override
  String get persistKind => 'kandilciBasi';

  @override
  Object? captureState() => solved ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      solved = true;
      lit = 3;
      _shadow = 1;
      _end = endLength;
      _gateOpened = true;
    }
    return [this];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final locks = game.world.children.whereType<FinaleLock>().toList();
    final now = locks.where((l) => l.open).length;
    if (now > lit) {
      lit = now;
      GameAudio.instance.play('memory', volume: 0.6);
      game.shake(2);
    }
    _shadow += ((lit / 3) - _shadow) * math.min(1, dt * 1.5);
    if (!solved && locks.isNotEmpty && lit >= locks.length) {
      solved = true;
      _end = 0;
      GameAudio.instance.play('bell', volume: 0.7);
      GameAudio.instance.dread(0);
    }
    if (solved) {
      exposure = 0;
      // Kamera sahneye bakar: perdedeki gölge, sönen kandil, yükselen
      // ışıklar (tehlike sönene dek dener).
      if (!_framed && _end < 2.5) {
        _framed = game.focus(position - Vector2(0, 4 * kTile), hold: 3.5);
      }
      _end += dt;
      if (_end > 3.5 && !_gateOpened) {
        _gateOpened = true;
        _openExit();
      }
      return;
    }
    // Gölgesi belirdikçe taraması ağırlaşır.
    _sweep += dt * (1 - 0.25 * lit);
    final p = game.player;
    if (p == null || p.isDead) {
      exposure = 0;
      return;
    }
    if (!debugHarmless && _sees(p)) {
      if (exposure == 0) {
        GameAudio.instance.play('chain', volume: 0.5, minGapMs: 600);
      }
      exposure += dt;
      game.threat = math.max(game.threat, 0.9);
      if (exposure > exposureLimit) {
        exposure = 0;
        p.die(cause: DeathCause.light);
      }
    } else {
      exposure = math.max(0, exposure - dt * 2);
    }
  }

  bool _sees(Player p) {
    if (p.hidden) return false;
    final d = p.center - lantern;
    final dist = d.length;
    if (dist > reach || dist < 4) return false;
    var off = math.atan2(d.y, d.x) - beamAngle;
    off = (off + math.pi) % (2 * math.pi) - math.pi;
    return off.abs() < halfWidth + 10 / dist;
  }

  void _openExit() {
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      if (g.position.x < position.x || g.opening) continue;
      final d = (g.position - position).length;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    best?.opening = true;
    GameAudio.instance.play('gate', volume: 0.6);
  }

  /// Bitiş sahnesinin ilerleyişi (0-1): diz çöküş.
  double get _kneel =>
      solved ? ((_end - 0.8) / 1.6).clamp(0.0, 1.0).toDouble() : 0.0;

  @override
  void render(Canvas canvas) {
    final base = Offset(size.x / 2, size.y);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    _paintScreen(canvas);
    _paintMasterLamp(canvas);
    if (!solved) _paintBeam(canvas);
    _paintFigure(canvas);
    if (solved) _paintRise(canvas);
    canvas.restore();
  }

  /// Dev perde: arkadan ustanın kandiliyle aydınlanır; Kandilci Başı'nın
  /// gölgesi üzerinde belirdikçe koyulaşır.
  void _paintScreen(Canvas canvas) {
    final r = screen.shift(-position.toOffset());
    final flick = 0.9 + 0.1 * math.sin(_t * 7) * math.sin(_t * 2.3);
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          r.center.translate(0, r.height * 0.2),
          r.width * 0.7,
          [
            const Color(0xFFF6DDA8).withValues(alpha: 0.85 * flick),
            const Color(0xFFC88A48).withValues(alpha: 0.75),
          ],
        ),
    );
    // Çerçeve: oyma ahşap, üstte hilal.
    final wood = Paint()..color = const Color(0xFF2A160A);
    canvas.drawRect(
      Rect.fromLTRB(r.left - 6, r.top - 8, r.right + 6, r.top),
      wood,
    );
    canvas.drawRect(Rect.fromLTRB(r.left - 6, r.top, r.left, r.bottom), wood);
    canvas.drawRect(Rect.fromLTRB(r.right, r.top, r.right + 6, r.bottom), wood);
    // Kandilci Başı'nın gölgesi: perdeye iri düşer; ayna sayısıyla belirir.
    final a = _shadow;
    if (a > 0.01) {
      canvas.save();
      canvas.clipRect(r);
      // Fener önde ve aşağıda: gölge iri, yana kaymış düşer (kendisiyle
      // karışmasın).
      canvas.translate(r.center.dx - 70, r.bottom);
      canvas.scale(2.1 + 0.2 * a, 1.75 + 0.15 * a);
      final ink = Paint()
        ..color = const Color(0xFF140A05).withValues(alpha: 0.85 * a);
      _silhouette(canvas, ink, kneel: _kneel, shadow: true);
      canvas.restore();
    }
  }

  /// Ustanın kandili: alemin altında asılı büyük kandil, içinde ustanın
  /// oturan gölgesi. Bitişte söner.
  void _paintMasterLamp(Canvas canvas) {
    final at = Offset(40, -8.4 * kTile);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(1.7);
    canvas.translate(-at.dx, -at.dy);
    final out = solved ? ((_end - 1.5) / 3).clamp(0.0, 1.0) : 0.0;
    final glow = (0.8 + 0.2 * math.sin(_t * 5)) * (1 - out);
    final chain = Paint()
      ..color = const Color(0xFF3A2A1A)
      ..strokeWidth = 1.5;
    canvas.drawLine(at.translate(0, -60), at.translate(0, -14), chain);
    if (glow > 0.02) glowDot(canvas, at, 70, kWarmLight, 0.6 * glow);
    final glass = Path()
      ..moveTo(at.dx - 12, at.dy - 12)
      ..lineTo(at.dx + 12, at.dy - 12)
      ..lineTo(at.dx + 16, at.dy + 10)
      ..quadraticBezierTo(at.dx, at.dy + 20, at.dx - 16, at.dy + 10)
      ..close();
    canvas.drawPath(
      glass,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF2A1A10),
          const Color(0xFFFFE0A0),
          glow,
        )!.withValues(alpha: 0.9),
    );
    // Ustanın gölgesi: bağdaş kurmuş, başı eğik (kandil sönünce silinir).
    final m = Paint()
      ..color = const Color(0xFF1A0B05).withValues(alpha: 0.8 * (1 - out));
    canvas.drawOval(
      Rect.fromCenter(center: at.translate(0, 4), width: 14, height: 9),
      m,
    );
    canvas.drawCircle(at.translate(1.5, -3.5), 3.2, m);
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF6A4A2A),
    );
    canvas.restore();
  }

  /// Fenerin huzmesi: soğuk, nane yeşili (Kandilcilerin ışığı).
  void _paintBeam(Canvas canvas) {
    final o = (lantern - position).toOffset();
    final a = beamAngle;
    final w = halfWidth;
    final far1 = o + Offset(math.cos(a - w), math.sin(a - w)) * reach;
    final far2 = o + Offset(math.cos(a + w), math.sin(a + w)) * reach;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(far1.dx, far1.dy)
        ..lineTo(far2.dx, far2.dy)
        ..close(),
      Paint()
        ..shader = ui.Gradient.radial(o, reach, [
          kCold.withValues(alpha: 0.45 + 0.4 * exposure),
          kCold.withValues(alpha: 0),
        ]),
    );
  }

  void _paintFigure(Canvas canvas) {
    // Kenarında fenerinin soğuk ışığı: perdedeki gölgesinden ayrılsın.
    canvas.save();
    canvas.scale(1.06, 1.03);
    _silhouette(
      canvas,
      Paint()..color = kCold.withValues(alpha: solved ? 0.25 : 0.55),
      kneel: _kneel,
    );
    canvas.restore();
    final ink = Paint()..color = const Color(0xFF120A06);
    _silhouette(canvas, ink, kneel: _kneel);
    // Fener: elinde (bitişte yere düşer).
    final drop = solved ? ((_end - 0.3) / 0.6).clamp(0.0, 1.0) : 0.0;
    final o =
        (lantern - position).toOffset() +
        Offset(-6 * drop, (78 - 8) * drop * drop);
    final lit = solved ? (1 - drop) : 1.0;
    if (lit > 0.02) glowDot(canvas, o, 30, kCold, 0.55 * lit);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: 12, height: 16),
        const Radius.circular(2),
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF2A3A30),
          const Color(0xFFD8FFE8),
          lit,
        )!,
    );
  }

  /// Kandilci Başı: uzun kukuletalı cübbe, sırtı kambur; sağ elinde
  /// fenerin sapı. Ayaklar (0, 0). [kneel] 1 iken diz çöker, başı eğilir.
  void _silhouette(
    Canvas canvas,
    Paint ink, {
    double kneel = 0,
    bool shadow = false,
  }) {
    final h = 100 - 34 * kneel;
    final sway = shadow ? 0.0 : math.sin(_t * 1.3) * 1.5;
    final robe = Path()
      ..moveTo(-22, 0)
      ..lineTo(22, 0)
      ..quadraticBezierTo(16, -h * 0.45, 12 + sway, -h * 0.78)
      ..quadraticBezierTo(4, -h * 0.9, -6 + sway, -h * 0.82)
      ..quadraticBezierTo(-18, -h * 0.5, -22, 0)
      ..close();
    canvas.drawPath(robe, ink);
    // Kukuleta: sivri, öne eğik.
    final bow = 10 * kneel;
    final hood = Path()
      ..moveTo(-10 + sway, -h * 0.8)
      ..quadraticBezierTo(-12 + sway, -h - 8, 2 + sway - bow, -h - 14 + bow)
      ..quadraticBezierTo(10 + sway, -h - 2, 12 + sway, -h * 0.8)
      ..close();
    canvas.drawPath(hood, ink);
    // Fenerin sapı (bitişte elinden düşer).
    if (!solved || shadow) {
      final pole = Paint()
        ..color = ink.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(-8 + sway, -h * 0.6),
        Offset(-24, -86 + 34 * kneel),
        pole,
      );
    }
  }

  /// Bitiş: kafeslerdeki ışıklar göğe yükselir.
  void _paintRise(Canvas canvas) {
    final k = (_end / endLength).clamp(0.0, 1.0);
    for (var i = 0; i < 24; i++) {
      final x = ((i * 53) % 300) - 150.0;
      final y = -30 - (_end * (40 + (i % 5) * 12) + i * 9) % 420;
      final a = (1 - k * 0.3) * (0.5 + 0.5 * math.sin(_t * 3 + i));
      glowDot(canvas, Offset(x, y), 10, kWarmLight, 0.6 * a);
      canvas.drawCircle(
        Offset(x, y),
        1.8,
        Paint()..color = const Color(0xFFFFF4D0).withValues(alpha: a),
      );
    }
  }
}
