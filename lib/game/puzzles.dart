import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'ark_animals.dart';
import 'feedback.dart';
import 'audio.dart';
import 'creatures.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'hints.dart';
import 'level.dart';
import 'levels.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'perde.dart';
import 'persist.dart';
import 'player.dart';
import 'rig.dart';
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
  PhasePlank(Vector2 cell, int tiles, {required this.shade, this.cold = false})
    : super(
        position: Vector2(cell.x, cell.y),
        size: Vector2(tiles * kTile, 10),
      );

  final bool shade;

  /// Kandilci yolu: yalnız Kandilcinin soğuk feneriyle belirir (Sâye'nin
  /// sıcak ışığı göstermez). Kandilciler ışığı kendi yollarına saklamış.
  final bool cold;
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
      final at = position + Vector2(x, 4);
      if (cold ? game.coldLitAt(at) : game.litAt(at)) {
        lit = true;
        break;
      }
    }
    final want = shade ? !lit : lit;
    // Biraz gecikmeli: ışık kenarında titreyip durmasın. Kandilci yolu
    // sönmeden önce daha uzun bekler ve titrer: üstündeki kaçabilsin.
    _fading = _on && !want;
    if (want != _on) {
      _hold += dt;
      if (_hold > (want ? 0.08 : (cold ? 0.8 : 0.2))) {
        _on = want;
        _hold = 0;
      }
    } else {
      _hold = 0;
    }
    _show += ((_on ? 1.0 : 0.0) - _show) * math.min(1, dt * 8);
  }

  double _hold = 0;

  /// Yanıyor ama ışık gitti: sönmek üzere (Kandilci yolunda titrer).
  bool _fading = false;

  @override
  void render(Canvas canvas) {
    final shown = _show;
    if (cold && _fading) _show *= 0.45 + 0.55 * (0.5 + 0.5 * math.sin(_t * 26));
    _render(canvas);
    _show = shown;
  }

  void _render(Canvas canvas) {
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
      // Kandilci yolu aynı biçimde, soğuk camgöbeği.
      // Katman tahtanın çevresiyle sınırlı (sınırsız katman her karede
      // bütün ekran kadar çizim demekti).
      if (cold) {
        canvas.saveLayer(
          Rect.fromLTWH(-10, -14, w + 20, 34),
          Paint()..colorFilter = _coldTint,
        );
      }
      if (_show < 0.98) {
        final dot = Paint()
          ..color = kWarmLight.withValues(alpha: cold ? 0.3 : 0.18);
        for (var x = 4.0; x < w; x += 8) {
          canvas.drawCircle(Offset(x, 4), 1.1, dot);
        }
      }
      if (_show > 0.02) {
        // Işıktan dökülmüş tahta: içi akkor, kenarları yanar, altına ve
        // üstüne yumuşak ışık taşar.
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, 8),
          const Radius.circular(3),
        );
        // Hale: bulanıklık filtresi yerine dikey degrade (her yanan tahta
        // için her karede bulanıklık telefonda pahalıydı).
        final halo = Rect.fromLTWH(-5, -7, w + 10, 22);
        final hc = const Color(0xFFFFD08A)
            .withValues(alpha: (cold ? 0.5 : 0.28) * _show);
        canvas.drawRRect(
          RRect.fromRectAndRadius(halo, const Radius.circular(9)),
          Paint()
            ..shader = ui.Gradient.linear(
              halo.topCenter,
              halo.bottomCenter,
              [hc.withValues(alpha: 0), hc, hc, hc.withValues(alpha: 0)],
              const [0, 0.35, 0.65, 1],
            ),
        );
        canvas.drawRRect(
          body,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              const Offset(0, 8),
              [
                const Color(0xFFFFF6DC).withValues(alpha: 0.95 * _show),
                const Color(0xFFFFC870).withValues(alpha: 0.8 * _show),
                const Color(0xFFE08A40).withValues(alpha: 0.6 * _show),
              ],
              const [0, 0.45, 1],
            ),
        );
        // İçinde akan ışık damarları.
        final vein = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5 * _show);
        for (var k = 0; k < 2; k++) {
          final y = 2.6 + k * 3;
          final path = Path()..moveTo(2, y);
          for (var x = 2.0; x <= w - 2; x += 6) {
            path.lineTo(x, y + math.sin(x * 0.2 + _t * 2 + k) * 0.9);
          }
          canvas.drawPath(path, vein);
        }
        for (var x = 10.0; x < w; x += 22) {
          final mote = math.sin(_t * 2 + x) * 3;
          canvas.drawCircle(
            Offset(x, -4 + mote),
            1.2,
            Paint()..color = kWarmLight.withValues(alpha: 0.6 * _show),
          );
        }
      }
      if (cold) canvas.restore();
    }
  }

  /// Sıcak ışık renklerini fenerin soğuk camgöbeğine çevirir.
  static const _coldTint = ColorFilter.matrix([
    0.25, 0.1, 0.0, 0, 0, //
    0.45, 0.45, 0.1, 0, 0, //
    0.5, 0.4, 0.25, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
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

  /// Üstünde yürünen süreyle büyüyen çatlak (0 – 1).
  double _strain = 0;

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
      // Basıldıkça çatlak büyür: tahtanın kırılabileceği görülür (yalnız
      // Kandilci'nin ağırlığı kırar).
      _strain = math.min(1, _strain + dt * 0.5);
      if (_creak <= 0) {
        _creak = 0.7;
        GameAudio.instance.play('creak', volume: 0.5);
        game.dust(
          Vector2(p.center.x, position.y + 9),
          color: const Color(0xFF6A5236),
          count: 4,
          falling: true,
        );
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
    if (!broken) {
      for (var i = 0; i < tiles; i++) {
        _board(canvas, i * kTile.toDouble(), i);
      }
      // Çatlaklar: basıldıkça uzar.
      if (_strain > 0.05) {
        final crack = Paint()
          ..color = const Color(0xFF0E0906).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (var i = 0; i < tiles; i++) {
          final x = i * kTile + kTile * 0.5;
          final len = 3 + 9 * _strain;
          canvas.drawPath(
            Path()
              ..moveTo(x - len, 2)
              ..lineTo(x - len * 0.3, 5)
              ..lineTo(x + len * 0.2, 3)
              ..lineTo(x + len, 7),
            crack,
          );
        }
      }
      // İki uçta paslı çivi ve sarkan kopuk ip.
      final rope = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF5A4A34);
      canvas.drawPath(
        Path()
          ..moveTo(2, 7)
          ..quadraticBezierTo(-2, 13, 0, 20),
        rope,
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
        Paint()..color = const Color(0xFF3A3024).withValues(alpha: a),
      );
      canvas.restore();
    }
  }

  /// Çürümüş tahta: gri-yeşile dönmüş, uçları kırık, delikli, yosunlu;
  /// ortası hafifçe çökmüş.
  void _board(Canvas canvas, double x, int i) {
    const w = kTile - 2.0;
    final sag = 1.2;
    final top = Path()
      ..moveTo(x + 1, 0.6)
      ..quadraticBezierTo(x + w / 2, sag, x + w, 0.4)
      ..lineTo(x + w - 1, 3)
      ..lineTo(x + w, 6.6)
      ..quadraticBezierTo(x + w / 2, 7 + sag, x + 2, 6.8)
      ..lineTo(x + 1, 4)
      ..close();
    canvas.drawPath(
      top,
      Paint()
        ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x, 7), const [
          Color(0xFF4E4434),
          Color(0xFF1E1A12),
        ]),
    );
    canvas.drawLine(
      Offset(x + 2, 1),
      Offset(x + w - 2, 0.9),
      Paint()
        ..color = const Color(0xFF9A8A6A).withValues(alpha: 0.35)
        ..strokeWidth = 0.8,
    );
    // Çatlaklar ve delikler.
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFF0E0A06);
    final h = (i * 2654435761) & 0xff;
    canvas.drawPath(
      Path()
        ..moveTo(x + 6 + h % 5, 0.8)
        ..lineTo(x + 10 + h % 4, 3.4)
        ..lineTo(x + 8 + h % 6, 6.6),
      crack,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + 20, 1)
        ..lineTo(x + 17, 4)
        ..lineTo(x + 22, 6.4),
      crack,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 14 + h % 6, 3.8), width: 3, height: 2),
      Paint()..color = const Color(0xFF0A0806),
    );
    // Yosun.
    canvas.drawOval(
      Rect.fromLTWH(x + 3 + h % 9, -0.6, 7, 2.2),
      Paint()..color = const Color(0xFF3A5A2A).withValues(alpha: 0.6),
    );
    // Paslı çivi.
    canvas.drawCircle(
      Offset(x + 3, 3.6),
      0.8,
      Paint()..color = const Color(0xFF8A4A26),
    );
  }
}

