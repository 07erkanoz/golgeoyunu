import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'player.dart';

// ================================================================ Gemi'nin ambarları
//
// Delikli Ambar: Anadolu'da anlatılır ki tufanda gemiyi bir fare deldi,
// yılan deliği kuyruğuyla tıkadı. Ambarın tabanındaki deliklerden su
// fışkırır, yaklaşanı geri savurur; sandığı itip ardına sığınarak deliğin
// üstüne sürmek onu tıkar. Bütün delikler tıkanınca ileriki kapı açılır.
//
// Yalpalayan Ambar: gemi dalgada yalpaladıkça bağı kopmuş fıçılar
// bölmelerde bir o yana bir bu yana yuvarlanır. Sandık yığınlarının üstünde
// bekle, fıçı geçince koş ya da üstünden atla.

/// Ambarın tabanındaki delik: su fışkırır; üstüne sandık sürülünce tıkanır.
class LeakJet extends PositionComponent with HasGameReference<GolgeGame> {
  LeakJet(int col, int floorRow)
    : super(
        position: Vector2((col + 0.5) * kTile, floorRow * kTile.toDouble()),
        priority: 18,
      );

  /// Fışkıran suyun boyu ve savurma gücü.
  static const double reach = 6.5 * kTile;
  static const double push = 520;

  double _t = 0;
  bool plugged = false;
  bool _opened = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final wasPlugged = plugged;
    plugged = game.world.children.whereType<Crate>().any(
      (c) =>
          (c.center.x - position.x).abs() < 12 &&
          (c.position.y + Crate.side - position.y).abs() < 6,
    );
    if (plugged && !wasPlugged) {
      GameAudio.instance.play('creak', volume: 0.5);
      GameAudio.instance.play('splash', volume: 0.35);
      _checkAll();
    }
    if (plugged) return;
    // Su sütununa giren geri ve yukarı savrulur.
    final p = game.player;
    if (p == null || p.isDead) return;
    final dx = p.center.x - position.x;
    if (dx.abs() < 14 && p.position.y + Player.h > position.y - reach) {
      final side = dx == 0 ? -1.0 : dx.sign;
      p.velocity.x = side * 260;
      p.velocity.y = math.min(p.velocity.y, -push);
      p.onGround = false;
      GameAudio.instance.play('splash', volume: 0.5, minGapMs: 500);
    }
  }

  void _checkAll() {
    final jets = game.world.children.whereType<LeakJet>().toList();
    if (_opened || !jets.every((j) => j.plugged)) return;
    for (final j in jets) {
      j._opened = true;
    }
    // Deliklerin sağındaki en yakın kapı açılır.
    final right = jets.map((j) => j.position.x).reduce(math.max);
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final d = g.position.x - right;
      if (d < 0 || g.opening) continue;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    best?.opening = true;
    GameAudio.instance.play('gate', volume: 0.6);
  }

  @override
  void render(Canvas canvas) {
    // Deliğin ağzı.
    canvas.drawOval(
      const Rect.fromLTWH(-9, -3, 18, 6),
      Paint()..color = const Color(0xFF0A0604),
    );
    if (plugged) return;
    // Fışkıran su: titreşen, köpüklü bir sütun.
    final h = reach * (0.92 + 0.08 * math.sin(_t * 23));
    final col = Path()
      ..moveTo(-7, 0)
      ..quadraticBezierTo(-10 + math.sin(_t * 17) * 2, -h * 0.5, -5, -h)
      ..lineTo(5, -h)
      ..quadraticBezierTo(10 + math.sin(_t * 19) * 2, -h * 0.5, 7, 0)
      ..close();
    canvas.drawPath(
      col,
      Paint()
        ..shader = Gradient.linear(const Offset(0, 0), Offset(0, -h), [
          const Color(0xFFBFE6F2).withValues(alpha: 0.85),
          const Color(0xFFBFE6F2).withValues(alpha: 0.15),
        ]),
    );
    final foam = Paint()
      ..color = const Color(0xFFF2FBFF).withValues(alpha: 0.8);
    for (var i = 0; i < 6; i++) {
      final k = ((_t * 1.7 + i / 6) % 1.0);
      canvas.drawCircle(
        Offset(math.sin(i * 2.1 + _t * 5) * 8, -h * k),
        1.6 + (1 - k) * 1.4,
        foam,
      );
    }
  }
}

/// Bağı kopmuş fıçı: bölmesinde geminin yalpasıyla bir o yana bir bu yana
/// yuvarlanır. Değdiği yerdeki Sâye ezilir; üstünden atlanır.
class RollingBarrel extends PositionComponent with HasGameReference<GolgeGame> {
  RollingBarrel(this.c0, this.c1, int floorRow, {this.phase = 0})
    : super(
        position: Vector2(
          (c0 + 1) * kTile.toDouble(),
          floorRow * kTile.toDouble(),
        ),
        priority: 17,
      );

  /// Bölmenin iki ucu (sütun): fıçı bu aralıkta yuvarlanır.
  final int c0;
  final int c1;
  final double phase;

  /// Yalpanın dönemi (sn): bütün fıçılar aynı dalgayla.
  static const double period = 6.4;
  static const double radius = 14;

  double _t = 0;
  double _spin = 0;
  double _prevX = 0;

  /// Yalpanın açısı (-1 sola, 1 sağa yatık): uçlarda bir an durur.
  double get roll {
    final s = math.sin((_t + phase) * 2 * math.pi / period);
    return s.sign * math.pow(s.abs(), 0.6).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final left = c0 * kTile + radius + 2;
    final right = (c1 + 1) * kTile - radius - 2;
    _prevX = position.x;
    position.x = left + (right - left) * (0.5 + 0.5 * roll);
    _spin += (position.x - _prevX) / radius;
    // Yuvarlanırken gıcırdar.
    if ((position.x - _prevX).abs() > 1.5) {
      GameAudio.instance.play('creak', volume: 0.12, minGapMs: 1400);
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    final c = Offset(position.x, position.y - radius);
    final r = p.toRect().deflate(3);
    final nx = c.dx.clamp(r.left, r.right);
    final ny = c.dy.clamp(r.top, r.bottom);
    if ((Offset(nx, ny) - c).distance < radius - 2) p.die();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, -radius);
    canvas.rotate(_spin);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = const Color(0xFF5A3A20),
    );
    final hoop = Paint()
      ..color = const Color(0xFF1A0E06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(Offset.zero, radius - 1, hoop);
    canvas.drawCircle(Offset.zero, radius * 0.55, hoop);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        Offset(math.cos(a), math.sin(a)) * radius * 0.55,
        Offset(math.cos(a), math.sin(a)) * (radius - 1),
        hoop..strokeWidth = 1.2,
      );
    }
    canvas.restore();
  }
}
