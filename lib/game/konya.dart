import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'player.dart';

// ============================================================== Semâzen

/// Dönen semâzen: hem kendi çevresinde hem salonun çevresinde döner. Yandan
/// bakınca bir elips çizer; önden geçerken (büyük, parlak) eteğinin
/// gölgesinde saklanılır, arkadan dönerken (küçük, soluk) saklamaz.
/// Sağ eli göğe açık, sol eli yere dönük: Hak'tan alır, halka verir.
class Semazen extends PositionComponent with HasGameReference<GolgeGame> {
  Semazen(Vector2 cell, {required int index})
    : _cx = cell.x + kTile / 2,
      _floor = cell.y + kTile,
      // Komşu semâzenler zıt evrede başlar: biri önden geçerken öteki arkada.
      _phase = index.isEven ? 0 : math.pi,
      super(size: Vector2(44, 64), anchor: Anchor.bottomCenter, priority: 16);

  /// Salonun çevresindeki yörüngenin yarıçapı ve hızı. En hızlı anında bile
  /// parmak ucunda yürüyen Sâye yetişebilir.
  static const double radius = 5 * kTile;
  static const double omega = 0.34;

  final double _cx;
  final double _floor;
  final double _phase;
  double _t = 0;
  double _spin = 0;

  double get _angle => _phase + omega * _t;

  /// Önde mi (Sâye'yi örter)?
  bool get inFront => math.sin(_angle) > 0.15;

  /// Eteğinin altında saklanıyor mu?
  bool shades(Rect r) {
    if (!inFront) return false;
    final dx = (r.center.dx - position.x).abs();
    return dx < 18 && (r.bottom - _floor).abs() < 6;
  }

  @override
  void onMount() {
    super.onMount();
    _place();
  }

  void _place() {
    position.setValues(_cx - radius * math.cos(_angle), _floor);
    final front = inFront;
    final want = front ? 26 : 12;
    if (priority != want) priority = want;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _spin += dt * 5.5;
    _place();
  }

  @override
  void render(Canvas canvas) {
    // Arkadayken küçülür ve solar.
    final depth = (math.sin(_angle) + 1) / 2;
    final k = 0.72 + 0.28 * depth;
    final alpha = 0.45 + 0.55 * depth;
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(k);
    drawSemazen(canvas, _spin, alpha: alpha);
    canvas.restore();
  }
}

/// Semâzenin gölgesi (ayakları orijinde). Perde sahnelerinde de kullanılır.
void drawSemazen(Canvas canvas, double spin, {double alpha = 1, Color? ink}) {
  final body = Paint()..color = (ink ?? kInk).withValues(alpha: alpha);
  final pale = Paint()
    ..color = const Color(0xFFF2ECE0).withValues(alpha: 0.85 * alpha);
  // Tennure: kefen. Dönerken çan gibi açılır; etek ucu dönüşün gerisinde
  // kalarak bir yana kabarır.
  final flare = 21 + 2.5 * math.sin(spin * 2);
  final swirl = math.sin(spin - 0.9) * 3;
  final skirt = Path()
    ..moveTo(-6, -30)
    ..lineTo(6, -30)
    ..quadraticBezierTo(14 + swirl, -14, flare + swirl, -2 - swirl * 0.3)
    ..quadraticBezierTo(swirl, 3, -flare + swirl, -2 + swirl * 0.3)
    ..quadraticBezierTo(-14 + swirl, -14, -6, -30)
    ..close();
  canvas.drawPath(skirt, pale);
  // Dönen kıvrımlar.
  final fold = Paint()
    ..color = const Color(0xFFB8AE9E).withValues(alpha: 0.7 * alpha)
    ..strokeWidth = 1;
  for (var i = 0; i < 4; i++) {
    final f = math.sin(spin + i * math.pi / 2);
    canvas.drawLine(Offset(f * 4, -29), Offset(f * flare * 0.9, -2), fold);
  }
  // Gövde ve destegül: dönerken omuzlar yan gelince daralır.
  final turn = math.cos(spin);
  final half = 4 + 1.2 * turn.abs();
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-half, -44, half * 2, 16),
      const Radius.circular(3),
    ),
    pale,
  );
  canvas.drawLine(
    const Offset(-5, -31),
    const Offset(5, -31),
    Paint()
      ..color = body.color
      ..strokeWidth = 1.6,
  );
  // Baş eğik, sikke: nefsin mezar taşı.
  canvas.drawCircle(const Offset(1.5, -47), 3.6, body);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-1.5, -62, 7, 14),
      const Radius.circular(2),
    ),
    body,
  );
  // Kollar: sağ el göğe açık, sol el yere. Beden döndükçe kollar da
  // döner: yandan bakınca kısalır, karşıdan bakınca uzanır.
  final arm = Paint()
    ..color = body.color
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  final sh = 4 * turn;
  canvas.drawLine(Offset(sh, -42), Offset(14 * turn, -52), arm);
  canvas.drawLine(Offset(14 * turn, -52), Offset(18 * turn, -55), arm);
  canvas.drawLine(Offset(-sh, -42), Offset(-15 * turn, -38), arm);
  canvas.drawLine(Offset(-15 * turn, -38), Offset(-19 * turn, -34), arm);
}

