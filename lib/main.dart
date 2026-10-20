import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'game/audio.dart';
import 'display.dart';
import 'game/golge_game.dart';
import 'settings.dart';
import 'ui/main_menu.dart';
import 'ui/settings_panel.dart';
import 'ui/touch_controls.dart';

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Dokunmatik kontroller: telefonda ve tablette (mobil tarayıcı dahil).
/// `--dart-define=TOUCH=true` masaüstünde de dokunmatik düğmeleri gösterir
/// (mobil görünümü önizlemek için).
bool get _isTouch =>
    const bool.fromEnvironment('TOUCH') ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.load(lowGraphicsByDefault: _isTouch);
  if (_isMobile) {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
    await applyRefreshRate();
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
  final _gameFocus = FocusNode(debugLabel: 'oyun');
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _game.onToggleFullscreen = () => _setFullscreen(!Settings.fullscreen);
    // Menü ya da ayarlar kapanınca klavye yeniden oyuna gider.
    _game.onFocusGame = () => WidgetsBinding.instance.addPostFrameCallback(
      (_) => _gameFocus.requestFocus(),
    );
    // Telefon oyunu arka plana alınca (ya da kapatılırken) ilerleme ve
    // ayarlar hemen yazılır; sistem uygulamayı öldürse de kaybolmaz.
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.detached) {
          _game.saveNow();
          Settings.save();
        }
        // Geri dönünce yüksek yenileme hızı yeniden istenir.
        if (state == AppLifecycleState.resumed && _isMobile) {
          applyRefreshRate();
        }
      },
    );
  }

  @override
  void dispose() {
    _gameFocus.dispose();
    _lifecycle.dispose();
    super.dispose();
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
      // Android'de geri hareketi (ör. kenardan kaydırma) oyunu kapatmasın:
      // oyunda duraklatma ekranını açar, açıksa kapatır.
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || _game.menuMode.value) return;
          _game.toggleSettings();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GameWidget(
                game: _game,
                focusNode: _gameFocus,
                autofocus: true,
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
                        canTouch: _isTouch,
                        onTouchChanged: () => setState(() {}),
                      ),
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _game.menuMode,
                builder: (context, inMenu, _) {
                  if (inMenu) return const SizedBox.shrink();
                  return Stack(
                    children: [
                      if (_isTouch)
                        ValueListenableBuilder<bool>(
                          valueListenable: _game.settingsOpen,
                          builder: (context, open, _) => open
                              ? const SizedBox.shrink()
                              : TouchControls(controls: _game.controls),
                        ),
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
      ),
    );
  }
}
