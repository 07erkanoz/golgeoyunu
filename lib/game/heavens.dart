import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'myth_figures.dart';
import 'player.dart';

// XVI · Göğün Katları (docs/MITOLOJI.md §5): Kam'ın davulu, ay katı, gün
// katı, Umay kuşunun gölgesi, Ülgen'in kapısı, Tulpar'la fırtınadan kaçış.

/// Kam'ın davulu: bölümün ortak ritmi. Her vuruşta bir bulut takımı belirir,
/// öbürü söner; ritim hem duyulur hem görülür.
class KamDrum extends Component with HasGameReference<GolgeGame> {
  KamDrum() : super(priority: 0);

  /// Bir vuruştan ötekine geçen süre.
  static const double beat = 1.4;

  double t = 0;
  int _last = -1;

  /// Şu anki vuruşun sırası.
  int get index => (t / beat).floor();

  /// Vuruşun içindeki yer (0-1).
  double get phase => (t / beat) % 1;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (index != _last) {
      _last = index;
      // Yakındaysa davul duyulur.
      final p = game.player;
      if (p != null && !p.isDead) {
        for (final c in game.world.children.whereType<DrumCloud>()) {
          if ((c.position.x - p.center.x).abs() < 16 * kTile) {
            GameAudio.instance.play('drum', volume: 0.55, minGapMs: 300);
            break;
          }
        }
      }
    }
  }
}

/// Davul bulutu: iki takımdan birine bağlıdır; takımı vuruşta belirir, bir
/// sonraki vuruşta söner. Sönmeden önce titrer, belirmeden önce silik görünür.
class DrumCloud extends Deck {
  DrumCloud(Vector2 cell, int tiles, {required this.group})
    : super(
        position: Vector2(cell.x, cell.y),
        size: Vector2(tiles * kTile, 10),
      );

  /// 0 ya da 1: çift ya da tek vuruşlarda belirir.
  final int group;
  KamDrum? _drum;
  double _show = 0;

  KamDrum? get drum =>
      _drum ??= game.world.children.whereType<KamDrum>().firstOrNull;

  /// Şu an üstüne basılır mı.
  bool get on {
    final d = drum;
    if (d == null) return true;
    return d.index % 2 == group;
  }

  @override
  bool get active => on;

  @override
  void step(double dt) {
    _show += ((on ? 1.0 : 0.0) - _show) * math.min(1, dt * 14);
  }

  @override
  void render(Canvas canvas) {
    final d = drum;
    final phase = d?.phase ?? 0;
    // Sönmek üzereyken titrer; sırası gelecekken silik görünür.
    final flicker = on && phase > 0.78
        ? 0.55 + 0.45 * math.sin(phase * 80)
        : 1.0;
    final ghost = !on && phase > 0.7 ? 0.25 : 0.08;
    final a = math.max(_show * flicker, ghost);
    final paint = Paint()..color = const Color(0xFFF4F2FF).withValues(alpha: a);
    final w = size.x;
    for (var x = 6.0; x < w; x += 12) {
      canvas.drawCircle(Offset(x, 4 + math.sin(x) * 1.5), 7, paint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 2, w, 8),
        const Radius.circular(4),
      ),
      paint,
    );
    // Davul vuruşunun izi: belirince bir halka açılır.
    if (on && phase < 0.25) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, 5),
          width: w + phase * 120,
          height: 10 + phase * 20,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFFFFFFF)
              .withValues(alpha: 0.6 * (1 - phase * 4)),
      );
    }
  }
}

/// Gün katı: göğün ışığı yakar. Yalnızca üstünde uçan Umay kuşunun (Hüma)
/// gölgesinde yürünür. Gölgenin dışında kalan yanar.
class ScorchZone extends PositionComponent with HasGameReference<GolgeGame> {
  ScorchZone(this.area) : super(priority: 24);

  final Rect area;
  double _t = 0;

  /// Kuşun gölgesinin yarı genişliği.
  static const double shade = 2.4 * kTile;

  /// Bu kadar saniye güneşte kalan yanar.
  static const double burnTime = 1.8;

  /// Kuşun hızı (piksel/sn): Sâye'nin koşusundan yavaş; gölgesine eşlik
  /// edilir.
  static const double birdSpeed = 110;

  /// Kuş zonun bir ucundan öbürüne bu kadar saniyede gider.
  double get sweep => (area.width - 2 * kTile) / birdSpeed;

  double burn = 0;

  /// Kuşun x'i: zonun üstünde gidip gelir.
  double get birdX {
    final k = (_t / sweep) % 2;
    final u = k < 1 ? k : 2 - k;
    final s = u * u * (3 - 2 * u);
    return area.left + kTile + s * (area.width - 2 * kTile);
  }

  int get _facing => ((_t / sweep) % 2) < 1 ? 1 : -1;

  bool inShade(double x) => (x - birdX).abs() < shade;

