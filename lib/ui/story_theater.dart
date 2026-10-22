import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/audio.dart';
import '../game/levels.dart';
import '../game/perde.dart';
import '../game/strings.dart';
import '../settings.dart';

/// Hikâye tiyatrosu: önsöz ve oyuncunun ulaştığı yere dek açılan bütün
/// bölüm perdeleri art arda, oyundaki gibi gölge oyunu olarak oynar. Her
/// geçilmiş bölümün ardından bir köprü: Sâye'nin o bölümde yürüdüğü yol.
/// Henüz oynanmamış perdeler kapalı kalır: hikâyenin devamı oynayarak açılır.
class StoryTheater extends StatefulWidget {
  const StoryTheater({super.key, required this.onClose});

  final VoidCallback onClose;

  /// Oynanacak perdeler: (sahne, satırlar, üst yazı, köprünün bölümü).
  /// Köprüde (son alan bölüm kimliği) başlık kartı yoktur; bölümün perdesi
  /// kesintisiz sürer.
  static List<(PerdeScene, List<String>, String, int?)> acts() {
    final reached = math.max(
      orderOf(SaveGame.current?.level ?? 0),
      Settings.unlocked,
    );
    final out = <(PerdeScene, List<String>, String, int?)>[
      (PerdeScene.prologue, prologueText, S.of('storyPrologue'), null),
    ];
    void bridge(int lv) {
      final lines = bridgeText(lv);
      if (lines.isEmpty) return;
      out.add((out.last.$1, lines, levels[lv].titleText, lv));
    }

    for (var o = 1; o <= reached && o < levelOrder.length; o++) {
      // Bir önceki bölüm geçildi: Sâye'nin oradaki yolu.
      bridge(levelOrder[o - 1]);
      final lv = levelOrder[o];
      final scene = interludeScene(lv);
      final lines = interludeText(lv);
      if (scene == null || lines.isEmpty) continue;
      out.add((scene, lines, levels[lv].titleText, null));
    }
    if (reached >= levelOrder.length - 1) {
      bridge(levelOrder.last);
      out.add((PerdeScene.epilogue, epilogueText, S.of('storyEpilogue'), null));
    }
    return out;
  }

  /// Hepsi açıldı mı (son perde de).
  static bool get complete =>
      math.max(orderOf(SaveGame.current?.level ?? 0), Settings.unlocked) >=
      levelOrder.length - 1;

  @override
  State<StoryTheater> createState() => _StoryTheaterState();
}

class _StoryTheaterState extends State<StoryTheater>
    with SingleTickerProviderStateMixin {
  static const _lineIn = 1.2;
  static const _lineOut = 1.0;

  late final List<(PerdeScene, List<String>, String, int?)> _acts =
      StoryTheater.acts();
  late final Ticker _ticker;
  final _tick = ValueNotifier<int>(0);
  double _last = 0;

  int _act = 0;
  int _line = 0;
  double _lineT = 0;
  double _sceneT = 0;

  /// Perdeler arasında başlık kartı (0-1 geçiş); bitince kapalı perde.
  double _card = 1.6;
  bool _ended = false;

  List<String> get _lines => _acts[_act].$2;

  double get _hold {
    final l = _lines[_line.clamp(0, _lines.length - 1)];
    return math.max(2.8, l.length * 0.055);
  }

  double get _lineLen => _lineIn + _hold + _lineOut;

  @override
  void initState() {
    super.initState();
    GameAudio.instance.menuMusic(false);
    GameAudio.instance.perde(true);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    GameAudio.instance.perde(false);
    GameAudio.instance.menuMusic(true);
    super.dispose();
  }

  void _onTick(Duration d) {
    final now = d.inMicroseconds / 1e6;
    final dt = (now - _last).clamp(0.0, 0.1);
    _last = now;
    _sceneT += dt;
    if (_ended) {
      _tick.value++;
      return;
    }
    if (_card > 0) {
      _card = math.max(0, _card - dt);
    } else {
      _lineT += dt;
      if (_lineT > _lineLen) _nextLine();
    }
    _tick.value++;
  }

  void _nextLine() {
    if (_card > 0) {
      _card = 0;
      return;
    }
    if (_line < _lines.length - 1) {
      _line++;
      _lineT = 0;
    } else {
      _nextAct();
    }
  }

  void _nextAct() {
    if (_act < _acts.length - 1) {
      _act++;
      _line = 0;
      _lineT = 0;
      _sceneT = 0;
      _card = _acts[_act].$4 == null ? 1.6 : 0;
    } else {
      _ended = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final k = (MediaQuery.sizeOf(context).height / 640).clamp(0.6, 1.0);
    return Material(
      color: const Color(0xFF050302),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(_nextLine),
              child: CustomPaint(painter: _TheaterPainter(this)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(14 * k),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_ended) _button(S.of('storySkipAct'), k, _nextAct),
                    SizedBox(width: 10 * k),
                    _button(S.of('back'), k, widget.onClose),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, double k, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFE0A15F),
      padding: EdgeInsets.symmetric(horizontal: 14 * k, vertical: 8 * k),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0x44E0A15F)),
      ),
    ),
    child: Text(label, style: TextStyle(fontSize: 14 * k, letterSpacing: 1.5)),
  );
}

