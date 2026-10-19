import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'player.dart';

// ================================================================ Fenerci

enum GuardState { patrol, pause, alert, chase, investigate }

/// Elinde fenerle devriye gezen Kandilci.
///
/// Oyuncuyu ışık konisinde görünce hemen saldırmaz: önce şüphelenir ("?"),
/// durup bakar. Şüphe dolarsa "!" ile kovalar. Ses ve ateşböceği ışığı onu
/// o yöne çeker.
class Guard extends PositionComponent with HasGameReference<GolgeGame> {
  Guard(Vector2 cell)
    : super(
        position: Level.standOn(cell, gw, gh),
        size: Vector2(gw, gh),
        priority: 15,
      );

  static const double gw = 24;
  static const double gh = 50;
  static const double patrolSpeed = 45;
  static const double chaseSpeed = 130;
  static const double viewDistance = 240;

  GuardState state = GuardState.patrol;
  int facing = -1;
  double suspicion = 0;
  double _t = 0;
  double _anim = 0;
  double _lost = 0;
  double _lastSeenX = 0;
  double? _investigateX;
  FireflyLure? _lure;

  Level get level => game.level;

  void _setState(GuardState s) {
    state = s;
    _t = 0;
  }

  bool get _calm =>
      state == GuardState.patrol ||
      state == GuardState.pause ||
      state == GuardState.investigate;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    final sees = !game.cinematic && _canSee(p);
    if (sees) _lastSeenX = p.center.x;

    // Şüphe: görünür kaldıkça dolar, gözden kaybolunca yavaşça söner.
    if (sees) {
      final near = (p.center.x - center.x).abs() < 110;
      suspicion = math.min(1, suspicion + dt * (near ? 2.4 : 1.15));
    } else {
      suspicion = math.max(0, suspicion - dt * 0.55);
    }
    if (_calm && suspicion >= 1) _setState(GuardState.alert);

    // Şüphelenen Kandilci durur ve oyuncunun olduğu yere bakar.
    final staring = _calm && sees;
    if (staring) facing = _lastSeenX >= center.x ? 1 : -1;

    switch (state) {
      case GuardState.patrol:
        if (!staring) {
          _anim += dt;
          if (!_walk(patrolSpeed * dt)) _setState(GuardState.pause);
          _noticeLure();
        }
      case GuardState.pause:
        if (!staring && _t > 1.4) {
          facing = -facing;
          _setState(GuardState.patrol);
        }
        if (!staring) _noticeLure();
      case GuardState.investigate:
        if (staring) break;
        final lure = _lure;
        final targetX = (lure != null && lure.isMounted)
            ? lure.position.x
            : _investigateX;
        if (targetX != null) {
          final dx = targetX - center.x;
          if (dx.abs() > 3) facing = dx > 0 ? 1 : -1;
          if (dx.abs() > 12 &&
              _walk(math.min(patrolSpeed * 1.4 * dt, dx.abs()))) {
            _anim += dt * 1.3;
            _t = 0;
          } else if (lure == null || !lure.isMounted) {
            // Sesin geldiği yere vardı: bir süre bakınır.
            _investigateX = null;
            _t = 0;
          } else {
            _t = 0;
          }
        } else if (_t > 2.2) {
          _lure = null;
          _setState(GuardState.pause);
        } else {
          // Etrafa bakınır.
          if ((_t * 1.2).floor().isOdd != (facing > 0)) facing = -facing;
        }
      case GuardState.alert:
        facing = _lastSeenX >= center.x ? 1 : -1;
        if (_t > 0.4) {
          _lost = 0;
          _setState(GuardState.chase);
        }
      case GuardState.chase:
        if (p.isDead) {
          suspicion = 0;
          _setState(GuardState.pause);
          break;
        }
        // Gördüğü son yere koşar; saklanan oyuncunun yerini bilemez.
        final dx = _lastSeenX - center.x;
        if (dx.abs() > 4) facing = dx > 0 ? 1 : -1;
        if (dx.abs() > 6) {
          _anim += dt * 2;
          _walk(math.min(chaseSpeed * dt, dx.abs()));
        }
        _lost = sees ? 0 : _lost + dt;
        if (_lost > 1.6) {
          suspicion = 0.5;
          _investigateX = _lastSeenX;
          _setState(GuardState.investigate);
        }
    }

