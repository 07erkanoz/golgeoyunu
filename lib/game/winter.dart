import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'player.dart';

// ================================================================== Kurt

/// Kış gecesinin kurdu: kokuyu izler, saklananı da bulur. Ağaçlara,
/// sarmaşıklara ve yüksek kayalara tırmanamaz; ateşböceği ışığından korkar.
/// Ağırdır: ince buz altında hemen kırılır.
class Wolf extends PositionComponent with HasGameReference<GolgeGame> {
  Wolf(Vector2 cell)
    : _home = cell.x,
      super(
        position: Level.standOn(cell, 30, 20),
        size: Vector2(30, 20),
        priority: 17,
      );

  static const double runSpeed = 150;
  static const double smell = 9 * kTile;

  final double _home;
  double _vy = 0;
  int facing = -1;
  bool hunting = false;
  bool falling = false;
  double _lost = 0;
  double _t = 0;
  double _fear = 0;
  bool _onGround = false;

  Level get level => game.level;

  bool _solidAt(double x, double y) => level.cellAt(x, y) == '#';

  @override
  void update(double dt) {
    super.update(dt);
    dt = math.min(dt, 1 / 30);
    _t += dt;
    final p = game.player;
    if (falling) {
      _vy = math.min(_vy + 1500 * dt, 800);
      position.y += _vy * dt;
      if (position.y > level.pixelHeight + 40 ||
          level.cellAt(center.x, position.y + size.y) == 'w') {
        GameAudio.instance.play('splash', volume: 0.7);
        removeFromParent();
      }
      return;
    }
    // Işıktan korkar.
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position - center).length < 110) {
        _fear = 1.5;
      }
    }
    var vx = 0.0;
    if (p != null && !p.isDead) {
      final d = p.center - center;
      if (!hunting && d.length < smell) {
        hunting = true;
        GameAudio.instance.play('crow', volume: 0.6, minGapMs: 3000);
      }
      if (hunting) {
        if (_fear > 0) {
          _fear -= dt;
          vx = -d.x.sign * runSpeed * 0.8;
        } else if (d.x.abs() > 6) {
          vx = d.x.sign * runSpeed;
        }
        // Ulaşamadığı yerdeki avı bir süre bekler, sonra döner.
        final reachable = d.y > -kTile * 1.5;
        _lost = reachable ? 0 : _lost + dt;
        if (_lost > 6) {
          hunting = false;
          _lost = 0;
        }
        if (d.x.abs() < 18 && d.y.abs() < 24) p.die(cause: DeathCause.dark);
      }
    }
    if (!hunting) {
      // Yuvasına döner.
      final back = _home - position.x;
      if (back.abs() > 4) vx = back.sign * 60;
    }
    if (vx != 0) facing = vx > 0 ? 1 : -1;
    _move(vx * dt);
    _fall(dt);
  }

  void _move(double dx) {
    if (dx == 0) return;
    final front = dx > 0 ? position.x + size.x + dx : position.x + dx;
    final top = position.y + 2;
    final feet = position.y + size.y - 2;
    // Bir karelik basamağa çıkar, daha yüksek duvarda durur.
    if (_solidAt(front, feet)) {
      if (!_solidAt(front, feet - kTile) &&
          !_solidAt(front, top - kTile) &&
          _onGround) {
        position.y -= kTile;
      } else {
        return;
      }
    }
    if (_solidAt(front, top)) return;
    position.x += dx;
  }

  void _fall(double dt) {
    _vy = math.min(_vy + 1500 * dt, 800);
    final prevBottom = position.y + size.y;
    position.y += _vy * dt;
    _onGround = false;
    final bottom = position.y + size.y;
    if (_solidAt(position.x + 4, bottom) ||
        _solidAt(position.x + size.x - 4, bottom)) {
      position.y = (bottom / kTile).floor() * kTile - size.y;
      _vy = 0;
      _onGround = true;
      return;
    }
    for (final d in game.world.children.whereType<Deck>()) {
      if (!d.active) continue;
      final r = d.toRect();
      if (position.x + size.x - 4 <= r.left || position.x + 4 >= r.right) {
        continue;
      }
      if (prevBottom <= r.top + 1 && bottom >= r.top) {
        position.y = r.top - size.y;
        _vy = 0;
        _onGround = true;
        if (d is ThinIce) d.crack(heavy: true);
        return;
      }
    }
    if (position.y > level.pixelHeight + 40) removeFromParent();
  }

  void plunge() {
    falling = true;
    _vy = 0;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    final ink = Paint()..color = kInk;
    final run = hunting ? math.sin(_t * 18) : math.sin(_t * 4) * 0.3;
    // Gövde, baş, kulaklar, kuyruk, bacaklar.
    canvas.drawOval(const Rect.fromLTWH(2, 4, 22, 10), ink);
    canvas.drawPath(
      Path()
        ..moveTo(20, 6)
        ..lineTo(30, 7)
        ..lineTo(26, 12)
        ..lineTo(20, 11)
        ..close(),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(21, 5)
        ..lineTo(23, 0)
        ..lineTo(25, 5)
        ..close(),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(3, 7)
        ..quadraticBezierTo(-4, 6 + run * 3, -6, 2)
        ..lineTo(-4, 1)
        ..quadraticBezierTo(-2, 5, 4, 9)
        ..close(),
      ink,
    );
    for (final (x, ph) in [(5.0, 0.0), (9.0, 1.6), (17.0, 3.1), (21.0, 4.7)]) {
      final sw = math.sin(_t * 18 + ph) * (hunting ? 3 : 0.5);
      canvas.drawLine(
        Offset(x, 12),
        Offset(x + sw, 20),
        Paint()
          ..color = kInk
          ..strokeWidth = 2,
      );
    }
    // Gözler: soluk sarı.
    canvas.drawCircle(
      const Offset(25, 7.5),
      1.3,
      Paint()
        ..color = const Color(0xFFFFE08A)
            .withValues(alpha: hunting ? 0.95 : 0.4),
    );
    canvas.restore();
    if (hunting) {
      glowDot(
        canvas,
        Offset(size.x / 2 + facing * 12, 8),
        10,
        const Color(0xFFFFE08A),
        0.2,
      );
    }
  }
}

