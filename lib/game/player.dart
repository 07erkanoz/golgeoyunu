import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'entities.dart';
import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'legends.dart';
import 'ski.dart';
import 'puzzles.dart';

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

  bool get hasWings =>
      (game.level.def.wings || game.wingsCollected) &&
      !game.level.inRain(center);

  /// Uzaktan zor görülür (parmak ucu ya da çömelme).
  bool get covering => sneaking || crouching;

  double _coyote = 0;
  double _jumpBuffer = 0;
  double _grabCooldown = 0;
  double _dropThrough = 0;
  double _stateTime = 0;
  double _anim = 0;
  double _runPhase = 0;
  double _gait = 0;
  int _lastHalfStep = 0;
  double _landDip = 0;
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
    hidden =
        inShadow &&
        state == PlayerState.normal &&
        onGround &&
        (crouching || sneaking || velocity.x.abs() < 20);
  }

  /// Oyuncunun taşıdığı ışık: konumu ve yarıçapı (aydınlatma katmanı için).
  (Vector2, double) get light {
    final radius =
        (crouching ? 55.0 : (sneaking ? 120.0 : 200.0)) * game.jarStrength;
    if (jarStyle) {
      return (position + Vector2(w / 2 + facing * 5, 17), radius);
    }
    return (position + Vector2(w / 2 + facing * 3, 6), radius * 0.6);
  }

  // ---------------------------------------------------------------- hareket

  void _updateNormal(double dt, int dir, bool up, bool down, bool jump) {
    final wasOnGround = onGround;
    final impact = velocity.y;
    crouching = onGround && down;
    if (crouching) sneaking = false;
    final maxSpeed = crouching
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
    if (dir != 0) facing = dir;
    _runPhase += velocity.x.abs() * dt * 0.075;
    // Adım döngüsü kat edilen yola bağlı: ayaklar yerde kaymaz.
    final speedFactor = (velocity.x.abs() / runSpeed).clamp(0.0, 1.0);
    // Koşarken adım daha uzun (biraz kayarak), ritim doğal kalır.
    if (onGround) _gait += velocity.x.abs() * dt / (16 + 26 * speedFactor);

    _coyote = onGround ? 0.1 : _coyote - dt;
    if (_jumpBuffer > 0 && _coyote > 0) {
      _jumpBuffer = 0;
      _coyote = 0;
      if (down && _standingOnOneWay()) {
        _dropThrough = 0.25;
        position.y += 2;
      } else {
        velocity.y = -jumpVelocity;
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

    // Kanatlar: havada zıplamayı basılı tutunca süzülür.
    final wasGliding = gliding;
    gliding = hasWings && !onGround && jump && velocity.y > -40;
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
    if (level.cellAt(center.x, center.y) == 'r') {
      velocity.y = gliding
          ? math.max(velocity.y - 2600 * dt, -260)
          : velocity.y - 1100 * dt;
    }
    pushing = false;
    _moveX(velocity.x * dt, dir);
    _moveY(velocity.y * dt, allowOneWay: _dropThrough <= 0);

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
        _onWalkway ? 'step_wood' : 'step',
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
      final r = ((position.y + h - 0.001) / kTile).floor();
      final top = r * kTile;
      for (var c = c0; c <= c1; c++) {
        final ch = level.cell(c, r);
        if (ch == '#' ||
            (allowOneWay && ch == '=' && prevBottom <= top + 0.5)) {
          position.y = top - h;
          velocity.y = 0;
          onGround = true;
          return;
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
          final prevTop = rect.top - d.delta.y;
          if (prevBottom <= prevTop + 1 && position.y + h >= rect.top) {
            position.y = rect.top - h;
            velocity.y = 0;
            onGround = true;
            riding = d;
            return;
          }
        }
      }
      // Sandığın üstüne basar.
      for (final o in _movingSolids) {
        final rect = o.toRect();
        if (position.x + w - 1 <= rect.left || position.x + 1 >= rect.right) {
          continue;
        }
        if (prevBottom <= rect.top + 0.5 && position.y + h >= rect.top) {
          position.y = rect.top - h;
          velocity.y = 0;
          onGround = true;
          return;
        }
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
    if (t < 0.6) {
      final k = t / 0.6;
      position.setValues(
        _climbFrom.x,
        _climbFrom.y + (_climbTo.y - _climbFrom.y) * k,
      );
    } else {
      final k = (t - 0.6) / 0.4;
      position.setValues(
        _climbFrom.x + (_climbTo.x - _climbFrom.x) * k,
        _climbTo.y,
      );
    }
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
  bool _skiAir = false;
  double _airSpin = 0;
  SkiRail? _grind;

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

  void _updateSki(double dt, int dir, bool jump, bool jumpPressed) {
    final s = game.skiSurface!;
    const g = 1500.0;
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
        velocity.setValues(_skiSpeed, -430);
        GameAudio.instance.play('jump', volume: 0.6);
      } else if (center.x > rail.position.x + rail.size.x) {
        _grind = null;
        _skiAir = true;
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
        var a = g * 0.55 * math.sin(th) * (game.inMagnet(x) ? -1.4 : 1.0);
        a -= _skiSpeed * 0.12 + 0.00035 * _skiSpeed * _skiSpeed.abs();
        if (dir > 0 && _skiSpeed < 300) a += 280;
        if (dir < 0) a -= 460 * (_skiSpeed >= 0 ? 1 : -1);
        if (game.inMagnet(x)) a -= 180;
        _skiSpeed = (_skiSpeed + a * dt).clamp(-180.0, 640.0);
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
        final yb = ground + vy * dt + 0.5 * g * dt * dt;
        if (ny == null || ny > yb + 1.5) {
          // Sırttan havalanır.
          _skiAir = true;
          _airSpin = 0;
          velocity.setValues(_skiSpeed * math.cos(th), vy);
        } else {
          position.setValues(nx - w / 2, ny - h);
          skiAngle += (th - skiAngle) * math.min(1, dt * 18);
          onGround = true;
          velocity.setValues(_skiSpeed * math.cos(th), vy);
          _gait += _skiSpeed.abs() * dt / 40;
          if (jumpPressed) {
            _skiAir = true;
            _airSpin = 0;
            velocity.setValues(
              _skiSpeed * math.cos(th) + math.sin(th) * 60,
              vy - 440,
            );
            GameAudio.instance.play('jump', volume: 0.6);
          }
        }
      }
    }
    if (_skiAir) {
      velocity.y = math.min(velocity.y + g * dt, 900);
      position.add(velocity * dt);
      if (jump) {
        // Basılı tutunca geriye takla.
        skiAngle -= 6.2 * dt;
        _airSpin += 6.2 * dt;
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
      if (ground != null && position.y + h >= ground) {
        final th = s.slope(center.x);
        final diff = _wrap(skiAngle - th);
        if (diff.abs() < 1.1) {
          _skiSpeed = velocity.x * math.cos(th) + velocity.y * math.sin(th);
          final flips = (_airSpin / (2 * math.pi) + 0.15).floor();
          if (flips > 0) {
            _skiSpeed += 60.0 * flips;
            GameAudio.instance.play('firefly', volume: 0.6);
          }
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
    }
    for (final r in game.world.children.whereType<SkiRock>()) {
      if (r.toRect().deflate(4).overlaps(toRect())) {
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

  /// Ellerin dünyadaki yeri (ipe tutunurken).
  Vector2 get hand => Vector2(center.x, position.y + 6);

  bool _tryRope() {
    for (final r in game.world.children.whereType<SwingRope>()) {
      if (r.holder != null) continue;
      final d = hand - r.anchor;
      final len = d.length;
      if (len < 30 || len > r.length + 6 || d.y < 0) continue;
      // İpin o anki çizgisine uzaklık.
      final dir = Vector2(math.sin(r.angle), math.cos(r.angle));
      final along = d.dot(dir);
      final perp = (d - dir * along).length;
      if (perp > 16) continue;
      rope = r;
      r.holder = this;
      ropeAngle = math.atan2(d.x, d.y);
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
    // Sarkaç: yerçekimi, salınıma güç katan girdi, hafif sönüm.
    final g = gravity * 0.55;
    var alpha = -(g / _ropeD) * math.sin(ropeAngle);
    alpha += dir * 2.6;
    _ropeOmega += alpha * dt;
    _ropeOmega *= 1 - 0.18 * dt;
    if (up) {
      _ropeD = math.max(36, _ropeD - 80 * dt);
    } else if (down) {
      _ropeD = math.min(r.length, _ropeD + 80 * dt);
    } else if (_ropeD < r.length * 0.65) {
      // Yukarıdan yakalayan ipte biraz aşağı kayar: salınım uzar.
      _ropeD = math.min(r.length * 0.65, _ropeD + 110 * dt);
    }
    final prevAngle = ropeAngle;
    ropeAngle = (ropeAngle + _ropeOmega * dt).clamp(-1.4, 1.4);
    if (ropeAngle.abs() >= 1.4) _ropeOmega *= -0.2;
    _placeOnRope(r);
    // Kayaya çarparsa geri sekip durur.
    if (_hitsSolid()) {
      ropeAngle = prevAngle;
      _ropeOmega *= -0.3;
      _placeOnRope(r);
    }
    if (_ropeOmega.abs() > 0.2) facing = _ropeOmega > 0 ? 1 : -1;
    if (dir != 0) facing = dir;
    _runPhase += _ropeOmega.abs() * dt;
    if (jumpPressed) {
      // Bırakış: ipin hızıyla savrulur, biraz da yukarı.
      final tangent = Vector2(math.cos(ropeAngle), -math.sin(ropeAngle));
      velocity
        ..setFrom(tangent * (_ropeOmega * _ropeD * 1.08))
        ..y -= 260;
      r.release(ropeAngle, _ropeOmega);
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

  // Çizimler 18x40'lık bir gövde için yapıldı; küçük çocuğa ölçeklenir.
  static const double _artW = 18;
  static const double _artH = 40;
  static const double _artScale = h / _artH;

  @override
  void render(Canvas canvas) {
    final ski = skiing && !isDead;
    if (ski) {
      canvas.save();
      canvas.translate(w / 2, h);
      canvas.rotate(skiAngle);
      canvas.translate(-w / 2, -h);
      drawSpray(canvas, Offset(w / 2 - 12, h), onGround ? _skiSpeed : 0, _anim);
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

  double get _speedFactor => (velocity.x.abs() / runSpeed).clamp(0.0, 1.0);

  /// İki kemikli bacak: kalçadan ayağa, diz öne doğru kırılır.
  static Offset _knee(Offset hip, Offset foot, double thigh, double shin) {
    final d = foot - hip;
    final dist = d.distance.clamp(0.01, thigh + shin - 0.01);
    final base = math.atan2(d.dy, d.dx);
    final cosA =
        ((thigh * thigh + dist * dist - shin * shin) / (2 * thigh * dist))
            .clamp(-1.0, 1.0);
    final a = math.acos(cosA);
    final k1 = hip + Offset(math.cos(base - a), math.sin(base - a)) * thigh;
    final k2 = hip + Offset(math.cos(base + a), math.sin(base + a)) * thigh;
    return k1.dx > k2.dx ? k1 : k2;
  }

  void _renderJar(Canvas canvas) {
    canvas.save();
    const cx = _artW / 2;
    if (facing < 0) {
      canvas.translate(_artW, 0);
      canvas.scale(-1, 1);
    }
    if (state == PlayerState.swing) {
      // Gövde ipin doğrultusunda: eller dönme noktası.
      const pivot = Offset(cx, 2);
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(-ropeAngle * facing);
      canvas.translate(-pivot.dx, -pivot.dy);
    }
    if (isDead && !_fell) {
      canvas.translate(cx, _artH);
      canvas.rotate(math.min(_stateTime * 5, 1) * math.pi / 2);
      canvas.translate(-cx, -_artH);
    }

    const thigh = 7.0;
    const shin = 7.0;
    final shielded = hidden || crouching;
    final walking = state == PlayerState.normal && onGround;
    final amount = walking ? math.min(1.0, velocity.x.abs() / 70) : 0.0;
    final run = walking ? (velocity.x.abs() / runSpeed).clamp(0.0, 1.0) : 0.0;
    final cycle = (_gait % 1.0) * 2 * math.pi;
    final dip = _landDip / 0.16;

    // Kalça yüksekliği: adımın ortasında hafif yükselip alçalır; sert inişte
    // dizler bükülür.
    var hipY =
        27.0 -
        math.cos(cycle * 2) * (0.6 + 0.8 * run) * amount +
        (amount == 0 ? math.sin(_anim * 2.2) * 0.3 : 0) +
        dip * 3.5;
    // Koşarken öne eğilir.
    var lean = run * 0.2;
    var lift = 2.4 + 2.2 * run;
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
      // Yarım döngü yerde geriye kayar (gövde ilerler), yarım döngü havada öne.
      final p = (phase % (2 * math.pi)) / (2 * math.pi);
      final stride = (5 + 4 * run) * amount;
      if (p < 0.5) {
        final t = p / 0.5;
        return Offset(cx + stride - 2 * stride * t, _artH - 0.5);
      }
      final t = (p - 0.5) / 0.5;
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
          // Asılı: gövde kenarın altında sallanır.
          final sway = math.sin(_anim * 2.5) * 1.2;
          hipY = 22;
          foot1 = Offset(cx + 1.5 + sway, 35.5);
          foot2 = Offset(cx - 1.5 + sway, 35);
        } else if (t < 0.6) {
          // Kollarla çekinir, dizler yukarı toplanır.
          hipY = 22;
          foot1 = Offset(cx + 3, 22 + 9 - t * 4);
          foot2 = Offset(cx - 2, 22 + 11 - t * 3);
          lean = 0.15;
        } else {
          // Dizini kenara atar ve doğrulur.
          final k = (t - 0.6) / 0.4;
          hipY = 22 + 5 * k;
          foot1 = Offset(cx + 3, 29 + 10.5 * k);
          foot2 = Offset(cx - 3, 31 + 8.5 * k);
          lean = 0.3 * (1 - k);
        }
      case PlayerState.swing:
        // İpte: eller başın üstünde, bacaklar salınımla savrulur.
        final kick = (_ropeOmega * 0.25).clamp(-0.6, 0.6);
        foot1 = Offset(cx + 2 + kick * 6, _artH - 2);
        foot2 = Offset(cx - 1 + kick * 4, _artH - 1);
        arm2 = math.pi - 0.15;
        jarAtHip = true;
        onRope = true;
      case PlayerState.vine:
        final p = math.sin(_runPhase * 2);
        foot1 = Offset(cx + 1.5, _artH - 3 + p * 3);
        foot2 = Offset(cx - 0.5, _artH - 3 - p * 3);
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
        if (!onGround) {
          final rising = velocity.y < 0;
          foot1 = Offset(cx + (rising ? 5 : 3), _artH - (rising ? 5 : 2));
          foot2 = Offset(cx - (rising ? 3 : 4), _artH - (rising ? 1 : 0));
          arm2 = rising ? -0.9 : -1.2;
          lean = 0.06;
        } else if (crouching) {
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
    }

    final hip = Offset(cx, hipY);
    final headY = hipY - 18.5;
    final shoulder = Offset(cx + lean * 6, hipY - 10);
    final head = Offset(cx + 1 + lean * 9, headY);

    // Kavanozu tutan kol öne uzanır; yürürken hafifçe sallanır.
    final jarArm = shielded
        ? 1.9
        : (jarAtHip
              ? (pushing ? 1.4 : math.pi - 0.15)
              : (sneaking ? 1.5 : 0.55 + math.sin(cycle) * 0.1 * amount));
    Offset limbEnd(Offset from, double angle, double len) =>
        from + Offset(math.sin(angle) * len, math.cos(angle) * len);
    jarHand = limbEnd(shoulder, jarArm, 9.5);
    if (onRope) {
      // El ele, ipe tutunarak tırmanır; sallanırken eller kıpırdamaz.
      final p = state == PlayerState.swing ? 0.0 : math.sin(_runPhase * 2);
      frontHand = Offset(cx + 0.8, shoulder.dy - 7 + p * 3);
      backHand = Offset(cx - 0.6, shoulder.dy - 3 - p * 3);
    }
    final swing = math.sin(_anim * 3 + cycle) * 0.12 * (0.3 + amount);
    final jar = jarAtHip
        ? hip.translate(5, -1)
        : (shielded
              ? jarHand.translate(-1.5, 1.5)
              : jarHand + Offset(math.sin(swing) * 4.5, math.cos(swing) * 4.5));
    final flicker = 0.85 + 0.15 * math.sin(_anim * 11) * math.sin(_anim * 3.7);
    final lightAmount = isDead ? 0.0 : (shielded ? 0.12 : 1.0) * flicker;

    if (lightAmount > 0) {
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

    void leg(Offset foot) {
      final knee = _knee(hip, foot, thigh, shin);
      _limb.strokeWidth = 4.4;
      canvas.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..lineTo(knee.dx, knee.dy)
          ..lineTo(foot.dx, foot.dy),
        _limb..strokeJoin = StrokeJoin.round,
      );
      // Küçük bot.
      canvas.drawOval(
        Rect.fromCenter(
          center: foot.translate(1.6, -0.6),
          width: 6.4,
          height: 3,
        ),
        _fill,
      );
    }

    // Arka kol ve arka bacak.
    _limb.strokeWidth = 3.2;
    final back = backHand ?? limbEnd(shoulder, arm2, 9.5);
    canvas.drawLine(shoulder, back, _limb);
    canvas.drawCircle(back, 1.9, _fill);
    leg(foot2);

    // İnce gövde; dizlere inen, arkası rüzgârla açılan uzun bir hırka.
    final wind = _speedFactor + (!onGround ? 0.4 : 0);
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

    if (hasWings) _drawWings(canvas, Offset(cx - 1 + lean * 6, hipY - 10));

    leg(foot1);

    // Baş: başı açık, dağınık saçlar rüzgârla arkaya yatar.
    canvas.drawCircle(head, 6.2, _fill);
    canvas.drawCircle(head + const Offset(5.6, 1.4), 1.4, _fill);
    // Saç tek parça: alnın üstünden tepeye, ardından arkaya yatan üç tutam.
    final b = wind * 2.4;
    double sw(int i) => math.sin(_anim * 5 + i * 1.4) * (0.25 + wind * 0.5);
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
        final x = neck.dx - 1 - k * len * (0.25 + sweep * 0.75) + tail;
        final y = neck.dy + 0.5 + k * len * (1 - sweep) * 0.9 + wave + tail;
        final half = 1.3 * (1 - k * 0.45);
        top.add(Offset(x, y - half));
        bottom.add(Offset(x, y + half));
      }
      final ribbon = Path()..addPolygon([...top, ...bottom.reversed], true);
      canvas.drawPath(ribbon, _fill);
    }

    // Kavanozu tutan ön kol ve ip.
    _limb.strokeWidth = 3.2;
    final front = frontHand ?? jarHand;
    canvas.drawLine(shoulder, front, _limb);
    canvas.drawCircle(front, 1.9, _fill);
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
