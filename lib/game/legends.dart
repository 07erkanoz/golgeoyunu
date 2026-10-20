import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'player.dart';
import 'strings.dart';

// ================================================================ Medusa

/// Yerebatan'ın Medusa başı. Ara ara gözlerini açar; bakışının önünde
/// kıpırdayan taşa döner (Sâye de, Kandilci de). Saklanan ya da kıpırdamadan
/// duran kurtulur. Bakışına bir ayna konursa kendi bakışıyla taşlaşır ve bir
/// daha açılmaz (Perseus'un kalkanı gibi).
class MedusaHead extends PositionComponent with HasGameReference<GolgeGame> {
  MedusaHead(Vector2 cell)
    : _t = (cell.x / kTile * 1.37) % period,
      super(position: cell + Vector2.all(kTile / 2), priority: 6);

  static const double range = 16 * kTile;
  static const double halfHeight = 2.4 * kTile;
  static const double closed = 3.6;
  static const double opening = 0.9;
  static const double open = 2.6;
  static const double closing = 0.5;
  static const double period = closed + opening + open + closing;

  /// Kalkan bu kadar yaklaşınca kendi yansımasını görür.
  static const double sealDistance = 4.5 * kTile;

  int facing = 1;
  double _t;
  bool sealed = false;
  final _lastPos = Vector2.zero();

  /// 0 kapalı, 1 tamamen açık.
  double get eyes {
    if (sealed) return 0;
    final k = _t % period;
    if (k < closed) return 0;
    if (k < closed + opening) return (k - closed) / opening;
    if (k < closed + opening + open) return 1;
    return 1 - (k - closed - opening - open) / closing;
  }

  bool get gazing => eyes >= 1;

  @override
  void onMount() {
    super.onMount();
    facing = position.x < game.level.pixelWidth / 2 ? 1 : -1;
    // Başın önü hangi yanda boşsa oraya bakar.
    final c = (position.x / kTile).floor();
    final r = (position.y / kTile).floor();
    if (game.level.solid(c + facing, r) && !game.level.solid(c - facing, r)) {
      facing = -facing;
    }
  }

