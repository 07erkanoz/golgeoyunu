import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'entities.dart';
import 'erlik.dart';
import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'konya.dart';
import 'legends.dart';
import 'ski.dart';
import 'strings.dart';
import 'puzzles.dart';
import 'rig.dart';
import '../settings.dart';

enum PlayerState { normal, hang, climbUp, vine, swing, dead }

/// Ölümün nasıl anlatılacağı.
enum DeathCause {
  /// Diken, düşüş.
  hazard,

  /// Suya düşüş.
  water,

  /// Kandilci ya da Gözcü yakaladı: fener ışığı taşar, kavanoz kırılır.
  light,

  /// Karabasan ya da karanlık bölge: karanlık yutar.
  dark,

  /// Medusa'nın bakışı: taşa döner.
  stone,
}

class Player extends PositionComponent with HasGameReference<GolgeGame> {
  Player(Vector2 start)
    : super(position: start, size: Vector2(w, h), priority: 20);

  static const double w = 14;
  static const double h = 28;
  static const double runSpeed = 160;
  static const double sneakSpeed = 58;
  static const double crouchSpeed = 42;
  static const double pushSpeed = 55;
  static const double jumpVelocity = 580;
  static const double gravity = 1900;
  static const double maxFall = 900;
  static const double climbSpeed = 95;

  final velocity = Vector2.zero();
  PlayerState state = PlayerState.normal;
  int facing = 1;
  bool onGround = false;
  bool crouching = false;
  bool inShadow = false;
  bool hidden = false;

  /// Parmak uçlarında yürüyor: yavaş ve sessiz, ışığı kısık.
  bool sneaking = false;

  /// Bir sandığı itiyor.
  bool pushing = false;

  /// Üstünde durduğu hareketli zemin (kaya, asansör kefesi).
  Deck? riding;

  /// Kanatlarla süzülüyor.
  bool gliding = false;
  bool _inWind = false;

  bool get hasWings =>
      (game.level.def.wings || game.wingsCollected) &&
      // Yerin altında gök yok: kanatlar açılmaz.
      game.level.def.theme != LevelTheme.underworld &&
      !game.level.def.noWings &&
      !game.level.inRain(center);

  /// Uzaktan zor görülür (parmak ucu ya da çömelme).
  bool get covering => sneaking || crouching;

  double _coyote = 0;
  double _jumpBuffer = 0;
  double _grabCooldown = 0;
  double _dropThrough = 0;

  /// Kanat çırpışları arasındaki bekleme (Tulpar'ın sırtında).
  double _flapCd = 0;
  double _stateTime = 0;
  double _anim = 0;
  double _runPhase = 0;
  double _gait = 0;
  int _lastHalfStep = 0;
  double _landDip = 0;

  // Çizim için ikincil hareket (oynanışı etkilemez): havaya geçiş, düşüşe
  // dönüş, gövde eğimi, kavanozun ve atkının gecikmeli salınımı.
  double _air = 0;
  double _fallBlend = 0;
  double _leanS = 0;
  double _prevVx = 0;
  final _jarSwing = Spring(stiffness: 70, damping: 6);
  final _scarf = Spring(stiffness: 30, damping: 5.5);

  /// Kavanozun dünyadaki son çizildiği yer (ışık oradan çıkar).
  Vector2? _jarWorld;

  /// Arkadan gelen bir ses: baş bir süre geriye döner (yalnızca çizim).
  double _lookBackT = 0;
  bool get lookingBack => _lookBackT > 0;
  void lookBack(double seconds) => _lookBackT = math.max(_lookBackT, seconds);

  /// Tetikte: kavanozu göğsüne çeker, eli hafifçe titrer. Güvenli yerde
  /// yavaşça gevşer.
  double _wary = 0;
  bool _jumpCut = true;
  bool _prevJump = false;
  bool _prevUp = false;
  bool _fell = false;
  bool _deathReported = false;
  int _hangDir = 1;
  int _hangCol = 0;
  int _hangRow = 0;
  final _climbFrom = Vector2.zero();
  final _climbTo = Vector2.zero();

  Level get level => game.level;
  bool get isDead => state == PlayerState.dead;

  void _setState(PlayerState s) {
    state = s;
    _stateTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    dt = math.min(dt, 1 / 30);
    _anim += dt;
    _stateTime += dt;
    _landDip = math.max(0, _landDip - dt);
    _updateShadow(dt);
    _updateMotion(dt);

    final c = game.controls;
    final active = !game.cinematic && !isDead;
    final left = active && c.left;
    final right = active && c.right;
    final up = active && c.up;
    final down = active && c.down;
    final jump = active && c.jump;
    final lurePressed = c.takeLure() && active;
    sneaking = active && c.sneak && state == PlayerState.normal;
    final dir = (right ? 1 : 0) - (left ? 1 : 0);
    final jumpPressed = jump && !_prevJump;
    final upPressed = up && !_prevUp;
    _prevJump = jump;
    _prevUp = up;
    _jumpBuffer = jumpPressed ? 0.12 : _jumpBuffer - dt;
    _grabCooldown -= dt;
    _lastRopeT -= dt;
    if (_lastRope != null && (onGround || _lastRopeT <= 0)) _lastRope = null;
    _dropThrough -= dt;

    // Kol çekmek ↑ ile: zincire/sarmaşığa tutunmadan önce bakılır.
    if (upPressed && state == PlayerState.normal && onGround) {
      for (final lever in game.world.children.whereType<Lever>()) {
        if (!lever.pulled && lever.near(center)) {
          lever.pull();
          _prevUp = true;
        }
      }
      for (final u in game.world.children.whereType<Usable>().toList()) {
        if (u.canUse(center)) {
          u.use();
          _prevUp = true;
          break;
        }
      }
    }

    final deck = riding;
    if (state == PlayerState.normal &&
        deck != null &&
        deck.isMounted &&
        deck.active) {
      position.add(deck.delta);
    }

    switch (state) {
      case PlayerState.normal when game.skiSurface != null:
        _updateSki(dt, dir, jump, jumpPressed);
      case PlayerState.normal:
        _updateNormal(dt, dir, up, down, jump);
      case PlayerState.hang:
        _updateHang(dir, up, down, jumpPressed, upPressed);
      case PlayerState.climbUp:
        _updateClimbUp();
      case PlayerState.vine:
        _updateVine(dt, dir, up, down, jumpPressed);
      case PlayerState.swing:
        _updateSwing(dt, dir, up, down, jumpPressed);
      case PlayerState.dead:
        _updateDead(dt);
    }

    if (state != PlayerState.normal) riding = null;
    switch (riding) {
      case CrumbleRock rock:
        rock.stoodOn = true;
      default:
    }

    if (lurePressed && state != PlayerState.climbUp) {
      game.releaseFirefly(light.$1, facing);
    }
    if (!isDead && game.skiSurface == null) _checkHazards();
    inShadow = level.rectHits(
      position.x + 2,
      position.y + 6,
      position.x + w - 2,
      position.y + h - 1,
      (ch) => ch == '~' || ch == 'I',
    );
    if (!inShadow && level.semazenCells.isNotEmpty) {
      final r = toRect();
      inShadow = game.world.children.whereType<Semazen>().any(
        (s) => s.shades(r),
      );
    }
    hidden =
        inShadow &&
        state == PlayerState.normal &&
        onGround &&
        (crouching || sneaking || velocity.x.abs() < 20);
  }

  /// Oyuncunun taşıdığı ışık: konumu ve yarıçapı (aydınlatma katmanı için).
  (Vector2, double) get light {
    final radius =
        (crouching ? 55.0 : (sneaking ? 120.0 : 200.0)) *
        game.jarStrength *
        game.jarBoost;
    if (jarStyle) {
      return (position + Vector2(w / 2 + facing * 5, 17), radius);
    }
    return (position + Vector2(w / 2 + facing * 3, 6), radius * 0.6);
  }

  // ---------------------------------------------------------------- hareket

  void _updateNormal(double dt, int dir, bool up, bool down, bool jump) {
    final wasOnGround = onGround;
    final impact = velocity.y;
    // Çalkuyruk'un sırtında çömelinmez; at daha hızlı koşar.
    crouching = onGround && down && !game.onHorse;
    if (crouching) sneaking = false;
    final maxSpeed = game.onHorse
        ? runSpeed * 1.4
        : crouching
        ? crouchSpeed
        : (pushing ? pushSpeed : (sneaking ? sneakSpeed : runSpeed));
    // Salın üstünde yürümez; sal onu sırıkla taşır.
    final target = riding is Raft ? 0.0 : dir * maxSpeed;
    // Ağırlıklı hareket: yavaş hızlanır, ters yöne dönüşte daha sert frenler.
    final reversing =
        dir != 0 && velocity.x.sign == -dir && velocity.x.abs() > 10;
    var accel = onGround
        ? (dir == 0 ? 1300.0 : (reversing ? 1700.0 : 900.0))
        : 650.0;
    // Buzda ayak tutmaz: hem hızlanmak hem durmak zordur.
    if (onGround && _onIce) accel *= 0.18;
    velocity.x = _approach(velocity.x, target, accel * dt);
    if (dir != 0 && dir != facing) {
      // Dönerken gövde bir an eski yöne yaslı kalır (ağırlık hissi).
      _leanS = -_leanS;
      _jarSwing.kick(2.5);
    }
    if (dir != 0) facing = dir;
    _runPhase += velocity.x.abs() * dt * 0.075;
    // Adım döngüsü kat edilen yola bağlı: ayaklar yerde kaymaz.
    final speedFactor = (velocity.x.abs() / runSpeed).clamp(0.0, 1.0);
    // Koşarken adım daha uzun (biraz kayarak), ritim doğal kalır.
    if (onGround) _gait += velocity.x.abs() * dt / (16 + 26 * speedFactor);

    _coyote = onGround ? 0.1 : _coyote - dt;
    _flapCd -= dt;
    // Tulpar'ın sırtında: havada zıplamak kanat çırpmaktır.
    if (game.flying &&
        _jumpBuffer > 0 &&
        _coyote <= 0 &&
        _flapCd <= 0 &&
        !onGround) {
      _jumpBuffer = 0;
      _flapCd = 0.22;
      velocity.y = -jumpVelocity * 0.85;
      _jumpCut = true;
      GameAudio.instance.play('glide', volume: 0.5, minGapMs: 120);
    }
    if (_jumpBuffer > 0 && _coyote > 0) {
      _jumpBuffer = 0;
      _coyote = 0;
      if (down && _standingOnOneWay()) {
        _dropThrough = 0.25;
        position.y += 2;
      } else {
        // Atın sıçrayışı çok daha yüksektir (yaklaşık iki katı).
        velocity.y = -jumpVelocity * (game.onHorse ? 1.42 : 1);
        _jumpCut = false;
        GameAudio.instance.play('jump', volume: sneaking ? 0.3 : 0.6);
      }
      onGround = false;
    }
    if (!_jumpCut && !jump && velocity.y < 0) {
      velocity.y *= 0.45;
      _jumpCut = true;
    }
    if (velocity.y >= 0) _jumpCut = true;

    final vyBefore = velocity.y;
    // Kanatlar: havada zıplamayı basılı tutunca süzülür.
    final wasGliding = gliding;
    final inWind = level.cellAt(center.x, center.y) == 'r';
    // Rüzgâr akımında açık kanat kapanmaz: akım onu yukarı taşır.
    gliding = hasWings && !onGround && jump && (velocity.y > -40 || inWind);
    if (gliding && !wasGliding) GameAudio.instance.play('glide', volume: 0.7);
    if (gliding) {
      velocity.y = math.min(velocity.y + gravity * 0.3 * dt, 75);
      velocity.x = _approach(
        velocity.x,
        dir * 205.0 - level.def.headwind * (1 + 0.8 * game.blizzard),
        500 * dt,
      );
    } else {
      velocity.y = math.min(velocity.y + gravity * dt, maxFall);
    }
    // Rüzgâr akımı yukarı iter; açık kanatları çok daha güçlü.
    if (inWind && !_inWind) {
      GameAudio.instance.play('gust', volume: 0.55, minGapMs: 2500);
    }
    _inWind = inWind;
    if (inWind) {
      velocity.y = gliding
          ? math.max(velocity.y - 2600 * dt, -260)
          : velocity.y - 1100 * dt;
    }
    pushing = false;
    _moveX(velocity.x * dt, dir);
    // Kare hızından bağımsız yörünge: yerçekimi/süzülme/rüzgâr ivmesi için
    // küçük bir düzeltme, her kare hızında 60 FPS'teki eğrinin aynısını
    // çizdirir (30 FPS'te zıplayış alçalmaz, 144'te yükselmez).
    final ay = dt > 0 ? (velocity.y - vyBefore) / dt : 0.0;
    _moveY(
      velocity.y * dt + ay * dt * (1 / 60 - dt) / 2,
      allowOneWay: _dropThrough <= 0,
    );

    // Sesler: koşarken adımlar, sert inişler. Tahta iskele daha çok gıcırdar.
    final quiet = sneaking || crouching;
    if (onGround && !wasOnGround) {
      if (impact > 420) _landDip = 0.16;
      if (impact > 420 && !quiet) _noise(220);
      if (impact > 250) {
        GameAudio.instance.play(
          'land',
          volume: quiet ? 0.25 : (impact / 900).clamp(0.3, 1.0),
        );
      }
    }
    // Adımlar: ayak yere bastığı anda (yürüyüş döngüsünün her yarısında)
    // tek bir ses. Koşarken yüksek ve çevreye duyulur; parmak ucunda kısık
    // ve sessizdir.
    final halfStep = (_gait * 2).floor();
    if (onGround && halfStep != _lastHalfStep && velocity.x.abs() > 30) {
      final loud = !quiet && velocity.x.abs() > 105;
      final speedVol = (velocity.x.abs() / runSpeed).clamp(0.25, 1.0);
      GameAudio.instance.play(
        _onWalkway
            ? 'step_wood'
            : (level.def.theme.snowy ? 'step_snow' : 'step'),
        volume: quiet ? 0.12 : 0.55 * speedVol,
        minGapMs: 90,
      );
      if (loud && halfStep.isEven) _noise(_onWalkway ? 210 : 140);
    }
    _lastHalfStep = halfStep;

    if (!onGround && _grabCooldown <= 0 && _tryRope()) return;
    if (_grabCooldown <= 0 &&
        _vineAt(center.x, center.y) &&
        (up || (!onGround && velocity.y > -150))) {
      _enterVine();
      return;
    }
    if (!onGround &&
        velocity.y > -60 &&
        _grabCooldown <= 0 &&
        !down &&
        (dir == facing || up)) {
      _tryLedgeGrab();
    }
  }