// ============================================================== Avize

/// Semâhanenin dev avizesi: kollarının ucundaki mum tablaları üstüne
/// basılır. Avize semâ gibi döner; tablalar hep yatay kalır.
class Chandelier extends PositionComponent with HasGameReference<GolgeGame> {
  Chandelier(Vector2 cell, {required int index, this.arms = 4})
    : _dir = index.isEven ? 1 : -1,
      super(position: cell + Vector2.all(kTile / 2), priority: 13) {
    for (var i = 0; i < arms; i++) {
      planks.add(CandleTray(this, i * 2 * math.pi / arms + index * 0.6));
    }
  }

  static const double radius = 4 * kTile;
  static const double speed = 0.5;

  final int arms;
  final int _dir;
  final planks = <CandleTray>[];
  double t = 0;

  double angleOf(CandleTray p) => p.offset + _dir * speed * t;

  @override
  void update(double dt) {
    super.update(dt);
    t += math.min(dt, 1 / 30);
  }

  @override
  void render(Canvas canvas) {
    final chain = Paint()
      ..color = kInk
      ..strokeWidth = 2;
    // Kubbeye uzanan zincir.
    canvas.drawLine(Offset.zero, const Offset(0, -900), chain);
    final rod = Paint()
      ..color = const Color(0xFF2A1C12)
      ..strokeWidth = 3;
    for (final p in planks) {
      final a = angleOf(p);
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a) * radius, math.sin(a) * radius),
        rod,
      );
    }
    // Halka ve göbek.
    canvas.drawCircle(
      Offset.zero,
      radius * 0.35,
      Paint()
        ..color = const Color(0xFF3A2818)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset.zero, 9, Paint()..color = kInk);
    glowDot(canvas, Offset.zero, 26, kWarmLight, 0.25);
  }
}

/// Avizenin kolundaki mum tablası (tek yönlü tahta).
class CandleTray extends Deck {
  CandleTray(this.owner, this.offset)
    : super(position: Vector2.zero(), size: Vector2(kTile * 2, 8));

  final Chandelier owner;
  final double offset;
  double _flick = 0;

  Vector2 _target() {
    final a = owner.angleOf(this);
    return owner.position +
        Vector2(math.cos(a), math.sin(a)) * Chandelier.radius -
        Vector2(size.x / 2, 0);
  }

  @override
  void onMount() {
    super.onMount();
    position.setFrom(_target());
  }

  @override
  void step(double dt) {
    _flick += dt;
    moveTo(_target());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 6),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF2A1C12),
    );
    canvas.drawLine(
      const Offset(2, 0.8),
      Offset(size.x - 2, 0.8),
      Paint()
        ..color = const Color(0xFFD9A860).withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    // Üç mum.
    for (final x in [8.0, size.x / 2, size.x - 8]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 1.5, -7, 3, 7),
        Paint()..color = const Color(0xFFE8DCC4),
      );
      final f = 1 + 0.25 * math.sin(_flick * 9 + x);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -10), width: 3 * f, height: 6 * f),
        Paint()..color = kWarmLight,
      );
      glowDot(canvas, Offset(x, -10), 12, kWarmLight, 0.35);
    }
  }
}

// ============================================================ Büyük fener

