import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'audio.dart';
import 'entities.dart';
import 'feedback.dart' show LinkPulse;
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart' show Deck;
import 'palette.dart';
import 'player.dart' show Player;
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
    : super(position: Vector2(cell.x + kTile / 2, cell.y + kTile), priority: 6);

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
    game.hint('shadowSteer');
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
      ..color = Color.lerp(
        const Color(0xFF120A06),
        const Color(0xFFFFD9A0),
        g,
      )!;
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

/// Gölge yarığı: duvarda ince, kıvrık bir çatlak. Sâye geçemez; gönderilen
/// gölge süzülüp geçer (ardındaki odada kol varsa çeker). Çatlağın içi
/// soluk mor ışır, gölge geçerken parlar.
class ShadowCrack extends PositionComponent with HasGameReference<GolgeGame> {
  ShadowCrack(this.col, this.top, this.bottom)
    : super(
        position: Vector2((col + 0.5) * kTile, top * kTile.toDouble()),
        priority: 7,
      );

  final int col, top, bottom;
  double _t = 0;
  double _lit = 0;

  double get _h => (bottom - top + 1) * kTile.toDouble();

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    final passing =
        p.shadowSent && (p.shadowFeet.x - position.x).abs() < kTile * 0.8;
    _lit = approach(_lit, passing ? 1 : 0, dt, 0.15);
  }

  @override
  void render(Canvas canvas) {
    final h = _h;
    final crack = Path()..moveTo(0, 2);
    for (var i = 1; i <= 8; i++) {
      final y = 2 + (h - 4) * i / 8;
      crack.lineTo((i.isEven ? -2.6 : 2.8) + math.sin(i * 2.3) * 1.6, y);
    }
    final pulse = 0.6 + 0.4 * math.sin(_t * 1.8);
    final glow = 0.45 * pulse + 0.55 * _lit;
    glowDot(
      canvas,
      Offset(0, h / 2),
      h * 0.6,
      const Color(0xFFB8A0E0),
      0.4 * glow,
    );
    canvas.drawPath(
      crack,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF050307),
    );
    canvas.drawPath(
      crack,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFE2D6FA).withValues(alpha: 0.5 + 0.5 * glow),
    );
  }
}

/// Gölge eşiği: yere gömülü, kenarı mor damarlı kara taş. Işığı da Sâye'nin
/// ayağını da tanımaz; yalnız gölgenin ağırlığını. Gönderilen gölge üstünde
/// durdukça bağlı kapı kalkar, gölge ayrılınca iner (Sâye kapıdan geçince
/// kapı açık kalır). Sâye aynı anda iki yerde olur: gölgesi eşikte, kendisi
/// kapıda.
class ShadowPlate extends PositionComponent with HasGameReference<GolgeGame> {
  ShadowPlate(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 20,
      );

  /// Gölgenin eşikte durduğu süre (sonra Sâye'ye döner).
  static const hold = 4.0;

  Gate? gate;
  bool pressed = false;
  double _t = 0;
  double _press = 0;

  /// Kapı açık kaldı (Sâye geçti): eşiğin işi bitti.
  bool get done => gate?.opening ?? false;

  bool _shadowOn(Player p) =>
      p.shadowSent &&
      (p.shadowFeet.x - position.x).abs() < 14 &&
      (p.shadowFeet.y - position.y).abs() < 12;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (gate == null) {
      var bestD = double.infinity;
      for (final g in game.world.children.whereType<Gate>()) {
        final d = (g.position - position).length;
        if (d < bestD) {
          bestD = d;
          gate = g;
        }
      }
      gate?.tied = true;
    }
    final p = game.player;
    final on = p != null && !done && _shadowOn(p);
    if (on && !pressed) {
      GameAudio.instance.play('grind', volume: 0.45);
      final g = gate;
      if (g != null) {
        game.world.add(
          LinkPulse(position - Vector2(0, 14), g.position + g.size / 2),
        );
      }
    }
    pressed = on;
    gate?.held = on;
    _press = approach(_press, on || done ? 1 : 0, dt, 0.12);
  }

  @override
  void render(Canvas canvas) {
    final sink = 2 * _press;
    final slab = RRect.fromRectAndRadius(
      Rect.fromLTWH(-17, -5 + sink, 34, 6 - sink),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      slab,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -5 + sink),
          const Offset(0, 1),
          const [Color(0xFF2A2230), Color(0xFF0C080E)],
        ),
    );
    final pulse = 0.6 + 0.4 * math.sin(_t * 1.6);
    final glow = done ? 0.5 : 0.4 * pulse + 0.6 * _press;
    glowDot(
      canvas,
      Offset(0, -3 + sink),
      34,
      const Color(0xFFB8A0E0),
      0.6 * glow,
    );
    // Mor damar: taşın üst kenarı boyunca, ortada yatan bir gölge oyması.
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE2D6FA).withValues(alpha: 0.45 + 0.55 * glow);
    canvas.drawLine(Offset(-14, -4.4 + sink), Offset(14, -4.4 + sink), vein);
    canvas.drawPath(
      Path()
        ..moveTo(-8, -2 + sink)
        ..quadraticBezierTo(-2, -3.6 + sink, 6, -2.2 + sink)
        ..moveTo(6, -2.2 + sink)
        ..lineTo(9, -2.4 + sink),
      vein,
    );
    canvas.drawCircle(Offset(-9.5, -2.2 + sink), 1.4, vein);
  }
}

