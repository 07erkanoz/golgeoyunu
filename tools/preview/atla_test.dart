// Girişte "Atla": eski (çerçeveli) ve yeni (küçük, soluk) yan yana.
// `flutter test tools/preview/atla_test.dart` → build/preview/atla.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/ui/quiet_skip.dart';

import 'yazi_tipi.dart';

class _Scene extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => PerdePainter.paintIntro(
    canvas,
    size,
    6.7,
    'GÖLGE OYUNU',
    'Hayal perdesinde bir gölgenin yolculuğu',
  );
  @override
  bool shouldRepaint(_Scene old) => false;
}

void main() {
  setUpAll(yaziTipiYukle);
  testWidgets('atla', (tester) async {
    tester.view.physicalSize = const Size(870, 782 + 4);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    Widget scene(Widget skip) => SizedBox(
      width: 870,
      height: 391,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _Scene())),
          Positioned(right: 10, bottom: 6, child: skip),
        ],
      ),
    );
    final old = TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFEBDDCB),
        backgroundColor: const Color(0x66140C09),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0x66E0A15F)),
        ),
      ),
      child: const Text('Atla  ›', style: TextStyle(fontSize: 15, letterSpacing: 1)),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              scene(old),
              const SizedBox(height: 4),
              scene(QuietSkip(onPressed: () {})),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage();
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/atla.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