    // Saklanan oyuncunun önünden geçip gider; yalnızca onu az önce görmüşse
    // ya da oyuncu açıktaysa yakalar.
    final justSaw = state == GuardState.chase && _lost < 0.4;
    if (!p.isDead &&
        (!p.hidden || justSaw) &&
        p.toRect().deflate(2).overlaps(toRect().deflate(4))) {
      p.die();
      suspicion = 0;
      _setState(GuardState.pause);
    }
  }

  /// Oyuncunun çıkardığı sesler: yakındaysa Kandilci o yöne gider.
  void hear(Vector2 from, double radius) {
    if (!_calm) return;
    final d = from - center;
    if (d.x.abs() > radius || d.y.abs() > 110) return;
    _lure = null;
    _investigateX = from.x;
    suspicion = math.max(suspicion, 0.35);
    _setState(GuardState.investigate);
  }

  void _noticeLure() {
    for (final lure in game.world.children.whereType<FireflyLure>()) {
      if (!lure.glowing) continue;
      final d = lure.position - _lantern;
      if (d.length > 300 || !level.lineOfSight(_lantern, lure.position)) {
        continue;
      }
      _lure = lure;
      _investigateX = null;
      _setState(GuardState.investigate);
      return;
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

  Vector2 get lanternWorld => _lantern;
  double get coneRange =>
      state == GuardState.chase ? viewDistance * 1.4 : viewDistance;

  Vector2 get _lantern =>
      Vector2(position.x + gw / 2 + facing * 15, position.y + 27);

  bool _canSee(Player p) {
    if (p.isDead || p.hidden) return false;
    final eye = _lantern;
    final target = p.center;
    final dx = target.x - eye.x;
    final dy = target.y - eye.y;
    var range = state == GuardState.chase ? viewDistance * 1.4 : viewDistance;
    // Çömelip kavanozunu örten ya da parmak ucunda yürüyen çocuk zor seçilir.
    if (state != GuardState.chase) {
      if (p.crouching) {
        range *= 0.5;
      } else if (p.sneaking) {
        range *= 0.7;
      }
    }
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
        ..shader = ui.Gradient.linear(lantern, lantern + Offset(range, 0), [
          kCold.withValues(alpha: alert ? 0.30 : 0.17),
          kCold.withValues(alpha: 0),
        ]),
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
    canvas.drawLine(
      lantern.translate(0, -8),
      lantern.translate(0, -4),
      _stroke..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: lantern, width: 7, height: 9),
        const Radius.circular(2),
      ),
      Paint()..color = kCold.withValues(alpha: 0.95),
    );
    canvas.restore();

    // Şüphe "?" ile görünür: dolmaya başladıkça belirginleşir.
    final doubt = state == GuardState.investigate
        ? 1.0
        : (alert ? 0.0 : suspicion);
    if (doubt > 0.02) {
      final q = Paint()
        ..color = kWarmLight.withValues(alpha: 0.35 + 0.65 * doubt)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        const Rect.fromLTWH(gw / 2 - 4, -27, 8, 8),
        math.pi,
        math.pi * 1.4,
        false,
        q,
      );
      canvas.drawLine(
        const Offset(gw / 2 + 1, -19.5),
        const Offset(gw / 2, -15),
        q,
      );
      canvas.drawCircle(
        const Offset(gw / 2, -10),
        1.6,
        Paint()..color = kWarmLight.withValues(alpha: 0.35 + 0.65 * doubt),
      );
    }
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
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile - 1),
        priority: 18,
      );

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
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 13, height: 8),
      white,
    );
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
    : super(
        position: Vector2(cell.x, cell.y - kTile),
        size: Vector2(kTile, kTile * 2),
        priority: 5,
      );

  double _t = 0;
  bool _done = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_done || p == null || p.isDead) return;
    final door = Rect.fromLTWH(
      position.x + 8,
      position.y,
      kTile - 16,
      kTile * 2,
    );
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
        ..shader = ui.Gradient.radial(
          c,
          130,
          [
            kWarmLight.withValues(alpha: 0.42 * pulse),
            kWarmLight.withValues(alpha: 0.10 * pulse),
            kWarmLight.withValues(alpha: 0),
          ],
          [0, 0.35, 1],
        ),
    );
    final door = RRect.fromLTRBAndCorners(
      3,
      0,
      kTile - 3,
      kTile * 2,
      topLeft: const Radius.circular(13),
      topRight: const Radius.circular(13),
    );
    canvas.drawRRect(
      door,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, kTile * 2), [
          kWarmLight,
          kWarmLight.withValues(alpha: 0.75),
        ]),
    );
    final mote = Paint()..color = kWarmLight.withValues(alpha: 0.8);
    for (var i = 0; i < 7; i++) {
      final k = ((_t * 0.25 + i / 7) % 1.0);
      final x = kTile / 2 + math.sin(i * 2.1 + _t) * 22;
      canvas.drawCircle(
        Offset(x, kTile * 2 - k * 110),
        1.4 * (1 - k) + 0.3,
        mote,
      );
    }
  }
}