  bool inGaze(Vector2 p) {
    if (sealed) return false;
    final d = p - position;
    if (d.x * facing < 0 || d.x.abs() > range) return false;
    if (d.y.abs() > halfHeight) return false;
    if (!game.level.lineOfSight(position, p)) return false;
    // Kalkanın ardında kalan görünmez.
    for (final s in game.world.children.whereType<ShieldCrate>()) {
      final r = s.toRect();
      final sx = r.center.dx;
      if ((sx - position.x).sign == (p.x - position.x).sign &&
          (sx - position.x).abs() < (p.x - position.x).abs() &&
          p.y > r.top - 8 &&
          p.y < r.bottom + 8) {
        return false;
      }
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (sealed) return;
    final before = eyes;
    _t += dt;
    if (before == 0 && eyes > 0) {
      // Taş sürtünmesi yalnızca yakındaki baştan duyulur.
      final p = game.player;
      final near = p == null || p.isDead
          ? 0.0
          : (1 - (p.center - position).length / (20 * kTile)).clamp(0.0, 1.0);
      if (near > 0) GameAudio.instance.play('grind', volume: 0.7 * near);
    }
    // Perseus'un kalkanı: gözler açılırken yakındaki cilalı kalkanda kendini
    // görür ve taşa döner.
    if (eyes > 0) {
      for (final m in game.world.children.whereType<ShieldCrate>()) {
        final d = m.toRect().center.dx - position.x;
        if (d * facing > -2 * kTile &&
            d.abs() < sealDistance &&
            (m.toRect().center.dy - position.y).abs() < halfHeight) {
          sealed = true;
          GameAudio.instance.play('grind');
          GameAudio.instance.play('memory', volume: 0.5);
          game.once('medusaSealed', S.of('medusaSealed'));
          return;
        }
      }
    }
    if (!gazing) {
      _lastPos.setZero();
      return;
    }
    final p = game.player;
    if (p != null && !p.isDead && !p.hidden && inGaze(p.center)) {
      final moving =
          p.velocity.length > 12 ||
          !p.onGround ||
          (_lastPos != Vector2.zero() && (p.position - _lastPos).length > 0.6);
      if (moving) p.die(cause: DeathCause.stone);
    }
    if (p != null) _lastPos.setFrom(p.position);
    for (final g in game.world.children.whereType<Guard>().toList()) {
      if (g.falling) continue;
      if (inGaze(g.center)) {
        // Kandilci taşa döner: üstüne basılabilen bir heykel olur.
        game.world.add(StoneGuard(g.position.clone(), g.facing));
        g.removeFromParent();
        GameAudio.instance.play('grind', volume: 0.6);
        game.once('guardStone', S.of('guardStone'));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final e = eyes;
    // Bakış: gözlerden çıkan, açıldıkça uzayan ve genişleyen soluk yeşil
    // bir ışın; içinde taş tozu süzülür.
    if (e > 0) {
      final len = range * (0.25 + 0.75 * e);
      final far = facing * len;
      final spread = halfHeight * (0.4 + 0.6 * e);
      final beam = Path()
        ..moveTo(facing * 6.0, -4)
        ..lineTo(far, -spread)
        ..lineTo(far, spread)
        ..lineTo(facing * 6.0, 4)
        ..close();
      final shimmer = 0.85 + 0.15 * math.sin(_t * 9);
      canvas.drawPath(
        beam,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(facing * 6.0, 0),
            Offset(far, 0),
            [
              const Color(0xFFD8F0C8).withValues(alpha: 0.45 * e * shimmer),
              const Color(0xFFB8D8B0).withValues(alpha: 0.18 * e),
              const Color(0xFFB8D8B0).withValues(alpha: 0),
            ],
            const [0, 0.35, 1],
          ),
      );
      // Taş tozu: ışının içinde gözden uzağa akar.
      final dust = Paint()
        ..color = const Color(0xFFE8F4E0).withValues(alpha: 0.5 * e);
      for (var i = 0; i < 18; i++) {
        final k = (i * 0.61803 + _t * 0.35) % 1.0;
        final y = (((i * 37) % 21) / 10 - 1) * spread * k;
        canvas.drawCircle(Offset(far * k, y), 1.3, dust);
      }
    }
    // Yılan saçlı taş baş (kabartma).
    final stone = Paint()..color = const Color(0xFF2A2420);
    final hair = Paint()
      ..color = const Color(0xFF2A2420)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final a = -math.pi + i * math.pi / 8;
      final wig = math.sin(_t * 2 + i) * (sealed ? 0 : 3);
      canvas.drawPath(
        Path()
          ..moveTo(math.cos(a) * 14, math.sin(a) * 14)
          ..quadraticBezierTo(
            math.cos(a) * 24 + wig,
            math.sin(a) * 24,
            math.cos(a + 0.3) * 30,
            math.sin(a + 0.3) * 30 + wig,
          ),
        hair,
      );
    }
    canvas.drawOval(const Rect.fromLTWH(-16, -18, 32, 38), stone);
    final eyeColor = sealed
        ? const Color(0xFF14100C)
        : Color.lerp(const Color(0xFF14100C), const Color(0xFFD8F0C8), e)!;
    for (final x in [-6.0, 6.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -2), width: 7, height: 1 + 3 * e),
        Paint()..color = eyeColor,
      );
    }
    if (e > 0.2) {
      glowDot(
        canvas,
        const Offset(0, -2),
        26,
        const Color(0xFFD8F0C8),
        0.35 * e,
      );
    }
    if (sealed) {
      // Taşlaşmış: çatlaklar.
      final crack = Paint()
        ..color = const Color(0xFF8A7A6A).withValues(alpha: 0.6)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(-10, -14), const Offset(2, 6), crack);
      canvas.drawLine(const Offset(2, 6), const Offset(-4, 18), crack);
    }
  }
}

/// Medusa'nın bakışıyla taşa dönmüş Kandilci: üstüne çıkılabilen heykel.
class StoneGuard extends Deck {
  StoneGuard(Vector2 at, this.facing)
    : super(position: at + Vector2(0, 0), size: Vector2(Guard.gw, Guard.gh));

