import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'player.dart';

// ================================================================ Fenerci

enum GuardState { patrol, pause, alert, chase }

/// Elinde fenerle devriye gezen avcı. Işık konisine giren ve gölgede
/// olmayan oyuncuyu görür, kovalar.
class Guard extends PositionComponent with HasGameReference<GolgeGame> {
  Guard(Vector2 cell)
      : super(position: Level.standOn(cell, gw, gh), size: Vector2(gw, gh), priority: 15);

  static const double gw = 24;
  static const double gh = 50;
  static const double patrolSpeed = 50;
  static const double chaseSpeed = 145;
  static const double viewDistance = 240;

  GuardState state = GuardState.patrol;
  int facing = -1;
  double _t = 0;
  double _anim = 0;
  double _lost = 0;

  Level get level => game.level;

  void _setState(GuardState s) {
    state = s;
    _t = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    final sees = !game.cinematic && _canSee(p);

    switch (state) {
      case GuardState.patrol:
        _anim += dt;
        if (!_walk(patrolSpeed * dt)) _setState(GuardState.pause);
        if (sees) _setState(GuardState.alert);
      case GuardState.pause:
        if (_t > 1.4) {
          facing = -facing;
          _setState(GuardState.patrol);
        }
        if (sees) _setState(GuardState.alert);
      case GuardState.alert:
        facing = p.center.x >= center.x ? 1 : -1;
        if (_t > 0.45) {
          _lost = 0;
          _setState(GuardState.chase);
        }
      case GuardState.chase:
        if (p.isDead) {
          _setState(GuardState.pause);
          break;
        }
        final dx = p.center.x - center.x;
        if (dx.abs() > 4) facing = dx > 0 ? 1 : -1;
        if (dx.abs() > 6) {
          _anim += dt * 2;
          _walk(math.min(chaseSpeed * dt, dx.abs()));
        }
        _lost = sees ? 0 : _lost + dt;
        if (_lost > 1.6) _setState(GuardState.pause);
    }

    if (!p.isDead &&
        p.toRect().deflate(3).overlaps(toRect().deflate(4))) {
      p.die();
      _setState(GuardState.pause);
    }
  }

  /// Yürüyebildiyse true; duvar ya da uçurum varsa false.
  bool _walk(double dist) {
    final front = facing > 0 ? position.x + gw + dist : position.x - dist;
    final c = (front / kTile).floor();
    final r0 = ((position.y + 1) / kTile).floor();
    final r1 = ((position.y + gh - 1) / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      if (level.solid(c, r)) return false;
    }
    final below = level.cell(c, ((position.y + gh + 1) / kTile).floor());
    if (below != '#' && below != '=') return false;
    position.x += facing * dist;
    return true;
  }

  Vector2 get _lantern =>
      Vector2(position.x + gw / 2 + facing * 15, position.y + 27);

  bool _canSee(Player p) {
    if (p.isDead || p.hidden) return false;
    final eye = _lantern;
    final target = p.center;
    final dx = target.x - eye.x;
    final dy = target.y - eye.y;
    final range = state == GuardState.chase ? viewDistance * 1.4 : viewDistance;
    if (dx * facing < -8) return false;
    if (dx.abs() > range) return false;
    if (dy.abs() > dx.abs() * 0.5 + 34) return false;
    // Otların içinde ama hareket ediyorsa: sadece yakından fark edilir.
    if (p.inShadow && dx.abs() > range * 0.45) return false;
    return level.lineOfSight(eye, target);
  }

  static final _ink = Paint()..color = kInk;
  static final _stroke = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final alert = state == GuardState.alert || state == GuardState.chase;
    canvas.save();
    if (facing < 0) {
      canvas.translate(gw, 0);
      canvas.scale(-1, 1);
    }
    const lantern = Offset(gw / 2 + 15, 27);

