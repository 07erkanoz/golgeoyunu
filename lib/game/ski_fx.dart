import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'player.dart';

/// Kayak yamacının canlılığı: kayakların arkasından savrulan kar tozu,
/// inişte kalkan kar bulutu, takla adları ve kombo, takladan sonra kısa bir
/// "kut" hızı (arkada altın kıvılcımlar).
class SkiFx extends Component with HasGameReference<GolgeGame> {
  SkiFx() : super(priority: 19);

  final _rnd = math.Random(7);

  /// Kar tozu taneleri: konum, hız, ömür, boy.
  final _grains = <_Grain>[];

  /// Ekranda süzülen takla yazıları.
  final _popups = <_Popup>[];

  bool _wasAir = false;

  /// Kombo: art arda yapılan numaralar (iniş arası 2,5 sn'den kısa).
  int combo = 0;
  double _comboT = 0;

  /// Takladan sonraki hız (sn).
  double kut = 0;

  /// Sâye bir numara yaptı: yazı, ses, hız.
  void trick(String name, {int weight = 1, bool flip = false}) {
    final p = game.player;
    if (p == null) return;
    combo = _comboT > 0 ? combo + weight : weight;
    _comboT = 2.5;
    final label = combo > 1 ? '$name  ×$combo' : name;
    _popups.add(_Popup(label, p.center.x, p.position.y - 18));
    // Yalnız takla kut hızı verir (takla uçurumları bununla aşılır).
    if (flip) {
      // Bir takla, rampadan takla uçurumunun kenarına dek yeter.
      kut = math.min(5, kut + 2.6 * weight);
      p.skiKick(40.0 * weight);
    }
    GameAudio.instance.play('firefly', volume: 0.5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _comboT = math.max(0, _comboT - dt);
    if (_comboT <= 0) combo = 0;
    kut = math.max(0, kut - dt);
    final p = game.player;
    final s = game.skiSurface;
    if (p != null && s != null && !p.isDead) {
      final feet = Offset(p.center.x, p.position.y + Player.h);
      final speed = p.skiSpeed;
      if (p.onGround && speed > 120) {
        // Kayakların arkasından toz: hızla artar.
        final n = (speed / 160).floor() + (_rnd.nextDouble() < 0.5 ? 1 : 0);
        for (var i = 0; i < n; i++) {
          _grains.add(
            _Grain(
              feet.translate(-6 - _rnd.nextDouble() * 6, -1),
              Offset(
                -speed * (0.15 + _rnd.nextDouble() * 0.25),
                -60 - _rnd.nextDouble() * speed * 0.35,
              ),
              0.5 + _rnd.nextDouble() * 0.5,
              1.2 + _rnd.nextDouble() * 2.2,
            ),
          );
        }
      }
      if (_wasAir && p.onGround) {
        // İnişte kar bulutu.
        for (var i = 0; i < 26; i++) {
          final a = math.pi + _rnd.nextDouble() * math.pi;
          final v = 60 + _rnd.nextDouble() * 160;
          _grains.add(
            _Grain(
              feet,
              Offset(math.cos(a) * v, math.sin(a) * v * 0.7),
              0.6 + _rnd.nextDouble() * 0.6,
              1.6 + _rnd.nextDouble() * 2.8,
            ),
          );
        }
      }
      _wasAir = !p.onGround;
      if (kut > 0 && _rnd.nextDouble() < 0.8) {
        _grains.add(
          _Grain(
            feet.translate(-4, -8 - _rnd.nextDouble() * 14),
            Offset(-40 - _rnd.nextDouble() * 60, -20 + _rnd.nextDouble() * 40),
            0.6,
            1.4,
            gold: true,
          ),
        );
      }
    }
    for (var i = _grains.length - 1; i >= 0; i--) {
      final g = _grains[i];
      g.age += dt;
      if (g.age > g.life) {
        _grains.removeAt(i);
        continue;
      }
      g.vel = Offset(g.vel.dx * (1 - dt * 1.6), g.vel.dy + 260 * dt);
      g.pos += g.vel * dt;
    }
    if (_grains.length > 500) _grains.removeRange(0, _grains.length - 500);
    for (var i = _popups.length - 1; i >= 0; i--) {
      final q = _popups[i];
      q.age += dt;
      q.y -= 28 * dt;
      if (q.age > 1.6) _popups.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas) {
    final lt = game.skiSurface == null ? null : game.skiLight;
    final snow = lt?.snowLit ?? const Color(0xFFF2F6FA);
    final paint = Paint();
    for (final g in _grains) {
      final k = 1 - g.age / g.life;
      paint.color = g.gold
          ? const Color(0xFFFFD890).withValues(alpha: 0.9 * k)
          : snow.withValues(alpha: 0.75 * k);
      canvas.drawCircle(g.pos, g.size * (0.6 + 0.4 * k), paint);
    }
    for (final q in _popups) {
      final a = q.age < 0.15
          ? q.age / 0.15
          : (1 - (q.age - 0.9) / 0.7).clamp(0.0, 1.0);
      final pb =
          ParagraphBuilder(
              ParagraphStyle(textAlign: TextAlign.center, fontSize: 15),
            )
            ..pushStyle(
              TextStyle(
                color: const Color(0xFFFFF0D0).withValues(alpha: a),
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.5 * a),
                    blurRadius: 4,
                  ),
                ],
              ),
            )
            ..addText(q.text);
      final para = pb.build()..layout(const ParagraphConstraints(width: 220));
      canvas.drawParagraph(para, Offset(q.x - 110, q.y - 20));
    }
  }
}

class _Grain {
  _Grain(this.pos, this.vel, this.life, this.size, {this.gold = false});

  Offset pos;
  Offset vel;
  final double life;
  final double size;
  final bool gold;
  double age = 0;
}

class _Popup {
  _Popup(this.text, this.x, this.y);

  final String text;
  final double x;
  double y;
  double age = 0;
}
