import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'puzzles.dart' show Usable;
import 'rig.dart' show approach;

// ===================================================== Gölgeyi göndermek
//
// Hayal perdesinde gölge tasvirden ayrılabilir. Gölge taşının üstünde ↑ ile
// Sâye gölgesini önden gönderir: gölge baktığı yöne yürür (parmaklıktan
// geçer; duvarda, uçurumda, suda durur), bir süre orada oyalanır, sonra
// döner. Kandilci gölgeyi fenerinin baktığı yerde görürse ona yürür ve
// gölge orada kaldıkça çocuğu görmez. Gölge gidince Sâye'nin gölgesi yoktur.
// Gölgenin kendisi Sâye'nin duvardaki gölgesiyle aynı çizilir (player.dart).

/// Gönderilen gölgenin Kandilci için görünen yeri (gölgenin göğsü).
class ShadowDecoy extends PositionComponent
    with HasGameReference<GolgeGame>, Lure {
  ShadowDecoy() : super(priority: 22);

  @override
  bool get glowing {
    final p = game.player;
    return p != null && p.shadowLures;
  }

  /// Kandilci gördü: gölge biraz daha oyalanır, kamera ikisini gösterir.
  void noticed(Guard g) {
    final p = game.player;
    if (p == null) return;
    p.shadowNoticed();
    GameAudio.instance.play('suspect', volume: 0.45, minGapMs: 800);
    game.focus((g.center + position) / 2, hold: 1.1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (p == null || !p.shadowSent) {
      removeFromParent();
      return;
    }
    position.setFrom(p.shadowFeet - Vector2(0, 30));
  }
}

/// Gölge taşı: yere gömülü, üstüne bir tasvir oyulmuş yassı taş. Gölge
/// gönderilebilir olduğunda oyma ılık ışır.
class ShadowStone extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  ShadowStone(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 6,
      );

  double _t = 0;
  double _glow = 0;

  bool get _ready {
    final p = game.player;
    return p != null && !p.isDead && !p.shadowSent;
  }

  @override
  bool canUse(Vector2 p) =>
      _ready && (p - position).x.abs() < 28 && (p - position).y.abs() < 44;

  @override
  void use() {
    final p = game.player;
    if (p == null) return;
    p.sendShadow();
    game.world.add(ShadowDecoy());
    GameAudio.instance.play('glide', volume: 0.55);
    GameAudio.instance.play('murmur', volume: 0.25, minGapMs: 2000);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    final near = p != null && (p.center - position).length < 6 * kTile;
    _glow = approach(_glow, _ready ? (near ? 1 : 0.45) : 0, dt, 0.4);
  }

  @override
  void render(Canvas canvas) {
    // Yassı taş: zeminden biraz yükselir.
    final slab = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-15, -7, 30, 8),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      slab,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -7),
          const Offset(0, 1),
          const [Color(0xFF5A463A), Color(0xFF241812)],
        ),
    );
    // Oyma tasvir: el kaldırmış küçük bir gölge (Sâye).
    final pulse = 0.75 + 0.25 * math.sin(_t * 2.4);
    final g = _glow * pulse;
    if (g > 0.02) glowDot(canvas, const Offset(0, -5), 22, kWarmLight, 0.5 * g);
    final carve = Paint()
      ..color = Color.lerp(const Color(0xFF120A06), const Color(0xFFFFD9A0), g)!;
    canvas.drawCircle(const Offset(0, -6.2), 1.5, carve);
    canvas.drawPath(
      Path()
        ..moveTo(-1.6, -4.6)
        ..lineTo(1.6, -4.6)
        ..lineTo(2.6, -0.8)
        ..lineTo(-2.6, -0.8)
        ..close(),
      carve,
    );
    canvas.drawLine(
      const Offset(1.4, -4.2),
      const Offset(4.6, -6.6),
      carve..strokeWidth = 0.9,
    );
  }
}
