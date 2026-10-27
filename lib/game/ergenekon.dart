import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'konya.dart';
import 'level.dart';
import 'mechanics.dart';
import 'myth_figures.dart';
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

  /// Ritimli damar: sıradaki (ışıklı) körük Demirci'nin örs vuruşuna denk
  /// basılır; her denk basış bir vuruş sayılır, sonra öbür körük yanar.
  /// [beatsNeeded] vuruşta ocak kızar. Yanlış an ya da yanlış körük vuruş
  /// düşürmez, yalnız sayılmaz (telefonda ne kaç kez basılacağı ne sıradaki
  /// körük belliydi; ısı kendiliğinden de sönüyordu).
  bool rhythm = false;

  /// Ritimde gereken denk vuruş sayısı.
  static const int beatsNeeded = 6;

  /// Ritimde şimdiye dek denk vuruş.
  int beats = 0;

  /// Ritimli damarın körükleri (soldan sağa); sıradaki yanar.
  List<Bellows> rhythmPumps = const [];
  int _turn = 0;

  /// Ritimde şimdi basılacak körük.
  Bellows? get activeBellows =>
      rhythmPumps.isEmpty ? null : rhythmPumps[_turn % rhythmPumps.length];

  /// Ocağın önündeki çukura itilmesi gereken kömür sandığı sayısı (odun
  /// ve kömür yığılmadan ocak yanmaz).
  int fuelNeeded = 0;

  /// Damarın örsü (ritimli damarda).
  Anvil? anvil;

  /// Sıralı damarda doğru basışlar arasında en çok bu kadar beklenebilir.
  static const double window = 15;

  /// Çukurdaki kömür sandığı sayısı.
  int get fuel {
    if (fuelNeeded == 0) return 0;
    final pitX = forge.dx - 3 * kTile;
    return game.world.children
        .whereType<Crate>()
        .where(
          (c) =>
              c.position.y > forge.dy - 10 &&
              (c.center.x - pitX).abs() < 3 * kTile,
        )
        .length;
  }

  bool get fueled => fuel >= fuelNeeded;

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
      beats = beatsNeeded;
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

  /// Kömür sandıklarının itileceği çukur: zeminde nabız gibi atan sıcak
  /// bir ışık ve aşağı bakan oklar (nereye itileceği gözle görülsün).
  void _pitMark(Canvas canvas) {
    final cx = kTile / 2 - 3 * kTile;
    final y = _h;
    final a = 0.35 + 0.25 * math.sin(_t * 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y - 2), width: 5 * kTile, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFF9A40).withValues(alpha: a),
    );
    final arrow = Paint()
      ..color = const Color(0xFFFFC27A).withValues(alpha: a + 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final dx in [-1.4 * kTile, 0.0, 1.4 * kTile]) {
      final bob = 4 * math.sin(_t * 3 + dx);
      final ax = cx + dx;
      final ay = y - 26 + bob;
      canvas.drawLine(Offset(ax, ay - 12), Offset(ax, ay), arrow);
      canvas.drawLine(Offset(ax - 6, ay - 6), Offset(ax, ay), arrow);
      canvas.drawLine(Offset(ax + 6, ay - 6), Offset(ax, ay), arrow);
    }
  }

  /// Bir körük basıldı.
  void pump(Bellows b) {
    if (opening) return;
    if (!lit) {
      GameAudio.instance.play('fizzle', volume: 0.5);
      game.once(
        fueled ? 'forgeCold' : 'forgeFuel',
        S.of(fueled ? 'forgeCold' : 'forgeFuel'),
      );
      return;
    }
    if (rhythm) {
      if (!identical(b, activeBellows)) return;
      final a = anvil;
      if (a != null && a.onBeat) {
        beats++;
        heat = math.min(1, beats / beatsNeeded);
        _turn++;
        _flash = 1;
        GameAudio.instance.play('fire', volume: 0.6);
        GameAudio.instance.play('bell', volume: 0.25 + 0.05 * beats);
        if (beats >= beatsNeeded) _open();
      } else {
        GameAudio.instance.play('fizzle', volume: 0.5);
      }
      return;
    }
    if (b.order == next) {
      next++;
      _since = 0;
      heat = math.min(1, (next - 1) / bellowsCount);
      _flash = 1;
      GameAudio.instance.play('fire', volume: 0.6);
      if (next > bellowsCount) _open();
    } else {
      _cool();
    }
  }

  /// Isı doldu, damar erir. Kamera damara döner ve erime bitene dek orada
  /// kalır: son körük basılınca kapının açıldığı görülsün.
  void _open() {
    opening = true;
    GameAudio.instance.play('grind', volume: 0.7);
    GameAudio.instance.play('gate', volume: 0.6);
    game.focus(
      Vector2(position.x + kTile / 2, position.y + _h / 2),
      hold: 1 / 0.45 + 0.4,
    );
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
      // Kömür yığılmadan ocak ateşböceğini çekmez.
      if (!fueled) return;
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
          l.absorb();
          GameAudio.instance.play('fire', volume: 0.8);
          game.shake(3);
          game.once(
            rhythm ? 'forgeLitBeat' : 'forgeLit',
            S.of(rhythm ? 'forgeLitBeat' : 'forgeLit'),
          );
        }
      }
      return;
    }
    if (rhythm) return;
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
    if (fuelNeeded > 0 && !fueled) _pitMark(canvas);
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

