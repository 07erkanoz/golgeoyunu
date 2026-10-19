import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'creatures.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'perde.dart';
import 'player.dart';
import 'strings.dart';

/// Yanına gelinip ↑ ile kullanılan düzenekler (vana, ayna).
mixin Usable on PositionComponent {
  bool canUse(Vector2 p);
  void use();
}

// ======================================================= Işık ve gölge yolu

/// Işıkta ve gölgede beliren tahtalar. Işık tahtası yalnızca ışık değince
/// katıdır (açık kavanoz, ateşböceği, fener, huzme). Gölge tahtası tersine
/// yalnızca karanlıkta katıdır: üstünden ancak çömelip kavanozun ışığını
/// saklayarak geçilir.
class PhasePlank extends Deck {
  PhasePlank(Vector2 cell, int tiles, {required this.shade})
    : super(
        position: Vector2(cell.x, cell.y),
        size: Vector2(tiles * kTile, 10),
      );

  final bool shade;
  bool _on = false;
  double _show = 0;
  double _t = math.Random().nextDouble() * 5;

  @override
  bool get active => _on;

  @override
  void step(double dt) {
    _t += dt;
    var lit = false;
    for (var x = 6.0; x < size.x; x += kTile) {
      if (game.litAt(position + Vector2(x, 4))) {
        lit = true;
        break;
      }
    }
    final want = shade ? !lit : lit;
    // Biraz gecikmeli: ışık kenarında titreyip durmasın.
    if (want != _on) {
      _hold += dt;
      if (_hold > (want ? 0.08 : 0.2)) {
        _on = want;
        _hold = 0;
      }
    } else {
      _hold = 0;
    }
    _show += ((_on ? 1.0 : 0.0) - _show) * math.min(1, dt * 8);
  }

  double _hold = 0;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    if (shade) {
      // Mürekkep gibi koyu tahta; ışıkta duman olup dağılır.
      final ink = Paint()..color = kInk.withValues(alpha: 0.15 + 0.85 * _show);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, 9),
          const Radius.circular(3),
        ),
        ink,
      );
      // Gölgede belli belirsiz soğuk bir kenar: yerini ele verir.
      canvas.drawLine(
        const Offset(2, 0.8),
        Offset(w - 2, 0.8),
        Paint()
          ..color = const Color(0xFF9AB8C8).withValues(alpha: 0.25 * _show)
          ..strokeWidth = 1.2,
      );
      if (_show < 0.9) {
        final smoke = Paint()
          ..color = kInk.withValues(alpha: 0.35 * (1 - _show));
        for (var x = 8.0; x < w; x += 14) {
          final rise = (_t * 12 + x) % 18;
          canvas.drawCircle(Offset(x, -rise), 3 + rise * 0.2, smoke);
        }
      }
    } else {
      // Işık tahtası: sönükken yalnızca noktalı bir iz, ışıkta parlar.
      if (_show < 0.98) {
        final dot = Paint()..color = kWarmLight.withValues(alpha: 0.18);
        for (var x = 4.0; x < w; x += 8) {
          canvas.drawCircle(Offset(x, 4), 1.1, dot);
        }
      }
      if (_show > 0.02) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, 8),
            const Radius.circular(3),
          ),
          Paint()
            ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 8), [
              const Color(0xFFFFE6B0).withValues(alpha: 0.85 * _show),
              const Color(0xFFE0A15F).withValues(alpha: 0.5 * _show),
            ]),
        );
        for (var x = 10.0; x < w; x += 22) {
          final mote = math.sin(_t * 2 + x) * 3;
          canvas.drawCircle(
            Offset(x, -4 + mote),
            1.2,
            Paint()..color = kWarmLight.withValues(alpha: 0.6 * _show),
          );
        }
      }
    }
  }
}

// ============================================================ Çürük tahta

/// Çürümüş iskele tahtası: Sâye'yi taşır, ağır bir Kandilci'yi taşımaz.
/// Kandilci devriyede üstüne çıkmaz; ancak bir sese ya da ateşböceğine
/// yönelince basar ve tahta çöker.
class RottenPlank extends Deck {
  RottenPlank(this.col, this.row, this.tiles)
    : super(
        position: Vector2(col * kTile, row * kTile.toDouble()),
        size: Vector2(tiles * kTile, 10),
      );

  final int col;
  final int row;
  final int tiles;
  bool broken = false;
  double _fall = 0;
  double _creak = 0;

  @override
  bool get active => !broken;

  @override
  void step(double dt) {
    if (broken) {
      _fall += dt;
      if (_fall > 2) removeFromParent();
      return;
    }
    final p = game.player;
    if (p != null && p.riding == this && p.velocity.x.abs() > 20) {
      _creak -= dt;
      if (_creak <= 0) {
        _creak = 0.7;
        GameAudio.instance.play('creak', volume: 0.5);
      }
    }
    for (final g in game.world.children.whereType<Guard>()) {
      final feet = g.position.y + Guard.gh;
      final cx = g.center.x;
      if ((feet - position.y).abs() < 6 &&
          cx > position.x + 4 &&
          cx < position.x + size.x - 4) {
        _break(g);
        return;
      }
    }
  }

