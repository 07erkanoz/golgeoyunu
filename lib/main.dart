import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'game/audio.dart';
import 'game/golge_game.dart';
import 'settings.dart';
import 'ui/main_menu.dart';
import 'ui/settings_panel.dart';
import 'ui/touch_controls.dart';

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.load();
  if (_isMobile) {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
  }
  if (_isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(title: 'Gölge Oyunu', minimumSize: Size(800, 450)),
      () async {
        await windowManager.show();
        await windowManager.focus();
        if (Settings.fullscreen) await windowManager.setFullScreen(true);
      },
    );
  }
  GameAudio.instance.init();
  runApp(const GolgeApp());
}

class GolgeApp extends StatefulWidget {
  const GolgeApp({super.key});

  @override
  State<GolgeApp> createState() => _GolgeAppState();
}

class _GolgeAppState extends State<GolgeApp> {
  final _game = GolgeGame();

  @override
  void initState() {
    super.initState();
    _game.onToggleFullscreen = () => _setFullscreen(!Settings.fullscreen);
  }

  Future<void> _setFullscreen(bool on) async {
    if (!_isDesktop) return;
    Settings.fullscreen = on;
    await Settings.save();
    await windowManager.setFullScreen(on);
    setState(() {});
  }

  void _refreshMenus() {
    // Dil değişince açık ekranlar yeni metinlerle yeniden kurulur.
    for (final name in [GolgeGame.menuOverlay, GolgeGame.settingsOverlay]) {
      if (_game.overlays.isActive(name)) {
        _game.overlays.remove(name);
        _game.overlays.add(name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gölge Oyunu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GameWidget(
              game: _game,
              overlayBuilderMap: {
                GolgeGame.menuOverlay: (context, GolgeGame game) => MainMenu(
                  game: game,
                  onQuit: _isDesktop ? () => windowManager.close() : null,
                ),
                GolgeGame.settingsOverlay: (context, GolgeGame game) =>
                    SettingsPanel(
                      game: game,
                      canFullscreen: _isDesktop,
                      onFullscreen: _setFullscreen,
                      onLanguage: _refreshMenus,
                    ),
              },
              initialActiveOverlays: const [GolgeGame.menuOverlay],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _game.menuMode,
              builder: (context, inMenu, _) {
                if (inMenu) return const SizedBox.shrink();
                return Stack(
                  children: [
                    if (_isMobile) TouchControls(controls: _game.controls),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: SafeArea(
                        child: IconButton(
                          tooltip: 'Esc',
                          onPressed: _game.toggleSettings,
                          icon: Icon(
                            Icons.settings_outlined,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
