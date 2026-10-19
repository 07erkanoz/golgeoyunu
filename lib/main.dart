import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game/golge_game.dart';
import 'ui/touch_controls.dart';

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isMobile) {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
  }
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gölge Oyunu',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GameWidget(game: _game),
            if (_isMobile) TouchControls(controls: _game.controls),
          ],
        ),
      ),
    );
  }
}