  void _break(Guard g) {
    broken = true;
    for (var c = col; c < col + tiles; c++) {
      game.level.clearCell(c, row);
    }
    GameAudio.instance.play('crumble');
    GameAudio.instance.play('creak');
    g.fall();
    game.shake(3);
  }

  @override
  void render(Canvas canvas) {
    final wood = Paint()..color = const Color(0xFF1A0F0A);
    final crack = Paint()
      ..color = kInk
      ..strokeWidth = 1.2;
    if (!broken) {
      for (var i = 0; i < tiles; i++) {
        final x = i * kTile.toDouble();
        canvas.drawRect(Rect.fromLTWH(x + 1, 0, kTile - 3, 7), wood);
        canvas.drawLine(Offset(x + 8, 0), Offset(x + 13, 7), crack);
        canvas.drawLine(Offset(x + 21, 1), Offset(x + 18, 6), crack);
      }
      // Sarkan kopuk ip.
      canvas.drawLine(
        const Offset(2, 7),
        const Offset(-2, 20),
        Paint()
          ..color = const Color(0xFF1A0F0A)
          ..strokeWidth = 1,
      );
      return;
    }
    // İki parça dönerek düşer.
    final a = (1 - _fall / 2).clamp(0.0, 1.0);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(
        size.x / 2 + side * (size.x / 4 + _fall * 20),
        _fall * _fall * 260,
      );
      canvas.rotate(side * _fall * 2.2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size.x / 2 - 2, height: 7),
        Paint()..color = const Color(0xFF1A0F0A).withValues(alpha: a),
      );
      canvas.restore();
    }
  }
}

// ============================================================== Su haznesi

/// Vanalarla dolup boşalan su haznesi. Suyun içinde kalan boğulur; yüzen
/// tahta suyun yüzünde durur ve üstündekini taşır.
class WaterBasin extends Component with HasGameReference<GolgeGame> {
  WaterBasin(this.area, {required double start})
    : surface = start,
      target = start,
      super(priority: 26);

  final Rect area;
  double surface;
  double target;
  double _delay = 0;
  double _t = 0;

  /// Suyun yükselip alçalma hızı; tufanda daha yavaş ama durmaz.
  double speed = 30;

  /// Tufan başladı mı (bir daha durmaz).
  bool flooding = false;

  void startFlood({double rate = 30}) {
    if (flooding) return;
    flooding = true;
    speed = rate;
    setTarget(high, delay: 1.2);
    GameAudio.instance.play('breath', volume: 0.5);
    game.shake(4);
  }

  double get low => area.bottom - 6;
  double get high => area.top + kTile;
  bool get moving => (surface - target).abs() > 0.5;

  void setTarget(double y, {double delay = 0}) {
    target = y.clamp(high, low);
    _delay = delay;
    GameAudio.instance.play('splash', volume: 0.5);
  }

  bool covers(Vector2 p) =>
      p.x > area.left && p.x < area.right && p.y > surface && p.y < area.bottom;

  @override
  void update(double dt) {
    _t += dt;
    if (_delay > 0) {
      _delay -= dt;
    } else if (moving) {
      final step = speed * dt;
      surface = (surface - target).abs() <= step
          ? target
          : surface + step * (target > surface ? 1 : -1);
    }
    final p = game.player;
    if (p != null && !p.isDead && covers(p.center + Vector2(0, -4))) {
      p.die(cause: DeathCause.water);
    }
  }

  @override
  void render(Canvas canvas) {
    final body = Rect.fromLTRB(area.left, surface, area.right, area.bottom);
    if (body.height <= 0) return;
    canvas.drawRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(body.topLeft, body.bottomLeft, [
          const Color(0xFF2A160E).withValues(alpha: 0.85),
          const Color(0xFF0C0605).withValues(alpha: 0.95),
        ]),
    );
    // Yüzeyde ışıltılı halkalar; su hareket ederken çalkalanır.
    final line = Paint()
      ..color = const Color(0xFFE19A5A).withValues(alpha: moving ? 0.4 : 0.22)
      ..strokeWidth = 1.2;
    for (var x = area.left + 6; x < area.right - 6; x += 18) {
      final wob = math.sin(_t * (moving ? 6 : 2) + x * 0.13) * (moving ? 2 : 1);
      canvas.drawLine(
        Offset(x, surface + 1 + wob),
        Offset(x + 9, surface + 1 + wob),
        line,
      );
    }
  }
}

/// Su haznesinin yüzünde duran tahta.
class FloatPlank extends Deck {
  FloatPlank(Vector2 cell, this.basin)
    : super(
        position: Vector2(cell.x, basin.surface - 6),
        size: Vector2(kTile * 2, 10),
      );

  final WaterBasin basin;
  double _t = 0;

  @override
  void step(double dt) {
    _t += dt;
    final bob = basin.moving ? 0.0 : math.sin(_t * 1.6) * 1.2;
    moveTo(Vector2(position.x, basin.surface - 6 + bob));
  }

  @override
  void render(Canvas canvas) {
    final wood = Paint()..color = const Color(0xFF1C110B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 9),
        const Radius.circular(2),
      ),
      wood,
    );
    canvas.drawLine(
      const Offset(2, 1),
      Offset(size.x - 2, 1),
      Paint()
        ..color = const Color(0xFFD08A5A).withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }
}

