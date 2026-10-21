import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'persist.dart';
import 'puzzles.dart';
import 'rig.dart';
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
    with HasGameReference<GolgeGame>, Usable, Persistent {
  StarStone(Vector2 cell, this.index, {Sign start = Sign.star})
    : sign = start,
      super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  final int index;
  Sign sign;
  double _turn = 0;

  @override
  String get persistKind => 'star';

  @override
  Object? captureState() => sign.index;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state is int && state >= 0 && state < Sign.values.length) {
      sign = Sign.values[state];
    }
    return [this];
  }

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
      game.once('horoscope', S.of('horoscope'));
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
class StoneGiant extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  StoneGiant(Vector2 cell)
    : _home = cell.x,
      super(
        position: Vector2(cell.x, cell.y + kTile),
        size: Vector2(5 * kTile, 9 * kTile),
        // Konum ayakların yeridir (kulak, ezme alanı ve köprü buna göre):
        // çizim de oradan yukarı uzanır. Önceden sol üst köşe sayıldığı için
        // dev toprağın içine çiziliyordu.
        anchor: Anchor.bottomLeft,
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

  /// Yürüyüş evresi: yalnızca yürürken ilerler. Bacaklar ve adım sesi aynı
  /// evreden çıkar; ayak yere bastığı anda gümbürtü duyulur.
  double _walk = 0;
  int _stepN = 0;
  static const double _stepRate = 2.9;

  /// Basan ayağın tozu (yerel x, yaş) ve yıkılışın yere çarpışı.
  final _dust = <(double, double)>[];
  bool _impact = false;

  /// Temasta başın kulaktan kaçışı (yay: çeker, geri gelir).
  final _flinch = Spring(stiffness: 55, damping: 5);

  @override
  String get persistKind => 'giant';

  @override
  Object? captureState() => hits == 0 ? null : [hits, fallen ? 1 : 0];

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    final s = numbers(state, 2);
    if (s == null) return [this];
    hits = s[0].round().clamp(0, hitsToFall);
    if (s[1] != 1) return [this];
    // Yıkılmış dev yatar; gövdesi köprüdür.
    fallen = true;
    hits = hitsToFall;
    _fallT = 1;
    _impact = true;
    return [this, GiantBridge(_bridgeAt)];
  }

  Vector2 get _bridgeAt =>
      Vector2(position.x + size.x / 2, position.y - kTile * 1.2);

  /// Kulağın dünyadaki yeri.
  Vector2 get ear => Vector2(
    position.x + size.x * 0.5 + _dir * 22,
    position.y - size.y * 0.78,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flinch.update(0, dt);
    for (var i = _dust.length - 1; i >= 0; i--) {
      final (x, age) = _dust[i];
      if (age + dt > 1.4) {
        _dust.removeAt(i);
      } else {
        _dust[i] = (x, age + dt);
      }
    }
    if (fallen) {
      _fallT = math.min(1, _fallT + dt * 0.7);
      if (_fallT >= 1 && !_impact) {
        // Gövde yere çarpar: toz, sarsıntı, gümbürtü.
        _impact = true;
        game.shake(12);
        GameAudio.instance.play('land');
        for (var k = 0; k < 7; k++) {
          _dust.add((size.x * 0.5 + (k - 3) * 40.0, 0));
        }
      }
      return;
    }
    if (_stagger > 0) {
      _stagger -= dt;
      return;
    }
    // Ağır adımlar: iki nokta arasında gidip gelir.
    position.x += _dir * 26 * dt;
    _walk += dt;
    if (position.x > _home + span) _dir = -1;
    if (position.x < _home) _dir = 1;
    final p = game.player;
    // Bacak sin(evre) ile gidip gelir: uçlarda (her yarım dönüşte) ayak
    // yere oturur.
    final n = ((_walk * _stepRate + math.pi / 2) / math.pi).floor();
    if (n != _stepN) {
      _stepN = n;
      // Basan ayağın altında toz kalkar.
      _dust.add((size.x * (n.isOdd ? 0.36 : 0.64) + _dir * 14, 0));
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
        _flinch.kick(-_dir * 9);
        GameAudio.instance.play('grind');
        GameAudio.instance.play('growl', volume: 0.7);
        game.shake(6 + hits * 2.0);
        if (hits < hitsToFall) {
          // Kaç ışık kaldığını söyler (sol üstte kısa bir not).
          game.narration.hint(
            S.of(hits == 1 ? 'giantHit1' : 'giantHit2'),
            queue: true,
          );
        }
        if (hits >= hitsToFall) {
          fallen = true;
          GameAudio.instance.play('crumble');
          game.once('giantFell', S.of('giantFell'));
          // Yatan gövdenin üstü köprü olur (gövde sağa, ayaklarından uzanır).
          game.world.add(GiantBridge(_bridgeAt));
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

  static final _stone = Paint()..color = const Color(0xFF241E2C);
  static final _edge = Paint()
    ..color = const Color(0xFF4A4058)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final _seam = Paint()
    ..color = const Color(0xFF15111A)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  /// [a]dan [b]ye uzanan, köşeleri kırık bir taş blok; üst kenarında soluk
  /// ışık, ortasında derz.
  void _block(
    Canvas canvas,
    Offset a,
    Offset b,
    double width, {
    double chip = 0.2,
  }) {
    final d = b - a;
    final len = d.distance;
    if (len < 0.01) return;
    final u = d / len;
    final n = Offset(-u.dy, u.dx) * (width / 2);
    final c = math.min(width, len) * chip;
    final p = Path()
      ..moveTo((a + n + u * c).dx, (a + n + u * c).dy)
      ..lineTo((b + n - u * c * 0.6).dx, (b + n - u * c * 0.6).dy)
      ..lineTo((b + n * 0.55).dx, (b + n * 0.55).dy)
      ..lineTo((b - n * 0.8).dx, (b - n * 0.8).dy)
      ..lineTo((b - n - u * c).dx, (b - n - u * c).dy)
      ..lineTo((a - n + u * c * 0.5).dx, (a - n + u * c * 0.5).dy)
      ..lineTo((a - n * 0.6).dx, (a - n * 0.6).dy)
      ..lineTo((a + n * 0.7).dx, (a + n * 0.7).dy)
      ..close();
    canvas.drawPath(p, _stone);
    // Işığa bakan kenar (sol üst) ve ortadaki derz.
    final lit = n.dx < 0 || n.dy < 0 ? n : -n;
    canvas.drawLine(a + lit * 0.85 + u * c, b + lit * 0.85 - u * c, _edge);
    canvas.drawLine(
      a + u * (len * 0.5) - n * 0.6,
      a + u * (len * 0.5) + n * 0.6,
      _seam,
    );
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Ayak dibindeki toz (devrilse de yerinde kalır).
    final dust = Paint();
    for (final (x, age) in _dust) {
      final k = age / 1.4;
      dust.color = const Color(0xFFB8A890).withValues(alpha: 0.35 * (1 - k));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, h - 4 - k * 10),
          width: 30 + k * 60,
          height: 8 + k * 14,
        ),
        dust,
      );
    }
    canvas.save();
    // Yıkılış: önce dizler çöker, sonra gövde öne devrilir ve ağırlaşarak
    // yere çarpar. Son hâli köprüyle aynı hizada yatan bir taş yığını.
    final buckle = fallen ? (_fallT / 0.3).clamp(0.0, 1.0) : 0.0;
    final topple = fallen ? ((_fallT - 0.2) / 0.8).clamp(0.0, 1.0) : 0.0;
    final f = topple * topple;
    if (fallen) {
      final k = 1 - 0.68 * f;
      canvas.translate(w / 2, h - w * k / 2 * f);
      canvas.rotate(f * math.pi / 2);
      canvas.scale(k, 1);
      canvas.translate(-w / 2, -h);
    }
    final stung = !fallen && _stagger > 0 ? (_stagger / 2.4) : 0.0;
    // Adım: ağırlık basan bacağa geçer, öbürü kalkıp öne gelir.
    final walking = !fallen && _stagger <= 0;
    final s =
        ((_walk * _stepRate - math.pi / 2) % (2 * math.pi) + 2 * math.pi) %
        (2 * math.pi);
    final swingA = s < math.pi;
    final half = (s % math.pi) / math.pi; // salınımın ne kadarı
    final lift = math.sin(half * math.pi);
    const reach = 15.0;
    // Kalça: basan ayağın üstüne kayar, basışta çöker.
    final sway = (swingA ? 1 : -1) * 5.0 * lift;
    final bob = -4 * lift + buckle * h * 0.14;
    final hipY = h * 0.68 + bob;
    final hipA = Offset(w * 0.36 + sway, hipY);
    final hipB = Offset(w * 0.64 + sway, hipY);
    double planted(double t) => _dir * reach * (1 - 2 * t);
    double swung(double t) =>
        _dir * reach * (-1 + 2 * (0.5 - math.cos(t * math.pi) / 2));
    final footA = Offset(
      w * 0.36 +
          (walking ? (swingA ? swung(half) : planted(half)) : 0) -
          buckle * 10,
      h - (walking && swingA ? lift * 16 : 0),
    );
    final footB = Offset(
      w * 0.64 +
          (walking ? (!swingA ? swung(half) : planted(half)) : 0) +
          buckle * 10,
      h - (walking && !swingA ? lift * 16 : 0),
    );
    // Dizler yürüme yönüne kırılır (yıkılırken öne çöker).
    final bend = _dir.toDouble();
    for (final (hip, foot) in [(hipA, footA), (hipB, footB)]) {
      final (knee, end) = solveLimb(
        hip,
        foot,
        h * 0.175,
        h * 0.175,
        bend: bend,
      );
      _block(canvas, hip, knee, w * 0.17);
      _block(canvas, knee, end.translate(0, -h * 0.03), w * 0.15);
      _block(
        canvas,
        end.translate(-w * 0.1, -h * 0.018),
        end.translate(w * 0.1, -h * 0.018),
        h * 0.036,
        chip: 0.1,
      );
    }
    // Leğen ve gövde: genişleyen göğüs, kırık omuz taşları.
    _block(
      canvas,
      Offset(w * 0.24 + sway, hipY),
      Offset(w * 0.76 + sway, hipY),
      h * 0.08,
    );
    final chest = h * 0.34 + bob * 0.8;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22 + sway, hipY - h * 0.02)
        ..lineTo(w * 0.1 + sway * 0.7, chest)
        ..lineTo(w * 0.16 + sway * 0.7, chest - h * 0.03)
        ..lineTo(w * 0.84 + sway * 0.7, chest - h * 0.03)
        ..lineTo(w * 0.9 + sway * 0.7, chest)
        ..lineTo(w * 0.78 + sway, hipY - h * 0.02)
        ..close(),
      _stone,
    );
    canvas.drawLine(
      Offset(w * 0.16 + sway * 0.7, chest - h * 0.025),
      Offset(w * 0.84 + sway * 0.7, chest - h * 0.025),
      _edge,
    );
    // Göğüs taşlarının derzleri.
    for (final y in [0.43, 0.52, 0.6]) {
      canvas.drawLine(
        Offset(w * 0.2 + sway * 0.8, h * y + bob * 0.8),
        Offset(w * 0.8 + sway * 0.8, h * y + bob * 0.8),
        _seam,
      );
    }
    // Kollar: yürürken bacakların tersine sallanır; temas anında kulak
    // tarafındaki el kulağa gider, öbürü dengeyi toplar.
    final swat = stung > 0
        ? math.sin(math.min(1, (1 - stung) * 3) * math.pi / 2)
        : 0.0;
    final headC = Offset(
      w * 0.5 + _flinch.value + sway * 0.6,
      h * 0.22 + bob * 0.7,
    );
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(
        w * (0.5 + side * 0.4) + sway * 0.7,
        chest + h * 0.01,
      );
      final armSwing = walking ? (swingA ? 1 : -1) * side * lift * 10 : 0.0;
      var hand = Offset(
        shoulder.dx + side * 6 + armSwing * _dir,
        h * 0.66 + bob * 0.5,
      );
      if (side == _dir && swat > 0) {
        hand = Offset.lerp(hand, headC + Offset(side * 30, 6), swat)!;
      } else if (stung > 0) {
        hand = hand.translate(side * 14 * stung, -12 * stung);
      }
      if (buckle > 0) {
        hand = hand.translate(side * 10 * buckle, -h * 0.05 * buckle);
      }
      final (elbow, end) = solveLimb(
        shoulder,
        hand,
        h * 0.17,
        h * 0.16,
        bend: side,
      );
      _block(canvas, shoulder, elbow, w * 0.15);
      _block(canvas, elbow, end, w * 0.13);
      _block(
        canvas,
        shoulder.translate(-w * 0.07, -h * 0.01),
        shoulder.translate(w * 0.07, -h * 0.01),
        h * 0.05,
        chip: 0.25,
      );
    }
    // Baş: kulaktan kaçar (temas), sonra yerine döner; Nemrut heykellerinin
    // sivri külahı.
    canvas.save();
    canvas.translate(headC.dx, headC.dy + h * 0.08);
    canvas.rotate(_flinch.value * 0.012 - _dir * swat * 0.12);
    canvas.translate(-headC.dx, -headC.dy - h * 0.08);
    final hx = headC.dx;
    final hy = headC.dy;
    canvas.drawPath(
      Path()
        ..moveTo(hx - w * 0.17, hy - h * 0.05)
        ..lineTo(hx - w * 0.19, hy + h * 0.03)
        ..lineTo(hx - w * 0.12, hy + h * 0.1)
        ..lineTo(hx + w * 0.12, hy + h * 0.1)
        ..lineTo(hx + w * 0.19, hy + h * 0.03)
        ..lineTo(hx + w * 0.17, hy - h * 0.05)
        ..close(),
      _stone,
    );
    // Külah: öne kıvrık uç.
    canvas.drawPath(
      Path()
        ..moveTo(hx - w * 0.19, hy - h * 0.04)
        ..quadraticBezierTo(
          hx - w * 0.15,
          hy - h * 0.2,
          hx + w * 0.06,
          hy - h * 0.25,
        )
        ..lineTo(hx + w * 0.12, hy - h * 0.21)
        ..quadraticBezierTo(
          hx + w * 0.2,
          hy - h * 0.1,
          hx + w * 0.19,
          hy - h * 0.04,
        )
        ..close(),
      _stone,
    );
    canvas.drawLine(
      Offset(hx - w * 0.19, hy - h * 0.045),
      Offset(hx + w * 0.19, hy - h * 0.045),
      _edge,
    );
    // Gözler: soluk ateş; her temasta söner, sendelerken titrer.
    final flicker = stung > 0 ? (0.5 + 0.5 * math.sin(_t * 30)) : 1.0;
    final eye = Paint()
      ..color = const Color(0xFFFFB070).withValues(
        alpha: fallen ? 0 : (0.8 - hits * 0.22).clamp(0.0, 1.0) * flicker,
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hx - w * 0.07, hy + h * 0.005),
        width: 9,
        height: 3.4,
      ),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hx + w * 0.07, hy + h * 0.005),
        width: 9,
        height: 3.4,
      ),
      eye,
    );
    canvas.restore();
    // Çatlaklar: her temasta yenisi açılır, içinden kor gibi ışık sızar.
    if (hits > 0) _cracks(canvas, w, h);
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