  final int facing;

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF3A3430);
    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(
      Path()
        ..moveTo(1, size.y)
        ..lineTo(3, 18)
        ..quadraticBezierTo(8, 6, 14, 2)
        ..lineTo(18, 14)
        ..lineTo(22, size.y)
        ..close(),
      stone,
    );
    canvas.drawLine(
      const Offset(17, 46),
      const Offset(29, 2),
      Paint()
        ..color = const Color(0xFF3A3430)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(4, 1),
      Offset(20, 1),
      Paint()
        ..color = const Color(0xFF8A8078).withValues(alpha: 0.6)
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }
}

/// Perseus'un cilalı kalkanı: itilebilir. Arkasında kalan Medusa'nın
/// bakışından korunur; Medusa'ya yaklaşınca onu kendi bakışıyla taşlaştırır.
class ShieldCrate extends Crate {
  ShieldCrate(super.cell);

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    const s = Crate.side;
    final c = const Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2, Paint()..color = const Color(0xFF3A2A14));
    canvas.drawCircle(
      c,
      s / 2 - 3,
      Paint()
        ..shader = ui.Gradient.radial(c.translate(-4, -4), s / 2, [
          const Color(0xFFF2D8A0),
          const Color(0xFF8A6030),
        ]),
    );
    // Parıltı.
    final glint = 0.5 + 0.5 * math.sin(_t * 2);
    canvas.drawCircle(
      c.translate(-5, -6),
      2.5,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4 + 0.4 * glint),
    );
  }
}

// =================================================================== Sal

/// Sarnıç suyunda bir sal. Üstünde ←/→ ile sırıkla itilir; Sâye salın
/// üstünde durur, sal onu taşır.
class Raft extends Deck {
  Raft(Vector2 cell)
    : super(
        position: Vector2(cell.x, cell.y + kTile + 3),
        size: Vector2(kTile * 3, 10),
      ) {
    // Suyun üstünde yüzer: su katmanının önünde çizilir.
    priority = 27;
  }

  double _vx = 0;
  double _t = 0;
  late double _surface;
  late double _minX;
  late double _maxX;

  @override
  void onMount() {
    super.onMount();
    // Bulunduğu su şeridinin uçları.
    final lv = game.level;
    final r = ((position.y - 3) / kTile).floor();
    final c = (position.x / kTile).floor();
    var lo = c;
    while (lo > 0 && lv.cell(lo - 1, r) == 'w') {
      lo--;
    }
    var hi = c + 2;
    while (hi + 1 < lv.width && lv.cell(hi + 1, r) == 'w') {
      hi++;
    }
    _minX = lo * kTile.toDouble();
    _maxX = (hi + 1) * kTile - size.x;
    _surface = r * kTile.toDouble();
  }

  bool get carrying => game.player?.riding == this;

  @override
  void step(double dt) {
    _t += dt;
    final c = game.controls;
    final dir = carrying ? (c.right ? 1 : 0) - (c.left ? 1 : 0) : 0;
    _vx += ((dir * 62.0) - _vx) * math.min(1, dt * 1.6);
    var x = position.x + _vx * dt;
    if (x < _minX || x > _maxX) {
      x = x.clamp(_minX, _maxX);
      _vx = 0;
    }
    final bob = math.sin(_t * 1.4) * 1.5;
    moveTo(Vector2(x, _surface + 3 + bob));
  }

  @override
  void render(Canvas canvas) {
    final log = Paint()..color = const Color(0xFF22140C);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * kTile + 1, 0, kTile - 2, 10),
          const Radius.circular(5),
        ),
        log,
      );
    }
    // Karanlık suda seçilsin: kütüklerin üstüne vuran ılık ışık.
    canvas.drawLine(
      const Offset(3, 1),
      Offset(size.x - 3, 1),
      Paint()
        ..color = kWarmLight.withValues(alpha: 0.45)
        ..strokeWidth = 1.6,
    );
    final rope = Paint()
      ..color = const Color(0xFFA07A52)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(8, 1), const Offset(8, 9), rope);
    canvas.drawLine(Offset(size.x - 8, 1), Offset(size.x - 8, 9), rope);
    // Sırık: binilmeden önce salın üstüne yatırılmış durur.
    if (!carrying) {
      canvas.drawLine(
        const Offset(4, -3),
        Offset(size.x - 2, -6),
        Paint()
          ..color = kInk
          ..strokeWidth = 2,
      );
    }
    if (carrying) {
      final sway = math.sin(_t * 3) * 6;
      canvas.drawLine(
        Offset(size.x / 2 + sway, -40),
        Offset(size.x / 2 - sway - 10, 30),
        Paint()
          ..color = kInk
          ..strokeWidth = 2,
      );
    }
  }
}

