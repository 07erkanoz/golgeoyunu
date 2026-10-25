import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'persist.dart';

// ================================================================ Kuş Yolu Katı
//
// Kazak ve Kırgızlar Samanyolu'na Kuş Yolu der: göçmen kuşlar yönlerini
// onunla bulur. Göğün Katları'nda Kuş Yolu bir ışık nehridir: içine giren
// Sâye'yi akışıyla taşır. Ülker (Süreyya) yedi yıldızdır: yedisine de
// dokununca aralarındaki çizgiler ışıktan bir köprü olur.

/// Işık nehri: noktalar boyunca akar; içine giren akışla taşınır.
class StarStream extends Component with HasGameReference<GolgeGame> {
  StarStream(List<(int, int)> cells)
    : points = [
        for (final (c, r) in cells)
          Offset((c + 0.5) * kTile, (r + 0.5) * kTile),
      ],
      super(priority: 12);

  final List<Offset> points;

  /// Akışın yarı genişliği ve hızı.
  static const double radius = 1.3 * kTile;
  static const double speed = 170;

  double _t = 0;
  bool _inside = false;

  /// Testler için: Sâye akışın içinde mi.
  bool get carrying => _inside;

  /// Noktanın akışa en yakın yeri: (uzaklık, akış yönü, yol boyunca
  /// kesir, en yakın nokta).
  (double, Offset, double, Offset) _nearest(Offset p) {
    var best = double.infinity;
    var dir = const Offset(1, 0);
    var along = 0.0;
    var at = points.first;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }
    var walked = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ab = b - a;
      final len = ab.distance;
      final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / (len * len)).clamp(
        0.0,
        1.0,
      );
      final q = a + ab * t;
      final d = (p - q).distance;
      if (d < best) {
        best = d;
        dir = ab / len;
        along = (walked + len * t) / total;
        at = q;
      }
      walked += len;
    }
    return (best, dir, along, at);
  }

  Offset _lastDir = const Offset(1, 0);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null || p.isDead) {
      _inside = false;
      return;
    }
    final (d, dir, along, at) = _nearest(p.center.toOffset());
    final inside = d < radius && along < 0.995;
    if (inside && !_inside) {
      GameAudio.instance.play('glide', volume: 0.5, minGapMs: 800);
    }
    if (!inside && _inside) {
      // Nehirden çıkarken akışın hızıyla savrulur.
      p.velocity.setValues(_lastDir.dx * speed, _lastDir.dy * speed);
    }
    _inside = inside;
    if (!inside) return;
    _lastDir = dir;
    // Akışla taşınır, ortasına doğru çekilir: konum doğrudan ilerler
    // (oyuncunun kendi hızı ve yerçekimi bu sırada sıfırlanır).
    final c = p.center.toOffset();
    final toward = at - c;
    final step = dir * speed * dt + toward * math.min(1, dt * 4);
    p.position.add(Vector2(step.dx, step.dy));
    p.velocity.setZero();
    p.onGround = false;
  }

  @override
  void render(Canvas canvas) {
    // Işık nehri: geniş soluk bant, içinde akan yıldız tozu.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final m = Offset.lerp(a, b, 0.5)!;
      path.quadraticBezierTo(a.dx, a.dy, m.dx, m.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFBFD8FF).withValues(alpha: 0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE6F0FF).withValues(alpha: 0.12),
    );
    // Akan tozlar.
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }
    final dust = Paint()..color = const Color(0xFFF2F6FF);
    final n = (total / 14).floor();
    for (var i = 0; i < n; i++) {
      final s = ((i * 14 + _t * speed) % total);
      var rem = s;
      var at = points.first;
      for (var k = 0; k < points.length - 1; k++) {
        final len = (points[k + 1] - points[k]).distance;
        if (rem <= len) {
          at = Offset.lerp(points[k], points[k + 1], rem / len)!;
          break;
        }
        rem -= len;
      }
      final off = math.sin(i * 1.7) * radius * 0.7;
      dust.color = const Color(0xFFF2F6FF)
          .withValues(alpha: 0.35 + 0.35 * math.sin(i + _t * 3).abs());
      canvas.drawCircle(at.translate(0, off), 1.1 + (i % 3) * 0.5, dust);
    }
  }
}

