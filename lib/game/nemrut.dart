import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'puzzles.dart';
import 'strings.dart';

// ======================================================== Aslan Horoskobu

/// Gökteki işaretler: Aslan Horoskobu'ndaki hilal, üç gezegen ve yıldız.
enum Sign { moon, jupiter, mercury, mars, star }

/// Horoskobun istediği sıra (soldan sağa yıldız taşları).
const horoscope = [Sign.moon, Sign.jupiter, Sign.mercury, Sign.mars];

void _drawSign(Canvas canvas, Sign s, Offset c, double r, Paint p) {
  switch (s) {
    case Sign.moon:
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c, radius: r)),
          Path()..addOval(
            Rect.fromCircle(
              center: c.translate(r * 0.45, -r * 0.15),
              radius: r * 0.85,
            ),
          ),
        ),
        p,
      );
    case Sign.jupiter:
      canvas.drawCircle(c, r * 0.8, p);
      canvas.drawLine(
        c.translate(-r, 0),
        c.translate(r, 0),
        Paint()
          ..color = p.color
          ..strokeWidth = 1.4,
      );
    case Sign.mercury:
      canvas.drawCircle(c, r * 0.45, p);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        canvas.drawLine(
          c,
          c + Offset(math.cos(a), math.sin(a)) * r,
          Paint()
            ..color = p.color
            ..strokeWidth = 1.2,
        );
      }
    case Sign.mars:
      canvas.drawCircle(c.translate(-r * 0.2, r * 0.2), r * 0.55, p);
      canvas.drawLine(
        c.translate(r * 0.1, -r * 0.1),
        c.translate(r * 0.8, -r * 0.8),
        Paint()
          ..color = p.color
          ..strokeWidth = 1.6,
      );
    case Sign.star:
      final path = Path();
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8 - math.pi / 2;
        final rr = i.isEven ? r : r * 0.4;
        final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path..close(), p);
  }
}

/// Döndürülebilen yıldız taşı: ↑ ile bir sonraki işarete döner. Bütün
/// taşlar Aslan Horoskobu'ndaki sırayı gösterince en yakın kapı açılır.
class StarStone extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  StarStone(Vector2 cell, this.index, {Sign start = Sign.star})
    : sign = start,
      super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  final int index;
  Sign sign;
  double _turn = 0;

  bool get correct => index < horoscope.length && sign == horoscope[index];

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 26 && (p - position).y.abs() < 44;

  @override
  void use() {
    sign = Sign.values[(sign.index + 1) % Sign.values.length];
    _turn = 1;
    GameAudio.instance.play('grind', volume: 0.5);
    _check();
  }

  void _check() {
    final stones = game.world.children.whereType<StarStone>().toList();
    if (stones.every((s) => s.correct)) {
      GameAudio.instance.play('memory', volume: 0.7);
      game.narration.whisper(S.of('horoscope'));
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    _turn = math.max(0, _turn - dt * 3);
  }

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF2A2430);
    canvas.drawRect(const Rect.fromLTWH(-12, -10, 24, 10), stone);
    canvas.save();
    canvas.translate(0, -24);
    canvas.rotate(_turn * math.pi);
    canvas.drawCircle(Offset.zero, 13, stone);
    final ok = correct;
    final lit = Paint()
      ..color = ok ? const Color(0xFFFFE0A0) : const Color(0xFFC8C0D8);
    _drawSign(canvas, sign, Offset.zero, 8, lit);
    canvas.restore();
    if (ok) glowDot(canvas, const Offset(0, -24), 30, kWarmLight, 0.35);
  }
}

