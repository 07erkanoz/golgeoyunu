import 'package:flutter/material.dart';

import '../game/strings.dart';

/// Defter, Hakkında ve Ayarlar'ın ortak çerçevesi: karanlık odada ortada kenarlı bir
/// sayfa. Üstte solda Geri, ortada başlık; varsa altında sekmeler; içerik
/// sayfanın içinde kayar.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.k,
    required this.title,
    required this.onBack,
    required this.child,
    this.tabs = const [],
    this.tab = 0,
    this.onTab,
    this.footer,
  });

  final double k;
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final List<String> tabs;
  final int tab;
  final ValueChanged<int>? onTab;

  /// Kaymayan alt şerit (ör. oyun sırasında Devam / Ana menü).
  final Widget? footer;

  static const _text = Color(0xFFEBDDCB);
  static const _accent = Color(0xFFE0A15F);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF070403),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            margin: EdgeInsets.symmetric(horizontal: 18 * k, vertical: 14 * k),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x44E0A15F)),
              gradient: const RadialGradient(
                center: Alignment(0, -0.8),
                radius: 1.4,
                colors: [Color(0xFF1E120A), Color(0xFF0E0806)],
              ),
            ),
            child: Column(
              children: [
                // Başlık satırı.
                SizedBox(
                  height: 58 * k,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        S.upper(title),
                        style: TextStyle(
                          color: _text,
                          fontSize: 20 * (k < 0.9 ? 0.9 : k),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        child: TextButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: Text(S.of('back')),
                          style: TextButton.styleFrom(
                            foregroundColor: _text.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (tabs.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6 * k),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < tabs.length; i++)
                          GestureDetector(
                            onTap: () => onTab?.call(i),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18 * k,
                                vertical: 8 * k,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: i == tab
                                        ? _accent
                                        : const Color(0x00000000),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                tabs[i],
                                style: TextStyle(
                                  color: i == tab
                                      ? _accent
                                      : _text.withValues(alpha: 0.55),
                                  fontSize: 14 * (k < 0.9 ? 0.9 : k),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Container(height: 1, color: const Color(0x33E0A15F)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      36 * k,
                      22 * k,
                      36 * k,
                      28 * k,
                    ),
                    child: child,
                  ),
                ),
                if (footer != null) ...[
                  Container(height: 1, color: const Color(0x33E0A15F)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24 * k,
                      12 * k,
                      24 * k,
                      14 * k,
                    ),
                    child: footer,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