// ============================================================= İnce buz

/// Donmuş gölün ince buzu (tek kare): üstünde fazla durulursa çatlar ve
/// kırılır; ağır bir kurt basınca hemen kırılır.
class ThinIce extends Deck {
  ThinIce(Vector2 cell)
    : super(
        position: Vector2(cell.x, cell.y),
        size: Vector2(kTile.toDouble(), 10),
      );

  double _stress = 0;
  bool broken = false;
  double _gone = 0;

  @override
  bool get active => !broken;

  void crack({bool heavy = false}) {
    if (broken) return;
    if (heavy) {
      _break();
      for (final w in game.world.children.whereType<Wolf>()) {
        if (w.toRect().overlaps(toRect().inflate(4))) w.plunge();
      }
    }
  }

  void _break() {
    broken = true;
    GameAudio.instance.play('shatter', volume: 0.5);
    GameAudio.instance.play('splash', volume: 0.4);
  }

  @override
  void step(double dt) {
    if (broken) {
      _gone += dt;
      return;
    }
    final p = game.player;
    if (p != null && p.riding == this) {
      _stress += dt;
      if (_stress > 0.15 && _stress - dt <= 0.15) {
        GameAudio.instance.play('creak', volume: 0.5);
      }
      if (_stress > 0.7) _break();
    } else {
      _stress = math.max(0, _stress - dt * 0.5);
    }
  }

  @override
  void render(Canvas canvas) {
    if (broken) {
      final a = (1 - _gone).clamp(0.0, 1.0);
      if (a <= 0) return;
      final shard = Paint()
        ..color = const Color(0xFFB8CCE4).withValues(alpha: 0.6 * a);
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(
          Rect.fromLTWH(i * 8.0, _gone * 30 * (i % 2 + 1), 6, 4),
          shard,
        );
      }
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 8),
      Paint()..color = const Color(0xFF9AB4D0).withValues(alpha: 0.55),
    );
    canvas.drawLine(
      const Offset(0, 0.8),
      Offset(size.x, 0.8),
      Paint()
        ..color = const Color(0xFFEAF2FF).withValues(alpha: 0.7)
        ..strokeWidth = 1.2,
    );
    // Çatlaklar: baskı arttıkça büyür.
    if (_stress > 0.05) {
      final k = (_stress / 0.7).clamp(0.0, 1.0);
      final crack = Paint()
        ..color = const Color(0xFF2A3A55)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(16, 1), Offset(16 - 10 * k, 7), crack);
      canvas.drawLine(Offset(16, 1), Offset(16 + 12 * k, 6), crack);
      canvas.drawLine(Offset(16 + 6 * k, 3), Offset(16 + 3 * k, 8), crack);
    }
  }
}