/// Aslan Horoskobu kabartması: gökteki doğru sırayı gösterir (süs ve ipucu).
class HoroscopeRelief extends PositionComponent
    with HasGameReference<GolgeGame> {
  HoroscopeRelief(Vector2 cell)
    : super(position: Vector2(cell.x, cell.y + kTile), priority: 2);

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    const w = 6 * kTile;
    const h = 4 * kTile;
    final slab = Paint()..color = const Color(0xFF231E2A);
    canvas.drawRect(const Rect.fromLTWH(0, -h, w, h), slab);
    // Aslan.
    final lion = Paint()..color = const Color(0xFF3A3242);
    canvas.drawOval(const Rect.fromLTWH(30, -60, 110, 34), lion);
    canvas.drawCircle(const Offset(145, -58), 18, lion);
    for (final x in [42.0, 62.0, 110.0, 128.0]) {
      canvas.drawRect(Rect.fromLTWH(x, -32, 9, 28), lion);
    }
    // Hilal aslanın göğsünde, yıldızlar ve gezegenler sırtında.
    final glow = 0.55 + 0.25 * math.sin(_t * 1.3);
    final mark = Paint()
      ..color = const Color(0xFFE8D8B0).withValues(alpha: glow);
    _drawSign(canvas, Sign.moon, const Offset(150, -36), 9, mark);
    for (var i = 1; i < horoscope.length; i++) {
      _drawSign(canvas, horoscope[i], Offset(40.0 + i * 30, -100), 8, mark);
    }
    for (var i = 0; i < 5; i++) {
      _drawSign(
        canvas,
        Sign.star,
        Offset(20 + i * 34.0, -78 + (i.isEven ? 0 : 8)),
        3.5,
        mark,
      );
    }
    // Kenar ve kar.
    canvas.drawRect(
      const Rect.fromLTWH(0, -h - 3, w, 4),
      Paint()..color = const Color(0xFFC8D2E2),
    );
  }
}

// ================================================================ Deprem

/// Gevşek kaya: depremde ya da altından geçilince düşer.
class LooseBoulder extends PositionComponent with HasGameReference<GolgeGame> {
  LooseBoulder(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile / 2),
        priority: 21,
      );

  double _shake = -1;
  double _vy = 0;
  bool _landed = false;
  double _gone = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) {
      _gone += dt;
      if (_gone > 1.2) removeFromParent();
      return;
    }
    if (_shake < 0) {
      final p = game.player;
      final under =
          p != null &&
          !p.isDead &&
          (p.center.x - position.x).abs() < 30 &&
          p.center.y > position.y;
      if (game.quake > 0.5 || under) _shake = 0;
      return;
    }
    _shake += dt;
    if (_shake < 0.35) return;
    _vy = math.min(_vy + 1900 * dt, 900);
    position.y += _vy * dt;
    final p = game.player;
    if (p != null &&
        !p.isDead &&
        p.toRect().inflate(4).contains(position.toOffset())) {
      p.die();
    }
    if (game.level.cellAt(position.x, position.y + 14) == '#' ||
        position.y > game.level.pixelHeight) {
      _landed = true;
      GameAudio.instance.play('crumble', volume: 0.6);
      game.shake(2);
    }
  }

  @override
  void render(Canvas canvas) {
    final j = _shake >= 0 && _shake < 0.35 ? math.sin(_shake * 70) * 2 : 0.0;
    final a = _landed ? (1 - _gone / 1.2).clamp(0.0, 1.0) : 1.0;
    final rock = Paint()..color = const Color(0xFF2A2430).withValues(alpha: a);
    canvas.drawPath(
      Path()
        ..moveTo(-13 + j, -6)
        ..lineTo(-4 + j, -14)
        ..lineTo(10 + j, -10)
        ..lineTo(14 + j, 4)
        ..lineTo(4 + j, 14)
        ..lineTo(-12 + j, 10)
        ..close(),
      rock,
    );
    canvas.drawLine(
      Offset(-8 + j, -10),
      Offset(8 + j, -12),
      Paint()
        ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.7 * a)
        ..strokeWidth = 2,
    );
  }
}

// ============================================================== Heykeller