// ============================================================ Alevli baca

/// Yanan damlarda bir baca: aralıklarla alev püskürtür. Üstüne sandık
/// itilirse tıkanır.
class FireVent extends PositionComponent with HasGameReference<GolgeGame> {
  FireVent(Vector2 cell, {double phase = 0})
    : _t = phase,
      super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 21,
      );

  static const double rest = 2.2;
  static const double warn = 0.7;
  static const double burn = 1.3;
  double _t;

  bool get plugged => game.world.children.whereType<Crate>().any(
    (c) => c.toRect().contains(Offset(position.x, position.y - 6)),
  );

  /// 0: sönük, 0-1: duman, 1: alev.
  double get heat {
    final k = _t % (rest + warn + burn);
    if (k < rest) return 0;
    if (k < rest + warn) return (k - rest) / warn * 0.99;
    return 1;
  }

  bool get burning => heat >= 1 && !plugged;

  Rect get flame =>
      Rect.fromLTWH(position.x - 12, position.y - 3 * kTile, 24, 3 * kTile);

  @override
  void update(double dt) {
    super.update(dt);
    final was = burning;
    final warm = heat;
    _t += dt;
    final p = game.player;
    // Ses yalnızca yakındaki bacadan gelir; uzaklaştıkça kısılır.
    final near = p == null
        ? 0.0
        : (1 - (p.center - position).length / (12 * kTile)).clamp(0.0, 1.0);
    if (!plugged && near > 0) {
      if (warm == 0 && heat > 0) {
        GameAudio.instance.play('fire_warn', volume: 0.5 * near, minGapMs: 0);
      }
      if (burning && !was) {
        GameAudio.instance.play('fire', volume: 0.7 * near, minGapMs: 0);
      }
    }
    if (burning &&
        p != null &&
        !p.isDead &&
        p.toRect().deflate(2).overlaps(flame)) {
      p.die(cause: DeathCause.light);
    }
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    canvas.drawRect(const Rect.fromLTWH(-8, -10, 16, 10), ink);
    canvas.drawRect(const Rect.fromLTWH(-10, -12, 20, 3), ink);
    if (plugged) return;
    final h = heat;
    if (h <= 0) return;
    if (h < 1) {
      // Duman: uyarı.
      final smoke = Paint()
        ..color = const Color(0xFF3A2A24).withValues(alpha: 0.5 * h);
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          Offset(math.sin(_t * 5 + i) * 4, -14 - i * 8 * h),
          4 + i * 1.5,
          smoke,
        );
      }
      return;
    }
    final flick = math.sin(_t * 30) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(-10, -10)
        ..quadraticBezierTo(-14, -50, flick, -3 * kTile)
        ..quadraticBezierTo(14, -50, 10, -10)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -10),
          Offset(0, -3 * kTile),
          [
            const Color(0xFFFFE6A0),
            const Color(0xFFE0703A).withValues(alpha: 0.6),
          ],
        ),
    );
    glowDot(canvas, const Offset(0, -40), 60, kEmber, 0.45);
  }
}

// ========================================================= Fener balonu

