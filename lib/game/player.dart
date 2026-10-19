import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';

enum PlayerState { normal, hang, climbUp, vine, dead }

class Player extends PositionComponent with HasGameReference<GolgeGame> {
  Player(Vector2 start)
    : super(position: start, size: Vector2(w, h), priority: 20);

  static const double w = 18;
  static const double h = 40;
  static const double runSpeed = 185;
  static const double sneakSpeed = 70;
  static const double jumpVelocity = 600;
  static const double gravity = 1900;
  static const double maxFall = 900;
  static const double climbSpeed = 115;

  final velocity = Vector2.zero();
  PlayerState state = PlayerState.normal;
  int facing = 1;
  bool onGround = false;
  bool crouching = false;
  bool inShadow = false;
  bool hidden = false;

  double _coyote = 0;
  double _jumpBuffer = 0;
  double _grabCooldown = 0;
  double _dropThrough = 0;
  double _stateTime = 0;
  double _anim = 0;
  double _runPhase = 0;
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

    final c = game.controls;
    final active = !game.cinematic && !isDead;
    final left = active && c.left;
    final right = active && c.right;
    final up = active && c.up;
    final down = active && c.down;
    final jump = active && c.jump;
    final dir = (right ? 1 : 0) - (left ? 1 : 0);
    final jumpPressed = jump && !_prevJump;
    final upPressed = up && !_prevUp;
    _prevJump = jump;
    _prevUp = up;
    _jumpBuffer = jumpPressed ? 0.12 : _jumpBuffer - dt;
    _grabCooldown -= dt;
    _dropThrough -= dt;

    switch (state) {
      case PlayerState.normal:
        _updateNormal(dt, dir, up, down, jump);
      case PlayerState.hang:
        _updateHang(dir, up, down, jumpPressed, upPressed);
      case PlayerState.climbUp:
        _updateClimbUp();
      case PlayerState.vine:
        _updateVine(dt, dir, up, down, jumpPressed);
      case PlayerState.dead:
        _updateDead(dt);
    }