// ======================================================== Ateşböceği yemi

/// Kavanozdan salınan ateşböceği: ileri uçar, bir süre havada süzülüp parlar.
/// Kandilciler ışığını görünce ona yönelir.
class FireflyLure extends PositionComponent with HasGameReference<GolgeGame> {
  FireflyLure(Vector2 from, int direction)
    : _vel = Vector2(direction * 380.0, -80),
      super(position: from.clone(), priority: 22);

  static const double life = 5.5;
  final Vector2 _vel;
  double _t = 0;

  bool get glowing => _t < life - 0.6;
  double get strength =>
      (1 - ((_t - (life - 1.2)) / 1.2).clamp(0.0, 1.0)) *
      (0.85 + 0.15 * math.sin(_t * 13));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t < 0.9) {
      final next = position + _vel * dt;
      if (game.level.cellAt(next.x, next.y) == '#') {
        _vel.setZero();
      } else {
        position.setFrom(next);
      }
      _vel.scale(math.pow(0.3, dt).toDouble());
    } else {
      position.y += math.sin(_t * 2.4) * 8 * dt;
      position.x += math.cos(_t * 1.7) * 6 * dt;
    }
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = strength.clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      26,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, 26, [
          kWarmLight.withValues(alpha: 0.5 * a),
          kWarmLight.withValues(alpha: 0),
        ]),
    );
    canvas.drawCircle(
      Offset.zero,
      2.2,
      Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: a),
    );
  }
}

// ================================================================== Sandık

/// İtilebilir ahşap sandık: üstüne çıkılır, yüksek yerlere basamak olur.
class Crate extends PositionComponent with HasGameReference<GolgeGame> {
  Crate(Vector2 cell)
    : super(
        position: Vector2(cell.x + 1, cell.y + kTile - side),
        size: Vector2.all(side),
        priority: 17,
      );

  static const double side = 30;
  double _vy = 0;

  Level get level => game.level;

  bool _blockedAt(Rect r) {
    if (level.rectSolid(r.left, r.top, r.right, r.bottom)) return true;
    for (final g in game.world.children.whereType<Gate>()) {
      if (g.solid && g.toRect().overlaps(r)) return true;
    }
    for (final c in game.world.children.whereType<Crate>()) {
      if (c != this && c.toRect().overlaps(r)) return true;
    }
    return false;
  }

  /// İtilmeye çalışılır; gerçekte ne kadar kaydığını döndürür.
  double push(double dx) {
    if (_vy.abs() > 1) return 0;
    final target = toRect().shift(Offset(dx, 0)).deflate(0.5);
    if (_blockedAt(target)) return 0;
    position.x += dx;
    return dx;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Uzun bir kare (ör. yükleme) sandığı zeminin içinden geçirmesin.
    dt = math.min(dt, 1 / 30);
    final prevBottom = position.y + side;
    _vy = math.min(_vy + 1900 * dt, 900);
    position.y += _vy * dt;
    final bottom = position.y + side;
    final r = ((bottom - 0.001) / kTile).floor();
    final c0 = ((position.x + 1) / kTile).floor();
    final c1 = ((position.x + side - 1) / kTile).floor();
    for (var c = c0; c <= c1; c++) {
      final ch = level.cell(c, r);
      if (ch == '#' || (ch == '=' && prevBottom <= r * kTile + 0.5)) {
        position.y = r * kTile - side;
        _vy = 0;
        return;
      }
    }
    if (position.y > level.pixelHeight + 200) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final box = Rect.fromLTWH(0, 0, side, side);
    canvas.drawRect(box, Paint()..color = const Color(0xFF2E1A10));
    // Üst ve ön kenara vuran sıcak ışık: karanlıkta da seçilsin.
    final rim = Paint()
      ..color = const Color(0xFFD08A5A).withValues(alpha: 0.55)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(0, 0.8), const Offset(side, 0.8), rim);
    canvas.drawLine(const Offset(0.8, 0), const Offset(0.8, side), rim);
    final plank = Paint()
      ..color = const Color(0xFF9A5A30).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(box.deflate(1.5), plank);
    canvas.drawLine(
      const Offset(2, 2),
      const Offset(side - 2, side - 2),
      plank,
    );
    canvas.drawLine(
      const Offset(2, side / 2),
      const Offset(side - 2, side / 2),
      plank,
    );
  }
}