/// Su vanası: haznenin suyunu boşaltır (`v`) ya da doldurur (`y`).
class Valve extends PositionComponent with HasGameReference<GolgeGame>, Usable {
  Valve(Vector2 cell, {required this.fill})
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  final bool fill;
  double _spin = 0;
  double _turn = 0;

  WaterBasin? get _basin {
    WaterBasin? best;
    var bestD = double.infinity;
    for (final b in game.world.children.whereType<WaterBasin>()) {
      final d = (b.area.center.dx - position.x).abs();
      if (d < bestD) {
        bestD = d;
        best = b;
      }
    }
    return best;
  }

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 26 && (p - position).y.abs() < 40;

  @override
  void use() {
    final b = _basin;
    if (b == null) return;
    _turn = 1;
    GameAudio.instance.play('gate', volume: 0.6);
    // Dolarken su bir an gurlar, sonra yükselir: tahtaya binmeye vakit kalır.
    b.setTarget(fill ? b.high : b.low, delay: fill ? 1.3 : 0.3);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_turn > 0) {
      _turn = math.max(0, _turn - dt * 0.8);
      _spin += dt * 9 * _turn;
    }
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    // Boru ve çark.
    canvas.drawRect(const Rect.fromLTWH(-3, -14, 6, 14), ink);
    canvas.save();
    canvas.translate(0, -18);
    canvas.rotate(_spin);
    final rim = Paint()
      ..color = const Color(0xFF2A1A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(Offset.zero, 8, rim);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a) * 8, math.sin(a) * 8),
        rim..strokeWidth = 1.6,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      const Offset(0, -18),
      1.6,
      Paint()
        ..color = (fill ? const Color(0xFF7FB8D0) : const Color(0xFFD08A5A))
            .withValues(alpha: 0.8),
    );
  }
}

// ================================================================== Ayna

/// Döndürülebilen ayna: huzmeyi 90° kırar. ↑ ile `/` ve `\` arasında döner.
class Mirror extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  Mirror(Vector2 cell, {this.slash = true})
    : col = (cell.x / kTile).round(),
      row = (cell.y / kTile).round(),
      super(position: cell + Vector2.all(kTile / 2), priority: 19);

  final int col;
  final int row;

  /// true: `/` (aşağı gelen huzmeyi sola atar), false: `\`.
  bool slash;
  double _angle = 0;

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 34 && (p - position).y.abs() < 46;

  @override
  void use() {
    slash = !slash;
    GameAudio.instance.play('lever', volume: 0.7);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = slash ? -math.pi / 4 : math.pi / 4;
    _angle += (target - _angle) * math.min(1, dt * 10);
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    // Ayak.
    canvas.drawRect(const Rect.fromLTWH(-2, 6, 4, 10), ink);
    canvas.drawRect(const Rect.fromLTWH(-7, 14, 14, 3), ink);
    canvas.save();
    canvas.rotate(_angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, -3, 30, 6),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawLine(
      const Offset(-13, -2.5),
      const Offset(13, -2.5),
      Paint()
        ..color = const Color(0xFFF2E6D0).withValues(alpha: 0.75)
        ..strokeWidth = 1.6,
    );
    canvas.restore();
  }
}

/// Işık kilidi: güneş oymalı taş. Huzme bir süre üstünde kalınca en yakın
/// kapı açılır.
class SunLock extends PositionComponent with HasGameReference<GolgeGame> {
  SunLock(Vector2 cell)
    : col = (cell.x / kTile).round(),
      row = (cell.y / kTile).round(),
      super(position: cell + Vector2.all(kTile / 2), priority: 18);

  final int col;
  final int row;
  double charge = 0;
  bool open = false;
  bool lit = false;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (open) return;
    charge = lit ? math.min(1, charge + dt / 0.8) : math.max(0, charge - dt);
    if (charge >= 1) {
      open = true;
      GameAudio.instance.play('memory', volume: 0.6);
      GameAudio.instance.play('gate', volume: 0.7);
      Gate? best;
      var bestD = double.infinity;
      for (final g in game.world.children.whereType<Gate>()) {
        final d = (g.position - position).length;
        if (d < bestD) {
          bestD = d;
          best = g;
        }
      }
      best?.opening = true;
    }
    lit = false;
  }

  @override
  void render(Canvas canvas) {
    final glow = open ? 1.0 : charge;
    if (glow > 0) {
      glowDot(canvas, Offset.zero, 30, kWarmLight, 0.45 * glow);
    }
    canvas.drawCircle(Offset.zero, 11, Paint()..color = kInk);
    final ray = Paint()
      ..color = Color.lerp(
        const Color(0xFF4A3020),
        const Color(0xFFFFE0A0),
        glow,
      )!
      ..strokeWidth = 1.6;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + _t * 0.2 * glow;
      canvas.drawLine(
        Offset(math.cos(a) * 4, math.sin(a) * 4),
        Offset(math.cos(a) * 9, math.sin(a) * 9),
        ray,
      );
    }
  }
}