    // Işık konisi.
    final range = state == GuardState.chase ? viewDistance * 1.4 : viewDistance;
    final cone = Path()
      ..moveTo(lantern.dx, lantern.dy - 3)
      ..lineTo(lantern.dx + range, lantern.dy - range * 0.5 - 34)
      ..lineTo(lantern.dx + range, lantern.dy + range * 0.5 + 34)
      ..lineTo(lantern.dx, lantern.dy + 3)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = ui.Gradient.linear(
          lantern,
          lantern + Offset(range, 0),
          [
            kCold.withValues(alpha: alert ? 0.30 : 0.17),
            kCold.withValues(alpha: 0),
          ],
        ),
    );
    canvas.drawCircle(
      lantern,
      34,
      Paint()
        ..shader = ui.Gradient.radial(lantern, 34, [
          kCold.withValues(alpha: 0.55),
          kCold.withValues(alpha: 0),
        ]),
    );

    // Gövde: kambur, uzun paltolu.
    final step = math.sin(_anim * 7);
    _stroke.strokeWidth = 4;
    canvas.drawLine(const Offset(8, 42), Offset(8 + step * 3, gh), _stroke);
    canvas.drawLine(const Offset(15, 42), Offset(15 - step * 3, gh), _stroke);
    canvas.drawPath(
      Path()
        ..moveTo(3, 44)
        ..quadraticBezierTo(1, 20, 9, 13)
        ..quadraticBezierTo(17, 8, 21, 16)
        ..quadraticBezierTo(24, 30, 21, 44)
        ..close(),
      _ink,
    );
    // Kukuleta.
    canvas.drawPath(
      Path()
        ..moveTo(9, 16)
        ..quadraticBezierTo(8, 2, 17, 3)
        ..lineTo(24, 9)
        ..quadraticBezierTo(22, 17, 15, 18)
        ..close(),
      _ink,
    );
    canvas.drawCircle(
      const Offset(19.5, 9.5),
      1.4,
      Paint()..color = kCold.withValues(alpha: alert ? 0.95 : 0.5),
    );
    // Feneri tutan kol.
    _stroke.strokeWidth = 3.5;
    canvas.drawLine(const Offset(16, 20), lantern.translate(-2, -6), _stroke);
    canvas.drawLine(lantern.translate(0, -8), lantern.translate(0, -4), _stroke..strokeWidth = 1.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: lantern, width: 7, height: 9), const Radius.circular(2)),
      Paint()..color = kCold.withValues(alpha: 0.95),
    );
    canvas.restore();

    if (alert) {
      final a = Paint()..color = kCold;
      canvas.drawRect(const Rect.fromLTWH(gw / 2 - 1.5, -24, 3, 11), a);
      canvas.drawCircle(const Offset(gw / 2, -9), 1.8, a);
    }
  }
}

// ================================================================= Ak kuş

/// Çocuğa yol gösteren beyaz kuş. Oyuncu yaklaşınca çıkışa doğru uçar.
class Bird extends PositionComponent with HasGameReference<GolgeGame> {
  Bird(Vector2 cell, this.target)
      : super(position: Vector2(cell.x + kTile / 2, cell.y + kTile - 1), priority: 18);

  final Vector2 target;
  bool _flying = false;
  final _vel = Vector2.zero();
  double _t = math.Random().nextDouble() * 5;
  double _flyT = 0;
  double _alpha = 1;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (!_flying) {
      if (p != null && (p.center - position).length < 150) {
        _flying = true;
        final dir = target - position;
        if (dir.length < 1) dir.setValues(1, -1);
        _vel
          ..setFrom(dir.normalized() * 150)
          ..y -= 90;
      }
      return;
    }
    _flyT += dt;
    _vel.y -= 40 * dt;
    position += _vel * dt;
    if (_flyT > 2.2) _alpha -= dt * 0.8;
    if (_alpha <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = _alpha.clamp(0.0, 1.0);
    final white = Paint()..color = kLight.withValues(alpha: a);
    canvas.drawCircle(
      const Offset(0, -7),
      14,
      Paint()
        ..color = kLight.withValues(alpha: 0.25 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.save();
    final dirX = _flying ? _vel.x : target.x - position.x;
    if (dirX < 0) canvas.scale(-1, 1);
    final bob = _flying ? 0.0 : math.sin(_t * 2) * 0.6;
    canvas.translate(0, bob);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -6), width: 13, height: 8), white);
    canvas.drawCircle(const Offset(5.5, -10), 3.3, white);
    canvas.drawPath(
      Path()
        ..moveTo(8.5, -10.5)
        ..lineTo(12, -9.5)
        ..lineTo(8.5, -8.6)
        ..close(),
      white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-5, -7)
        ..lineTo(-11, -9)
        ..lineTo(-10, -4)
        ..close(),
      white,
    );
    if (_flying) {
      final flap = math.sin(_t * 18) * 10;
      for (final s in [1.0, 0.75]) {
        canvas.drawPath(
          Path()
            ..moveTo(-3, -7)
            ..quadraticBezierTo(-1, -12 - flap * s, -7, -16 - flap * s)
            ..lineTo(3, -7)
            ..close(),
          white,
        );
      }
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(-4, -8)
          ..quadraticBezierTo(0, -10, 3, -6)
          ..lineTo(-4, -5)
          ..close(),
        Paint()..color = const Color(0xFFBDBDB4).withValues(alpha: a),
      );
      final leg = Paint()
        ..color = kLight.withValues(alpha: a)
        ..strokeWidth = 1;
      canvas.drawLine(const Offset(-1, -2), const Offset(-1, 1), leg);
      canvas.drawLine(const Offset(2, -2), const Offset(2, 1), leg);
    }
    canvas.restore();
  }
}

