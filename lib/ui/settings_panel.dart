import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/audio.dart';
import '../game/golge_game.dart';
import '../game/hints.dart';
import '../game/palette.dart';
import '../game/strings.dart';
import '../display.dart';
import '../settings.dart';
import 'page_frame.dart';

/// Ayarlar: Esc ya da dişli simgesiyle açılan, Defter ve Hakkında ile aynı
/// çerçevede sekmeli bir sayfa (Ses, Görüntü, Oyun, Kontroller, Lisanslar);
/// her sekmede başlıklı bölümler. Açıkken oyun durur; oyun sırasında altta
/// Ana menü / Yeniden dene / Devam et.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.game,
    required this.canFullscreen,
    required this.onFullscreen,
    required this.onLanguage,
    this.canTouch = false,
    this.onTouchChanged,
  });

  /// Dokunmatik kontrol ayarları yalnızca telefon ve tablette görünür.
  final bool canTouch;
  final VoidCallback? onTouchChanged;

  /// Dil değişince arkadaki ekranlar yenilensin.
  final VoidCallback onLanguage;

  bool get inGame => !game.menuMode.value;

  final GolgeGame game;
  final bool canFullscreen;
  final ValueChanged<bool> onFullscreen;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

enum _Tab { sound, display, game, controls, licenses }

class _SettingsPanelState extends State<SettingsPanel> {
  static const _text = Color(0xFFEBDDCB);
  static const _accent = Color(0xFFE0A15F);

  /// Son açık sekme (yeniden açılınca oradan).
  static _Tab _last = _Tab.sound;
  _Tab _tab = _last;

  double _k = 1;

  /// Yazı ölçeği: alçak ekranda (telefon) da okunur kalsın diye küçülmesi
  /// sınırlı (boşluklar _k ile küçülür).
  double get _f => _k < 0.92 ? 0.92 : _k;

  List<_Tab> get _tabs => [
    _Tab.sound,
    _Tab.display,
    _Tab.game,
    if (widget.canTouch) _Tab.controls,
    _Tab.licenses,
  ];

  String _tabName(_Tab t) => S.of(switch (t) {
    _Tab.sound => 'tabSound',
    _Tab.display => 'tabDisplay',
    _Tab.game => 'tabGame',
    _Tab.controls => 'tabControls',
    _Tab.licenses => 'tabLicenses',
  });