/// Ülker: yedi yıldız. Dokunulan yanar; yedisi yanınca aralarındaki
/// çizgiler ışıktan bir köprü olur.
class UlkerCluster extends Component
    with HasGameReference<GolgeGame>, Persistent {
  UlkerCluster(List<(int, int)> stars, this.bridge)
    : stars = [
        for (final (c, r) in stars)
          Offset((c + 0.5) * kTile, (r + 0.5) * kTile),
      ],
      super(priority: 13);

  final List<Offset> stars;

  /// Köprü: (ilk sütun, son sütun, satır).
  final (int, int, int) bridge;

  late final List<bool> lit = List.filled(stars.length, false);
  bool complete = false;
  double _t = 0;
  double _glow = 0;
  final _planks = <UlkerPlank>[];

  @override
  String get persistKind => 'ulker';

  @override
  Object? captureState() => complete ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      complete = true;
      lit.fillRange(0, lit.length, true);
      _glow = 1;
    }
    return [this];
  }

  // Eşzamanlı: beklenen bir yükleme, ölüp yeniden doğunca ardından gelen
  // parçaların dünyaya girişini bekletiyordu (bkz. JoyLights).
  @override
  void onLoad() {
    final (c0, c1, r) = bridge;
    for (var c = c0; c <= c1; c += 2) {
      _planks.add(UlkerPlank(this, c, r));
    }
    game.world.addAll(_planks);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (complete) {
      _glow = math.min(1, _glow + dt * 0.8);
      return;
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    for (var i = 0; i < stars.length; i++) {
      if (lit[i]) continue;
      if ((stars[i] - p.center.toOffset()).distance < 22) {
        lit[i] = true;
        final n = lit.where((l) => l).length;
        GameAudio.instance.play('firefly', volume: 0.4 + 0.08 * n);
        if (n == stars.length) {
          complete = true;
          GameAudio.instance.play('solve', volume: 0.7);
          GameAudio.instance.play('bell', volume: 0.4);
        }
      }
    }
  }

  /// Köprünün belirişi (0-1).
  double get glow => _glow;

  @override
  void render(Canvas canvas) {
    // Takımyıldızın çizgileri: yanan yıldızlar arasında soluk iplik.
    final line = Paint()
      ..strokeWidth = 1.4
      ..color = const Color(0xFFDDE8FF).withValues(alpha: 0.35 + 0.4 * _glow);
    for (var i = 0; i < stars.length - 1; i++) {
      if (lit[i] && lit[i + 1]) canvas.drawLine(stars[i], stars[i + 1], line);
    }
    for (var i = 0; i < stars.length; i++) {
      final on = lit[i];
      final tw = 0.7 + 0.3 * math.sin(_t * 3 + i * 1.3);
      glowDot(
        canvas,
        stars[i],
        on ? 26 : 14,
        const Color(0xFFDDE8FF),
        (on ? 0.6 : 0.25) * tw,
      );
      final s = on ? 6.0 : 4.0;
      final o = stars[i];
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - s)
          ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
          ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s)
          ..close(),
        Paint()
          ..color = (on ? const Color(0xFFFFFFFF) : const Color(0xFF9FB4D8))
              .withValues(alpha: on ? 1 : 0.7),
      );
    }
  }
}

/// Ülker köprüsünün bir parçası: yedi yıldız yanınca belirir, basılır.
class UlkerPlank extends Deck {
  UlkerPlank(this.cluster, int col, int row)
    : super(
        position: Vector2(col * kTile.toDouble(), row * kTile.toDouble()),
        size: Vector2(2 * kTile.toDouble(), 8),
      );

  final UlkerCluster cluster;

  @override
  bool get active => cluster.glow > 0.6;

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    final g = cluster.glow;
    if (g <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 0, size.x - 2, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFDDE8FF).withValues(alpha: 0.75 * g),
    );
    glowDot(
      canvas,
      Offset(size.x / 2, 2),
      26,
      const Color(0xFFDDE8FF),
      0.3 * g,
    );
  }
}