// ============================================================== Su haznesi

/// Vanalarla dolup boşalan su haznesi. Suyun içinde kalan boğulur; yüzen
/// tahta suyun yüzünde durur ve üstündekini taşır.
class WaterBasin extends Component
    with HasGameReference<GolgeGame>, Persistent {
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

  @override
  String get persistKind => 'basin';

  /// Vanayla ayarlanan seviye saklanır; tufan (kovalamaca) baştan başlar.
  @override
  Object? captureState() => flooding ? null : [target];

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    final t = numbers(state, 1);
    if (t != null) {
      target = t[0].clamp(high, area.bottom);
      surface = target;
    }
    return [this];
  }

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

  /// Su durduğu an: yüzeyde halkalar yayılır, kenar parlar (çekilmenin ya
  /// da dolmanın bittiği küçük ekranda da görülsün, duyulsun).
  double _settle = 0;

  /// Su durdu mu (son hareketten beri, testler için).
  bool get settledFlash => _settle > 0;

  @override
  void update(double dt) {
    _t += dt;
    _settle = math.max(0, _settle - dt / 1.6);
    if (_delay > 0) {
      _delay -= dt;
    } else if (moving) {
      final step = speed * dt;
      surface = (surface - target).abs() <= step
          ? target
          : surface + step * (target > surface ? 1 : -1);
      if (!moving && !flooding) {
        _settle = 1;
        GameAudio.instance.play('splash', volume: 0.8);
      }
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
    // Sarnıcın suyu gibi serin bir ton: taştan ayrılır.
    canvas.drawRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(body.topLeft, body.bottomLeft, [
          const Color(0xFF1A3034).withValues(alpha: 0.9),
          const Color(0xFF0C0605).withValues(alpha: 0.95),
        ]),
    );
    // Yüzey: dalgalı, parlak bir kenar; su hareket ederken çalkalanır,
    // durduğu an bir kez parlar.
    final glow = _settle;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE6A066)
          .withValues(alpha: (moving ? 0.75 : 0.6) + 0.25 * glow)
      ..strokeWidth = 2 + glow;
    final wave = Path()..moveTo(area.left, surface + 1);
    for (var x = area.left + 4; x <= area.right; x += 4) {
      final wob =
          math.sin(_t * (moving ? 6 : 2) + x * 0.13) * (moving ? 2.2 : 1.2);
      wave.lineTo(x, surface + 1 + wob);
    }
    canvas.drawPath(wave, edge);
    canvas.drawRect(
      Rect.fromLTRB(area.left, surface, area.right, surface + 6),
      Paint()
        ..color = const Color(0xFFE6A066).withValues(alpha: 0.16 + 0.2 * glow),
    );
    // Durunca yüzeyde ortadan yayılan halkalar.
    if (glow > 0) {
      final k = 1 - glow;
      for (var i = 0; i < 2; i++) {
        final r = (k * 1.4 - i * 0.3).clamp(0.0, 1.0);
        if (r <= 0) continue;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(area.center.dx, surface + 2),
            width: area.width * r,
            height: 8 * r + 2,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFFFD8A8).withValues(alpha: 0.6 * (1 - r)),
        );
      }
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
    // Karanlık suda seçilsin: açık kahve tahta, ışık alan üst kenar, iki
    // kalas arası derz ve ip bağları; çevresinde suyun halkaları. (Eskiden
    // neredeyse siyahtı, üstüne çıkılacağı anlaşılmıyordu.)
    final w = size.x;
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE8C08A)
          .withValues(alpha: 0.25 + 0.1 * math.sin(_t * 2));
    final spread = 4 + 3 * (0.5 + 0.5 * math.sin(_t * 1.3));
    canvas.drawOval(Rect.fromLTRB(-spread, 6, w + spread, 13), ripple);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, 9),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF7A4A28));
    canvas.drawRect(
      Rect.fromLTWH(0, 5, w, 4),
      Paint()..color = const Color(0xFF4A2A16),
    );
    // Ortadaki derz ve ip bağları.
    final dark = Paint()
      ..color = const Color(0xFF2A160C)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w / 2, 1), Offset(w / 2, 8), dark);
    for (final x in [w * 0.22, w * 0.78]) {
      canvas.drawLine(Offset(x - 2, 0), Offset(x - 2, 9), dark);
      canvas.drawLine(Offset(x + 1, 0), Offset(x + 1, 9), dark);
    }
    // Işık alan üst kenar.
    canvas.drawLine(
      const Offset(1.5, 0.8),
      Offset(w - 1.5, 0.8),
      Paint()
        ..color = const Color(0xFFE8B880).withValues(alpha: 0.9)
        ..strokeWidth = 1.4,
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
    // Kamera hazneye: suyun yükselişi ya da çekilişi görünsün. Oyuncu
    // haznenin içindeyse (su onun çevresinde yükselecekse) kamera ondan
    // ayrılmaz: yukarıya bakarken aşağıda boğuluyordu.
    final p = game.player;
    final inside =
        p != null &&
        b.area.inflate(kTile).contains(Offset(p.center.x, p.center.y));
    if (!inside) {
      game.focus(
        Vector2(b.area.center.dx, (fill ? b.high : b.low) - kTile),
        hold: fill ? 2.6 : 2.0,
      );
    }
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
    // Bakır boru: yerden çıkar, dirsek, flanş ve somunlar.
    final pipe = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-3.5, 0),
        const Offset(3.5, 0),
        const [Color(0xFF8A5A3A), Color(0xFF4A2A18), Color(0xFF241408)],
        const [0, 0.45, 1],
      );
    canvas.drawRect(const Rect.fromLTWH(-3.5, -14, 7, 14), pipe);
    for (final y in [-3.0, -13.0]) {
      canvas.drawRect(
        Rect.fromLTWH(-5, y - 1.5, 10, 3),
        Paint()..color = const Color(0xFF3A2416),
      );
      for (final x in [-3.5, 3.5]) {
        canvas.drawCircle(
          Offset(x, y),
          0.8,
          Paint()..color = const Color(0xFFB08A60),
        );
      }
    }
    // Patina lekesi.
    canvas.drawOval(
      const Rect.fromLTWH(-3, -10, 4, 3),
      Paint()..color = const Color(0xFF4A7A68).withValues(alpha: 0.5),
    );
    // Dökme demir çark: kalın jant, kıvrık kollar, ortada göbek.
    canvas.save();
    canvas.translate(0, -18);
    canvas.rotate(_spin);
    canvas.drawCircle(
      Offset.zero,
      8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..color = const Color(0xFF1E1A18),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 8.5),
      math.pi * 1.1,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0xFFB0A090).withValues(alpha: 0.55),
    );
    final spoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E1A18);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(
            math.cos(a + 0.4) * 5,
            math.sin(a + 0.4) * 5,
            math.cos(a) * 8,
            math.sin(a) * 8,
          ),
        spoke,
      );
    }
    // Tutamak düğmesi.
    canvas.drawCircle(
      const Offset(0, -8.5),
      1.6,
      Paint()..color = const Color(0xFF4A2C18),
    );
    canvas.restore();
    canvas.drawCircle(
      const Offset(0, -18),
      2.4,
      Paint()..color = const Color(0xFF2A2624),
    );
    canvas.drawCircle(
      const Offset(0, -18),
      1.3,
      Paint()
        ..color = (fill ? const Color(0xFF7FB8D0) : const Color(0xFFD08A5A))
            .withValues(alpha: 0.9),
    );
  }
}