/// Bir ızgaradan aşağı düşen güneş huzmesi: aynalarla kırılır, sandıklar ve
/// kaya keser; ışık kilitlerini açar, Gözcü'nün gözünü kamaştırır.
class SunBeam extends Component with HasGameReference<GolgeGame> {
  SunBeam(Vector2 cell)
    : _col = (cell.x / kTile).round(),
      _row = (cell.y / kTile).round(),
      super(priority: 17);

  final int _col;
  final int _row;
  final segments = <(Offset, Offset)>[];
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    _trace();
  }

  void _trace() {
    segments.clear();
    final level = game.level;
    final mirrors = {
      for (final m in game.world.children.whereType<Mirror>())
        (m.col, m.row): m,
    };
    final locks = {
      for (final l in game.world.children.whereType<SunLock>())
        (l.col, l.row): l,
    };
    final crates = game.world.children.whereType<Crate>().toList();
    var c = _col;
    var r = _row;
    var dx = 0;
    var dy = 1;
    var start = Offset((c + 0.5) * kTile, r * kTile.toDouble());
    for (var i = 0; i < 120; i++) {
      c += dx;
      r += dy;
      final center = Offset((c + 0.5) * kTile, (r + 0.5) * kTile);
      final edge = center - Offset(dx * kTile / 2, dy * kTile / 2);
      if (c < 0 || c >= level.width || r < 0 || r >= level.height) {
        segments.add((start, edge));
        break;
      }
      if (level.solid(c, r) || crates.any((k) => k.toRect().contains(center))) {
        segments.add((start, edge));
        break;
      }
      final lock = locks[(c, r)];
      if (lock != null) {
        lock.lit = true;
        segments.add((start, center));
        break;
      }
      final m = mirrors[(c, r)];
      if (m != null) {
        segments.add((start, center));
        start = center;
        // `/`: (dx,dy) → (-dy,-dx); `\`: (dx,dy) → (dy,dx).
        final ndx = m.slash ? -dy : dy;
        final ndy = m.slash ? -dx : dx;
        dx = ndx;
        dy = ndy;
      }
    }
    // Huzmeye giren Gözcü'nün gözü kamaşır.
    for (final w in game.world.children.whereType<Watcher>()) {
      final lamp = w.lamp.toOffset();
      if (segments.any((s) => _dist(lamp, s.$1, s.$2) < 22)) w.dazzle();
    }
  }

  static double _dist(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(
      0.0,
      1.0,
    );
    return (p - (a + ab * t)).distance;
  }

  /// Nokta huzmenin içinde mi (ışık ve gölge tahtaları için)?
  bool lights(Offset p) => segments.any((s) => _dist(p, s.$1, s.$2) < 18);

  @override
  void render(Canvas canvas) {
    final flick = 0.85 + 0.15 * math.sin(_t * 3.1);
    for (final (a, b) in segments) {
      final wide = Paint()
        ..color = const Color(0xFFFFE2A8).withValues(alpha: 0.10 * flick)
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, wide);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFFFFF0CC).withValues(alpha: 0.45 * flick)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    // Havada süzülen toz.
    final dust = Paint()
      ..color = const Color(0xFFFFF0CC).withValues(alpha: 0.5);
    for (final (a, b) in segments) {
      final len = (b - a).distance;
      for (var i = 0; i < len / 30; i++) {
        final k = ((i * 0.37 + _t * 0.05) % 1.0);
        final p = Offset.lerp(a, b, k)!;
        canvas.drawCircle(
          p + Offset(math.sin(_t + i) * 5, math.cos(_t * 0.7 + i) * 5),
          0.9,
          dust,
        );
      }
    }
  }
}

// ============================================================ Dev perde

/// Yerebatan'da sütunlar arasına gerilmiş, yırtık, arkadan aydınlanan dev
/// perde. Önünden geçen Sâye'nin gölgesi perdeye dev gibi düşer. Bir kez,
/// Sâye perdenin ortasında durunca gölge geç kalır ve başını çevirip ona bakar.
class GiantPerde extends PositionComponent with HasGameReference<GolgeGame> {
  GiantPerde(Vector2 cell)
    : super(
        position: Vector2(cell.x, cell.y + kTile),
        size: Vector2(widthTiles * kTile, heightTiles * kTile),
        priority: 3,
      );

  static const widthTiles = 14;
  static const heightTiles = 6;

  double _t = 0;
  final _trail = <(double, double, int)>[];
  double _stillT = 0;

  /// Gölgenin geç kaldığı an: -1 olmadı, 0..lagLength sürüyor, sonra bitti.
  double lagT = -1;
  static const lagLength = 3.2;
  double _frozenX = 0;
  int _frozenFacing = 1;