    if (!isDead) _checkHazards();
    inShadow = level.rectHits(
      position.x + 3,
      position.y + 8,
      position.x + w - 3,
      position.y + h - 1,
      (ch) => ch == '~' || ch == 'I',
    );
    hidden =
        inShadow &&
        state == PlayerState.normal &&
        onGround &&
        (crouching || velocity.x.abs() < 25);
  }

  // ---------------------------------------------------------------- hareket

  void _updateNormal(double dt, int dir, bool up, bool down, bool jump) {
    crouching = onGround && down;
    final target = dir * (crouching ? sneakSpeed : runSpeed);
    final accel = onGround ? (dir == 0 ? 2200.0 : 1500.0) : 1000.0;
    velocity.x = _approach(velocity.x, target, accel * dt);
    if (dir != 0) facing = dir;
    _runPhase += velocity.x.abs() * dt * 0.075;

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
      }
      onGround = false;
    }
    if (!_jumpCut && !jump && velocity.y < 0) {
      velocity.y *= 0.45;
      _jumpCut = true;
    }
    if (velocity.y >= 0) _jumpCut = true;

    velocity.y = math.min(velocity.y + gravity * dt, maxFall);
    _moveX(velocity.x * dt);
    _moveY(velocity.y * dt, allowOneWay: _dropThrough <= 0);

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

  void _moveX(double dx) {
    if (dx == 0) return;
    position.x += dx;
    final r0 = ((position.y + 1) / kTile).floor();
    final r1 = ((position.y + h - 1) / kTile).floor();
    final c = dx > 0
        ? ((position.x + w - 0.001) / kTile).floor()
        : (position.x / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      if (!level.solid(c, r)) continue;
      position.x = dx > 0 ? c * kTile - w : (c + 1) * kTile;
      velocity.x = 0;
      return;
    }
  }

  void _moveY(double dy, {bool allowOneWay = true}) {
    final prevBottom = position.y + h;
    position.y += dy;
    onGround = false;
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
        r * kTile + 4,
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

  void die({bool fell = false}) {
    if (isDead) return;
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
    if (!_deathReported && _stateTime > (_fell ? 0.1 : 0.6)) {
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
  static final _glow = Paint()
    ..color = kLight.withValues(alpha: 0.55)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  /// Geliştirici modunda V ile değişir: gözleri parlayan çocuk ya da
  /// ateşböceği kavanozlu çocuk.
  static bool jarStyle = true;

  @override
  void render(Canvas canvas) =>
      jarStyle ? _renderJar(canvas) : _renderEyes(canvas);

  void _renderEyes(Canvas canvas) {
    canvas.save();
    const cx = w / 2;
    if (facing < 0) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    if (isDead && !_fell) {
      canvas.translate(cx, h);
      canvas.rotate(math.min(_stateTime * 5, 1) * math.pi / 2);
      canvas.translate(-cx, -h);
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
      case PlayerState.vine:
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
        canvas.drawCircle(e1, 3, _glow);
        canvas.drawCircle(e2, 2.6, _glow);
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

  void _renderJar(Canvas canvas) {
    canvas.save();
    const cx = w / 2;
    if (facing < 0) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    if (isDead && !_fell) {
      canvas.translate(cx, h);
      canvas.rotate(math.min(_stateTime * 5, 1) * math.pi / 2);
      canvas.translate(-cx, -h);
    }

    final moving =
        state == PlayerState.normal && onGround && velocity.x.abs() > 20;
    final bob = moving
        ? math.sin(_runPhase * 2).abs() * -1.2
        : math.sin(_anim * 2.4) * 0.4;
    var headY = 9.0 + bob;
    var hipY = 28.0 + bob * 0.5;
    var legLen = 12.0;
    double leg1;
    double leg2;
    double arm1;
    double arm2;
    var jarAtHip = false;

    switch (state) {
      case PlayerState.hang:
      case PlayerState.climbUp:
        final sway = math.sin(_anim * 2.5) * 0.12;
        leg1 = sway + 0.12;
        leg2 = sway - 0.15;
        arm1 = math.pi - 0.15;
        arm2 = math.pi - 0.35;
        jarAtHip = true;
      case PlayerState.vine:
        final p = math.sin(_runPhase * 2);
        leg1 = 0.3 + p * 0.3;
        leg2 = 0.3 - p * 0.3;
        arm1 = math.pi - 0.3 + p * 0.3;
        arm2 = math.pi - 0.3 - p * 0.3;
        jarAtHip = true;
      case PlayerState.dead:
        leg1 = 0.15;
        leg2 = -0.15;
        arm1 = 0.9;
        arm2 = -0.3;
      case PlayerState.normal:
        if (!onGround) {
          final rising = velocity.y < 0;
          leg1 = rising ? 0.75 : 0.35;
          leg2 = rising ? -0.25 : -0.4;
          arm1 = rising ? 1.5 : 1.2;
          arm2 = rising ? -1.0 : -1.3;
        } else if (crouching) {
          headY += 7;
          hipY = 31;
          legLen = 9.5;
          final s =
              math.sin(_runPhase) * 0.45 * math.min(1, velocity.x.abs() / 40);
          leg1 = 1.0 + s;
          leg2 = -0.35 - s;
          arm1 = 0.9;
          arm2 = 0.5;
        } else {
          final amount = math.min(1.0, velocity.x.abs() / 80);
          final s = math.sin(_runPhase) * 0.6 * amount;
          leg1 = s;
          leg2 = -s;
          // Kavanozlu el öne uzanır, daha az sallanır.
          arm1 = 0.55 + s * 0.25;
          arm2 = s * 0.9 - 0.05;
        }
    }
    if (hidden) {
      // Kavanozu göğsüne bastırıp örter.
      arm1 = 1.9;
    }

    final shoulder = Offset(cx, headY + 8);
    final hip = Offset(cx, hipY);
    Offset limbEnd(Offset from, double angle, double len) =>
        from + Offset(math.sin(angle) * len, math.cos(angle) * len);

    final hand = limbEnd(shoulder, arm1, 10);
    final jar = jarAtHip
        ? hip.translate(5, -1)
        : (hidden ? hand.translate(-1.5, 1.5) : hand.translate(0.5, 4.5));
    final flicker = 0.85 + 0.15 * math.sin(_anim * 11) * math.sin(_anim * 3.7);
    final lightAmount = isDead ? 0.0 : (hidden ? 0.12 : 1.0) * flicker;

    // Kavanozun etrafa saçtığı ışık (silüetin arkasında).
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

    _limb.strokeWidth = 3.3;
    canvas.drawLine(shoulder, limbEnd(shoulder, arm2, 10), _limb);
    _limb.strokeWidth = 4.4;
    canvas.drawLine(hip, limbEnd(hip, leg2, legLen), _limb);

    // Kalın paltolu gövde.
    _limb.strokeWidth = 10;
    canvas.drawLine(Offset(cx, headY + 7), hip.translate(0, -1.5), _limb);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 5.5, hipY - 6)
        ..lineTo(cx + 5.5, hipY - 6)
        ..lineTo(cx + 6.5, hipY + 2)
        ..lineTo(cx - 6, hipY + 2)
        ..close(),
      _fill,
    );

    _limb.strokeWidth = 4.4;
    canvas.drawLine(hip, limbEnd(hip, leg1, legLen), _limb);

    // Baş ve örgü bere.
    final head = Offset(cx + 1, headY);
    canvas.drawCircle(head, 7, _fill);
    canvas.drawCircle(head + const Offset(6.4, 1.6), 1.6, _fill);
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - 7.6, head.dy - 0.5)
        ..cubicTo(
          head.dx - 8.5,
          head.dy - 11,
          head.dx + 7.5,
          head.dy - 12,
          head.dx + 7.6,
          head.dy - 2,
        )
        ..close(),
      _fill,
    );
    final pompom =
        head +
        Offset(
          -6.5 - _speedFactor * 1.5,
          -9 + math.sin(_anim * 5) * 0.4 * _speedFactor,
        );
    canvas.drawCircle(pompom, 2.7, _fill);

    // Atkının arkaya savrulan ucu.
    final wind = _speedFactor + (!onGround ? 0.4 : 0);
    final neck = Offset(cx - 1, headY + 7.5);
    canvas.drawPath(
      Path()
        ..moveTo(neck.dx, neck.dy - 1.5)
        ..quadraticBezierTo(
          neck.dx - 5,
          neck.dy + 1 - wind * 3,
          neck.dx - 8 - wind * 3,
          neck.dy + 4 - wind * 4 + math.sin(_anim * 9) * wind,
        )
        ..lineTo(neck.dx - 7 - wind * 3, neck.dy + 6 - wind * 4)
        ..quadraticBezierTo(neck.dx - 4, neck.dy + 3, neck.dx, neck.dy + 1.5)
        ..close(),
      _fill,
    );

    _limb.strokeWidth = 3.3;
    canvas.drawLine(
      shoulder,
      jarAtHip ? limbEnd(shoulder, arm1, 10) : hand,
      _limb,
    );

    _drawJar(canvas, jar, lightAmount);

    // Kavanozun ışığı silüetin ön yüzüne vurur.
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
      canvas.drawCircle(
        c,
        5,
        Paint()
          ..color = _jarLight.withValues(alpha: 0.5 * light)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
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
}
