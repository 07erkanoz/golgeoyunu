import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'player.dart';
import 'puzzles.dart';
import 'strings.dart';

// XV · Ergenekon (docs/MITOLOJI.md §5): dört yanı aşılmaz dağlarla çevrili
// vadi. Demirci dağın demir damarını eritmeyi önerir; dağın dibine odun ve
// kömür yığılır, deriden körükler kurulur, dağ erir.

/// Demir damarı: geçidi kapatan demir. Ocağı (dibindeki köz) bir ateşböceği
/// yakar; körükler doğru sırayla basıldıkça ısınır, ısı dolunca erir.
class IronVein extends Gate {
  IronVein(int col, int top, int bottom)
    : _top = top,
      _rows = bottom - top + 1,
      super(col, top, bottom) {
    position.x = col * kTile.toDouble();
    size.x = kTile.toDouble();
  }

  final int _top;
  final int _rows;

  /// Körüklerin beklenen sırası dolarken ısı (0-1).
  double heat = 0;

  /// Ocak yandı mı (ateşböceği değince).
  bool lit = false;

  /// Erime (0-1): yarıdan sonra geçilir.
  double melt = 0;

  /// Sıradaki körüğün numarası (1'den başlar).
  int next = 1;

  /// Son doğru basıştan beri geçen süre: geç kalınırsa ateş söner.
  double _since = 0;
  double _t = 0;
  double _flash = 0;

  /// Bu damara bağlı körük sayısı (kurulurken verilir).
  int bellowsCount = 1;

  /// Doğru basışlar arasında en çok bu kadar beklenebilir.
  static const double window = 8;

  double get _h => _rows * kTile.toDouble();

  Offset get forge =>
      Offset(position.x + kTile / 2, (_top + _rows) * kTile.toDouble());

  @override
  bool get solid => melt < 0.5;

  @override
  String get persistKind => 'vein';