  Offset get glowCenter =>
      Offset(position.x + size.x * 0.55, position.y - size.y * 0.45);
  double get glowRadius => size.x * 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null || p.isDead) return;
    _trail.add((_t, p.center.x, p.facing));
    while (_trail.length > 2 && _t - _trail.first.$1 > 2.5) {
      _trail.removeAt(0);
    }
    final rel = (p.center.x - position.x) / size.x;
    final inFront =
        rel > 0 && rel < 1 && (p.position.y + Player.h - position.y).abs() < 12;
    if (lagT < 0) {
      // Ortada durup beklerse: bir kez.
      if (inFront && rel > 0.35 && rel < 0.65 && p.velocity.x.abs() < 5) {
        _stillT += dt;
        if (_stillT > 0.5) {
          lagT = 0;
          _frozenX = p.center.x;
          _frozenFacing = p.facing;
        }
      } else {
        _stillT = 0;
      }
    } else if (lagT < lagLength) {
      lagT += dt;
      if (lagT >= lagLength) {
        game.narration.whisper(S.of('shadowLooked'));
      }
    }
  }

  /// Gölgenin o anki konumu ve yönü.
  (double, int)? _shadow() {
    final p = game.player;
    if (p == null || p.isDead) return null;
    var x = p.center.x;
    var facing = p.facing;
    // Normalde gölge bir an gecikmeyle izler.
    for (final e in _trail.reversed) {
      if (_t - e.$1 >= 0.09) {
        x = e.$2;
        facing = e.$3;
        break;
      }
    }
    if (lagT >= 0 && lagT < lagLength) {
      // Gölge kalır; bir süre sonra başını çevirip Sâye'ye bakar, sonra
      // yetişir.
      final catchUp = ((lagT - (lagLength - 0.5)) / 0.5).clamp(0.0, 1.0);
      x = _frozenX + (x - _frozenX) * catchUp;
      final looks = lagT > 1.0 && lagT < lagLength - 0.4;
      if (looks) facing = p.center.x >= _frozenX ? 1 : -1;
      if (!looks) facing = _frozenFacing;
      if (catchUp > 0) facing = p.facing;
    }
    return (x, facing);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Perde gökte değil; konum alt kenar: yukarı doğru çizilir.
    canvas.save();
    canvas.translate(0, -h);
    final torn = Path()..moveTo(0, 0);
    torn.lineTo(w, 0);
    var x = w;
    var i = 0;
    while (x > 0) {
      final y = h - 6 - ((i * 37) % 23) * 0.9;
      torn.lineTo(x, y);
      x -= 18 + (i * 13) % 17;
      i++;
    }
    torn
      ..lineTo(0, h - 10)
      ..close();
    final c = Offset(w * 0.55, h * 0.55);
    final flick = 0.9 + 0.06 * math.sin(_t * 7.3) + 0.04 * math.sin(_t * 13.1);
    canvas.save();
    canvas.clipPath(torn);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          w * 0.6,
          [
            const Color(0xFFFFD59A).withValues(alpha: 0.85 * flick),
            const Color(0xFFB8692F).withValues(alpha: 0.75 * flick),
            const Color(0xFF3A180A).withValues(alpha: 0.9),
          ],
          const [0, 0.45, 1],
        ),
    );
    // Eski tasvirlerin silik izleri.
    final ghost = Paint()
      ..color = const Color(0xFF2A1208).withValues(alpha: 0.28);
    canvas.save();
    canvas.translate(w * 0.12, h);
    canvas.scale(0.55);
    PerdePainter.drawMaster(canvas, ghost);
    canvas.restore();
    canvas.save();
    canvas.translate(w * 0.9, h);
    canvas.scale(-0.5, 0.5);
    PerdePainter.drawLamplighter(canvas, ghost);
    canvas.restore();

    // Sâye'nin perdeye düşen dev gölgesi.
    final s = _shadow();
    if (s != null) {
      final (sx, facing) = s;
      final lx = sx - position.x;
      if (lx > -80 && lx < w + 80) {
        canvas.save();
        canvas.translate(w * 0.5 + (lx - w * 0.5) * 1.1, h - 4);
        canvas.scale(facing * 1.75, 1.75);
        final ink = Paint()
          ..color = const Color(0xFF1A0A04).withValues(alpha: 0.8);
        PerdePainter.drawSaye(
          canvas,
          ink,
          Paint()..color = const Color(0x00000000),
          _t,
          jar: 0,
        );
        canvas.restore();
      }
    }
    canvas.restore();

    // Yırtıklardan sızan ışık ve üst kalas.
    canvas.drawRect(Rect.fromLTWH(-10, -5, w + 20, 7), Paint()..color = kInk);
    canvas.drawLine(
      const Offset(-10, -2),
      const Offset(-40, -40),
      Paint()
        ..color = kInk
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(w + 10, -2),
      Offset(w + 40, -40),
      Paint()
        ..color = kInk
        ..strokeWidth = 2,
    );
    for (final (fx, fy, r) in [(0.7, 0.35, 10.0), (0.28, 0.2, 6.0)]) {
      glowDot(
        canvas,
        Offset(w * fx, h * fy),
        r * 2.4,
        kWarmLight,
        0.55 * flick,
      );
    }
    canvas.restore();
  }
}

// ==================================================================== İp

/// Tavana ya da bir kayaya bağlı ip: havada değince tutunulur, sallanılır,
/// zıplayınca bırakılır. Boşken rüzgârda hafifçe salınır.
class SwingRope extends Component with HasGameReference<GolgeGame> {
  SwingRope(int col, int row, int tiles)
    : anchor = Vector2((col + 0.5) * kTile, row * kTile.toDouble()),
      length = tiles * kTile.toDouble(),
      _t = col * 0.37,
      super(priority: 19);