/// Kandilcilerin gök feneri: iki nokta arasında süzülür, aşağı doğru ışık
/// tutar. Işığında kalan görülür; görüldükten bir an sonra yakalanır.
class LanternBalloon extends PositionComponent
    with HasGameReference<GolgeGame> {
  LanternBalloon(Vector2 cell)
    : _home = cell + Vector2(kTile / 2, kTile / 2),
      _t = (cell.x / kTile * 0.73) % 14,
      super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 23);

  static const double span = 5 * kTile;
  static const double beamLength = 7 * kTile;
  final Vector2 _home;
  double _t;
  double suspicion = 0;

  bool inBeam(Vector2 p) {
    final d = p - position;
    if (d.y < 0 || d.y > beamLength) return false;
    return d.x.abs() < 10 + d.y * 0.32 &&
        game.level.lineOfSight(position + Vector2(0, 10), p);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.setValues(
      _home.x + math.sin(_t * 0.45) * span,
      _home.y + math.sin(_t * 1.3) * 6,
    );
    final p = game.player;
    if (p == null || p.isDead || game.cinematic) return;
    final sees = !p.hidden && inBeam(p.center);
    if (sees && suspicion == 0) {
      GameAudio.instance.play('suspect', volume: 0.6, minGapMs: 1200);
    }
    suspicion = sees
        ? math.min(1, suspicion + dt * 1.8)
        : math.max(0, suspicion - dt * 0.8);
    if (suspicion >= 1) {
      suspicion = 0;
      p.die(cause: DeathCause.light);
    }
  }

  @override
  void render(Canvas canvas) {
    // Işık konisi.
    canvas.drawPath(
      Path()
        ..moveTo(-6, 10)
        ..lineTo(6, 10)
        ..lineTo(10 + beamLength * 0.32, beamLength)
        ..lineTo(-10 - beamLength * 0.32, beamLength)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 10),
          const Offset(0, beamLength),
          [
            Color.lerp(
              kCold,
              const Color(0xFFF2FFFC),
              suspicion,
            )!.withValues(alpha: 0.22 + 0.25 * suspicion),
            kCold.withValues(alpha: 0),
          ],
        ),
    );
    // Kâğıt balon ve asılı fener.
    canvas.drawOval(
      const Rect.fromLTWH(-16, -34, 32, 34),
      Paint()..color = const Color(0xFF1A1418),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-10, -28, 20, 24),
      Paint()..color = kCold.withValues(alpha: 0.25),
    );
    final line = Paint()
      ..color = kInk
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(-8, -2), const Offset(-3, 8), line);
    canvas.drawLine(const Offset(8, -2), const Offset(3, 8), line);
    canvas.drawRect(
      const Rect.fromLTWH(-4, 6, 8, 8),
      Paint()..color = kCold.withValues(alpha: 0.95),
    );
  }
}

// ============================================================ Simurg tüyü

/// Kaf'ta dağılmış Simurg tüyleri. Hepsi toplanınca tüy sunağı açılır.
class SimurgFeather extends PositionComponent with HasGameReference<GolgeGame> {
  SimurgFeather(Vector2 cell)
    : super(position: cell + Vector2.all(kTile / 2), priority: 19);

  bool taken = false;
  double _t = math.Random().nextDouble() * 5;
  double _gone = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (taken) {
      _gone += dt;
      if (_gone > 1) removeFromParent();
      return;
    }
    final p = game.player;
    if (p != null && !p.isDead && (p.center - position).length < 26) {
      taken = true;
      GameAudio.instance.play('memory', volume: 0.7);
      final left = game.world.children
          .whereType<SimurgFeather>()
          .where((f) => !f.taken)
          .length;
      game.narration.whisper(
        left == 0 ? S.of('feathersAll') : '${S.of('feather')} · $left',
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final a = taken ? (1 - _gone).clamp(0.0, 1.0) : 1.0;
    canvas.save();
    canvas.translate(0, math.sin(_t * 1.6) * 4 - (taken ? _gone * 40 : 0));
    canvas.rotate(math.sin(_t * 0.9) * 0.3);
    glowDot(canvas, Offset.zero, 26, const Color(0xFFE8D58A), 0.4 * a);
    canvas.drawPath(
      Path()
        ..moveTo(0, -14)
        ..quadraticBezierTo(8, -4, 2, 12)
        ..lineTo(-1, 12)
        ..quadraticBezierTo(-7, -4, 0, -14)
        ..close(),
      Paint()..color = const Color(0xFFE8D58A).withValues(alpha: 0.9 * a),
    );
    canvas.drawLine(
      const Offset(0, -12),
      const Offset(0.5, 16),
      Paint()
        ..color = const Color(0xFF6A5A2A).withValues(alpha: a)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }
}

/// Tüy sunağı: bölümdeki bütün tüyler toplanınca parlar ve en yakın kapıyı
/// açar.
class FeatherAltar extends PositionComponent with HasGameReference<GolgeGame> {
  FeatherAltar(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  bool open = false;
  double _glow = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (open) {
      _glow = math.min(1, _glow + dt);
      return;
    }
    final any = game.world.children.whereType<SimurgFeather>().any(
      (f) => !f.taken,
    );
    if (any) return;
    open = true;
    GameAudio.instance.play('gate', volume: 0.7);
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final d = (g.position - position).length;
      if (d < bestD && !g.opening) {
        bestD = d;
        best = g;
      }
    }
    best?.opening = true;
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    canvas.drawRect(const Rect.fromLTWH(-12, -18, 24, 18), ink);
    canvas.drawRect(const Rect.fromLTWH(-16, -22, 32, 5), ink);
    if (_glow > 0) {
      glowDot(
        canvas,
        const Offset(0, -30),
        50,
        const Color(0xFFE8D58A),
        0.5 * _glow,
      );
    }
    // Kanat oyması.
    final carve = Paint()
      ..color = Color.lerp(
        const Color(0xFF3A3020),
        const Color(0xFFF2E2A0),
        _glow,
      )!
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(-8, -6)
        ..quadraticBezierTo(0, -16, 8, -6),
      carve,
    );
  }
}