/// Arazinin arkasında duran dev taş tanrı (oturan) ya da yere düşmüş başı.
/// Tırmanılacak dizler, kucak ve omuzlar haritada ayrıca `#` ile verilir.
class Colossus extends PositionComponent with HasGameReference<GolgeGame> {
  Colossus(Vector2 cell, {required this.kind})
    : super(
        // Oturan tanrının işareti omuzlarının üstündedir; çizim 9 kare
        // aşağıdaki zemine oturur.
        position: Vector2(cell.x, cell.y + kTile + (kind <= 1 ? 9 * kTile : 0)),
        priority: -1,
      );

  /// 0: oturan tanrı (başı yok), 1: oturan tanrı (başı yerinde),
  /// 2: düşmüş baş, 3: kartal, 4: aslan.
  final int kind;

  static final _stone = Paint()..color = const Color(0xFF1E1A26);
  static final _snow = Paint()..color = const Color(0xFFB8C2D4);

  @override
  void render(Canvas canvas) {
    switch (kind) {
      case 0 || 1:
        _god(canvas, headOn: kind == 1);
      case 2:
        _head(canvas, const Offset(48, 0), 1.0, tilt: -0.15);
      case 3:
        _bird(canvas);
      default:
        _lion(canvas);
    }
  }

  // Oturan tanrı: taht 4×4, gövde, omuzlar (toplam ~9 kare yüksek).
  void _god(Canvas canvas, {required bool headOn}) {
    const t = kTile;
    canvas.drawRect(const Rect.fromLTWH(0, -4 * t, 6 * t, 4 * t), _stone);
    // Dizler öne çıkar.
    canvas.drawRect(const Rect.fromLTWH(4 * t, -3 * t, 3 * t, t), _stone);
    canvas.drawPath(
      Path()
        ..moveTo(1 * t, -4 * t)
        ..lineTo(1.3 * t, -7.6 * t)
        ..quadraticBezierTo(3 * t, -8.2 * t, 4.7 * t, -7.6 * t)
        ..lineTo(5 * t, -4 * t)
        ..close(),
      _stone,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0.6 * t, -7.8 * t, 4.8 * t, 0.6 * t),
      _stone,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0.6 * t, -7.9 * t, 4.8 * t, 0.14 * t),
      _snow,
    );
    canvas.drawRect(
      const Rect.fromLTWH(4 * t, -3.1 * t, 3 * t, 0.12 * t),
      _snow,
    );
    if (headOn) {
      _head(canvas, const Offset(3 * t, -7.8 * t), 1.0);
    } else {
      canvas.drawRect(
        const Rect.fromLTWH(2.6 * t, -8.4 * t, 0.8 * t, 0.6 * t),
        _stone,
      );
    }
    // Tahtın arkasındaki nomos yazısından satırlar.
    final line = Paint()
      ..color = const Color(0xFF3A3446)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      canvas.drawLine(
        Offset(0.3 * t, -3.6 * t + i * 10),
        Offset(1.6 * t, -3.6 * t + i * 10),
        line,
      );
    }
  }

  void _head(Canvas canvas, Offset at, double s, {double tilt = 0}) {
    const t = kTile;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(tilt);
    canvas.scale(s);
    canvas.drawOval(
      const Rect.fromLTWH(-1.1 * t, -2.8 * t, 2.2 * t, 2.6 * t),
      _stone,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-0.9 * t, -1.2 * t)
        ..quadraticBezierTo(-0.8 * t, 0.1 * t, 0, 0.15 * t)
        ..quadraticBezierTo(0.8 * t, 0.1 * t, 0.9 * t, -1.2 * t)
        ..close(),
      _stone,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-1.15 * t, -2.4 * t)
        ..quadraticBezierTo(-1.0 * t, -4.6 * t, 0.2 * t, -5.4 * t)
        ..quadraticBezierTo(0.6 * t, -5.2 * t, 0.45 * t, -4.8 * t)
        ..quadraticBezierTo(1.0 * t, -3.6 * t, 1.15 * t, -2.4 * t)
        ..close(),
      _stone,
    );
    canvas.drawOval(
      Rect.fromLTWH(-0.6 * t, -5.1 * t, 0.9 * t, 0.22 * t),
      _snow,
    );
    canvas.restore();
  }

  void _bird(Canvas canvas) {
    const t = kTile;
    canvas.drawRect(const Rect.fromLTWH(0, -2 * t, 2.5 * t, 2 * t), _stone);
    canvas.drawPath(
      Path()
        ..moveTo(0.4 * t, -2 * t)
        ..quadraticBezierTo(0.2 * t, -4.6 * t, 1.3 * t, -5.3 * t)
        ..lineTo(1.9 * t, -5 * t)
        ..lineTo(1.5 * t, -4.6 * t)
        ..quadraticBezierTo(2.3 * t, -3.4 * t, 2.1 * t, -2 * t)
        ..close(),
      _stone,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, -2.05 * t, 2.5 * t, 0.12 * t),
      _snow,
    );
  }

  void _lion(Canvas canvas) {
    const t = kTile;
    canvas.drawRect(const Rect.fromLTWH(0, -2 * t, 2.5 * t, 2 * t), _stone);
    canvas.drawPath(
      Path()
        ..moveTo(0.2 * t, -2 * t)
        ..lineTo(0.3 * t, -4.3 * t)
        ..quadraticBezierTo(1.4 * t, -5.4 * t, 2.3 * t, -4.3 * t)
        ..lineTo(2.3 * t, -2 * t)
        ..close(),
      _stone,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, -2.05 * t, 2.5 * t, 0.12 * t),
      _snow,
    );
  }
}