  void _save() {
    GameAudio.instance.applyVolumes();
    Settings.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _k = (MediaQuery.sizeOf(context).height / 640).clamp(0.6, 1.0);
    if (!_tabs.contains(_tab)) _tab = _Tab.sound;
    return Material(
      type: MaterialType.transparency,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: _accent,
          inactiveTrackColor: const Color(0x33E0A15F),
          thumbColor: _accent,
          overlayColor: const Color(0x22E0A15F),
          trackHeight: 3,
        ),
        child: PageFrame(
          k: _k,
          title: S.of('settingsTitle'),
          onBack: widget.game.toggleSettings,
          tabs: [for (final t in _tabs) _tabName(t)],
          tab: _tabs.indexOf(_tab),
          onTab: (i) => setState(() => _last = _tab = _tabs[i]),
          footer: _footer(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (_tab) {
                  _Tab.sound => _sound(),
                  _Tab.display => _display(),
                  _Tab.game => _gameTab(),
                  _Tab.controls => _controls(),
                  _Tab.licenses => _licenses(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- sekmeler

  List<Widget> _sound() => [
    _section(S.of('secVolumes')),
    _slider(S.of('music'), Settings.music, (v) => Settings.music = v),
    _slider(S.of('ambience'), Settings.ambience, (v) => Settings.ambience = v),
    _slider(S.of('effects'), Settings.effects, (v) => Settings.effects = v),
    _section(S.of('secNarration')),
    _switch(S.of('voiceSetting'), Settings.voice, (v) {
      Settings.voice = v;
      if (!v) GameAudio.instance.stopVoice(clearQueue: true);
    }),
    if (Settings.voice)
      _slider(
        S.of('voiceVolume'),
        Settings.voiceVolume,
        (v) => Settings.voiceVolume = v,
      ),
    _switch(
      S.of('subtitles'),
      Settings.subtitles,
      (v) => Settings.subtitles = v,
      note: S.of('subtitlesHint'),
    ),
  ];

  List<Widget> _display() => [
    _section(S.of('secScreen')),
    if (widget.canFullscreen)
      _switch(S.of('fullscreen'), Settings.fullscreen, (v) {
        widget.onFullscreen(v);
      }, save: false),
    _slider(
      S.of('brightness'),
      Settings.brightness,
      (v) => Settings.brightness = v,
      min: 0.6,
      max: 1.6,
    ),
    _slider(
      S.of('textSize'),
      Settings.textScale,
      (v) => Settings.textScale = v,
      min: 0.8,
      max: 1.6,
      divisions: 8,
    ),
    _section(S.of('secGraphics')),
    _row(
      S.of('graphics'),
      _segments<bool>(
        {false: S.of('gfxHigh'), true: S.of('gfxLow')},
        Settings.lowGraphics,
        (v) => Settings.lowGraphics = v,
      ),
    ),
    // Yüksek yenileme hızı: Android'de 90/120 Hz istenir; masaüstünde
    // kapalıyken kareler 60 dolayında sınırlanır (açıkken ekranın hızı).
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)
      _switch(S.of('highRefresh'), Settings.highRefresh, (v) {
        Settings.highRefresh = v;
        applyRefreshRate();
        widget.game.pacer.apply();
      }),
    if (Cartoon.trialBuild) ...[
      _switch(
        S.of('lightDepth'),
        Realism.on,
        (v) {
          Realism.on = v;
          Settings.realism = v;
        },
        note: Settings.lowGraphics ? S.of('lightDepthLow') : null,
        noteAlways: true,
      ),
      _switch(S.of('textureSetting'), Cartoon.on, (v) {
        Cartoon.on = v;
        Settings.texture = v;
      }),
      _slider(S.of('colorTone'), Cartoon.tone, (v) {
        Cartoon.tone = v;
        Settings.tone = v;
      }, divisions: 20),
    ],
    _section(S.of('secAccess')),
    _switch(
      S.of('calmEffects'),
      Settings.calmEffects,
      (v) => Settings.calmEffects = v,
    ),
    if (Cartoon.trialBuild)
      _switch(
        S.of('perfMeter'),
        widget.game.perfShown,
        (v) => widget.game.perfShown = v,
      ),
  ];

  List<Widget> _gameTab() => [
    _section(S.of('language')),
    _row(
      S.of('language'),
      _segments<Lang>({Lang.tr: 'Türkçe', Lang.en: 'English'}, S.lang, (v) {
        S.lang = v;
        widget.onLanguage();
      }),
    ),
    _section(S.of('secNarration')),
    // İkinci oynayışta hikâyeyi yeniden okumak istemeyen için.
    _switch(
      S.of('storyWhispers'),
      Settings.storyWhispers,
      (v) => Settings.storyWhispers = v,
      note: S.of('storyWhispersHint'),
    ),
    _switch(S.of('hintsSetting'), Settings.hints, (v) => Settings.hints = v),
    _switch(
      S.of('skipSeenPerde'),
      Settings.skipSeenPerde,
      (v) => Settings.skipSeenPerde = v,
    ),
    if (!widget.canTouch) ...[
      _section(S.of('secKeys')),
      Text(
        S.of('controls'),
        style: TextStyle(
          color: _text.withValues(alpha: 0.65),
          fontSize: 13 * _f,
          height: 1.6,
        ),
      ),
    ],
  ];

  List<Widget> _controls() => [
    _section(S.of('touchControls')),
    _row(
      S.of('touchControls'),
      _segments<bool>(
        {false: S.of('touchButtons'), true: S.of('touchGestures')},
        Settings.touchGestures,
        (v) => Settings.touchGestures = v,
        after: widget.onTouchChanged,
      ),
    ),
    _slider(
      S.of('touchOpacity'),
      Settings.touchOpacity,
      (v) => Settings.touchOpacity = v,
      min: 0.1,
      after: widget.onTouchChanged,
    ),
    if (!Settings.touchGestures)
      _slider(
        S.of('touchScale'),
        Settings.touchScale,
        (v) => Settings.touchScale = v,
        min: 0.75,
        max: 1.4,
        after: widget.onTouchChanged,
      ),
    _switch(S.of('leftHanded'), Settings.leftHanded, (v) {
      Settings.leftHanded = v;
      widget.onTouchChanged?.call();
    }),
    if (Settings.touchGestures)
      Padding(
        padding: EdgeInsets.only(top: 10 * _k),
        child: Text(
          Hints.sides(S.of('touchHelpGestures')),
          style: TextStyle(
            color: _text.withValues(alpha: 0.6),
            fontSize: 12 * _f,
            height: 1.5,
          ),
        ),
      ),
  ];

  List<Widget> _licenses() => [
    Text(
      S.of('licensesIntro'),
      style: TextStyle(
        color: _text.withValues(alpha: 0.7),
        fontSize: 13 * _f,
        height: 1.5,
      ),
    ),
    _credit(S.of('creditMusic'), S.of('creditMusicText')),
    _credit(S.of('creditSounds'), S.of('creditSoundsText')),
    _credit(S.of('creditVoice'), S.of('creditVoiceText')),
    _credit(S.of('creditArt'), S.of('creditArtText')),
    SizedBox(height: 22 * _k),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: S.of('gameTitle'),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _text,
          side: const BorderSide(color: Color(0x55E0A15F)),
        ),
        child: Text(S.of('openLicenses')),
      ),
    ),
  ];

  // ----------------------------------------------------------- yapıtaşları

  /// Oyun sırasında altta sabit: Ana menü, Yeniden dene, Devam et.
  Widget? _footer() {
    if (!widget.inGame) return null;
    final side = OutlinedButton.styleFrom(
      foregroundColor: _text,
      side: const BorderSide(color: Color(0x55EBDDCB)),
    );
    return Row(
      children: [
        OutlinedButton(
          onPressed: widget.game.backToMenu,
          style: side,
          child: Text(S.of('mainMenu')),
        ),
        SizedBox(width: 10 * _k),
        OutlinedButton(
          onPressed: () {
            widget.game.toggleSettings();
            widget.game.player?.die();
          },
          style: side,
          child: Text(S.of('retry')),
        ),
        const Spacer(),
        FilledButton(
          onPressed: widget.game.toggleSettings,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: const Color(0xFF140C09),
          ),
          child: Text(S.of('resume')),
        ),
      ],
    );
  }