/// Mürekkep tahta: gölge köprüsünün bir karesi. Gönderilen gölge uçurumun
/// üstünde yürürken ayağının altında mürekkep katılaşır; gölge Sâye'ye
/// dönünce tahtalar az bekler, titrer ve dağılır.
class InkPlank extends Deck {
  InkPlank(int col, int row)
    : super(
        position: Vector2(col * kTile.toDouble(), row * kTile.toDouble()),
        size: Vector2(kTile.toDouble(), 10),
      );

  /// Gölge döndükten sonra tahtanın dayandığı süre.
  static const linger = 2.2;

  bool laid = false;
  double _after = 0;
  double _show = 0;
  double _t = math.Random().nextDouble() * 5;

  @override
  bool get active => laid;

  @override
  void step(double dt) {
    _t += dt;
    final p = game.player;
    if (p != null && p.shadowSent) {
      final f = p.shadowFeet;
      if (!laid &&
          f.x >= position.x - 2 &&
          f.x <= position.x + size.x + 2 &&
          (f.y - position.y).abs() < 8) {
        laid = true;
        GameAudio.instance.play('glide', volume: 0.18, minGapMs: 250);
      }
      _after = 0;
    } else if (laid) {
      _after += dt;
      if (_after > linger) {
        laid = false;
        GameAudio.instance.play('fizzle', volume: 0.2, minGapMs: 400);
      }
    }
    _show = approach(_show, laid ? 1 : 0, dt, laid ? 0.12 : 0.3);
  }

  @override
  void render(Canvas canvas) {
    var a = _show;
    if (a < 0.01) {
      // Uçurumun üstünde belli belirsiz bir iz: köprünün yeri.
      final dot = Paint()
        ..color = const Color(0xFFB8A0E0).withValues(
          alpha: 0.12 + 0.08 * math.sin(_t * 1.7),
        );
      for (var x = 4.0; x < size.x; x += 8) {
        canvas.drawCircle(Offset(x, 2), 1, dot);
      }
      return;
    }
    // Sönmeden önce titrer: üstündeki kaçabilsin.
    if (laid && _after > linger - 1.0) {
      a *= 0.45 + 0.55 * (0.5 + 0.5 * math.sin(_t * 26));
    }
    final w = size.x;
    final ink = Paint()..color = kInk.withValues(alpha: 0.9 * a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-1, 0, w + 2, 8),
        const Radius.circular(3),
      ),
      ink,
    );
    // Alttan sarkan mürekkep damlaları.
    for (var i = 0; i < 3; i++) {
      final x = 5.0 + i * 11 + math.sin(i * 2.1) * 2;
      final len = 4 + 4 * (0.5 + 0.5 * math.sin(_t * 1.3 + i * 1.9));
      canvas.drawLine(
        Offset(x, 7),
        Offset(x, 7 + len * a),
        Paint()
          ..color = kInk.withValues(alpha: 0.7 * a)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    // Üst kenarda soğuk mor ışık: gölgenin izi.
    canvas.drawLine(
      const Offset(1, 0.8),
      Offset(w - 1, 0.8),
      Paint()
        ..color = const Color(0xFFE2D6FA).withValues(alpha: 0.45 * a)
        ..strokeWidth = 1.2,
    );
  }
}
