import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/audio.dart';
import '../game/auto_quality.dart';
import '../game/golge_game.dart';
import '../game/hints.dart';
import '../game/palette.dart';
import '../game/strings.dart';
import '../display.dart';
import '../settings.dart';

/// Esc ya da dişli simgesiyle açılan ayarlar: ses seviyeleri ve tam ekran.
/// Açıkken oyun durur.
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

class _SettingsPanelState extends State<SettingsPanel> {
  static const _text = Color(0xFFEBDDCB);
  static const _accent = Color(0xFFE0A15F);

  void _changed() {
    GameAudio.instance.applyVolumes();
    Settings.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC050302),
      alignment: Alignment.center,
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.94,
        ),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF140C09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33E0A15F)),
        ),
        // Anahtarların dokunma halkaları panelin zemininde görünsün.
        child: Material(
          type: MaterialType.transparency,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              inactiveTrackColor: const Color(0x33E0A15F),
              thumbColor: _accent,
              overlayColor: const Color(0x22E0A15F),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    S.of('settingsTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 20,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _label(S.of('music'), Settings.music),
                  Slider(
                    value: Settings.music,
                    onChanged: (v) {
                      Settings.music = v;
                      _changed();
                    },
                  ),
                  _label(S.of('ambience'), Settings.ambience),
                  Slider(
                    value: Settings.ambience,
                    onChanged: (v) {
                      Settings.ambience = v;
                      _changed();
                    },
                  ),
                  _label(S.of('effects'), Settings.effects),
                  Slider(
                    value: Settings.effects,
                    onChanged: (v) {
                      Settings.effects = v;
                      _changed();
                    },
                  ),
                  if (widget.canFullscreen)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        S.of('fullscreen'),
                        style: const TextStyle(color: _text),
                      ),
                      value: Settings.fullscreen,
                      activeThumbColor: _accent,
                      onChanged: (v) {
                        widget.onFullscreen(v);
                        setState(() {});
                      },
                    ),
                  if (widget.canTouch) ...[
                    Row(
                      children: [
                        Text(
                          S.of('touchControls'),
                          style: const TextStyle(color: _text, fontSize: 14),
                        ),
                        const Spacer(),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(S.of('touchButtons')),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(S.of('touchGestures')),
                            ),
                          ],
                          selected: {Settings.touchGestures},
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            foregroundColor: _text,
                            selectedForegroundColor: const Color(0xFF140C09),
                            selectedBackgroundColor: _accent,
                            side: const BorderSide(color: Color(0x55EBDDCB)),
                          ),
                          onSelectionChanged: (v) {
                            Settings.touchGestures = v.first;
                            Settings.save();
                            widget.onTouchChanged?.call();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    _label(S.of('touchOpacity'), Settings.touchOpacity),
                    Slider(
                      value: Settings.touchOpacity,
                      min: 0.1,
                      onChanged: (v) {
                        Settings.touchOpacity = v;
                        Settings.save();
                        widget.onTouchChanged?.call();
                        setState(() {});
                      },
                    ),
                    if (!Settings.touchGestures) ...[
                      _label(S.of('touchScale'), Settings.touchScale),
                      Slider(
                        value: Settings.touchScale,
                        min: 0.75,
                        max: 1.4,
                        onChanged: (v) {
                          Settings.touchScale = v;
                          Settings.save();
                          widget.onTouchChanged?.call();
                          setState(() {});
                        },
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.of('leftHanded'),
                            style: const TextStyle(color: _text, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: Settings.leftHanded,
                          activeThumbColor: _accent,
                          inactiveThumbColor: _text.withValues(alpha: 0.6),
                          inactiveTrackColor: const Color(0x22EBDDCB),
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Color(0x55EBDDCB),
                          ),
                          onChanged: (v) {
                            Settings.leftHanded = v;
                            Settings.save();
                            widget.onTouchChanged?.call();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    if (Settings.touchGestures)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          Hints.sides(S.of('touchHelpGestures')),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _text.withValues(alpha: 0.55),
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ),
                  ],
                  _label(S.of('brightness'), Settings.brightness),
                  Slider(
                    value: Settings.brightness,
                    min: 0.6,
                    max: 1.6,
                    onChanged: (v) {
                      Settings.brightness = v;
                      Settings.save();
                      setState(() {});
                    },
                  ),
                  // Fısıltı, ipucu ve efsane kartının yazısı büyütülür.
                  _label(S.of('textSize'), Settings.textScale),
                  Slider(
                    value: Settings.textScale,
                    min: 0.8,
                    max: 1.6,
                    divisions: 8,
                    onChanged: (v) {
                      Settings.textScale = v;
                      setState(() {});
                    },
                    onChangeEnd: (_) => Settings.save(),
                  ),
                  // Deneme yapısında: renk ve doku denemesi (Yerebatan
                  // renkleri, bütün bölümlerde zemin dokusu) açılıp kapanır,
                  // tonu kaydırılır (0 karanlık, 100 aydınlık).
                  if (Cartoon.trialBuild) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Renk ve doku denemesi',
                            style: TextStyle(color: _text, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: Cartoon.on,
                          activeThumbColor: _accent,
                          inactiveThumbColor: _text.withValues(alpha: 0.6),
                          inactiveTrackColor: const Color(0x22EBDDCB),
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Color(0x55EBDDCB),
                          ),
                          onChanged: (v) => setState(() {
                            Cartoon.on = v;
                            Settings.texture = v;
                            Settings.save();
                          }),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Settings.lowGraphics
                                ? 'Işık ve derinlik (deneme)\nDüşük grafikte kapalı'
                                : 'Işık ve derinlik (deneme)',
                            style: const TextStyle(color: _text, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: Realism.on,
                          activeThumbColor: _accent,
                          inactiveThumbColor: _text.withValues(alpha: 0.6),
                          inactiveTrackColor: const Color(0x22EBDDCB),
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Color(0x55EBDDCB),
                          ),
                          onChanged: (v) => setState(() {
                            Realism.on = v;
                            Settings.realism = v;
                            Settings.save();
                            if (v) AutoQuality.userChose = true;
                          }),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ölçüm göstergesi (kare, bellek)',
                            style: TextStyle(color: _text, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: widget.game.perfShown,
                          activeThumbColor: _accent,
                          inactiveThumbColor: _text.withValues(alpha: 0.6),
                          inactiveTrackColor: const Color(0x22EBDDCB),
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Color(0x55EBDDCB),
                          ),
                          onChanged: (v) => setState(() {
                            widget.game.perfShown = v;
                            Settings.save();
                          }),
                        ),
                      ],
                    ),
                    _label(S.of('colorTone'), Cartoon.tone),
                    Slider(
                      value: Cartoon.tone,
                      divisions: 20,
                      onChanged: (v) {
                        Cartoon.tone = v;
                        Settings.tone = v;
                        setState(() {});
                      },
                      onChangeEnd: (_) => Settings.save(),
                    ),
                  ],
                  // Yüksek yenileme hızı: Android'de 90/120 Hz istenir;
                  // masaüstünde kapalıyken kareler 60 dolayında sınırlanır
                  // (açıkken ekranın kendi hızı).
                  if (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.linux ||
                      defaultTargetPlatform == TargetPlatform.macOS)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.of('highRefresh'),
                            style: const TextStyle(color: _text, fontSize: 14),
                          ),
                        ),
                        Switch(
                          value: Settings.highRefresh,
                          activeThumbColor: _accent,
                          inactiveThumbColor: _text.withValues(alpha: 0.6),
                          inactiveTrackColor: const Color(0x22EBDDCB),
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Color(0x55EBDDCB),
                          ),
                          onChanged: (v) {
                            setState(() => Settings.highRefresh = v);
                            Settings.save();
                            applyRefreshRate();
                            widget.game.pacer.apply();
                          },
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Text(
                        S.of('graphics'),
                        style: const TextStyle(color: _text, fontSize: 14),
                      ),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(S.of('gfxHigh')),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(S.of('gfxLow')),
                          ),
                        ],
                        selected: {Settings.lowGraphics},
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          foregroundColor: _text,
                          selectedForegroundColor: const Color(0xFF140C09),
                          selectedBackgroundColor: _accent,
                          side: const BorderSide(color: Color(0x55EBDDCB)),
                        ),
                        onSelectionChanged: (v) {
                          Settings.lowGraphics = v.first;
                          Settings.autoLowered = false;
                          if (!v.first) AutoQuality.userChose = true;
                          Settings.save();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.of('autoQuality'),
                          style: const TextStyle(color: _text, fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: Settings.autoQuality,
                        activeThumbColor: _accent,
                        inactiveThumbColor: _text.withValues(alpha: 0.6),
                        inactiveTrackColor: const Color(0x22EBDDCB),
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Color(0x55EBDDCB),
                        ),
                        onChanged: (v) {
                          setState(() => Settings.autoQuality = v);
                          Settings.save();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.of('calmEffects'),
                          style: const TextStyle(color: _text, fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: Settings.calmEffects,
                        activeThumbColor: _accent,
                        inactiveThumbColor: _text.withValues(alpha: 0.6),
                        inactiveTrackColor: const Color(0x22EBDDCB),
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Color(0x55EBDDCB),
                        ),
                        onChanged: (v) {
                          Settings.calmEffects = v;
                          Settings.save();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  // Anlatım: ikinci oynayışta hikâyeyi yeniden okumak
                  // istemeyen için.
                  _switchRow(
                    S.of('storyWhispers'),
                    Settings.storyWhispers,
                    (v) => Settings.storyWhispers = v,
                    note: S.of('storyWhispersHint'),
                  ),
                  _switchRow(
                    S.of('hintsSetting'),
                    Settings.hints,
                    (v) => Settings.hints = v,
                  ),
                  _switchRow(
                    S.of('skipSeenPerde'),
                    Settings.skipSeenPerde,
                    (v) => Settings.skipSeenPerde = v,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        S.of('language'),
                        style: const TextStyle(color: _text, fontSize: 14),
                      ),
                      const Spacer(),
                      SegmentedButton<Lang>(
                        segments: const [
                          ButtonSegment(value: Lang.tr, label: Text('Türkçe')),
                          ButtonSegment(value: Lang.en, label: Text('English')),
                        ],
                        selected: {S.lang},
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          foregroundColor: _text,
                          selectedForegroundColor: const Color(0xFF140C09),
                          selectedBackgroundColor: _accent,
                          side: const BorderSide(color: Color(0x55EBDDCB)),
                        ),
                        onSelectionChanged: (v) {
                          S.lang = v.first;
                          Settings.save();
                          widget.onLanguage();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.of('controls'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _text.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (widget.inGame) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.game.backToMenu,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _text,
                              side: const BorderSide(color: Color(0x55EBDDCB)),
                            ),
                            child: Text(S.of('mainMenu')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              widget.game.toggleSettings();
                              widget.game.player?.die();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _text,
                              side: const BorderSide(color: Color(0x55EBDDCB)),
                            ),
                            child: Text(S.of('retry')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton(
                    onPressed: widget.game.toggleSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: const Color(0xFF140C09),
                    ),
                    child: Text(widget.inGame ? S.of('resume') : S.of('close')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Açma/kapama satırı: değişince kaydedilir.
  Widget _switchRow(
    String text,
    bool value,
    void Function(bool) set, {
    String? note,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _text, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _accent,
            inactiveThumbColor: _text.withValues(alpha: 0.6),
            inactiveTrackColor: const Color(0x22EBDDCB),
            trackOutlineColor: const WidgetStatePropertyAll(Color(0x55EBDDCB)),
            onChanged: (v) {
              set(v);
              Settings.save();
              setState(() {});
            },
          ),
        ],
      ),
      if (note != null && !value)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            note,
            style: TextStyle(
              color: _text.withValues(alpha: 0.55),
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
    ],
  );

  Widget _label(String text, double value) => Row(
    children: [
      Text(text, style: const TextStyle(color: _text, fontSize: 14)),
      const Spacer(),
      Text(
        '${(value * 100).round()}',
        style: TextStyle(color: _text.withValues(alpha: 0.6), fontSize: 13),
      ),
    ],
  );
}