  final Vector2 anchor;
  final double length;
  Player? holder;
  double angle = 0;
  double _omega = 0;
  double _t;

  void release(double a, double omega) {
    holder = null;
    angle = a;
    _omega = omega;
  }

  @override
  void update(double dt) {
    _t += dt;
    final p = holder;
    if (p != null) {
      if (p.state != PlayerState.swing || p.rope != this) {
        holder = null;
      } else {
        angle = p.ropeAngle;
        return;
      }
    }
    // Boş ip: kendi sarkaç salınımı, yavaşça durulur; rüzgâr hafif iter.
    _omega +=
        (-(1100 / length) * math.sin(angle) + math.sin(_t * 0.7) * 0.15) * dt;
    _omega *= 1 - 0.6 * dt;
    angle += _omega * dt;
  }

  @override
  void render(Canvas canvas) {
    final p = holder;
    final end = p != null
        ? p.hand
        : anchor + Vector2(math.sin(angle), math.cos(angle)) * length;
    final rope = Paint()
      ..color = const Color(0xFF2A1C14)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // Hafif sarkık: ortası biraz bükük çizilir.
    final mid =
        (anchor + end) / 2 +
        Vector2(math.cos(angle), -math.sin(angle)) * (p == null ? 3 : 1.5);
    canvas.drawPath(
      Path()
        ..moveTo(anchor.x, anchor.y)
        ..quadraticBezierTo(mid.x, mid.y, end.x, end.y),
      rope..style = PaintingStyle.stroke,
    );
    // Bağlantı halkası ve uçtaki düğüm.
    canvas.drawCircle(anchor.toOffset(), 3.5, Paint()..color = kInk);
    if (p == null) {
      canvas.drawCircle(
        end.toOffset(),
        3,
        Paint()..color = const Color(0xFF2A1C14),
      );
    }
  }
}

// ================================================================ Gemi

/// Gemideki oyma hayvanların türleri: her birinin bir eşi vardır.
enum AnimalKind { lion, elephant, giraffe, deer }

/// Oyma bir hayvan: itilebilen sandık. Eşinin gölgesinin önüne gelince
/// ikisi birleşir.
class AnimalCrate extends Crate {
  AnimalCrate(super.cell, this.kind);

  final AnimalKind kind;

  @override
  void render(Canvas canvas) {
    const s = Crate.side;
    final wood = Paint()..color = const Color(0xFF3A2414);
    canvas.drawRect(const Rect.fromLTWH(0, s - 6, s, 6), wood);
    canvas.save();
    canvas.translate(s / 2, s - 6);
    _animal(canvas, kind, wood, 0.42);
    canvas.restore();
    canvas.drawLine(
      const Offset(0, s - 5.5),
      const Offset(s, s - 5.5),
      Paint()
        ..color = const Color(0xFFD08A5A).withValues(alpha: 0.5)
        ..strokeWidth = 1.2,
    );
  }
}

/// Hayvanın gölge tasviri (ayakları orijinde, boyu ~60*scale).
void _animal(Canvas canvas, AnimalKind kind, Paint p, double scale) {
  canvas.save();
  canvas.scale(scale);
  switch (kind) {
    case AnimalKind.lion:
      canvas.drawOval(const Rect.fromLTWH(-26, -34, 52, 22), p);
      canvas.drawCircle(const Offset(26, -32), 13, p);
      for (final x in [-20.0, -8.0, 10.0, 18.0]) {
        canvas.drawRect(Rect.fromLTWH(x, -16, 5, 16), p);
      }
      canvas.drawPath(
        Path()
          ..moveTo(-26, -28)
          ..quadraticBezierTo(-42, -34, -44, -18)
          ..lineTo(-40, -18)
          ..quadraticBezierTo(-38, -28, -26, -24)
          ..close(),
        p,
      );
    case AnimalKind.elephant:
      canvas.drawOval(const Rect.fromLTWH(-30, -46, 60, 36), p);
      canvas.drawCircle(const Offset(30, -38), 13, p);
      canvas.drawRect(const Rect.fromLTWH(38, -34, 6, 30), p);
      for (final x in [-24.0, -10.0, 8.0, 20.0]) {
        canvas.drawRect(Rect.fromLTWH(x, -14, 8, 14), p);
      }
    case AnimalKind.giraffe:
      canvas.drawOval(const Rect.fromLTWH(-20, -46, 40, 22), p);
      canvas.drawPath(
        Path()
          ..moveTo(12, -42)
          ..lineTo(26, -92)
          ..lineTo(33, -90)
          ..lineTo(21, -38)
          ..close(),
        p,
      );
      canvas.drawOval(const Rect.fromLTWH(24, -100, 16, 8), p);
      for (final x in [-15.0, -6.0, 7.0, 14.0]) {
        canvas.drawRect(Rect.fromLTWH(x, -28, 4, 28), p);
      }
    case AnimalKind.deer:
      canvas.drawOval(const Rect.fromLTWH(-20, -36, 40, 18), p);
      canvas.drawPath(
        Path()
          ..moveTo(14, -32)
          ..lineTo(22, -52)
          ..lineTo(28, -50)
          ..lineTo(20, -30)
          ..close(),
        p,
      );
      canvas.drawCircle(const Offset(26, -52), 6, p);
      final antler = Paint()
        ..color = p.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(26, -56)
          ..lineTo(22, -70)
          ..moveTo(23, -64)
          ..lineTo(16, -68)
          ..moveTo(28, -56)
          ..lineTo(34, -68),
        antler,
      );
      for (final x in [-15.0, -6.0, 7.0, 14.0]) {
        canvas.drawRect(Rect.fromLTWH(x, -20, 3, 20), p);
      }
  }
  canvas.restore();
}

