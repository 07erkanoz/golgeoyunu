import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'creatures.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'player.dart';

// ================================================================ Kaf'ın vadileri
//
// Attâr'ın Mantıku't-Tayr'ında kuşlar, Hüdhüd'ün peşinde Simurg'a varmak
// için yedi vadiden geçer. Kaf'ta ikisi:
//
// Hayret Vadisi · Aynalı Göl: kıpırtısız gölün üstünde yolun bir kısmı
// havada görünmez; görünmeyen basamaklar yalnız gölün yüzündeki yansımada
// belli olur. Rüzgâr esince göl dalgalanır, yansıma bir an bozulur.
//
// Otuz Kuş · Kuşlardan Köprü: Hüdhüd'ün peşindeki sürü uçurumun üstünden
// dizi dizi uçar; Sâye kuşların sırtına basarak geçer.

/// Aynalı göl: yüzeyin parıltısı, rüzgârın dalgası ve Sâye'nin yansıması.
class MirrorLake extends PositionComponent with HasGameReference<GolgeGame> {
  MirrorLake(this.c0, this.c1, this.surfaceRow) : super(priority: 27);

  final int c0;
  final int c1;
  final int surfaceRow;

  /// Rüzgârın döngüsü: uzun durgunluk, kısa dalga (önce hışırtı).
  static const double period = 7;
  static const double ripple = 1.6;
  static const double warn = 0.8;

  double _t = 0;
  bool _warned = false;

  /// Önizleme ve testler için: rüzgâr döngüsünde an.
  set debugTime(double v) => _t = v;

  double get surface => surfaceRow * kTile.toDouble();
  double get left => c0 * kTile.toDouble();
  double get right => (c1 + 1) * kTile.toDouble();

  double get _u => _t % period;

  /// Dalga (0 durgun, 1 tam dalgalı).
  double get wave {
    final u = _u;
    final start = period - ripple;
    if (u < start) return 0;
    final k = (u - start) / ripple;
    return math.sin(k * math.pi);
  }

  /// Rüzgâr gelmek üzere (0-1): suyun yüzünde ince çizgiler.
  double get coming {
    final u = _u;
    final start = period - ripple - warn;
    if (u < start || u > period - ripple) return 0;
    return (u - start) / warn;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    final near =
        p != null && p.center.x > left - 4 * kTile && p.center.x < right;
    if (coming > 0 && !_warned && near) {
      _warned = true;
      GameAudio.instance.play('gust', volume: 0.35, minGapMs: 2000);
    }
    if (coming == 0 && wave == 0) _warned = false;
  }

  @override
  void render(Canvas canvas) {
    final s = surface;
    // Ayna gibi yüz: gökyüzünün soluk yansıması.
    canvas.drawRect(
      Rect.fromLTRB(left, s, right, s + 3 * kTile),
      Paint()
        ..shader = Gradient.linear(Offset(0, s), Offset(0, s + 3 * kTile), [
          const Color(0xFF9FE6D2).withValues(alpha: 0.22 * (1 - wave)),
          const Color(0xFF0A2A26).withValues(alpha: 0),
        ]),
    );
    final line = Paint()
      ..color = const Color(0xFFDFFFF4).withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, s), Offset(right, s), line);
    // Rüzgâr gelirken ve eserken yüzde kırışıklar.
    final w = math.max(coming * 0.5, wave);
    if (w > 0) {
      final rip = Paint()
        ..color = const Color(0xFFDFFFF4).withValues(alpha: 0.35 * w)
        ..strokeWidth = 1;
      for (var x = left; x < right; x += 22) {
        final y = s + 6 + ((x * 7) % 40);
        final dx = math.sin(_t * 6 + x) * 6 * w;
        canvas.drawLine(Offset(x + dx, y), Offset(x + dx + 12, y), rip);
      }
    }
    // Görünmeyen basamakların yansıması (suyun çiziminin üstünde).
    for (final m in game.world.children.whereType<MirrorStep>()) {
      m.paintReflection(canvas, this);
    }
    // Sâye'nin yansıması: kavanozun ışığı suda.
    final p = game.player;
    if (p != null && p.center.x > left && p.center.x < right && !p.isDead) {
      final jar = p.lightVisual;
      final ry = s + (s - jar.y) * MirrorStep.reflectionDepth;
      if (ry > s) {
        glowDot(
          canvas,
          Offset(jar.x + math.sin(_t * 9) * 5 * wave, ry),
          18,
          kWarmLight,
          0.4 * (1 - 0.7 * wave),
        );
      }
    }
  }
}

