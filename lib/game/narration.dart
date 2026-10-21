import 'dart:math' as math;
import 'dart:ui' as ui;

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

  /// Satır ekranda kalma süresi: uzun satırlar okunacak kadar kalır.
  double get _hold {
    if (_lines.isEmpty) return _lineHold;
    final line = _lines[_lineIndex.clamp(0, _lines.length - 1)];
    return math.max(_lineHold, line.length * 0.055);
  }

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

  /// Efsane varlığıyla ilk karşılaşma: adı, kim olduğu (tek cümle) ve
  /// Defter'e yazıldığı. Sırayla gösterilir; bölüm başlığı varken bekler.
  void showMyth(String name, String who) => _myths.add((name, who));

  final _myths = <(String, String)>[];
  (String, String)? _myth;
  double _mythT = 0;

  /// Şu an gösterilen efsane kartının adı (testler için).
  String? get debugMyth => _myth?.$1;

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
    _lineT = _lineIn + _hold;
  }

  /// Satırı kapatmaya başla; zaten kapanıyorsa hemen sonrakine geç.
  void skip() {
    if (!inCinematic) return;
    final fadeOutStart = _lineIn + _hold;
    _lineT = _lineT < fadeOutStart
        ? fadeOutStart
        : fadeOutStart + _lineOut + 0.001;
  }

  void showTitle(String title, String subtitle, [String place = '']) {
    _title = title;
    _subtitle = subtitle;
    _place = place;
    _titleT = 0;
    // Önceki bölümün alan adı yeni bölümün başında kalmasın.
    _area = null;
  }

  void whisper(String text) => _whispers.add(text);

  /// Sahne değişince (yeni bölüm, menü) eski bölümün bekleyen fısıltıları
  /// ve ipuçları atılır; yeni bölümde bağlamsız belirmesinler.
  void resetScene() {
    _myths.clear();
    _myth = null;
    _whispers.clear();
    _whisper = null;
    _hints.clear();
    _hint = null;
    _area = null;
  }

  /// Kullanım istemi: Sâye'nin başının üstünde küçük bir etiket; hikâye
  /// fısıltısıyla yarışmaz.
  /// Yer ipuçları sıraya girmez: ekran boşsa hemen gösterilir ve `true`
  /// döner; doluysa `false` (oyuncu hâlâ yakındaysa sonra yeniden denenir).
  /// Olay ipuçları ([queue]) sıraya girer.
  bool hint(String text, {bool queue = false}) {
    if (queue) {
      if (_hint != text && !_hints.contains(text)) _hints.add(text);
      return true;
    }
    if (!canHint) return false;
    _hint = text;
    _hintT = 0;
    return true;
  }

  /// Şu an yeni bir ipucu gösterilebilir mi?
  bool get canHint => _hint == null && _hints.isEmpty && !inCinematic;

  String? get debugWhisper => _whisper;
  String? get debugHint => _hint;

  /// Fısıltı üstte mi (Sâye ekranın alt yarısındayken)? Fısıltı boyunca
  /// sabit kalır, zıplamaz.
  bool _whisperTop = false;

  bool _playerLow() {
    final p = game.player;
    if (p == null || !p.isMounted) return false;
    final g = game.camera.localToGlobal(p.center);
    return g.y > game.camera.viewport.size.y * 0.5;
  }

  final _hints = <String>[];
  String? _hint;
  double _hintT = 0;
  double _hintDuration(String s) => 2.6 + s.length * 0.04;

  void pulseCounter() => _counterT = 0;

  void pulseFireflies() => _fireflyT = 0;

  double _whisperDuration(String s) => 3.5 + s.length * 0.06;

  @override
  void update(double dt) {
    if (inCinematic) {
      _backdrop = math.min(1, _backdrop + dt / 1.5);
      _lineT += dt;
      _sceneT += dt;
      if (_lineT > _lineIn + _hold + _lineOut) {
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
    if (_myth == null) {
      // Fısıltı sürerken beklenir: ikisi aynı yere düşmesin.
      if (_myths.isNotEmpty &&
          _title == null &&
          _whisper == null &&
          !inCinematic) {
        _myth = _myths.removeAt(0);
        _mythT = 0;
      }
    } else {
      _mythT += dt;
      if (_mythT > 6.5) _myth = null;
    }
    if (_whisper == null) {
      // Efsane kartı ekrandayken fısıltı bekler.
      if (_whispers.isNotEmpty && _myth == null && !inCinematic) {
        _whisper = _whispers.removeAt(0);
        _whisperT = 0;
        _whisperTop = _playerLow();
      }
    } else {
      _whisperT += dt;
      if (_whisperT > _whisperDuration(_whisper!)) _whisper = null;
    }
    if (_hint == null) {
      if (_hints.isNotEmpty && !inCinematic && !game.menuMode.value) {
        _hint = _hints.removeAt(0);
        _hintT = 0;
      }
    } else {
      _hintT += dt;
      if (_hintT > _hintDuration(_hint!)) _hint = null;
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
      if (_cache.length > 120) _clearCache();
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

  /// Önbellek boşaltılırken dizilmiş metinlerin yerel kaynakları da bırakılır.
  void _clearCache() {
    for (final tp in _cache.values) {
      tp.dispose();
    }
    _cache.clear();
  }

  /// İstem etiketi: sol üst köşede, koyu zemin, ılık kenar.
  void _prompt(
    Canvas canvas,
    String s,
    double w,
    double h,
    double unit,
    double alpha, {
    required bool top,
  }) {
    if (alpha <= 0) return;
    final a = (alpha * 20).round() / 20;
    // Küçük ve sakin: hikâyenin önüne geçmez.
    final size = math.max(10.5, unit * 0.019);
    final key = 'istem|$s|$size|$a';
    final tp = _cache[key] ??= _layout(
      s,
      size,
      a,
      false,
      0.4,
      w * 0.56,
      const Color(0xFFFFE9C4),
      false,
    );
    // Ortada, iki başparmağın arasında (dokunmatikte sol yarı yürüme, sağ
    // yarı zıplama); fısıltının karşı tarafında: fısıltı üstteyse altta,
    // alttaysa üstte (yer adının altında).
    final bw = tp.width + 20;
    final bh = tp.height + 8;
    final left = (w - bw) / 2;
    final y = top ? h * 0.115 : h - bh - math.max(12.0, h * 0.035);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, y, bw, bh),
      Radius.circular(math.min(bh / 2, 14)),
    );
    canvas.drawRRect(
      box,
      Paint()..color = const Color(0xFF140C09).withValues(alpha: 0.7 * a),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFE0A15F).withValues(alpha: 0.4 * a),
    );
    tp.paint(canvas, Offset(left + 10, y + 4));
  }

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
          fontFamily: 'Roboto',
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
      final a = _envelope(_lineT, _lineIn, _hold, _lineOut);
      final isEnd = line == line.toUpperCase();
      final scene = _scene;
      if (scene != null) {
        // Perde: satırlar altında, son satır (başlık) perdenin üstüne düşen
        // bir gölge yazı olarak.
        final progress = _lineIndex + (_lineT / (_lineIn + _hold + _lineOut));
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
          S.upper(_place),
          Offset(w / 2, h * 0.53),
          unit * 0.02,
          a * 0.55,
          spacing: 4,
        );
      }
    }

    // Efsane kartı: adı büyük, altında kim olduğu, en altta Defter notu.
    final myth = _myth;
    if (myth != null) {
      final a = _envelope(_mythT, 1.0, 4.2, 1.3);
      // Okunurluk: arkada yumuşak, koyu bir şerit (parlak ağacın önünde de).
      if (a > 0) {
        final band = Rect.fromLTWH(0, h * 0.2, w, h * 0.24);
        canvas.drawRect(
          band,
          Paint()
            ..shader = ui.Gradient.linear(
              band.topCenter,
              band.bottomCenter,
              [
                const Color(0x00000000),
                Color.fromRGBO(6, 3, 2, 0.55 * a),
                Color.fromRGBO(6, 3, 2, 0.55 * a),
                const Color(0x00000000),
              ],
              const [0, 0.3, 0.7, 1],
            ),
        );
      }
      _text(
        canvas,
        S.upper(myth.$1),
        Offset(w / 2, h * 0.27),
        unit * 0.046,
        a,
        spacing: 9,
      );
      _text(
        canvas,
        myth.$2,
        Offset(w / 2, h * 0.335),
        unit * 0.025,
        a * 0.85,
        italic: true,
        maxWidth: w * 0.7,
      );
      _text(
        canvas,
        S.upper(S.of('mythNoted')),
        Offset(w / 2, h * 0.39),
        unit * 0.016,
        a * 0.5,
        spacing: 4,
      );
    }

    // Yer adı: üstte, ince ve geniş aralıklı; başlık varken gösterilmez.
    if (_area != null && _title == null) {
      final a = _envelope(_areaT, 1.0, 2.6, 1.4);
      _text(
        canvas,
        '—  ${_area!}  —',
        Offset(w / 2, h * 0.07),
        unit * 0.022,
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
      // Sâye'nin olmadığı yarıda: o alttaysa yazı üstte, üstteyse altta.
      final y = _whisperTop ? h * 0.17 : h * 0.86;
      // Okunurluk için yumuşak, koyu bir şerit.
      if (a > 0) {
        final band = Rect.fromLTWH(0, y - h * 0.08, w, h * 0.16);
        canvas.drawRect(
          band,
          Paint()
            ..shader = ui.Gradient.linear(
              band.topCenter,
              band.bottomCenter,
              [
                const Color(0x00050302),
                const Color(0xFF050302).withValues(alpha: 0.6 * a),
                const Color(0x00050302),
              ],
              const [0, 0.5, 1],
            ),
        );
      }
      _text(
        canvas,
        _whisper!,
        Offset(w / 2, y),
        unit * 0.028,
        a,
        italic: true,
        maxWidth: w * 0.6,
      );
    }

    if (game.menuMode.value) return;

    if (_hint != null && !inCinematic) {
      final a = _envelope(_hintT, 0.3, _hintDuration(_hint!) - 0.9, 0.6);
      // Fısıltı varsa onun karşı tarafında; yoksa Sâye'nin olmadığı yarıda.
      // Efsane kartı üstteyken ipucu altta.
      final top = _whisper != null
          ? !_whisperTop
          : _myth != null
          ? false
          : _playerLow();
      _prompt(canvas, _hint!, w, h, unit, a, top: top);
    }

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
        unit * 0.024,
        a,
        spacing: 2,
      );
    }
  }
}
