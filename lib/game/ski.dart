import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'player.dart';

/// Kayak bölümlerinin pürüzsüz kar yamacı. Yükseklikler sütun başına (kare
/// cinsinden) verilir; aralar doğrusal birleştirilir. Negatif yükseklik
/// uçurumdur.
class SkiSurface {
  SkiSurface(this.rows);

  final List<double> rows;

  /// x'teki zemin yüksekliği (piksel), uçurumsa null.
  double? at(double x) {
    final f = x / kTile - 0.5;
    final i = f.floor();
    if (i < 0) return rows.first < 0 ? null : rows.first * kTile;
    if (i + 1 >= rows.length) return rows.last < 0 ? null : rows.last * kTile;
    final a = rows[i];
    final b = rows[i + 1];
    if (a < 0 || b < 0) return null;
    final t = f - i;
    return (a + (b - a) * t) * kTile;
  }

  /// x'teki eğim açısı (aşağı inen yokuş artı).
  double slope(double x) {
    final y0 = at(x - 6);
    final y1 = at(x + 6);
    if (y0 == null || y1 == null) return 0;
    return math.atan2(y1 - y0, 12);
  }
}

/// Karlı yamacın çizimi: kar örtüsü, altında koyu kaya, yer yer çam.
class SkiTerrain extends Component with HasGameReference<GolgeGame> {
  SkiTerrain(this.surface) : super(priority: 1);

  final SkiSurface surface;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect.inflate(64);
    final c0 = math.max(0, (view.left / kTile).floor() - 1);
    final c1 = math.min(
      surface.rows.length - 1,
      (view.right / kTile).ceil() + 1,
    );
    final bottom = game.level.pixelHeight + 400;
    final rock = Paint()..color = kInk;
    final snow = Paint()..color = const Color(0xFFC8D2E2);
    var c = c0;
    while (c <= c1) {
      if (surface.rows[c] < 0) {
        c++;
        continue;
      }
      // Kesintisiz bir zemin parçası.
      final path = Path();
      final top = Path();
      final start = c;
      while (c <= c1 && surface.rows[c] >= 0) {
        final x = (c + 0.5) * kTile;
        final y = surface.rows[c] * kTile;
        if (c == start) {
          path.moveTo(x - kTile / 2, bottom);
          path.lineTo(x - kTile / 2, y);
          top.moveTo(x - kTile / 2, y);
        }
        path.lineTo(x, y);
        top.lineTo(x, y);
        c++;
      }
      final endX = (c - 0.5) * kTile;
      final endY = surface.rows[c - 1] * kTile;
      path
        ..lineTo(endX + kTile / 2, endY)
        ..lineTo(endX + kTile / 2, bottom)
        ..close();
      top.lineTo(endX + kTile / 2, endY);
      canvas.drawPath(path, rock);
      canvas.drawPath(
        top,
        snow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeJoin = StrokeJoin.round,
      );
    }
    // Yamaçtaki çamlar (belirlenimci).
    final tree = Paint()..color = const Color(0xFF0E1420);
    final cap = Paint()..color = const Color(0xFF8C9CB4);
    for (var i = c0; i <= c1; i++) {
      if (surface.rows[i] < 0 || (i * 7919) % 11 != 0) continue;
      final x = (i + 0.5) * kTile;
      final y = surface.rows[i] * kTile + 4;
      final h = 40.0 + (i * 31) % 30;
      canvas.drawPath(
        Path()
          ..moveTo(x, y - h)
          ..lineTo(x + h * 0.28, y)
          ..lineTo(x - h * 0.28, y)
          ..close(),
        tree,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, y - h)
          ..lineTo(x + h * 0.12, y - h * 0.6)
          ..lineTo(x - h * 0.12, y - h * 0.6)
          ..close(),
        cap,
      );
    }
  }
}

/// Karın içinden çıkan kaya: kayarken üstünden atlanmalı.
class SkiRock extends PositionComponent with HasGameReference<GolgeGame> {
  SkiRock(this.col, this.surface)
    : super(
        position: Vector2(
          (col + 0.5) * kTile - 14,
          (surface.rows[col]) * kTile - 22,
        ),
        size: Vector2(28, 24),
        priority: 18,
      );

  final int col;
  final SkiSurface surface;

  @override
  void render(Canvas canvas) {
    final rock = Paint()..color = const Color(0xFF1A1E28);
    canvas.drawPath(
      Path()
        ..moveTo(0, 24)
        ..lineTo(4, 8)
        ..lineTo(12, 0)
        ..lineTo(22, 4)
        ..lineTo(28, 24)
        ..close(),
      rock,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 7)
        ..lineTo(12, 1)
        ..lineTo(21, 5)
        ..lineTo(14, 6)
        ..close(),
      Paint()..color = const Color(0xFFDCE4F0),
    );
  }
}