// ================================================================== Ayna

/// Döndürülebilen ayna: huzmeyi 90° kırar. ↑ ile `/` ve `\` arasında döner.
class Mirror extends PositionComponent
    with HasGameReference<GolgeGame>, Usable, Persistent {
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
  String get persistKind => 'mirror';

  @override
  Object? captureState() => slash ? 1 : 0;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1 || state == 0) slash = state == 1;
    return [this];
  }

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
    // Ahşap ayak: oyma direk ve geniş taban.
    final wood = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-3, 0),
        const Offset(3, 0),
        const [Color(0xFF6A4226), Color(0xFF2A180C)],
      );
    canvas.drawRect(const Rect.fromLTWH(-2.2, 4, 4.4, 11), wood);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, 14, 16, 3.5),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF3A2414),
    );
    canvas.drawCircle(
      const Offset(0, 5),
      2.6,
      Paint()..color = const Color(0xFF8A6A40),
    );
    canvas.save();
    canvas.rotate(_angle);
    // Pirinç çerçeveli cilalı ayna: yüzünde gök yansır, ışıkta parlar.
    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-16, -4, 32, 8),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -4),
          const Offset(0, 4),
          const [Color(0xFFD8B070), Color(0xFF6A4A20)],
        ),
    );
    final glass = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-14, -2.4, 28, 3.6),
      const Radius.circular(1.6),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-14, 0),
          const Offset(14, 0),
          const [
            Color(0xFF8AA8C0),
            Color(0xFFF2F6FA),
            Color(0xFF7A98B0),
            Color(0xFFDCE8F2),
          ],
          const [0, 0.35, 0.6, 1],
        ),
    );
    // Süslü uçlar.
    for (final x in [-16.0, 16.0]) {
      canvas.drawCircle(
        Offset(x, 0),
        2.2,
        Paint()..color = const Color(0xFFB08A50),
      );
    }
    canvas.restore();
  }
}