/// Görünmeyen basamak: havada görünmez, gölün yansımasında belli olur.
/// Üstüne basılınca bir an seçilir (oyuncuya geri bildirim).
class MirrorStep extends Deck {
  MirrorStep(int col, int row, this.tiles)
    : super(
        position: Vector2(col * kTile.toDouble(), row * kTile.toDouble()),
        size: Vector2(tiles * kTile.toDouble(), 8),
      );

  final int tiles;

  /// Yansımanın derinliği (yüzeyden uzaklığın kesri).
  static const double reflectionDepth = 0.32;
  MirrorLake? _lake;
  double _touched = 0;
  double _t = 0;

  /// Yansımanın ortası (dünya): ışık katmanı için.
  Offset get reflectionCenter {
    final l = lake!;
    final y = l.surface + (l.surface - position.y - size.y) * reflectionDepth;
    return Offset(position.x + size.x / 2, y + size.y / 2);
  }

  MirrorLake? get lake =>
      _lake ??= game.world.children.whereType<MirrorLake>().firstOrNull;

  @override
  void step(double dt) {
    _t += dt;
    _touched = math.max(0, _touched - dt);
    final p = game.player;
    if (p != null && identical(p.riding, this)) _touched = 0.7;
  }

  @override
  void render(Canvas canvas) {
    // Basılınca bir an: ince bir ışık çizgisi.
    if (_touched > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, 4),
          const Radius.circular(2),
        ),
        Paint()
          ..color = const Color(0xFFDFFFF4)
              .withValues(alpha: 0.5 * (_touched / 0.7)),
      );
    }
  }

  /// Yansıma: gölün yüzüne göre aynalanmış taş levha; sığ açıyla
  /// bakıldığı için kısalmış (suyun hemen altında). Gölün kendisi çizer
  /// (suyun çiziminin üstünde kalsın diye).
  void paintReflection(Canvas canvas, MirrorLake l) {
    final mirrorY =
        l.surface + (l.surface - position.y - size.y) * reflectionDepth;
    final wave = l.wave;
    final a = 0.85 * (1 - 0.85 * wave);
    if (a <= 0.02) return;
    canvas.save();
    canvas.translate(
      position.x + math.sin(_t * 7 + position.x) * 10 * wave,
      mirrorY,
    );
    // Ayın yansıması gibi soluk ve parlak: karanlık suda seçilsin.
    final slab = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y * 0.8),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      slab,
      Paint()..color = const Color(0xFF9FE6D2).withValues(alpha: 0.4 * a),
    );
    canvas.drawLine(
      const Offset(2, 1),
      Offset(size.x - 2, 1),
      Paint()
        ..color = const Color(0xFFE6FFF6).withValues(alpha: a)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }
}

/// Kuşlardan köprü: sürü uçurumun üstünden soldan sağa, dalga gibi
/// yükselip alçalarak uçar; uçurumun sonunda yükselip ayrılır, baştan
/// yeniden gelir. Her kuş üstüne basılan küçük bir zemindir (Sâye zemin
/// olarak dünyanın doğrudan çocuklarına bakar: kuşlar dünyaya eklenir).
class BirdBridge {
  BirdBridge(this.c0, this.c1, this.row);

  final int c0;
  final int c1;
  final int row;