  bool get _onWalkway => level.cellAt(center.x, position.y + h + 2) == '=';

  bool get _onIce {
    final r = ((position.y + h + 2) / kTile).floor();
    return level.isIce(((position.x + 2) / kTile).floor(), r) ||
        level.isIce(((position.x + w - 2) / kTile).floor(), r);
  }

  void _noise(double radius) {
    final feet = Vector2(center.x, position.y + h);
    game.makeNoise(feet, radius);
  }

  /// Hareketli katı nesneler: sandıklar ve kapalı kapılar.
  Iterable<PositionComponent> get _movingSolids sync* {
    for (final c in game.world.children) {
      if (c is Crate) yield c;
      if (c is Gate && c.solid) yield c;
    }
  }

  void _moveX(double dx, int dir) {
    if (dx == 0) return;
    position.x += dx;
    final r0 = ((position.y + 1) / kTile).floor();
    // Ayak hizasındaki birkaç piksellik basamak engel sayılmaz (çukura
    // oturmuş sandığın üstünden zemine çıkarken).
    final r1 = ((position.y + h - 4) / kTile).floor();
    final c = dx > 0
        ? ((position.x + w - 0.001) / kTile).floor()
        : (position.x / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      if (!level.solid(c, r)) continue;
      position.x = dx > 0 ? c * kTile - w : (c + 1) * kTile;
      velocity.x = 0;
      return;
    }
    final me = Rect.fromLTWH(position.x, position.y + 1, w, h - 2);
    for (final o in _movingSolids) {
      final r = o.toRect();
      if (!r.overlaps(me)) continue;
      if (o is Crate && onGround && dir == dx.sign.toInt()) {
        final overlap = dx > 0 ? me.right - r.left : me.left - r.right;
        if (o.push(overlap) != 0) {
          pushing = true;
          continue;
        }
      }
      position.x = dx > 0 ? r.left - w : r.right;
      velocity.x = 0;
      return;
    }
  }

  void _moveY(double dy, {bool allowOneWay = true}) {
    final prevBottom = position.y + h;
    position.y += dy;
    onGround = false;
    riding = null;
    final c0 = ((position.x + 1) / kTile).floor();
    final c1 = ((position.x + w - 1) / kTile).floor();
    if (dy > 0) {
      // Bu karede değilen yüzeylerden en yüksekteki (ilk değilen) seçilir:
      // büyük bir adımda (düşük FPS) hem bir hareketli tahtayı hem altındaki
      // zemini geçen ayak, tahtanın içine değil üstüne konar.
      double? best;
      Deck? bestDeck;
      final r = ((position.y + h - 0.001) / kTile).floor();
      final top = r * kTile;
      for (var c = c0; c <= c1; c++) {
        final ch = level.cell(c, r);
        if (ch == '#' ||
            (allowOneWay && ch == '=' && prevBottom <= top + 0.5)) {
          best = top.toDouble();
          break;
        }
      }
      // Hareketli kayalar ve asansör kefeleri: yalnızca üstten basılır.
      if (allowOneWay) {
        for (final d in game.world.children.whereType<Deck>()) {
          if (!d.active) continue;
          final rect = d.toRect();
          if (position.x + w - 2 <= rect.left || position.x + 2 >= rect.right) {
            continue;
          }
          if (d.catches(prevBottom, position.y + h) &&
              (best == null || rect.top < best)) {
            best = rect.top;
            bestDeck = d;
          }
        }
      }
      // Sandığın üstüne basar.
      for (final o in _movingSolids) {
        final rect = o.toRect();
        if (position.x + w - 1 <= rect.left || position.x + 1 >= rect.right) {
          continue;
        }
        if (prevBottom <= rect.top + 0.5 &&
            position.y + h >= rect.top &&
            (best == null || rect.top < best)) {
          best = rect.top;
          bestDeck = null;
        }
      }
      if (best != null) {
        position.y = best - h;
        velocity.y = 0;
        onGround = true;
        riding = bestDeck;
        return;
      }
    } else if (dy < 0) {
      final r = (position.y / kTile).floor();
      for (var c = c0; c <= c1; c++) {
        if (!level.solid(c, r)) continue;
        position.y = (r + 1) * kTile;
        velocity.y = 0;
        return;
      }
    }
  }

  bool _standingOnOneWay() {
    final r = ((position.y + h + 1) / kTile).floor();
    final c0 = ((position.x + 1) / kTile).floor();
    final c1 = ((position.x + w - 1) / kTile).floor();
    var oneWay = false;
    for (var c = c0; c <= c1; c++) {
      final ch = level.cell(c, r);
      if (ch == '#') return false;
      if (ch == '=') oneWay = true;
    }
    return oneWay;
  }

  // ------------------------------------------------------------- tutunma

  bool _free(int c, int r) {
    final ch = level.cell(c, r);
    return ch != '#' && ch != '=';
  }

  void _tryLedgeGrab() {
    // Atın sırtında kenara tutunulmaz.
    if (game.onHorse) return;
    final d = facing;
    final probeX = d > 0 ? position.x + w + 3 : position.x - 3;
    final c = (probeX / kTile).floor();
    final ownC0 = ((position.x + 1) / kTile).floor();
    final ownC1 = ((position.x + w - 1) / kTile).floor();
    final hand = position.y;
    for (var r = ((hand - 8) / kTile).ceil(); r * kTile <= hand + 16; r++) {
      if (_free(c, r) || !_free(c, r - 1) || !_free(c, r - 2)) continue;
      var clear = true;
      for (var oc = ownC0; oc <= ownC1; oc++) {
        if (!_free(oc, r) || !_free(oc, r - 1) || !_free(oc, r - 2)) {
          clear = false;
        }
      }
      if (!clear) continue;
      _setState(PlayerState.hang);
      _hangDir = d;
      _hangCol = c;
      _hangRow = r;
      _hangSway
        ..reset()
        ..kick((velocity.x * d * 0.03 + velocity.y * 0.012).clamp(-4.0, 6.0));
      velocity.setZero();
      onGround = false;
      position.setValues(
        d > 0 ? c * kTile - w : (c + 1) * kTile,
        r * kTile + 3,
      );
      return;
    }
  }

  void _updateHang(
    int dir,
    bool up,
    bool down,
    bool jumpPressed,
    bool upPressed,
  ) {
    if (jumpPressed && dir == -_hangDir) {
      _setState(PlayerState.normal);
      facing = -_hangDir;
      velocity.setValues(-_hangDir * runSpeed, -jumpVelocity * 0.8);
      _jumpCut = false;
      _grabCooldown = 0.25;
      return;
    }
    if (down) {
      _setState(PlayerState.normal);
      velocity.setZero();
      _grabCooldown = 0.35;
      return;
    }
    final wantsUp =
        jumpPressed ||
        upPressed ||
        (up && _stateTime > 0.2) ||
        (dir == _hangDir && _stateTime > 0.35);
    if (!wantsUp) return;
    final tx = _hangDir > 0
        ? _hangCol * kTile + 2
        : (_hangCol + 1) * kTile - w - 2;
    final ty = _hangRow * kTile - h;
    if (level.rectSolid(tx, ty, tx + w, ty + h)) return;
    _climbFrom.setFrom(position);
    _climbTo.setValues(tx, ty);
    _setState(PlayerState.climbUp);
  }

  void _updateClimbUp() {
    const duration = 0.32;
    final t = (_stateTime / duration).clamp(0.0, 1.0);
    // Önce kollarla çekinir (hızlı başlar, kenara yaklaşınca yavaşlar),
    // yükselişin sonuna doğru beden kenarın üstüne kayar: iki hareket
    // birbirine karışır, köşe kırılmaz.
    double ease(double x) => x * x * (3 - 2 * x);
    final v = 1 - math.pow(1 - (t / 0.65).clamp(0.0, 1.0), 2.2).toDouble();
    final hx = ease(((t - 0.45) / 0.55).clamp(0.0, 1.0));
    position.setValues(
      _climbFrom.x + (_climbTo.x - _climbFrom.x) * hx,
      _climbFrom.y + (_climbTo.y - _climbFrom.y) * v,
    );
    if (t >= 1) {
      position.setFrom(_climbTo);
      velocity.setZero();
      onGround = true;
      _jumpBuffer = 0;
      _setState(PlayerState.normal);
    }
  }

