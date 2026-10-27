import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'level.dart';
import 'puzzles.dart';

// XIII · Derinkuyu: yeraltı şehrinin yuvarlak taş kapıları. Değirmen taşı
// gibi iri, ortası delik taşlar; yalnızca içeriden, duvardaki yuvasına
// yuvarlanarak açılır ve kapanır. Dışarıdaki bekler, içerideki yaşar.

/// Yuvarlak taş kapı: üç kare yüksek bir geçidi kapatır. İçeriden ([inside]
/// yönündeki yandan) ↑ ile yuvasına yuvarlanır, yine ↑ ile kapanır;
/// dışarıdan kıpırdamaz. Kapalıyken Sâye'yi de Kandilci'yi de geçirmez:
/// içerideki, dışarıdakini kapının ardında bırakabilir.
class RollingDoor extends Gate with Usable {
  RollingDoor(this.col, int row, {required this.inside})
    : super(col, row - 2, row);

  final int col;

  /// İçerinin yönü: 1 sağ, -1 sol.
  final int inside;

  /// İstenen durum (açık mı) ve yuvarlanma (0 kapalı, 1 yuvasında).
  bool want = false;
  double roll = 0;
  double _nudge = 0;

  static const double radius = 46;

  /// Yuvası: kapının iç yanında, bu kadar uzakta.
  static const double travel = 2.3 * kTile;

  double get _cx => col * kTile + kTile / 2;
  double get _bottom => position.y + size.y;

  @override
  bool get solid => roll < 0.55;

  @override
  String get persistKind => 'rollingDoor';

  @override
  Object? captureState() => want ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      want = true;
      roll = 1;
    }
    return [this];
  }

  @override
  Rect toRect() => Rect.fromLTWH(
    col * kTile.toDouble(),
    position.y,
    kTile.toDouble(),
    size.y,
  );

  /// Nokta kapının iç yanında mı.
  bool isInside(Vector2 p) => (p.x - _cx) * inside > 0;

  @override
  bool canUse(Vector2 p) =>
      (p.x - _cx).abs() < 2.4 * kTile && (p.y - (_bottom - 16)).abs() < 34;

  @override
  void use() {
    final p = game.player;
    if (p == null) return;
    if (!isInside(p.center)) {
      // Dışarıdan itilen taş kıpırdar ama yerinden oynamaz.
      _nudge = 0.5;
      GameAudio.instance.play('creak', volume: 0.5, minGapMs: 400);
      game.hint('rollingDoorOutside');
      return;
    }
    want = !want;
    GameAudio.instance.play('grind', volume: 0.6);
    game.shake(1.5);
  }

  /// Kapanırken geçitte biri varsa taş ona çarpmadan durur.
  bool _blocked() {
    final r = toRect();
    final p = game.player;
    if (p != null && !p.isDead && p.toRect().overlaps(r)) return true;
    return game.world.children.whereType<Guard>().any(
      (g) => g.toRect().overlaps(r),
    );
  }

  @override
  void update(double dt) {
    _nudge = math.max(0, _nudge - dt);
    final target = want ? 1.0 : 0.0;
    var next = roll + (target - roll).clamp(-dt * 0.85, dt * 0.85);
    if (next < roll && next < 0.6 && _blocked()) next = math.max(roll, 0.6);
    roll = next;
  }

  @override
  void render(Canvas canvas) {
    // Yerel çizim: konum kapı sütununun 8 piksel sağında başlar.
    final base = Offset(_cx - position.x, size.y - radius);
    final open = base.translate(inside * travel, 0);
    // Duvardaki yuva: taş açılınca buraya oturur.
    canvas.drawCircle(
      open,
      radius + 4,
      Paint()..color = const Color(0xFF0A0706).withValues(alpha: 0.75),
    );
    final wobble = _nudge > 0 ? math.sin(_nudge * 60) * 1.5 : 0.0;
    final c = Offset.lerp(base, open, roll)!.translate(wobble, 0);
    final angle = inside * roll * travel / radius;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final disc = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          radius,
          const [Color(0xFF6E5C4A), Color(0xFF3A2E24), Color(0xFF1E1712)],
          const [0, 0.75, 1],
        ),
    );
    canvas.drawCircle(
      Offset.zero,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF120D0A),
    );
    // Yontu izleri: merkezden kenara oyuklar (döndükçe görünür).
    final chisel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF241B14).withValues(alpha: 0.8);
    for (var i = 0; i < 9; i++) {
      final a = i * math.pi * 2 / 9;
      canvas.drawLine(
        Offset(math.cos(a) * 14, math.sin(a) * 14),
        Offset(
          math.cos(a + 0.12) * (radius - 6),
          math.sin(a + 0.12) * (radius - 6),
        ),
        chisel,
      );
    }
    canvas.drawArc(
      disc.deflate(6),
      -2.4,
      1.3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFB08A62).withValues(alpha: 0.35),
    );
    // Ortadaki delik: içeriden sırıkla çevrilir.
    canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFF070504));
    canvas.restore();
  }
}