/// Demirci'nin örsü: ritimli damarın başında Demirci durur, çekici örse
/// düzenli vurur. Körükler bu vuruşa denk basılınca ocak ısınır ("yetmiş
/// körük" bir ağızdan üfler). Çekiç kalkıp inerken vuruş önceden görülür.
class Anvil extends PositionComponent with HasGameReference<GolgeGame> {
  Anvil(Vector2 feet, {this.facing = 1})
    : super(position: feet, anchor: Anchor.bottomCenter, priority: 16);

  final int facing;

  /// İki vuruş arası (saniye): Demirci çiziminin çekiç döngüsü.
  static const double beat = 1 / 0.9;

  /// Vuruşun iki yanındaki denk sayılan pay (saniye).
  static const double grace = 0.36;

  /// Usta iri çizilir (Sâye'nin üç katı): çekicin inişi uzaktan görülsün.
  static const double drawScale = 0.9;

  double _t = 0;
  double _hit = 0;
  bool _met = false;

  /// Vuruş döngüsünde nerede (0 = çekiç örse indi, 1'e doğru yeniden
  /// iniyor).
  double get phase => (_t / beat) % 1.0;

  /// Şu an vuruşa denk mi.
  bool get onBeat {
    final ph = (_t / beat) % 1.0;
    return math.min(ph, 1 - ph) * beat < grace;
  }

  Offset get glowCenter => Offset(position.x, position.y - 30);

  @override
  void update(double dt) {
    super.update(dt);
    final before = (_t / beat).floor();
    _t += dt;
    _hit = math.max(0, _hit - dt * 4);
    final p = game.player;
    if ((_t / beat).floor() != before) {
      _hit = 1;
      // Vuruş: yakındaysa duyulur.
      final near = p == null
          ? 0.0
          : (1 - (p.center.x - position.x).abs() / (18 * kTile)).clamp(
              0.0,
              1.0,
            );
      if (near > 0) {
        GameAudio.instance.play('chain', volume: 0.55 * near, minGapMs: 300);
        GameAudio.instance.play('land', volume: 0.35 * near, minGapMs: 300);
      }
    }
    if (!_met && p != null && (p.center.x - position.x).abs() < 9 * kTile) {
      _met = true;
      game.once('cameo:demirci', S.of('cameo_demirci'));
      game.meetMyth('demirci');
    }
  }

  @override
  void render(Canvas canvas) {
    // Vuruşta örsten kıvılcım ve ışık halkası (ritim gözle de görülsün).
    if (_hit > 0) {
      canvas.drawCircle(
        Offset(facing * 31 * drawScale, -22 * drawScale),
        14 + 40 * (1 - _hit),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFC870).withValues(alpha: 0.6 * _hit),
      );
    }
    canvas.save();
    canvas.scale(facing * drawScale, drawScale);
    MythFigures.demirci(canvas, _t);
    canvas.restore();
  }
}