/// Duvarda eşini bekleyen bir hayvan gölgesi. Aynı türden oyma hayvan
/// önüne itilince gölgeler birleşir, en yakın kapı açılır.
class Pedestal extends PositionComponent with HasGameReference<GolgeGame> {
  Pedestal(Vector2 cell, this.kind)
    : super(position: Vector2(cell.x + kTile / 2, cell.y + kTile), priority: 4);

  final AnimalKind kind;
  bool matched = false;
  double _glow = 0;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (matched) {
      _glow = math.min(1, _glow + dt);
      return;
    }
    for (final a in game.world.children.whereType<AnimalCrate>()) {
      if (a.kind != kind) continue;
      final cx = a.position.x + Crate.side / 2;
      final feet = a.position.y + Crate.side;
      if ((cx - position.x).abs() < 14 && (feet - position.y).abs() < 4) {
        matched = true;
        GameAudio.instance.play('memory', volume: 0.6);
        _openIfAllMatched();
      }
    }
  }

  /// Bu gölgeye en yakın kapı, o kapıya bağlı bütün gölgeler eşini bulunca
  /// açılır.
  Gate? get _gate {
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final d = (g.position - position).length;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    return best;
  }

  void _openIfAllMatched() {
    final gate = _gate;
    if (gate == null || gate.opening) return;
    final group = game.world.children.whereType<Pedestal>().where(
      (p) => p._gate == gate,
    );
    if (group.every((p) => p.matched)) {
      gate.opening = true;
      GameAudio.instance.play('gate', volume: 0.6);
    }
  }

  @override
  void render(Canvas canvas) {
    // Duvara düşen eş gölge; eşleşince ışıkla çevrelenir.
    final shade = Paint()
      ..color = const Color(0xFF0A0604)
          .withValues(alpha: 0.55 + 0.1 * math.sin(_t));
    canvas.save();
    canvas.translate(0, -kTile * 0.4);
    canvas.scale(-1, 1);
    _animal(canvas, kind, shade, 1.1);
    canvas.restore();
    if (_glow > 0) {
      glowDot(canvas, Offset(0, -kTile), 70, kWarmLight, 0.4 * _glow);
    }
    // Kaide çizgisi.
    canvas.drawLine(
      const Offset(-14, -1),
      const Offset(14, -1),
      Paint()
        ..color = const Color(0xFFD08A5A).withValues(alpha: 0.4 + 0.4 * _glow)
        ..strokeWidth = 2,
    );
  }
}

// ================================================================= Dağ

/// Saçaktan sarkan buz sarkıtı: altından geçilince titrer, sonra düşer.
class FallingIcicle extends PositionComponent with HasGameReference<GolgeGame> {
  FallingIcicle(Vector2 cell)
    : super(position: Vector2(cell.x + kTile / 2, cell.y), priority: 21);

  double _shake = -1;
  double _vy = 0;
  bool _fallen = false;
  double _gone = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (_fallen) {
      _gone += dt;
      if (_gone > 0.6) removeFromParent();
      return;
    }
    if (_shake < 0) {
      // Yaklaşan ayak sesiyle çatırdar: altına varmadan düşmeye başlar.
      final dx = position.x - (p?.center.x ?? 0);
      final ahead = p == null ? 0.0 : dx * p.velocity.x.sign;
      if (p != null &&
          !p.isDead &&
          ((ahead > 0 && ahead < 40) || dx.abs() < 10) &&
          p.center.y > position.y &&
          p.center.y - position.y < 9 * kTile) {
        _shake = 0;
        GameAudio.instance.play('creak', volume: 0.4);
      }
      return;
    }
    _shake += dt;
    if (_shake < 0.3) return;
    _vy = math.min(_vy + 1900 * dt, 900);
    position.y += _vy * dt;
    if (p != null &&
        !p.isDead &&
        p.toRect().contains(Offset(position.x, position.y + 18))) {
      p.die();
    }
    if (game.level.cellAt(position.x, position.y + 22) == '#' ||
        position.y > game.level.pixelHeight) {
      _fallen = true;
      GameAudio.instance.play('shatter', volume: 0.35);
    }
  }

  @override
  void render(Canvas canvas) {
    final jitter = _shake >= 0 && _shake < 0.45
        ? math.sin(_shake * 80) * 1.5
        : 0.0;
    final a = _fallen ? (1 - _gone / 0.6).clamp(0.0, 1.0) : 1.0;
    final ice = Paint()
      ..color = const Color(0xFFB8CCE4).withValues(alpha: 0.9 * a);
    if (_fallen) {
      // Kırık parçalar.
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(-8 + i * 4.0 + jitter, 20 - _gone * 10 * (i % 2 + 1)),
          1.6,
          ice,
        );
      }
      return;
    }
    canvas.drawPath(
      Path()
        ..moveTo(-5 + jitter, 0)
        ..lineTo(5 + jitter, 0)
        ..lineTo(jitter, 24)
        ..close(),
      ice,
    );
    canvas.drawLine(
      Offset(-1 + jitter, 2),
      Offset(jitter, 18),
      Paint()
        ..color = const Color(0xFFF2F8FF).withValues(alpha: 0.7 * a)
        ..strokeWidth = 1,
    );
  }
}