/// Işık kilidi: güneş oymalı taş. Huzme bir süre üstünde kalınca en yakın
/// kapı açılır.
class SunLock extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
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
  String get persistKind => 'sunlock';

  @override
  Object? captureState() => open ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      open = true;
      charge = 1;
    }
    return [this];
  }

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
      glowDot(canvas, Offset.zero, 34, kWarmLight, 0.5 * glow);
    }
    // Taşa oyulmuş güneş kilidi: dişli dış halka, ışınlar, ortada mühür.
    final stone = Paint()
      ..shader = ui.Gradient.radial(const Offset(-3, -3), 14, const [
        Color(0xFF5A4636),
        Color(0xFF1E1610),
      ]);
    final teeth = Path();
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      final r = i.isEven ? 13.0 : 11.2;
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? teeth.moveTo(pt.dx, pt.dy) : teeth.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(teeth..close(), stone);
    canvas.drawCircle(
      Offset.zero,
      9.5,
      Paint()..color = const Color(0xFF140E0A),
    );
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        const Color(0xFF6A4A2A),
        const Color(0xFFFFE6A8),
        glow,
      )!;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + _t * 0.25 * glow;
      ray.strokeWidth = i.isEven ? 1.8 : 1.1;
      canvas.drawLine(
        Offset(math.cos(a) * 4.2, math.sin(a) * 4.2),
        Offset(
          math.cos(a) * (i.isEven ? 8.6 : 7.2),
          math.sin(a) * (i.isEven ? 8.6 : 7.2),
        ),
        ray,
      );
    }
    canvas.drawCircle(Offset.zero, 3.4, Paint()..color = ray.color);
    canvas.drawCircle(
      Offset.zero,
      3.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF140E0A),
    );
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
class GiantPerde extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  GiantPerde(Vector2 cell, {this.puzzle = false})
    : super(
        position: Vector2(cell.x, cell.y + kTile),
        size: Vector2(widthTiles * kTile, heightTiles * kTile),
        priority: 3,
      );

  static const widthTiles = 14;
  static const heightTiles = 6;

  // ------------------------------------------------ Sarnıcın iki yüzü
  // Perdenin ardındaki kandil bir iple üç durak arasında kayar. Gölge
  // kandilden uzaklaştıkça büyüyerek perdeye düşer. Kapı, aynı anda iki
  // koşul tutunca açılır: dev gölgenin başı perdedeki göze değer, kavanozun
  // gerçek ışığı taştaki göze. İkisi ancak tek bir kandil durağında birlikte
  // sağlanır.

  /// Bu perde bulmaca mı (yanında ip var)?
  final bool puzzle;

  /// Kandilin durakları (perde genişliğine oranla) ve şimdiki durak.
  static const stops = [0.15, 0.5, 0.85];
  int stop = 2;
  double _lampX = 0.85;

  /// Gölgenin perdedeki işareti (genişliğe oranla) ve gölge başının yüksekliği.
  static const markAt = 0.9;
  static const _markY = 72.0;

  /// Kandilden uzaklaşan gölge bu kadar büyür (izdüşüm katsayısı).
  static const project = 1.6;

  bool solved = false;
  double _hold = 0;
  double _turnT = 0;
  double _markGlow = 0;
  bool _shadowOnMark = false;

  /// Bulmacada kandil (ışık) perdenin neresinde (dünya x).
  double get lampX => position.x + size.x * (puzzle ? _lampX : 0.55);

  /// Sâye [px]'teyken gölgesinin perdedeki yeri (dünya x).
  double shadowX(double px) {
    if (!puzzle) {
      return position.x + size.x * 0.5 + (px - position.x - size.x * 0.5) * 1.1;
    }
    return lampX + (px - lampX) * project;
  }

  /// Gölgenin göze düşmesi için Sâye'nin durması gereken yer (testler için).
  double standFor(int s) {
    final l = position.x + size.x * stops[s];
    return l + (position.x + size.x * markAt - l) / project;
  }

  /// Kandili bir durak sola çeker (en soldan sonra yeniden sağa döner).
  void pull() {
    stop = (stop + stops.length - 1) % stops.length;
    _pulls++;
    GameAudio.instance.play('creak', volume: 0.6);
    GameAudio.instance.play('chain', volume: 0.25);
  }

  @override
  String get persistKind => 'perde';

  @override
  Object? captureState() => puzzle ? [stop, solved ? 1 : 0] : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    final s = numbers(state, 2);
    if (s != null) {
      stop = s[0].round().clamp(0, stops.length - 1);
      _lampX = stops[stop];
      solved = s[1] == 1;
      if (solved) _markGlow = 1;
    }
    return [this];
  }

  void _solve() {
    solved = true;
    GameAudio.instance.play('memory', volume: 0.7);
    GameAudio.instance.play('gate', volume: 0.7);
    game.once('perdeSolved', S.of('perdeSolved'));
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final d = (g.position - position).length;
      if (g.position.x > position.x && d < bestD && !g.opening) {
        bestD = d;
        best = g;
      }
    }
    best?.opening = true;
  }

  /// Çözülünce açılacak kapı (sağdaki en yakın): göz levhası taşır.
  Gate? _myGate;

  Gate? get _targetGate {
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final d = (g.position - position).length;
      if (g.position.x > position.x && d < bestD) {
        bestD = d;
        best = g;
      }
    }
    return best;
  }

  // ------------------------------------------- öğretici geri bildirim
  // Bulmaca iki koşul ister; oyuncu hangisinin tuttuğunu görsün: kapıda iki
  // göz (üstte perdenin, altta taşın gözü), gölgenin başı perdedeki göze
  // yaklaştıkça göz ısınır, perdenin kirişinde kandilin üç durağı. Takılan
  // oyuncuya kademeli yardım: önce ipucu simgesi uyanır, sonra doğru durakta
  // yerde silik ayak izi belirir, yanlış duraktaysa ip "çek beni" der.

  /// İp kaç kez çekildi; bulmacanın önünde çözülmeden geçen süre.
  int _pulls = 0;
  double _stuckT = 0;

  /// Yardım düzeyi: 0 yok, 1 ipucu simgesi, 2 ayak izi ve çağıran ip.
  int help = 0;

  /// İki koşulun birlikte sağlandığı durak (hesaplanır; yoksa null).
  int? _goodStop;
  bool _goodKnown = false;
  double _stoneGlow = 0;
  double _footT = 0;

  int? get goodStop {
    if (_goodKnown) return _goodStop;
    _goodKnown = true;
    final stones = game.world.children.whereType<EyeStone>().toList();
    if (stones.isEmpty) return null;
    final good = <int>[];
    for (var i = 0; i < stops.length; i++) {
      final jar = Vector2(standFor(i), position.y - Player.h * 0.55);
      final ok = stones.any(
        (e) =>
            (e.position - jar).length < 200 * 0.7 * 0.9 &&
            game.level.lineOfSight(jar, e.position),
      );
      if (ok) good.add(i);
    }
    _goodStop = good.length == 1 ? good.first : null;
    return _goodStop;
  }

  /// Yanlış durakta takılan oyuncuya ip kendini çeker gibi gösterir.
  bool get beckon =>
      puzzle && !solved && help >= 2 && goodStop != null && stop != goodStop;

  void _updateHelp(double dt, Player p) {
    if (solved) return;
    final near =
        (p.center.x - (position.x + size.x / 2)).abs() <
            size.x / 2 + 3 * kTile &&
        (p.center.y - position.y).abs() < 4 * kTile;
    if (near) _stuckT += dt;
    if (help < 1 && (_stuckT > 40 || _pulls >= 4)) {
      help = 1;
      game.once(
        'perdeHelp:${game.levelIndex}',
        Hints.text('eyeStone'),
        hint: true,
      );
    }
    if (help < 2 && (_stuckT > 90 || _pulls >= 7)) help = 2;
  }

  void _updatePuzzle(double dt, Player p, bool inFront) {
    final gate = _myGate ??= _targetGate;
    final lit = game.world.children.whereType<EyeStone>().any((e) => e.lit);
    _stoneGlow = approach(_stoneGlow, lit || solved ? 1 : 0, dt, 0.2);
    if (gate != null) {
      gate.emblem = true;
      gate.emblemGlow = solved ? 1 : _markGlow;
      gate.emblemGlowStone = solved ? 1 : _stoneGlow;
    }
    _updateHelp(dt, p);
    _footT += dt;
    _lampX = approach(_lampX, stops[stop], dt, 0.35);
    _turnT = math.max(0, _turnT - dt);
    final settled = (_lampX - stops[stop]).abs() < 0.01;
    final s = _shadow();
    final on =
        s != null &&
        inFront &&
        settled &&
        !p.crouching &&
        (shadowX(s.$1) - (position.x + size.x * markAt)).abs() < 20;
    _shadowOnMark = on;
    // Sıcak–soğuk: gölgenin başı göze yaklaştıkça göz ısınır (değince tam).
    var warm = 0.0;
    if (s != null && inFront && settled && !p.crouching) {
      final d = (shadowX(s.$1) - (position.x + size.x * markAt)).abs();
      warm = (1 - d / 160).clamp(0.0, 1.0) * 0.5;
    }
    _markGlow = approach(_markGlow, on || solved ? 1 : warm, dt, 0.2);
    if (solved) return;
    // İlk kez göze değince gölge kendi başına döner (bulmacayı bozmaz).
    final key = 'perdeTurn:${game.levelIndex}';
    if (on && !game.eventSeen(key)) {
      game.markEvent(key);
      _turnT = 1.3;
      GameAudio.instance.play('breath', volume: 0.45);
    }
    _hold = on && lit ? _hold + dt : 0;
    if (_hold > 0.6) _solve();
  }

  /// Perdeye boyanmış göz: gölgenin başı değince ve bulmaca çözülünce
  /// içinden ışır.
  void _drawMark(Canvas canvas, double w) {
    final c = Offset(w * markAt, _markY);
    final g = _markGlow;
    if (g > 0.02) glowDot(canvas, c, 26, kWarmLight, 0.6 * g);
    final eye = Path()
      ..moveTo(c.dx - 13, c.dy)
      ..quadraticBezierTo(c.dx, c.dy - 10, c.dx + 13, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + 10, c.dx - 13, c.dy)
      ..close();
    canvas.drawPath(
      eye,
      Paint()
        ..color = const Color(0xFF2A1208).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c,
      3.6,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF2A1208),
          const Color(0xFFFFF0C8),
          g,
        )!.withValues(alpha: 0.85),
    );
  }

  /// Perdenin üst kirişinde kandilin üç durağı (şu anki yanar); takılan
  /// oyuncuya doğru durakta yerde silik ayak izi.
  void _drawStops(Canvas canvas, double w, double h) {
    // Kiriş ve üç durak halkası: kandil hangisindeyse o yanar; ip çekilince
    // sola kayar (en soldan sonra yeniden sağa).
    final rail = Paint()
      ..color = const Color(0xFF8A5A30)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(w * 0.08, 8), Offset(w * 0.92, 8), rail);
    for (var i = 0; i < stops.length; i++) {
      final c = Offset(w * stops[i], 8);
      final on = i == stop;
      if (on) glowDot(canvas, c, 16, kWarmLight, 0.8);
      final r = on ? 5.5 : 4.5;
      canvas.drawCircle(
        c,
        r,
        Paint()..color = on ? const Color(0xFFFFE6B0) : const Color(0xFF3A2414),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFC08458),
      );
    }
  }

  /// Takılan oyuncuya: doğru durakta, durulacak yerde zeminde silik ayak
  /// izi (perdenin yırtık kenarının dışında, zeminde; yerel: konum alt kenar).
  void _drawFootprint(Canvas canvas) {
    final good = goodStop;
    if (help < 2 || solved || good == null || stop != good) return;
    final x = standFor(good) - position.x;
    final pulse = 0.55 + 0.45 * math.sin(_footT * 3);
    glowDot(canvas, Offset(x, -4), 30, kWarmLight, 0.7 * pulse);
    final foot = Paint()
      ..color = const Color(0xFFFFEAC0).withValues(alpha: 0.9 * pulse);
    for (final dx in [-6.0, 6.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + dx, -2.5), width: 9, height: 4.5),
        foot,
      );
    }
  }

  // ----------------------------------------------- gizli alkış (S1c)
  // Oyun bitince sahne boş kalır. Sâye perdenin önünde zıplayıp hemen
  // çömelirse (seyirciye selam), perdenin ardında Karagöz seyircisinin
  // gölgeleri belirip alkışlar. Bir kez.

  double _jumpedT = 99;

  /// Alkışın başından beri geçen süre (-1: yok).
  double clapT = -1;
  static const _clapLen = 3.4;

  void _updateApplause(double dt, Player p, bool inFront) {
    if (clapT >= 0) {
      clapT += dt;
      if (clapT > _clapLen) clapT = -1;
      return;
    }
    if (!inFront) {
      _jumpedT = 99;
      return;
    }
    if (!p.onGround && p.velocity.y < -150) {
      _jumpedT = 0;
    } else {
      _jumpedT += dt;
    }
    if ((solved || !puzzle) &&
        p.onGround &&
        p.crouching &&
        _jumpedT < 2 &&
        game.calmMoment &&
        !game.secretSeen('alkis')) {
      clapT = 0;
      GameAudio.instance.play('clap', volume: 0.7);
      game.foundSecret('alkis');
    }
  }

  /// Seyirci: baş ve omuz gölgeleri (kavuklu, fesli, başı açık), elleri
  /// göğüslerinde birleşip ayrılır.
  void _drawAudience(Canvas canvas, double w, double h) {
    if (clapT < 0) return;
    final a =
        math.min(1.0, clapT / 0.4) * math.min(1.0, (_clapLen - clapT) / 0.7);
    if (a <= 0) return;
    final ink = Paint()
      ..color = const Color(0xFF2A1208).withValues(alpha: 0.72 * a);
    const people = [
      (0.16, 1.0, 1),
      (0.3, 0.86, 0),
      (0.44, 1.08, 2),
      (0.6, 0.92, 1),
      (0.74, 1.0, 0),
    ];
    for (var i = 0; i < people.length; i++) {
      final (fx, s0, hat) = people[i];
      final size = s0 * 1.4;
      final x = w * fx;
      final top = h - 46 * size;
      // Omuzlar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - 16 * size, top + 16 * size, x + 16 * size, h + 4),
          Radius.circular(10 * size),
        ),
        ink,
      );
      // Baş.
      canvas.drawCircle(Offset(x, top + 8 * size), 8 * size, ink);
      switch (hat) {
        case 1: // kavuk
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, top - 2 * size),
              width: 18 * size,
              height: 12 * size,
            ),
            ink,
          );
        case 2: // fes
          canvas.drawPath(
            Path()
              ..moveTo(x - 6 * size, top + 1 * size)
              ..lineTo(x - 4 * size, top - 8 * size)
              ..lineTo(x + 4 * size, top - 8 * size)
              ..lineTo(x + 6 * size, top + 1 * size)
              ..close(),
            ink,
          );
      }
      // Eller: göğüste birleşip ayrılır (herkes kendi hızında).
      final beat = math.sin(clapT * math.pi * 2 * (3.6 + i * 0.4) + i);
      final gap = 3 + 6 * (0.5 + 0.5 * beat) * size;
      final hy = top + 26 * size;
      canvas.drawCircle(Offset(x - gap, hy - 6 * size), 3.4 * size, ink);
      canvas.drawCircle(Offset(x + gap, hy - 6 * size), 3.4 * size, ink);
    }
  }

  /// Gölge göze değiyor mu (testler ve ipucu için).
  bool get shadowOnMark => _shadowOnMark;

  double _t = 0;
  final _trail = <(double, double, int)>[];
  double _stillT = 0;

  /// Gölgenin geç kaldığı an: -1 olmadı, 0..lagLength sürüyor, sonra bitti.
  double lagT = -1;

  String get _eventKey => 'perde:${game.levelIndex}:${position.x.round()}';

  @override
  void onMount() {
    super.onMount();
    // Bir kez oynar: yeniden doğunca gölge yine geç kalmaz.
    if (game.eventSeen(_eventKey)) lagT = lagLength;
  }

  static const lagLength = 3.2;
  double _frozenX = 0;
  int _frozenFacing = 1;

  Offset get glowCenter => Offset(lampX, position.y - size.y * 0.45);
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
    if (puzzle) _updatePuzzle(dt, p, inFront);
    // Selam zıplamayla başlar: havadayken de "önünde" sayılır.
    _updateApplause(dt, p, rel > 0 && rel < 1);
    if (lagT < 0) {
      // Ortada durup beklerse: bir kez.
      if (inFront && rel > 0.35 && rel < 0.65 && p.velocity.x.abs() < 5) {
        _stillT += dt;
        if (_stillT > 0.5) {
          lagT = 0;
          game.markEvent(_eventKey);
          _frozenX = p.center.x;
          _frozenFacing = p.facing;
        }
      } else {
        _stillT = 0;
      }
    } else if (lagT < lagLength) {
      lagT += dt;
      if (lagT >= lagLength) {
        game.once('shadowLooked', S.of('shadowLooked'));
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
    // Bulmacada gölge bir kez kendi başına döner.
    if (_turnT > 0.2) facing = -facing;
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
    final c = Offset(lampX - position.x, h * 0.55);
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
        canvas.translate(shadowX(sx) - position.x, h - 4);
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
    if (puzzle) {
      _drawMark(canvas, w);
      _drawStops(canvas, w, h);
    }
    _drawAudience(canvas, w, h);
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
    if (puzzle) _drawFootprint(canvas);
  }
}