/// Nevruz örsü: vadiden çıkışta akkor bir demir. Efsanede o gün bir demir
/// ateşte kızdırılıp örste dövülür. ↑ ile üç kez vurulunca en yakın kapı
/// (ileride) açılır, şafak söker.
class NevruzAnvil extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  NevruzAnvil(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        size: Vector2(34, 26),
        anchor: Anchor.bottomCenter,
        priority: 15,
      );

  static const int strikesNeeded = 3;
  int strikes = 0;
  double _cool = 0;
  double _hit = 0;
  double _t = 0;

  bool get done => strikes >= strikesNeeded;

  @override
  bool canUse(Vector2 p) =>
      !done && (p.x - position.x).abs() < 34 && (p.y - position.y).abs() < 44;

  @override
  void use() {
    if (_cool > 0 || done) return;
    strikes++;
    _cool = 0.45;
    _hit = 1;
    game.shake(2.5);
    GameAudio.instance.play('chain', volume: 0.7);
    GameAudio.instance.play('land', volume: 0.5);
    if (done) {
      GameAudio.instance.play('gate', volume: 0.6);
      game.once('nevruzStruck', S.of('nevruzStruck'));
      Gate? best;
      var bestD = double.infinity;
      for (final g in game.world.children.whereType<Gate>()) {
        if (g is IronVein || g.position.x < position.x) continue;
        final d = g.position.x - position.x;
        if (d < bestD) {
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
    _t += dt;
    _cool = math.max(0, _cool - dt);
    _hit = math.max(0, _hit - dt * 3);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    final ink = Paint()..color = const Color(0xFF140C08);
    // Örs.
    canvas.drawPath(
      Path()
        ..moveTo(-16, -18)
        ..lineTo(14, -18)
        ..lineTo(18, -15)
        ..lineTo(8, -12)
        ..lineTo(6, 0)
        ..lineTo(-6, 0)
        ..lineTo(-8, -12)
        ..lineTo(-14, -14)
        ..close(),
      ink,
    );
    // Üstünde akkor demir: vuruldukça soğur, işi bitince ak ışır.
    final glow = done
        ? 0.6 + 0.4 * math.sin(_t * 3)
        : 1 - strikes / strikesNeeded * 0.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -22, 20, 4),
        const Radius.circular(2),
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFFB04018),
          const Color(0xFFFFE0A0),
          glow,
        )!,
    );
    canvas.drawCircle(
      const Offset(0, -20),
      18,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -20), 18, [
          const Color(0xFFFF9A40).withValues(alpha: 0.5 * glow),
          const Color(0x00FF9A40),
        ]),
    );
    if (_hit > 0) {
      final spark = Paint()..color = const Color(0xFFFFE8B0);
      for (var i = 0; i < 9; i++) {
        final a = -math.pi / 2 + (i - 4) * 0.32;
        canvas.drawCircle(
          const Offset(0, -22) +
              Offset(math.cos(a), math.sin(a)) * (6 + 22 * (1 - _hit)),
          1.2,
          spark,
        );
      }
    }
    canvas.restore();
  }
}

/// Eriyen demir dağın içi: açık havanın yerine koyu, pas tonlu kaya;
/// içinde kızıl demir damarları atar, akkor demir yükseldikçe daha çok
/// ışır.
class IronInterior extends Component with HasGameReference<GolgeGame> {
  IronInterior(this.area) : super(priority: -5);