class _TheaterPainter extends CustomPainter {
  _TheaterPainter(this.s) : super(repaint: s._tick);

  final _StoryTheaterState s;

  static const _text = Color(0xFFEBDDCB);

  void _write(
    Canvas canvas,
    String str,
    Offset center,
    double size,
    double alpha, {
    bool italic = false,
    double spacing = 0.5,
    double maxWidth = 900,
    Color color = _text,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(
          color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          fontSize: size,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          fontWeight: FontWeight.w300,
          letterSpacing: spacing,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(h, w * 0.6);
    final (scene, lines, title, bridge) = s._acts[s._act];
    final r = PerdePainter.screenRect(size);
    if (s._ended) {
      // Kapalı perde: devamı oynayarak açılır.
      PerdePainter.paint(canvas, size, PerdeScene.prologue, s._sceneT, 2.9, 1);
      _write(
        canvas,
        StoryTheater.complete ? S.of('storyAllPlayed') : S.of('storyMore'),
        Offset(w / 2, (r.bottom + h) / 2),
        unit * 0.036,
        0.9,
        italic: true,
        maxWidth: w * 0.8,
      );
      return;
    }
    final progress = s._card > 0 ? 0.0 : s._line + (s._lineT / s._lineLen);
    PerdePainter.paint(
      canvas,
      size,
      scene,
      s._sceneT,
      progress,
      1,
      bridge: bridge,
      bridgeLines: lines.length,
    );
    if (s._card > 0) {
      // Perdenin adı.
      final a =
          math.min(1.0, s._card / 0.4) * math.min(1.0, (1.6 - s._card) / 0.4);
      // Perdenin önüne ışık iner: ad, sahnedeki tasvirlerin (ayna, kule)
      // altında kalmadan okunur.
      canvas.drawRect(
        r,
        Paint()..color = const Color(0xFFE6A15A).withValues(alpha: 0.82 * a),
      );
      _write(
        canvas,
        S.upper(title),
        r.center.translate(0, -r.height * 0.18),
        r.height * 0.08,
        a,
        spacing: 8,
        maxWidth: r.width,
        color: const Color(0xFF1A0B05),
      );
      return;
    }
    final line = lines[s._line];
    final t = s._lineT;
    final a = t < _StoryTheaterState._lineIn
        ? t / _StoryTheaterState._lineIn
        : t > _StoryTheaterState._lineIn + s._hold
        ? 1 -
              (t - _StoryTheaterState._lineIn - s._hold) /
                  _StoryTheaterState._lineOut
        : 1.0;
    final isEnd = line == line.toUpperCase();
    if (isEnd) {
      canvas.drawRect(
        r,
        Paint()..color = const Color(0xFFE6A15A).withValues(alpha: 0.78 * a),
      );
      _write(
        canvas,
        line,
        r.center.translate(0, -r.height * 0.18),
        r.height * 0.1,
        a,
        spacing: 10,
        maxWidth: r.width,
        color: const Color(0xFF1A0B05),
      );
    } else {
      _write(
        canvas,
        line,
        Offset(w / 2, (r.bottom + h) / 2 + r.height * 0.02),
        unit * 0.034,
        a,
        italic: true,
        maxWidth: w * 0.8,
      );
    }
    // Perde sırası: altta küçük noktalar.
    final dots = s._acts.length;
    for (var i = 0; i < dots; i++) {
      canvas.drawCircle(
        Offset(w / 2 + (i - (dots - 1) / 2) * 12, h - 14),
        i == s._act ? 3 : 2,
        Paint()
          ..color = const Color(0xFFE0A15F)
              .withValues(alpha: i <= s._act ? 0.8 : 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_TheaterPainter old) => true;
}
