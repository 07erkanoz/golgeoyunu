import 'package:flutter/material.dart';

import '../game/golge_game.dart';

/// Mobil için ekran üstü düğmeler: solda yön, sağda yukarı/aşağı ve zıpla.
class TouchControls extends StatelessWidget {
  const TouchControls({super.key, required this.controls});

  final Controls controls;

  @override
  Widget build(BuildContext context) {
    final t = controls.touch;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Pad(icon: Icons.chevron_left, onChanged: (v) => t.left = v),
            const SizedBox(width: 14),
            _Pad(icon: Icons.chevron_right, onChanged: (v) => t.right = v),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Pad(icon: Icons.keyboard_arrow_up, size: 54, onChanged: (v) => t.up = v),
                const SizedBox(height: 10),
                _Pad(icon: Icons.keyboard_arrow_down, size: 54, onChanged: (v) => t.down = v),
              ],
            ),
            const SizedBox(width: 16),
            _Pad(icon: Icons.circle_outlined, size: 84, onChanged: (v) => t.jump = v),
          ],
        ),
      ),
    );
  }
}

class _Pad extends StatefulWidget {
  const _Pad({required this.icon, required this.onChanged, this.size = 70});

  final IconData icon;
  final double size;
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
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: _down ? 0.18 : 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Icon(widget.icon, color: Colors.white.withValues(alpha: 0.5), size: widget.size * 0.5),
      ),
    );
  }
}
