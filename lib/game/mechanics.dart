import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';

/// Üstüne basılabilen hareketli zeminlerin ortak tabanı. Yalnızca üstten
/// katıdır (tek yönlü platform gibi); üstünde duranı her karede kendi
/// hareketi kadar taşır.
abstract class Deck extends PositionComponent with HasGameReference<GolgeGame> {
  Deck({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: 14);

  /// Bu karede ne kadar yer değiştirdi (binenleri taşımak için).
  final delta = Vector2.zero();

  /// false iken içinden düşülür (ör. kopup düşen kaya).
  bool get active => true;

  void moveTo(Vector2 p) {
    delta.add(p - position);
    position.setFrom(p);
  }

  @override
  void update(double dt) {
    delta.setZero();
    super.update(dt);
    step(math.min(dt, 1 / 30));
  }

  void step(double dt);

  /// Taş levha: pürüzlü kenarlı, üstüne ışık vuran.
  void drawSlab(Canvas canvas, {double alpha = 1, double shakeX = 0}) {
    final theme = game.level.def.theme;
    final w = size.x;
    final h = size.y;
    final ink = Paint()..color = kInk.withValues(alpha: alpha);
    canvas.save();
    canvas.translate(shakeX, 0);
    final rock = Path()
      ..moveTo(0, 2)
      ..lineTo(w * 0.3, 0)
      ..lineTo(w * 0.7, 1)
      ..lineTo(w, 3)
      ..lineTo(w - 4, h)
      ..lineTo(w * 0.62, h + 6)
      ..lineTo(w * 0.35, h + 3)
      ..lineTo(5, h)
      ..close();
    canvas.drawPath(rock, ink);
    canvas.drawLine(
      const Offset(1, 1.5),
      Offset(w - 1, 2.5),
      Paint()
        ..color = const Color(0xFFD08A5A).withValues(alpha: 0.35 * alpha)
        ..strokeWidth = 1.2,
    );
    if (theme == LevelTheme.sky ||
        theme == LevelTheme.cliffs ||
        theme == LevelTheme.kaf) {
      final root = Paint()
        ..color = kInk.withValues(alpha: alpha)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < 3; i++) {
        final x = w * (0.25 + i * 0.25);
        canvas.drawPath(
          Path()
            ..moveTo(x, h)
            ..quadraticBezierTo(x + 3, h + 8, x - 1, h + 14 + i * 3),
          root,
        );
      }
    }
    canvas.restore();
  }
}

/// İki nokta arasında yumuşakça gidip gelen kaya.
class MovingRock extends Deck {
  MovingRock(Vector2 cell, {required bool vertical})
    : _origin = Vector2(cell.x, cell.y),
      _axis = vertical ? Vector2(0, -1) : Vector2(1, 0),
      super(position: Vector2(cell.x, cell.y), size: Vector2(kTile * 2, 14));

  static const double range = kTile * 4;
  static const double period = 5.5;
  final Vector2 _origin;
  final Vector2 _axis;
  double _t = 0;

  @override
  void step(double dt) {
    _t += dt;
    final k = 0.5 - 0.5 * math.cos(_t / period * 2 * math.pi);
    moveTo(_origin + _axis * (range * k));
  }

  @override
  void render(Canvas canvas) => drawSlab(canvas);
}

/// Üstüne basılınca titreyip kopan, bir süre sonra yerine geri gelen kaya.
class CrumbleRock extends Deck {
  CrumbleRock(Vector2 cell)
    : _origin = Vector2(cell.x, cell.y),
      super(position: Vector2(cell.x, cell.y), size: Vector2(kTile * 2, 14));

  final Vector2 _origin;
  double _shake = -1;
  double _fall = -1;
  double _vy = 0;
  double _back = 0;

  bool stoodOn = false;

  @override
  bool get active => _fall < 0.12 && _back <= 0;