  @override
  Object? captureState() => opening ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      opening = true;
      lit = true;
      heat = 1;
      melt = 1;
    }
    return [this];
  }

  @override
  Rect toRect() => Rect.fromLTWH(
    position.x,
    position.y + _h * melt,
    kTile.toDouble(),
    _h * (1 - melt),
  );

  /// Bir körük basıldı.
  void pump(Bellows b) {
    if (opening) return;
    if (!lit) {
      GameAudio.instance.play('fizzle', volume: 0.5);
      game.once('forgeCold', S.of('forgeCold'));
      return;
    }
    if (b.order == next) {
      next++;
      _since = 0;
      heat = math.min(1, (next - 1) / bellowsCount);
      _flash = 1;
      GameAudio.instance.play('fire', volume: 0.6);
      if (next > bellowsCount) {
        opening = true;
        GameAudio.instance.play('grind', volume: 0.7);
        GameAudio.instance.play('gate', volume: 0.6);
      }
    } else {
      _cool();
    }
  }

  void _cool() {
    if (heat > 0 || next > 1) {
      GameAudio.instance.play('fizzle', volume: 0.7);
    }
    heat = 0;
    next = 1;
    _since = 0;
  }

  @override
  void update(double dt) {
    _t += dt;
    _flash = math.max(0, _flash - dt * 2);
    if (opening) {
      melt = math.min(1, melt + dt * 0.45);
      return;
    }
    if (!lit) {
      // Sönmüş ocak yakına salınan ateşböceğini kendine çeker; böcek
      // közlere değince ocak yanar.
      final mouth = Vector2(forge.dx, forge.dy - 18);
      for (final l in game.world.children.whereType<FireflyLure>().toList()) {
        if (!l.glowing && l.pull == null) continue;
        final d = (l.position - mouth).length;
        if (d < 9 * kTile) l.pull = mouth;
        if (d < 10) {
          lit = true;
          _flash = 1;
          l.removeFromParent();
          GameAudio.instance.play('fire', volume: 0.8);
          game.shake(3);
          game.once('forgeLit', S.of('forgeLit'));
        }
      }
      return;
    }
    if (next > 1) {
      _since += dt;
      if (_since > window) _cool();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = kTile.toDouble();
    final h = _h;
    final top = h * melt;
    // Demir: koyu, pas lekeli; ısındıkça kızarır.
    final glow = math.max(heat, melt) * (0.85 + 0.15 * math.sin(_t * 5));
    final body = Rect.fromLTWH(0, top, w, h - top);
    canvas.drawRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(body.topCenter, body.bottomCenter, [
          Color.lerp(const Color(0xFF2E2A2C), const Color(0xFFE05A2A), glow)!,
          Color.lerp(const Color(0xFF1E1A1C), const Color(0xFFFFB050), glow)!,
        ]),
    );
    final rust = Paint()
      ..color = const Color(0xFF7A3A22).withValues(alpha: 0.5 * (1 - glow));
    for (var y = top + 8; y < h - 4; y += 18) {
      canvas.drawLine(
        Offset(4, y),
        Offset(w - 6, y + 5),
        rust..strokeWidth = 2,
      );
    }
    // Eriyen demir: dibinde akkor bir göl.
    if (melt > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, h),
          width: w * (1 + 2 * melt),
          height: 8,
        ),
        Paint()..color = const Color(0xFFFFB050).withValues(alpha: 0.8),
      );
    }
    _forge(canvas, w, h);
  }

  /// Ocak: damarın dibinde taştan kubbeli bir yuva. Sönmüşken kül ve ince
  /// bir duman, ağzında ateşböceğini çağıran soluk bir ışıltı; yanınca
  /// alevler ve ısıyla büyüyen kor ışığı.
  void _forge(Canvas canvas, double w, double h) {
    final cx = w / 2;
    final base = h;
    // Isı ve kor ışığı.
    if (lit) {
      final r = 70 + 70 * math.max(heat, melt) + 30 * _flash;
      canvas.drawCircle(
        Offset(cx, base - 16),
        r,
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, base - 16), r, [
            const Color(0xFFFFB050).withValues(alpha: 0.45 + 0.2 * heat),
            const Color(0x00FF8030),
          ]),
      );
    }
    // Taş kubbe: iki yanda yığma taşlar, ortada ağız.
    final stone = Paint()..color = const Color(0xFF3A3230);
    final stoneLit = Paint()
      ..color = lit
          ? Color.lerp(const Color(0xFF5A4038), const Color(0xFFB86A40), heat)!
          : const Color(0xFF4A423E);
    for (final (x, y, r) in const [
      (-34.0, -8.0, 11.0),
      (-24.0, -20.0, 10.0),
      (-12.0, -30.0, 10.0),
      (2.0, -34.0, 10.0),
      (16.0, -32.0, 10.0),
      (28.0, -22.0, 10.0),
      (38.0, -10.0, 11.0),
      (-30.0, -2.0, 9.0),
      (34.0, -2.0, 9.0),
    ]) {
      canvas.drawCircle(Offset(cx + x - 2, base + y), r, stone);
      canvas.drawCircle(Offset(cx + x - 4, base + y - 3), r * 0.55, stoneLit);
    }
    // Ağız.
    final mouth = Path()
      ..moveTo(cx - 20, base)
      ..quadraticBezierTo(cx - 18, base - 26, cx, base - 27)
      ..quadraticBezierTo(cx + 18, base - 26, cx + 20, base)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFF0E0A08));
    if (!lit) {
      // Kül ve tüten ince duman; ağzında çağıran ışıltı.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, base - 3), width: 30, height: 7),
        Paint()..color = const Color(0xFF5A5450),
      );
      final call = 0.5 + 0.5 * math.sin(_t * 2.2);
      canvas.drawCircle(
        Offset(cx, base - 14),
        22 + 6 * call,
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, base - 14), 28, [
            const Color(0xFFFFD890).withValues(alpha: 0.18 + 0.14 * call),
            const Color(0x00FFD890),
          ]),
      );
      canvas.drawCircle(
        Offset(cx, base - 6),
        1.6,
        Paint()
          ..color = const Color(0xFFFF9050).withValues(alpha: 0.4 + 0.4 * call),
      );
      final smoke = Paint();
      for (var i = 0; i < 4; i++) {
        final u = (_t * 0.15 + i / 4) % 1.0;
        smoke.color = const Color(0xFF8A8480).withValues(alpha: 0.2 * (1 - u));
        canvas.drawCircle(
          Offset(cx + math.sin(_t + i) * 5 + u * 10, base - 30 - u * 70),
          4 + u * 10,
          smoke,
        );
      }
      return;
    }
    // Köz yatağı ve alevler (ısı arttıkça büyür).
    final coal = Paint()
      ..color = Color.lerp(
        const Color(0xFFB8401A),
        const Color(0xFFFFC060),
        0.5 + 0.5 * math.sin(_t * 6) * 0.5 + _flash * 0.5,
      )!;
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(cx - 12 + i * 6.0, base - 3), 3.6, coal);
    }
    final flame = Paint();
    final size = 0.6 + 0.5 * math.max(heat, melt) + 0.4 * _flash;
    for (var i = 0; i < 4; i++) {
      final fx = cx - 9 + i * 6.0;
      final ht = (14 + 6 * math.sin(_t * (7 + i) + i * 2)) * size;
      flame.color = Color.lerp(
        const Color(0xFFFF7A2A),
        const Color(0xFFFFE0A0),
        i.isEven ? 0.2 : 0.6,
      )!.withValues(alpha: 0.9);
      canvas.drawPath(
        Path()
          ..moveTo(fx - 4, base - 3)
          ..quadraticBezierTo(
            fx - 4,
            base - ht * 0.6,
            fx + math.sin(_t * 9 + i) * 2,
            base - ht,
          )
          ..quadraticBezierTo(fx + 4, base - ht * 0.6, fx + 4, base - 3)
          ..close(),
        flame,
      );
    }
  }
}