// ==================================================================== Kapı

/// Demir parmaklıklı kapı: kol çekilince yukarı kalkar.
class Gate extends PositionComponent with HasGameReference<GolgeGame> {
  Gate(int col, int top, int bottom)
    : _height = (bottom - top + 1) * kTile,
      super(
        position: Vector2(col * kTile + 8, top * kTile.toDouble()),
        size: Vector2(16, (bottom - top + 1) * kTile),
        priority: 16,
      );

  final double _height;
  bool opening = false;
  double _lift = 0;

  bool get solid => _lift < _height * 0.75;

  @override
  Rect toRect() =>
      Rect.fromLTWH(position.x, position.y - _lift, size.x, size.y);

  @override
  void update(double dt) {
    super.update(dt);
    if (opening && _lift < _height) _lift = math.min(_height, _lift + dt * 70);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, -_lift);
    final bar = Paint()..color = const Color(0xFF0E0806);
    for (var x = 0.0; x <= 14; x += 4.6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2.6, _height), bar);
    }
    for (var y = 6.0; y < _height; y += 24) {
      canvas.drawRect(Rect.fromLTWH(-1, y, 18, 3), bar);
    }
    canvas.drawLine(
      const Offset(0.5, 0),
      Offset(0.5, _height),
      Paint()
        ..color = const Color(0xFF8A4A2A).withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    for (var x = 1.3; x <= 15; x += 4.6) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 1.6, _height)
          ..lineTo(x + 1.3, _height + 5)
          ..lineTo(x + 4, _height),
        bar,
      );
    }
    canvas.restore();
  }
}

// ===================================================================== Kol

/// Duvardaki kol: oyuncu yanındayken ↑ ile çekilir, bölümdeki kapıları açar.
class Lever extends PositionComponent with HasGameReference<GolgeGame> {
  Lever(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  bool pulled = false;
  double _swing = 0;
  double _t = 0;

  bool near(Vector2 p) =>
      (p - position).x.abs() < 22 && (p - position).y.abs() < 40;

  void pull() {
    if (pulled) return;
    pulled = true;
    for (final g in game.world.children.whereType<Gate>()) {
      g.opening = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (pulled) _swing = math.min(1, _swing + dt * 4);
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    canvas.drawRect(const Rect.fromLTWH(-7, -5, 14, 5), ink);
    canvas.save();
    canvas.translate(0, -3);
    canvas.rotate(-0.7 + _swing * 1.4);
    canvas.drawRect(const Rect.fromLTWH(-1.5, -17, 3, 17), ink);
    canvas.drawCircle(const Offset(0, -17), 3, ink);
    canvas.drawCircle(
      const Offset(-0.8, -17.8),
      1.6,
      Paint()..color = const Color(0xFFD08A5A).withValues(alpha: 0.7),
    );
    canvas.restore();
    final p = game.player;
    if (!pulled && p != null && near(p.center)) {
      final a = 0.55 + 0.45 * math.sin(_t * 5);
      final arrow = Paint()
        ..color = kWarmLight.withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -26), const Offset(0, -38), arrow);
      canvas.drawLine(const Offset(-4, -33), const Offset(0, -38), arrow);
      canvas.drawLine(const Offset(4, -33), const Offset(0, -38), arrow);
    }
  }
}

// ============================================================ Ses halkası

/// Oyuncunun çıkardığı sesin görsel ipucu: ayakların altında açılan halka.
class NoiseRing extends PositionComponent {
  NoiseRing(Vector2 at, this.radius)
    : super(position: at.clone(), priority: 21);

  final double radius;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.5) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = _t / 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.5 * k,
        height: radius * 0.12 * k,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = kText.withValues(alpha: 0.35 * (1 - k)),
    );
  }
}
