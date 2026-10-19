import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'palette.dart';
import 'perde.dart';
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

  /// Satırların altında oynayan perde sahnesi (yoksa siyah ekran).
  PerdeScene? _scene;
  double _sceneT = 0;

  String? _title;
  String _subtitle = '';
  String _place = '';

  /// Bölümün içinde yeni bir yere girince üstte beliren ad.
  String? _area;
  double _areaT = 0;

  void showArea(String name) {
    _area = name;
    _areaT = 0;
  }

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
    PerdeScene? scene,
  }) {
    _lines = lines;
    _scene = lines.isEmpty ? null : scene;
    _sceneT = 0;
    GameAudio.instance.perde(_scene != null);
    _lineIndex = 0;
    _lineT = 0;
    _backdrop = instantBlack ? 1 : 0;
    _onCinematicDone = onDone;
    _whisper = null;
    _title = null;
  }

  /// Sahnenin tamamını atlar (Esc).
  void skipAll() {
    if (!inCinematic) return;
    _lineIndex = _lines.length - 1;
    _lineT = _lineIn + _lineHold;
  }

  /// Satırı kapatmaya başla; zaten kapanıyorsa hemen sonrakine geç.
  void skip() {
    if (!inCinematic) return;
    final fadeOutStart = _lineIn + _lineHold;
    _lineT = _lineT < fadeOutStart
        ? fadeOutStart
        : fadeOutStart + _lineOut + 0.001;
  }

  void showTitle(String title, String subtitle, [String place = '']) {
    _title = title;
    _subtitle = subtitle;
    _place = place;
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
      _sceneT += dt;
      if (_lineT > _lineIn + _lineHold + _lineOut) {
        _lineT = 0;
        _lineIndex++;
        if (_lineIndex >= _lines.length) {
          _lines = const [];
          _backdrop = 0;
          if (_scene != null) GameAudio.instance.perde(false);
          _scene = null;
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
    if (_area != null) {
      _areaT += dt;
      if (_areaT > 5) _area = null;
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
    bool shadow = true,
  }) {
    if (alpha <= 0) return;
    // Dizilmiş yazılar önbellekte: saydamlık 20 basamağa yuvarlanır, böylece
    // solma sırasında bile her karede yeniden dizilmez.
    final a = (alpha * 20).round() / 20;
    if (a <= 0) return;
    final key =
        '$s|$fontSize|$italic|$spacing|$maxWidth|${color.toARGB32()}|$a|$shadow';
    var tp = _cache[key];
    if (tp == null) {
      if (_cache.length > 120) _cache.clear();
      tp = _cache[key] = _layout(
        s,
        fontSize,
        a,
        italic,
        spacing,
        maxWidth,
        color,
        shadow,
      );
    }
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  final _cache = <String, TextPainter>{};

  TextPainter _layout(
    String s,
    double fontSize,
    double alpha,
    bool italic,
    double spacing,
    double maxWidth,
    Color color,
    bool shadow,
  ) {
    return TextPainter(
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
            if (shadow)
              Shadow(
                color: kInk.withValues(alpha: alpha * 0.85),
                offset: const Offset(1.2, 1.5),
              ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
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
      final scene = _scene;
      if (scene != null) {
        // Perde: satırlar altında, son satır (başlık) perdenin üstüne düşen
        // bir gölge yazı olarak.
        final progress =
            _lineIndex + (_lineT / (_lineIn + _lineHold + _lineOut));
        PerdePainter.paint(
          canvas,
          Size(w, h),
          scene,
          _sceneT,
          progress,
          _backdrop,
        );
        final r = PerdePainter.screenRect(Size(w, h));
        if (isEnd) {
          _text(
            canvas,
            line,
            r.center.translate(0, -r.height * 0.18),
            r.height * 0.1,
            a,
            spacing: 10,
            maxWidth: r.width,
            color: const Color(0xFF1A0B05),
            shadow: false,
          );
        } else {
          _text(
            canvas,
            line,
            Offset(w / 2, (r.bottom + h) / 2 + r.height * 0.02),
            unit * 0.034,
            a,
            italic: true,
            spacing: 0.5,
            maxWidth: w * 0.8,
          );
        }
      } else {
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
      }
      _text(
        canvas,
        S.of('skipHint'),
        Offset(w - 130, h - 30),
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
      if (_place.isNotEmpty) {
        _text(
          canvas,
          _place.toUpperCase(),
          Offset(w / 2, h * 0.53),
          unit * 0.02,
          a * 0.55,
          spacing: 4,
        );
      }
    }

    // Yer adı: üstte, ince ve geniş aralıklı; başlık varken gösterilmez.
    if (_area != null && _title == null) {
      final a = _envelope(_areaT, 1.0, 2.6, 1.4);
      _text(
        canvas,
        '—  ${_area!}  —',
        Offset(w / 2, h * 0.1),
        unit * 0.026,
        a * 0.8,
        italic: true,
        spacing: 2,
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
        glowDot(canvas, c, 12, const Color(0xFFFFC46B), 0.4 * hudAlpha);
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