/// Deriden körük: ↑ ile basılır. Üstündeki çentik sayısı sırasını söyler.
class Bellows extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  Bellows(Vector2 cell, this.order)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        size: Vector2(30, 22),
        anchor: Anchor.bottomCenter,
        priority: 15,
      );

  /// Sırası (1'den başlar); üstünde bu kadar çentik vardır.
  final int order;
  IronVein? vein;
  double _press = 0;
  double _t = math.Random().nextDouble() * 4;

  /// Sırası 0 olan körük süstür (dağın dibindeki yetmiş körükten biri).
  @override
  bool canUse(Vector2 p) =>
      order > 0 &&
      (p.x - position.x).abs() < 26 &&
      (p.y - position.y).abs() < 44;

  @override
  void use() {
    _press = 1;
    GameAudio.instance.play('gust', volume: 0.35, minGapMs: 150);
    vein?.pump(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _press = math.max(0, _press - dt * 3);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    final squash = 1 - 0.45 * math.sin(_press * math.pi);
    final ink = Paint()..color = const Color(0xFF2A1A12);
    final hide = Paint()..color = const Color(0xFF6A4630);
    // Alt tahta, deri körük, üst tahta, sap.
    canvas.drawRect(const Rect.fromLTWH(-15, -4, 30, 4), ink);
    final top = -4 - 14 * squash;
    canvas.drawPath(
      Path()
        ..moveTo(-13, -4)
        ..lineTo(-15, (top - 4) / 2)
        ..lineTo(-12, top)
        ..lineTo(12, top)
        ..lineTo(15, (top - 4) / 2)
        ..lineTo(13, -4)
        ..close(),
      hide,
    );
    final fold = Paint()
      ..color = const Color(0xFF3A2416)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final y = -4 + (top + 4) * i / 3;
      canvas.drawLine(Offset(-14, y), Offset(14, y), fold);
    }
    canvas.drawRect(Rect.fromLTWH(-14, top - 3, 28, 3), ink);
    canvas.drawRect(Rect.fromLTWH(10, top - 7, 9, 3), ink);
    // Burun: ocağa uzanan demir uç.
    canvas.drawPath(
      Path()
        ..moveTo(-15, -3)
        ..lineTo(-24, -1)
        ..lineTo(-15, 0)
        ..close(),
      ink,
    );
    // Çentikler: sırası (ışıklı oyuk).
    final hot = vein?.lit ?? false;
    final notch = Paint()
      ..color = (hot ? const Color(0xFFFFD890) : const Color(0xFF8A7A68))
          .withValues(alpha: hot ? 0.75 + 0.25 * math.sin(_t * 2) : 0.5);
    for (var i = 0; i < order; i++) {
      canvas.drawCircle(
        Offset((i - (order - 1) / 2) * 5.0, top - 9),
        1.6,
        notch,
      );
    }
    canvas.restore();
  }
}

