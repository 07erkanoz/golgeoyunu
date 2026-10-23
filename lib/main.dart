import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'game/audio.dart';
import 'display.dart';
import 'game/golge_game.dart';
import 'game/strings.dart';
import 'settings.dart';
import 'ui/hint_button.dart';
import 'ui/main_menu.dart';
import 'ui/recent_panel.dart';
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
  await Settings.load();
  // Geliştirici ölçümü: grafik düzeyi zorlanır (kayıtlı ayara dokunmaz).
  if (const bool.fromEnvironment('DEV')) {
    const gfx = String.fromEnvironment('GFX');
    if (gfx == 'low') Settings.lowGraphics = true;
    if (gfx == 'high') Settings.lowGraphics = false;
  }
  if (_isMobile) {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
    await applyRefreshRate();
  }
  if (_isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'Gölge Oyunu',
        size: Size(1280, 720),
        minimumSize: Size(800, 450),
        center: true,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  GameAudio.instance.init();
  runApp(const GolgeApp());
  // Tam ekran, pencere gösterilip oyun ilk karesini çizdikten sonra: daha
  // önce açılışta istenince Windows'ta çerçevesiz, görev çubuğunda görünmeyen
  // ve içi çizilmeyen siyah bir pencere kalıyordu.
  if (_isDesktop && Settings.fullscreen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        await windowManager.setFullScreen(true);
        await windowManager.focus();
      });
    });
  }
}

class GolgeApp extends StatefulWidget {
  const GolgeApp({super.key});

  @override
  State<GolgeApp> createState() => _GolgeAppState();
}

class _GolgeAppState extends State<GolgeApp> with WindowListener {
  final _game = GolgeGame();
  final _gameFocus = FocusNode(debugLabel: 'oyun');
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _game.onToggleFullscreen = () => _setFullscreen(!Settings.fullscreen);
    if (_isDesktop) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
    }
    // Menü ya da ayarlar kapanınca klavye yeniden oyuna gider.
    _game.onFocusGame = () => WidgetsBinding.instance.addPostFrameCallback(
      (_) => _gameFocus.requestFocus(),
    );
    // Telefon oyunu arka plana alınca (ya da kapatılırken) ilerleme ve
    // ayarlar hemen yazılır; sistem uygulamayı öldürse de kaybolmaz.
    // Pencere/uygulama odağını kaybedince tuş bırakma olayları gelmeyebilir:
    // basılı kalan girdi temizlenir.
    _gameFocus.addListener(() {
      if (!_gameFocus.hasFocus) _game.controls.resetAll();
    });
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.resumed) _game.controls.resetAll();
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

  /// Masaüstünde pencere kapatılırken önce ilerleme ve ayarlar diske yazılır,
  /// sonra pencere kapanır (yalnız yaşam döngüsü bildirimine güvenilmez).
  @override
  void onWindowClose() async {
    try {
      await _game.saveNow();
      await Settings.save();
      await SaveGame.flush().timeout(const Duration(seconds: 2));
    } catch (_) {}
    await windowManager.destroy();
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
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
          if (_game.recentOpen) {
            _game.toggleRecent();
            return;
          }
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
                  GolgeGame.recentOverlay: (context, GolgeGame game) =>
                      RecentPanel(game: game),
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
                              : ValueListenableBuilder<bool>(
                                  valueListenable: _game.narration.perdeOn,
                                  builder: (context, perde, _) => TouchControls(
                                    controls: _game.controls,
                                    hideHelp: perde,
                                  ),
                                ),
                        ),
                      // Perde oynarken sağ altta "Atla": perdenin tamamı
                      // geçilir (dokunmatikte de; klavyede Esc).
                      ValueListenableBuilder<bool>(
                        valueListenable: _game.narration.perdeOn,
                        builder: (context, on, _) => !on
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: 16,
                                bottom: 12,
                                child: SafeArea(
                                  child: TextButton(
                                    onPressed: _game.narration.skipAll,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFEBDDCB),
                                      backgroundColor: const Color(0x66140C09),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      shape: const StadiumBorder(
                                        side: BorderSide(
                                          color: Color(0x66E0A15F),
                                        ),
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
                      // İpucu simgesi: ipucu gerektiren yerde yanar,
                      // dokununca ipucu görünür (klavyede H).
                      Positioned(
                        top: 4,
                        right: _isTouch ? 164 : 100,
                        child: SafeArea(
                          child: HintButton(game: _game, touch: _isTouch),
                        ),
                      ),
                      // "i": az önceki hikâye ve ipucu (okumayı kaçıranlar
                      // için); dokunmatikte ateşböceği simgesinin solunda.
                      Positioned(
                        top: 8,
                        right: _isTouch ? 116 : 56,
                        child: SafeArea(
                          child: IconButton(
                            tooltip: 'I',
                            onPressed: _game.toggleRecent,
                            icon: Icon(
                              Icons.info_outline,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
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