// ================================================================ Sağanak

/// Sağanak bölgesi: yağmur çizgileri; içindeyken kanatlar ıslanır.
class RainZone extends Component with HasGameReference<GolgeGame> {
  RainZone(this.area) : super(priority: 25);

  final Rect area;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final r = area.intersect(view);
    if (r.width <= 0 || r.height <= 0) return;
    final rain = Paint()
      ..color = const Color(0xFFB8C8E0).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    final count = (area.width * area.height / 2600).clamp(20, 220).toInt();
    for (var i = 0; i < count; i++) {
      final x = area.left + (i * 97.0 % area.width);
      final y = area.top + ((i * 211.0 + _t * 520) % area.height);
      if (!r.contains(Offset(x, y))) continue;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 14), rain);
    }
  }
}

// ============================================================ Peri halkası

/// Perilerin bıraktığı ışıklı halka: üstüne basanı göğe fırlatır.
class FairyRing extends PositionComponent with HasGameReference<GolgeGame> {
  FairyRing(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 19,
      );

  double _t = 0;
  double _pulse = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _pulse = math.max(0, _pulse - dt * 2);
    final p = game.player;
    if (p == null || p.isDead || !p.onGround) return;
    final feet = p.position.y + Player.h;
    if ((p.center.x - position.x).abs() < 18 && (feet - position.y).abs() < 4) {
      p.velocity.y = -880;
      p.onGround = false;
      _pulse = 1;
      GameAudio.instance.play('firefly', volume: 0.8);
      GameAudio.instance.play('glide', volume: 0.5);
    }
  }

  @override
  void render(Canvas canvas) {
    final glow = 0.5 + 0.3 * math.sin(_t * 3) + _pulse * 0.5;
    glowDot(
      canvas,
      const Offset(0, -6),
      34,
      const Color(0xFFE8C8FF),
      0.35 * glow,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-15, -4, 30, 7),
      Paint()
        ..color = const Color(0xFFF2E0FF).withValues(alpha: 0.7 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Halkanın üstünde süzülen tozlar.
    final dust = Paint()
      ..color = const Color(0xFFF8EEFF).withValues(alpha: 0.8);
    for (var i = 0; i < 6; i++) {
      final k = ((_t * 0.6 + i / 6) % 1.0);
      canvas.drawCircle(
        Offset(math.sin(_t * 2 + i) * 10, -4 - k * 40),
        1.2 * (1 - k) + 0.4,
        dust,
      );
    }
  }
}

// ============================================================ Sürgü taşı

/// Derinkuyu'nun yuvarlak sürgü taşı: itilerek yuvarlanır, geçidi kapatır.
/// Kandilciler onu yerinden oynatamaz.
class MillStone extends Crate {
  MillStone(super.cell);

  double _roll = 0;
  double _lastX = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _roll += (position.x - _lastX) / 15;
    _lastX = position.x;
  }

  @override
  void render(Canvas canvas) {
    const s = Crate.side;
    const c = Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2 + 1, Paint()..color = const Color(0xFF2A1C16));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_roll);
    final groove = Paint()
      ..color = const Color(0xFF6A4A36).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset.zero, s / 2 - 4, groove);
    canvas.drawCircle(Offset.zero, 3, Paint()..color = const Color(0xFF0A0605));
    canvas.drawLine(const Offset(0, -12), const Offset(0, -6), groove);
    canvas.restore();
  }
}