/// Kütükten çit: üstüne konulup kayılır (uçurumları geçmek için).
class SkiRail extends PositionComponent {
  SkiRail(int col, int row, int tiles)
    : super(
        // Üstü, uçurumun kenarındaki kar hizasında: dümdüz kayılarak çıkılır.
        position: Vector2(col * kTile.toDouble(), (row + 1) * kTile - 1),
        size: Vector2(tiles * kTile.toDouble(), 6),
        priority: 18,
      );

  double get top => position.y;

  @override
  void render(Canvas canvas) {
    final wood = Paint()
      ..color = const Color(0xFF241810)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(2, 2), Offset(size.x - 2, 2), wood);
    for (var x = 8.0; x < size.x; x += 40) {
      canvas.drawLine(Offset(x, 2), Offset(x - 4, 40), wood..strokeWidth = 3);
    }
    canvas.drawLine(
      const Offset(2, -1),
      Offset(size.x - 2, -1),
      Paint()
        ..color = const Color(0xFFDCE4F0).withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );
  }
}

/// Manyetik Tepe: içinde kar yokuş yukarı akar (göz yanılır mı, dağ mı
/// çeker, kimse bilmez).
class MagnetZone extends Component with HasGameReference<GolgeGame> {
  MagnetZone(this.from, this.to) : super(priority: 2);

  final double from;
  final double to;
  double _t = 0;

  bool covers(double x) => x >= from && x <= to;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final s = game.skiSurface;
    if (s == null) return;
    // Yokuş yukarı süzülen ince parıltılar.
    final p = Paint()..color = const Color(0xFFB8E0FF).withValues(alpha: 0.5);
    for (var i = 0; i < 24; i++) {
      final k = ((i * 0.37 + _t * 0.25) % 1.0);
      final x = to - (to - from) * k;
      final y = s.at(x);
      if (y == null) continue;
      canvas.drawCircle(Offset(x, y - 10 - (i % 5) * 6), 1.4, p);
    }
  }
}

/// Çığ: arkadan gelen bir kar duvarı. Yakalarsa karanlık. Bitiş çizgisinde
/// dağılır.
class Avalanche extends PositionComponent with HasGameReference<GolgeGame> {
  Avalanche(this.startX, this.endX) : super(priority: 24);

  final double startX;
  final double endX;
  bool _awake = false;
  bool _gone = false;
  double _speed = 0;
  double _t = 0;
  double _fade = 0;

  bool get awake => _awake && !_gone;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_gone) {
      _fade = math.max(0, _fade - dt);
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      if (p.center.x > startX && !p.isDead) {
        _awake = true;
        position.x = p.center.x - 700;
        _speed = 230;
        GameAudio.instance.play('thunder');
        game.narration.whisper('…');
      }
      return;
    }
    _fade = math.min(1, _fade + dt);
    if (p.center.x > endX) {
      _gone = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;
    _speed = math.min(440, _speed + dt * 14);
    position.x += _speed * dt;
    // Çok geride kalmasın.
    position.x = math.max(position.x, p.center.x - 760);
    position.y = (game.skiSurface?.at(position.x) ?? position.y);
    final gap = p.center.x - position.x;
    game.shake(((300 - gap) / 300).clamp(0.0, 1.0) * 6);
    GameAudio.instance.dread(((700 - gap) / 600).clamp(0.2, 1.0));
    if (gap < 30) p.die(cause: DeathCause.dark);
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final a = _fade;
    final snow = Paint()
      ..color = const Color(0xFFE6EEF8).withValues(alpha: 0.92 * a);
    final shade = Paint()
      ..color = const Color(0xFF9AAAC0).withValues(alpha: 0.8 * a);
    for (var i = 0; i < 16; i++) {
      final ang = i / 16 * math.pi;
      final r = 120 + 30 * math.sin(_t * 4 + i * 1.3);
      final c = Offset(-math.cos(ang) * 80 - 60, -math.sin(ang) * r * 1.4);
      canvas.drawCircle(
        c,
        70 + 15 * math.sin(_t * 3 + i),
        i.isEven ? snow : shade,
      );
    }
    canvas.drawRect(Rect.fromLTWH(-600, -60, 600, 400), snow);
  }
}

/// Kayakçının çizimi için yardımcı: tahta.
void drawSkis(Canvas canvas, Offset feet, double len) {
  final board = Paint()
    ..color = kInk
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    feet.translate(-len * 0.45, 0),
    feet.translate(len * 0.5, 0),
    board,
  );
  canvas.drawLine(
    feet.translate(len * 0.5, 0),
    feet.translate(len * 0.62, -3),
    board,
  );
}

/// Kayak için kar tozu.
void drawSpray(Canvas canvas, Offset at, double speed, double t) {
  if (speed < 120) return;
  final p = Paint()..color = const Color(0xFFF2F6FA).withValues(alpha: 0.6);
  for (var i = 0; i < 6; i++) {
    final k = ((t * 3 + i * 0.17) % 1.0);
    canvas.drawCircle(
      at.translate(-k * 30 - i * 2, -k * 14 * (i % 3 + 1) * 0.5),
      1.5 + (1 - k) * 2,
      p,
    );
  }
}
