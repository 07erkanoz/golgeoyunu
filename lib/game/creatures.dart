import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'strings.dart';

// =============================================================== Yarasalar

/// Tavanda baş aşağı uyuyan yarasalar. Yakında koşan, gürültü yapan ya da
/// açık ışıkla yaklaşan çocuk onları ürkütür: çığlıkla uçuşurlar ve bu
/// gürültü Kandilcileri o yöne çeker.
class BatRoost extends PositionComponent with HasGameReference<GolgeGame> {
  BatRoost(Vector2 cell)
    : super(position: Vector2(cell.x + kTile / 2, cell.y + 2), priority: 23);

  final _rnd = math.Random();
  late final List<_Bat> _bats = List.generate(6, (i) {
    return _Bat(
      Offset((i - 2.5) * 6 + _rnd.nextDouble() * 3, _rnd.nextDouble() * 4),
      _rnd.nextDouble() * 6,
    );
  });
  bool flown = false;
  double _t = 0;

  void disturb() {
    if (flown) return;
    flown = true;
    GameAudio.instance.play('bats');
    for (final b in _bats) {
      final a = -math.pi / 2 + (_rnd.nextDouble() - 0.5) * 2.4;
      b.vel = Offset(math.cos(a), math.sin(a)) * (120 + _rnd.nextDouble() * 80);
    }
    game.makeNoise(position + Vector2(0, 20), 380, source: this);
  }

  void hear(Vector2 from, double radius) {
    final d = from - position;
    if (d.x.abs() < radius * 0.8 && d.y.abs() < 280) disturb();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!flown) {
      final p = game.player;
      if (p == null || p.isDead) return;
      final dx = (p.center.x - position.x).abs();
      final dy = (p.center.y - position.y).abs();
      if (dy > 260) return;
      final loud = p.onGround && p.velocity.x.abs() > 105 && !p.covering;
      if ((dx < 150 && loud) || (dx < 60 && !p.covering)) disturb();
      return;
    }
    for (final b in _bats) {
      b.pos += b.vel * dt;
      b.vel =
          b.vel.scale(1, 0.985) +
          Offset(math.sin(_t * 9 + b.phase) * 40 * dt, -10 * dt);
    }
    if (_t > 8) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF0C0706);
    for (final b in _bats) {
      if (!flown) {
        // Baş aşağı asılı, hafifçe sallanan damla gövdeler.
        final sway = math.sin(_t * 1.5 + b.phase) * 0.8;
        canvas.drawOval(
          Rect.fromCenter(
            center: b.pos.translate(sway, 6),
            width: 5,
            height: 9,
          ),
          ink,
        );
        canvas.drawLine(
          b.pos.translate(sway, 1.5),
          b.pos.translate(0, -1),
          ink..strokeWidth = 1,
        );
      } else {
        final flap = math.sin(_t * 30 + b.phase) * 4;
        final c = b.pos;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 7, c.dy - flap)
            ..quadraticBezierTo(c.dx - 3, c.dy + 1, c.dx, c.dy)
            ..quadraticBezierTo(c.dx + 3, c.dy + 1, c.dx + 7, c.dy - flap)
            ..lineTo(c.dx, c.dy + 2.5)
            ..close(),
          ink,
        );
      }
    }
  }
}

class _Bat {
  _Bat(this.pos, this.phase);
  Offset pos;
  final double phase;
  Offset vel = Offset.zero;
}

// ================================================================= Karga

/// Çatılarda ve kayalıklarda tüneyen karga: yanından koşan çocuğu görünce
/// bağırarak havalanır ve yakındaki bekçileri uyarır.
class Crow extends PositionComponent with HasGameReference<GolgeGame> {
  Crow(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile - 1),
        priority: 19,
      );

  bool _flying = false;
  double _t = math.Random().nextDouble() * 4;
  double _flyT = 0;
  int _look = -1;
  Offset _vel = Offset.zero;

  void scare(Vector2 from) {
    if (_flying) return;
    _flying = true;
    GameAudio.instance.play('crow');
    final dir = position.x >= from.x ? 1.0 : -1.0;
    _look = dir > 0 ? 1 : -1;
    _vel = Offset(dir * 110, -150);
    game.makeNoise(position.clone(), 260, source: this);
  }

  void hear(Vector2 from, double radius) {
    if ((from - position).length < radius * 0.6) scare(from);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_flying) {
      _flyT += dt;
      position += Vector2(_vel.dx, _vel.dy) * dt;
      _vel = _vel.translate(0, -20 * dt);
      if (_flyT > 4) removeFromParent();
      return;
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    _look = p.center.x >= position.x ? 1 : -1;
    final d = (p.center - position).length;
    final loud = p.velocity.x.abs() > 105 && !p.covering;
    if ((d < 140 && loud) || d < 45) scare(p.center);
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    canvas.save();
    if (_look < 0) canvas.scale(-1, 1);
    if (!_flying) {
      final peck = math.max(0.0, math.sin(_t * 1.1)) > 0.9 ? 2.0 : 0.0;
      canvas.drawOval(const Rect.fromLTWH(-6, -9, 12, 7), ink);
      canvas.drawCircle(Offset(5, -10 + peck), 2.8, ink);
      canvas.drawPath(
        Path()
          ..moveTo(7, -11 + peck)
          ..lineTo(11, -9.5 + peck)
          ..lineTo(7, -9 + peck)
          ..close(),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-5, -7)
          ..lineTo(-11, -4)
          ..lineTo(-5, -4)
          ..close(),
        ink,
      );
      canvas.drawLine(
        const Offset(-1, -2.5),
        const Offset(-1, 0),
        ink..strokeWidth = 1,
      );
      canvas.drawLine(const Offset(2, -2.5), const Offset(2, 0), ink);
      canvas.drawCircle(
        Offset(5.8, -10.8 + peck),
        0.6,
        Paint()..color = const Color(0xFFD08A5A),
      );
    } else {
      final flap = math.sin(_t * 22) * 7;
      canvas.drawOval(const Rect.fromLTWH(-6, -8, 12, 6), ink);
      canvas.drawCircle(const Offset(6, -6), 2.6, ink);
      canvas.drawPath(
        Path()
          ..moveTo(-3, -6)
          ..quadraticBezierTo(-6, -14 - flap, -12, -12 - flap)
          ..lineTo(3, -6)
          ..close(),
        ink,
      );
    }
    canvas.restore();
  }
}

