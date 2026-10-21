import 'package:flutter/material.dart';

import '../game/golge_game.dart';
import '../game/strings.dart';
import '../settings.dart';

/// Telefon ve tablet için ekran üstü kontroller.
///
/// Sol başparmak: ◀ ▶. Sağ başparmak: büyük zıplama; üstünde ↑ (tırman,
/// kol çek), solunda ↓ (çömel). Küçük düğmeler: ateşböceği ve parmak ucu
/// (mobilde basılı tutulmaz, açılıp kapanır).
class TouchControls extends StatefulWidget {
  const TouchControls({super.key, required this.controls});

  final Controls controls;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  // Parmak ucu durumu tek yerde, oyunun girdisinde tutulur.
  bool get _sneak => widget.controls.touch.sneak;

  @override
  void dispose() {
    // Kontroller kaldırılırken basılı kalan bir düğme oyuncuyu yürütmesin.
    widget.controls.touch.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Settings.touchGestures) {
      return _GestureControls(controls: widget.controls);
    }
    return Opacity(opacity: Settings.touchOpacity, child: _buttons(context));
  }

  Widget _buttons(BuildContext context) {
    final t = widget.controls.touch;
    final tr = !S.en;
    // Boyut ayarı bütün düğmeleri ve aralarını büyütür; sol elle oynamada
    // yönler sağa, eylemler sola geçer.
    final k = Settings.touchScale;
    final swap = Settings.leftHanded;
    Positioned at({
      required bool start,
      required double side,
      required double bottom,
      required Widget child,
    }) => start != swap
        ? Positioned(left: side * k, bottom: bottom * k, child: child)
        : Positioned(right: side * k, bottom: bottom * k, child: child);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Stack(
          children: [
            // Yön.
            at(
              start: true,
              side: 0,
              bottom: 0,
              child: Row(
                children: [
                  _Pad(
                    icon: Icons.chevron_left_rounded,
                    size: 84 * k,
                    onChanged: (v) => t.left = v,
                  ),
                  SizedBox(width: 16 * k),
                  _Pad(
                    icon: Icons.chevron_right_rounded,
                    size: 84 * k,
                    onChanged: (v) => t.right = v,
                  ),
                ],
              ),
            ),
            // Yönlerin üstünde: parmak ucu anahtarı.
            at(
              start: true,
              side: 4,
              bottom: 104,
              child: _Pad(
                icon: Icons.do_not_step,
                label: tr ? 'parmak ucu' : 'tiptoe',
                size: 52 * k,
                active: _sneak,
                onChanged: (v) {
                  if (!v) return;
                  setState(() => t.sneak = !t.sneak);
                },
              ),
            ),
            // Eylemler: zıpla, tırman, çömel, ateşböceği.
            at(
              start: false,
              side: 0,
              bottom: 0,
              child: SizedBox(
                width: 210 * k,
                height: 200 * k,
                child: Stack(
                  children: [
                    at(
                      start: false,
                      side: 0,
                      bottom: 0,
                      child: _Pad(
                        icon: Icons.arrow_upward_rounded,
                        label: tr ? 'zıpla' : 'jump',
                        size: 96 * k,
                        onChanged: (v) => t.jump = v,
                      ),
                    ),
                    at(
                      start: false,
                      side: 22,
                      bottom: 118,
                      child: _Pad(
                        icon: Icons.keyboard_double_arrow_up_rounded,
                        label: tr ? 'tırman' : 'climb',
                        size: 56 * k,
                        onChanged: (v) => t.up = v,
                      ),
                    ),
                    at(
                      start: false,
                      side: 112,
                      bottom: 8,
                      child: _Pad(
                        icon: Icons.keyboard_double_arrow_down_rounded,
                        label: tr ? 'çömel' : 'crouch',
                        size: 56 * k,
                        onChanged: (v) => t.down = v,
                      ),
                    ),
                    at(
                      start: false,
                      side: 112,
                      bottom: 100,
                      child: _Pad(
                        icon: Icons.auto_awesome,
                        label: tr ? 'ateşböceği' : 'firefly',
                        size: 56 * k,
                        onChanged: (v) {
                          if (v) widget.controls.queueLure();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pad extends StatefulWidget {
  const _Pad({
    required this.icon,
    required this.onChanged,
    this.size = 70,
    this.label,
    this.active = false,
  });

  final IconData icon;
  final double size;
  final String? label;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  State<_Pad> createState() => _PadState();
}

class _PadState extends State<_Pad> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    const warm = Color(0xFFE0A15F);
    final lit = _down || widget.active;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lit
                  ? warm.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: lit
                    ? warm.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.22),
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.icon,
              color: lit ? warm : Colors.white.withValues(alpha: 0.5),
              size: widget.size * 0.48,
            ),
          ),
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                widget.label!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================ Hareket modu

/// Düğmesiz kontrol (Limbo'nun mobil sürümü gibi): sol yarıda parmağı
/// sürükleyerek yürü (yukarı: tırman/kol, aşağı: çömel), sağ yarıya dokunarak
/// zıpla (basılı tut: yüksek zıplama, kanatla süzülme). Ateşböceği
/// köşedeki ✨ simgesiyle salınır. Köşelerde yalnızca iki küçük silik simge kalır.
class _GestureControls extends StatefulWidget {
  const _GestureControls({required this.controls});

  final Controls controls;

  @override
  State<_GestureControls> createState() => _GestureControlsState();
}

class _GestureControlsState extends State<_GestureControls> {
  static const _dead = 16.0;
  static const _vertical = 34.0;

  int? _stickPointer;
  Offset _origin = Offset.zero;
  Offset _knob = Offset.zero;
  final _jumpPointers = <int>{};
  double _hintAlpha = 1;

  Buttons get _t => widget.controls.touch;
  bool get _sneak => _t.sneak;

  @override
  void dispose() {
    _t.release();
    super.dispose();
  }

  void _down(PointerDownEvent e, double width) {
    // Sol elle oynamada yürüme sağ yarıda, zıplama sol yarıda.
    final left = (e.localPosition.dx < width / 2) != Settings.leftHanded;
    if (left && _stickPointer == null) {
      _stickPointer = e.pointer;
      _origin = _knob = e.localPosition;
    } else if (!left) {
      // Ateşböceği köşedeki simgeyle salınır: ikinci parmak (yürürken sağa
      // dokunmak gibi) yanlışlıkla ateşböceği harcamasın.
      _jumpPointers.add(e.pointer);
      _t.jump = true;
    }
    _fadeHints();
    setState(() {});
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _stickPointer) return;
    var d = e.localPosition - _origin;
    // Halka parmağı izler: çok uzaklaşınca merkez de kayar.
    const reach = 70.0;
    if (d.distance > reach) {
      _origin = e.localPosition - d / d.distance * reach;
      d = e.localPosition - _origin;
    }
    _knob = e.localPosition;
    _t
      ..left = d.dx < -_dead
      ..right = d.dx > _dead
      ..up = d.dy < -_vertical
      ..down = d.dy > _vertical;
    setState(() {});
  }

  void _up(PointerEvent e) {
    if (e.pointer == _stickPointer) {
      _stickPointer = null;
      _t
        ..left = false
        ..right = false
        ..up = false
        ..down = false;
    }
    _jumpPointers.remove(e.pointer);
    if (_jumpPointers.isEmpty) _t.jump = false;
    setState(() {});
  }

  void _fadeHints() {
    if (_hintAlpha > 0) _hintAlpha = 0;
  }

  @override
  Widget build(BuildContext context) {
    final alpha = Settings.touchOpacity;
    return LayoutBuilder(
      builder: (context, box) {
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) => _down(e, box.maxWidth),
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: _up,
                child: CustomPaint(
                  painter: _StickPainter(
                    active: _stickPointer != null,
                    origin: _origin,
                    knob: _knob,
                    alpha: alpha,
                  ),
                ),
              ),
            ),
            // İlk dokunuşa kadar görünen küçük ipuçları.
            Positioned(
              left: Settings.leftHanded ? null : 28,
              right: Settings.leftHanded ? 28 : null,
              bottom: 22,
              child: AnimatedOpacity(
                opacity: _hintAlpha * alpha,
                duration: const Duration(seconds: 2),
                child: _hint(Icons.swipe, S.of('hintMove')),
              ),
            ),
            Positioned(
              right: Settings.leftHanded ? null : 28,
              left: Settings.leftHanded ? 28 : null,
              bottom: 22,
              child: AnimatedOpacity(
                opacity: _hintAlpha * alpha,
                duration: const Duration(seconds: 2),
                child: _hint(Icons.touch_app_outlined, S.of('hintJump')),
              ),
            ),
            // Köşelerdeki iki küçük simge: parmak ucu ve ateşböceği.
            Positioned(
              left: 18,
              top: 62,
              child: _CornerButton(
                icon: Icons.do_not_step,
                active: _sneak,
                alpha: alpha,
                onTap: () {
                  setState(() => _t.sneak = !_t.sneak);
                },
              ),
            ),
            Positioned(
              right: 64,
              top: 10,
              child: _CornerButton(
                icon: Icons.auto_awesome,
                alpha: alpha,
                onTap: widget.controls.queueLure,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _hint(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.5)),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _StickPainter extends CustomPainter {
  _StickPainter({
    required this.active,
    required this.origin,
    required this.knob,
    required this.alpha,
  });

  final bool active;
  final Offset origin;
  final Offset knob;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    canvas.drawCircle(
      origin,
      52,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.25 * alpha),
    );
    canvas.drawCircle(
      knob,
      20,
      Paint()..color = const Color(0xFFE0A15F).withValues(alpha: 0.35 * alpha),
    );
  }

  @override
  bool shouldRepaint(_StickPainter old) =>
      old.active != active ||
      old.origin != origin ||
      old.knob != knob ||
      old.alpha != alpha;
}

class _CornerButton extends StatelessWidget {
  const _CornerButton({
    required this.icon,
    required this.onTap,
    required this.alpha,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double alpha;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const warm = Color(0xFFE0A15F);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTap(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? warm.withValues(alpha: 0.25 * alpha)
              : Colors.transparent,
          border: Border.all(
            color: (active ? warm : Colors.white).withValues(
              alpha: 0.3 * alpha,
            ),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: (active ? warm : Colors.white).withValues(alpha: 0.55 * alpha),
        ),
      ),
    );
  }
}