/// Temas sayısına göre devin çatlakları (yerel koordinatta, oranla).
const _crackLines = [
  // 1. temas: başta ve omuzda
  [
    Offset(0.46, 0.14),
    Offset(0.5, 0.2),
    Offset(0.47, 0.26),
    Offset(0.52, 0.31),
  ],
  [Offset(0.2, 0.31), Offset(0.27, 0.38), Offset(0.24, 0.45)],
  // 2. temas: gövde boyunca
  [Offset(0.62, 0.33), Offset(0.56, 0.42), Offset(0.6, 0.5), Offset(0.54, 0.6)],
  [Offset(0.3, 0.45), Offset(0.38, 0.52), Offset(0.34, 0.62)],
  // 3. temas (yıkılırken): bacaklara iner
  [Offset(0.5, 0.6), Offset(0.45, 0.7), Offset(0.5, 0.8), Offset(0.46, 0.92)],
];

extension on StoneGiant {
  void _cracks(Canvas canvas, double w, double h) {
    final n = math.min(_crackLines.length, hits * 2 + (fallen ? 1 : 0));
    final glow = Paint()
      ..color = const Color(0xFFFF9A40).withValues(alpha: fallen ? 0.25 : 0.55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final core = Paint()
      ..color = const Color(0xFFFFE0A0).withValues(alpha: fallen ? 0.3 : 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final pts = _crackLines[i];
      final path = Path()..moveTo(pts.first.dx * w, pts.first.dy * h);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx * w, p.dy * h);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
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