  /// Bölüm başlığı: küçük, geniş aralıklı, ılık; yanında ince bir çizgi.
  Widget _section(String title) => Padding(
    padding: EdgeInsets.only(top: 22 * _k, bottom: 6 * _k),
    child: Row(
      children: [
        Text(
          S.upper(title),
          style: TextStyle(
            color: _accent.withValues(alpha: 0.9),
            fontSize: 11 * _f,
            letterSpacing: 3,
          ),
        ),
        SizedBox(width: 12 * _k),
        Expanded(child: Container(height: 1, color: const Color(0x22E0A15F))),
      ],
    ),
  );

  /// Ayar satırı: solda ad, sağda denetim.
  Widget _row(String label, Widget control) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4 * _k),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: _text, fontSize: 14 * _f),
          ),
        ),
        control,
      ],
    ),
  );

  Widget _slider(
    String label,
    double value,
    void Function(double) set, {
    double min = 0,
    double max = 1,
    int? divisions,
    VoidCallback? after,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: 2 * _k),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(color: _text, fontSize: 14 * _f),
          ),
        ),
        Expanded(
          flex: 5,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              set(v);
              GameAudio.instance.applyVolumes();
              after?.call();
              setState(() {});
            },
            onChangeEnd: (_) => Settings.save(),
          ),
        ),
        SizedBox(
          width: 42 * _f,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _text.withValues(alpha: 0.6),
              fontSize: 13 * _f,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _switch(
    String label,
    bool value,
    void Function(bool) set, {
    String? note,
    bool noteAlways = false,
    bool save = true,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _row(
        label,
        Switch(
          value: value,
          activeThumbColor: _accent,
          inactiveThumbColor: _text.withValues(alpha: 0.6),
          inactiveTrackColor: const Color(0x22EBDDCB),
          trackOutlineColor: const WidgetStatePropertyAll(Color(0x55EBDDCB)),
          onChanged: (v) {
            set(v);
            if (save) _save();
            setState(() {});
          },
        ),
      ),
      if (note != null && (noteAlways || !value))
        Padding(
          padding: EdgeInsets.only(bottom: 6 * _k, right: 60 * _k),
          child: Text(
            note,
            style: TextStyle(
              color: _text.withValues(alpha: 0.55),
              fontSize: 11.5 * _f,
              height: 1.45,
            ),
          ),
        ),
    ],
  );

  Widget _segments<T>(
    Map<T, String> options,
    T value,
    void Function(T) set, {
    VoidCallback? after,
  }) => SegmentedButton<T>(
    segments: [
      for (final e in options.entries)
        ButtonSegment(value: e.key, label: Text(e.value)),
    ],
    selected: {value},
    showSelectedIcon: false,
    style: SegmentedButton.styleFrom(
      foregroundColor: _text,
      selectedForegroundColor: const Color(0xFF140C09),
      selectedBackgroundColor: _accent,
      side: const BorderSide(color: Color(0x55EBDDCB)),
      visualDensity: VisualDensity.compact,
    ),
    onSelectionChanged: (v) {
      set(v.first);
      after?.call();
      _save();
    },
  );

  Widget _credit(String title, String body) => Padding(
    padding: EdgeInsets.only(top: 18 * _k),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.upper(title),
          style: TextStyle(
            color: _accent.withValues(alpha: 0.85),
            fontSize: 11 * _f,
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: 5 * _k),
        Text(
          body,
          style: TextStyle(
            color: _text.withValues(alpha: 0.7),
            fontSize: 13 * _f,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