// ================================================================== Gözcü

/// Yüksekte durup projektör ışığıyla aşağıyı tarayan Gözcü. Yürümez; ama
/// ışığında uzun kalan çocuğu yakalatır. Ateşböceği salınırsa ışığını ona
/// kilitler.
class Watcher extends PositionComponent with HasGameReference<GolgeGame> {
  Watcher(Vector2 cell)
    : super(
        position: Level.standOn(cell, 22, 52),
        size: Vector2(22, 52),
        priority: 15,
      );

  static const double beamLength = 360;
  static const double beamHalf = 0.17;

  int facing = 1;
  double suspicion = 0;
  double _t = 0;
  double _angle = 0.6;

  Vector2 get lamp =>
      Vector2(position.x + size.x / 2 + facing * 10, position.y + 14);

  bool get alarmed => suspicion >= 1;

  @override
  void onMount() {
    super.onMount();
    // Bölümün ortasına bakar.
    facing = position.x < game.level.pixelWidth / 2 ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;

    // Ateşböceği varsa ışığını ona kilitler.
    FireflyLure? lure;
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position - lamp).length < beamLength) lure = l;
    }
    if (lure != null) {
      final d = lure.position - lamp;
      final target = math.atan2(d.y, d.x * facing);
      _angle += (target - _angle) * math.min(1, dt * 4);
    } else {
      _angle = 0.6 + 0.55 * math.sin(_t * 0.7);
    }

    if (p == null || p.isDead || game.cinematic) {
      suspicion = math.max(0, suspicion - dt);
      return;
    }
    final sees = lure == null && _inBeam(p.center) && !p.hidden;
    if (sees && suspicion == 0) {
      GameAudio.instance.play('suspect', volume: 0.7, minGapMs: 1500);
    }
    suspicion = sees
        ? math.min(1, suspicion + dt * 1.6)
        : math.max(0, suspicion - dt * 0.6);
    if (suspicion >= 1) {
      p.die();
      suspicion = 0;
    }
  }

  bool _inBeam(Vector2 target) {
    final d = target - lamp;
    final dist = d.length;
    if (dist > beamLength || d.x * facing < 0) return false;
    final a = math.atan2(d.y, d.x * facing);
    if ((a - _angle).abs() > beamHalf + 8 / math.max(dist, 1)) return false;
    // Işık Gözcü'nün durduğu taşın kenarından başlar.
    final start = lamp + d.normalized() * math.min(12, dist);
    return game.level.lineOfSight(start, target);
  }

  /// Aydınlatma katmanı ve çizim için ışık üçgeni (dünya koordinatlarında).
  Path beamPath() {
    final o = lamp;
    final a1 = _angle - beamHalf;
    final a2 = _angle + beamHalf;
    return Path()
      ..moveTo(o.x, o.y)
      ..lineTo(
        o.x + facing * math.cos(a1) * beamLength,
        o.y + math.sin(a1) * beamLength,
      )
      ..lineTo(
        o.x + facing * math.cos(a2) * beamLength,
        o.y + math.sin(a2) * beamLength,
      )
      ..close();
  }

  @override
  void render(Canvas canvas) {
    // Işık hüzmesi (yerel koordinatlara çevrilerek).
    canvas.save();
    canvas.translate(-position.x, -position.y);
    final o = lamp;
    final far = Offset(
      o.x + facing * math.cos(_angle) * beamLength,
      o.y + math.sin(_angle) * beamLength,
    );
    canvas.drawPath(
      beamPath(),
      Paint()
        ..shader = ui.Gradient.linear(o.toOffset(), far, [
          kCold.withValues(alpha: 0.28 + 0.3 * suspicion),
          kCold.withValues(alpha: 0),
        ]),
    );
    canvas.restore();

    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    final ink = Paint()..color = kInk;
    // Uzun cüppe, geniş omuzlar, sivri miğfer.
    canvas.drawPath(
      Path()
        ..moveTo(3, 52)
        ..lineTo(5, 20)
        ..quadraticBezierTo(11, 14, 18, 20)
        ..lineTo(20, 52)
        ..close(),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 16)
        ..lineTo(11, -2)
        ..lineTo(16, 16)
        ..close(),
      ink,
    );
    canvas.drawCircle(const Offset(11, 12), 5.5, ink);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(13.5, 12), width: 3, height: 1.2),
      Paint()..color = kCold.withValues(alpha: 0.6 + 0.4 * suspicion),
    );
    // Projektör: omuzda büyük bir fener.
    canvas.drawRect(const Rect.fromLTWH(14, 10, 10, 8), ink);
    canvas.drawRect(
      const Rect.fromLTWH(22, 11, 3, 6),
      Paint()..color = kCold.withValues(alpha: 0.95),
    );
    canvas.restore();
    if (suspicion > 0.05) {
      final a = Paint()..color = kCold.withValues(alpha: 0.4 + 0.6 * suspicion);
      canvas.drawRect(Rect.fromLTWH(size.x / 2 - 1.5, -22, 3, 10), a);
      canvas.drawCircle(Offset(size.x / 2, -7), 1.8, a);
    }
  }
}

