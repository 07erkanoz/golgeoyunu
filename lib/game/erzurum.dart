import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';

// IX · Kar Yolu: Erzurum'un damları. Evliya Çelebi anlatır: Erzurum'da kış
// öyle sert gelir ki damdan dama atlayan kedi havada donar. Damların
// arasında, sıçrayışın tam ortasında donup kalmış bir kedi (küçük sürpriz).

class FrozenCat extends PositionComponent with HasGameReference<GolgeGame> {
  FrozenCat(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 18);

  double _t = 0;
  bool _seen = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_seen || p == null || p.isDead) return;
    if ((p.center - position).length < 3.2 * kTile) {
      _seen = true;
      GameAudio.instance.play('shatter', volume: 0.25);
      game.hint('frozenCat');
      if (!game.secretSeen('donmusKedi')) game.foundSecret('donmusKedi');
    }
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF0E1418);
    // Uzanmış gövde: önde kollar, arkada kuyruk; havada.
    final body = Path()
      ..moveTo(-22, 2)
      ..quadraticBezierTo(-10, -9, 8, -7)
      ..quadraticBezierTo(18, -6, 22, -2)
      ..lineTo(34, 2) // ön kollar uzanmış
      ..lineTo(33, 4)
      ..lineTo(20, 3)
      ..quadraticBezierTo(4, 6, -12, 5)
      ..lineTo(-26, 10) // arka bacaklar geride
      ..lineTo(-27, 8)
      ..close();
    canvas.drawPath(body, ink);
    // Baş ve kulaklar.
    canvas.drawCircle(const Offset(23, -8), 6, ink);
    canvas.drawPath(
      Path()
        ..moveTo(19, -12)
        ..lineTo(20, -19)
        ..lineTo(23, -13)
        ..moveTo(24, -13)
        ..lineTo(27, -19)
        ..lineTo(28, -11),
      ink,
    );
    // Kuyruk: havada donmuş bir kıvrım.
    canvas.drawPath(
      Path()
        ..moveTo(-21, 1)
        ..quadraticBezierTo(-34, -4, -36, -16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF0E1418),
    );
    // Kırağı: ince açık çizgi ve sarkan buz parçaları.
    final frost = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFCFE8F2).withValues(alpha: 0.75);
    canvas.drawPath(body, frost);
    canvas.drawCircle(const Offset(23, -8), 6, frost);
    final ice = Paint()..color = const Color(0xFFDDF1F8).withValues(alpha: 0.8);
    for (final x in [-8.0, 0.0, 9.0, 16.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 1.5, 5)
          ..lineTo(x + 1.5, 5)
          ..lineTo(x, 10 + (x.abs() % 5)),
        ice,
      );
    }
    // Gözü açık, şaşkın.
    canvas.drawCircle(
      const Offset(25, -9),
      1.3,
      Paint()..color = const Color(0xFFE8F6FA),
    );
    // Arada bir buzda pırıltı.
    final glint = (math.sin(_t * 1.7) + 1) / 2;
    if (glint > 0.85) {
      canvas.drawCircle(
        const Offset(4, -8),
        1.6 + (glint - 0.85) * 12,
        Paint()
          ..color = const Color(0xFFFFFFFF)
              .withValues(alpha: (glint - 0.85) * 5),
      );
    }
  }
}

/// Erzurum evi: damı karlı, taş duvarlı; sokağa bakan küçük pencerelerden
/// ocağın ışığı sızar. Yalnızca görünüş: ev haritadaki kaya bloğudur.
class ErzurumHouse extends PositionComponent with HasGameReference<GolgeGame> {
  ErzurumHouse(int c0, int c1, int roof)
    : super(
        position: Vector2(c0 * kTile.toDouble(), roof * kTile.toDouble()),
        size: Vector2(
          (c1 - c0 + 1) * kTile.toDouble(),
          (20 - roof) * kTile.toDouble(),
        ),
        priority: 2,
      );

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;
    // Taş duvar: sıra sıra yonu.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1E2228),
    );
    final mortar = Paint()
      ..color = const Color(0xFF2C323A)
      ..strokeWidth = 1;
    for (var y = 10.0; y < h; y += 14) {
      canvas.drawLine(Offset(2, y), Offset(w - 2, y), mortar);
      final off = (y ~/ 14).isOdd ? 0.0 : 12.0;
      for (var x = off + 6; x < w - 4; x += 24) {
        canvas.drawLine(Offset(x, y - 14), Offset(x, y), mortar);
      }
    }
    // Ahşap hatıllar.
    final beam = Paint()..color = const Color(0xFF3A2A1C);
    canvas.drawRect(Rect.fromLTWH(0, 4, w, 5), beam);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, 4), beam);
    // Pencereler: ocağın ışığı titrer.
    final flick = 0.75 + 0.25 * math.sin(_t * 5.3 + position.x);
    final glow = Paint()
      ..color = const Color(0xFFE8A050).withValues(alpha: 0.55 * flick);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF2A1C12);
    final n = (w / 72).floor().clamp(1, 4);
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * w / n - 9;
      final r = Rect.fromLTWH(x, 22, 18, 22);
      canvas.drawRect(r, glow);
      canvas.drawRect(r, frame);
      canvas.drawLine(r.topCenter, r.bottomCenter, frame);
    }
    // Kapı.
    final door = Rect.fromLTWH(w / 2 - 11, h - 40, 22, 40);
    canvas.drawRect(door, Paint()..color = const Color(0xFF2C1E14));
    canvas.drawRect(door, frame);
    // Damın kar saçağı: kenarlardan sarkan yumuşak kar.
    final snow = Paint()..color = const Color(0xFFE6EEF2);
    final eave = Path()..moveTo(-4, 0);
    for (var x = -4.0; x <= w + 4; x += 10) {
      eave.lineTo(x, 4 + (x.toInt() * 7 % 5).toDouble());
    }
    eave
      ..lineTo(w + 4, -3)
      ..lineTo(-4, -3)
      ..close();
    canvas.drawPath(eave, snow);
  }
}