  /// Kuş, Sâye zona yaklaşana dek girişte bekler; uçuşu o an başlar.
  /// (Eskiden bölüm açılınca başlıyordu: varınca kuş nerede olursa,
  /// ona göre bazen uzun süre beklemek gerekiyordu.)
  bool _awake = false;

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (!_awake &&
        p != null &&
        area.inflate(3 * kTile).contains(Offset(p.center.x, p.center.y))) {
      _awake = true;
    }
    if (_awake) _t += dt;
    if (p == null || p.isDead) {
      burn = 0;
      return;
    }
    final inside = area.contains(Offset(p.center.x, p.center.y));
    if (inside) game.meetMyth('umayKusu');
    if (inside && !inShade(p.center.x)) {
      burn += dt / burnTime;
      if (burn >= 1) {
        burn = 0;
        p.die(cause: DeathCause.light);
      }
    } else {
      burn = math.max(0, burn - dt * 1.5);
    }
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final soft = area.inflate(3 * kTile);
    if (!view.overlaps(soft)) return;
    final x = birdX;
    // Zonun dibi zeminin içindedir; ışık zeminin yüzüne düşer.
    final ground = area.bottom - kTile;
    final top = math.max(soft.top, view.top - 40);
    final layer = Rect.fromLTRB(soft.left, top, soft.right, ground + 8);
    // Gün katının ışığı: gökten eğik inen altın huzmeler; kenarlarda erir,
    // içinde ısı tozu yükselir. Kuşun gölgesi huzmeleri keser.
    canvas.saveLayer(layer, Paint());
    final ray = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 9; i++) {
      final h = (i * 2654435761) & 0xffff;
      final cx = area.left + (i + 0.5) / 9 * area.width + (h % 40) - 20;
      final w0 = 18.0 + h % 26;
      final w1 = w0 * 2.4;
      final sway = math.sin(_t * 0.4 + i) * 10;
      final a = 0.10 + 0.06 * math.sin(_t * (0.7 + i * 0.13) + i);
      final skew = (layer.bottom - top) * 0.28;
      final beam = Path()
        ..moveTo(cx - w0 + sway - skew, top)
        ..lineTo(cx + w0 + sway - skew, top)
        ..lineTo(cx + w1, layer.bottom)
        ..lineTo(cx - w1, layer.bottom)
        ..close();
      ray.shader = ui.Gradient.linear(Offset(0, top), Offset(0, layer.bottom), [
        const Color(0xFFFFE8A8).withValues(alpha: a * 0.6),
        const Color(0xFFFFD27A).withValues(alpha: a),
      ]);
      canvas.drawPath(beam, ray);
    }
    // Zeminde ışığın yaktığı parlak şerit.
    canvas.drawRect(
      Rect.fromLTRB(area.left, ground - 30, area.right, ground + 8),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, ground - 30),
          Offset(0, ground + 8),
          const [Color(0x00FFE0A0), Color(0x55FFE0A0)],
        ),
    );
    // Isı tozu.
    final mote = Paint()
      ..color = const Color(0xFFFFF0C8).withValues(alpha: 0.7);
    for (var i = 0; i < 40; i++) {
      final h = (i * 40503) & 0xffff;
      final mx = area.left + (h % 1000) / 1000 * area.width;
      final u = (_t * (0.08 + (h % 7) * 0.01) + (h % 97) / 97) % 1.0;
      final my = ground - u * area.height;
      canvas.drawCircle(Offset(mx + math.sin(_t + i) * 6, my), 1.2, mote);
    }
    // Kuşun gölgesi: huzmeleri silen serin bir sütun.
    canvas.drawRect(
      Rect.fromLTRB(x - shade * 1.3, top, x + shade * 1.3, layer.bottom),
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = ui.Gradient.linear(
          Offset(x - shade * 1.3, 0),
          Offset(x + shade * 1.3, 0),
          const [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          const [0, 0.25, 0.75, 1],
        ),
    );
    // Kenarlarda eriyen maske (dikdörtgen görünmesin).
    canvas.drawRect(
      layer,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          layer.centerLeft,
          layer.centerRight,
          const [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          const [0, 0.14, 0.86, 1],
        ),
    );
    canvas.restore();
    // Gölgenin içi serin ve mavimsi; yerde koyu bir leke.
    canvas.drawRect(
      Rect.fromLTRB(x - shade, ground - 6.5 * kTile, x + shade, ground),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x - shade, 0),
          Offset(x + shade, 0),
          const [Color(0x00203048), Color(0x66203048), Color(0x00203048)],
          const [0, 0.5, 1],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, ground - 2),
        width: shade * 1.8,
        height: 10,
      ),
      Paint()..color = const Color(0x88101828),
    );
    // Kuş.
    canvas.save();
    // Kuş zeminin birkaç kat üstünde uçar: gölgesiyle birlikte görünür.
    canvas.translate(x, ground - 6.5 * kTile + math.sin(_t * 1.6) * 6);
    canvas.scale(_facing * 1.1, 1.1);
    MythFigures.umayBird(canvas, _t);
    canvas.restore();
    // Yanma: Sâye güneşte kaldıkça ekran beyazlaşır.
    if (burn > 0) {
      canvas.drawRect(
        view,
        Paint()..color = const Color(0xFFFFF6E0).withValues(alpha: 0.55 * burn),
      );
    }
  }
}