/// Akan demir: eriyen damardan akan akkor yol. Akarken yakar (üstünde
/// durulmaz, düşülür); soğuyup kararınca köprü olur, sonra yeniden erir.
class MoltenChannel extends Deck {
  MoltenChannel(Vector2 cell, int tiles, {required this.phase})
    : super(
        position: Vector2(cell.x, cell.y),
        size: Vector2(tiles * kTile, 10),
      );

  /// Döngüdeki başlangıç kayması (saniye).
  final double phase;

  /// Döngü: akkor akış, soğuma, kara köprü, yeniden kızarma.
  static const double flowing = 3.2;
  static const double cooling = 0.8;
  static const double solidFor = 4.0;
  static const double warning = 1.0;
  static const double period = flowing + cooling + solidFor + warning;

  double _t = 0;

  double get _c => (_t + phase) % period;

  /// Şu an akıyor mu (geçilmez, yakar).
  bool get molten => _c < flowing;

  @override
  bool get active => !molten;

  @override
  void step(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final c = _c;
    // 0: soğuk kara demir, 1: akkor.
    final hot = c < flowing
        ? 1.0
        : c < flowing + cooling
        ? 1 - (c - flowing) / cooling
        : c > period - warning
        ? (c - (period - warning)) / warning * (0.5 + 0.5 * math.sin(_t * 20))
        : 0.0;
    final rect = Rect.fromLTWH(0, 0, w, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF1A1614),
          const Color(0xFFFF8A30),
          hot,
        )!,
    );
    if (molten) {
      // Akış: üstünde kayan parlak benekler.
      final spark = Paint()..color = const Color(0xFFFFE0A0);
      for (var x = 0.0; x < w; x += 9) {
        final k = (x + _t * 60) % w;
        canvas.drawCircle(
          Offset(k, 3 + math.sin(_t * 4 + x) * 1.5),
          1.4,
          spark,
        );
      }
    } else {
      // Soğuyan kabuk: çatlaklar.
      final crack = Paint()
        ..color = const Color(0xFF5A2A18).withValues(alpha: 0.8)
        ..strokeWidth = 1;
      for (var x = 6.0; x < w; x += 14) {
        canvas.drawLine(Offset(x, 1), Offset(x + 5, 8), crack);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Akarken üstüne basan yanar.
    final p = game.player;
    if (p == null || p.isDead || !molten) return;
    final feet = p.position.y + Player.h;
    if (p.position.x + Player.w > position.x &&
        p.position.x < position.x + size.x &&
        (feet - position.y).abs() < 6) {
      p.die(cause: DeathCause.hazard);
    }
  }
}

/// Vadinin sisi: yolu ve çukurları gizler (yalnızca görünüş). Yerde en
/// yoğun, yukarı çıktıkça incelir ve ~5 kare yukarıda biter (dağlar, gök
/// açık kalır); iki yanda uzun, yumuşak bir geçişle erir; içinde ağır ağır
/// akan bulanık tutamlar. Gökbörü'nün izleri sisin üstünde parlar.
class MistZone extends Component with HasGameReference<GolgeGame> {
  MistZone(this.area) : super(priority: 18);