// =============================================================== Karabasan

/// Sarnıç kanallarının karanlığından çıkan dev gölge. Çocuk başlangıç
/// çizgisini geçince arkasından gelir; yakalarsa ölüm. Ateşböceği ışığı onu
/// bir anlığına geri iter. Bitiş çizgisinde dağılır.
class Karabasan extends PositionComponent with HasGameReference<GolgeGame> {
  Karabasan(this.startX, this.endX) : super(priority: 24);

  final double startX;
  final double endX;
  bool _awake = false;
  bool _gone = false;
  double _speed = 0;
  double _recoil = 0;
  double _t = 0;
  double _fade = 0;

  bool get awake => _awake && !_gone;

  @override
  void update(double dt) {
    super.update(dt);
    dt = math.min(dt, 1 / 30);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_gone) {
      _fade = math.max(0, _fade - dt * 0.8);
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      if (p.center.x > startX && !p.isDead) {
        _awake = true;
        position.setValues(p.center.x - 360, p.center.y);
        _speed = 60;
        game.narration.whisper(S.of('chase'));
        GameAudio.instance.play('alert');
      }
      return;
    }
    _fade = math.min(1, _fade + dt * 1.5);
    if (p.center.x > endX) {
      _gone = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;

    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position.x - position.x).abs() < 170) _recoil = 1.3;
    }
    if (_recoil > 0) {
      _recoil -= dt;
      _speed = -50;
    } else {
      _speed = math.min(128, _speed + dt * 90);
    }
    position.x += _speed * dt;
    // Oyuncunun çok gerisinde kalmasın: gerilim sürsün.
    position.x = math.max(position.x, p.center.x - 420);
    position.y += (p.center.y - position.y) * math.min(1, dt * 1.5);

    final gap = p.center.x - position.x;
    game.shake(((260 - gap) / 260).clamp(0.0, 1.0) * 5);
    GameAudio.instance.dread(((520 - gap) / 420).clamp(0.15, 1.0));
    if (gap < 46 && (p.center.y - position.y).abs() < 90) p.die();
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final a = _fade;
    final ink = Paint()
      ..color = const Color(0xFF020101).withValues(alpha: 0.96 * a);
    // Kaynayan gövde: üst üste binen, nefes alan gölgeler.
    for (var i = 0; i < 14; i++) {
      final ang = i / 14 * math.pi * 2;
      final r = 70 + 18 * math.sin(_t * 3 + i * 1.7);
      canvas.drawCircle(
        Offset(math.cos(ang) * r * 0.55 - 40, math.sin(ang) * r * 0.75),
        48 + 10 * math.sin(_t * 2.3 + i),
        ink,
      );
    }
    // Öne uzanan pençe gibi dokunaçlar.
    final arm = Paint()
      ..color = const Color(0xFF020101).withValues(alpha: 0.96 * a)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final y0 = -60.0 + i * 24;
      final reach = 60 + 25 * math.sin(_t * 4 + i * 1.3);
      arm.strokeWidth = 7 - i % 3 * 1.5;
      canvas.drawPath(
        Path()
          ..moveTo(10, y0 * 0.6)
          ..quadraticBezierTo(
            reach * 0.6,
            y0 * 0.6 + 18 * math.sin(_t * 5 + i),
            reach,
            y0 + 10 * math.cos(_t * 3 + i),
          ),
        arm,
      );
    }
    // Soluk, bakan iki göz.
    final eye = Paint()
      ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.8 * a);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-6, -18), width: 9, height: 4),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(10, -16), width: 8, height: 3.5),
      eye,
    );
  }
}
