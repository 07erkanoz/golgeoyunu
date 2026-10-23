import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../settings.dart';
import 'audio.dart';
import 'golge_game.dart';
import 'palette.dart';
import 'perde.dart';
import 'strings.dart';

/// Hikâye katmanı: siyah ekranda akan sinematik satırlar, bölüm başlıkları,
/// oyun içi fısıltılar ve hatıra sayacı.
///
/// Oyun içinde her yazının sabit bir yeri vardır, hiçbiri yer değiştirmez
/// ve birbirinin üstüne binmez: yer adı en üstte, ipucu hemen altında,
/// efsane kartı ortada, hikâye fısıltısı en altta.
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
  /// ayrı şeritlerde durur (kart ortada, fısıltı altta).
  void showMyth(String name, String who) => _myths.add((name, who));

  final _myths = <(String, String)>[];
  (String, String)? _myth;
  double _mythT = 0;
  double _mythLen = 6.5;

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

  /// Alt yazı gibi akış: yeni fısıltı beklemeden en alta gelir, önceki bir
  /// satır yukarı kayıp okunmayı sürdürür. En çok iki satır görünür.
  String? _prev;
  double _prevT = 0;
  double _prevLen = 0;

  /// Önceki satırın yukarı kayışı (0 → 1).
  double _shift = 1;

  /// Yeni satır gelmeden önce alttaki satırın en az görünme süresi.
  static const double _minShow = 1.0;

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
    _prev = null;
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
    _prev = null;
    _hints.clear();
    _hint = null;
    _pending = null;
    _area = null;
  }

  /// Kullanım istemi: üstte, yer adının altında sabit şeritte; hikâye
  /// fısıltısıyla yarışmaz.
  /// Yer ipuçları sırayı beklemez: ekran boşsa hemen, doluysa ekrandaki
  /// ipucu okunacak kadar kaldıktan sonra onun yerine geçer; oyuncu o arada
  /// uzaklaşsa da gösterilir (hızlı ilerleyen oyuncu da görür). Gösterildiği
  /// an [onShown] çağrılır. Yalnız perde sırasında `false`.
  /// Olay ipuçları ([queue]) sıraya girer.
  bool hint(String text, {bool queue = false, VoidCallback? onShown}) {
    if (queue) {
      if (_hint != text && !_hints.contains(text)) _hints.add(text);
      return true;
    }
    if (!canHint) return false;
    if (_hint == text) return true;
    if (_hints.isEmpty && _hintFree) {
      _showHint(text);
      onShown?.call();
    } else if (_pending?.$1 != text) {
      // Bekleyen tek yer ipucu: en yenisi (oyuncunun şu an olduğu yer).
      _pending = (text, onShown);
    }
    return true;
  }

  void _showHint(String text) {
    _hint = text;
    _remember(RecentKind.hint, text);
    _hintT = 0;
  }

  /// Ekrandaki ipucu en az bu kadar kalır, sonra yeni yerin ipucu gelir.
  static const double minHintShow = 2.2;

  bool get _hintFree => _hint == null || _hintT >= minHintShow;

  /// Sırasını bekleyen yer ipucu.
  (String, VoidCallback?)? _pending;

  /// Şu an yeni bir ipucu gösterilebilir mi?
  bool get canHint => !inCinematic;

  String? get debugWhisper => _whisper;

  /// Ekrandaki bütün fısıltılar (üstteki önceki satır dahil).
  List<String> get debugWhispers => [?_prev, ?_whisper];
  String? get debugHint => _hint;

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
      }
    } else {
      _mythT += dt;
      if (_mythT > _mythLen) _myth = null;
    }
    _updateWhispers(dt);
    if (_hint != null) {
      _hintT += dt;
      if (_hintT > _hintDuration(_hint!)) _hint = null;
    }
    // Ekrandaki ipucu okunacak kadar kaldıysa sıradaki gelir: önce olay
    // ipuçları (ölümden sonraki ilişki, çözüm), sonra bekleyen yer ipucu.
    if (_hintFree && !inCinematic && !game.menuMode.value) {
      final pending = _pending;
      if (_hints.isNotEmpty) {
        _showHint(_hints.removeAt(0));
      } else if (pending != null) {
        _pending = null;
        _showHint(pending.$1);
        pending.$2?.call();
      }
    }
    _counterT += dt;
    _fireflyT += dt;
  }

  void _updateWhispers(double dt) {
    if (_whisper != null) _whisperT += dt;
    if (_prev != null) _prevT += dt;
    _shift = math.min(1, _shift + dt / 0.35);
    // Sırada bekleyen varsa ekrandakiler okunacak kadar kalır; kapanışları
    // yarım kesilmez.
    if (_whispers.isNotEmpty) {
      if (_prev != null) {
        _prevLen = math.min(
          _prevLen,
          math.max(_busyDuration(_prev!), _prevT + 0.8),
        );
      } else if (_whisper != null) {
        _whisperLen = math.min(
          _whisperLen,
          math.max(_busyDuration(_whisper!), _whisperT + 0.8),
        );
      }
    }
    if (_prev != null && _prevT > _prevLen) _prev = null;
    if (_whisper != null && _whisperT > _whisperLen) _whisper = null;
    if (_whispers.isEmpty || inCinematic) return;
    // Çok bekleyen satırlar ekrana gelmez (yer geçildi), panele düşer.
    while (_whispers.isNotEmpty && _clock - _whispers.first.$2 > staleAfter) {
      _remember(RecentKind.story, _whispers.removeAt(0).$1);
    }
    if (_whispers.isEmpty) return;
    // Yeni satır en alta gelir: alt boşsa hemen; doluysa alttaki biraz
    // görününce o yukarı kayar (üst de doluysa üstteki bitince).
    if (_whisper != null) {
      if (_prev != null || _whisperT < _minShow) return;
      _prev = _whisper;
      _prevT = _whisperT;
      _prevLen = _whisperLen;
      _shift = 0;
    }
    _whisper = _whispers.removeAt(0).$1;
    _remember(RecentKind.story, _whisper!);
    _whisperT = 0;
    _whisperLen = _whisperDuration(_whisper!);
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
    FontWeight weight = FontWeight.w300,
    double anchor = 0.5,
  }) {
    if (alpha <= 0) return;
    // Dizilmiş yazılar önbellekte: saydamlık 20 basamağa yuvarlanır, böylece
    // solma sırasında bile her karede yeniden dizilmez.
    final a = (alpha * 20).round() / 20;
    if (a <= 0) return;
    final key =
        '$s|$fontSize|$italic|$spacing|$maxWidth|${color.toARGB32()}|$a|$shadow|'
        '${weight.value}';
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
        weight,
      );
    }
    // [anchor]: noktanın yazının neresine düştüğü (0 üst, 0.5 orta, 1 alt).
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height * anchor));
  }

  final _cache = <String, TextPainter>{};

  /// Fısıltı satırının yüksekliği (önceki satırı üstüne koymak için).
  double _measure(String s, double size, double maxWidth) {
    final key = 'olcu|$s|$size|$maxWidth';
    final tp = _cache[key] ??= _layout(
      s,
      size,
      1,
      true,
      0,
      maxWidth,
      kText,
      true,
      FontWeight.w400,
    );
    return tp.height;
  }

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
    double alpha,
  ) {
    if (alpha <= 0) return;
    final a = (alpha * 20).round() / 20;
    // Sakin ama okunur: telefonda da küçülmez; yazı büyüklüğü ayarıyla büyür.
    final size = math.max(13.5, unit * 0.024) * Settings.textScale;
    final key = 'istem|$s|$size|$a';
    final tp = _cache[key] ??= _layout(
      s,
      size,
      a,
      false,
      0.3,
      w * 0.6,
      const Color(0xFFFFE9C4),
      false,
      FontWeight.w400,
    );
    // Hep aynı yerde: üstte ortada, yer adının altında.
    final bw = tp.width + 24;
    final bh = tp.height + 10;
    final left = (w - bw) / 2;
    final y = hintTop(h);
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
    tp.paint(canvas, Offset(left + 12, y + 5));
  }

  /// İpucu şeridinin üst kenarı (yer adının altı; sol üstteki görev satırı
  /// ve ateşböceklerinin altında kalır).
  static double hintTop(double h) => math.max(h * 0.12, 88.0);

  TextPainter _layout(
    String s,
    double fontSize,
    double alpha,
    bool italic,
    double spacing,
    double maxWidth,
    Color color,
    bool shadow, [
    FontWeight weight = FontWeight.w300,
  ]) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: color.withValues(alpha: alpha),
          fontSize: fontSize,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          fontWeight: weight,
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
            math.max(15.0, unit * 0.034) * Settings.textScale,
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
          unit * (isEnd ? 0.05 : 0.036) * Settings.textScale,
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

    // Fısıltı yığınının çıkabileceği en üst yer (efsane kartının altı).
    var stackLimit = hintTop(h) + 44;
    // Efsane kartı: adı büyük, altında kim olduğu, en altta Defter notu.
    final myth = _myth;
    if (myth != null) {
      final a = _envelope(_mythT, 1.0, _mythLen - 2.3, 1.3);
      final k = Settings.textScale;
      final nameSize = math.max(20.0, unit * 0.046) * k;
      final whoSize = math.max(14.0, unit * 0.026) * k;
      final noteSize = math.max(10.0, unit * 0.016) * k;
      // Sabit yeri: ipucu şeridinin altında, ekranın ortasında.
      final top = math.max(h * 0.3, hintTop(h) + 44);
      final nameY = top + nameSize * 0.9;
      final whoY = nameY + nameSize * 0.75 + whoSize * 1.1;
      final noteY = whoY + whoSize * 1.4 + noteSize;
      stackLimit = noteY + noteSize + 8;
      // Okunurluk: arkada yumuşak, koyu bir şerit (parlak ağacın önünde de).
      if (a > 0) {
        final band = Rect.fromLTRB(0, top - h * 0.03, w, noteY + h * 0.04);
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
        Offset(w / 2, nameY),
        nameSize,
        a,
        spacing: 9,
        weight: FontWeight.w400,
      );
      _text(
        canvas,
        myth.$2,
        Offset(w / 2, whoY),
        whoSize,
        a * 0.9,
        italic: true,
        maxWidth: w * 0.7,
        weight: FontWeight.w400,
      );
      _text(
        canvas,
        S.upper(S.of('mythNoted')),
        Offset(w / 2, noteY),
        noteSize,
        a * 0.55,
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
        math.max(12.0, unit * 0.022) * Settings.textScale,
        a * 0.8,
        italic: true,
        spacing: 2,
      );
    }

    if (_whisper != null || _prev != null) {
      final a = math.max(
        _whisper == null
            ? 0.0
            : _envelope(_whisperT, 0.6, _whisperLen - 1.4, 0.8),
        _prev == null ? 0.0 : _envelope(_prevT, 0.6, _prevLen - 1.4, 0.8),
      );
      // Hep aynı yerde: en altta ortada (dokunmatikte iki başparmağın
      // arasında); uzun satır yukarı doğru büyür.
      final bottom = h - math.max(14.0, h * 0.045);
      final size = math.max(15.0, unit * 0.032) * Settings.textScale;
      // Okunurluk için alttan yükselen yumuşak, koyu bir şerit.
      if (a > 0) {
        final band = Rect.fromLTRB(0, h * 0.66, w, h);
        canvas.drawRect(
          band,
          Paint()
            ..shader = ui.Gradient.linear(band.topCenter, band.bottomCenter, [
              const Color(0x00050302),
              const Color(0xFF050302).withValues(alpha: 0.7 * a),
            ]),
        );
      }
      // Önceki satır yeni satırın üstüne kayar, biraz solar.
      // Küçük ekranda yığın efsane kartına değecekse önceki satır gizlenir
      // ("Az önce" panelinde okunur).
      final prev = _prev;
      final above = prev == null || _whisper == null
          ? 0.0
          : _measure(_whisper!, size, w * 0.64) + size * 0.5;
      if (prev != null &&
          bottom - above - _measure(prev, size, w * 0.64) >= stackLimit) {
        final e = 1 - math.pow(1 - _shift, 3).toDouble();
        _text(
          canvas,
          prev,
          Offset(w / 2, bottom - above * e),
          size,
          _envelope(_prevT, 0.6, _prevLen - 1.4, 0.8) * 0.75,
          italic: true,
          maxWidth: w * 0.64,
          weight: FontWeight.w400,
          anchor: 1,
        );
      }
      if (_whisper != null) {
        _text(
          canvas,
          _whisper!,
          Offset(w / 2, bottom),
          size,
          _envelope(_whisperT, 0.6, _whisperLen - 1.4, 0.8),
          italic: true,
          maxWidth: w * 0.64,
          weight: FontWeight.w400,
          anchor: 1,
        );
      }
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
      _prompt(canvas, _hint!, w, h, unit, a);
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
