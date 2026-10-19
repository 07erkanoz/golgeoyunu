import 'package:flutter/material.dart';

import '../game/golge_game.dart';
import '../game/levels.dart';
import '../game/strings.dart';
import '../settings.dart';

/// Ana menü: arkada oyunun dünyası yavaşça akar, solda başlık ve seçenekler.
class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.game, this.onQuit});

  final GolgeGame game;
  final VoidCallback? onQuit;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  static const _text = Color(0xFFEBDDCB);
  static const _accent = Color(0xFFE0A15F);

  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  bool _confirmNew = false;

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
    final save = SaveGame.current;
    final savedLevel = save == null
        ? null
        : levels[save.level.clamp(0, levels.length - 1)].titleText;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: Stack(
        children: [
          // Okunabilirlik için soldan sağa açılan karartma.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xE6050302),
                    Color(0x99050302),
                    Color(0x00050302),
                  ],
                  stops: [0, 0.45, 0.8],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(64, 40, 32, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  Text(
                    S.of('gameTitle'),
                    style: const TextStyle(
                      color: _text,
                      fontSize: 52,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 14,
                      shadows: [
                        Shadow(color: Color(0xAAE0A15F), blurRadius: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.of('menuSubtitle'),
                    style: TextStyle(
                      color: _text.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 44),
                  if (save != null)
                    _item(
                      S.of('continue'),
                      hint: savedLevel,
                      primary: true,
                      onTap: widget.game.continueGame,
                    ),
                  _item(
                    _confirmNew ? S.of('confirmNew') : S.of('newGame'),
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
                  _item(S.of('settings'), onTap: widget.game.toggleSettings),
                  if (widget.onQuit != null)
                    _item(S.of('quit'), onTap: widget.onQuit!),
                  const Spacer(flex: 4),
                  Row(
                    children: [
                      _langButton('TR', Lang.tr),
                      Text(
                        '  /  ',
                        style: TextStyle(color: _text.withValues(alpha: 0.35)),
                      ),
                      _langButton('EN', Lang.en),
                      const Spacer(),
                      Text(
                        S.of('musicCredit'),
                        style: TextStyle(
                          color: _text.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    String? hint,
    bool primary = false,
    bool warn = false,
  }) {
    return _MenuItem(
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
  });

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
          padding: EdgeInsets.only(left: _hover ? 14 : 0, top: 9, bottom: 9),
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
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.warn
                      ? const Color(0xFFE08A6A)
                      : (lit ? text : text.withValues(alpha: 0.7)),
                  fontSize: 21,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.5,
                ),
              ),
              if (widget.hint != null) ...[
                const SizedBox(width: 14),
                Text(
                  widget.hint!,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.8),
                    fontSize: 13,
                    letterSpacing: 2,
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