  final Rect area;
  double _t = 0;
  late final List<List<Offset>> _veins = () {
    final r = math.Random(area.left.toInt() * 31 + area.top.toInt());
    return [
      for (var i = 0; i < 26; i++)
        () {
          var p = Offset(
            area.left + r.nextDouble() * area.width,
            area.top + r.nextDouble() * area.height,
          );
          final pts = [p];
          var a = r.nextDouble() * math.pi * 2;
          for (var k = 0; k < 7; k++) {
            a += (r.nextDouble() - 0.5) * 1.4;
            p += Offset(math.cos(a), math.sin(a)) * (14 + r.nextDouble() * 22);
            pts.add(p);
          }
          return pts;
        }(),
    ];
  }();

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    if (!view.overlaps(area)) return;
    canvas.save();
    canvas.clipRect(area);
    canvas.drawRect(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          area.topCenter,
          area.bottomCenter,
          const [Color(0xFF1A100C), Color(0xFF2A1610), Color(0xFF3A1A0E)],
          const [0, 0.6, 1],
        ),
    );
    // Kaya katmanları: eğik, soluk çizgiler.
    final strata = Paint()
      ..color = const Color(0xFF4A2A1C).withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var y = area.top; y < area.bottom; y += 26) {
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y + 18), strata);
    }
    // Kızıl damarlar: akkor demir yükseldikçe daha çok ışır.
    var heat = 0.35;
    for (final f in game.world.children.whereType<LightFlood>()) {
      if (f.awake) heat = 0.75;
    }
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < _veins.length; i++) {
      final pts = _veins[i];
      final pulse = 0.6 + 0.4 * math.sin(_t * 1.6 + i * 0.9);
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      glow
        ..strokeWidth = 5
        ..color = const Color(0xFFFF5A1E).withValues(alpha: 0.18 * heat * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glow);
      glow
        ..strokeWidth = 1.4
        ..maskFilter = null
        ..color = const Color(0xFFFF9A50).withValues(alpha: 0.7 * heat * pulse);
      canvas.drawPath(path, glow);
    }
    canvas.restore();
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

  /// Ritimli damarda basılan körük boşalır, dolması bu kadar sürer.
  static const double refill = 0.8;
  double _empty = 0;

  /// Körük dolu mu (ritimde basılabilir).
  bool get ready => _empty <= 0;

  /// Sırası 0 olan körük süstür (dağın dibindeki yetmiş körükten biri);
  /// sıralı damarda süs körüğe basmak ocağı söndürür.
  @override
  bool canUse(Vector2 p) =>
      (order > 0 || !(vein?.rhythm ?? false)) &&
      (p.x - position.x).abs() < 26 &&
      (p.y - position.y).abs() < 44;

  /// Ritimde sırası bu körükte mi (ışıklı körük).
  bool get isTurn {
    final v = vein;
    return v != null && v.rhythm && identical(v.activeBellows, this);
  }

  /// Sıralı damarda sıradaki körük mü.
  bool get isNext {
    final v = vein;
    return v != null && !v.rhythm && v.lit && !v.opening && order == v.next;
  }

  @override
  void use() {
    final v = vein;
    if (v != null && v.rhythm && v.lit && !isTurn) {
      // Sırası başka körükte: bu körük sönük.
      GameAudio.instance.play('creak', volume: 0.3, minGapMs: 200);
      return;
    }
    if (v != null && v.rhythm && !ready) {
      // Boş körük: hava yok.
      GameAudio.instance.play('creak', volume: 0.3, minGapMs: 200);
      return;
    }
    _press = 1;
    GameAudio.instance.play('gust', volume: 0.35, minGapMs: 150);
    if (v != null && v.rhythm && v.lit) _empty = refill;
    v?.pump(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _press = math.max(0, _press - dt * 3);
    _empty = math.max(0, _empty - dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    // Basınca çöker; ritimde boşken yavaş yavaş yeniden şişer.
    final deflated = _empty / refill;
    final squash =
        (1 - 0.45 * math.sin(_press * math.pi)) * (1 - 0.55 * deflated);
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
    final v = vein;
    if (v != null && v.rhythm) {
      // Ritimli ocakta yalnız sıradaki körük yanar: üstünde aşağı bakan
      // ok, vuruşa doğru daralan halka ve kaç vuruş kaldığını gösteren
      // korlar. Öbür körükler sönük.
      if (order > 0 && v.lit && !v.opening && isTurn) {
        _turnMarks(canvas, v, top);
      }
      canvas.restore();
      return;
    }
    // Çentikler: sırası (ışıklı oyuk); iri, uzaktan sayılır. Sıradaki
    // körüğün çentikleri parlar, üstünde aşağı bakan bir ok atar.
    final hot = vein?.lit ?? false;
    final next = isNext;
    final notch = Paint()
      ..color =
          (next
                  ? const Color(0xFFFFE6A8)
                  : hot
                  ? const Color(0xFFB89868)
                  : const Color(0xFF8A7A68))
              .withValues(alpha: next ? 0.8 + 0.2 * math.sin(_t * 5) : 0.6);
    for (var i = 0; i < order; i++) {
      canvas.drawCircle(
        Offset((i - (order - 1) / 2) * 8.0, top - 10),
        2.8,
        notch,
      );
    }
    if (next) _arrow(canvas, top - 20);
    canvas.restore();
  }

  /// Aşağı bakan, inip kalkan ılık ok: "buna bas".
  void _arrow(Canvas canvas, double y) {
    final bob = 3 * math.sin(_t * 4);
    final p = Paint()
      ..color = const Color(0xFFFFD890)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final tip = Offset(0, y + bob);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx - 6, tip.dy - 6)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + 6, tip.dy - 6)
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx, tip.dy - 13),
      p,
    );
  }

  /// Ritimde sıradaki körüğün işaretleri: kaç vuruş kaldığını gösteren
  /// korlar, vuruşa doğru daralan halka, ok.
  void _turnMarks(Canvas canvas, IronVein v, double top) {
    const need = IronVein.beatsNeeded;
    for (var i = 0; i < need; i++) {
      final lit = i < v.beats;
      final at = Offset((i - (need - 1) / 2) * 7.0, top - 40);
      canvas.drawCircle(
        at,
        lit ? 3 : 2.4,
        Paint()
          ..color = lit
              ? const Color(0xFFFF9A40)
              : const Color(0xFF140A06).withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        at,
        3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFFFC27A).withValues(alpha: 0.6),
      );
    }
    _arrow(canvas, top - 26);
    final anvil = v.anvil;
    if (anvil == null) return;
    final on = anvil.onBeat;
    if (ready) {
      // Vuruşa doğru daralan halka: kapanıp parladığı an basma anı.
      final ph = anvil.phase;
      final r = 6 + 26 * (1 - ph);
      canvas.drawCircle(
        Offset(0, top - 9),
        on ? 9 : r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 3.5 : 2
          ..color = (on ? const Color(0xFFFFE6A8) : const Color(0xFFFFB050))
              .withValues(alpha: on ? 1 : 0.35 + 0.5 * ph),
      );
    }
    canvas.drawCircle(
      Offset(0, top - 9),
      on ? 5 : 3.2,
      Paint()..color = const Color(0xFFFFD890).withValues(alpha: on ? 1 : 0.45),
    );
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
  static const double solidFor = 3.0;
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