// ======================================================== Taş dev Nemrud

/// Nemrud'un taş devi: terasta ağır ağır yürür, adımları yeri sarsar,
/// ayaklarının dibinde kalanı ezer. Kulağına bir ateşböceği (sivrisinek
/// gibi) girerse sendeler; üçüncüsünde yıkılır ve gövdesi köprü olur.
class StoneGiant extends PositionComponent with HasGameReference<GolgeGame> {
  StoneGiant(Vector2 cell)
    : _home = cell.x,
      super(
        position: Vector2(cell.x, cell.y + kTile),
        size: Vector2(5 * kTile, 9 * kTile),
        priority: 16,
      );

  static const double span = 11 * kTile;
  static const int hitsToFall = 3;

  final double _home;
  double _t = 0;
  double _stagger = 0;
  int hits = 0;
  bool fallen = false;
  double _fallT = 0;
  int _dir = 1;
  double _lastStep = 0;

  /// Kulağın dünyadaki yeri.
  Vector2 get ear => Vector2(
    position.x + size.x * 0.5 + _dir * 22,
    position.y - size.y * 0.78,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (fallen) {
      _fallT = math.min(1, _fallT + dt * 0.7);
      return;
    }
    if (_stagger > 0) {
      _stagger -= dt;
      return;
    }
    // Ağır adımlar: iki nokta arasında gidip gelir.
    position.x += _dir * 26 * dt;
    if (position.x > _home + span) _dir = -1;
    if (position.x < _home) _dir = 1;
    final p = game.player;
    if (_t - _lastStep > 1.1) {
      _lastStep = _t;
      // Adımlar yakında duyulur ve sarsar; uzaktan yalnızca hafif bir gümbürtü.
      final near = p == null || p.isDead
          ? 0.0
          : (1 - (p.center - position).length / (24 * kTile)).clamp(0.0, 1.0);
      if (near > 0) {
        GameAudio.instance.play('land', volume: 0.9 * near);
        game.shake(4 * near);
        game.quake = math.max(game.quake, 0.6 * near);
      }
    }
    if (p != null && !p.isDead) {
      // Ayakların dibi ezer.
      final feet = Rect.fromLTWH(position.x, position.y - 28, size.x, 28);
      if (p.toRect().overlaps(feet)) p.die();
    }
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position - ear).length < 46) {
        l.removeFromParent();
        hits++;
        _stagger = 2.4;
        GameAudio.instance.play('grind');
        game.shake(6);
        if (hits >= hitsToFall) {
          fallen = true;
          GameAudio.instance.play('crumble');
          game.narration.whisper(S.of('giantFell'));
          game.world.add(
            GiantBridge(Vector2(position.x - kTile, position.y - kTile * 1.2)),
          );
          // Devin düşüşü ilerideki (çıkışa doğru) kapıyı kırar.
          Gate? best;
          var bestD = double.infinity;
          for (final g in game.world.children.whereType<Gate>()) {
            final dd = (g.position - position).length;
            if (g.position.x > position.x && dd < bestD && !g.opening) {
              bestD = dd;
              best = g;
            }
          }
          best?.opening = true;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF241E2C);
    final w = size.x;
    final h = size.y;
    canvas.save();
    if (fallen) {
      canvas.translate(w / 2, 0);
      canvas.rotate(-_fallT * math.pi / 2 * _dir);
      canvas.translate(-w / 2, 0);
    } else if (_stagger > 0) {
      canvas.translate(math.sin(_t * 40) * 3, 0);
    }
    final step = math.sin(_t * 2.9) * 6;
    // Bacaklar.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.18 + step, h - h * 0.32, w * 0.22, h * 0.32),
      stone,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.6 - step, h - h * 0.32, w * 0.22, h * 0.32),
      stone,
    );
    // Gövde, omuzlar, kollar.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.12, h * 0.32, w * 0.76, h * 0.38),
      stone,
    );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.3, w, h * 0.08), stone);
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.06, h * 0.34, w * 0.14, h * 0.32),
      stone,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.92, h * 0.34, w * 0.14, h * 0.32),
      stone,
    );
    // Baş ve sivri külah.
    canvas.drawOval(Rect.fromLTWH(w * 0.3, h * 0.12, w * 0.4, h * 0.2), stone);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, h * 0.16)
        ..quadraticBezierTo(w * 0.34, -h * 0.02, w * 0.56, -h * 0.06)
        ..lineTo(w * 0.62, -h * 0.02)
        ..quadraticBezierTo(w * 0.7, h * 0.08, w * 0.7, h * 0.16)
        ..close(),
      stone,
    );
    // Gözler: soluk ateş.
    final eye = Paint()
      ..color = const Color(0xFFFFB070).withValues(alpha: fallen ? 0 : 0.8);
    canvas.drawOval(Rect.fromLTWH(w * 0.4, h * 0.2, 7, 3), eye);
    canvas.drawOval(Rect.fromLTWH(w * 0.54, h * 0.2, 7, 3), eye);
    canvas.restore();
    if (!fallen) {
      // Kulak: ateşböceğinin girmesi gereken yer, hafifçe parlar.
      final e = ear - position;
      glowDot(
        canvas,
        e.toOffset(),
        16,
        kWarmLight,
        0.25 + 0.15 * math.sin(_t * 4),
      );
    }
  }
}

/// Yıkılan devin gövdesi: üstünden geçilen bir köprü.
class GiantBridge extends Deck {
  GiantBridge(Vector2 at) : super(position: at, size: Vector2(9 * kTile, 16));

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF241E2C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 22),
        const Radius.circular(8),
      ),
      stone,
    );
    canvas.drawLine(
      const Offset(4, 1.5),
      Offset(size.x - 4, 1.5),
      Paint()
        ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
  }
}

/// Bölümün depremi: ara ara yer sarsılır, gevşek kayalar düşer.
class QuakeClock extends Component with HasGameReference<GolgeGame> {
  double _t = 5;

  @override
  void update(double dt) {
    game.quake = math.max(0, game.quake - dt * 0.7);
    _t -= dt;
    if (_t <= 0) {
      _t = 11 + math.sin(game.levelIndex * 3.0 + _t) * 2;
      game.quake = 1;
      game.shake(7);
      GameAudio.instance.play('grind', volume: 0.9);
      GameAudio.instance.play('crumble', volume: 0.6);
    }
  }
}
