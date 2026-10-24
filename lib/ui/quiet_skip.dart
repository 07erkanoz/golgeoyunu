import 'package:flutter/material.dart';

import '../game/strings.dart';

/// Perdenin ve girişin "Atla"sı: köşede küçük, soluk bir yazı (çerçevesiz,
/// zeminsiz); sahneyi örtmez, göze batmaz. Dokunma alanı yine parmak kadar.
class QuietSkip extends StatelessWidget {
  const QuietSkip({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFEBDDCB).withValues(alpha: 0.42),
        overlayColor: const Color(0xFFEBDDCB),
        minimumSize: const Size(56, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        '${S.of('skipPerde')}  ›',
        style: const TextStyle(fontSize: 12.5, letterSpacing: 2),
      ),
    );
  }
}
