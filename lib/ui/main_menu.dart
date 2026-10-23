import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/golge_game.dart';
import '../game/levels.dart';
import '../game/perde.dart';
import '../game/strings.dart';
import '../settings.dart';
import 'info_pages.dart';
import 'story_theater.dart';

/// Ana menü: arkada oyunun dünyası yavaşça akar; solda kandille aydınlanan
/// bir hayal perdesi (oyunun adı gölge harflerle), sağda seçenekler.
class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.game, this.onQuit});

  final GolgeGame game;
  final VoidCallback? onQuit;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  int _taps = 0;
  int _lastTap = 0;
  bool _unlockedNote = false;

  void _secretTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _taps = now - _lastTap < 700 ? _taps + 1 : 1;
    _lastTap = now;
    if (_taps < 7) return;
    _taps = 0;
    Settings.unlocked = levelOrder.length - 1;
    // Her şey açılır: Hikâye'nin bütün perdeleri ve Defter de.
    Settings.allOpen = true;
    Settings.save();
    setState(() => _unlockedNote = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _unlockedNote = false);
    });
  }

  static const _text = Color(0xFFEBDDCB);
  static const _accent = Color(0xFFE0A15F);

  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  bool _confirmNew = false;

  /// Bölüm listesi açık mı.
  bool _chapters = false;

  /// Hikâye tiyatrosu açık mı.
  bool _theater = false;

  /// Menünün üstünde açık sayfa: Hikâye, Defter ya da Hakkında.
  _Sheet? _sheet;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _setLang(Lang l) {
    S.lang = l;
    Settings.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Alçak ekranlarda (telefon) yazılar ve boşluklar küçülür.
    final k = (MediaQuery.sizeOf(context).height / 640).clamp(0.6, 1.0);
    // Seçenekler parmakla dokunulabilecek kadar büyük kalır.
    final itemK = k < 0.85 ? 0.85 : k;
    final save = SaveGame.current;
    final savedLevel = save == null
        ? null
        : levels[save.level.clamp(0, levels.length - 1)].titleText;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: Stack(
        children: [
          // Perde karanlık bir odada: dünya arkada soluk akar.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.35, -0.1),
                  radius: 1.3,
                  colors: [Color(0xB0050302), Color(0xF0050302)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(28 * k, 16 * k, 40 * k, 16 * k),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1 / 0.8,
                        child: _MenuPerde(
                          title: S.of('gameTitle'),
                          tagline: S.of('menuTagline'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 36 * k),
                  Expanded(
                    flex: 8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Ornament(),
                        SizedBox(height: 18 * k),
                        if (_chapters) ...[
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final i in levelOrder.take(
                                    Settings.unlocked + 1,
                                  ))
                                    _item(
                                      levels[i].titleText,
                                      scale: itemK * 0.85,
                                      hint: levels[i].placeText
                                          .split(' · ')
                                          .first,
                                      onTap: () => widget.game.startChapter(i),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          _item(
                            S.of('back'),
                            scale: itemK,
                            onTap: () => setState(() => _chapters = false),
                          ),
                        ] else ...[
                          if (save != null)
                            _item(
                              S.of('continue'),
                              scale: itemK,
                              hint: savedLevel,
                              primary: true,
                              onTap: widget.game.continueGame,
                            ),
                          _item(
                            _confirmNew ? S.of('confirmNew') : S.of('newGame'),
                            scale: itemK,
                            primary: save == null,
                            warn: _confirmNew,
                            onTap: () {
                              if (save != null && !_confirmNew) {
                                setState(() => _confirmNew = true);
                                return;
                              }
                              widget.game.startNewGame();
                            },
                          ),
                          if (Settings.unlocked >= 1)
                            _item(
                              S.of('chapters'),
                              scale: itemK,
                              hint: S.of('chaptersHint'),
                              onTap: () => setState(() {
                                _chapters = true;
                                _confirmNew = false;
                              }),
                            ),
                          _item(
                            S.of('story'),
                            scale: itemK,
                            hint: S.of('storyHint'),
                            onTap: () => setState(() {
                              _sheet = _Sheet.story;
                              _confirmNew = false;
                            }),
                          ),
                          _item(
                            S.of('book'),
                            scale: itemK,
                            hint: S.of('bookHint'),
                            onTap: () => setState(() {
                              _sheet = _Sheet.book;
                              _confirmNew = false;
                            }),
                          ),
                          _item(
                            S.of('settings'),
                            scale: itemK,
                            onTap: widget.game.toggleSettings,
                          ),
                          _item(
                            S.of('about'),
                            scale: itemK,
                            hint: S.of('aboutHint'),
                            onTap: () => setState(() {
                              _sheet = _Sheet.about;
                              _confirmNew = false;
                            }),
                          ),
                          if (widget.onQuit != null)
                            _item(
                              S.of('quit'),
                              scale: itemK,
                              onTap: widget.onQuit!,
                            ),
                        ],
                        SizedBox(height: 18 * k),
                        const _Ornament(),
                        SizedBox(height: 14 * k),
                        Row(
                          children: [
                            Flexible(
                              // Gizli: yedi kez dokununca bütün bölümler
                              // açılır (deneme için).
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _secretTap,
                                child: Text(
                                  _unlockedNote
                                      ? S.of('allUnlocked')
                                      : S.of('menuSubtitle'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _accent.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _langButton('TR', Lang.tr),
                            Text(
                              ' / ',
                              style: TextStyle(
                                color: _text.withValues(alpha: 0.35),
                              ),
                            ),
                            _langButton('EN', Lang.en),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Hikâye, Defter, Hakkında: menünün üstünde tam ekran.
          if (_sheet == _Sheet.story)
            _page(
              k,
              itemK,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _item(
                      S.of('watchActs'),
                      scale: itemK,
                      primary: true,
                      onTap: () => setState(() => _theater = true),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const StoryPage(),
                ],
              ),
            ),
          if (_sheet == _Sheet.book)
            _page(
              k,
              itemK,
              MemoryBookPage(
                memories: widget.game.collectedMemories,
                myths: widget.game.mythsSeen,
              ),
            ),
          if (_sheet == _Sheet.about)
            Positioned.fill(
              child: _AboutScreen(
                k: k,
                itemK: itemK,
                back: _item(
                  S.of('back'),
                  scale: itemK,
                  onTap: () => setState(() => _sheet = null),
                ),
                link: (label, hint, uri) => _item(
                  label,
                  scale: itemK * 0.85,
                  hint: hint,
                  onTap: () => _open(uri),
                ),
              ),
            ),
          // Hikâye tiyatrosu: perdeler art arda, menünün üstünde.
          if (_theater)
            Positioned.fill(
              child: StoryTheater(
                onClose: () => setState(() => _theater = false),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Tarayıcı açılamazsa sessizce geçilir.
    }
  }

  /// Menünün üstünde açılan yazılı sayfa: ortada okunur genişlikte, altta
  /// Geri.
  Widget _page(double k, double itemK, Widget child) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xFF070403),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24 * k, 18 * k, 24 * k, 8 * k),
              child: Column(
                children: [
                  Expanded(child: SingleChildScrollView(child: child)),
                  const _Ornament(),
                  _item(
                    S.of('back'),
                    scale: itemK,
                    onTap: () => setState(() => _sheet = null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _langButton(String label, Lang lang) {
    final active = S.lang == lang;
    return InkWell(
      onTap: () => _setLang(lang),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _accent : _text.withValues(alpha: 0.45),
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _item(
    String label, {
    required VoidCallback onTap,
    double scale = 1,
    String? hint,
    bool primary = false,
    bool warn = false,
  }) {
    return _MenuItem(
      scale: scale,
      label: label,
      hint: hint,
      onTap: onTap,
      primary: primary,
      warn: warn,
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.label,
    required this.onTap,
    this.hint,
    this.primary = false,
    this.warn = false,
    this.scale = 1,
  });

  final double scale;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool primary;
  final bool warn;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFFEBDDCB);
    const accent = Color(0xFFE0A15F);
    final lit = _hover || widget.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            left: _hover ? 14 : 0,
            top: 9 * widget.scale,
            bottom: 9 * widget.scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _hover ? 1 : 0,
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.local_fire_department_outlined,
                    size: 16,
                    color: accent,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.warn
                        ? const Color(0xFFE08A6A)
                        : (lit ? text : text.withValues(alpha: 0.7)),
                    fontSize: 21 * widget.scale,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (widget.hint != null) ...[
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.hint!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.8),
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kandille aydınlanan menü perdesi: titreyen ışık, sallanan tasvirler.
class _MenuPerde extends StatefulWidget {
  const _MenuPerde({required this.title, required this.tagline});

  final String title;
  final String tagline;

  @override
  State<_MenuPerde> createState() => _MenuPerdeState();
}

class _MenuPerdeState extends State<_MenuPerde>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6)
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PerdePainter(_time, widget.title, widget.tagline),
    );
  }
}

class _PerdePainter extends CustomPainter {
  _PerdePainter(this.time, this.title, this.tagline) : super(repaint: time);

  final ValueNotifier<double> time;
  final String title;
  final String tagline;

  @override
  void paint(Canvas canvas, Size size) =>
      PerdePainter.paintMenu(canvas, size, time.value, title, tagline);

  @override
  bool shouldRepaint(_PerdePainter old) =>
      old.title != title || old.tagline != tagline;
}

/// İnce süs çizgisi: iki yanda çizgi, ortada eşkenar dörtgen.
class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE0A15F);
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: accent.withAlpha(80))),
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: accent.withAlpha(170)),
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: accent.withAlpha(80))),
        ],
      ),
    );
  }
}