/// Yıkık manastırın çanı: rüzgârda hafifçe sallanır. Yanından hızlı
/// geçilirse çalar ve Kandilciler sese gelir.
class WindBell extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  WindBell(Vector2 cell)
    : super(position: Vector2(cell.x + kTile / 2, cell.y), priority: 18);

  double _t = 0;
  double _ring = 0;
  double _rearm = 0;

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 30 && (p - position).y.abs() < 4 * kTile;

  /// Bilerek çalmak: Kandilcileri sese çekmek için.
  @override
  void use() => _ringNow();

  void _ringNow() {
    if (_rearm > 0) return;
    _ring = 1;
    _rearm = 2.5;
    GameAudio.instance.play('bell');
    game.makeNoise(position.clone(), 780, source: this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _ring = math.max(0, _ring - dt * 0.6);
    _rearm -= dt;
    final p = game.player;
    if (p == null || p.isDead || _rearm > 0) return;
    final d = p.center - position;
    final fast = p.velocity.x.abs() > 75 || !p.onGround;
    if (d.x.abs() < 44 && d.y > 0 && d.y < 4 * kTile && fast) _ringNow();
  }

  @override
  void render(Canvas canvas) {
    final swing = math.sin(_t * 1.3) * 0.08 + math.sin(_t * 14) * 0.35 * _ring;
    canvas.drawLine(
      Offset.zero,
      const Offset(0, 6),
      Paint()
        ..color = kInk
        ..strokeWidth = 1.5,
    );
    canvas.save();
    canvas.translate(0, 6);
    canvas.rotate(swing);
    final bronze = Paint()..color = const Color(0xFF2A1E14);
    canvas.drawPath(
      Path()
        ..moveTo(-4, 0)
        ..quadraticBezierTo(-5, 10, -11, 18)
        ..lineTo(11, 18)
        ..quadraticBezierTo(5, 10, 4, 0)
        ..close(),
      bronze,
    );
    canvas.drawLine(
      const Offset(-10, 17),
      const Offset(10, 17),
      Paint()
        ..color = const Color(0xFFC8A060).withValues(alpha: 0.4 + 0.5 * _ring)
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(const Offset(0, 19), 2.2, bronze);
    canvas.restore();
    if (_ring > 0.05) {
      // Çanın sesi: genişleyen ince halkalar.
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFE8D0A0).withValues(alpha: 0.4 * _ring);
      canvas.drawCircle(const Offset(0, 14), 20 + (1 - _ring) * 60, ringPaint);
    }
  }
}

/// Aziz Hakob Manastırı'nın kalıntısı: sivri külahlı kilisenin yıkık
/// gövdesi, kemerli pencereler. Arazinin arkasında, süs.
class MonasteryRuin extends PositionComponent with HasGameReference<GolgeGame> {
  MonasteryRuin(Vector2 cell)
    : super(position: Vector2(cell.x, cell.y + kTile), priority: -1);

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF1A2230);
    final snow = Paint()..color = const Color(0xFF8A9AB4);
    // Gövde (yer yer yıkık üst kenar).
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(0, -150)
      ..lineTo(40, -150)
      ..lineTo(52, -128)
      ..lineTo(70, -150)
      ..lineTo(200, -150)
      ..lineTo(200, -96)
      ..lineTo(232, -70)
      ..lineTo(240, 0)
      ..close();
    canvas.drawPath(body, stone);
    // Kasnak ve yarısı yıkılmış külah.
    canvas.drawRect(const Rect.fromLTWH(78, -210, 64, 60), stone);
    canvas.drawPath(
      Path()
        ..moveTo(74, -210)
        ..lineTo(110, -262)
        ..lineTo(126, -240)
        ..lineTo(134, -246)
        ..lineTo(146, -210)
        ..close(),
      stone,
    );
    // Kemerli pencereler: içleri karanlık mavi.
    final window = Paint()..color = const Color(0xFF0A0E16);
    for (final x in [24.0, 96.0, 160.0]) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, -118, 18, 40),
          topLeft: const Radius.circular(9),
          topRight: const Radius.circular(9),
        ),
        window,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(100, -196, 12, 28),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      window,
    );
    // Haç taşı.
    final cross = Paint()
      ..color = const Color(0xFF3A465C)
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(110, -272), const Offset(110, -290), cross);
    canvas.drawLine(const Offset(103, -283), const Offset(117, -283), cross);
    // Karla örtülü kenarlar.
    canvas.drawRect(const Rect.fromLTWH(0, -153, 40, 4), snow);
    canvas.drawRect(const Rect.fromLTWH(70, -153, 130, 4), snow);
    canvas.drawRect(const Rect.fromLTWH(76, -213, 68, 4), snow);
  }
}