// ============================================================ Perde ipi

/// Dev perdenin yanındaki ip: çekince perdenin ardındaki kandil bir sonraki
/// durağa kayar.
class PerdeCord extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  PerdeCord(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  double _tug = 0;
  double _t = 0;

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 30 && (p - position).y.abs() < 44;

  GiantPerde? _perdeCache;

  /// Bu ipin bağlı olduğu (en yakın) dev perde.
  GiantPerde? get _perde {
    if (_perdeCache != null && _perdeCache!.isMounted) return _perdeCache;
    GiantPerde? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<GiantPerde>()) {
      final d = (g.position - position).length;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    return _perdeCache = best;
  }

  @override
  void use() {
    GiantPerde? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<GiantPerde>()) {
      final d = (g.position - position).length;
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    best?.pull();
    _tug = 1;
    _pulled = true;
    // Kamera perdeye: kandil kayar, dev gölge yer değiştirir.
    if (best != null) {
      game.focus(best.position + best.size / 2 - Vector2(0, kTile), hold: 1.3);
    }
  }

  /// İlk çekilene dek ip kendini belli eder: püskülde ılık ışık, ipten
  /// aşağı süzülen bir ışık tanesi.
  bool _pulled = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _tug = math.max(0, _tug - dt * 3);
  }

  @override
  void render(Canvas canvas) {
    // Tavandaki kalastan sarkan ip; çekilince aşağı iner, püskülü sallanır.
    final pull = math.sin(_tug * math.pi) * 8;
    final sway = math.sin(_t * 1.4) * 1.2;
    final end = Offset(sway, -14 + pull);
    final rope = Paint()
      ..color = kInk
      ..strokeWidth = 1.6;
    const top = Offset(0, -6 * kTile);
    final perde = _perde;
    final beckon = perde != null && perde.beckon;
    if (!_pulled || beckon) {
      final pulse = 0.6 + 0.4 * math.sin(_t * 3);
      final c = end + const Offset(0, 5);
      canvas.drawCircle(
        c,
        28,
        Paint()
          ..shader = ui.Gradient.radial(c, 28, [
            const Color(0xFFFFC27A).withValues(alpha: 0.5 * pulse),
            const Color(0x00FFC27A),
          ]),
      );
      // Koyu taşta ip seçilsin: yanında ince ılık bir parlaklık.
      canvas.drawLine(
        top + const Offset(1.2, 0),
        end + const Offset(1.2, 0),
        Paint()
          ..color = const Color(0xFFC89A62).withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      final k = (_t % 2.6) / 1.6;
      if (k < 1) {
        final bead = Offset.lerp(top, end, k * k)!;
        glowDot(canvas, bead, 7, kWarmLight, 0.8 * math.sin(k * math.pi));
      }
    }
    canvas.drawLine(top, end, rope);
    canvas.drawPath(
      Path()
        ..moveTo(end.dx - 1.5, end.dy)
        ..lineTo(end.dx + 1.5, end.dy)
        ..lineTo(end.dx + 3.5, end.dy + 9)
        ..lineTo(end.dx - 3.5, end.dy + 9)
        ..close(),
      Paint()
        ..color = _pulled && !beckon
            ? const Color(0xFF6A3A1E)
            : const Color(0xFFC0782E),
    );
    canvas.drawCircle(end, 2.4, Paint()..color = kInk);
  }
}