/// Kandilcilerin büyük feneri: minarenin şerefesine asılmış, damları
/// tarar. Huzmesi duvarda, kubbede, bacada kesilir; arkasına saklanılır.
/// Huzmede kalan gölge birkaç an içinde silinir.
class GreatLamp extends PositionComponent with HasGameReference<GolgeGame> {
  GreatLamp(Vector2 cell, {required int index})
    : _phase = index * 1.7,
      super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 22);

  /// Huzmenin uzunluğu, yarı açısı ve tarama.
  static const double reach = 26 * kTile;
  static const double halfWidth = 0.1;
  static const double mid = math.pi / 2;
  static const double sweep = 1.15;
  static const double period = 7.0;

  final double _phase;
  double _t = 0;
  double exposure = 0;

  double get beamAngle =>
      mid + sweep * math.sin(_t * 2 * math.pi / period + _phase);

  /// Huzmenin kenarlarını oluşturan ışınların ucu (duvarda kesilir).
  final rays = <Offset>[];

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _trace();
    final p = game.player;
    if (p == null || p.isDead) {
      exposure = 0;
      return;
    }
    if (_sees(p)) {
      if (exposure == 0) {
        GameAudio.instance.play('chain', volume: 0.5, minGapMs: 600);
      }
      exposure += dt;
      game.threat = math.max(game.threat, 0.9);
      if (exposure > 0.1) {
        exposure = 0;
        p.die(cause: DeathCause.light);
      }
    } else {
      exposure = math.max(0, exposure - dt * 2);
    }
  }

  bool _sees(Player p) {
    if (p.hidden) return false;
    final target = p.center;
    final d = target - position;
    final dist = d.length;
    if (dist > reach || dist < 4) return false;
    var off = math.atan2(d.y, d.x) - beamAngle;
    off = (off + math.pi) % (2 * math.pi) - math.pi;
    // Çok yakında huzme daha geniş görünür (gövdenin kendisi).
    if (off.abs() > halfWidth + 10 / dist) return false;
    return _clear(position.toOffset(), target.toOffset());
  }

  /// İki nokta arasında kaya yok mu?
  bool _clear(Offset a, Offset b) {
    final len = (b - a).distance;
    final level = game.level;
    for (var s = 18.0; s < len; s += 8) {
      final q = Offset.lerp(a, b, s / len)!;
      if (level.cellAt(q.dx, q.dy) == '#') return false;
    }
    return true;
  }

  Offset _cast(double a) {
    final level = game.level;
    final dir = Offset(math.cos(a), math.sin(a));
    final o = position.toOffset();
    for (var s = 18.0; s < reach; s += 8) {
      final q = o + dir * s;
      if (level.cellAt(q.dx, q.dy) == '#') return q;
    }
    return o + dir * reach;
  }

  void _trace() {
    rays.clear();
    const n = 7;
    for (var i = 0; i < n; i++) {
      final a = beamAngle - halfWidth + 2 * halfWidth * i / (n - 1);
      rays.add(_cast(a));
    }
  }

  Path beamPath() {
    final o = Offset.zero;
    final path = Path()..moveTo(o.dx, o.dy);
    for (final r in rays) {
      final l = r - position.toOffset();
      path.lineTo(l.dx, l.dy);
    }
    return path..close();
  }

  @override
  void render(Canvas canvas) {
    if (rays.isEmpty) return;
    final far = rays[rays.length ~/ 2] - position.toOffset();
    canvas.drawPath(
      beamPath(),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, far, [
          kCold.withValues(alpha: 0.42 + exposure),
          kCold.withValues(alpha: 0.05),
        ]),
    );
    // Fenerin kendisi.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 26),
        const Radius.circular(4),
      ),
      Paint()..color = kInk,
    );
    canvas.drawCircle(
      Offset(math.cos(beamAngle) * 6, math.sin(beamAngle) * 6),
      6,
      Paint()..color = const Color(0xFFE4FFF8),
    );
    glowDot(canvas, Offset.zero, 60, kCold, 0.5);
  }
}

// ============================================================ Işık seli

