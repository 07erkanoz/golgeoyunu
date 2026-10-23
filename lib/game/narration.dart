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
  /// Defter'e yazıldığı. Karşılaşma anında gösterilir (yalnız bölüm başlığı
  /// ve perde varken bekler); hikâye fısıltısını beklemez, kesmez: ikisi
  /// ayrı şeritlerde durur.
  void showMyth(String name, String who) => _myths.add((name, who));

  final _myths = <(String, String)>[];
  (String, String)? _myth;
  double _mythT = 0;
  double _mythLen = 6.5;

  /// Kart bir kat aşağıda mı (üst şeritte hikâye satırı varken açıldı).
  bool _mythLow = false;

  /// Şu an gösterilen efsane kartının adı (testler için).
  String? get debugMyth => _myth?.$1;

  void showArea(String name) {
    _remember(RecentKind.place, name);
    _area = name;
    _areaT = 0;
  }

  double _titleT = 0;

  /// Bekleyen fısıltılar ve sıraya girdikleri an.
  final _whispers = <(String, double)>[];
  String? _whisper;
  double _whisperT = 0;

  /// Ekrandaki fısıltının süresi (sırada bekleyen varsa kısalır).
  double _whisperLen = 0;

  /// Anlatımın kendi saati (sıradakinin ne kadar beklediğini ölçer).
  double _clock = 0;

  /// Bu kadar bekleyen satır ekrana gelmez: o yer çoktan geçildi; "Az önce"
  /// panelinde okunur. Art arda gelen üç dört hikâye satırı düşmesin diye
  /// geniş tutulur (sırada bekleyen varken satırlar zaten kısalır).
  static const double staleAfter = 25;

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

  /// Az önce ekrana gelenler (en yenisi sonda): okumayı kaçıran "i"
  /// düğmesinden yeniden okur. Bölüm değişince temizlenir.
  final recent = <RecentLine>[];

  /// İpucunun somut çözümü: "Az önce" panelinde katlı durur, istenince
  /// açılır (ekrana yazılmaz).
  void rememberSolution(String text) => _remember(RecentKind.solution, text);

  void _remember(RecentKind kind, String text) {
    if (text.trim().isEmpty) return;
    if (recent.isNotEmpty &&
        recent.last.text == text &&
        recent.last.kind == kind) {
      return;
    }
    recent.add(RecentLine(kind, text));
    if (recent.length > 24) recent.removeAt(0);
  }

  void showTitle(String title, String subtitle, [String place = '']) {
    recent.clear();
    _remember(RecentKind.title, '$title\n$subtitle');
    _title = title;
    _subtitle = subtitle;
    _place = place;
    _titleT = 0;
    // Önceki bölümün alan adı yeni bölümün başında kalmasın.
    _area = null;
  }

  void whisper(String text) => _whispers.add((text, _clock));

  /// Çok adımlı bir düzeneğin o anki adımı (yoksa null); her karede oyun
  /// belirler. Sol üstte küçük, kalıcı bir satır olarak yazılır.
  String? objective;
  TextPainter? _goalTp;
  String? _goalText;

  void _objectiveLine(Canvas canvas, String s, double unit) {
    if (s != _goalText) {
      _goalText = s;
      _goalTp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: kText.withValues(alpha: 0.9),
            fontSize: math.max(12, unit * 0.022),
            height: 1.3,
            shadows: const [Shadow(blurRadius: 6, color: Color(0xFF000000))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(240, game.size.x * 0.45));
    }
    final tp = _goalTp!;
    const left = 24.0;
    const top = 54.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 10, top - 6, tp.width + 20, tp.height + 12),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0x8C0A0605),
    );
    canvas.drawRect(
      Rect.fromLTWH(left - 10, top - 6, 3, tp.height + 12),
      Paint()..color = const Color(0xFFE0A15F),
    );
    tp.paint(canvas, const Offset(left, top));
  }

  /// Sahne değişince (yeni bölüm, menü) eski bölümün bekleyen fısıltıları
  /// ve ipuçları atılır; yeni bölümde bağlamsız belirmesinler.
  void resetScene() {
    objective = null;
    recent.clear();
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
    _remember(RecentKind.hint, text);
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

  /// Sırada bekleyen varken: okunacak kadar.
  double _busyDuration(String s) => 2.4 + s.length * 0.04;

  @override
  void update(double dt) {
    _clock += dt;
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
      if (_myths.isNotEmpty && _title == null && !inCinematic) {
        _myth = _myths.removeAt(0);
        _remember(RecentKind.legend, '${_myth!.$1}\n${_myth!.$2}');
        _mythT = 0;
        // Arka arkaya kart bekliyorsa her biri okunacak kadar kalır.
        _mythLen = _myths.isEmpty ? 6.5 : 4.5;
        _mythLow = _whisper != null && _whisperTop;
      }
    } else {
      _mythT += dt;
      if (_mythT > _mythLen) _myth = null;
    }
    if (_whisper == null) {
      // Çok bekleyen satırlar ekrana gelmez (yer geçildi), panele düşer.
      while (_whispers.isNotEmpty &&
          _clock - _whispers.first.$2 > staleAfter &&
          !inCinematic) {
        _remember(RecentKind.story, _whispers.removeAt(0).$1);
      }
      if (_whispers.isNotEmpty && !inCinematic) {
        _whisper = _whispers.removeAt(0).$1;
        _remember(RecentKind.story, _whisper!);
        _whisperT = 0;
        _whisperLen = _whisperDuration(_whisper!);
        // Efsane kartı üst ortadayken hikâye satırı alt şeride iner.
        _whisperTop = _playerLow() && _myth == null && _myths.isEmpty;
      }
    } else {
      _whisperT += dt;
      // Sırada bekleyen varsa bu satır okunacak kadar kalır; kapanışı yarım
      // kesilmez.
      if (_whispers.isNotEmpty) {
        _whisperLen = math.min(
          _whisperLen,
          math.max(_busyDuration(_whisper!), _whisperT + 0.8),
        );
      }
      if (_whisperT > _whisperLen) _whisper = null;
    }
    if (_hint == null) {
      if (_hints.isNotEmpty && !inCinematic && !game.menuMode.value) {
        _hint = _hints.removeAt(0);
        _remember(RecentKind.hint, _hint!);
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
          // Perdenin adı perdeye bir göstermelik olarak konur.
          PerdePainter.gostermelik(canvas, r, line, _sceneT, a);
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
      final a = _envelope(_mythT, 1.0, _mythLen - 2.3, 1.3);
      // Üstte hikâye satırı varsa kart onun altına iner.
      final dy = _mythLow ? h * 0.12 : 0.0;
      // Okunurluk: arkada yumuşak, koyu bir şerit (parlak ağacın önünde de).
      if (a > 0) {
        final band = Rect.fromLTWH(0, h * 0.2 + dy, w, h * 0.24);
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
        Offset(w / 2, h * 0.27 + dy),
        unit * 0.046,
        a,
        spacing: 9,
      );
      _text(
        canvas,
        myth.$2,
        Offset(w / 2, h * 0.335 + dy),
        unit * 0.025,
        a * 0.85,
        italic: true,
        maxWidth: w * 0.7,
      );
      _text(
        canvas,
        S.upper(S.of('mythNoted')),
        Offset(w / 2, h * 0.39 + dy),
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
      final a = _envelope(_whisperT, 0.8, _whisperLen - 1.6, 0.8);
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

    if (game.perfShown && game.perfText.isNotEmpty) {
      _text(
        canvas,
        game.perfText,
        Offset(w / 2, h * 0.035),
        unit * 0.018,
        0.9,
        maxWidth: w * 0.9,
      );
    }

    if (game.menuMode.value) return;

    // Görev satırı: çok adımlı düzenekte o anki adım (sol üstte, kalıcı).
    final goal = objective;
    if (goal != null && !inCinematic) _objectiveLine(canvas, goal, unit);

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

/// Az önce ekrana gelen bir yazının türü.
enum RecentKind { title, place, story, hint, legend, solution }

class RecentLine {
  const RecentLine(this.kind, this.text);
  final RecentKind kind;
  final String text;
}