/// Göz taşı: duvara oyulmuş bir göz. Kavanozun gerçek ışığı değince uyanır
/// (çömelip kavanozu örtmek, saklanmak ya da duvar ardından tutmak olmaz).
class EyeStone extends PositionComponent with HasGameReference<GolgeGame> {
  EyeStone(Vector2 cell)
    : super(position: cell + Vector2.all(kTile / 2), priority: 4);

  bool lit = false;
  double _glow = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    lit = false;
    if (p != null && !p.isDead && !p.crouching && !p.hidden) {
      final (from, r) = p.light;
      lit =
          (from - position).length < r * 0.7 &&
          game.level.lineOfSight(from, position);
    }
    _glow = approach(_glow, lit ? 1 : 0, dt, 0.15);
  }

  @override
  void render(Canvas canvas) {
    // Taş levha ve oyulmuş göz.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -11, 26, 22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2C1C14),
    );
    final eye = Path()
      ..moveTo(-9, 0)
      ..quadraticBezierTo(0, -7, 9, 0)
      ..quadraticBezierTo(0, 7, -9, 0)
      ..close();
    canvas.drawPath(eye, Paint()..color = const Color(0xFF120A06));
    if (_glow > 0.02) glowDot(canvas, Offset.zero, 22, kWarmLight, 0.6 * _glow);
    canvas.drawCircle(
      Offset.zero,
      2.6,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF3A2418),
          const Color(0xFFFFF0C8),
          _glow,
        )!,
    );
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
      super(priority: 19) {
    // İp boğum boğum bir zincir: her boğum bir öncekine bağlı, kendi
    // ağırlığıyla sarkar. Tutulan yerin altındaki kısım serbestçe sallanır.
    final n = math.max(6, (length / 12).round());
    _seg = length / n;
    for (var i = 0; i <= n; i++) {
      final p = Offset(anchor.x, anchor.y + _seg * i);
      _pts.add(p);
      _prev.add(p);
    }
  }

  final Vector2 anchor;
  final double length;
  Player? holder;
  double _t;
  late final double _seg;
  final _pts = <Offset>[];
  final _prev = <Offset>[];
  double _acc = 0;

  /// İpin dikeyle yaptığı açı (bağlantıdan ucuna).
  double get angle {
    final e = _pts.last;
    return math.atan2(e.dx - anchor.x, e.dy - anchor.y);
  }

  /// İpe [p] noktasında tutunulabilir mi: ipin herhangi bir boğumuna
  /// yeterince yakınsa bağlantıdan o noktaya uzaklık, değilse null.
  double? grabAt(Vector2 p, {double reach = 16}) {
    final q = p.toOffset();
    var along = 0.0;
    double? best;
    var bestD = reach;
    for (var i = 0; i < _pts.length - 1; i++) {
      final a = _pts[i];
      final b = _pts[i + 1];
      final ab = b - a;
      final len2 = ab.distanceSquared;
      final t = len2 == 0
          ? 0.0
          : (((q - a).dx * ab.dx + (q - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      final d = (a + ab * t - q).distance;
      if (d < bestD) {
        bestD = d;
        best = along + _seg * t;
      }
      along += _seg;
    }
    return best;
  }

  /// Bırakıldı: zincir elin son hızıyla salınmayı sürdürür.
  void release(double a, double omega) => holder = null;

  @override
  void update(double dt) {
    _t += dt;
    final p = holder;
    if (p != null && (p.state != PlayerState.swing || p.rope != this)) {
      holder = null;
    }
    // Sabit adımlı (1/120 sn) zincir: kare hızından bağımsız.
    _acc = math.min(_acc + dt, 0.1);
    const h = 1 / 120;
    while (_acc >= h) {
      _acc -= h;
      _step(h);
    }
  }

  void _step(double h) {
    final p = holder;
    // Hafif bir hava akımı boş ipi kıpırdatır.
    final wind = p == null
        ? math.sin(_t * 0.7) * 18 + math.sin(_t * 1.9) * 6
        : 0.0;
    for (var i = 1; i < _pts.length; i++) {
      final v = (_pts[i] - _prev[i]) * 0.995;
      _prev[i] = _pts[i];
      _pts[i] = _pts[i] + v + Offset(wind, 900) * (h * h);
    }
    // Tutulan boğum elin yerinde; üstü gergin, altı serbest.
    int? held;
    if (p != null) {
      held = (p.ropeDistance / _seg).round().clamp(1, _pts.length - 1);
      _pts[held] = p.hand.toOffset();
    }
    for (var k = 0; k < 8; k++) {
      _pts[0] = anchor.toOffset();
      for (var i = 0; i < _pts.length - 1; i++) {
        final a = _pts[i];
        final b = _pts[i + 1];
        final d = b - a;
        final dist = d.distance;
        // İp gerilir ama sıkışmaz: yalnızca boyu aşınca çekilir.
        if (dist <= _seg || dist == 0) continue;
        final fix = d * ((dist - _seg) / dist);
        final aPinned = i == 0 || i == held;
        final bPinned = i + 1 == held;
        if (aPinned && !bPinned) {
          _pts[i + 1] = b - fix;
        } else if (bPinned && !aPinned) {
          _pts[i] = a + fix;
        } else if (!aPinned && !bPinned) {
          _pts[i] = a + fix * 0.5;
          _pts[i + 1] = b - fix * 0.5;
        }
      }
      if (held != null) _pts[held] = p!.hand.toOffset();
    }
  }

  @override
  void render(Canvas canvas) {
    final rope = Paint()
      ..color = const Color(0xFF2A1C14)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Boğumlardan geçen yumuşak bir eğri.
    final path = Path()..moveTo(_pts[0].dx, _pts[0].dy);
    for (var i = 1; i < _pts.length - 1; i++) {
      final m = (_pts[i] + _pts[i + 1]) / 2;
      path.quadraticBezierTo(_pts[i].dx, _pts[i].dy, m.dx, m.dy);
    }
    path.lineTo(_pts.last.dx, _pts.last.dy);
    if (game.level.def.theme == LevelTheme.forest) {
      _renderVine(canvas, path);
      return;
    }
    canvas.drawPath(path, rope);
    // Bağlantı halkası ve uçtaki düğüm.
    canvas.drawCircle(anchor.toOffset(), 3.5, Paint()..color = kInk);
    canvas.drawCircle(_pts.last, 3, Paint()..color = const Color(0xFF2A1C14));
  }

  /// Ötüken'de ip bir sarmaşıktır: bir dala sarılı, yer yer yapraklı.
  void _renderVine(Canvas canvas, Path path) {
    final a = anchor.toOffset();
    // Dal: bağlandığı yerden iki yana uzanan kalın, eğri bir kol.
    final branch = Paint()
      ..color = const Color(0xFF1C140C)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(a.dx - 46, a.dy - 10)
        ..quadraticBezierTo(a.dx - 8, a.dy + 4, a.dx + 30, a.dy - 4),
      branch,
    );
    canvas.drawPath(
      Path()
        ..moveTo(a.dx + 12, a.dy)
        ..quadraticBezierTo(a.dx + 26, a.dy - 14, a.dx + 40, a.dy - 22),
      branch..strokeWidth = 3.5,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF26301A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final leaf = Paint()..color = const Color(0xFF4E6B2E);
    final dark = Paint()..color = const Color(0xFF2E4220);
    for (var i = 2; i < _pts.length; i += 2) {
      final p = _pts[i];
      final side = i % 4 == 0 ? 1.0 : -1.0;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(side * 0.7 + math.sin(_t * 1.3 + i) * 0.15);
      canvas.drawOval(
        Rect.fromLTWH(side > 0 ? 0 : -9, -2.5, 9, 5),
        i % 3 == 0 ? dark : leaf,
      );
      canvas.restore();
    }
    canvas.drawCircle(_pts.last, 3, Paint()..color = const Color(0xFF26301A));
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

  /// Fil öteki hayvanlardan ağırdır: terazide eşini bulamaz.
  @override
  int get weight => kind == AnimalKind.elephant ? 3 : 2;

  /// Son itilişten beri geçen süre (eşinin gölgesi bu sırada ısınır).
  double sincePush = 99;

  @override
  double push(double dx, {int depth = 0}) {
    final moved = super.push(dx, depth: depth);
    if (moved != 0) {
      sincePush = 0;
      if (depth == 0) _showMate();
    }
    return moved;
  }

  @override
  void update(double dt) {
    super.update(dt);
    sincePush += dt;
  }

  /// İlk itilişte kamera bu hayvanın eşinin gölgesini gösterir (ekranda
  /// değilse): hangi heykelin nereye gideceği baştan belli olsun.
  void _showMate() {
    final key = 'esGoster:${game.levelIndex}:${kind.name}:${home.x.round()}';
    if (game.eventSeen(key)) return;
    Pedestal? mate;
    var best = double.infinity;
    for (final p in game.world.children.whereType<Pedestal>()) {
      if (p.kind != kind || p.matched) continue;
      final d = (p.position - position).length;
      if (d < best) {
        best = d;
        mate = p;
      }
    }
    if (mate == null) return;
    game.markEvent(key);
    final at = mate.position - Vector2(0, kTile * 1.6);
    final view = game.camera.visibleWorldRect.deflate(kTile * 2);
    if (!view.contains(Offset(at.x, at.y))) game.focus(at, hold: 1.4);
  }

  @override
  void render(Canvas canvas) {
    const s = Crate.side;
    const scale = 0.56;
    final art = ArkAnimal.of(arkKind(kind));
    final b = art.silhouette.getBounds();
    // Fenerin vurduğu ılık ışık.
    canvas.drawCircle(
      const Offset(s / 2, s - 18),
      40,
      Paint()
        ..shader = Gradient.radial(const Offset(s / 2, s - 18), 40, [
          const Color(0xFFE0A15F).withValues(alpha: 0.18),
          const Color(0xFFE0A15F).withValues(alpha: 0),
        ]),
    );
    // Kaide: oyma kenarlı, üstü fenerle aydınlık tahta blok.
    final l = math.min(-1.0, s / 2 + b.left * scale - 3);
    final r = math.max(s + 1.0, s / 2 + b.right * scale + 3);
    final base = Rect.fromLTRB(l, s - 7, r, s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, const Radius.circular(1.5)),
      Paint()
        ..shader = Gradient.linear(base.topCenter, base.bottomCenter, [
          const Color(0xFF7A4A28),
          const Color(0xFF2E1A0E),
        ]),
    );
    canvas.drawLine(
      Offset(l + 1, s - 6.4),
      Offset(r - 1, s - 6.4),
      Paint()
        ..color = const Color(0xFFF0C080).withValues(alpha: 0.75)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(l + 2, s - 3),
      Offset(r - 2, s - 3),
      Paint()
        ..color = const Color(0xFF1A0E06).withValues(alpha: 0.6)
        ..strokeWidth = 0.8,
    );
    // Gövdenin kaideye düşen gölgesi.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s / 2 + b.center.dx * scale, s - 7),
        width: b.width * scale * 0.9,
        height: 3,
      ),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.35),
    );
    canvas.save();
    canvas.translate(s / 2, s - 7);
    canvas.scale(scale);
    drawCarvedAnimal(canvas, arkKind(kind));
    canvas.restore();
  }
}

