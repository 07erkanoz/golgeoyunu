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
        _pounceCd = math.max(0, _pounceCd - dt);
        if (_fear > 0) {
          _fear -= dt;
          _crouch = 0;
          vx = -d.x.sign * runSpeed * 0.8;
        } else if (_crouch > 0) {
          // Atılmadan önce bir an çöker, hırlar: oyuncuya kaçacak an kalır.
          _crouch -= dt;
          facing = d.x >= 0 ? 1 : -1;
          if (_crouch <= 0) _lunge = 0.45;
        } else if (_lunge > 0) {
          _lunge -= dt;
          vx = facing * runSpeed * 1.35;
        } else if (_pounceCd <= 0 &&
            d.x.abs() < 3.5 * kTile &&
            d.x.abs() > 20 &&
            d.y.abs() < kTile) {
          _crouch = 0.32;
          _pounceCd = 2.4;
          GameAudio.instance.play('growl', volume: 0.6, minGapMs: 1500);
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
    _crouchS += ((_crouch > 0 ? 1.0 : 0.0) - _crouchS) * math.min(1, dt * 14);
    if (dt > 0) {
      final pace = (_gait - _lastGait) / dt;
      _pace += (pace - _pace) * math.min(1, dt * 10);
    }
    _lastGait = _gait;
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
    // Kapalı kapı geçilmez.
    final ahead = Rect.fromLTWH(
      dx > 0 ? position.x + size.x : position.x + dx,
      top,
      dx.abs(),
      size.y - 4,
    );
    if (game.closedGateAt(ahead)) return;
    position.x += dx;
    _gait += dx.abs();
  }

  /// Saldırı: kısa bir çöküş, ardından atılış; arada bekleme.
  double _crouch = 0;
  double _lunge = 0;
  double _pounceCd = 0;
  double _crouchS = 0;

  /// Gerçekten yürünen yol: bacaklar buna göre döner (duvara dayanmış kurt
  /// yerinde koşmaz).
  double _gait = 0;
  double _lastGait = 0;
  double _pace = 0;

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
    // Adımlar katedilen yola bağlı: dörtnala geniş, dolaşırken kısa.
    final run = (_pace / runSpeed).clamp(0.0, 1.0);
    final moving = _pace > 6;
    final amp = moving ? 0.4 + 0.35 * run : 0.06;
    final ph = _gait / (6 + 3.4 * run) + (moving ? 0 : _t * 1.5);
    final bob = math.sin(ph * 2) * 0.8 * run;
    // Çökerken gövde alçalır, baş öne iner.
    canvas.translate(0, bob + _crouchS * 3.5);

    // Bacaklar: arkadaki çift biraz daha koyu, gövdenin ardında kalır.
    final far = Paint()
      ..color = Color.lerp(kInk, const Color(0xFF3A3A44), 0.25)!;
    _leg(canvas, const Offset(7, 11), ph + math.pi, amp, true, far);
    _leg(canvas, const Offset(19, 11.5), ph + math.pi * 0.6, amp, false, far);

    // Gövde: geride sırt, omuzda kabarık yele, derin göğüs, içe çekik karın.
    canvas.drawPath(
      Path()
        ..moveTo(3, 8)
        ..quadraticBezierTo(8, 4.6, 14, 5.6)
        ..lineTo(15.2, 3.6)
        ..lineTo(16.4, 5.0)
        ..lineTo(17.6, 3.0)
        ..lineTo(18.8, 4.8)
        ..lineTo(20.2, 3.4)
        ..quadraticBezierTo(22, 3.6, 23.2, 3.4)
        // Baş: alın, uzun burun, çene.
        ..quadraticBezierTo(25.5, 2.8, 27, 5.0)
        ..lineTo(31, 6.6)
        ..quadraticBezierTo(31.6, 7.6, 30.6, 8.2)
        ..lineTo(27.4, 9.4)
        ..quadraticBezierTo(25.6, 10.8, 23.2, 10.4)
        // Boyun altı ve göğüs.
        ..quadraticBezierTo(21.2, 13.6, 18.4, 14.0)
        ..quadraticBezierTo(14, 13.4, 11.4, 11.6)
        ..quadraticBezierTo(7.4, 12.6, 4.4, 12.2)
        ..quadraticBezierTo(1.8, 10.8, 3, 8)
        ..close(),
      ink,
    );
    // Kulaklar: biri öne, biri geriye dikilir.
    canvas.drawPath(
      Path()
        ..moveTo(23.0, 4.0)
        ..lineTo(23.6, -0.8)
        ..lineTo(25.4, 3.4)
        ..close()
        ..moveTo(21.4, 4.2)
        ..lineTo(21.2, 0.2)
        ..lineTo(23.2, 3.6)
        ..close(),
      ink,
    );
    // Kabarık kuyruk: avdayken arkaya uzanır, beklerken sarkar.
    final lift = hunting ? 1.0 : 0.0;
    final wag = math.sin(_t * (hunting ? 9 : 2)) * (hunting ? 1.2 : 0.6);
    canvas.drawPath(
      Path()
        ..moveTo(4, 7.4)
        ..quadraticBezierTo(-2, 8 - lift * 4 + wag, -6.5, 14 - lift * 9 + wag)
        ..quadraticBezierTo(-4.2, 15.5 - lift * 9, -1.6, 13.6 - lift * 5)
        ..quadraticBezierTo(1.2, 12, 4.6, 10.6)
        ..close(),
      ink,
    );
    // Yakın bacaklar.
    _leg(canvas, const Offset(6, 11), ph, amp, true, ink);
    _leg(canvas, const Offset(20, 12), ph + math.pi * 1.6, amp, false, ink);

    // Göz: soluk sarı; avdayken alev alır.
    canvas.drawCircle(
      const Offset(26.4, 6.0),
      1.15,
      Paint()
        ..color = const Color(0xFFFFE08A).withValues(alpha: hunting ? 1 : 0.45),
    );
    // Soğukta nefesi buhar olur.
    final breath = Paint();
    final rate = hunting ? 2.2 : 0.8;
    for (var i = 0; i < 3; i++) {
      final k = (_t * rate + i / 3) % 1.0;
      breath.color = const Color(0xFFE8EEF8)
          .withValues(alpha: 0.28 * (1 - k) * (k < 0.08 ? k / 0.08 : 1));
      canvas.drawCircle(
        Offset(32 + k * 8, 8 - k * 4 + math.sin(_t * 3 + i)),
        1.2 + k * 2.6,
        breath,
      );
    }
    canvas.restore();
    if (hunting) {
      glowDot(
        canvas,
        Offset(facing > 0 ? 26.4 : size.x - 26.4, 6 + bob),
        9,
        const Color(0xFFFFE08A),
        0.25,
      );
    }
  }

  /// İki eklemli bacak: arka bacakta diz geriye, ön bacakta bilek öne kırılır.
  void _leg(
    Canvas canvas,
    Offset root,
    double phase,
    double amp,
    bool hind,
    Paint paint,
  ) {
    final swing = math.sin(phase) * amp;
    // İleri giden ayak yerden kalkar.
    final raise = math.max(0.0, math.cos(phase)) * amp * 2.4;
    final upper = hind ? 5.2 : 4.6;
    final lower = hind ? 4.6 : 4.4;
    final knee =
        root +
        Offset(
          math.sin(swing + (hind ? 0.35 : -0.05)) * upper,
          math.cos(swing) * upper - raise * 0.4,
        );
    final bend = hind ? -0.55 : 0.25;
    final foot = Offset(
      knee.dx + math.sin(swing * 0.6 + bend) * lower,
      math.min(20.0, knee.dy + math.cos(swing * 0.6 + bend) * lower) -
          raise * 0.6,
    );
    final stroke = Paint()
      ..color = paint.color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = hind ? 3.0 : 2.4;
    canvas.drawLine(root, knee, stroke);
    stroke.strokeWidth = 1.7;
    canvas.drawLine(knee, foot, stroke);
    // Pençe.
    canvas.drawLine(foot, foot.translate(1.8, 0), stroke);
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
