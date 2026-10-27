import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'level.dart';
import 'mechanics.dart';
import 'player.dart';

// XVI · Erlik'in katı: Kıl Köprü. Altay anlatısında yeraltı ırmağının
// üstünde kıl kadar ince bir köprü vardır; ruhlar ondan geçer, ağır gelen
// ırmağa düşer. Köprü koşanın altında sallanır; salınım taşarsa köprü bir
// an silkinir, üstündeki düşer. Parmak ucunda yürüyen ya da arada durup
// köprünün durulmasını bekleyen geçer.

class HairBridge extends Deck {
  HairBridge(int c0, int c1, int row)
    : super(
        position: Vector2(c0 * kTile.toDouble(), row * kTile.toDouble()),
        size: Vector2((c1 - c0 + 1) * kTile.toDouble(), 6),
      );

  /// Salınım (0-1): 1'e varınca köprü silkinir.
  double sway = 0;
  double _t = 0;

  /// Silkinme süresi: bu sırada köprü kimseyi taşımaz.
  double _drop = 0;
  double _creakIn = 0;

  @override
  bool get active => _drop <= 0;

  @override
  void step(double dt) {
    _t += dt;
    _drop = math.max(0, _drop - dt);
    _creakIn -= dt;
    final p = game.player;
    final on = p != null && !p.isDead && identical(p.riding, this);
    if (on) {
      // Koşu salar; parmak ucu ve duruş dindirir.
      final k = p.velocity.x.abs() / Player.runSpeed;
      sway = math.max(0, sway + (k * k * 1.15 - 0.32) * dt);
      if (sway > 0.25) game.hint('hairBridge');
      if (sway > 0.55 && _creakIn <= 0) {
        _creakIn = 0.7;
        GameAudio.instance.play('creak', volume: 0.3 + sway * 0.4);
      }
      if (sway >= 1) {
        sway = 0;
        _drop = 0.9;
        GameAudio.instance.play('creak', volume: 0.8);
        game.shake(2);
      }
    } else {
      sway = math.max(0, sway - dt * 0.6);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    // Silkinen köprü bir an aşağı çırpılır, sonra yerine döner.
    final whip = _drop > 0 ? math.sin((0.9 - _drop) / 0.9 * math.pi) * 40 : 0;
    final shake = math.sin(_t * (6 + sway * 10)) * sway * 6;
    double sagAt(double x) {
      final u = x / w;
      final belly = math.sin(u * math.pi);
      return 2 + belly * (3 + sway * 10 + whip) + shake * belly;
    }

    final rope = Path()..moveTo(0, sagAt(0));
    for (var x = 8.0; x <= w; x += 8) {
      rope.lineTo(x, sagAt(x));
    }
    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFD9CBB0).withValues(alpha: 0.85);
    canvas.drawPath(rope, hair);
    canvas.drawPath(
      rope.shift(const Offset(0, 3)),
      hair
        ..strokeWidth = 1
        ..color = const Color(0xFFB8A88C).withValues(alpha: 0.6),
    );
    // Seyrek düğümler: kılın üstüne bağlanmış ince basamaklar.
    final knot = Paint()
      ..color = const Color(0xFFE8DCC0).withValues(alpha: 0.7);
    for (var x = 14.0; x < w; x += 28) {
      canvas.drawCircle(Offset(x, sagAt(x) + 1.5), 1.4, knot);
    }
    // Uçlarda kazıklar.
    final post = Paint()..color = const Color(0xFF1A0E0C);
    canvas.drawRect(const Rect.fromLTWH(-3, -14, 4, 20), post);
    canvas.drawRect(Rect.fromLTWH(w - 1, -14, 4, 20), post);
  }
}