/// Oyun türünün çizimdeki adı.
String arkKind(AnimalKind k) => switch (k) {
  AnimalKind.lion => 'lion',
  AnimalKind.elephant => 'elephant',
  AnimalKind.giraffe => 'giraffe',
  AnimalKind.deer => 'deer',
};

/// Duvarda eşini bekleyen bir hayvan gölgesi. Aynı türden oyma hayvan
/// önüne itilince gölgeler birleşir, en yakın kapı açılır.
class Pedestal extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  Pedestal(Vector2 cell, this.kind)
    : super(position: Vector2(cell.x + kTile / 2, cell.y + kTile), priority: 4);

  final AnimalKind kind;
  bool matched = false;
  double _glow = 0;
  double _t = 0;

  @override
  String get persistKind => 'pedestal';

  @override
  Object? captureState() => matched ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      matched = true;
      _glow = 1;
    }
    return [this];
  }

  /// Eşi yakında ya da itiliyor: gölge ısınır, kenarı ışır (0..1).
  double _hot = 0;

  /// Yanlış hayvan önüne gelince gölge "hayır" der gibi sallanır.
  double _no = 0;
  AnimalCrate? _wrong;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _no = math.max(0, _no - dt);
    if (matched) {
      _glow = math.min(1, _glow + dt);
      _hot = math.max(0, _hot - dt);
      return;
    }
    var hot = 0.0;
    AnimalCrate? wrong;
    for (final a in game.world.children.whereType<AnimalCrate>()) {
      final cx = a.position.x + Crate.side / 2;
      final feet = a.position.y + Crate.side;
      final dx = (cx - position.x).abs();
      final level = (feet - position.y).abs() < 4;
      if (a.kind != kind) {
        if (dx < 16 && level) wrong = a;
        continue;
      }
      if ((feet - position.y).abs() < 3 * kTile) {
        final near = (1 - dx / (10 * kTile)).clamp(0.0, 1.0);
        final pushed = a.sincePush < 1.5 ? 1.0 : 0.0;
        hot = math.max(hot, math.max(near, pushed * 0.7 + near * 0.3));
      }
      if (dx < 14 && level) {
        matched = true;
        GameAudio.instance.play('memory', volume: 0.6);
        _openIfAllMatched();
      }
    }
    // Yanlış hayvan geldi: bir kez sallanır.
    if (wrong != null && wrong != _wrong) {
      _no = 0.7;
      GameAudio.instance.play('fizzle', volume: 0.4);
    }
    _wrong = wrong;
    _hot = approach(_hot, hot, dt, 0.25);
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
    // Gölgenin perdesi: duvarda fenerle aydınlanmış, ahşap çerçeveli bir
    // pencere. Heykellerin kendi gölgelerinden ayrılsın, "burası bir
    // sahne, oyuncusunu bekliyor" desin.
    final art = ArkAnimal.of(arkKind(kind));
    final b = art.silhouette.getBounds().shift(Offset(0, -kTile * 0.4));
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTRB(b.left - 12, b.top - 12, b.right + 12, -2),
      const Radius.circular(6),
    );
    final pulse = 0.5 + 0.5 * math.sin(_t * 4);
    canvas.drawRRect(
      screen,
      Paint()
        ..shader = Gradient.radial(screen.center, screen.width * 0.7, [
          const Color(0xFFFFD9A0)
              .withValues(alpha: 0.2 + 0.18 * _hot + 0.25 * _glow),
          const Color(0xFFE0A15F).withValues(alpha: 0.05 + 0.08 * _hot),
        ]),
    );
    canvas.drawRRect(
      screen,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF3A2414),
    );
    canvas.drawRRect(
      screen.deflate(2.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFF0C080)
            .withValues(alpha: 0.25 + 0.5 * _hot * pulse + 0.4 * _glow),
    );
    if (_no > 0) {
      canvas.save();
      canvas.translate(math.sin(_no * 40) * 4 * _no, 0);
    }
    // Duvara düşen eş gölge; eşleşince ışıkla çevrelenir.
    final shade = Paint()
      ..color = const Color(0xFF0A0604)
          .withValues(alpha: 0.8 + 0.08 * math.sin(_t));
    canvas.save();
    // Oyma hayvanla aynı yöne bakar: önüne gelince ikisi üst üste oturur.
    // Fener titredikçe gölge biraz büyüyüp küçülür, yana yatar.
    final flick = 1 + 0.03 * math.sin(_t * 3.1) + 0.02 * math.sin(_t * 7.3);
    canvas.translate(0, -kTile * 0.4);
    canvas.transform(
      Float64List.fromList([
        flick, 0, 0, 0, //
        -0.08 * math.sin(_t * 0.8), flick, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1,
      ]),
    );
    // Eşi yaklaşınca gölgenin kenarı ılık ışır.
    if (_hot > 0.02 && !matched) {
      canvas.drawPath(
        art.silhouette,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = kWarmLight.withValues(
            alpha: 0.55 * _hot * (0.6 + 0.4 * pulse),
          ),
      );
    }
    drawAnimalShadow(canvas, arkKind(kind), shade.color, blur: 1.2);
    canvas.restore();
    if (_no > 0) canvas.restore();
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

