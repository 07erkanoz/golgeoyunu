import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'player.dart';

// XII · Peri Bacaları: Kızıl Vadi. Anadolu inancında Albastı (Al karısı)
// kızıl saçlı bir gölgedir; ışığa gelir, demirden korkar. Vadide süzülür,
// açık kavanozun ışığına yönelir; bacalara çakılı demir nalların çevresine
// giremez. Sâye naldan nala geçer; Albastı yaklaşınca çömelip ışığını örter.

/// Bir peri bacasının dibine çakılı demir nal: çevresine Albastı giremez.
class IronCharm extends PositionComponent with HasGameReference<GolgeGame> {
  IronCharm(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile - 6), priority: 15);

  static const double guard = 2.6 * kTile;
  double _t = 0;

  /// Albastı yaklaşınca nal parlar.
  double flare = 0;

  bool covers(Vector2 p) => (p - position).length < guard;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    flare = math.max(0, flare - dt * 1.5);
  }

  @override
  void render(Canvas canvas) {
    // Nal: ucu aşağı bakan U, çivi delikleri.
    final glow = 0.25 + 0.75 * flare;
    canvas.drawCircle(
      const Offset(0, -6),
      14 + flare * 10,
      Paint()
        ..color = const Color(0xFF9FB6C8).withValues(alpha: 0.12 * glow + 0.05),
    );
    final shoe = Path()
      ..moveTo(-7, 0)
      ..lineTo(-7, -8)
      ..arcToPoint(const Offset(7, -8), radius: const Radius.circular(7))
      ..lineTo(7, 0);
    canvas.drawPath(
      shoe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(
          const Color(0xFF5A646C),
          const Color(0xFFDDE8F0),
          glow,
        )!,
    );
    final nail = Paint()..color = const Color(0xFF1A1E22);
    for (final o in const [
      Offset(-7, -3),
      Offset(7, -3),
      Offset(-5, -11),
      Offset(5, -11),
    ]) {
      canvas.drawCircle(o, 0.9, nail);
    }
    // Ara ara pırıltı.
    if (math.sin(_t * 2.1 + position.x) > 0.96) {
      canvas.drawCircle(
        const Offset(-3, -13),
        1.6,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
  }
}

/// Albastı: kızıl saçlı gölge. Açık ışığa süzülür; demirin çevresine
/// giremez; dokunduğunu karanlıkta bırakır (Sâye ölür).
class AlbastiHunter extends PositionComponent with HasGameReference<GolgeGame> {
  AlbastiHunter(Vector2 cell)
    : _home = cell + Vector2(kTile / 2, kTile / 2),
      super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 22);

  final Vector2 _home;
  final _vel = Vector2.zero();
  double _t = 0;

  /// Işığa yönelmiş mi (çizimde saçlar dalgalanır, ses).
  bool hunting = false;

  static const double speed = 78;
  static const double sight = 10 * kTile;

  Iterable<IronCharm> get _irons => game.world.children.whereType<IronCharm>();

  bool _shielded(Vector2 at) => _irons.any((i) => i.covers(at));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    Vector2 target = _home;
    final wasHunting = hunting;
    hunting = false;
    if (p != null && !p.isDead) {
      final lit = !p.hidden && !p.crouching;
      final d = p.center - position;
      if (lit && d.length < sight && !_shielded(p.center)) {
        target = p.center;
        hunting = true;
      }
    }
    if (hunting && !wasHunting) {
      GameAudio.instance.play('murmur', volume: 0.5, minGapMs: 2500);
      game.hint('albasti');
    }
    final want = target - position;
    final dist = want.length;
    final v = hunting ? speed : speed * 0.5;
    final desired = dist > 1
        ? want / dist * math.min(v, dist / dt)
        : Vector2.zero();
    _vel.setFrom(_vel + (desired - _vel) * math.min(1, dt * 3));
    // Hafif süzülüş.
    _vel.y += math.sin(_t * 2.3) * 6 * dt;
    final next = position + _vel * dt;
    // Demirin çevresine giremez: sınırda durur, nal parlar.
    for (final iron in _irons) {
      if (iron.covers(next)) {
        iron.flare = 1;
        final away = next - iron.position;
        final push = away.length < 1 ? Vector2(0, -1) : away.normalized();
        next.setFrom(iron.position + push * (IronCharm.guard + 1));
        _vel.scale(0.3);
      }
    }
    position.setFrom(next);
    if (p != null && !p.isDead && (p.center - position).length < 18) {
      p.die(cause: DeathCause.dark);
      GameAudio.instance.play('fizzle', volume: 0.6);
    }
  }

  @override
  void render(Canvas canvas) {
    final flick = 0.75 + 0.25 * math.sin(_t * 9);
    // Kızıl hale.
    canvas.drawCircle(
      Offset.zero,
      26,
      Paint()..color = const Color(0xFF7A1410).withValues(alpha: 0.18 * flick),
    );
    // Gövde: aşağı doğru incelen, ucu kopuk gölge.
    final body = Path()
      ..moveTo(-9, -10)
      ..quadraticBezierTo(-12, 8, -4 + math.sin(_t * 3) * 3, 22)
      ..quadraticBezierTo(2, 14, 6, 22 + math.sin(_t * 4) * 2)
      ..quadraticBezierTo(12, 6, 9, -10)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = const Color(0xFF14070A).withValues(alpha: 0.9),
    );
    // Baş.
    canvas.drawCircle(
      const Offset(0, -14),
      7,
      Paint()..color = const Color(0xFF14070A),
    );
    // Uzun kızıl saçlar: geriye savrulur.
    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB0281C).withValues(alpha: 0.9);
    final back = _vel.x >= 0 ? -1.0 : 1.0;
    final wave = hunting ? 1.0 : 0.5;
    for (var i = 0; i < 6; i++) {
      final len = 22.0 + i * 4;
      final hp = Path()..moveTo(-4 + i * 1.6, -18);
      hp.quadraticBezierTo(
        back * len * 0.5,
        -18 + math.sin(_t * 5 + i) * 6 * wave,
        back * len,
        -10 + i * 3 + math.sin(_t * 4 + i * 0.7) * 5 * wave,
      );
      canvas.drawPath(hp, hair);
    }
    // Gözler: iki kor.
    final eye = Paint()
      ..color = const Color(0xFFFF7A3A).withValues(alpha: flick);
    canvas.drawCircle(const Offset(-2.5, -14.5), 1.4, eye);
    canvas.drawCircle(const Offset(2.5, -14.5), 1.4, eye);
  }
}
