import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/audio.dart';
import '../game/perde.dart';
import '../game/strings.dart';
import '../settings.dart';

/// Açılış girişi: ilk açılışta ana menünün üstünde bir kez oynar (bkz.
/// perde_giris.dart). Dokununca ya da bir tuşla atlanır; sonunda perde
/// menüdeki perdenin yerine kayar, giriş saydamlaşıp menü kalır.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({
    super.key,
    required this.menuPerde,
    required this.onDone,
  });

  /// Menüdeki perdenin ekrandaki yeri (yoksa giriş ortada biter).
  final Rect? Function() menuPerde;
  final VoidCallback onDone;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);

  /// Menünün perdesiyle aynı saat (ikisi aynı anda kurulur): sonda menünün
  /// çizimi menüdekiyle aynı anda (Hüdhüd aynı yerde) görünsün.
  double _menuTime = 0;

  /// Saat ses motoru hazır olunca başlar (kibrit sesi kaybolmasın); en
  /// çok bu kadar beklenir.
  static const _maxWait = 2.5;
  Duration? _start;
  double _offset = 0;
  bool _done = false;
  final _played = <String>{};

  @override
  void initState() {
    super.initState();
    GameAudio.instance.menuMusic(false);
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration d) {
    _menuTime = d.inMicroseconds / 1e6;
    if (_start == null) {
      final waited = d.inMicroseconds / 1e6;
      if (!GameAudio.instance.ready && waited < _maxWait) return;
      _start = d;
    }
    final t = (d - _start!).inMicroseconds / 1e6 + _offset;
    _time.value = t;
    _sounds(t);
    if (t >= introLength) _finish();
  }

  /// Sözsüz: kibrit, alev, ney nefesi, Kandilci geçerken gerilim.
  void _sounds(double t) {
    final a = GameAudio.instance;
    void at(double beat, String key, void Function() play) {
      if (t >= beat && _played.add(key)) play();
    }

    at(IntroBeats.strike, 'kibrit', () => a.play('match', volume: 0.6));
    at(IntroBeats.lampUp, 'alev', () => a.play('fire', volume: 0.25));
    at(IntroBeats.sayeIn, 'ney', () => a.perde(true));
    at(IntroBeats.shadowStep, 'adım', () => a.play('breath', volume: 0.3));
    at(IntroBeats.lamplighter, 'kandilci', () {
      a.perde(false);
      a.play('gust', volume: 0.35);
      a.dread(0.45);
    });
    at(IntroBeats.lampOut, 'söndü', () {
      a.play('fizzle', volume: 0.5);
      a.dread(0);
    });
    at(IntroBeats.firefly, 'ateşböceği', () => a.play('firefly', volume: 0.5));
    at(IntroBeats.title, 'başlık', () => a.perde(true));
    at(IntroBeats.relight, 'yeniden', () => a.play('fire', volume: 0.3));
    at(IntroBeats.toMenu, 'menü', () {
      a.perde(false);
      a.menuMusic(true);
    });
  }

  /// Atla: kandil yanmış, perde menüye dönmek üzere.
  void _skip() {
    if (_done) return;
    // Ses motoru beklenirken: doğrudan menü.
    if (_start == null) {
      _finish();
      return;
    }
    final t = _time.value;
    if (t >= IntroBeats.toMenu) return;
    _offset += IntroBeats.toMenu - t;
    // Atlanan anların sesleri çalmasın; menü müziği gelsin.
    for (final k in [
      'kibrit',
      'alev',
      'ney',
      'adım',
      'kandilci',
      'söndü',
      'ateşböceği',
      'başlık',
      'yeniden',
    ]) {
      _played.add(k);
    }
    GameAudio.instance
      ..perde(false)
      ..dread(0);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _ticker.stop();
    Settings.introSeen = true;
    Settings.save();
    GameAudio.instance
      ..perde(false)
      ..dread(0)
      ..menuMusic(true);
    widget.onDone();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent) {
          _skip();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: ValueListenableBuilder<double>(
          valueListenable: _time,
          builder: (context, t, child) {
            final fade = ((t - 11.6) / 0.6).clamp(0.0, 1.0);
            return Opacity(opacity: 1 - fade, child: child);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _IntroPainter(
                  _time,
                  () => _menuTime,
                  S.of('gameTitle'),
                  S.of('menuTagline'),
                  widget.menuPerde,
                ),
              ),
              // Atla: perdedeki gibi sağ altta.
              Positioned(
                right: 16,
                bottom: 12,
                child: SafeArea(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _time,
                    builder: (context, t, _) => AnimatedOpacity(
                      opacity: t < IntroBeats.toMenu ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEBDDCB),
                          backgroundColor: const Color(0x66140C09),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: const StadiumBorder(
                            side: BorderSide(color: Color(0x66E0A15F)),
                          ),
                        ),
                        child: Text(
                          '${S.of('skipPerde')}  ›',
                          style: const TextStyle(
                            fontSize: 15,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPainter extends CustomPainter {
  _IntroPainter(this.time, this.menuTime, this.title, this.tagline, this.target)
    : super(repaint: time);

  final ValueNotifier<double> time;
  final double Function() menuTime;
  final String title;
  final String tagline;
  final Rect? Function() target;

  @override
  void paint(Canvas canvas, Size size) => PerdePainter.paintIntro(
    canvas,
    size,
    time.value,
    title,
    tagline,
    target: target(),
    menuTime: menuTime(),
  );

  @override
  bool shouldRepaint(_IntroPainter old) => false;
}