  final Rect area;
  double _t = 0;

  /// Ay ışığında serin, grimsi pus.
  static const _mist = Color(0xFFBFCAD2);

  /// Kenarlarda erime genişliği.
  static const double _fade = 7 * kTile;

  @override
  void update(double dt) => _t += dt;

  /// Zeminin yüksekliği: zonun sütunlarında en sık rastlanan ilk katı
  /// karo (çukurlar ve kayalar sayılmaz). Bir kez hesaplanır.
  late final double _ground = () {
    final lv = game.level;
    final count = <int, int>{};
    for (var c = (area.left / kTile).floor(); c < area.right / kTile; c++) {
      for (var r = (area.top / kTile).floor(); r < lv.height; r++) {
        if (lv.solid(c, r)) {
          count[r] = (count[r] ?? 0) + 1;
          break;
        }
      }
    }
    if (count.isEmpty) return area.bottom - 3 * kTile;
    final best = count.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.key * kTile.toDouble();
  }();

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final g = _ground;
    final top = g - 5.5 * kTile;
    final r = Rect.fromLTRB(
      area.left - _fade * 0.5,
      top,
      area.right + _fade * 0.5,
      math.max(area.bottom, g + 10 * kTile),
    );
    if (!view.overlaps(r)) return;
    canvas.saveLayer(r, Paint());
    // Dikey: yukarıda hiç, yere indikçe koyulaşır; zeminde ve çukurlarda
    // yolu gizleyecek kadar yoğun.
    double at(double y) => ((y - r.top) / r.height).clamp(0.0, 1.0);
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          // Yere yatan sis kümesi: zeminin üstünde ve toprağın ilk bir buçuk
          // karesinde yoğun (çukurların ağzı seçilmez), aşağıda kaybolur.
          [
            _mist.withValues(alpha: 0),
            _mist.withValues(alpha: 0.18),
            _mist.withValues(alpha: 0.55),
            _mist.withValues(alpha: 0.92),
            _mist.withValues(alpha: 0.92),
            _mist.withValues(alpha: 0),
          ],
          [
            0,
            at(g - 3.5 * kTile),
            at(g - 1.6 * kTile),
            at(g - 0.3 * kTile),
            at(g + 1.3 * kTile),
            at(g + 2.9 * kTile),
          ],
        ),
    );
    // Sisin altı toprak gibi koyu: çukurların içi seçilmez (yol görünmez).
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          const [Color(0x000D0A09), Color(0x000D0A09), Color(0xFF0D0A09)],
          [0, at(g + 1.2 * kTile), at(g + 2.4 * kTile)],
        ),
    );
    // Akan tutamlar: uzun, bulanık; farklı hızlarda ve yüksekliklerde.
    final wisp = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    for (var i = 0; i < 16; i++) {
      final speed = 8 + (i % 5) * 4.0;
      final span = r.width + 400;
      final x = r.left - 200 + ((i * 263.0 + _t * speed) % span);
      final hgt = ((i * 0.37) % 1) * 3.6 * kTile;
      final y = g - 0.4 * kTile - hgt;
      final wdt = 220.0 + (i * 53) % 180;
      wisp.color = Color.lerp(
        _mist,
        const Color(0xFFFFFFFF),
        0.25,
      )!.withValues(alpha: 0.32 * (1 - hgt / (4.2 * kTile)));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y + math.sin(_t * 0.4 + i) * 6),
          width: wdt,
          height: 34 + (i % 3) * 10.0,
        ),
        wisp,
      );
    }
    // İki yanda uzun, yumuşak erime.
    double fx(double x) => ((x - r.left) / r.width).clamp(0.0, 1.0);
    canvas.drawRect(
      r,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          r.centerLeft,
          r.centerRight,
          const [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          [0, fx(area.left + _fade * 0.5), fx(area.right - _fade * 0.5), 1],
        ),
    );
    canvas.restore();
  }
}
