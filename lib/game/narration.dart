import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'golge_game.dart';
import 'palette.dart';
import 'strings.dart';

/// Hikâye katmanı: siyah ekranda akan sinematik satırlar, bölüm başlıkları,
/// oyun içi fısıltılar ve hatıra sayacı.
class Narration extends Component with HasGameReference<GolgeGame> {
  Narration() : super(priority: 20);

  static const _lineIn = 1.2;
  static const _lineHold = 2.8;
  static const _lineOut = 1.0;

  List<String> _lines = const [];
  int _lineIndex = 0;
  double _lineT = 0;
  double _backdrop = 0;
  VoidCallback? _onCinematicDone;

  String? _title;
  String _subtitle = '';
  double _titleT = 0;

  final _whispers = <String>[];
  String? _whisper;
  double _whisperT = 0;

  double _counterT = 99;
  double _fireflyT = 99;

  bool get inCinematic => _lines.isNotEmpty;

  void playCinematic(
    List<String> lines,
    VoidCallback onDone, {
    bool instantBlack = false,
  }) {
    _lines = lines;
    _lineIndex = 0;
    _lineT = 0;
    _backdrop = instantBlack ? 1 : 0;
    _onCinematicDone = onDone;
    _whisper = null;
    _title = null;
  }

  /// Satırı kapatmaya başla; zaten kapanıyorsa hemen sonrakine geç.
  void skip() {
    if (!inCinematic) return;
    final fadeOutStart = _lineIn + _lineHold;
    _lineT = _lineT < fadeOutStart
        ? fadeOutStart
        : fadeOutStart + _lineOut + 0.001;
  }

  void showTitle(String title, String subtitle) {
    _title = title;
    _subtitle = subtitle;
    _titleT = 0;
  }

  void whisper(String text) => _whispers.add(text);

  void pulseCounter() => _counterT = 0;

  void pulseFireflies() => _fireflyT = 0;

  double _whisperDuration(String s) => 3.0 + s.length * 0.045;

  @override
  void update(double dt) {
    if (inCinematic) {
      _backdrop = math.min(1, _backdrop + dt / 1.5);
      _lineT += dt;
      if (_lineT > _lineIn + _lineHold + _lineOut) {
        _lineT = 0;
        _lineIndex++;
        if (_lineIndex >= _lines.length) {
          _lines = const [];
          _backdrop = 0;
          final cb = _onCinematicDone;
          _onCinematicDone = null;
          cb?.call();
        }
      }
    }
    if (_title != null) {
      _titleT += dt;
      if (_titleT > 6) _title = null;
    }
    if (_whisper == null) {
      if (_whispers.isNotEmpty && !inCinematic) {
        _whisper = _whispers.removeAt(0);
        _whisperT = 0;
      }
    } else {
      _whisperT += dt;
      if (_whisperT > _whisperDuration(_whisper!)) _whisper = null;
    }
    _counterT += dt;
    _fireflyT += dt;
  }

  double _envelope(double t, double fadeIn, double hold, double fadeOut) {
    if (t < fadeIn) return t / fadeIn;
    if (t < fadeIn + hold) return 1;
    return (1 - (t - fadeIn - hold) / fadeOut).clamp(0.0, 1.0);
  }

  void _text(
    Canvas canvas,
    String s,
    Offset center,
    double fontSize,
    double alpha, {
    bool italic = false,
    double spacing = 0,
    double maxWidth = 900,
    Color color = kText,
  }) {
    if (alpha <= 0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: fontSize,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          fontWeight: FontWeight.w300,
          letterSpacing: spacing,
          height: 1.4,
          shadows: [
            Shadow(color: kInk.withValues(alpha: alpha * 0.9), blurRadius: 12),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void render(Canvas canvas) {
    final size = game.camera.viewport.size;
    final w = size.x;
    final h = size.y;
    final unit = math.min(h, w * 0.6);

    if (inCinematic) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = kInk.withValues(alpha: _backdrop),
      );
      final line = _lines[_lineIndex];
      final a = _envelope(_lineT, _lineIn, _lineHold, _lineOut);
      final isEnd = line == line.toUpperCase();
      _text(
        canvas,
        line,
        Offset(w / 2, h / 2),
        unit * (isEnd ? 0.05 : 0.036),
        a,
        italic: !isEnd,
        spacing: isEnd ? 10 : 0.5,
        maxWidth: w * 0.8,
      );
      _text(
        canvas,
        S.of('skipHint'),
        Offset(w - 90, h - 30),
        unit * 0.022,
        0.25,
      );
      return;
    }

    if (_title != null) {
      final a = _envelope(_titleT, 1.2, 3.0, 1.8);
      _text(
        canvas,
        _title!,
        Offset(w / 2, h * 0.36),
        unit * 0.07,
        a,
        spacing: 12,
      );
      _text(
        canvas,
        _subtitle,
        Offset(w / 2, h * 0.46),
        unit * 0.032,
        a * 0.8,
        italic: true,
      );
    }

    if (_whisper != null) {
      final a = _envelope(
        _whisperT,
        0.8,
        _whisperDuration(_whisper!) - 1.6,
        0.8,
      );
      _text(
        canvas,
        _whisper!,
        Offset(w / 2, h * 0.84),
        unit * 0.032,
        a,
        italic: true,
        maxWidth: w * 0.75,
      );
    }

    if (game.menuMode.value) return;

    // Kavanozdaki ateşböcekleri: sol üstte küçük ışıklar.
    final hudAlpha = 0.35 + 0.65 * (1 - (_fireflyT / 2.5).clamp(0.0, 1.0));
    for (var i = 0; i < GolgeGame.maxFireflies; i++) {
      final lit = i < game.fireflies;
      final c = Offset(34 + i * 18, 36);
      if (lit) {
        canvas.drawCircle(
          c,
          9,
          Paint()
            ..color = const Color(0xFFFFC46B).withValues(alpha: 0.35 * hudAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(
        c,
        lit ? 3.2 : 2.4,
        Paint()
          ..color = (lit ? const Color(0xFFFFE8B8) : kText).withValues(
            alpha: lit ? hudAlpha : 0.18,
          ),
      );
    }

    if (_counterT < 4.5 && game.memoryCount > 0) {
      final a = _envelope(_counterT, 0.4, 3.0, 1.1);
      _text(
        canvas,
        '${S.of('memoryCounter')}  ${game.memoryCount} / ${game.memoryTotal}',
        Offset(w - 100, 40),
        unit * 0.03,
        a,
        spacing: 2,
      );
    }
  }
}