  // ------------------------------------------------------------ sarmaşık

  bool _vineAt(double x, double y) => level.cellAt(x, y) == '|';

  void _enterVine() {
    final col = (center.x / kTile).floor();
    position.x = col * kTile + kTile / 2 - w / 2;
    velocity.setZero();
    crouching = false;
    _setState(PlayerState.vine);
  }

  void _updateVine(double dt, int dir, bool up, bool down, bool jumpPressed) {
    if (dir != 0) facing = dir;
    if (jumpPressed) {
      _setState(PlayerState.normal);
      velocity.setValues(dir * runSpeed, -jumpVelocity * 0.85);
      _jumpCut = false;
      _grabCooldown = 0.3;
      return;
    }
    final vy = up ? -climbSpeed : (down ? climbSpeed : 0.0);
    _runPhase += vy.abs() * dt * 0.09;
    _climbPhase -= vy * dt * 0.18;
    final prevY = position.y;
    _moveY(vy * dt, allowOneWay: false);
    velocity.setZero();
    if (!_vineAt(center.x, position.y + h * 0.5)) {
      if (vy < 0) {
        position.y = prevY;
      } else {
        _setState(PlayerState.normal);
        _grabCooldown = 0.3;
        return;
      }
    }
    if (onGround && vy > 0) _setState(PlayerState.normal);
  }

  // -------------------------------------------------------------- kayak

  /// Kayarken gövdenin (ve tahtanın) açısı.
  double skiAngle = 0;
  double _skiSpeed = 0;

  /// Havada geçen süre (takla adı için).
  double _airTime = 0;

  /// Havadaki dönüş (radyan, takla sayımı için).
  double get skiAirSpin => _airSpin;

  /// Kayarken hız. Ak Kurt'un izi ve taklalar dışarıdan iter.
  double get skiSpeed => _skiSpeed;

  /// Takladan sonraki kut hızının üst sınırı: takla uçurumları ancak bu
  /// hızla aşılır (olağan en yüksek hız 640).
  static const double kutSpeed = 800;

  /// Kayakta zıplayış hızı (yukarı). Pist üreteci de aynısını kullanır
  /// (tools/generate_maps.py SKI_JUMP).
  static const double skiJump = 560;

  /// Zıplarken yamacın aşağı akışından kalan pay.
  static double _jumpBase(double vy) => vy < 0 ? vy : vy * 0.35;

  /// Takla dönüş hızı (radyan/sn): bir tam takla ~0,83 sn; takla
  /// rampasındaki uçuşa (en az 1,2 sn) rahatça sığar.
  static const double flipRate = 7.6;

  /// İnişte bedenle yamaç arasındaki açı bundan büyükse düşülür.
  static const double landTolerance = 1.35;

  /// Kayak bölümü başlarken ya da yeniden doğunca ilk hız: kayıt noktasından
  /// sıfırdan başlayan, ilerideki takla rampasında hızlanamıyordu.
  static const double skiStartSpeed = 380;
  bool _skiStarted = false;

  /// Kayan Sâye'ye ileri itiş (Ak Kurt'un izi, takla ödülü).
  void skiKick(double dv) {
    if (game.skiSurface == null) return;
    _skiSpeed = math.min(_skiSpeed + dv, kutSpeed);
  }

  bool _skiAir = false;
  double _airSpin = 0;
  SkiRail? _grind;

  /// Zıplama tamponu: sırtta bir anlığına havalanırken ya da inmeden hemen
  /// önce basılan zıplama yutulmasın (sırttaki kayanın üstünden atlanabilsin).
  double _skiJumpBuf = 0;

  /// Bu havalanışta zıplandı mı (sırttan havalanınca bir kez hakkı var).
  bool _skiJumped = false;

  void _skiJump(double th) {
    final vy = _skiSpeed * math.sin(th);
    _skiAir = true;
    onGround = false;
    _skiJumped = true;
    _skiJumpBuf = 0;
    _airSpin = 0;
    _airTime = 0;
    velocity.setValues(
      _skiSpeed * math.cos(th) + math.sin(th) * 60,
      // Yokuş aşağı akışın çoğu bırakılır: kayakçı ekranda da gerçekten
      // havalanır (Alto gibi yüksek, süzülür bir zıplayış).
      _jumpBase(math.min(vy, velocity.y)) - skiJump,
    );
    GameAudio.instance.play('jump', volume: 0.6);
  }

  bool get skiing => game.skiSurface != null;