// ========================================================== Hatıra parçası

class MemoryShard extends PositionComponent with HasGameReference<GolgeGame> {
  MemoryShard(Vector2 cell, this.index)
      : super(position: cell + Vector2.all(kTile / 2), priority: 18);

  final int index;
  double _t = math.Random().nextDouble() * 6;
  bool _taken = false;
  double _burst = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_taken) {
      _burst += dt;
      if (_burst > 0.9) removeFromParent();
      return;
    }
    final p = game.player;
    if (p != null && !p.isDead && (p.center - position).length < 24) {
      _taken = true;
      game.collectMemory(index);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_taken) {
      final k = _burst / 0.9;
      canvas.drawCircle(
        Offset.zero,
        6 + k * 70,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - k) + 0.5
          ..color = kWarmLight.withValues(alpha: (1 - k) * 0.8),
      );
      return;
    }
    final y = math.sin(_t * 2) * 4;
    final c = Offset(0, y);
    final pulse = 0.75 + math.sin(_t * 3.3) * 0.25;
    canvas.drawCircle(
      c,
      22,
      Paint()
        ..shader = ui.Gradient.radial(c, 22, [
          kWarmLight.withValues(alpha: 0.45 * pulse),
          kWarmLight.withValues(alpha: 0),
        ]),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_t * 0.8);
    canvas.drawPath(
      Path()
        ..moveTo(0, -6)
        ..lineTo(4, 0)
        ..lineTo(0, 6)
        ..lineTo(-4, 0)
        ..close(),
      Paint()..color = kWarmLight,
    );
    canvas.restore();
  }
}

// ============================================================ Işık kapısı

class ExitPortal extends PositionComponent with HasGameReference<GolgeGame> {
  ExitPortal(Vector2 cell)
      : super(position: Vector2(cell.x, cell.y - kTile), size: Vector2(kTile, kTile * 2), priority: 5);

  double _t = 0;
  bool _done = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_done || p == null || p.isDead) return;
    final door = Rect.fromLTWH(position.x + 8, position.y, kTile - 16, kTile * 2);
    if (door.overlaps(p.toRect())) {
      _done = true;
      game.onExitReached();
    }
  }

  @override
  void render(Canvas canvas) {
    const c = Offset(kTile / 2, kTile);
    final pulse = 0.85 + math.sin(_t * 1.7) * 0.15;
    canvas.drawCircle(
      c,
      130,
      Paint()
        ..shader = ui.Gradient.radial(c, 130, [
          kWarmLight.withValues(alpha: 0.42 * pulse),
          kWarmLight.withValues(alpha: 0.10 * pulse),
          kWarmLight.withValues(alpha: 0),
        ], [0, 0.35, 1]),
    );
    final door = RRect.fromLTRBAndCorners(
      3, 0, kTile - 3, kTile * 2,
      topLeft: const Radius.circular(13),
      topRight: const Radius.circular(13),
    );
    canvas.drawRRect(
      door,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, kTile * 2),
          [kWarmLight, kWarmLight.withValues(alpha: 0.75)],
        ),
    );
    final mote = Paint()..color = kWarmLight.withValues(alpha: 0.8);
    for (var i = 0; i < 7; i++) {
      final k = ((_t * 0.25 + i / 7) % 1.0);
      final x = kTile / 2 + math.sin(i * 2.1 + _t) * 22;
      canvas.drawCircle(Offset(x, kTile * 2 - k * 110), 1.4 * (1 - k) + 0.3, mote);
    }
  }
}