  /// Sürünün hızı (piksel/sn) ve kuşların arası (piksel).
  static const double speed = 58;
  static const double spacing = 3.4 * kTile;

  List<Component> birds() {
    final span = (c1 - c0) * kTile.toDouble();
    final n = (span / spacing).ceil() + 1;
    return [
      for (var i = 0; i < n; i++) BirdDeck(this, i * spacing),
      // Uçurumun ötesinde sürünün konduğu halka.
      BirdRing(
        Vector2((c1 + 4) * kTile.toDouble(), (row + 2) * kTile.toDouble()),
      ),
    ];
  }
}

class BirdDeck extends Deck {
  BirdDeck(this.flock, this.offset)
    : super(position: Vector2.zero(), size: Vector2(36, 8));

  final BirdBridge flock;
  final double offset;
  double _t = 0;

  double get _left => flock.c0 * kTile.toDouble();
  double get _span => (flock.c1 - flock.c0) * kTile.toDouble();

  /// Yolun neresinde (0-1); uçta kalkar, başta iner.
  double get _u =>
      ((_t * BirdBridge.speed + offset) % (_span + 3 * kTile)) / _span;

  /// Gözcü'nün feneri değince ürkmüş: havalanır, birazdan yerine döner.
  double _scared = 0;

  /// Testler için: ürkmüş mü.
  bool get scared => _scared > 0;

  /// Kalkışta, inişte ve ürkmüşken basılmaz.
  @override
  bool get active => _u > 0.02 && _u < 1.0 && _scared <= 0;

  @override
  void step(double dt) {
    _t += dt;
    // Fenerin ışığı değen kuş ürker: çığlık atıp havalanır, iki saniye
    // sonra sürüye döner (sırtındaki Sâye düşer).
    if (_scared > 0) {
      _scared = math.max(0, _scared - dt);
    } else if (_u > 0.02 && _u < 1.0) {
      for (final w in game.world.children.whereType<Watcher>()) {
        if (w.lights(center)) {
          _scared = 2.2;
          GameAudio.instance.play('bird', volume: 0.5, minGapMs: 200);
          break;
        }
      }
    }
    final u = _u;
    final x = _left + u * _span;
    final wave = math.sin(_t * 1.6 + offset * 0.01) * 0.6 * kTile;
    // Uçta yükselip ayrılır, başta yukarıdan iner.
    final lift = u > 1.0
        ? (u - 1.0) * _span * 1.2
        : u < 0.06
        ? (0.06 - u) / 0.06 * 3 * kTile
        : 0.0;
    // Ürkmüş kuş yukarı kaçar, sonra iner.
    final fright = _scared > 0
        ? math.sin(math.min(1, (2.2 - _scared) / 0.5) * math.pi / 2) *
              4 *
              kTile *
              math.min(1, _scared / 0.6)
        : 0.0;
    moveTo(Vector2(x - size.x / 2, flock.row * kTile + wave - lift - fright));
  }

  @override
  void render(Canvas canvas) {
    final fade = _u > 1.0
        ? (1 - (_u - 1.0) * 6).clamp(0.0, 1.0)
        : _u < 0.06
        ? (_u / 0.06).clamp(0.0, 1.0)
        : 1.0;
    if (fade <= 0) return;
    // Yandan süzülen kuş: geniş açık kanatlar (basılan yer), küçük gövde,
    // baş ve kuyruk; kanatlar ağır ağır çırpar.
    final flap = math.sin(_t * 5 + offset * 0.05);
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.scale(1.35);
    canvas.translate(-size.x / 2, 0);
    final ink = Paint()
      ..color = const Color(0xFF14201E).withValues(alpha: fade);
    final cx = size.x / 2;
    final tip = 6 * flap;
    final wings = Path()
      ..moveTo(cx - 22, 1 - tip)
      ..quadraticBezierTo(cx - 10, -3 - tip * 0.4, cx, 3)
      ..quadraticBezierTo(cx + 10, -3 - tip * 0.4, cx + 22, 1 - tip)
      ..quadraticBezierTo(cx + 10, 2 - tip * 0.2, cx, 7)
      ..quadraticBezierTo(cx - 10, 2 - tip * 0.2, cx - 22, 1 - tip)
      ..close();
    canvas.drawPath(wings, ink);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 2, 5), width: 14, height: 6),
      ink,
    );
    canvas.drawCircle(Offset(cx + 10, 3.5), 2.6, ink);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 5, 5)
        ..lineTo(cx - 12, 3)
        ..lineTo(cx - 12, 8)
        ..close(),
      ink,
    );
    // Sırtında ay ışığı: basılacak yer seçilsin.
    canvas.drawLine(
      Offset(cx - 16, 0.5 - tip * 0.7),
      Offset(cx + 16, 0.5 - tip * 0.7),
      Paint()
        ..color = const Color(0xFFBFF5E4).withValues(alpha: 0.45 * fade)
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }
}