// ============================================================ Terazi

/// Nuh'un Gemisi'nin terazisi: iki kefenin üstünde aynı hayvanın gölgesi
/// asılı. Eşler (aynı tür, aynı ağırlık) iki kefeye konunca kefeler aynı
/// hizaya gelir ve ileriki kapı açılır. Fil ağırdır: hiçbir kefeyi dengelemez.
class ArkScale extends Component with HasGameReference<GolgeGame>, Persistent {
  ArkScale(this.lift, this.kindA, this.kindB) : super(priority: 13);

  final BalanceLift lift;
  final AnimalKind kindA;
  final AnimalKind kindB;
  bool solved = false;
  double _hold = 0;
  double _glow = 0;

  @override
  String get persistKind => 'scale';

  @override
  Object? captureState() => solved ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      solved = true;
      _glow = 1;
    }
    return [this];
  }

  bool _carries(LiftPan pan, AnimalKind kind) => game.world.children
      .whereType<AnimalCrate>()
      .any((c) => c.riding == pan && c.kind == kind);

  /// Kefeler eşini taşıyor ve aynı hizada mı?
  bool get balanced =>
      lift.a.load == lift.b.load &&
      lift.level &&
      _carries(lift.a, kindA) &&
      _carries(lift.b, kindB);

  @override
  void update(double dt) {
    super.update(dt);
    final ok = solved || balanced;
    _glow = approach(_glow, ok ? 1 : 0, dt, 0.3);
    if (solved) return;
    _hold = ok ? _hold + dt : 0;
    if (_hold < 0.8) return;
    solved = true;
    GameAudio.instance.play('memory', volume: 0.7);
    GameAudio.instance.play('gate', volume: 0.7);
    game.once('scaleSolved', S.of('scaleSolved'));
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final d = (g.position - lift.b.position).length;
      if (g.position.x > lift.b.position.x && d < bestD && !g.opening) {
        bestD = d;
        best = g;
      }
    }
    best?.opening = true;
  }

  @override
  void render(Canvas canvas) {
    // Kefenin ipinde asılı tahta: üstünde beklenen hayvanın gölgesi.
    for (final (pan, kind) in [(lift.a, kindA), (lift.b, kindB)]) {
      final c = Offset(pan.position.x + pan.size.x / 2, pan.position.y - 46);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 40, height: 30),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF2A1A10),
      );
      if (_glow > 0.02) glowDot(canvas, c, 40, kWarmLight, 0.45 * _glow);
      canvas.save();
      canvas.translate(c.dx, c.dy + 12);
      canvas.scale(0.42);
      drawAnimalShadow(
        canvas,
        arkKind(kind),
        Color.lerp(
          const Color(0xFF0A0604),
          const Color(0xFFE8C890),
          _glow * 0.7,
        )!,
        blur: 1,
      );
      canvas.restore();
    }
  }
}

/// Terazinin kolu: çekilince kefeler boşalır, gemideki hayvanlar
/// yerlerine döner (yanlış sandık itilince bulmaca kilitlenmesin).
class ScaleCrank extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  ScaleCrank(this.arkScale, Vector2 at) : super(position: at, priority: 18);

  final ArkScale arkScale;
  double _turn = 0;

  @override
  bool canUse(Vector2 p) =>
      !arkScale.solved &&
      (p - position).x.abs() < 24 &&
      (p - position).y.abs() < 40;

  @override
  void use() {
    if (arkScale.solved) return;
    _turn = 1;
    GameAudio.instance.play('creak', volume: 0.7);
    GameAudio.instance.play('chain', volume: 0.4);
    final left = arkScale.lift.a.base.x - 8 * kTile;
    final right = arkScale.lift.b.base.x + 8 * kTile;
    for (final c in game.world.children.whereType<AnimalCrate>()) {
      if (c.home.x > left && c.home.x < right) c.sendHome();
    }
    arkScale.lift.reset();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _turn = math.max(0, _turn - dt * 1.5);
  }

  @override
  void render(Canvas canvas) {
    // Direğe bağlı tekerlek: çevrilince döner.
    final ink = Paint()..color = kInk;
    canvas.drawRect(const Rect.fromLTWH(-2, -22, 4, 22), ink);
    canvas.save();
    canvas.translate(0, -22);
    canvas.rotate(_turn * math.pi * 2);
    canvas.drawCircle(Offset.zero, 7, ink);
    final spoke = Paint()
      ..color = const Color(0xFFD08A5A).withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    for (var k = 0; k < 3; k++) {
      canvas.rotate(math.pi / 3);
      canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), spoke);
    }
    canvas.restore();
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

  /// Tavana uzanan ip (çan havada asılı kalmasın).
  double _rope = 6;

  @override
  void onMount() {
    super.onMount();
    final lv = game.level;
    final c = (position.x / kTile).floor();
    var r = (position.y / kTile).floor() - 1;
    while (r >= 0 && !lv.solid(c, r)) {
      r--;
    }
    _rope = math.max(6, position.y - (r + 1) * kTile);
  }

  /// Şu an çalıyor mu (yeni vurulmuş).
  bool get ringing => _ring > 0;

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
    if (_rearm > 0) return;
    // Uzaktan çalmak: ateşböceği çana değince çalar (bekçiyi oraya çeker).
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position - position).length < 26) {
        _ringNow();
        return;
      }
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    final d = p.center - position;
    final fast = p.velocity.x.abs() > 75 || !p.onGround;
    if (d.x.abs() < 44 && d.y > 0 && d.y < 4 * kTile && fast) _ringNow();
  }

  @override
  void render(Canvas canvas) {
    final swing = math.sin(_t * 1.3) * 0.08 + math.sin(_t * 14) * 0.35 * _ring;
    canvas.drawLine(
      Offset(0, 6 - _rope),
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