  static double _wrap(double a) {
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a < -math.pi) {
      a += 2 * math.pi;
    }
    return a;
  }

  /// Sırttan havalanma: yamacın kırık çizgisinde bir köşe geçilirken,
  /// zemin 1/60 sn'lik bir uçuşun düşeceğinden 1,5 pikselden fazla aşağı
  /// kaçıyorsa kayakçı havalanır. Karar yalnızca köşelerde ve sabit bir
  /// zaman penceresiyle verilir; böylece 60, 120 ya da 144 Hz'de aynı sırtta,
  /// aynı hızda aynı sonuç çıkar.
  static bool _skiLiftsOff(
    SkiSurface s,
    double x,
    double nx,
    double vx,
    double g,
  ) {
    if (nx <= x) return false;
    // Köşeler sütun ortalarında: (i + 0.5) * kTile.
    final k = ((nx / kTile) - 0.5).floor();
    final vk = (k + 0.5) * kTile;
    if (!(vk > x && vk <= nx)) return false;
    const look = 1 / 60;
    final half = vx * look / 2;
    final before = s.at(vk - half);
    final atV = s.at(vk);
    final ahead = s.at(vk + half);
    if (before == null || atV == null || ahead == null) return false;
    final rate = (atV - before) / math.max(half, 0.001);
    final ballistic = before + rate * 2 * half + 0.5 * g * look * look;
    // Küçük tümsekler kaldırmaz (kayakçı kara yapışık kalır, zıplama boşa
    // gitmez); yalnız belirgin sırtlar ve rampa uçları havalandırır.
    return ahead > ballistic + 4.0;
  }

  void _updateSki(double dt, int dir, bool jump, bool jumpPressed) {
    final s = game.skiSurface!;
    const g = 1500.0;
    if (!_skiStarted) {
      _skiStarted = true;
      _skiSpeed = math.max(_skiSpeed, skiStartSpeed);
      // Kayıt noktası karo hizasında: kayakçı karın üstüne oturtulur (yoksa
      // havada doğup düşüyordu).
      final y0 = s.at(center.x);
      if (y0 != null) {
        position.y = y0 - h;
        skiAngle = s.slope(center.x);
        _skiAir = false;
      }
    }
    _skiJumpBuf = jumpPressed ? 0.22 : math.max(0, _skiJumpBuf - dt);
    facing = 1;
    crouching = false;
    sneaking = false;
    onGround = false;
    final rail = _grind;
    if (rail != null) {
      // Kütüğün üstünde kayar: sürtünme yok.
      position.x += _skiSpeed * dt;
      position.y = rail.top - h;
      skiAngle += (0 - skiAngle) * math.min(1, dt * 12);
      onGround = true;
      velocity.setValues(_skiSpeed, 0);
      if (jumpPressed) {
        _grind = null;
        _skiAir = true;
        _airTime = 0;
        game.skiFx?.trick(S.of('trickRail'));
        velocity.setValues(_skiSpeed, -skiJump);
        GameAudio.instance.play('jump', volume: 0.6);
      } else if (center.x > rail.position.x + rail.size.x) {
        _grind = null;
        _skiAir = true;
        _airTime = 0;
        game.skiFx?.trick(S.of('trickRail'));
      }
      _gait += _skiSpeed * dt / 40;
      return;
    }
    if (!_skiAir) {
      final x = center.x;
      final ground = s.at(x);
      if (ground == null) {
        _skiAir = true;
        velocity.setValues(
          _skiSpeed * math.cos(skiAngle),
          _skiSpeed * math.sin(skiAngle),
        );
      } else {
        final th = s.slope(x);
        // Takladan sonra kut: altın hız, rüzgâr direnci tutmaz.
        final kut = (game.skiFx?.kut ?? 0) > 0;
        var a = g * 0.55 * math.sin(th) * (game.inMagnet(x) ? -1.4 : 1.0);
        a -=
            _skiSpeed * 0.12 +
            (kut ? 0 : 0.00035 * _skiSpeed * _skiSpeed.abs());
        // Yavaşken sopalarla güçlü itiş: en dik yokuşa da ağır ağır
        // tırmanılır, hiçbir vadide sıkışıp kalınmaz.
        if (dir > 0 && _skiSpeed < 300) a += _skiSpeed < 140 ? 760 : 280;
        if (dir < 0) a -= 460 * (_skiSpeed >= 0 ? 1 : -1);
        if (game.inMagnet(x)) a -= 180;
        if (kut) a += 260;
        _skiSpeed = (_skiSpeed + a * dt).clamp(-180.0, kut ? kutSpeed : 640.0);
        final nx = x + _skiSpeed * math.cos(th) * dt;
        // Kar hizasındaki kütüğe kayarak çıkar.
        for (final r in game.world.children.whereType<SkiRail>()) {
          if (nx > r.position.x &&
              nx < r.position.x + r.size.x &&
              (r.top - ground).abs() < 10) {
            _grind = r;
            _skiSpeed = math.max(_skiSpeed, 160);
            position.y = r.top - h;
            return;
          }
        }
        final ny = s.at(nx);
        final vy = _skiSpeed * math.sin(th);
        if (ny == null || _skiLiftsOff(s, x, nx, _skiSpeed * math.cos(th), g)) {
          // Sırttan havalanır.
          _skiAir = true;
          _skiJumped = false;
          _airSpin = 0;
          _airTime = 0;
          velocity.setValues(_skiSpeed * math.cos(th), vy);
        } else {
          position.setValues(nx - w / 2, ny - h);
          skiAngle += (th - skiAngle) * math.min(1, dt * 18);
          onGround = true;
          velocity.setValues(_skiSpeed * math.cos(th), vy);
          _gait += _skiSpeed.abs() * dt / 40;
          if (_skiJumpBuf > 0) {
            velocity.y = vy;
            _skiJump(th);
          }
        }
      }
    }
    if (_skiAir) {
      // Sırttan yeni havalanmış, kar hâlâ ayağının dibinde: zıplama sayılır.
      if (_skiJumpBuf > 0 && !_skiJumped && _airTime < 0.2) {
        // Uçurumun dudağından yeni ayrıldıysa (altı boş) da sayılır: kenara
        // geç kalan zıplama yutulmasın.
        final under = s.at(center.x);
        if ((under == null && _airTime < 0.12) ||
            (under != null && under - (position.y + h) < 16)) {
          _skiSpeed = velocity.x.abs() > 0 ? velocity.length : _skiSpeed;
          _skiJump(s.slope(center.x));
        }
      }
      _airTime += dt;
      velocity.y = math.min(velocity.y + g * dt, 900);
      position.add(velocity * dt);
      // Bırakılan taklanın kaçta kaçı dönüldü: dörtte üçü geçtiyse kendi
      // tamamlanır (tuşu biraz erken bırakan ters inmesin).
      final turn = (_airSpin / (2 * math.pi)) % 1.0;
      final finishing = !jump && _airSpin > 0 && turn > 0.62;
      if (jump || finishing) {
        // Basılı tutunca geriye takla.
        final step = flipRate * dt;
        final left = (1 - turn) * 2 * math.pi;
        final d = finishing ? math.min(step, left + 1e-4) : step;
        skiAngle -= d;
        _airSpin += d;
      } else {
        // Takla atmıyorsa beden, ineceği yamaca kendiliğinden hizalanır.
        skiAngle = _wrap(skiAngle);
        final below = s.at(center.x + velocity.x * 0.15);
        final target = below == null
            ? math.atan2(velocity.y, velocity.x) * 0.5
            : s.slope(center.x + velocity.x * 0.15);
        skiAngle += (target - skiAngle) * math.min(1, dt * 5);
      }
      // Kütüğe konar.
      for (final r in game.world.children.whereType<SkiRail>()) {
        final feet = position.y + h;
        if (velocity.y > 0 &&
            center.x > r.position.x &&
            center.x < r.position.x + r.size.x &&
            feet >= r.top &&
            feet - velocity.y * dt <= r.top + 2) {
          _grind = r;
          _skiSpeed = math.max(velocity.x, 160);
          _skiAir = false;
          position.y = r.top - h;
          GameAudio.instance.play('creak', volume: 0.6);
          return;
        }
      }
      final ground = s.at(center.x);
      // Uçurumun karşı duvarına çarpma: bir önceki karede boşluğun
      // üstündeydi ve ayakları kenarın epey altında: kenara çıkamaz, geri
      // seker ve düşer.
      if (ground != null &&
          position.y + h > ground + 14 &&
          s.at(center.x - velocity.x * dt) == null) {
        position.x -= velocity.x * dt + 2;
        velocity.setValues(
          -math.min(80.0, velocity.x.abs() * 0.15),
          velocity.y,
        );
        _airSpin = 0;
        GameAudio.instance.play('land', volume: 0.6);
      } else if (ground != null && position.y + h >= ground) {
        final th = s.slope(center.x);
        final diff = _wrap(skiAngle - th);
        if (diff.abs() < landTolerance) {
          // İnişte hız büyük ölçüde korunur (yokuşa inen durmasın).
          _skiSpeed = math.max(
            velocity.x * math.cos(th) + velocity.y * math.sin(th),
            velocity.x * 0.9,
          );
          final flips = (_airSpin / (2 * math.pi) + 0.15).floor();
          final fx = game.skiFx;
          if (flips > 0) {
            _skiSpeed += 60.0 * flips;
            fx?.trick(
              flips == 1
                  ? S.of('trickFlip')
                  : flips == 2
                  ? S.of('trickFlip2')
                  : S.of('trickFlipN').replaceAll('{n}', '$flips'),
              weight: flips,
              flip: true,
            );
          } else if (_airTime > 1.1) {
            fx?.trick(S.of('trickAir'));
          }
          _airTime = 0;
          _airSpin = 0;
          _skiAir = false;
          skiAngle = th;
          position.y = ground - h;
          GameAudio.instance.play('land', volume: 0.7);
        } else {
          die();
          return;
        }
      }
      if (position.y > level.pixelHeight + 80) die(fell: true);
      // Uçurumun dibine düştü: kenarların epey altına inince karanlık
      // yutar (dipsiz boşlukta uzun uzun düşmesin).
      if (ground == null) {
        double? edge;
        for (var k = 1; k < 30 && edge == null; k++) {
          edge = s.at(center.x + k * kTile) ?? s.at(center.x - k * kTile);
        }
        if (edge != null && position.y > edge + 260) die(fell: true);
      }
    }
    for (final r in game.world.children.whereType<SkiRock>()) {
      // Kayanın sert çekirdeği: yanına ya da tepesine sürtünmek affedilir
      // (zıplama penceresi telefonda da yakalanabilsin).
      final rr = r.toRect();
      final core = Rect.fromLTRB(
        rr.left + 7,
        rr.top + 8,
        rr.right - 7,
        rr.bottom,
      );
      if (core.overlaps(toRect().deflate(2))) {
        die();
        return;
      }
    }
  }

  // ---------------------------------------------------------------- ip

  /// Tutunulan ip ve sarkaç durumu: açı (dikeyden), açısal hız, ipteki yer.
  SwingRope? rope;
  double ropeAngle = 0;
  double _ropeOmega = 0;
  double _ropeD = 0;

  /// İpteki açısal hız (sağa salınım artı).
  double get ropeOmega => _ropeOmega;

  /// Kenara tutununca beden gelen hızla bir kez savrulur, sonra durulur.
  final _hangSway = Spring(stiffness: 30, damping: 3.2);

  /// Sarmaşıkta tırmanma evresi: yukarı artar, aşağı azalır (eller ve
  /// ayaklar sırayla tutar).
  double _climbPhase = 0;

  /// Bağlantıdan ellere uzaklık (ipin hangi boğumunda tutunulduğu).
  double get ropeDistance => _ropeD;

  /// İpte beden ellerin altında asılı: ipin açısına bir yayla, geç uyar
  /// (yön değişiminde bacaklar bir an geride kalır).
  final _swingBody = Spring(stiffness: 55, damping: 6.5);

  /// Ellerin dünyadaki yeri (ipe tutunurken).
  Vector2 get hand => Vector2(center.x, position.y + 6);

  /// Az önce bırakılan ip: bırakınca zincir elin hızıyla aynı yöne savrulur,
  /// yanından geçerken yeniden yakalanmasın. Yere basınca ya da başka ipe
  /// tutununca (veya bir süre geçince) yine tutulabilir.
  SwingRope? _lastRope;
  double _lastRopeT = 0;

  bool _tryRope() {
    for (final r in game.world.children.whereType<SwingRope>()) {
      if (r.holder != null) continue;
      if (r == _lastRope) continue;
      final d = hand - r.anchor;
      final len = d.length;
      if (len < 30 || len > r.length + 6 || d.y < 0) continue;
      // İpin o anki biçimine (boğumlarına) uzaklık.
      final along = r.grabAt(hand);
      if (along == null || along < 26) continue;
      rope = r;
      r.holder = this;
      _lastRope = null;
      ropeAngle = math.atan2(d.x, d.y);
      _swingBody.reset(ropeAngle);
      _ropeD = len.clamp(36.0, r.length);
      final tangent = Vector2(math.cos(ropeAngle), -math.sin(ropeAngle));
      _ropeOmega = velocity.dot(tangent) / _ropeD;
      velocity.setZero();
      gliding = false;
      _setState(PlayerState.swing);
      GameAudio.instance.play('creak', volume: 0.5);
      return true;
    }
    return false;
  }

  void _updateSwing(double dt, int dir, bool up, bool down, bool jumpPressed) {
    final r = rope;
    if (r == null || !r.isMounted) {
      _setState(PlayerState.normal);
      return;
    }
    // Sarkaç: yerçekimi, salınıma güç katan girdi, hafif sönüm. Küçük, sabit
    // adımlarla hesaplanır: salınım kare hızından bağımsız aynı kalır.
    final g = gravity * 0.55;
    final prevAngle = ropeAngle;
    final steps = math.max(1, (dt * 120).ceil());
    final h = dt / steps;
    for (var i = 0; i < steps; i++) {
      var alpha = -(g / _ropeD) * math.sin(ropeAngle);
      // Sallanmayı büyütmek: bacaklarla pompalamak gibi. Aşağıda ve gidiş
      // yönünde etkili, uçlarda etkisiz (ip uçta kendiliğinden hızlanmaz).
      if (dir != 0) {
        final along = dir * _ropeOmega >= -0.05 ? 1.0 : 0.35;
        alpha += dir * 2.9 * math.max(0.0, math.cos(ropeAngle * 1.25)) * along;
      }
      _ropeOmega += alpha * h;
      _ropeOmega *= 1 - 0.18 * h;
      if (up) {
        _ropeD = math.max(36, _ropeD - 80 * h);
      } else if (down) {
        _ropeD = math.min(r.length, _ropeD + 80 * h);
      } else if (_ropeD < r.length * 0.65) {
        // Yukarıdan yakalayan ipte biraz aşağı kayar: salınım uzar.
        _ropeD = math.min(r.length * 0.65, _ropeD + 110 * h);
      }
      ropeAngle += _ropeOmega * h;
      // Tepede ip gevşer: salınım orada yumuşakça durup geri döner.
      if (ropeAngle.abs() > 1.3 && ropeAngle * _ropeOmega > 0) {
        _ropeOmega *= 1 - math.min(1.0, (ropeAngle.abs() - 1.3) * 40 * h * 60);
      }
      ropeAngle = ropeAngle.clamp(-1.45, 1.45);
    }
    _placeOnRope(r);
    // Kayaya çarparsa geri sekip durur.
    if (_hitsSolid()) {
      ropeAngle = prevAngle;
      _ropeOmega *= -0.3;
      _placeOnRope(r);
    }
    // Yalnızca oyuncu yön verince döner (her salınım ucunda titremesin).
    if (dir != 0) facing = dir;
    _runPhase += _ropeOmega.abs() * dt;
    if (jumpPressed) {
      // Bırakış: ipin hızıyla savrulur, biraz da yukarı.
      final tangent = Vector2(math.cos(ropeAngle), -math.sin(ropeAngle));
      velocity
        ..setFrom(tangent * (_ropeOmega * _ropeD * 1.08))
        ..y -= 260;
      r.release(ropeAngle, _ropeOmega);
      _lastRope = r;
      _lastRopeT = 1.2;
      rope = null;
      _grabCooldown = 0.35;
      _jumpCut = false;
      GameAudio.instance.play('jump', volume: 0.5);
      _setState(PlayerState.normal);
    }
  }

  void _placeOnRope(SwingRope r) {
    final h0 =
        r.anchor + Vector2(math.sin(ropeAngle), math.cos(ropeAngle)) * _ropeD;
    position.setValues(h0.x - w / 2, h0.y - 6);
  }

  bool _hitsSolid() {
    final c0 = ((position.x + 1) / kTile).floor();
    final c1 = ((position.x + w - 1) / kTile).floor();
    final r0 = ((position.y + 1) / kTile).floor();
    final r1 = ((position.y + h - 1) / kTile).floor();
    for (var c = c0; c <= c1; c++) {
      for (var r = r0; r <= r1; r++) {
        if (level.solid(c, r)) return true;
      }
    }
    return false;
  }

  // --------------------------------------------------------------- ölüm

  void _checkHazards() {
    final bottom = position.y + h;
    final r = ((bottom - 1) / kTile).floor();
    final c0 = ((position.x + 3) / kTile).floor();
    final c1 = ((position.x + w - 3) / kTile).floor();
    for (var c = c0; c <= c1; c++) {
      final ch = level.cell(c, r);
      if (ch == '^' && bottom > r * kTile + 14) {
        die();
        return;
      }
      if (ch == 'w' && bottom > r * kTile + 12) {
        die(fell: true);
        return;
      }
    }
    if (position.y > level.pixelHeight + 80) die(fell: true);
  }

  /// Son ölümün nedeni: yakalanma ışıkla, Karabasan karanlıkla anlatılır.
  DeathCause deathCause = DeathCause.hazard;

  void die({bool fell = false, DeathCause cause = DeathCause.hazard}) {
    if (isDead) return;
    deathCause = cause;
    final water = level.cellAt(center.x, position.y + h + 4) == 'w';
    if (water) deathCause = DeathCause.water;
    // Işıkla yakalanmada cam sesi, fener ışığı taşınca gelir.
    if (deathCause != DeathCause.light) {
      GameAudio.instance.play(switch (deathCause) {
        DeathCause.water => 'splash',
        DeathCause.dark => 'breath',
        DeathCause.stone => 'grind',
        _ => 'death',
      });
    }
    _fell = fell;
    crouching = false;
    velocity.x = 0;
    _setState(PlayerState.dead);
  }

  void _updateDead(double dt) {
    if (_fell) {
      velocity.y = math.min(velocity.y + gravity * dt, maxFall);
      position.y += velocity.y * dt;
    } else {
      velocity.y = math.min(velocity.y + gravity * dt, maxFall);
      _moveY(velocity.y * dt);
    }
    final report = _fell ? 0.1 : (deathCause == DeathCause.light ? 0.12 : 0.6);
    if (!_deathReported && _stateTime > report) {
      _deathReported = true;
      game.onPlayerDied();
    }
  }

  static double _approach(double v, double target, double delta) =>
      v < target ? math.min(v + delta, target) : math.max(v - delta, target);

  // -------------------------------------------------------------- çizim
  //
  // Geçici karakter: koyu silüetli bir çocuk, ışığı gözlerinde. Profesyonel
  // çizimle değiştirilecek.

  static final _body = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _fill = Paint()..color = kInk;

  /// Geliştirici modunda V ile değişir: gözleri parlayan çocuk ya da
  /// ateşböceği kavanozlu çocuk.
  static bool jarStyle = true;

  /// Kenar ışığı geçişi: yalnızca siluet çizilir; ışıklar, kavanoz ve
  /// kanatlar atlanır.
  static bool _rimPass = false;

  // Çizimler 18x40'lık bir gövde için yapıldı; küçük çocuğa ölçeklenir.
  static const double _artW = 18;
  static const double _artH = 40;
  static const double _artScale = h / _artH;

  /// Sâye'nin gölgeleri: ayağının dibinde yere düşen yumuşak leke (havadayken
  /// iniş yerini gösterir, yere yaklaştıkça koyulaşır) ve kavanozun ışığıyla
  /// arkasındaki duvara uzanan silueti.
  void _drawShadows(Canvas canvas) {
    // Zemin: ayağın altındaki ilk dolu kare ya da iskele (en çok 6 kare).
    double? ground;
    if (onGround) {
      ground = h;
    } else {
      final feet = position.y + h;
      final r0 = (feet / kTile).floor();
      for (var r = r0; r <= r0 + 6; r++) {
        final ch = level.cell((center.x / kTile).floor(), r);
        if (ch == '#' || ch == '=' || ch == 'w' || ch == '-') {
          final top = r * kTile.toDouble();
          if (top >= feet - 1) ground = top - position.y;
          break;
        }
      }
    }
    if (ground != null) {
      final drop = (ground - h).clamp(0.0, 6 * kTile);
      final k = 1 - drop / (6 * kTile);
      final width = (18 + 8 * k) * (crouching ? 1.2 : 1);
      // Bulanıklaştırma yerine yumuşak geçişli elips (telefonda ucuz).
      final c = Offset(w / 2, ground + 0.5);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1, (4.5 * k + 1.5) / width);
      canvas.drawCircle(
        Offset.zero,
        width / 2,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            width / 2,
            [
              const Color(0xFF000000).withValues(alpha: 0.62 * k),
              const Color(0xFF000000).withValues(alpha: 0.3 * k),
              const Color(0x00000000),
            ],
            const [0, 0.55, 1],
          ),
      );
      canvas.restore();
    }
    _wallShadow(canvas);
  }

  // ------------------------------------------------------- duvardaki gölge
  //
  // Kavanoz önde, Sâye'nin gölgesi arkasındaki duvara iri ve dağınık düşer:
  // perdeye vuran bir izdüşüm. Korku anlarında gölge kendi aklıyla davranır:
  // geriden gelir ya da Sâye'den ayrılıp gider, durup döner, geri koşar.

  _ShadowMood _mood = _ShadowMood.follow;
  double _moodT = 0;
  // Gölgenin dünyadaki ayak noktası (ayrıldığında) ve yönü.
  double _shadowX = 0;
  double _shadowY = 0;
  int _shadowFacing = 1;
  double _shadowGait = 0;
  double _shadowFade = 1;
  // Geriden gelme için son konumlar (zaman, x, y).
  final _trail = <(double, double, double)>[];

  /// Korku anında gölgenin tepkisi: güçlü korkuda ayrılıp gider, hafifte
  /// geriden gelir.
  void shadowFright(double amount) {
    if (isDead || skiing) return;
    if (amount >= 0.8) {
      _mood = _ShadowMood.astray;
      _shadowX = center.x - facing * 20;
      _shadowY = position.y + h;
      _shadowFacing = -facing;
      _shadowFade = 1;
    } else if (amount >= 0.4 && _mood == _ShadowMood.follow) {
      _mood = _ShadowMood.lag;
    } else {
      return;
    }
    _moodT = 0;
  }

  /// Çizimin ikincil hareketi: kontrolü geciktirmez, yalnızca bedenin
  /// geçişlerini yumuşatır.
  void _updateMotion(double dt) {
    if (dt <= 0) return;
    _lookBackT = math.max(0, _lookBackT - dt);
    final tense = game.threat > 0.25 || _lookBackT > 0;
    _wary = approach(_wary, tense ? 1 : 0, dt, tense ? 0.15 : 0.9);
    _air = approach(_air, onGround ? 0 : 1, dt, onGround ? 0.045 : 0.08);
    _fallBlend = approach(
      _fallBlend,
      ((velocity.y + 120) / 300).clamp(0.0, 1.0),
      dt,
      0.07,
    );
    final run = onGround ? (velocity.x.abs() / runSpeed).clamp(0.0, 1.0) : 0.0;
    _leanS = approach(_leanS, run * 0.2, dt, 0.12);
    if (state == PlayerState.swing) _swingBody.update(ropeAngle, dt);
    if (state == PlayerState.hang) _hangSway.update(0, dt);
    // İleri doğru ivme (+ hızlanma, - frenleme).
    final ax = (velocity.x - _prevVx) / dt * facing;
    _prevVx = velocity.x;
    // Kavanoz ipin ucunda: hızlanınca geride kalır, frenlenince öne savrulur.
    _jarSwing.update((-ax * 0.0011).clamp(-0.75, 0.75), dt);
    // Atkı hızla ve havada açılır; frenlemede ileri savrulur.
    final wind = velocity.x.abs() / runSpeed + (onGround ? 0 : 0.4);
    _scarf.update((wind - ax * 0.0005).clamp(-0.4, 1.6), dt);
  }

  /// Testler için: son çizimde ayakların dünyadaki yeri.
  final debugFeet = <Vector2>[];

  /// Çizim uzayından (yöne çevrilmiş, ölçekli) dünyaya.
  Vector2 _toWorld(Offset a) => Vector2(
    position.x +
        (w - _artW * _artScale) / 2 +
        (facing < 0 ? _artW - a.dx : a.dx) * _artScale,
    position.y + a.dy * _artScale,
  );

  /// Işığın görünen merkezi: kavanozun çizildiği yer. Oynanış (tahtaların
  /// yanması, görülme) [light]ı kullanır; o sabit kalır.
  Vector2 get lightVisual => _jarWorld ?? light.$1;

  void _updateShadow(double dt) {
    _trail.add((_anim, center.x, position.y + h));
    while (_trail.length > 2 && _anim - _trail.first.$1 > 1.2) {
      _trail.removeAt(0);
    }
    _moodT += dt;
    switch (_mood) {
      case _ShadowMood.follow:
        break;
      case _ShadowMood.lag:
        if (_moodT > 4.5) _mood = _ShadowMood.follow;
      case _ShadowMood.astray:
        // 0–0.6 sn donar; sonra ters yöne yürüyüp solar; 2.6'da durur,
        // 3.2'de döner ve bakar; 4.0'dan sonra hızla geri gelir.
        if (_moodT > 0.6 && _moodT < 2.6) {
          _shadowX += _shadowFacing * 46 * dt;
          _shadowGait += 46 * dt / 30;
          _shadowFade = math.max(0.6, _shadowFade - dt * 0.2);
        } else if (_moodT > 3.2 && _moodT < 4.0) {
          _shadowFacing = (center.x - _shadowX).sign.toInt();
          if (_shadowFacing == 0) _shadowFacing = 1;
        } else if (_moodT >= 4.0) {
          final dx = center.x - facing * 20 - _shadowX;
          final step = 260 * dt;
          _shadowFacing = dx >= 0 ? 1 : -1;
          _shadowX += dx.abs() < step ? dx : dx.sign * step;
          _shadowY += (position.y + h - _shadowY) * math.min(1, dt * 8);
          _shadowGait += step / 22;
          _shadowFade = math.min(1, _shadowFade + dt);
          if (dx.abs() < 2 || _moodT > 7) _mood = _ShadowMood.follow;
        }
    }
  }

  void _wallShadow(Canvas canvas) {
    final mood = _mood;
    if (!jarStyle || !level.def.theme.indoor) return;
    // Saklanırken gölge yok; ama korku anında gölge kendi başına kalabilir.
    if ((hidden || crouching) && mood == _ShadowMood.follow) return;
    final flicker = 0.85 + 0.15 * math.sin(_anim * 11) * math.sin(_anim * 3.7);
    var alpha = 0.38 * flicker;
    // Gölgenin ayak noktası (yerel koordinat) ve yönü.
    var foot = Offset(w / 2 - facing * (20 + math.sin(_anim * 1.3)), h);
    var dirFacing = facing;
    var walking = false;
    switch (mood) {
      case _ShadowMood.follow:
        break;
      case _ShadowMood.lag:
        // Yarım saniye önceki yerinde: Sâye'nin peşinden geç gelir.
        final when = _anim - 0.5 * (1 - (_moodT - 3.5).clamp(0.0, 1.0));
        var past = _trail.first;
        for (final t in _trail) {
          if (t.$1 <= when) past = t;
        }
        foot = Offset(past.$2 - position.x - facing * 20, past.$3 - position.y);
      case _ShadowMood.astray:
        foot = Offset(_shadowX - position.x, _shadowY - position.y);
        dirFacing = _shadowFacing;
        walking = (_moodT > 0.6 && _moodT < 2.6) || _moodT >= 4.0;
        alpha *= _shadowFade * 1.5;
    }
    // Gölgenin kendi duruşu: ayrıldığında yürür, Sâye dursa bile.
    final saved = (facing, velocity.x, _gait, onGround, state);
    if (mood == _ShadowMood.astray) {
      facing = dirFacing;
      state = PlayerState.normal;
      onGround = true;
      velocity.x = walking ? dirFacing * 60.0 : 0;
      _gait = _shadowGait;
    }
    // Gölge tek parça çizilir, küçük bir katmanda tek seferde bulanıklaşır
    // (her uzvu ayrı bulanıklaştırmak telefonda pahalıydı).
    _fill.color = const Color(0xFF000000);
    _limb.color = _fill.color;
    _rimPass = true;
    final bounds = Rect.fromCenter(
      center: foot.translate(0, -h * 0.85),
      width: w * 3.4 + 40,
      height: h * 1.9 + 28,
    );
    canvas.saveLayer(
      bounds,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, (alpha * 1.7).clamp(0.0, 0.85))
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
    );
    canvas.save();
    // Işık yakında ve aşağıda: gölge ayaklardan büyüyerek yukarı uzanır.
    canvas.translate(foot.dx, foot.dy);
    canvas.scale(1.45, 1.7);
    canvas.translate(-w / 2, -h);
    canvas.translate((w - _artW * _artScale) / 2, 0);
    canvas.scale(_artScale);
    _renderJar(canvas);
    canvas.restore();
    canvas.restore();
    _rimPass = false;
    facing = saved.$1;
    velocity.x = saved.$2;
    _gait = saved.$3;
    onGround = saved.$4;
    state = saved.$5;
    _fill.color = kInk;
    _limb.color = kInk;
  }

  @override
  void render(Canvas canvas) {
    // Çalkuyruk'un sırtında: atın sırtına oturur (çömelik duruş), yere
    // gölge düşmez; at kendi çizilir.
    if (game.onHorse && !isDead) {
      final was = crouching;
      crouching = true;
      canvas.save();
      canvas.translate(0, -Calkuyruk.saddle + 4);
      _renderBody(canvas, riding: true);
      canvas.restore();
      crouching = was;
      return;
    }
    _renderBody(canvas);
  }

  void _renderBody(Canvas canvas, {bool riding = false}) {
    final ski = skiing && !isDead;
    if (ski) {
      canvas.save();
      canvas.translate(w / 2, h);
      canvas.rotate(skiAngle);
      canvas.translate(-w / 2, -h);
      drawSpray(canvas, Offset(w / 2 - 12, h), onGround ? _skiSpeed : 0, _anim);
    }
    if (!ski && !isDead && !riding && !Settings.lowGraphics) {
      _drawShadows(canvas);
    }
    if (jarStyle && !hidden && !crouching && !isDead && !Settings.lowGraphics) {
      // Kenar ışığı: kavanozun sıcak ışığı siluetin önünü ve tepesini yalar.
      // Aynı figür ışık renginde, ışığa doğru biraz kaydırılarak önce çizilir;
      // mürekkep figür üstüne gelince geriye yalnızca ince parlak bir kenar kalır.
      final flicker =
          0.85 + 0.15 * math.sin(_anim * 11) * math.sin(_anim * 3.7);
      _fill.color = _jarLight.withValues(alpha: 0.42 * flicker);
      _limb.color = _fill.color;
      _rimPass = true;
      canvas.save();
      canvas.translate((w - _artW * _artScale) / 2 + facing * 0.6, -0.5);
      canvas.scale(_artScale);
      _renderJar(canvas);
      canvas.restore();
      _rimPass = false;
      _fill.color = kInk;
      _limb.color = kInk;
    }
    canvas.save();
    canvas.translate((w - _artW * _artScale) / 2, 0);
    canvas.scale(_artScale);
    jarStyle ? _renderJar(canvas) : _renderEyes(canvas);
    canvas.restore();
    if (ski) {
      drawSkis(canvas, Offset(w / 2, h), 34);
      canvas.restore();
    }
  }

  void _renderEyes(Canvas canvas) {
    canvas.save();
    const cx = _artW / 2;
    if (facing < 0) {
      canvas.translate(_artW, 0);
      canvas.scale(-1, 1);
    }
    if (isDead && !_fell) {
      canvas.translate(cx, _artH);
      canvas.rotate(math.min(_stateTime * 5, 1) * math.pi / 2);
      canvas.translate(-cx, -_artH);
    }

    var headY = 8.0 + math.sin(_anim * 3) * 0.5;
    var hipY = 28.0;
    var legLen = 12.0;
    double leg1;
    double leg2;
    Offset hand1;
    Offset hand2;
    const shoulder = Offset(cx, 17);

    Offset armTo(double angle, [double len = 11]) =>
        shoulder + Offset(math.sin(angle) * len, math.cos(angle) * len);

    switch (state) {
      case PlayerState.hang:
      case PlayerState.climbUp:
        final sway = math.sin(_anim * 2.5) * 0.12;
        hand1 = const Offset(cx + 5, -4);
        hand2 = const Offset(cx + 2, -4);
        leg1 = sway + 0.1;
        leg2 = sway - 0.15;
      case PlayerState.vine || PlayerState.swing:
        final p = math.sin(_runPhase * 2);
        hand1 = Offset(cx + 2, -1 + p * 4);
        hand2 = Offset(cx - 1, 3 - p * 4);
        leg1 = 0.25 + p * 0.3;
        leg2 = 0.25 - p * 0.3;
      case PlayerState.dead:
        hand1 = armTo(0.3);
        hand2 = armTo(-0.2);
        leg1 = 0.1;
        leg2 = -0.1;
      case PlayerState.normal:
        if (!onGround) {
          final rising = velocity.y < 0;
          leg1 = rising ? 0.7 : 0.35;
          leg2 = rising ? -0.25 : -0.35;
          hand1 = armTo(rising ? 2.3 : 1.6);
          hand2 = armTo(rising ? -0.9 : -1.2);
        } else if (crouching) {
          headY += 8;
          hipY = 32;
          legLen = 9;
          final s =
              math.sin(_runPhase) * 0.5 * math.min(1, velocity.x.abs() / 40);
          leg1 = 0.9 + s;
          leg2 = -0.3 - s;
          hand1 = const Offset(cx + 6, 26);
          hand2 = const Offset(cx + 2, 27);
        } else {
          final amount = math.min(1.0, velocity.x.abs() / 80);
          final s = math.sin(_runPhase) * 0.6 * amount;
          leg1 = s;
          leg2 = -s;
          hand1 = armTo(-s * 0.9 + 0.05);
          hand2 = armTo(s * 0.9 - 0.05);
        }
    }

    final hip = Offset(cx, hipY);
    final bodyTop = Offset(cx + (crouching ? 2 : 0), headY + 7);

    _body.strokeWidth = 3.2;
    canvas.drawLine(shoulder.translate(0, headY - 8), hand2, _body);
    _body.strokeWidth = 4;
    canvas.drawLine(
      hip,
      hip + Offset(math.sin(leg2) * legLen, math.cos(leg2) * legLen),
      _body,
    );
    _body.strokeWidth = 9;
    canvas.drawLine(bodyTop, hip.translate(0, -2), _body);
    _body.strokeWidth = 4;
    canvas.drawLine(
      hip,
      hip + Offset(math.sin(leg1) * legLen, math.cos(leg1) * legLen),
      _body,
    );
    _body.strokeWidth = 3.2;
    canvas.drawLine(shoulder.translate(0, headY - 8), hand1, _body);

    final head = Offset(cx + 1, headY);
    canvas.drawCircle(head, 7.5, _fill);
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - 6, head.dy - 3)
        ..lineTo(head.dx - 9, head.dy - 9)
        ..lineTo(head.dx - 2, head.dy - 6)
        ..lineTo(head.dx, head.dy - 12)
        ..lineTo(head.dx + 3, head.dy - 6)
        ..lineTo(head.dx + 8, head.dy - 9)
        ..lineTo(head.dx + 6, head.dy - 2)
        ..close(),
      _fill,
    );

    if (!isDead) {
      final blink = (_anim % 4.3) < 0.12;
      final alpha = hidden ? 0.22 : 1.0;
      final e1 = head + const Offset(3.5, -0.5);
      final e2 = head + const Offset(6.6, 0);
      if (!hidden && !blink) {
        glowDot(canvas, e1, 5, kLight, 0.6);
        glowDot(canvas, e2, 4.5, kLight, 0.6);
      }
      final eye = Paint()..color = kLight.withValues(alpha: alpha);
      if (blink) {
        eye.strokeWidth = 1;
        canvas.drawLine(
          e1 - const Offset(1.4, 0),
          e1 + const Offset(1.4, 0),
          eye,
        );
        canvas.drawLine(
          e2 - const Offset(1.2, 0),
          e2 + const Offset(1.2, 0),
          eye,
        );
      } else {
        canvas.drawCircle(e1, 1.6, eye);
        canvas.drawCircle(e2, 1.3, eye);
      }
    }
    canvas.restore();
  }

  // ------------------------------------------------- kavanozlu çocuk stili

  static const _jarLight = Color(0xFFFFC46B);
  static final _limb = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  void _renderJar(Canvas canvas) {
    if (!_rimPass) debugFeet.clear();
    canvas.save();
    const cx = _artW / 2;
    if (facing < 0) {
      canvas.translate(_artW, 0);
      canvas.scale(-1, 1);
    }
    if (state == PlayerState.swing) {
      // Beden ellerin altında asılı; ipin açısına geç uyar.
      const pivot = Offset(cx, 2);
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(-_swingBody.value * facing);
      canvas.translate(-pivot.dx, -pivot.dy);
    }
    if (isDead && !_fell) {
      canvas.translate(cx, _artH);
      canvas.rotate(math.min(_stateTime * 5, 1) * math.pi / 2);
      canvas.translate(-cx, -_artH);
    }

    const thigh = 7.5;
    const shin = 7.5;
    final shielded = hidden || crouching;
    // Havadayken adım pozu kalkış anındaki hâlinde donar (adım döngüsü
    // yalnızca yerde ilerler); hava pozu onun üstüne karışır.
    final walking = state == PlayerState.normal && !skiing;
    final amount = walking ? math.min(1.0, velocity.x.abs() / 70) : 0.0;
    final run = walking ? (velocity.x.abs() / runSpeed).clamp(0.0, 1.0) : 0.0;
    final cycle = (_gait % 1.0) * 2 * math.pi;
    final dip = _landDip / 0.16;
    final stride = (5 + 4 * run) * amount;
    // Ayağın yerde kaldığı pay: yerdeki ayak gövdeyle tam aynı hızda geriye
    // gitmeli (kaymasın). Bir döngü 16+26·hız piksel; ayak yerdeyken 2·adım
    // kadar geri gider. Koşuda pay küçülür: iki ayağın da yerden kesildiği
    // bir an olur (gerçek koşu gibi).
    final stance = amount < 0.05
        ? 0.5
        : (2 * stride * _artScale / (16 + 26 * run)).clamp(0.25, 0.7);

    /// Ayak bu evrede yerde mi: yerdeyse basışın ne kadar ortasında (0..1).
    double planted(double phase) {
      final p = (phase % (2 * math.pi)) / (2 * math.pi);
      return p < stance ? math.sin(p / stance * math.pi) : 0;
    }

    // Kalça: yürürken basan ayağın üstünde hafifçe yükselir; koşarken basışta
    // çöker, havadayken kalkar. Sert inişte dizler bükülür.
    final load = math.max(planted(cycle), planted(cycle + math.pi));
    var hipY =
        27.0 +
        amount * ((1 - run) * -0.7 * load + run * (1.3 * load - 0.6)) +
        (amount == 0 ? math.sin(_anim * 2.2) * 0.3 : 0) +
        dip * 3.5;
    // Koşarken öne eğilir; dönüşte bir an eski yöne yaslı kalır.
    var lean = _leanS;
    var lift = 2.4 + 3.2 * run;
    Offset foot1;
    Offset foot2;
    double arm2;
    var jarAtHip = false;
    var jarHand = const Offset(0, 0);
    // Ellerin sabitlendiği yerler (kenar, zincir); boşsa kol açısından bulunur.
    Offset? backHand;
    Offset? frontHand;
    var onRope = false;

    // Dünya koordinatını bu çizimin (ölçekli, yöne çevrilmiş) uzayına çevirir.
    Offset toArt(double wx, double wy) {
      var ax = (wx - position.x - (w - _artW * _artScale) / 2) / _artScale;
      if (facing < 0) ax = _artW - ax;
      return Offset(ax, (wy - position.y) / _artScale);
    }

    Offset stepFoot(double phase) {
      // Yerdeyken gövdenin altından geriye gider, sonra havada öne savrulur.
      final p = (phase % (2 * math.pi)) / (2 * math.pi);
      if (p < stance) {
        final t = p / stance;
        return Offset(cx + stride - 2 * stride * t, _artH - 0.5);
      }
      final t = (p - stance) / (1 - stance);
      final eased = 0.5 - math.cos(t * math.pi) / 2;
      return Offset(
        cx - stride + 2 * stride * eased,
        _artH - 0.5 - math.sin(t * math.pi) * lift * amount,
      );
    }

    switch (state) {
      case PlayerState.hang:
      case PlayerState.climbUp:
        // Eller kenarı kavrar: kenarın gerçek yerine sabitlenir.
        final edgeX = _hangDir > 0 ? _hangCol * kTile : (_hangCol + 1) * kTile;
        final edge = toArt(edgeX.toDouble(), _hangRow * kTile.toDouble());
        frontHand = edge.translate(1.8, 0.6);
        backHand = edge.translate(-0.6, 1.2);
        arm2 = math.pi;
        jarAtHip = true;
        final t = state == PlayerState.climbUp
            ? (_stateTime / 0.32).clamp(0.0, 1.0)
            : 0.0;
        if (t == 0) {
          // Asılı: tutunma anındaki hızla savrulur, sonra durulur; bacaklar
          // boşlukta hafifçe sallanır.
          final sway = _hangSway.value + math.sin(_anim * 1.3) * 0.35;
          final dangle = math.sin(_anim * 2.1) * 0.8;
          hipY = 22;
          foot1 = Offset(cx + 1.5 + sway * 1.4 + dangle, 35.5);
          foot2 = Offset(
            cx - 1.5 + sway * 1.2 - dangle,
            35 - dangle.abs() * 0.6,
          );
          lean = -sway * 0.03;
        } else {
          // Kollarla çekinir, dizler toplanır; öndeki diz kenara atılır,
          // arkadaki ayak iter; beden doğrulurken ağırlık öne geçer.
          double ease(double x) => x * x * (3 - 2 * x);
          final pull = ease((t / 0.55).clamp(0.0, 1.0));
          final rise = ease(((t - 0.45) / 0.55).clamp(0.0, 1.0));
          hipY = 22 + 5 * rise;
          foot1 = Offset(
            cx + 1.5 + 2.5 * pull,
            35.5 - 8 * pull + 12 * rise - 4 * pull * (1 - rise),
          );
          foot2 = Offset(cx - 1.5 - 1.5 * rise, 35 - 3 * pull + 4.5 * rise);
          lean = 0.22 * pull * (1 - rise) + 0.12 * math.sin(rise * math.pi);
        }
      case PlayerState.swing:
        // İpte: eller başın üstünde, bacaklar salınımla savrulur.
        // İleri salınımda bacaklar öne uzanır, geri salınımda dizler toplanır
        // (salıncakta pompalamak gibi).
        final kick = (_ropeOmega * facing * 0.3).clamp(-0.7, 0.7);
        final fwd = math.max(0.0, kick);
        final tuck = math.max(0.0, -kick);
        foot1 = Offset(
          cx + 2 + fwd * 8 - tuck * 2,
          _artH - 2 - fwd * 4 - tuck * 5,
        );
        foot2 = Offset(
          cx - 1 + fwd * 6 - tuck * 3,
          _artH - 1 - fwd * 2 - tuck * 6,
        );
        arm2 = math.pi - 0.15;
        jarAtHip = true;
        onRope = true;
      case PlayerState.vine:
        // Ayaklar sırayla basar: basan ayak sarmaşıkta durur (beden yükselir),
        // öbürü bir üst tutamağa uzanır.
        double grip(double ph, double lo, double hi) {
          final q = (ph % 1 + 1) % 1;
          if (q < 0.5) return hi + (lo - hi) * (q / 0.5);
          final e = (q - 0.5) / 0.5;
          return lo + (hi - lo) * (e * e * (3 - 2 * e));
        }
        final q = _climbPhase / (2 * math.pi);
        foot1 = Offset(cx + 1.5, grip(q + 0.5, _artH, _artH - 6));
        foot2 = Offset(cx - 0.5, grip(q, _artH, _artH - 6));
        final p = math.sin(_climbPhase);
        arm2 = math.pi - 0.3 - p * 0.3;
        jarAtHip = true;
        onRope = true;
      case PlayerState.dead:
        foot1 = Offset(cx + 2, _artH);
        foot2 = Offset(cx - 2, _artH);
        arm2 = -0.3;
      case PlayerState.normal when skiing:
        // Kayak duruşu: dizler kırık, gövde öne eğik, ayaklar tahtada.
        hipY = 30;
        lean = 0.28;
        foot1 = Offset(cx + 3, _artH - 0.5);
        foot2 = Offset(cx - 3, _artH - 0.5);
        arm2 = -0.7 + math.sin(_anim * 3) * 0.1;
      case PlayerState.normal:
        if (crouching) {
          hipY = 32;
          foot1 = stepFoot(cycle).translate(1.5, 0);
          foot2 = stepFoot(cycle + math.pi).translate(-1.5, 0);
          arm2 = 0.4;
          lean = 0.35;
        } else if (pushing) {
          // Sandığı iterken: gövde öne yaslanır, kollar ileri uzanır.
          lean = 0.45;
          hipY += 1.5;
          foot1 = stepFoot(cycle).translate(-2, 0);
          foot2 = stepFoot(cycle + math.pi).translate(-3, 0);
          arm2 = 1.45;
          jarAtHip = true;
          // Avuçlar sandığın yüzüne dayanır; dirsekler zorlanırken bükülür.
          frontHand = Offset(cx + 11.5, hipY - 9);
          backHand = Offset(cx + 11, hipY - 6);
        } else if (sneaking) {
          // Parmak uçlarında: hafif çömelik, dizler yüksek kalkar, kol dengede.
          lean = 0.22;
          hipY += 1.5;
          lift = 5;
          foot1 = stepFoot(cycle);
          foot2 = stepFoot(cycle + math.pi);
          arm2 = 1.1 + math.sin(cycle) * 0.15;
        } else if (amount < 0.05) {
          foot1 = Offset(cx + 2, _artH - 0.5);
          foot2 = Offset(cx - 2, _artH - 0.5);
          arm2 = 0.05;
        } else {
          foot1 = stepFoot(cycle);
          foot2 = stepFoot(cycle + math.pi);
          // Arka kol öndeki bacağın tersine sallanır; koşuda daha geniş.
          arm2 = -math.sin(cycle) * (0.45 + 0.6 * run) * amount;
        }
        // Havaya geçiş: kalkışta adım pozundan yumuşakça toplanır; tepe
        // noktasında dizler yükselmeden düşüşe doğru açılır.
        if (_air > 0.01) {
          final rise = 1 - _fallBlend;
          final a1 = blendPose(
            Offset(cx + 3, _artH - 2),
            Offset(cx + 5, _artH - 5),
            rise,
          );
          final a2 = blendPose(
            Offset(cx - 4, _artH),
            Offset(cx - 3, _artH - 1),
            rise,
          );
          foot1 = blendPose(foot1, a1, _air);
          foot2 = blendPose(foot2, a2, _air);
          arm2 += (-1.2 + 0.3 * rise - arm2) * _air;
          lean += (0.06 - lean) * _air;
        }
        // Bacak boyu yetmiyorsa kalça iner: basan ayak yerinden kaymaz,
        // kemik uzamaz.
        if (!onGround || _air > 0.5) break;
        for (final f in [foot1, foot2]) {
          if (f.dy >= _artH - 1) {
            hipY = lowerToReach(cx, hipY, f, (thigh + shin) * 0.985);
          }
        }
    }

    final hip = Offset(cx, hipY);
    final headY = hipY - 18.5;
    final shoulder = Offset(cx + lean * 6, hipY - 10);
    final head = Offset(cx + 1 + lean * 9, headY);

    // Kavanozu tutan kol öne uzanır; yürürken hafifçe sallanır.
    // Tetikteyken (dururken) kavanoz göğse çekilir, el hafifçe titrer.
    final still = (1 - amount).clamp(0.0, 1.0) * _wary;
    final jarArm = shielded
        ? 1.9
        : (jarAtHip
              ? (pushing ? 1.4 : math.pi - 0.15)
              : (sneaking ? 1.5 : 0.55 + math.sin(cycle) * 0.1 * amount) +
                    still * (0.75 + math.sin(_anim * 37) * 0.03));
    Offset limbEnd(Offset from, double angle, double len) =>
        from + Offset(math.sin(angle) * len, math.cos(angle) * len);
    jarHand = limbEnd(shoulder, jarArm, 9.5);
    if (onRope) {
      // El ele, ipe tutunarak tırmanır; sallanırken eller kıpırdamaz.
      if (state == PlayerState.swing) {
        frontHand = Offset(cx + 0.8, shoulder.dy - 7);
        backHand = Offset(cx - 0.6, shoulder.dy - 3);
      } else {
        // El el üstüne: tutan el sarmaşıkta durur (bedene göre aşağı
        // kayar), öbürü yukarı uzanıp yeni tutamağı kavrar.
        double grip(double ph) {
          final q = (ph % 1 + 1) % 1;
          const hi = -10.0;
          const lo = 5.0;
          if (q < 0.5) return hi + (lo - hi) * (q / 0.5);
          final e = (q - 0.5) / 0.5;
          return lo + (hi - lo) * (e * e * (3 - 2 * e));
        }

        final q = _climbPhase / (2 * math.pi);
        frontHand = Offset(cx + 0.8, shoulder.dy + grip(q));
        backHand = Offset(cx - 0.6, shoulder.dy + grip(q + 0.5));
      }
    }
    // Kavanoz ipin ucunda bir yay: ivmeye gecikmeli tepki verir; adımla
    // hafifçe sekip dururken neredeyse kıpırdamaz.
    final swing =
        _jarSwing.value +
        math.sin(cycle * 2) * 0.06 * amount * (1 - _air) +
        math.sin(_anim * 1.7) * 0.03;
    final jar = jarAtHip
        ? hip.translate(5, -1)
        : (shielded
              ? jarHand.translate(-1.5, 1.5)
              : jarHand + Offset(math.sin(swing) * 4.5, math.cos(swing) * 4.5));
    final flicker = 0.85 + 0.15 * math.sin(_anim * 11) * math.sin(_anim * 3.7);
    final lightAmount = isDead ? 0.0 : (shielded ? 0.12 : 1.0) * flicker;

    if (lightAmount > 0 && !_rimPass) {
      canvas.drawCircle(
        jar,
        64,
        Paint()
          ..shader = ui.Gradient.radial(
            jar,
            64,
            [
              _jarLight.withValues(alpha: 0.26 * lightAmount),
              _jarLight.withValues(alpha: 0.08 * lightAmount),
              _jarLight.withValues(alpha: 0),
            ],
            const [0, 0.4, 1],
          ),
      );
    }

    // Arkadaki kol ve bacak bir ton açık: iki bacak birbirine karışmaz,
    // derinlik okunur (kenar ışığı ve gölge geçişlerinde tek renk).
    final ink = _limb.color;
    final far = _rimPass
        ? ink
        : Color.lerp(kInk, const Color(0xFF5A3A26), 0.32)!;

    void leg(Offset target, {bool back = false}) {
      final (knee, foot) = solveLimb(hip, target, thigh, shin);
      if (!_rimPass) debugFeet.add(_toWorld(foot));
      _limb
        ..color = back ? far : ink
        ..strokeWidth = 4.4;
      _fill.color = _limb.color;
      // Uyluk kalın, baldır incelir.
      canvas.drawLine(hip, knee, _limb..strokeJoin = StrokeJoin.round);
      _limb.strokeWidth = 3.6;
      canvas.drawLine(knee, foot, _limb);
      // Küçük bot.
      canvas.drawOval(
        Rect.fromCenter(
          center: foot.translate(1.6, -0.6),
          width: 6.4,
          height: 3,
        ),
        _fill,
      );
      _limb.color = ink;
      _fill.color = ink;
    }

    /// Kol: omuzdan dirseğe kalın, bileğe incelir; dirsek geriye kırılır.
    void arm(Offset target, {bool back = false}) {
      final (elbow, hand) = solveLimb(shoulder, target, 5, 5, bend: -1);
      _limb
        ..color = back ? far : ink
        ..strokeWidth = 3.4;
      canvas.drawLine(shoulder, elbow, _limb);
      _limb.strokeWidth = 2.6;
      canvas.drawLine(elbow, hand, _limb);
      _fill.color = _limb.color;
      canvas.drawCircle(hand, 1.7, _fill);
      _limb.color = ink;
      _fill.color = ink;
    }

    // Arka kol ve arka bacak.
    arm(backHand ?? limbEnd(shoulder, arm2, 9.5), back: true);
    leg(foot2, back: true);

    // İnce gövde; dizlere inen, arkası rüzgârla açılan uzun bir hırka.
    // Atkı, saç ve hırka bir yaya bağlı: hızlanınca açılır, frenlenince bir
    // an öne savrulur, dururken yavaşça sarkar.
    final wind = math.max(0.0, _scarf.value);
    final fling = math.max(0.0, -_scarf.value);
    _limb.strokeWidth = 8;
    canvas.drawLine(
      Offset(head.dx - 0.5, headY + 7),
      hip.translate(0, -1.5),
      _limb,
    );
    final flare = 1.5 + wind * 2.5 + math.sin(_anim * 4) * 0.4 * (0.3 + wind);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 4.2, hipY - 8)
        ..lineTo(cx + 4.2 + lean * 4, hipY - 8)
        ..quadraticBezierTo(cx + 5.5, hipY + 1, cx + 4.6, hipY + 6)
        ..lineTo(cx - 4.5 - flare, hipY + 6.5 - flare * 0.5)
        ..quadraticBezierTo(cx - 5, hipY, cx - 4.2, hipY - 8)
        ..close(),
      _fill,
    );

    if (hasWings && !_rimPass) {
      _drawWings(canvas, Offset(cx - 1 + lean * 6, hipY - 10));
    }

    leg(foot1);

    // Arkadan bir ses: baş geriye döner (beden yerinde kalır).
    final looking = _lookBackT > 0;
    if (looking) {
      canvas.save();
      canvas.translate(head.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-head.dx, 0);
    }
    // Baş: yuvarlak kafatası, öne çıkan alın ve küçük burun, geriye çekilen
    // çene; dağınık saçlar rüzgârla arkaya yatar.
    canvas.drawCircle(head.translate(-0.3, -0.2), 6.0, _fill);
    canvas.drawPath(
      Path()
        ..moveTo(head.dx + 4.4, head.dy - 2.4)
        ..quadraticBezierTo(
          head.dx + 6.4,
          head.dy - 0.8,
          head.dx + 7.1,
          head.dy + 1.2,
        )
        ..lineTo(head.dx + 5.4, head.dy + 2.0)
        ..quadraticBezierTo(
          head.dx + 5.6,
          head.dy + 4.4,
          head.dx + 2.8,
          head.dy + 5.6,
        )
        ..lineTo(head.dx - 1.2, head.dy + 5.0)
        ..close(),
      _fill,
    );
    // Saç tek parça: alnın üstünden tepeye, ardından arkaya yatan üç tutam.
    final b = wind * 2.4;
    // Dururken saç kıpırdamaz; rüzgârda dalgalanır; düşerken havalanır,
    // yükselirken sarkar.
    final float = (_fallBlend - 0.5) * 2 * _air;
    double sw(int i) =>
        math.sin(_anim * 5 + i * 1.4) * (0.06 + wind * 0.55) -
        float * (1.4 + i * 0.5);
    Offset h(double x, double y) => head + Offset(x, y);
    final hair = Path()
      ..moveTo(h(5.8, -1.5).dx, h(5.8, -1.5).dy)
      ..quadraticBezierTo(
        h(7.2, -5).dx,
        h(7.2, -5).dy,
        h(4, -6.6).dx,
        h(4, -6.6).dy,
      )
      ..quadraticBezierTo(
        h(0.5, -8.6).dx,
        h(0.5, -8.6).dy,
        h(-4, -7.4).dx,
        h(-4, -7.4).dy,
      )
      ..lineTo(h(-9.5 - b, -7 + sw(0)).dx, h(-9.5 - b, -7 + sw(0)).dy)
      ..lineTo(h(-6.4, -4.6).dx, h(-6.4, -4.6).dy)
      ..lineTo(h(-10.5 - b, -3 + sw(1)).dx, h(-10.5 - b, -3 + sw(1)).dy)
      ..lineTo(h(-6.8, -0.8).dx, h(-6.8, -0.8).dy)
      ..lineTo(h(-9 - b * 0.8, 2 + sw(2)).dx, h(-9 - b * 0.8, 2 + sw(2)).dy)
      ..lineTo(h(-5.2, 3).dx, h(-5.2, 3).dy)
      ..lineTo(h(-2, -1).dx, h(-2, -1).dy)
      ..close();
    canvas.drawPath(hair, _fill);

    if (looking) canvas.restore();

    // Uzun atkı: boyuna dolanır, iki ucu ardında dalgalanır.
    final neck = Offset(head.dx - 1.5, headY + 7);
    canvas.drawOval(
      Rect.fromCenter(center: neck.translate(0.5, 0), width: 9, height: 4),
      _fill,
    );
    for (final tail in const [0.0, 1.0]) {
      final len = 13.0 - tail * 4 + wind * 5;
      final top = <Offset>[];
      final bottom = <Offset>[];
      const n = 7;
      for (var i = 0; i <= n; i++) {
        final k = i / n;
        // Dururken aşağı sarkar, koşarken ve havada yatayda savrulur.
        final sweep = (0.25 + wind * 0.75).clamp(0.0, 1.0);
        final wave =
            math.sin(_anim * (7 + tail * 2) - k * 5 + tail) * k * (0.6 + wind);
        final x =
            neck.dx -
            1 -
            k * len * (0.25 + sweep * 0.75) +
            tail +
            k * len * fling * 1.4;
        final y = neck.dy + 0.5 + k * len * (1 - sweep) * 0.9 + wave + tail;
        final half = 1.3 * (1 - k * 0.45);
        top.add(Offset(x, y - half));
        bottom.add(Offset(x, y + half));
      }
      final ribbon = Path()..addPolygon([...top, ...bottom.reversed], true);
      canvas.drawPath(ribbon, _fill);
    }

    // Kavanozu tutan ön kol ve ip.
    final front = frontHand ?? jarHand;
    arm(front);
    if (_rimPass) {
      canvas.restore();
      return;
    }
    if (!jarAtHip && !shielded) {
      canvas.drawLine(
        jarHand,
        jar.translate(0, -5.4),
        Paint()
          ..color = kInk
          ..strokeWidth = 0.9,
      );
    }

    _drawJar(canvas, jar, lightAmount);
    {
      // Işığın görünen merkezi: kavanozun bu karedeki gerçek yeri (kenar ışığı
      // ve duvar gölgesi geçişleri buraya gelmeden döner).
      _jarWorld = state == PlayerState.normal && !skiing && !isDead && !jarAtHip
          ? _toWorld(jar)
          : null;
    }

    if (lightAmount > 0.2) {
      canvas.drawCircle(
        jar,
        22,
        Paint()
          ..shader = ui.Gradient.radial(jar, 22, [
            _jarLight.withValues(alpha: 0.16 * lightAmount),
            _jarLight.withValues(alpha: 0),
          ]),
      );
    }
    canvas.restore();
  }

  void _drawJar(Canvas canvas, Offset c, double light) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 6.4, height: 7.6),
      const Radius.circular(2.2),
    );
    canvas.drawRRect(
      body,
      Paint()..color = Color.lerp(kInk, _jarLight, 0.15 + 0.75 * light)!,
    );
    if (light > 0.2) {
      glowDot(canvas, c, 8, _jarLight, 0.55 * light);
      // Uçuşan ateşböcekleri.
      final fly = Paint()
        ..color = const Color(0xFFFFF6D8).withValues(alpha: light);
      for (var i = 0; i < 3; i++) {
        final t = _anim * (1.6 + i * 0.7) + i * 2.1;
        canvas.drawCircle(
          c + Offset(math.sin(t) * 1.8, math.cos(t * 1.3) * 2.2),
          0.7,
          fly,
        );
      }
    }
    canvas.drawRRect(
      body,
      Paint()
        ..color = kInk.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    // Camın yan yüzündeki ince parıltı: kavanoz olduğu uzaktan da seçilir.
    canvas.drawLine(
      c.translate(-1.9, -2.3),
      c.translate(-1.9, 1.4),
      Paint()
        ..color = const Color(0xFFFFF8E8).withValues(alpha: 0.25 + 0.35 * light)
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round,
    );
    // Kapak ve ip.
    canvas.drawRect(
      Rect.fromCenter(center: c.translate(0, -4.4), width: 5.4, height: 1.8),
      _fill,
    );
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(0, -5.4), width: 4.4, height: 3.6),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
  }

  /// Hezarfen'in kanatları: süzülürken açılır, yoksa sırtta katlıdır.
  void _drawWings(Canvas canvas, Offset shoulder) {
    final cloth = Paint()
      ..color = const Color(0xFFE2D2B6).withValues(alpha: 0.88);
    final frame = Paint()
      ..color = kInk
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    if (gliding) {
      final flap = math.sin(_anim * 6) * 1.5;
      for (final s in [-1.0, 1.0]) {
        final wing = Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..quadraticBezierTo(
            shoulder.dx + s * 12,
            shoulder.dy - 14 + flap,
            shoulder.dx + s * 26,
            shoulder.dy - 8 + flap,
          )
          ..lineTo(shoulder.dx + s * 22, shoulder.dy - 3)
          ..lineTo(shoulder.dx + s * 17, shoulder.dy - 1)
          ..lineTo(shoulder.dx + s * 10, shoulder.dy + 2)
          ..close();
        canvas.drawPath(wing, cloth);
        canvas.drawPath(wing, frame);
      }
    } else {
      final folded = Path()
        ..moveTo(shoulder.dx - 1, shoulder.dy - 2)
        ..lineTo(shoulder.dx - 7, shoulder.dy - 6)
        ..lineTo(shoulder.dx - 6, shoulder.dy + 9)
        ..lineTo(shoulder.dx - 1, shoulder.dy + 6)
        ..close();
      canvas.drawPath(folded, cloth);
      canvas.drawPath(folded, frame);
    }
  }
}

enum _ShadowMood { follow, lag, astray }