/// Kandilcilerin yüzyıllardır biriktirdiği ışık, ustanın kandili sönmeye
/// yüz tutunca taşar: aşağıdan yükselen soğuk bir ışık seli. Gölgeye değerse
/// siler. Sâye ancak tırmanarak kurtulur.
class LightFlood extends PositionComponent with HasGameReference<GolgeGame> {
  LightFlood(this.startX, this.topY) : super(priority: 30);

  final double startX;

  /// Bu yüksekliğin üstüne çıkınca sel durur ve çekilir.
  final double topY;
  bool _awake = false;
  bool _done = false;
  double _speed = 0;
  double _t = 0;
  double _fade = 0;

  bool get awake => _awake && !_done;
  double get surface => position.y;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_done) {
      _fade = math.max(0, _fade - dt * 0.5);
      position.y += 40 * dt;
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      if (p.center.x > startX && !p.isDead) {
        _awake = true;
        position.y = p.position.y + Player.h + 7 * kTile;
        _speed = 40;
        GameAudio.instance.play('thunder', volume: 0.6);
        game.scare(0.8);
      }
      return;
    }
    _fade = math.min(1, _fade + dt);
    if (p.position.y + Player.h < topY) {
      _done = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;
    _speed = math.min(72, _speed + dt * 2.4);
    position.y -= _speed * dt;
    // Çok geride kalırsa yetişir.
    position.y = math.min(position.y, p.position.y + Player.h + 9 * kTile);
    final gap = position.y - (p.position.y + Player.h);
    game.threat = math.max(game.threat, (1 - gap / 300).clamp(0.0, 1.0));
    GameAudio.instance.dread(((400 - gap) / 360).clamp(0.2, 1.0));
    if (gap < 2) p.die(cause: DeathCause.light);
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final view = game.camera.visibleWorldRect;
    final a = _fade;
    final left = view.left - position.x - 20;
    final width = view.width + 40;
    final depth = view.bottom - position.y + 40;
    if (depth <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, width, depth),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, depth), [
          const Color(0xFFE4FFF8).withValues(alpha: 0.85 * a),
          kCold.withValues(alpha: 0.55 * a),
        ]),
    );
    // Dalgalanan yüzey ve yukarı uçuşan kıvılcımlar.
    final edge = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * a)
      ..strokeWidth = 3;
    final path = Path()..moveTo(left, 0);
    for (var x = 0.0; x <= width; x += 24) {
      path.lineTo(left + x, -3 * math.sin(_t * 3 + (left + x) / 40));
    }
    canvas.drawPath(path, edge..style = PaintingStyle.stroke);
    final spark = Paint()..color = kCold.withValues(alpha: 0.7 * a);
    for (var i = 0; i < 30; i++) {
      final k = (i * 0.37 + _t * 0.4) % 1.0;
      final x = left + ((i * 97.0) % width);
      canvas.drawCircle(Offset(x, -k * 90), 1.6 * (1 - k), spark);
    }
  }
}

/// İnce Minare'nin şerefeden yukarısı: ince gövde, külah ve alem (süs).
class MinaretCap extends PositionComponent {
  MinaretCap(Vector2 balcony) : super(position: balcony, priority: 4);

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    // Şerefe korkuluğu.
    canvas.drawRect(const Rect.fromLTWH(-110, 22, 220, 4), ink);
    for (var x = -104.0; x <= 104; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 10, 3, 14), ink);
    }
    canvas.drawRect(const Rect.fromLTWH(-110, 8, 220, 3), ink);
    // Üst gövde ve külah.
    canvas.drawRect(const Rect.fromLTWH(-14, -96, 28, 106), ink);
    for (final y in [-80.0, -50.0, -20.0]) {
      canvas.drawLine(
        Offset(-14, y),
        Offset(14, y),
        Paint()
          ..color = const Color(0xFF2A3552)
          ..strokeWidth = 1.5,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-17, -96)
        ..lineTo(0, -170)
        ..lineTo(17, -96)
        ..close(),
      ink,
    );
    // Alem: hilal.
    canvas.drawLine(
      const Offset(0, -170),
      const Offset(0, -184),
      Paint()
        ..color = const Color(0xFFD8B860)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(0, -190),
      6,
      Paint()..color = const Color(0xFFD8B860),
    );
    canvas.drawCircle(const Offset(2.5, -191), 5, Paint()..color = kInk);
  }
}