enum _Sheet { story, book, about }

/// Hakkında: bir gölge oyununun sonundaki gibi. Solda aydınlık perde, sağda
/// perde kapanırken okunan künye: hayalî (perdeyi oynatan usta), müzik,
/// sesler, tasvirler; bağlantılar menünün seçenekleri gibi.
class _AboutScreen extends StatelessWidget {
  const _AboutScreen({
    required this.k,
    required this.itemK,
    required this.back,
    required this.link,
  });

  final double k;
  final double itemK;
  final Widget back;
  final Widget Function(String label, String hint, Uri uri) link;

  static const _text = Color(0xFFEBDDCB);
  static const _accent = Color(0xFFE0A15F);

  Widget _label(String t) => Text(
    S.upper(t),
    style: TextStyle(
      color: _accent.withValues(alpha: 0.85),
      fontSize: 11 * k,
      letterSpacing: 3.5,
    ),
  );

  Widget _credit(String title, String body) => Padding(
    padding: EdgeInsets.only(top: 14 * k),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        SizedBox(height: 4 * k),
        Text(
          body,
          style: TextStyle(
            color: _text.withValues(alpha: 0.62),
            fontSize: 12.5 * k,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF070403),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28 * k, 16 * k, 40 * k, 16 * k),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1 / 0.8,
                    child: _MenuPerde(
                      title: S.of('gameTitle'),
                      tagline: S.of('aboutGame'),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 36 * k),
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12 * k),
                            Text(
                              S.of('credits'),
                              style: TextStyle(
                                color: _text.withValues(alpha: 0.5),
                                fontSize: 13 * k,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 18 * k),
                            _label(S.of('hayali')),
                            SizedBox(height: 6 * k),
                            Text(
                              'Erkan Öz',
                              style: TextStyle(
                                color: _text,
                                fontSize: 34 * k,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 3,
                              ),
                            ),
                            Text(
                              S.of('hayaliRole'),
                              style: TextStyle(
                                color: _accent.withValues(alpha: 0.7),
                                fontSize: 12 * k,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 14 * k),
                            Text(
                              S.of('aboutDev'),
                              style: TextStyle(
                                color: _text.withValues(alpha: 0.82),
                                fontSize: 14 * k,
                                fontStyle: FontStyle.italic,
                                height: 1.55,
                              ),
                            ),
                            SizedBox(height: 14 * k),
                            const _Ornament(),
                            _credit(
                              S.of('creditMusic'),
                              S.of('creditMusicText'),
                            ),
                            _credit(
                              S.of('creditSounds'),
                              S.of('creditSoundsText'),
                            ),
                            _credit(S.of('creditArt'), S.of('creditArtText')),
                            SizedBox(height: 16 * k),
                            link(
                              S.of('siteLink'),
                              S.of('aboutSite'),
                              Uri.https('erkanoz.com', '/'),
                            ),
                            link(
                              S.of('gameLink'),
                              'lifeos.com.tr/gölgeler',
                              Uri.https('lifeos.com.tr', '/gölgeler/'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    back,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
