import 'package:flutter/material.dart';

import '../game/golge_game.dart';
import '../game/narration.dart';
import '../game/strings.dart';

const _text = Color(0xFFEBDDCB);
const _accent = Color(0xFFE0A15F);

/// "Az önce": okumayı kaçıranlar için bu bölümde ekrana gelen hikâye
/// satırları, ipuçları, yer adları ve efsaneler (en yenisi üstte). Açıkken
/// oyun bekler.
class RecentPanel extends StatelessWidget {
  const RecentPanel({super.key, this.game, this.preview});

  final GolgeGame? game;

  /// Önizleme için hazır satırlar (oyun olmadan).
  final List<RecentLine>? preview;

  String _label(RecentKind k) => switch (k) {
    RecentKind.title => S.of('recentTitleKind'),
    RecentKind.place => S.of('recentPlace'),
    RecentKind.story => S.of('recentStory'),
    RecentKind.hint => S.of('recentHint'),
    RecentKind.legend => S.of('recentLegend'),
  };

  @override
  Widget build(BuildContext context) {
    final lines = (preview ?? game!.narration.recent).reversed.toList();
    final close = game?.toggleRecent ?? () {};
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: close,
      child: Container(
        color: const Color(0xCC050302),
        alignment: Alignment.center,
        child: SafeArea(
          child: GestureDetector(
            // Panelin içine dokunmak kapatmasın.
            onTap: () {},
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              decoration: BoxDecoration(
                color: const Color(0xF0140C09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x33E0A15F)),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.of('recentTitle'),
                            style: const TextStyle(
                              color: _text,
                              fontSize: 16,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: close,
                          icon: const Icon(Icons.close, color: _text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: lines.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                S.of('recentEmpty'),
                                style: TextStyle(
                                  color: _text.withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: lines.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 18,
                                color: _accent.withValues(alpha: 0.12),
                              ),
                              itemBuilder: (_, i) {
                                final l = lines[i];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.upper(_label(l.kind)),
                                      style: TextStyle(
                                        color: _accent.withValues(alpha: 0.8),
                                        fontSize: 10,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      l.text,
                                      style: TextStyle(
                                        color: _text.withValues(alpha: 0.9),
                                        fontSize: 14,
                                        height: 1.45,
                                        fontStyle: l.kind == RecentKind.story
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