/// Testler için: Sâye bir kuşun üstünde mi.
bool onBird(Player p) => p.riding is BirdDeck;

/// Sürünün konduğu yer: uçurumun ötesinde, Ayna Salonu'nun önünde otuz
/// kuştan bir halka. Sâye yaklaşınca havalanıp bir kez halka çizerek
/// döner, sonra yine konar (Simurg'u arayan otuz kuş: sonunda aynada
/// kendilerini görürler).
class BirdRing extends PositionComponent with HasGameReference<GolgeGame> {
  BirdRing(Vector2 feet) : super(position: feet, priority: 16);

  static const int count = 30;
  static const double flight = 4;

  double _t = 0;
  double? _fly;
  bool _seen = false;

  /// Halka havada mı.
  bool get flying => _fly != null;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final f = _fly;
    if (f != null) {
      _fly = f + dt;
      if (_fly! > flight) _fly = null;
      return;
    }
    final p = game.player;
    if (!_seen &&
        p != null &&
        (p.center.x - position.x).abs() < 5 * kTile &&
        (p.center.y - position.y).abs() < 3 * kTile) {
      _seen = true;
      _fly = 0;
      GameAudio.instance.play('bird', volume: 0.6);
      GameAudio.instance.play('glide', volume: 0.4);
    }
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF14201E);
    final f = _fly;
    for (var i = 0; i < count; i++) {
      // Konmuş: yerde, iki sıra yay; uçarken: havada dönen bir halka.
      final perch = Offset(
        (i - count / 2) * 7.0 + (i.isEven ? 0 : 3.5),
        i.isEven ? -2.0 : -6.0,
      );
      var at = perch;
      var flying = false;
      if (f != null) {
        final k = math.sin(math.min(1.0, f / flight) * math.pi);
        final a = i / count * 2 * math.pi + f * 1.6;
        final ring = Offset(math.cos(a) * 70, -90 + math.sin(a) * 40);
        at = Offset.lerp(perch, ring, k)!;
        flying = k > 0.1;
      }
      canvas.save();
      canvas.translate(at.dx, at.dy);
      if (flying) {
        final flap = math.sin(_t * 14 + i);
        canvas.drawPath(
          Path()
            ..moveTo(-6, -flap * 3)
            ..quadraticBezierTo(-2, -1, 0, 1)
            ..quadraticBezierTo(2, -1, 6, -flap * 3)
            ..quadraticBezierTo(2, 1, 0, 3)
            ..quadraticBezierTo(-2, 1, -6, -flap * 3)
            ..close(),
          ink,
        );
      } else {
        final peck = math.sin(_t * 2 + i * 1.7) > 0.92 ? 1.5 : 0.0;
        canvas.drawOval(const Rect.fromLTWH(-3.5, -4, 7, 4.5), ink);
        canvas.drawCircle(Offset(3, -4.5 + peck), 1.8, ink);
      }
      canvas.restore();
    }
  }
}
