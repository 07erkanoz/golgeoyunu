import 'package:flutter/material.dart';

import '../game/audio.dart';
import '../game/golge_game.dart';
import '../game/strings.dart';
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
                  if (Settings.touchGestures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        S.of('touchHelpGestures'),
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
                  min: 0.8,
                  max: 1.3,
                  onChanged: (v) {
                    Settings.brightness = v;
                    Settings.save();
                    setState(() {});
                  },
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
                        ButtonSegment(value: true, label: Text(S.of('gfxLow'))),
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
                        Settings.save();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                  S.of('credits').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.of('musicLicense'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _text.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.45,
                  ),
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
    );
  }

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