/// Tulpar: göğün kanatlı atı. Sâye dokununca sırtına alır: atla koşulur,
/// havada zıplayınca kanat çırpar (yükselir).
class TulparMount extends PositionComponent with HasGameReference<GolgeGame> {
  TulparMount(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        size: Vector2(44, 38),
        anchor: Anchor.bottomCenter,
        priority: 19,
      );

  static const double drawScale = 0.38;

  // Koşu: adım döngüsü, yürüyüş miktarı, havada uzanma.
  double _phase = 0;
  double _gait = 0;
  double _leap = 0;
  double _t = 0;
  int facing = 1;

  Offset get glowCenter => Offset(position.x, position.y - 24);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (!game.onHorse) {
      if (!p.isDead &&
          (p.center.x - position.x).abs() < 26 &&
          (p.position.y + Player.h - position.y).abs() < 20) {
        game.mountHorse(winged: true);
      }
      return;
    }
    final nx = p.position.x + Player.w / 2;
    // Adım döngüsü yürünen yoldan (dörtnala ~70 piksel); havada uzanır.
    _phase = (_phase + (nx - position.x).abs() / 70) % 1.0;
    final speed = (p.velocity.x.abs() / 260).clamp(0.0, 1.0);
    _gait += (speed - _gait) * math.min(1, dt * 6);
    _leap += ((p.onGround ? 0.0 : 1.0) - _leap) * math.min(1, dt * 9);
    position.setValues(nx, p.position.y + Player.h);
    facing = p.facing;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(facing * drawScale, drawScale);
    // Uçarken kanatlar hızlı çırpar.
    final p = game.player;
    final fly = game.onHorse && p != null && !p.onGround;
    MythFigures.tulpar(
      canvas,
      fly ? _t * 4 : _t,
      shape: MythFigures.horseRun(_phase, weight: _gait, leap: _leap),
    );
    canvas.restore();
  }
}

/// Erlik'in fırtınası: Sâye Tulpar'a binince soldan gelir; yetişirse söndürür.
/// [endX]'e varınca dağılır.
class StormWall extends PositionComponent with HasGameReference<GolgeGame> {
  StormWall(this.startX, this.endX) : super(priority: 30);

  final double startX;
  final double endX;
  bool _awake = false;
  bool _done = false;
  double _speed = 0;
  double _t = 0;
  double _fade = 0;

  bool get awake => _awake && !_done;

  /// Fırtınanın ön yüzü (dünya x).
  double get front => position.x;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_done) {
      _fade = math.max(0, _fade - dt * 0.6);
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      if (game.onHorse && !p.isDead) {
        _awake = true;
        position.x = p.center.x - 9 * kTile;
        _speed = 60;
        GameAudio.instance.play('thunder', volume: 0.7);
        game.scare(0.8);
      }
      return;
    }
    _fade = math.min(1, _fade + dt);
    if (p.center.x > endX) {
      _done = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;
    _speed = math.min(165, _speed + dt * 30);
    position.x += _speed * dt;
    // Çok geride kalırsa yetişir.
    position.x = math.max(position.x, p.center.x - 12 * kTile);
    final gap = p.center.x - position.x;
    game.threat = math.max(game.threat, (1 - gap / 320).clamp(0.0, 1.0));
    GameAudio.instance.dread(((420 - gap) / 380).clamp(0.2, 1.0));
    if (gap < 10) p.die(cause: DeathCause.dark);
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final view = game.camera.visibleWorldRect;
    final a = _fade;
    final right = 0.0;
    final left = view.left - position.x - 40;
    if (right < left) return;
    final rect = Rect.fromLTRB(
      left,
      view.top - position.y - 20,
      right,
      view.bottom - position.y + 20,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.centerLeft, rect.centerRight, [
          const Color(0xFF0A0614).withValues(alpha: a),
          const Color(0xFF2A1840).withValues(alpha: 0.9 * a),
        ]),
    );
    // Dalgalı ön yüz ve şimşekler.
    final edge = Path()..moveTo(0, rect.top);
    for (var y = rect.top; y <= rect.bottom; y += 20) {
      edge.lineTo(math.sin(_t * 3 + y / 30) * 10, y);
    }
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFB27AE8).withValues(alpha: 0.8 * a),
    );
    if ((_t * 1.7) % 1 < 0.08) {
      final bolt = Path()..moveTo(-30, rect.top + 20);
      var x = -30.0;
      for (var y = rect.top + 20; y < rect.bottom - 40; y += 30) {
        x += math.sin(y * 13) * 18;
        bolt.lineTo(x, y);
      }
      canvas.drawPath(
        bolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFF0E8FF).withValues(alpha: a),
      );
    }
  }
}