  @override
  void step(double dt) {
    if (_back > 0) {
      _back -= dt;
      if (_back <= 0) {
        position.setFrom(_origin);
        _shake = -1;
        _fall = -1;
      }
      return;
    }
    if (_shake < 0 && _fall < 0 && stoodOn) {
      _shake = 0;
      GameAudio.instance.play('crumble', volume: 0.8);
    }
    stoodOn = false;
    if (_shake >= 0 && _fall < 0) {
      _shake += dt;
      if (_shake > 0.55) {
        _fall = 0;
        _vy = 0;
      }
    }
    if (_fall >= 0) {
      _fall += dt;
      _vy = math.min(_vy + 1600 * dt, 800);
      moveTo(position + Vector2(0, _vy * dt));
      if (_fall > 2) _back = 3.5;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_back > 0) return;
    final shakeX = _shake >= 0 && _fall < 0 ? math.sin(_shake * 70) * 1.5 : 0.0;
    drawSlab(canvas, alpha: (1 - (_fall - 1).clamp(0.0, 1.0)), shakeX: shakeX);
    if (_shake < 0 && _fall < 0) {
      // Çatlak: dikkatli bakan oyuncu kopacağını anlar.
      canvas.drawPath(
        Path()
          ..moveTo(size.x * 0.45, 0)
          ..lineTo(size.x * 0.52, 6)
          ..lineTo(size.x * 0.47, 11),
        Paint()
          ..color = const Color(0xFFD08A5A).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }
}

/// Karşı ağırlıklı asansörün bir kefesi.
class LiftPan extends Deck {
  LiftPan(Vector2 cell)
    : base = Vector2(cell.x, cell.y),
      super(position: Vector2(cell.x, cell.y), size: Vector2(kTile * 2, 10));

  final Vector2 base;

  /// Üstündeki ağırlık: oyuncu 1, her sandık 2.
  int get load {
    var w = game.player?.riding == this ? 1 : 0;
    for (final c in game.world.children.whereType<Crate>()) {
      if (c.riding == this) w += 2;
    }
    return w;
  }

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    final wood = Paint()..color = const Color(0xFF241510);
    // Kenarlı bir sepet: terazinin kefesi olduğu ilk bakışta anlaşılsın.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 7), wood);
    canvas.drawRect(Rect.fromLTWH(0, -6, 4, 8), wood);
    canvas.drawRect(Rect.fromLTWH(size.x - 4, -6, 4, 8), wood);
    canvas.drawPath(
      Path()
        ..moveTo(4, 7)
        ..lineTo(size.x - 4, 7)
        ..lineTo(size.x - 10, 13)
        ..lineTo(10, 13)
        ..close(),
      wood,
    );
    canvas.drawLine(
      const Offset(0, 0.8),
      Offset(size.x, 0.8),
      Paint()
        ..color = const Color(0xFFD08A5A).withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );
    // Halatlar: makaraya kadar.
    final rope = Paint()
      ..color = kInk
      ..strokeWidth = 1.3;
    final top = -(position.y - base.y) - BalanceLift.ropeTop;
    canvas.drawLine(const Offset(2, -6), Offset(size.x / 2, top), rope);
    canvas.drawLine(Offset(size.x - 2, -6), Offset(size.x / 2, top), rope);
  }
}

/// Ağırlığa göre çalışan karşı ağırlıklı asansör: ağır kefe iner, öteki
/// çıkar; ağırlıklar eşitse olduğu yerde kalır.
class BalanceLift extends Component with HasGameReference<GolgeGame> {
  // Kefelerden (14) sonra, sandık (17) ve oyuncudan (20) önce güncellenir:
  // böylece kefelerin bu karedeki hareketi binenlere aktarılır.
  BalanceLift(this.a, this.b) : super(priority: 15);

  static const double travel = kTile * 4;
  static const double speed = 42;
  static const double ropeTop = kTile * 4;

  final LiftPan a;
  final LiftPan b;
  double _offset = 0;

  @override
  void update(double dt) {
    dt = math.min(dt, 1 / 30);
    final diff = a.load - b.load;
    if (diff != 0) {
      final before = _offset;
      _offset = (_offset + diff.sign * speed * dt).clamp(-travel, travel);
      if (_offset != before) {
        GameAudio.instance.play('creak', volume: 0.5, minGapMs: 900);
      }
    }
    a.moveTo(a.base + Vector2(0, _offset));
    b.moveTo(b.base - Vector2(0, _offset));
  }

  @override
  void render(Canvas canvas) {
    // Makaralar ve iki kefeyi bağlayan halat.
    final pa = Offset(a.base.x + a.size.x / 2, a.base.y - ropeTop);
    final pb = Offset(b.base.x + b.size.x / 2, b.base.y - ropeTop);
    final ink = Paint()..color = kInk;
    canvas.drawLine(pa, pb, ink..strokeWidth = 1.6);
    // Makaralar kefeler hareket ettikçe döner: ağırlığın etkisi görünür.
    final spoke = Paint()
      ..color = const Color(0xFFD08A5A).withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (final (p, dir) in [(pa, 1.0), (pb, -1.0)]) {
      canvas.drawCircle(p, 9, ink);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(dir * _offset / 9);
      for (var k = 0; k < 4; k++) {
        canvas.rotate(math.pi / 4);
        canvas.drawLine(const Offset(-7, 0), const Offset(7, 0), spoke);
      }
      canvas.restore();
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = const Color(0xFFD08A5A).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }
}

/// Hezarfen'in kanatları: Kule'nin tepesinde bulunur, süzülmeyi açar.
class WingsPickup extends PositionComponent with HasGameReference<GolgeGame> {
  WingsPickup(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile - 6), priority: 18);

  double _t = 0;
  bool _taken = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_taken || p == null || p.isDead) return;
    if ((p.center - position).length < 28) {
      _taken = true;
      game.collectWings();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final glow = 0.6 + 0.4 * math.sin(_t * 2);
    canvas.drawCircle(
      const Offset(0, -10),
      30,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -10), 30, [
          kWarmLight.withValues(alpha: 0.35 * glow),
          kWarmLight.withValues(alpha: 0),
        ]),
    );
    final cloth = Paint()
      ..color = const Color(0xFFE8D9C0).withValues(alpha: 0.9);
    final frame = Paint()
      ..color = kInk
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final s in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(0, -8)
        ..quadraticBezierTo(s * 10, -26, s * 22, -20)
        ..lineTo(s * 18, -14)
        ..lineTo(s * 14, -9)
        ..lineTo(s * 8, -5)
        ..close();
      canvas.drawPath(wing, cloth);
      canvas.drawPath(wing, frame);
    }
    canvas.drawLine(const Offset(0, -10), const Offset(0, 0), frame);
  }
}
